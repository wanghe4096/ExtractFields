# -*- coding: utf-8 -*-
"""
    测试　日志文件　解析

    用法
    １ 列出全部支持的　日志　source_type
    2  给定 source_type 列出数据抽取的流程
        eg.
            python t_extract.py etc access_combined

    3  给定 source_type　和　具体的日志文件，　会有两个方法进行选择，1 表示选择extract方法 ：显示解析后的结果，2 表示选择multiline方法：多行event进行合并,并显示合并的过程和结果
        eg.
            python t_extract.py etc access_combined ../LogSample/apache/access_log
            # 测试 custom line-breaker
            python t_extract.py etc wmi ./samples/splunk-wmi.log
            单行:python t_extract.py etc access_combined samples/apache.log
            多行:python t_extract.py etc catalina samples/ANON-catalina.log
    4 获得时间戳正则
        eg.
                python      #进入命令行
                from t_extract import *
                timeInfoTuplet = getTimeInfoTuplet('anonymizer/anonymizer-time.ini')
                text = '113.96.151.228 - - [23/Mar/2015:15:07:25 +0800] "GET /drupal7/sites/all/themes/business-sun/images/nav_bright.png HTTP/1.1" 200 1544 "http://221.176.36.22/drupal7/sites/default/files/css/css_RZjyH429I2kO-99SMK9IKUApg5hKEHgZz3_8Orrf5YI.css" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)


"""
import os
import sys
import re
import spl_common
from distutils.util import strtobool
from jinja2 import Environment, FileSystemLoader
from DateParser import _validateDate, _validateTime

def pcre_subparse(vl="",l={}):
    pl = re.compile('\[\[(.*?)\]\]')
    ml = pl.findall(vl)
    res = vl
    if len(ml)>0:
        for i in ml:
            sl = i.split(":")
            if len(sl)>1:
                res = vl.replace('[['+i+']]','(?<'+sl[1]+'>'+l[sl[0]]+')')
            else:
                res = vl.replace('[['+i+']]',l[sl[0]])
            vl = res
    return res

def pcre_parse(value="",transforms={}):
    l={}
    for (k,d) in transforms.items():
        if type(d)==dict and d.has_key('REGEX'):
            pa=re.compile('\?\<(.*?)\>')
            v = d['REGEX']
            val = v
            li = pa.findall(v)
            if len(li)>0:
                for i in li:
                    if i == "":
                        val = v.replace('?<>','?:')
                    v=val
                if not v.startswith('(?') or not v.endswith(')'):
                    l[k]='(?:'+v.replace('/','\/')+')'
                else:
                    l[k]=v.replace('/','\/')
            else:
                if not v.startswith('(?') or not v.endswith(')'):
                    l[k]='(?:'+d['REGEX'].replace('/','\/')+')'
                else:
                    l[k]=d['REGEX'].replace('/','\/')
    p = re.compile('\[\[(.*?)\]\]')
    m = p.findall(value)
    result = value
    if len(m)>0:
        result = pcre_subparse(result,l)
        while len(p.findall(result))>0:
            result = pcre_subparse(result,l)
    else:
        result = pcre_subparse(l[result],l)
        while len(p.findall(result)) > 0:
            result = pcre_subparse(result,l)
    pp = re.compile('\?\<(.*?)\>')
    mm = pp.findall(result)
    for j in mm:
        count = 0
        for i in mm:
            if j == i:
                count = count + 1
        if count > 1:
            for k in range(count):
                if len(pp.findall(result)) != len(set(pp.findall(result))):
                    result = result.replace(j,j+str(k),k+1)
    return result

def generate_sourcetype_re(sourcetype,transforms,props_conf):
    transforms_stanza = {}
    for k in props_conf[sourcetype].keys():
        if re.search('(?:TRANSFORMS-*|REPORT-*|EXTRACT-*)',k):
            transforms_stanza[k]=transforms['default']
            for (ke,va) in transforms[props_conf[sourcetype][k]].items():
                transforms_stanza[k][ke] = va
            transforms_stanza[k]['REGEX']=pcre_parse(props_conf[sourcetype][k],transforms)
    return transforms_stanza


def findAllDatesAndTimes(text, timeInfoTuplet):
    global today, _MIN_YEAR, _MAX_YEAR

    #timeExpressions = timeInfoTuplet[0]
    #dateExpressions = timeInfoTuplet[1]
    datetimeExpressions = timeInfoTuplet[2]
    matches = getAllMatches(text, datetimeExpressions, _validateDate)
    #matches = getAllMatches(text, dateExpressions, _validateDate)
    #matches.extend(getAllMatches(text, timeExpressions, _validateTime))
    return matches


