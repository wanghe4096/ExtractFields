local rex_pcre = require "rex_pcre"

-- print( rex_pcre.new("[0-9]+"):exec("1234") )

-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor
{% if options.get('multiline') %}
MultiLineEventFeed = {
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
-- default single line
{% endif -%}
{% if options.get('custom_linebreaker') %}
-- custom line breaker
CustomLineBreakerFeed = {
    line_pos = 0,
    line_breaker_re = nil,
    -- prealloc {{ max_events }} entry, to avoid table's realloc
    -- should enlarger max_events if ...
    lines = ""
}

function CustomLineBreakerFeed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.line_breaker_re = rex_pcre.new("{{ options.get('linebreaker_regex') }}")
    return o
end

function CustomLineBreakerFeed:is_breaker(new_line)
    -- print (new_line)
    -- print ("=====")
    return (nil ~= (self.line_breaker_re:exec(new_line)))
end

function CustomLineBreakerFeed:feed(new_line)
    if self.line_pos >= {{ max_events }} then
        -- should log the event..
        return false
    end
    -- fixme: many cause many memory relloc, but if we use string-builder, it can NOT do regex:exec, so...
    self.lines = self.lines .. new_line
    -- check should break
    if self:is_breaker(self.lines) then
        print(new_line)
        return false
    end
    -- self.line_pos = self.line_pos + 1
    return true
end

local feeder = CustomLineBreakerFeed:new()
{% endif %}
-- read data from stdin line by line, and output them by append line no.
local count = 1
while true do
    -- with *all , no strip the line-end
    local line = io.read("*all")
    if line == nil then break end
    io.write(string.format("%6d  ", count), line, "\n")
    feeder:feed(line)
    count = count + 1
end