# -*- coding: utf-8 -*-
"""
    测试　日志文件　解析

    用法
    １ 列出全部支持的　日志　source_type
    2  给定 source_type 列出数据抽取的流程
        eg.
            python t_extract.py etc access_combined

    3  给定 source_type　和　具体的日志文件
    
        extract方法 ：显示解析后的结果
        eg.
            python t_extract.py etc access_combined ../LogSample/apache/access_log
            # 测试 custom line-breaker & report-pipe
            python t_extract.py etc wmi ./samples/splunk-wmi.log
            # 测试 EXTRACT- REPORT-
            python t_extract.py etc ActiveDirectory ./samples/splunk-ad.log
            # 测试 TRANSFORMS via syslog
            单行:python t_extract.py etc access_combined samples/apache.log
            多行:python t_extract.py etc catalina samples/ANON-catalina.log

            multiline方法：多行event进行合并,并显示合并的过程和结果
            eg.
                单行:python t_extract.py etc access_combined samples/apache.log anonymizer/anonymizer-time.ini true
                多行:python t_extract.py etc catalina samples/ANON-catalina.log anonymizer/anonymizer-time.ini true

    4  配置文件的 override
        可以使用 类似 source::...a... 的方式，重载系统的默认配置， 在实践中, 应该有针对性的生成额外的处理函数

    5 获得时间戳正则
        eg.
                python      #进入命令行
                from t_extract import *
                from DateParser import _validateDate, _validateTime,_validateDateTime
                timeInfoTuplet = getTimeInfoTuplet('anonymizer/anonymizer-time.ini')
                text = '<5>Mar 23 15:24:01 mysql kernel: type=1400 audit(1427095441.779:115): avc:  denied  { name_connect } for  pid=1605 comm=72733A6D61696E20513A526567 dest=11514 scontext=system_u:system_r:syslogd_t:s0 tcontext=system_u:object_r:port_t:s0 tclass=tcp_socket'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '113.96.151.228 - - [23/Mar/2015:15:07:19 +0800] "GET / HTTP/1.1" 302 20 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '<188>2015-03-23 20:02:54 YunJiSuan_Fw_E1000E_02 %%01FIB/4/log_fib(l): -DevIP=192.168.60.9; FIB timer 272 timeout!'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '<156>Apr 12 2015 12:20:34 NFJD-SW1 %%01NTP/4/STRATUM_CHANGE(l): System stratum changes from 4 to 3 after clock update.'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '<189>: 2015 Apr 13 11:15:10 CST: %ETHPORT-5-SPEED: Interface Ethernet103/1/17, operational speed changed to 1 Gbps'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '<188>Mar 23 2015 08:45:46 Quidway %%01IFNET/4/IF_STATE(l)[143635]:Interface Ethernet0/0/13 has turned into DOWN state.'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '17-Aug-2015 16:12:14.997 INFO [Thread-41] com.duowan.yy.utility.ToolUtility.doGet 执行Get===>http://dcmnew.sysop.duowan.com//webservice/agentmaintencewebservice/sendEmail?applicationKey=openapi&id=743341'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '[2015-08-13 09:58:40.161259] I [rpcsvc.c:2142:rpcsvc_set_outstanding_rpc_limit] 0-rpc-service: Configured rpc.outstanding-rpc-limit with value 16'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '<154>: 2015 Apr 12 09:17:01 CST: last message repeated 4 times'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = 'Sep 13 00:10:02 ubuntu CRON[4240]: pam_unix(cron:session): session closed for user root'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)

                text = '13-Aug-2013 16:12:14.997 INFO [Thread-21] com.splunk.ip.utility.FxhfVbmvgtp.loRis 执行Get===>http://kurtis.denis.splunk.com//hermelinda/dqsxcnvlqruggckifigrewgd/roseMarie?gwjwsixwvrcXld=yolande&id=331211'
                matches = findAllDatesAndTimes(text, timeInfoTuplet)


"""
import os
import sys
import re
import spl_common
from distutils.util import strtobool
from jinja2 import Environment, FileSystemLoader
from DateParser import _validateDate, _validateTime,_validateDateTime

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

def generate_sourcetype_re(sourcetype,transforms,props_conf,debug=True):
    transforms_stanza = {}
    if debug:
        print '====sourcetype=====\n',sourcetype
        print '====props_conf[sourcetype]=====\n',props_conf[sourcetype]
    for k in props_conf[sourcetype].keys():
        if re.search('(?:TRANSFORMS-*|REPORT-*|EXTRACT-*)',k):
            transforms_stanza[k]=transforms['default']
            for (ke,va) in transforms[props_conf[sourcetype][k]].items():
                transforms_stanza[k][ke] = va
            transforms_stanza[k]['REGEX']=pcre_parse(props_conf[sourcetype][k],transforms)
    return transforms_stanza


