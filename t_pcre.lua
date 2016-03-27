rex_pcre = require "rex_pcre"

print( rex_pcre.new("[0-9]+"):exec("1234") )
print( rex_pcre.new("\\d+"):exec("hello1234") )
print( rex_pcre.new("([\r\n]+---splunk-wmi-end-of-event---\r\n[\r\n]*)"):exec("Timestamp_Object=NULL\r\nTimestamp_PerfTime=NULL\r\nTimestamp_Sys100NS=NULL\r\nwmi_type=unspecified\r\n---splunk-wmi-end-of-event---\r\n\r\n"))