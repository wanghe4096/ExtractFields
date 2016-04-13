
--49444250/104.022794008=475321.30310014
--49444250/125.411713839=394255.4366450579
local oneapm = {}
oneapm.namestype = {status='int',client_ip='string',server_ip='string',client_dev_message='string',timestamp='string',bytes='int',uri='string',uri__domain='string',uri_path='string',uri_='string',version='string',uri_query='string',server_port='int',file='string',response_size='int',root='string',method='string',response_time='double'}
-- build series transform | report | extract
-- report



local reg = "^(?<client_ip>\\S+)\\s(?<server_ip>\\S+):(?<server_port>\\d+)\\s(?<response_time>\\d*\\.\\d+|(?:0x[a-fA-F0-9]+|\\d+))\\s-\\s\\[(?<timestamp>[^\\]]*+)\\]\\s(?:\"\\s*+(?<method>[^\\s\"]++)?(?:\\s++(?:(?<uri>(?<uri_>(?<uri__domain>\\w++:\\/\\/[^\\/\\s\"]++))?+(?<uri_path>(?:\\/++(?<root>(?:\\\\\"|[^\\s\\?\\/\"])++)\\/++)?(?:(?:\\\\\"|[^\\s\\?\\/\"])*+\\/++)*(?<file>[^\\s\\?\\/]+)?)(?:\\?(?<uri_query>[^\\s]*))?))(?:\\s++(?<version>[^\\s\"]++))*)?\\s*+\")\\s(?<status>\\d+)\\s(?<response_size>\\d+)\\s(?<bytes>\\d+)\\s\\\"-\\\"\\s(?<client_dev_message>.*)"
oneapm.names = {'client_ip','server_ip','server_port','response_time','timestamp','method','uri','uri_','uri__domain','uri_path','root','file','uri_query','version','status','response_size','bytes','client_dev_message'}
local n = 18



-- TODO: 1 create a event emit, on_event?
-- TODO: 2 feed data line by line, and put it into a buffer
-- TODO: 3 do extractor

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
    print_table(match(event_lines:sub(b, e)))
    print(event_lines:sub(b, e))
    return match(event_lines:sub(b, e)),event_lines:sub(b, e)
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


oneapm.feeder = DefaultLineBreakerFeed:new()


local ffi = require('ffi')
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
        oneapm.feeder:finished()
        break
    end
    oneapm.feeder:feed(block)
end
f:close()
--pcre.pcre_free_study(pcre.re_stu)
--pcre.pcre_free(pcre.re)
module(...)
return oneapm
-- end of file