def findAllDatesAndTimes(text, timeInfoTuplet):
    global today, _MIN_YEAR, _MAX_YEAR
    timeExpressions = timeInfoTuplet[0]
    dateExpressions = timeInfoTuplet[1]
    datetimeExpressions = timeInfoTuplet[2]
    matches = getMatches(text, timeExpressions, _validateTime)
    if not matches:
        print 'bad time,please check'
        exit()
    datematches = getMatches(text, dateExpressions, _validateDate)
    if datematches:
        matches.extend(datematches)
    else:
        print 'bad date,please check'
        exit()
    datetimematches = getAllMatches(text, datetimeExpressions, _validateDateTime,matches)
    if datetimematches:
        matches.extend(datetimematches)
    return matches


def getAllMatches(text, expressions, validator,matches):
    index = -1
    extract_list = list()
    for k,expression in expressions.items():
        index += 1
        match = re.search(expression,text)
        if match:
            values = match.groupdict()
            timevalues = match.group()
            extractions = validator(values)
            if extractions and values.get('year') == matches[4]['year'] and values.get('hour')==matches[1]['hour']:
                # DC: WE HAVE A VALID MATCH, AND IT WASN'T THE FIRST EXPRESSION,
                # MAKE THIS PATTERN THE FIRST ONE TRIED FROM NOW ON
                extract_list = [timevalues,values,{k:expression}]
                #if index > 0:
                #    expressions.insert(0, expressions.pop(index))
                return extract_list

def getMatches(text, expressions, validator):
    index = -1
    extract_list = list()
    for k,expression in expressions.items():
        index += 1
        match = re.search(expression,text)
        if match:
            values = match.groupdict()
            timevalues = match.group()
            extractions = validator(values)
            if extractions:
                # DC: WE HAVE A VALID MATCH, AND IT WASN'T THE FIRST EXPRESSION,
                # MAKE THIS PATTERN THE FIRST ONE TRIED FROM NOW ON
                extract_list = [timevalues,values,{k:expression}]
                #if index > 0:
                #    expressions.insert(0, expressions.pop(index))
                return extract_list


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


def multiline(sourcetype,transforms,props_conf,logfile,timestampconffilename,debug=True):
    if debug:
        print '1.read file as follow:'
        print 'props_conf'
    log = open(logfile)
    if debug:
        print logfile,'===>>>open'


        print '\n\n\n2.读取props文件节的默认配置'
    sourcetype_stanza_props = props_conf['default']
    if debug:
        print sourcetype_stanza_props


        print '\n\n\n3.获得sourcetype所对应的props文件节的配置覆盖默认的配置'
    for (k,v) in props_conf[sourcetype].items():
        sourcetype_stanza_props[k] = v
    if debug:
        print props_conf[sourcetype],"\n===覆盖>>>result===>>>\n",sourcetype_stanza_props
    
        print '\n\n\n3.1获得sourcetype所对应transforms.conf转换后 的正则'
    sourcetype_re=generate_sourcetype_re(sourcetype,transforms,props_conf,debug)
    if debug:
        print '========sourcetype_re=======\n',sourcetype_re 

        print '\n\n\n4.当SHOULD_LINEMERGE为true时，说明需要进行多行构建，否则不需要'
    event={"sourcetype":sourcetype,"_raw":""}
    f = open(logfile)
    text = f.readline()
    f.close()
    timeInfoTuplet = getTimeInfoTuplet(timestampconffilename)
    matches = findAllDatesAndTimes(text, timeInfoTuplet)
    multiline_re = matches[8].values()[0]
    if debug:
        print '默认的时间戳正则:',multiline_re
        print 'SHOULD_LINEMERGE:',sourcetype_stanza_props['SHOULD_LINEMERGE']

    if strtobool(sourcetype_stanza_props['SHOULD_LINEMERGE']):
        if debug:
            print '判断多行构建的正则，如果存在BREAK_ONLY_BEFORE，就用它，没有就默认用BREAK_ONLY_BEFORE_DATE'
            print 'BREAK_ONLY_BEFORE:',sourcetype_stanza_props['BREAK_ONLY_BEFORE'],':在此冒号之前为值'

        if sourcetype_stanza_props['BREAK_ONLY_BEFORE']:
            if debug:
                print multiline_re,'===>>>',sourcetype_stanza_props['BREAK_ONLY_BEFORE']
            multiline_re = sourcetype_stanza_props['BREAK_ONLY_BEFORE']

        if debug:
            print '当LINE_BREAKER不存在时为默认的\\r\\n'
            print 'sourcetype_stanza_props.has_key("LINE_BREAKER"):',sourcetype_stanza_props.has_key("LINE_BREAKER")


        if not sourcetype_stanza_props.has_key("LINE_BREAKER"):
            linecount = 0
            count = 0
            if debug:
                print '单行读取进行多行event构建'

            for line in log:
                if re.search(multiline_re,line):
                    if linecount >= 1:
                        if debug:
                            print '===============事件结束==============='
                        event['linecount'] = linecount
                        print event
                        event={"sourcetype":sourcetype,"_raw":""}
                    linecount = 1
                    count = count + 1
                    event['_raw']=str(count)+'\t'+line
                    if debug:
                        print '\n\n\n===============事件开始===============\n',event['_raw']

                else:
                    linecount = linecount + 1
                    count = count + 1
                    line = str(count)+'\t'+line
                    event['_raw']=event['_raw']+line
                    if debug:
                        print "===========多行合并 " + str(linecount-1) +" 次===========\n"
                        print event['_raw']
            if debug:
                print '===============事件结束==============='

    else:
        if debug:
            print "不需要多行构建，一个LINE_BREAKER分割即为一个event"
        for line in log:
            event={"linecount":1,"sourcetype":sourcetype,"_raw":line}
            print event
        if debug:
            print "不需要多行构建，一个LINE_BREAKER分割即为一个event"

    log.close()
    if debug:
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

        if k.startswith('TRANSFORMS-'):
            # to report -> do somthing in transform
            # TRANSFORMS-<class> = <transform_stanza_name>, <transform_stanza_name2>,..
            # source -> transform_stanza_name -> transform_stanza_name2 -> result
            transform_stanza_list = v.split(',')
            transform_stanza_list.insert(0, '_raw')
            transform_stanza_list.append('result')
            print 'transform:\t', ' -> '.join(transform_stanza_list)
            transform_stanza_list = v.split(',')
            for transform_stanza in transform_stanza_list:
                processing_transform_stanza(transforms, transform_stanza)

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