def getAllMatches(text, expressions, validator):
    index = -1
    matches = list()
    mat_dict = {}
    for expression in expressions.values():
        index += 1
        isvalid = True
        match = re.search(expression,text)
        if match:
            print match.group(),'\n=======\n',match.groupdict()
            print expression
            val = {}
            for k,v in match.groupdict().items():
                if v != None:
                    val[k] = v
            mat_dict[match.group()] = expression
    for k,v in mat_dict.items():
        
    return matches

'''
        for match in expression.finditer(text):
            values = match.groupdict()
            for k,v in values.items():
                if v != None:
                    val[k] = v
            isvalid = validator(val)
        print  '=============\n',match.group(),'\n',val
        if isvalid:
            matches.append(val)
'''
                #print "MATCHED: ", match.group()
                #matches.append(match.span())
                # DOING ALL EXPRESSIONS FOR OPTIMIZATION DOES NOTHING.
                # # DC: WE HAVE A VALID MATCH, AND IT WASN'T THE FIRST EXPRESSION,
                # # MAKE THIS PATTERN THE FIRST ONE TRIED FROM NOW ON
                # if index > 0: # optimize search
                #     expressions.insert(0, expressions.pop(index))


def getTimeInfoTuplet(timestampconfilename):
    text = readText(timestampconfilename)
    text = text.replace('\\n', '\n').replace('\n\n', '\n')
    exec(text)
    compiledTimePatterns = compilePatterns(timePatterns)
    compiledDatePatterns = compilePatterns(datePatterns)
    compiledDateTimePatterns = compilePatterns(datetimePatterns)
    timeInfoTuplet = [compiledTimePatterns, compiledDatePatterns, compiledDateTimePatterns,minYear, maxYear]
    return timeInfoTuplet

def readText(filename):
    try:
        f = open(filename, 'r')
        text = f.read()
        f.close()
        return text
    except Exception, e:
        print '*** Error reading file', filename, ':', e
        return ""

def compilePatterns(formats):
    compiledDict = {}
    for (k,format) in formats.items():
        #print '==========key=========',k
        #print str(format)
        #compiledDict[k] = (re.compile(format, re.I))
        compiledDict[k] = format
        #print compiledDict[k],'\n=============='
    return compiledDict



def multiline(sourcetype,transforms,props_conf,logfile):
    print '1.read file as follow:'
    print 'props_conf'
    log = open(logfile)
    print logfile,'===>>>open'


    print '\n\n\n2.读取props文件节的默认配置'
    sourcetype_stanza_props = props_conf['default']
    print sourcetype_stanza_props


    print '\n\n\n3.获得sourcetype所对应的props文件节的配置覆盖默认的配置'
    for (k,v) in props_conf[sourcetype].items():
        sourcetype_stanza_props[k] = v
    print props_conf[sourcetype],"\n===覆盖>>>result===>>>\n",sourcetype_stanza_props
    
    print '\n\n\n3.1获得sourcetype所对应transforms.conf转换后 的正则'
    sourcetype_re=generate_sourcetype_re(sourcetype,transforms,props_conf)
    print '========sourcetype_re=======\n',sourcetype_re 

    print '\n\n\n4.当SHOULD_LINEMERGE为true时，说明需要进行多行构建，否则不需要'
    event={"sourcetype":sourcetype,"_raw":""}
    multiline_re = r'(\d+:\d+:\d)'
    print '默认的时间戳正则:',multiline_re
    print 'SHOULD_LINEMERGE:',sourcetype_stanza_props['SHOULD_LINEMERGE']

    if strtobool(sourcetype_stanza_props['SHOULD_LINEMERGE']):
        print '判断多行构建的正则，如果存在BREAK_ONLY_BEFORE，就用它，没有就默认用BREAK_ONLY_BEFORE_DATE'
        print 'BREAK_ONLY_BEFORE:',sourcetype_stanza_props['BREAK_ONLY_BEFORE'],':在此冒号之前为值'

        if sourcetype_stanza_props['BREAK_ONLY_BEFORE']:
            print multiline_re,'===>>>',sourcetype_stanza_props['BREAK_ONLY_BEFORE']
            multiline_re = sourcetype_stanza_props['BREAK_ONLY_BEFORE']

        print '当LINE_BREAKER不存在时为默认的\\r\\n'
        print 'sourcetype_stanza_props.has_key("LINE_BREAKER"):',sourcetype_stanza_props.has_key("LINE_BREAKER")


        if not sourcetype_stanza_props.has_key("LINE_BREAKER"):
            linecount = 0
            count = 0
            print '单行读取进行多行event构建'

            for line in log:
                if re.search(multiline_re,line):
                    if linecount >= 1:
                        print '===============事件结束==============='
                        event['linecount'] = linecount
                        #print event
                        event={"sourcetype":sourcetype,"_raw":""}
                    linecount = 1
                    count = count + 1
                    event['_raw']=str(count)+'\t'+line
                    print '\n\n\n===============事件开始===============\n',event['_raw']

                else:
                    linecount = linecount + 1
                    count = count + 1
                    line = str(count)+'\t'+line
                    event['_raw']=event['_raw']+line
                    print "===========多行合并 " + str(linecount-1) +" 次===========\n"
                    print event['_raw']
            print '===============事件结束==============='

    else:
        print "不需要多行构建，一个LINE_BREAKER分割即为一个event"
        for line in log:
            event={"linecount":1,"sourcetype":sourcetype,"_raw":line}
            print event
        print "不需要多行构建，一个LINE_BREAKER分割即为一个event"

    log.close()
    print logfile,'===>>>close'


