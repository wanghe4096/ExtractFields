# -*- coding: utf-8 -*-
"""
1.EXTRACT- how to parse
2.some regex deal with format

执行:
    python generate_lua.py access_combined samples/apache

rex_pcre = require "rex_pcre"
re = '(?:^(?<clientip>(?:\\S+))\\s++(?<ident>(?:\\S+))\\s++(?<user>(?:\\S+))\\s++(?<req_time>(?:\\[(?:[^\\]]*+)\\]))\\s++(?:"\\s*+(?<method>(?:[^\\s"]++))?(?:\\s++(?<uri>(?<uri_>(?<domain0>\\w++:\\/\\/[^\\/\\s"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\"|[^\\s\\?\\/"])++)\\/++)?(?:(?:\\\\"|[^\\s\\?\\/"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?)(?:\\s++(?<version>(?:[^\\s"]++)))*)?\\s*+")\\s++(?<status>(?:\\S+))\\s++(?<bytes>(?:\\S+))(?:\\s++"(?<referer>(?<referer_>(?<domain>\\w++:\\/\\/[^\\/\\s"]++))?+[^"]*+)"(?:\\s++(?<useragent>(?:"(?:[^"]*+)"))(?:\\s++(?<cookie>(?:"(?:[^"]*+)")))?+)?+)?(?<other>(?:.*)))'
b = '113.96.151.228 - - [23/Mar/2015:15:07:30 +0800] "GET /drupal7/sites/default/files/css/css_tvjLXeiJa667A1Ha2T2SVo0fKFy5Eiy6QNovxfdLlpI.css HTTP/1.1" 200 4830 "http://221.176.36.22/drupal7/?q=comment/511" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"'
clientip,ident,user,req_time,method,uri,uri_,domain0,uri_path,root,file,uri_query,version,status,bytes,referer,referer_,domain,useragent,cookie,other = rex_pcre.new(re):match(b)

"""
import os
import sys
import re
import spl_common,pcre,pygrok
from distutils.util import strtobool
from jinja2 import Environment, FileSystemLoader
from DateParser import _validateDate, _validateTime,_validateDateTime

def extract_event(transforms_stanza,event={}):
    final_event = event
    for (key,val) in transforms_stanza.items():                       ###############source key################
        if key.startswith('TRANSFORMS'):                     ###############FORMAT###############
            middle_event = spl_match(event['_raw'],val['REGEX'])
        elif key.startswith('REPORT'):
            middle_event = spl_match(event['_raw'],val['REGEX'])
        else:
            middle_event = spl_match(event['_raw'],val['REGEX'])
        if middle_event is None:
            middle_event = event
            middle_event['error'] = 'the part of event can not parse,please check the raw log'
        else:
            for (k,v) in middle_event.items():
                final_event[k] = v

    print final_event

def spl_match(line='',pattern=''):
    if re.search('(?:\?P\<(.*?)\>|\%\{(.*?)\})',pattern):
        return pygrok.grok_match(line,pattern)
    else:
        m = pcre.search(pattern,line)
        return m.groupdict() if m is not None else None

def pcre_subparse(vl,l={}):
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
        if d.has_key('REGEX'):
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
        else:
            l[k] = ''
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

    if result:
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



def generate_sourcetype_re(sourcetype,transforms,props_conf,debug=False):
    transforms_stanza = {}
    if debug:
        print '====sourcetype=====\n',sourcetype
        print '====props_conf[sourcetype]=====\n',props_conf[sourcetype]
    for k in props_conf[sourcetype].keys():
        if re.search('(?:TRANSFORMS-*|REPORT-*|EXTRACT-*)',k):
            #transforms_stanza[k]=props_conf[sourcetype][k].split(',')
            #for i in len(transforms_stanza[k]):
            transforms_stanza[k]=transforms['default']
            for (ke,va) in transforms[props_conf[sourcetype][k]].items():
                transforms_stanza[k][ke] = va
            transforms_stanza[k]['REGEX']=pcre_parse(props_conf[sourcetype][k],transforms)
    return transforms_stanza


