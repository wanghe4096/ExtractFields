
--49444250/104.022794008=475321.30310014
--49444250/125.411713839=394255.4366450579
local rex_pcre = require "rex_pcre"
local access_combined = {}
access_combined.event_fieldstypes = {flag='true',description='please input the type of fields as follows,after you can input flag to true'}
-- build series transform | report | extract
-- report



local reg = "^(?<clientip>\\S+)\\s++(?<ident>\\S+)\\s++(?<user>\\S+)\\s++\\[(?<req_time>[^\\]]*+)\\]\\s++(?:\"\\s*+(?<method>[^\\s\"]++)?(?:\\s++(?:(?<uri>(?<uri_>(?<uri__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\\"|[^\\s\\?\\/\"])++)\\/++)?(?:(?:\\\\\"|[^\\s\\?\\/\"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?))(?:\\s++(?<version>[^\\s\"]++))*)?\\s*+\")\\s++(?<status>\\S+)\\s++(?<bytes>\\S+)(?:\\s++\"(?<referer>(?<referer_>(?<referer__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+[^\"]*+)\"(?:\\s++\"(?<useragent>[^\"]*+)\"(?:\\s++\"(?<cookie>[^\"]*+)\")?+)?+)?(?<other>.*)"
access_combined.event_names = {'clientip','ident','user','req_time','method','uri','uri_','uri__domain','uri_path','root','file','uri_query','version','status','bytes','referer','referer_','referer__domain','useragent','cookie','other'}
local n = 21



-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor

if not reg then
    reg = ''
end

if not access_combined.event_names then
    access_combined.event_names = {}
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

require('dateparse.DateParse')


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
    events = {}
    if not _pattern then
        getAllMatches(event_lines:sub(b,e))
        access_combined.time_names = time_names
    end
    events.time = match_datetime(event_lines:sub(b,e))
    --events.time = getAllMatches(event_lines:sub(b,e))
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
        print('===begin===')
        print('===events.time===')
        print_table(events.time)
        print('===events.event===')
        print_table(events.event)
        print('===end===')
    end

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


access_combined.feeder = DefaultLineBreakerFeed:new()


local ffi = require('ffi')

local pcre = ffi.load('pcre')
local errptr = ffi.new('const char*[1]')
local intptr = ffi.new('int[1]')
local re = pcre.pcre_compile(reg, 0, errptr, intptr, nil)

local size = (n + 1) * 3
local ovector = ffi.new('int['..size..']')
local re_stu = pcre.pcre_study(re, pcre.PCRE_STUDY_JIT_COMPILE, errptr)
local ret = {}
local st = n + 1 


function match(subject)
  pcre.pcre_exec(re, re_stu, subject, #subject, 0, 0, ovector, size)
  for i=0, n*2, 2 do
    if ovector[i] >= 0 then
      ret[i/2] = subject:sub(ovector[i]+1, ovector[i+1])
    end
  end
  return ret
end


function print_table( t )
    if type(t) == 'string' then
        print(t)
    else
        for k,v in pairs(t) do
            print(k,v)
        end
    end
end


local data_file = arg[1]

-- read buffer from stdin
local buffer_size = 2^16    -- make a 64k buffer. use this buffer make reading faster.
local f = io.open(data_file, "rb")
while true do
    local block = f:read(buffer_size)
    if not block then
        access_combined.feeder:finished()
        break
    end
    access_combined.feeder:feed(block)
end
f:close()
print('===fail match===')
print_table(match_fail.event)
print_table(match_fail.time)


--pcre.pcre_free_study(pcre.re_stu)
--pcre.pcre_free(pcre.re)
module(...)
return access_combined
--return access_combined.feeder,event_names,event_fieldstypes,time_names
-- end of file