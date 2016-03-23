local rex_pcre = require "rex_pcre"

-- print( rex_pcre.new("[0-9]+"):exec("1234") )
-- print( rex_pcre.new("\\d+"):exec("{{ foo }}1234") )

-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor

MultiLineEventFeed = {
    line_pos = 0,
    -- prealloc {{ max_events }} entry, to avoid table's realloc
    lines = { {% for i in range(0, max_events+1)%}'', {% endfor %} }
}

function MultiLineEventFeed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
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

-- read data from stdin line by line, and output them by append line no.
local count = 1
while true do
    local line = io.read()
    if line == nil then break end
    -- io.write(string.format("%6d  ", count), line, "\n")
    print(feeder:feed(line))
    count = count + 1
end