def findAllDatesAndTimes(text, timeInfoTuplet,debug=False):
    global today, _MIN_YEAR, _MAX_YEAR
    timeExpressions = timeInfoTuplet[0]
    dateExpressions = timeInfoTuplet[1]
    datetimeExpressions = timeInfoTuplet[2]
    if debug:
        print '====timematches begin===='
    timematches = getTimeMatches(text, timeExpressions, _validateTime,debug)
    if not timematches:
        print 'bad time,please check'
        exit(-1)
    if debug:
        print '====datematches begin===='
    datematches = getDateMatches(text, dateExpressions, _validateDate,debug)
    if not datematches:
        print 'bad date,please check'
        exit(-1)
    if debug:
        print '====datetimematches begin===='
    datetimematches = getAllMatches(text, datetimeExpressions, _validateDateTime,timematches,datematches,debug)
    if not datetimematches:
        print 'bad datetime,please check'
    matches = [timematches,datematches,datetimematches]
    return matches


def getAllMatches(text, expressions, validator,timematches,datematches,debug=False):
    index = -1
    extract_list = list()
    for k,expression in expressions.items():
        index += 1
        match = re.search(expression,text)
        if debug:
            print index,'=='+k+'==match.group():'
            print index,'=='+k+'==match.groupdict():'
        if match:
            values = match.groupdict()
            timevalues = match.group()
            if debug:
                print '===timevalues====',timevalues
                print '=====values=====',values

            extractions = validator(values)
            if extractions and values.get('year') == datematches[1]['year'] and values.get('hour')==timematches[1]['hour']:
                extract_list = [timevalues,values,{k:expression}]
                return extract_list
    print 'no regex match,please check datetime of the logfile or datetime regex'
    return ['',{'year':None,'month':None,'day':None,'hour':None,'minute':None,'second':None},{'regex':None}]

def getTimeMatches(text, expressions, validator,debug=False):
    index = -1
    extract_list = list()
    for k,expression in expressions.items():
        index += 1
        match = re.search(expression,text)
        if debug:
            print index,'=='+k+'==match.group():'
            print index,'=='+k+'==match.groupdict():'
        if match:
            values = match.groupdict()
            timevalues = match.group()
            if debug:
                print '===timevalues====',timevalues
                print '=====values=====',values

            if timevalues:
                extractions = validator(values)
                if extractions:
                    extract_list = [timevalues,values,{k:expression}]
                    return extract_list
            else:
                extract_list = [timevalues,values,{k:expression}]
                return extract_list

    print 'no regex match,please check time of the logfile'
    return ['',{'hour':None,'minute':None,'second':None},{'regex':None}]


def getDateMatches(text, expressions, validator,debug=False):
    index = -1
    extract_list = list()
    for k,expression in expressions.items():
        index += 1
        match = re.search(expression,text)
        if debug:
            print index,'=='+k+'==match.group():'
            print index,'=='+k+'==match.groupdict():'
        if match:
            values = match.groupdict()
            timevalues = match.group()
            if debug:
                print '===timevalues====',timevalues
                print '=====values=====',values

            if timevalues:
                extractions = validator(values)
                if extractions:
                    extract_list = [timevalues,values,{k:expression}]
                    return extract_list
            else:
                extract_list = [timevalues,values,{k:expression}]
                return extract_list

    print 'no regex match,please check date or time of the logfile'
    return ['',{'year':None,'month':None,'day':None},{'regex':None}]


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

def writeText(filename, text):
    try:
        f = open(filename, 'w')
        f.write(text)
        f.close()
    except Exception, e:
        print '*** Error writing file', filename, ':', e

def compilePatterns(formats):
    compiledDict = {}
    for (k,format) in formats.items():
        #print '==========key=========',k
        #print str(format)
        #compiledDict[k] = (re.compile(format, re.I))
        compiledDict[k] = format
        #print compiledDict[k],'\n=============='
    return compiledDict


def multiline(sourcetype,transforms,props_conf,logfile,timestampconffilename,debug=False):
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
    matches = findAllDatesAndTimes(text, timeInfoTuplet,debug)
    multiline_re = matches[2][2].values()[0]
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
                        if debug:
                            print '=======event=====\n',event
                            print '=======final_event======='
                        extract_event(sourcetype_re,event)
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
            if debug:
                print '=======event=====\n',event
                print '=======final_event======='
            extract_event(sourcetype_re,event)

        if debug:
            print "不需要多行构建，一个LINE_BREAKER分割即为一个event"

    log.close()
    if debug:
        print logfile,'===>>>close'

stanza_re = re.compile('\[\[([a-zA-z0-9\-:]*?)\]\]')

