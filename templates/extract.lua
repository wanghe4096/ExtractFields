
--49444250/104.022794008=475321.30310014
--49444250/125.411713839=394255.4366450579
local rex_pcre = require "rex_pcre"
local {{sourcetype}} = {}
{{sourcetype}}.namestype = {{ namestype }}
-- build series transform | report | extract
-- report
{% if processor.step_reports %}
{% for step_name in processor.step_reports %}

local reg = "{{ processor.get_full_regex(step_name, True) }}"
{{sourcetype}}.names = {{ processor.get_names(step_name) }}
local n = {{processor.get_names_count(step_name)}}

{% endfor %}

{% elif processor.step_transform %}
-- transform
{% for step_name in processor.step_transform %}

local reg = "{{ processor.get_full_regex(step_name, True) }}"
{{sourcetype}}.names = {{ processor.get_names(step_name) }}
local n = {{processor.get_names_count(step_name)}}

{% endfor %}
{% elif processor.step_extract %}
-- extract
{% for step_name in processor.step_extract %}

local reg = "{{ processor.get_full_regex(step_name, True) }}"
{{sourcetype}}.names = {{ processor.get_names(step_name) }}
local n = {{processor.get_names_count(step_name)}}

{% endfor %}
{% endif -%}

-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor

if not reg then
    reg = ''
end

if not {{sourcetype}}.names then
    {{sourcetype}}.names = {}
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

{% if options.get('multiline') %}
local MultiLineEventFeed = {
    --time_extract = nil --time extract
    multiline_re = '{{options.get('BREAK_ONLY_BEFORE')}}' ,--'\\d+:\\d+:\\d+',
    line_data = nil
}


function MultiLineEventFeed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MultiLineEventFeed:new_event(event_lines, b, e)
    events = nil
    if self.multiline_re == '' then
        self.multiline_re = getAllMatches(event_lines:sub(b,e))._pattern
        --self.multiline_re = '\\d+:\\d+:\\d+'
    end
    print('=====multiline_re=====')
    print(self.multiline_re)
    --if rex_pcre.new(self.multiline_re):exec(event_lines:sub(b,e)) then
    if match_time(event_lines:sub(b,e),self.multiline_re) then
        if linecount >= 1 then
            print('=====event======')
            print(event)
            events = {}
            if reg == '' then
                events.event = event
            else
                events.event = match(event)
            end
            events.time = getAllMatches(event)
            if not events.event then
                print('fail match event:',event)
                table.insert(match_fail.event,event)
                events = nil
            elseif not events.time then
                print('fail match time:',event)
                table.insert(match_fail.time,event)
                events = nil
            end
            if events then
                print('===events.time===')
                print_table(events.time)
                print('===events.event===')
                print_table(events.event)
            end
            event = ''
            linecount = 0
        end
        linecount = 1
        event = event_lines:sub(b,e)         
    else
        linecount = linecount + 1
        event = event .. '\n' .. event_lines:sub(b,e)
    end
    return events
end

function MultiLineEventFeed:feed(data)
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
                --self:new_event(line_data, 1, line_data:len())
                multiline = self:new_event(line_data, 1, line_data:len())
                self.line_data = nil
            else
                --self:new_event(data, i+1, nexti-2)
                multiline = self:new_event(data, i+1, nexti-2)
            end

        else
            if self.line_data ~= nil then
                line_data = self.line_data..data:sub(1, nexti-1)
                --self:new_event(line_data, 1, line_data:len())
                multiline = self:new_event(line_data, 1, line_data:len())
                self.line_data = nil
            else
                --self:new_event(data, i+1, nexti-1)
                multiline = self:new_event(data, i+1, nexti-1)
            end
        end
        
        i = nexti
        if multiline then
            result[count] = multiline
            count = count + 1
        end
    end
    return result
end

function MultiLineEventFeed:finished(data)
    result = {}
    if self.line_data ~= nil then
        multiline = self:new_event(self.line_data, 1, self.line_data:len())
        if multiline then
            result[1] = multiline
        end
    end
    return result
end

{{sourcetype}}.feeder = MultiLineEventFeed:new()

{% elif options.get('default_linebreaker') %}
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

function DefaultLineBreakerFeed:finished(data)
    result = {}
    if self.line_data ~= nil then
        result[1] = self:new_event(self.line_data, 1, self.line_data:len())
    end
    return result
end


{{sourcetype}}.feeder = DefaultLineBreakerFeed:new()
{% endif -%}
{% if options.get('custom_linebreaker') %}
-- custom line breaker
local CustomLineBreakerFeed = {
    line_breaker_re = nil,
    line_data = nil
}

function CustomLineBreakerFeed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.line_breaker_re = rex_pcre.new("{{ options.get('linebreaker_regex') }}")
    return o
end

function CustomLineBreakerFeed:new_event(event_lines)
    -- processing the events
    
    print ("=====")
end

function CustomLineBreakerFeed:feed(data)
    -- each time read buffer_size's length data. try find line_breaker_re in the buffer, if not store it.
    local buffer = nil
    if self.line_data ~= nil then
        buffer = self.line_data..data
    else
        buffer = data   -- fast path
    end

    local match_pos = 1
    while true do
        local b, e, _ = self.line_breaker_re:exec(buffer, match_pos)
        if b ~= nil then
            -- for fast processing subset a string is NOT require.
            local event_lines = (buffer.sub(buffer, match_pos, b))
            match_pos = e + 1
            self:new_event(event_lines)
        else
            self.line_data = buffer
            break
        end
    end -- end wile

end

{{sourcetype}}.feeder = CustomLineBreakerFeed:new()
{% endif %}

local ffi = require('ffi')
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
]]

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
        {{sourcetype}}.feeder:finished()
        break
    end
    {{sourcetype}}.feeder:feed(block)
end
f:close()
print('===fail match===')
print_table(match_fail)
--[[
    aa = {{sourcetype}}.feeder:feed(block)

    for k,v in pairs(aa) do
        print('=======fields========')
        print_table(v)
    end
    ]]


--pcre.pcre_free_study(pcre.re_stu)
--pcre.pcre_free(pcre.re)
module(...)
return {{sourcetype}}
-- end of file