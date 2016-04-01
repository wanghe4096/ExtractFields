local rex_pcre = require "rex_pcre"

sourcetype = 'access_combined'
local full_props = {}
{% for k,d in processor.full_props.items() %}
full_props['{{k.replace('\\','\\\\')}}'] = {}
{% for kd,vd in d.items() %}
full_props['{{k.replace('\\','\\\\')}}']['{{kd.replace('\\','\\\\')}}'] = '{{vd.replace('\\','\\\\')}}'
{% endfor %}
{% endfor %}

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function generate_sourcetype_re( sourcetype,full_props)
    sourcetype_stanza = full_props[sourcetype]
    sourcetype_re = {}
    for k,v in pairs(sourcetype_stanza) do
        if string.starts(k,'REPORT') and k ~= '' then
            sourcetype_re[sourcetype_stanza['namegroup-REPORT']] = v
        end
        if string.starts(k,'TRANSFORMS') and k ~= '' then
            sourcetype_re[sourcetype_stanza['namegroup-TRANSFORMS']] = v
        end
    end
    return sourcetype_re
end

line = '113.96.151.228 - - [23/Mar/2015:15:07:30 +0800] "GET /drupal7/sites/default/files/css/css_tvjLXeiJa667A1Ha2T2SVo0fKFy5Eiy6QNovxfdLlpI.css HTTP/1.1" 200 4830 "http://221.176.36.22/drupal7/?q=comment/511" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"'

function extract_event( sourcetype_re,line )
    namegroup = {}
    for k,v in pairs(sourcetype_re) do
        count = 0
        group={rex_pcre.new(v):match(line)}
        for w in string.gmatch(k,"([^',']+)") do
            count = count+1
            namegroup[w]=group[count]
        end
    end
    return namegroup
end

function print_table( t )
    for k,v in pairs(t) do
        print(k,v)
    end
end

sourcetype_re = generate_sourcetype_re( sourcetype,full_props)
local logfile = arg[1]
local f = io.open(logfile,'r')
assert(f)
print('===================lua script exec begin===================')
for line in f:lines() do
    namegroup = extract_event( sourcetype_re,line )
    print('=========namegroup begin=========')
    print_table(namegroup)
    print('=========namegroup end=========')
end
print('=====================lua script exec finish=======================')

