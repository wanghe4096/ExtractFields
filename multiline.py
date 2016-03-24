#encoding=utf-8

#    start:
#         python multiline.py


import spl_common,re
#-- TODO: 一. data stream coming,multiline process
#		已知sourcetype
def multiline():
    sourcetype="catalina"
    print '1.read file as follow:'
    props_file = "etc/system/default/props.conf"
    props_conf = spl_common.readConfFile(props_file)
    print props_file,"===>>>",'props_conf'
    #logfile = '../LogSample/apache/access_log'
    logfile = '/home/candy/source/fieldExtract/samples/catalina'
    log = open(logfile)
    print logfile,'===>>>open'
    print '2.读取props文件节的默认配置'
    sourcetype_stanza_props = props_conf['default']
    print sourcetype_stanza_props
    print '3.获得sourcetype所对应的props文件节的配置覆盖默认的配置'
    for (k,v) in props_conf[sourcetype].items():
        sourcetype_stanza_props[k] = v
    print props_conf[sourcetype],"\n===覆盖>>>result===>>>\n",sourcetype_stanza_props
    print '4.当SHOULD_LINEMERGE为true时，说明需要进行多行构建，否则不需要'
    event={"sourcetype":sourcetype,"_raw":""}
    multiline_re = r'(\d+:\d+:\d)'
    print '默认的时间戳正则:',multiline_re
    print 'SHOULD_LINEMERGE:',sourcetype_stanza_props['SHOULD_LINEMERGE']
    if sourcetype_stanza_props['SHOULD_LINEMERGE']=='true':
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
                        print '事件结束'
                        event['linecount'] = linecount
                        #print event
                        event={"sourcetype":sourcetype,"_raw":""}
                    linecount = 1
                    count = count + 1
                    event['_raw']=str(count)+'\t'+line
                    print '事件开始:\n',event['_raw']
                else:
                    linecount = linecount + 1
                    count = count + 1
                    line = str(count)+'\t'+line
                    event['_raw']=event['_raw']+line
                    print event['_raw']
    else:
    	print "不需要多行构建，一个LINE_BREAKER分割即为一个event"
    	for line in log:
    	    event={"linecount":1,"sourcetype":sourcetype,"_raw":line}
    	    print event
    	print "不需要多行构建，一个LINE_BREAKER分割即为一个event"
    log.close()
    print logfile,'===>>>close'

if __name__ == '__main__':
	multiline()

#-- TODO: 2 feed data line by line, and put it into a buffer

#-- TODO: 3 do extractor