def build_regex_expr(meta_re_expr, props, transforms):
    pass


class DataProcessor(object):
    """
        - 加载数据的处理流程
    """
    def __init__(self, props, transforms):
        self._props = props
        self._transforms = transforms
        self.step_reports = []
        self.step_transform = []
        self.step_extract = []

    def add_report(self, step_name):
        self.step_reports.append(step_name)

    def add_transform(self, step_name):
        self.step_transform.append(step_name)

    def add_extract(self, step_name):
        self.step_extract.append(step_name)

    def get_normal_name(self, name):
        new_name = []
        for c in name:
            if ord(c) in range(ord('a'), ord('z')) or c in range(ord('A'), ord('Z')) or c in range(ord('0'), ord('9')):
                new_name.append(c)
            else:
                new_name.append('_')
        return ''.join(new_name)

    def get_full_regex(self, step_name):
        """
            取得当前表达式的完整形式， 以及包括的 named_group
        """

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
    #line_breaker = line_breaker.replace('\\', "\\\\")
    options = {
        'default_linebreaker': default_line_breaker,
        'custom_linebreaker': not default_line_breaker,
        'linebreaker_regex': line_breaker,
        'multiline': line_merge and True
    }
    # load processor
    processor = DataProcessor(props, transforms)
    for k, v in props[source_type].items():
        if k.startswith('REPORT-'):
            # to report -> do somthing in transform
            # REPORT-<class> = <transform_stanza_name>, <transform_stanza_name2>,..
            # source -> transform_stanza_name -> transform_stanza_name2 -> result
            transform_stanza_list = v.split(',')
            for transform_stanza in transform_stanza_list:
                processor.add_report(transform_stanza)
                #processing_transform_stanza(transforms, transform_stanza)

        if k.startswith('TRANSFORMS-'):
            # to report -> do somthing in transform
            # TRANSFORMS-<class> = <transform_stanza_name>, <transform_stanza_name2>,..
            # source -> transform_stanza_name -> transform_stanza_name2 -> result
            transform_stanza_list = v.split(',')
            for transform_stanza in transform_stanza_list:
                processor.add_transform(transform_stanza)
            #    processing_transform_stanza(transforms, transform_stanza)

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
            # TODO: deal -extract
            print 'value:\t', reg_expr, '->', reg_field

    # do execute
    lua_code_generated = template.render(processor=processor, max_events=max_events, options=options)
    print lua_code_generated
    # write to ...
    fname = "_t.lua"
    with open(fname, 'w') as fh:
        fh.write(lua_code_generated)

    try:
        os.system("luajit %s %s" % (fname, log_file))
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
        extract(source_types, source_type, props, transforms, log_file)

    if len(sys.argv) >= 5:
        source_type = sys.argv[2]
        log_file = sys.argv[3]
        timestampconffilename = sys.argv[4]
        if sys.argv[5]:
            debug = strtobool(sys.argv[5])
        else:
            debug = True
        multiline(source_type,transforms,props,log_file,timestampconffilename,debug)
# end of file