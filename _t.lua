local rex_pcre = require "rex_pcre"

-- print( rex_pcre.new("[0-9]+"):exec("1234") )

-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor

-- default single line

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