def list_all_source_type(source_types, props):
    _types = set()
    for k, d in props.items():
        if 'sourcetype' in d:
            s_name = d['sourcetype']
            if s_name:
                _types.add(s_name)

    for sname in _types:
        print sname


stanza_re = re.compile('\[\[([a-zA-z0-9\-:]*?)\]\]')

def processing_transform_stanza(transforms, transform_stanza, prefix=''):
    # see the description
    # http://docs.splunk.com/Documentation/Splunk/latest/Admin/Transformsconf

    if transform_stanza not in transforms:
        print 'transform %s not found' % transform_stanza
        exit(-1)
    transform_define = transforms[transform_stanza]
    regex_expr = transform_define['REGEX']
    #regex_expr = regex_expr.strip()
    print prefix, transform_stanza, ":", regex_expr
    # in regex, might have some macro.
    # use regex to strip them out
    stanza_set = set()
    for match in stanza_re.finditer(regex_expr):
        expr = match.group(1)
        toks = expr.split(':')
        expr_name = '_'
        if len(toks) == 1:
            stanza_name = toks[0]
        if len(toks) == 2:
            stanza_name, expr_name = toks
        if len(toks) > 2:
            print 'unknown stanze format %s'% expr
            exit(-1)

        stanza_set.add(stanza_name)
        print prefix, ' ', expr_name, '->', stanza_name
    if stanza_set:
        print prefix, '  -----------'
    for stanza in stanza_set:
        processing_transform_stanza(transforms, stanza, prefix=prefix+'  ')
    pass


def show_source_extract_plan(source_types, source_type, props, transforms):

    if source_type not in props:
        print 'source %s not found' % source_type
        exit(-1)
    # get the props
    # the format description see :
    #   http://docs.splunk.com/Documentation/Splunk/6.2.3/Admin/Propsconf
    print 'execute plan of %s' % source_type
    for k, v in props[source_type].items():
        if k.startswith('REPORT-'):
            # to report -> do somthing in transform
            # TRANSFORMS-<class> = <transform_stanza_name>, <transform_stanza_name2>,..
            # source -> transform_stanza_name -> transform_stanza_name2 -> result
            transform_stanza_list = v.split(',')
            transform_stanza_list.insert(0, '_raw')
            transform_stanza_list.append('result')
            print 'pipe:\t', ' -> '.join(transform_stanza_list)
            transform_stanza_list = v.split(',')
            for transform_stanza in transform_stanza_list:
                processing_transform_stanza(transforms, transform_stanza)
        # TODO: deal TRANSFORMS-
        if k.startswith('EXTRACT-'):
            # local extract
            # eg. EXTRACT-<class> = [<regex>|<regex> in <src_field>]
            rules = v.split(' in ')
            if rules > 1:
                reg_expr = rules[0]
                reg_field = rules[1]
            else:
                reg_expr = rules[0]
                reg_field = '_raw'
            print 'value:\t', reg_expr, '->', reg_field
        #print k, v
    pass


