local rex_pcre = require "rex_pcre"

-- print( rex_pcre.new("[0-9]+"):exec("1234") )
-- print( rex_pcre.new("\\d+"):exec("{{ foo }}1234") )

-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor

EventFeed = {
    line_pos = 0,
    -- prealloc {{ max_events }} entry, to avoid table's realloc
    lines = { {% for i in range(0, max_events+1)%}'', {% endfor %} }
}

function EventFeed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function EventFeed:feed(new_line)
end

a = {n=10 }
a[1] = 1
a[11] = 1

-- read data from stdin line by line, and output them by append line no.
local count = 1
while true do
    local line = io.read()
    if line == nil then break end
    -- io.write(string.format("%6d  ", count), line, "\n")
    count = count + 1
end
