#!/usr/bin/env luajit

local ffi = require('ffi')
local type = type
local tonumber = tonumber
local print = print

require('libpcre.pcre_header')

module(...)

L = ffi.load('pcre')

reg = '(?:^(?<clientip>(?:\\S+))\\s++(?<ident>(?:\\S+))\\s++(?<user>(?:\\S+))\\s++(?<req_time>(?:\\[(?:[^\\]]*+)\\]))\\s++(?:"\\s*+(?<method>(?:[^\\s"]++))?(?:\\s++(?<uri>(?<uri_>(?<domain0>\\w++:\\/\\/[^\\/\\s"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\"|[^\\s\\?\\/"])++)\\/++)?(?:(?:\\\\"|[^\\s\\?\\/"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?)(?:\\s++(?<version>(?:[^\\s"]++)))*)?\\s*+")\\s++(?<status>(?:\\S+))\\s++(?<bytes>(?:\\S+))(?:\\s++"(?<referer>(?<referer_>(?<domain>\\w++:\\/\\/[^\\/\\s"]++))?+[^"]*+)"(?:\\s++(?<useragent>(?:"(?:[^"]*+)"))(?:\\s++(?<cookie>(?:"(?:[^"]*+)")))?+)?+)?(?<other>(?:.*)))'
text = '113.96.151.228 - - [23/Mar/2015:15:07:19 +0800] "GET / HTTP/1.1" 302 20 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"'

local errptr = ffi.new('const char*[1]')
local intptr = ffi.new('int[1]')
local re = L.pcre_compile(reg, 0, errptr, intptr, nil)
n = 21
local size = (n + 1) * 3
local ovector = ffi.new('int['..size..']')
local re_stu = L.pcre_study(re, L.PCRE_STUDY_JIT_COMPILE, errptr)
local ret = {}
local st = n + 1 

function match(subject, regex)
  --print('re',re,'group_number:n',n,'size',size,'ovector',ovector)
  --st = L.pcre_exec(re, re_stu, subject, #subject, 0, 0, ovector, size)
  L.pcre_exec(re, re_stu, subject, #subject, 0, 0, ovector, size)
  --print('match_group_number:st',st)
  --L.pcre_free_study(re_stu)
  --L.pcre_free(re)
  for i=0, n*2, 2 do
    if ovector[i] >= 0 then
      --print('====:',ovector[i]+1, ovector[i+1])
      ret[i/2] = subject:sub(ovector[i]+1, ovector[i+1])
    end
  end
  return ret
end

function print_table( t )
    for k,v in pairs(t) do
        print(k,v)
    end
end


--t = match(text,reg)
--print_table(t)