
--49444250/104.022794008=475321.30310014
--49444250/125.411713839=394255.4366450579
local rex_pcre = require "rex_pcre"
require('dateparse.DateParse')
local ffi = require('ffi')
local pcre = ffi.load('pcre')
local splunkd_access = {}
splunkd_access.namestype = {flag='true',description='please input the type of fields as follows,after you can input flag to true'}
-- build series transform | report | extract
-- report

splunkd_access.source_key_tab = {}
splunkd_access.source_key_names = {}
local reg = ''
local cn = 0
local n = 0
local n_tab = {}
local re = nil
local re_tab = {}
local size =  nil
local size_tab = {}
local ovector = nil
local ovector_tab = {}
local re_stu = nil
local re_stu_tab = {}


--local event_report_access_extractions_re = rex_pcre.new("^(?<clientip>\\S+)\\s++(?<ident>\\S+)\\s++(?<user>\\S+)\\s++\\[(?<req_time>[^\\]]*+)\\]\\s++(?:\"\\s*+(?<method>[^\\s\"]++)?(?:\\s++(?:(?<uri>(?<uri_>(?<uri__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\\"|[^\\s\\?\\/\"])++)\\/++)?(?:(?:\\\\\"|[^\\s\\?\\/\"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?))(?:\\s++(?<version>[^\\s\"]++))*)?\\s*+\")\\s++(?<status>\\S+)\\s++(?<bytes>\\S+)(?:\\s++\"(?<referer>(?<referer_>(?<referer__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+[^\"]*+)\"(?:\\s++\"(?<useragent>[^\"]*+)\"(?:\\s++\"(?<cookie>[^\"]*+)\")?+)?+)?(?<other>.*)")
--function event_report_access_extractions(new_event)

--end
cn = cn + 1
splunkd_access.source_key_tab[cn] = "_raw"
splunkd_access.source_key_names[cn] = {'clientip','ident','user','req_time','method','uri','uri_','uri__domain','uri_path','root','file','uri_query','version','status','bytes','referer','referer_','referer__domain','useragent','cookie','other'}

reg = "^(?<clientip>\\S+)\\s++(?<ident>\\S+)\\s++(?<user>\\S+)\\s++\\[(?<req_time>[^\\]]*+)\\]\\s++(?:\"\\s*+(?<method>[^\\s\"]++)?(?:\\s++(?:(?<uri>(?<uri_>(?<uri__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\\"|[^\\s\\?\\/\"])++)\\/++)?(?:(?:\\\\\"|[^\\s\\?\\/\"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?))(?:\\s++(?<version>[^\\s\"]++))*)?\\s*+\")\\s++(?<status>\\S+)\\s++(?<bytes>\\S+)(?:\\s++\"(?<referer>(?<referer_>(?<referer__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+[^\"]*+)\"(?:\\s++\"(?<useragent>[^\"]*+)\"(?:\\s++\"(?<cookie>[^\"]*+)\")?+)?+)?(?<other>.*)"
local errptr_access_extractions = ffi.new('const char*[1]')
local intptr_access_extractions = ffi.new('int[1]')

n = 21
size = (n + 1) * 3
ovector = ffi.new('int['..size..']')
re = pcre.pcre_compile(reg, 0, errptr_access_extractions, intptr_access_extractions, nil)
re_stu = pcre.pcre_study(re, pcre.PCRE_STUDY_JIT_COMPILE, errptr_access_extractions)

n_tab[cn] = n
size_tab[cn] = size
ovector_tab[cn] = ovector
re_tab[cn] = re
re_stu_tab[cn] = re_stu


--local reg = "^(?<clientip>\\S+)\\s++(?<ident>\\S+)\\s++(?<user>\\S+)\\s++\\[(?<req_time>[^\\]]*+)\\]\\s++(?:\"\\s*+(?<method>[^\\s\"]++)?(?:\\s++(?:(?<uri>(?<uri_>(?<uri__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\\"|[^\\s\\?\\/\"])++)\\/++)?(?:(?:\\\\\"|[^\\s\\?\\/\"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?))(?:\\s++(?<version>[^\\s\"]++))*)?\\s*+\")\\s++(?<status>\\S+)\\s++(?<bytes>\\S+)(?:\\s++\"(?<referer>(?<referer_>(?<referer__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+[^\"]*+)\"(?:\\s++\"(?<useragent>[^\"]*+)\"(?:\\s++\"(?<cookie>[^\"]*+)\")?+)?+)?(?<other>.*)"
--splunkd_access.names = {'clientip','ident','user','req_time','method','uri','uri_','uri__domain','uri_path','root','file','uri_query','version','status','bytes','referer','referer_','referer__domain','useragent','cookie','other'}
--local n = 21



--local event_report_extract_spent_re = rex_pcre.new("(?P<spent>\\d+)ms$")
--function event_report_extract_spent(new_event)

--end
cn = cn + 1
splunkd_access.source_key_tab[cn] = "_raw"
splunkd_access.source_key_names[cn] = {}

reg = "(?P<spent>\\d+)ms$"
local errptr_extract_spent = ffi.new('const char*[1]')
local intptr_extract_spent = ffi.new('int[1]')

n = 1
size = (n + 1) * 3
ovector = ffi.new('int['..size..']')
re = pcre.pcre_compile(reg, 0, errptr_extract_spent, intptr_extract_spent, nil)
re_stu = pcre.pcre_study(re, pcre.PCRE_STUDY_JIT_COMPILE, errptr_extract_spent)

n_tab[cn] = n
size_tab[cn] = size
ovector_tab[cn] = ovector
re_tab[cn] = re
re_stu_tab[cn] = re_stu


--local reg = "(?P<spent>\\d+)ms$"
--splunkd_access.names = {}
--local n = 1



-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor

if not reg then
    reg = ''
end

if not splunkd_access.names then
    splunkd_access.names = {}
end

if not n then
    n = 0
end

local result = nil
local count = nil
local i = nil
local nexti = nil
local line_data = nil

local linecount = 0
local event = ''
local events = nil
local multiline = nil
local match_fail = {}
match_fail.event = {}
match_fail.time = {}



-- default single line, use [\r\n]
local DefaultLineBreakerFeed = {
    delimiter = nil,    -- detected delimiter, default nil, might be [\r\n | \n]
    line_data = nil     -- only a small mount data <- buffer
}

function DefaultLineBreakerFeed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end



function DefaultLineBreakerFeed:new_event(event_lines, b, e)
    local a = nil
    for k,v in pairs(re_tab) do
        print('===' .. k .. '===')
        print(v,re_stu_tab[k],ovector_tab[k],size_tab[k],n_tab[k])
        a = match(event_lines:sub(b, e),v,re_stu_tab[k],ovector_tab[k],size_tab[k],n_tab[k])
        print_table(a)
    end
    --[[
    events = {}
    events.time = getAllMatches(event_lines:sub(b,e))
    events.event = match(event_lines:sub(b, e))
    if not events.event then
        print('fail match event:',event_lines:sub(b, e))
        table.insert(match_fail.event,event_lines:sub(b, e))
        events = nil
    elseif not events.time then
        print('fail match time:',event_lines:sub(b, e))
        table.insert(match_fail.time,event_lines:sub(b, e))
        events = nil
    end
    if events then
        print('===events.time===')
        print_table(events.time)
        print('===events.event===')
        print_table(events.event)
    end
]]
    return events
end

function DefaultLineBreakerFeed:feed(data)
    result = {}
    count = 0
    i = 0
    nexti = 0
    while true do
        nexti = data:find("\n", i+1)  
        if nexti == nil then
            self.line_data = data:sub(i+1) 
            break
        end

        if data:byte(nexti-1) == 13 then
            if self.line_data ~= nil then
                line_data = self.line_data..data:sub(1, nexti-2)
                result[count] = self:new_event(line_data, 1, line_data:len())
                self.line_data = nil
            else
                result[count] = self:new_event(data, i+1, nexti-2)
            end

        else
            if self.line_data ~= nil then
                line_data = self.line_data..data:sub(1, nexti-1)
                result[count] = self:new_event(line_data, 1, line_data:len())
                self.line_data = nil
            else
                result[count] = self:new_event(data, i+1, nexti-1)
            end
        end

        i = nexti
        count = count + 1
    end
    return result
end

function DefaultLineBreakerFeed:finished()
    result = {}
    if self.line_data ~= nil and self.line_data ~= '' then
        result[1] = self:new_event(self.line_data, 1, self.line_data:len())
    end
    return result
end


splunkd_access.feeder = DefaultLineBreakerFeed:new()



--[[
ffi.cdef[[
typedef struct real_pcre pcre;
typedef struct pcre_extra pcre_extra;
static const int PCRE_STUDY_JIT_COMPILE = 0x00000001;
pcre *pcre_compile(const char *, int, const char **, int *,
                  const unsigned char *);
pcre *pcre_compile2(const char *, int, int *, const char **,
                  int *, const unsigned char *);
pcre_extra *pcre_study(const pcre *, int, const char **);
int pcre_exec(const pcre *, const pcre_extra *, const char *,
                   int, int, int, int *, int);
void pcre_free_study(pcre_extra *);
void (*pcre_free)(void *);


local pcre = ffi.load('pcre')
local errptr = ffi.new('const char*[1]')
local intptr = ffi.new('int[1]')
local re = pcre.pcre_compile(reg, 0, errptr, intptr, nil)

local size = (n + 1) * 3
local ovector = ffi.new('int['..size..']')
local re_stu = pcre.pcre_study(re, pcre.PCRE_STUDY_JIT_COMPILE, errptr)
local ret = {}
local st = n + 1 


function match(subject, regex)
  pcre.pcre_exec(re, re_stu, subject, #subject, 0, 0, ovector, size)
  for i=0, n*2, 2 do
    if ovector[i] >= 0 then
      ret[i/2] = subject:sub(ovector[i]+1, ovector[i+1])
    end
  end
  return ret
end
]]

local ret = {}

function match(subject, _re,_re_stu,_ovector,_size,_n)
  pcre.pcre_exec(_re, _re_stu, subject, #subject, 0, 0, _ovector, _size)
  print('#######')
  print(_re,_re_stu,_ovector,_size,_n)
  for i=0, _n*2, 2 do
    if _ovector[i] >= 0 then
      ret[i/2] = subject:sub(_ovector[i]+1, _ovector[i+1])
    end
  end
  return ret
end


function print_table( t )
    for k,v in pairs(t) do
        print(k,v)
    end
end


local data_file = arg[1]

-- read buffer from stdin
local buffer_size = 2^16    -- make a 64k buffer. use this buffer make reading faster.
local f = io.open(data_file, "rb")
while true do
    local block = f:read(buffer_size)
    if not block then
        splunkd_access.feeder:finished()
        break
    end
    splunkd_access.feeder:feed(block)
end
f:close()
print('===fail match===')
print_table(match_fail)
--[[
    aa = splunkd_access.feeder:feed(block)

    for k,v in pairs(aa) do
        print('=======fields========')
        print_table(v)
    end
    ]]


--pcre.pcre_free_study(pcre.re_stu)
--pcre.pcre_free(pcre.re)
module(...)
return splunkd_access
-- end of file