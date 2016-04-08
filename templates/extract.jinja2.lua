--49444250/164=301489.3292682927
--49444250/264.455225945=186966.4319293246

local rex_pcre = require "rex_pcre"
local re = '(?:^(?<clientip>(?:\\S+))\\s++(?<ident>(?:\\S+))\\s++(?<user>(?:\\S+))\\s++(?<req_time>(?:\\[(?:[^\\]]*+)\\]))\\s++(?:"\\s*+(?<method>(?:[^\\s"]++))?(?:\\s++(?<uri>(?<uri_>(?<domain0>\\w++:\\/\\/[^\\/\\s"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\"|[^\\s\\?\\/"])++)\\/++)?(?:(?:\\\\"|[^\\s\\?\\/"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?)(?:\\s++(?<version>(?:[^\\s"]++)))*)?\\s*+")\\s++(?<status>(?:\\S+))\\s++(?<bytes>(?:\\S+))(?:\\s++"(?<referer>(?<referer_>(?<domain>\\w++:\\/\\/[^\\/\\s"]++))?+[^"]*+)"(?:\\s++(?<useragent>(?:"(?:[^"]*+)"))(?:\\s++(?<cookie>(?:"(?:[^"]*+)")))?+)?+)?(?<other>(?:.*)))'
local name = 'clientip,ident,user,req_time,method,uri,uri_,domain0,uri_path,root,file,uri_query,version,status,bytes,referer,referer_,domain,useragent,cookie,other'
local re_new = rex_pcre.new(re)
local names = {}
for w in string.gmatch(name,"([^',']+)") do
    table.insert(names,w)
end

--local countline = 0
-- print( rex_pcre.new("[0-9]+"):exec("1234") )
function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function extract_event(line )
    namegroup = {}
    count = 0
    group={re_new:match(line)}
    for w in string.gmatch(name,"([^',']+)") do
        count = count+1
        namegroup[w]=group[count]
    end
    return namegroup
end

function t_extract_event(group)
    namegroup = {}
    for k,v in pairs(names) do
        namegroup[v]=group[k]
    end
    return namegroup
end

function print_table( t )
    for k,v in pairs(t) do
        print(k,v)
    end
end

-- build series transform | report | extract
-- report
{% for step_name in processor.step_reports %}
local event_report_{{ processor.get_normal_name(step_name) }}_re = rex_pcre.new("{{ processor.get_full_regex(step_name, True) }}")
function event_report_{{ processor.get_normal_name(step_name) }}(new_event)

end

{% endfor %}
-- transform
{% for step_name in processor.step_transform %}
-- {{ step_name }}
{% endfor %}
-- extract
{% for step_name in processor.step_extract %}
-- {{ step_name }}
{% endfor %}

-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor
{% if options.get('multiline') %}
local MultiLineEventFeed = {
    line_pos = 0,
    -- prealloc {{ max_events }} entry, to avoid table's realloc
    lines = { {% for i in range(0, max_events+1)%}'', {% endfor %} }
end

function MultiLineEventFeed:feed(new_line)
    if self.line_pos >= {{ max_events }} then
        return false
    end
    self.lines[self.line_pos] = new_line
    self.line_pos = self.line_pos + 1
    return true
end

function MultiLineEventFeed:new_event()
    -- called when self.lines contains a whole event.
end

local feeder = MultiLineEventFeed:new()
{% endif -%}
{% if options.get('default_linebreaker') %}
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
    -- processing the events
    -- do regex
    --print('========')
    --print(event_lines:sub(b, e))
    --namegroup = extract_event(event_lines:sub(b, e))
    t = {re_new:match(event_lines:sub(b, e))}
    --namegroup = t_extract_event(t)
    --print_table(namegroup)
    --countline = countline + 1
end

function DefaultLineBreakerFeed:feed(data)
    -- find each [\r\n]+, in fact \n only
    -- table to store the indices
    local i = 0
    local nexti = 0
    while true do
        -- if do line breaker only, speed at 220W/s  ngx_access_log
        nexti = data:find("\n", i+1)    -- find 'next' newline
        if nexti == nil then
            self.line_data = data:sub(i+1) -- the remain..
            --print(self.line_data)
            --exit()
            break
        end

        -- check is \r\n
        if data:byte(nexti-1) == 13 then
            -- patch self.line_data
            if self.line_data ~= nil then
                local line_data = self.line_data..data:sub(1, nexti-2)
                self:new_event(line_data, 1, line_data:len())
                self.line_data = nil
            else
                self:new_event(data, i+1, nexti-2)
            end
        else
            if self.line_data ~= nil then
                local line_data = self.line_data..data:sub(1, nexti-1)
                self:new_event(line_data, 1, line_data:len())
                self.line_data = nil
            else
                self:new_event(data, i+1, nexti-1)
            end
        end
        i = nexti
        -- print(i)
    end
end

function DefaultLineBreakerFeed:finished(data)
    if self.line_data ~= nil then
        self:new_event(self.line_data, 1, self.line_data:len())
    end
end


local feeder = DefaultLineBreakerFeed:new()
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

local feeder = CustomLineBreakerFeed:new()
{% endif %}


local data_file = arg[1]
-- read buffer from stdin
local buffer_size = 2^16    -- make a 64k buffer. use this buffer make reading faster.
local f = io.open(data_file, "rb")
while true do
    local block = f:read(buffer_size)
    if not block then
        feeder:finished()
        break
    end
    -- io.write(block)
    feeder:feed(block)
end
f:close()
--print('countline:',countline)
-- end of file