def extract(source_types, source_type, props, transforms, log_file):
    """
     1 compile to LUA code via jinja2 template
     2 execute the lua code, strip struct code.
    """
    if source_type not in props:
        print 'source %s not found' % source_type
        exit(-1)

    env = Environment(loader=FileSystemLoader('templates'))
    template = env.get_template('extract.jinja2.lua')
    # read the source type
    # read option value
    # ref: http://docs.splunk.com/Documentation/Splunk/6.2.2/Data/Indexmulti-lineevents
    # ref: https://answers.splunk.com/answers/338978/can-i-use-the-parameters-break-only-beforeddd-and-1.html
    # You cannot have both of these lines for a single input. Splunk will use one of them, but ignore the other.
    #  There will probably be a message in splunkd.log but that will be the only indication of the problem - except
    # for the fact that your events will not break the way you want!
    max_events = int(props[source_type].get('MAX_EVENTS', props['default'].get('MAX_EVENTS', 250)))
    line_merge = props[source_type].get('SHOULD_LINEMERGE', props['default'].get('SHOULD_LINEMERGE', 'True'))
    line_merge = strtobool(line_merge)
    line_breaker = props[source_type].get('LINE_BREAKER', props['default'].get('LINE_BREAKER', '([\\r\\n]+)'))
    default_line_breaker = line_breaker in ['([\\r\\n]+)', '[\\r\\n]+']

    """
        BREAK_ONLY_BEFORE_DATE | BREAK_ONLY_BEFORE | MUST_BREAK_AFTER | MUST_NOT_BREAK_AFTER | MUST_NOT_BREAK_BEFORE | MAX_EVENTS
        works only when SHOULD_LINEMERGE is true.

        TRUNCATE | LINE_BREAKER | LINE_BREAKER_LOOKBEHIND works all the time.
            1 break into lines
            2 line merge
    """
    #print '--------', line_breaker, (line_merge and True), line_merge
    #FIXME: escape regex-expr
    options = {
        'default_linebreaker': default_line_breaker,
        'custom_linebreaker': not default_line_breaker,
        'linebreaker_regex': line_breaker,
        'multiline': line_merge and True
    }
    #print options
    lua_code_generated = template.render(max_events=max_events, options=options)
    print lua_code_generated
    # write to ...
    fname = "_t.lua"
    with open(fname, 'w') as fh:
        fh.write(lua_code_generated)
    # do execute
    try:
        os.system("luajit %s < %s" % (fname, log_file))
    finally:
        #os.remove(fname)
        pass
    # remove the lua source.


if __name__ == '__main__':

    fpath = sys.argv[1]

    conf_path = os.path.join(fpath, 'system', 'default')
    fname_datatypebnf = os.path.join(conf_path, 'datatypesbnf.conf')
    fname_searchbnf = os.path.join(conf_path, 'searchbnf.conf')
    fname_sourcetype = os.path.join(conf_path, 'props_conf.conf')
    fname_props = os.path.join(conf_path, 'props.conf')
    fname_transform = os.path.join(conf_path, 'transforms.conf')

    # load
    if os.path.isfile(fname_searchbnf):
        #print fname_datatypebnf, os.path.exists(fname_datatypebnf)
        dt_bnf = spl_common.readConfFile(fname_datatypebnf)
        se_bnf = spl_common.readConfFile(fname_searchbnf)
        source_types = spl_common.readConfFile(fname_sourcetype)
        props = spl_common.readConfFile(fname_props)
        transforms = spl_common.readConfFile(fname_transform)
    else:
        print "can not read from config path %s " % fname_searchbnf
        exit(-1)

    if len(sys.argv) == 2:
        # <bin>, <conf_path> list all source type
        list_all_source_type(source_types, props)

    if len(sys.argv) == 3:
        # <bin>, <conf_path> <source_type>,  list the source type's execute plan
        source_type = sys.argv[2]
        show_source_extract_plan(source_types, source_type, props, transforms)

    if len(sys.argv) == 4:
        # <bin>, <conf_path> <source_type> <log_file>,  list the source type's execute plan
        source_type = sys.argv[2]
        log_file = sys.argv[3]
        select_method = raw_input("please select method(1.extract,2.multiline): ")
        if select_method == '1' or select_method == 'extract':
            extract(source_types, source_type, props, transforms, log_file)
        elif select_method == '2' or select_method == 'multiline':
            multiline(source_type,transforms,props,log_file)
        else:
            print 'please input: 1 | extract | 2 | multiline'

# end of file