def build_normal_regex(regex_expr, transforms, name_group_prefix=''):
    """
        convert to normal regex via transform rules
    """
    rv = regex_expr
    convert_map = {}
    for match in stanza_re.finditer(regex_expr):
        #print match, dir(match)
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

        if True:
            transform_define = transforms[stanza_name]
            regex_expr = transform_define['REGEX']
            if expr_name == '_':
                regex_prefix = name_group_prefix
            else:
                if name_group_prefix:
                    regex_prefix = name_group_prefix + "_" + expr_name + "_"
                else:
                    regex_prefix = expr_name + "_"

            regex_normal_expr = build_normal_regex(regex_expr, transforms, regex_prefix)

            # add name_group_prefix if there is one
            # print '0000', name_group_prefix, expr_name
            regex_normal_expr = re.sub(r'\?\<(\w+)\>', r'?<%s\1>' % regex_prefix, regex_normal_expr)
            # check is named or not
            if expr_name == '_':
                convert_map[expr] = "(?:%s)" % regex_normal_expr
            else:
                # if there is a ?<> should do a replacement
                if regex_normal_expr.find('?<>') != -1:
                    convert_map[expr] = regex_normal_expr.replace('?<>', "?<%s>" % expr_name)
                else:
                    convert_map[expr] = "(?<%s>%s)" % (expr_name, regex_normal_expr)

    # do replace
    for k, v in convert_map.items():
        #print rv, '....>'
        rv = rv.replace("[[%s]]" % k, v)
        #print rv
    #print regex_expr, '0-0000'
    return rv

class DataProcessor(object):
    """
        - 加载数据的处理流程
    """
    def __init__(self, props, transforms):
        self.props = props
        self.transforms = transforms
        self.full_props = generate_full_props(props,transforms)

def generate_full_props(props,transforms):
    full_props = dict(props)
    for sourcetype_stanza,att_values in props.items():
        for k,v in att_values.items():
            if k.startswith('REPORT') and v:
                transform_stanza_list = v.split(',')
                transform_stanza_list_re = list()
                for transform_stanza in transform_stanza_list:
                    transform_stanza_list_re.append(pcre_parse(transform_stanza.strip(),transforms))
                full_props[sourcetype_stanza][k] = ''.join(transform_stanza_list_re)
                namegroup = re.findall('\?\<(.*?)\>',''.join(transform_stanza_list_re))
                if namegroup:
                    full_props[sourcetype_stanza]['namegroup-REPORT']= ','.join(namegroup)
                else:
                    full_props[sourcetype_stanza]['namegroup-REPORT']=''


            if k.startswith('TRANSFORMS') and v:
                transform_stanza_list = v.split(',')
                transform_stanza_list_re = list()
                for transform_stanza in transform_stanza_list:
                    transform_stanza_list_re.append(pcre_parse(transform_stanza.strip(),transforms))
                full_props[sourcetype_stanza][k] = ''.join(transform_stanza_list_re)
                namegroup = re.findall('\?\<(.*?)\>',''.join(transform_stanza_list_re))
                if namegroup:
                    full_props[sourcetype_stanza]['namegroup-TRANSFORMS']=','.join(namegroup)
                else:
                    full_props[sourcetype_stanza]['namegroup-TRANSFORMS']=''
    return full_props

def extract( source_type, props, transforms, log_file):
    """
     1 compile to LUA code via jinja2 template
     2 execute the lua code, strip struct code.
    """
    if source_type not in props:
        print 'source %s not found' % source_type
        exit(-1)

    env = Environment(loader=FileSystemLoader('templates'))
    template = env.get_template('generate_extract.jinja2.lua')
    # load processor
    processor = DataProcessor(props, transforms)
    # do execute
    lua_code_generated = template.render(processor=processor)
    print lua_code_generated
    # write to ...
    fname = "generate_lua_extract_line.lua"
    writeText(fname, lua_code_generated)

    try:
        os.system("luajit %s %s" % (fname, log_file))
    finally:
        #os.remove(fname)
        pass
    # remove the lua source.


conf_path = os.path.join('etc', 'system', 'default')
fname_props = os.path.join(conf_path, 'props.conf')
fname_transform = os.path.join(conf_path, 'transforms.conf')

props = spl_common.readConfFile(fname_props)
transforms = spl_common.readConfFile(fname_transform)
timestampconffilename = 'anonymizer/anonymizer-time.ini'

if __name__ == '__main__':

    if len(sys.argv) == 3:
        source_type = sys.argv[1]
        log_file = sys.argv[2]
        extract(source_type, props, transforms, log_file)
    else:
        print '<bin> <source_type> <logfile>'

        #multiline(source_type,transforms,props,log_file,timestampconffilename,debug=False)
# end of file
