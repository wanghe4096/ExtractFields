local rex_pcre = require "rex_pcre"

-- print( rex_pcre.new("[0-9]+"):exec("1234") )
function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

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

function DefaultLineBreakerFeed:new_event(event_lines)
    -- processing the events
    print (event_lines)
    print ("=====")
end

function DefaultLineBreakerFeed:feed(data)
    -- find each [\r\n]+, in fact \n only
    -- table to store the indices
    local i = 0
    while true do
        -- if do line breaker only, speed at 220W/s  ngx_access_log
        i = data:find("\n", i+1)    -- find 'next' newline
        if i == nil then
            self.line_data = '' -- the remain..
            break
        end
        -- print(i)
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
    print (event_lines)
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
    if not block then break end
    -- io.write(block)
    feeder:feed(block)
end
f:close()
-- end of file