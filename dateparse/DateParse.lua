local _MIN_YEAR = 2000
local _MAX_YEAR = 2016
local current_time = os.time()
local current_time_tab = os.date('*t',current_time)

local litmonthtable = { jan = 1, feb = 2, mar = 3, apr = 4, may = 5,
                  jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12 }

local timeinfo = {{{REGEX='\\D(?P<hour>[012]?\\d):(?P<minute>[0-6]\\d):(?P<second>[0-6]\\d(?:\\.\\d+)?)? *(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?',names={'hour','minute','second','zone'}},{REGEX='\\D(?P<hour>[012]?\\d):(?P<minute>[0-6]\\d)(?::(?P<second>[0-6]\\d(?:\\.\\d+)?))? *(?P<ampm>[ap][m.]+)? *(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?',names={'hour','minute','second','ampm','zone'}}},{{REGEX='(?:(?P<litday>mon|Mon|MON|tue|Tue|TUE|wed|Wed|WED|thu|Thu|THU|fri|Fri|FRI|sat|Sat|SAT|sun|Sun|SUN)[a-z]*,? )? *(?:[^:0-9]|^)(?P<day>\\d{1,2})(?:[^:0-9]|$)(?:st|nd|rd|th|[,\\.;])? *[- \\/] *(?:(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*) *[- \\/](?:[0-9: ]+)(?:(?P<year>\\d+)(?P<epoch> *[ABCDE\\.]+)?)?',names={'litday','day','litmonth','year','epoch'}},{REGEX='(?:(?P<litday>mon|Mon|MON|tue|Tue|TUE|wed|Wed|WED|thu|Thu|THU|fri|Fri|FRI|sat|Sat|SAT|sun|Sun|SUN)[a-z]*,? )? *(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*[ ,.]+(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))(?:st|nd|rd|th|[,\\.;])?(?:[ a-z]+(?:(?P<year>\\d+)(?P<epoch> *[ABCDE\\.]+)?))?',names={'litday','litmonth','day','year','epoch'}},{REGEX='(?P<month>[0-2]?\\d(?!:))\\/(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))(?:\\/(?:(?P<year>\\d+)(?P<epoch> *[ABCDE\\.]+)?))?[^0-9a-z\\.]',names={'month','day','year','epoch'}},{REGEX='(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))\\.(?P<month>[0-2]?\\d(?!:))\\.(?:(?P<year>\\d+)(?P<epoch> *[ABCDE\\.]+)?)?',names={'day','month','year','epoch'}},{REGEX='(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))[:\\/\\- ](?:(?P<month>[0-2]?\\d(?!:))|(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*)[:\\/\\- ](?P<year>\\d+)',names={'day','month','litmonth','year'}},{REGEX='(?:(?P<month>[0-2]?\\d(?!:))|(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*)[:\\/\\- ](?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))[:\\/\\- ](?P<year>\\d+)',names={'month','litmonth','day','year'}},{REGEX='(?P<year>\\d+)[:\\/\\- ](?:(?P<month>[0-2]?\\d(?!:))|(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*)[:\\/\\- ](?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))',names={'year','month','litmonth','day'}},{REGEX='(?P<month>[0-2]?\\d(?!:))-(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))-(?:(?P<year>-?\\d+\\d\\d(?!:))(?P<epoch> *[ABCDE\\.]+)?)',names={'month','day','year','epoch'}},{REGEX='(?:(?P<litday>mon|Mon|MON|tue|Tue|TUE|wed|Wed|WED|thu|Thu|THU|fri|Fri|FRI|sat|Sat|SAT|sun|Sun|SUN)[a-z]*,? )? *(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*[:\\/\\- ](?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))\\s\\d+:\\d+:\\d+\\s(?P<year>\\d+)(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?',names={'litday','litmonth','day','year','zone'}},{REGEX='(?P<year>\\d+)-(?P<month>[01]\\d(?!:))-?(?P<day>[0123]\\d(?!:))?(?!:)',names={'year','month','day'}},{REGEX='(?P<year>\\d+)\\.(?P<month>[0-2]?\\d(?!:))\\.(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))',names={'year','month','day'}},{REGEX='(?:(?P<litday>mon|Mon|MON|tue|Tue|TUE|wed|Wed|WED|thu|Thu|THU|fri|Fri|FRI|sat|Sat|SAT|sun|Sun|SUN)[a-z]*,?[ a-z]+)? *(?:(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))(?:st|nd|rd|th|[,\\.;])?[ a-z]+) *(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*(?:[ ,.a-z]+(?:(?P<year>\\d+)(?P<epoch> *[ABCDE\\.]+)?))?',names={'litday','day','litmonth','year','epoch'}},{REGEX='(?P<year>\\d+)[\\/-](?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*[\\/-](?P<day>[0123]\\d(?!:))(?!:)',names={'year','litmonth','day'}}},{{REGEX='(?:(?:(?P<litday>mon|Mon|MON|tue|Tue|TUE|wed|Wed|WED|thu|Thu|THU|fri|Fri|FRI|sat|Sat|SAT|sun|Sun|SUN)[a-z]*,? )? *(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*[:\\/\\- ](?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:)))\\D(?P<hour>[012]?\\d)[:.](?P<minute>[0-6]\\d)[:.](?P<second>[0-6]\\d(?:\\.\\d+)?)(?:(?P<ampm>[ap][m.]+)? *)?(?:(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?)?',names={'litday','litmonth','day','hour','minute','second','ampm','zone'}},{REGEX='(?:(?:(?P<litday>mon|Mon|MON|tue|Tue|TUE|wed|Wed|WED|thu|Thu|THU|fri|Fri|FRI|sat|Sat|SAT|sun|Sun|SUN)[a-z]*,? )? *(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*[:\\/\\- ](?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:)))\\D(?P<hour>[012]?\\d)[:.](?P<minute>[0-6]\\d)[:.](?P<second>[0-6]\\d(?:\\.\\d+)?)\\D(?P<year>\\d+)\\D(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?',names={'litday','litmonth','day','hour','minute','second','year','zone'}},{REGEX='(?:(?P<year>\\d+)[:\\/\\- ](?:(?P<month>[0-2]?\\d(?!:))|(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*)[:\\/\\- ](?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:)))\\D(?P<hour>[012]?\\d)[:.](?P<minute>[0-6]\\d)[:.](?P<second>[0-6]\\d(?:\\.\\d+)?)(?:(?P<ampm>[ap][m.]+)? *)?(?:(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?)?',names={'year','month','litmonth','day','hour','minute','second','ampm','zone'}},{REGEX='(?:(?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))[:\\/\\- ](?:(?P<month>[0-2]?\\d(?!:))|(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*)[:\\/\\- ](?P<year>\\d+))\\D(?P<hour>[012]?\\d)[:.](?P<minute>[0-6]\\d)[:.](?P<second>[0-6]\\d(?:\\.\\d+)?)(?:(?P<ampm>[ap][m.]+)? *)?(?:(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?)?',names={'day','month','litmonth','year','hour','minute','second','ampm','zone'}},{REGEX='(?:(?:(?P<month>[0-2]?\\d(?!:))|(?P<litmonth>jan|Jan|JAN|feb|Feb|FEB|mar|Mar|MAR|apr|Apr|APR|may|May|MAY|jun|Jun|JUN|jul|Jul|JUL|aug|Aug|AUG|sep|Sep|SEP|oct|Oct|OCT|nov|Nov|NOV|dec|Dec|DEC)[a-z,\\.;]*)[:\\/\\- ](?P<day>20(?![\\d:])|(?!20)\\d?\\d(?!:))[:\\/\\- ](?P<year>\\d+))\\D(?P<hour>[012]?\\d)[:.](?P<minute>[0-6]\\d)[:.](?P<second>[0-6]\\d(?:\\.\\d+)?)(?:(?P<ampm>[ap][m.]+)? *)?(?:(?P<zone>((?:(?:UT|UTC|GMT(?![+-])|CET|CEST|CETDST|MET|MEST|METDST|MEZ|MESZ|EET|EEST|EETDST|WET|WEST|WETDST|MSK|MSD|IST|JST|KST|HKT|AST|ADT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|CAST|CADT|EAST|EADT|WAST|WADT|Z)|(?:GMT)?[+-]\\d\\d?:?(?:\\d\\d)?)(?!\\w))?)?)?',names={'month','litmonth','day','year','hour','minute','second','ampm','zone'}}}}


 local function _validateDate(values)
    local errors = nil
    local status = true
    local year = current_time_tab.year
    local month = 1
    local day = 1

    local yvalue = values._year
    local dvalue = values._day
    local mvalue = values._month
    local lvalue = values._litmonth

    if yvalue == nil and dvalue == nil and mvalue == nil then
        return true
    end

    if yvalue then
        year = yvalue
        if string.len(year) < 4 then
            return nil
        end
        status = pcall(function () if year - _MAX_YEAR > 0 or year - _MIN_YEAR <0 then
            errors = "bad year: " .. yvalue
            --print (errors)
        end end)
    elseif not values._hour then
      return nil
    end
    if dvalue then
        day = dvalue
        status = pcall(function () if day-0 < 1 or day-0 > 31 then
            errors = "bad day: " .. dvalue
            --print (errors)
        end end)
    else
        return nil
    end
    if mvalue then
        month = mvalue
        status = pcall(function () if month-0 > 12 or month-0 == 0 then
            errors = "bad month: " .. mvalue
            --print (errors)
        end end)
    end
    if lvalue then
        litmonth = string.lower(lvalue)
        month = litmonthtable[litmonth]
        if not month then
            errors =  'wrong month name: ' .. litmonth
            --print (errors)
        end
    end

    if errors then
        if _debug then
            print ("Error: " .. errors)
        end
        return nil
    end
    if not status then
      return nil
    end


    if day == nil then
        day = current_time_tab.day
    end
    if month == nil then
            month = current_time_tab.month
    end
    if year == nil then
        year = current_time_tab.year
    end
    return {day,month,year}
end

local function _validateTime(values)

    local errors = nil
    local status = true
    local hour,minute,second,ampm,offset = 0,0,0,'a',0

    local zvalue = values._zone
    local hvalue = values._hour
    local mvalue = values._minute
    local svalue = values._second
    local ampmvalue = values._ampm

    if zvalue then
        zone = zvalue
    end
    --[[
        # Convert to UTC offset
        offset = utc_offset(zone)
    else:
        # USE CURRENT TIMEZONE
        offset = utc_offset(time.tzname[0])
        ]]

    if hvalue then
        hour = hvalue
        if ampmvalue then
            ampm = ampmvalue
            if ampm:sub(1,1) == 'p' or ampm:sub(1,1) == 'P' then
                hour = hour + 12
            end
        end
        status = pcall(function () if hour-0 < 0 or hour-0 > 23 then
            errors = "bad hour:" .. hour
            --print (errors)
        end end)
    end
    if mvalue then
        minute = mvalue
        status = pcall(function () if minute-0 < 0 or minute-0 > 59 then
            errors = "bad minute:" .. minute
            --print (errors)
        end end)
    end
    if svalue then
        second = svalue
        status = pcall(function () if second-0 < 0 or second-0 > 59 then
            errors = "bad second:" .. second
            --print (errors)
        end end)
    end

    if errors then
        --print ("Error: " .. errors)
        return nil
    end

    if not status then
      return nil
    end
    return {hour,minute,second,offset}
end


local function _validateDateTime(values)
    local result = nil
    result = _validateDate(values)
    if result then
        result = _validateTime(values)
    else
        return nil
    end
    return result
 end

local ffi = require('ffi')
ffi.cdef[[
typedef struct real_pcre pcre;
typedef struct pcre_extra pcre_extra;
static const int PCRE_STUDY_JIT_COMPILE = 0x00000001;
static const int PCRE_CASELESS           = 0x00000001;
static const int PCRE_MULTILINE          = 0x00000002;
static const int PCRE_DOTALL             = 0x00000004;
static const int PCRE_EXTENDED           = 0x00000008;
static const int PCRE_ANCHORED           = 0x00000010;
static const int PCRE_UTF8               = 0x00000800;
pcre *pcre_compile(const char *, int, const char **, int *,
                  const unsigned char *);
pcre *pcre_compile2(const char *, int, int *, const char **,
                  int *, const unsigned char *);
pcre_extra *pcre_study(const pcre *, int, const char **);
int pcre_exec(const pcre *, const pcre_extra *, const char *,
                   int, int, int, int *, int);
int pcre_fullinfo(const pcre *, const pcre_extra *, int,
                  void *);
void pcre_free_study(pcre_extra *);
void (*pcre_free)(void *);
]]

local L = ffi.load('pcre')

local flags = {
  a = L.PCRE_ANCHORED,
  d = 0, --ignored. should call L.pcre_dfa_exec
  i = L.PCRE_CASELESS,
  j = 0, --ignored
  m = L.PCRE_MULTILINE,
  o = 0, --ignored
  s = L.PCRE_DOTALL,
  u = L.PCRE_UTF8,
  x = L.PCRE_EXTENDED,
}

local function options2flags(options)
  local f = 0
  for i=1, #options do
    f = bit.bor(f, flags[options:sub(i, i)])
  end
  return f
end

local _n = nil

function match_time(subject, regex, options, ctx)
  local o = 0
  local pos
  if not ctx or not ctx.pos then
    pos = 0
  else
    pos = ctx.pos
  end
  local re, n, size, ovector
  if ctx and type(ctx._rectx) == 'table' then
    re = ctx._rectx.re
    n = ctx._rectx.n
    size = ctx._rectx.size
    ovector = ctx._rectx.ovector
    o = ctx._rectx.options
  else
    if options then
      o = options2flags(options)
    end
    local errptr = ffi.new('const char*[1]')
    local intptr = ffi.new('int[1]')
    re = L.pcre_compile(regex, o, errptr, intptr, nil)
    if re == nil then
      return nil, ffi.string(errptr[0]), intptr[0]
    end
    --re_stu = L.pcre_study(re, L.PCRE_STUDY_JIT_COMPILE, errptr)
    L.pcre_fullinfo(re, nil, 2 --[[PCRE_INFO_CAPTURECOUNT]], intptr)
    n = intptr[0]
    _n = n
    size = (n + 1) * 3
    ovector = ffi.new('int['..size..']')
  end
  --local st = L.pcre_exec(re, re_stu, subject, #subject, pos, 0, ovector, size)
  local st = L.pcre_exec(re, nil, subject, #subject, pos, 0, ovector, size)
  local err
  if st == -1 then
    -- no match
    if not ctx or not ctx._rectx then
      --L.pcre_free_study(re_stu)
      L.pcre_free(re)
    end
    return nil
  elseif st < 0 then
    err = 'pcre_exec failed with error code ' .. ret
  end
  if not ctx or not ctx._rectx then
    --L.pcre_free_study(re_stu)
    L.pcre_free(re)
  elseif ctx._rectx == true then
    ctx._rectx = {
      re = re,
      n = n,
      size = size,
      ovector = ovector,
      options = o,
    }
  end
  if err then
    return nil, err
  end
  local ret = {}
  if ctx then
    ctx.pos = ovector[1]
  end
  if ctx and ctx._index then
    for i=0, n*2, 2 do
      ret[i/2] = {ovector[i]+1, ovector[i+1]}
    end
  else
    for i=0, n*2, 2 do
      if ovector[i] >= 0 then
        ret[i/2] = subject:sub(ovector[i]+1, ovector[i+1])
      end
    end
  end
  return ret
end

_pattern = nil

local _pcre = ffi.load('pcre')
local _errptr = nil
local _intptr = nil
local _re = nil

local _size = nil
local _ovector = nil
local _re_stu = nil
local _ret = {}


function match_datetime(subject)
  if not _ovector then
     _errptr = ffi.new('const char*[1]')
     _intptr = ffi.new('int[1]')
     _re = _pcre.pcre_compile(_pattern, 0, _errptr, _intptr, nil)

    _size = (_n + 1) * 3
    _ovector = ffi.new('int['.._size..']')
    _re_stu = _pcre.pcre_study(_re, _pcre.PCRE_STUDY_JIT_COMPILE, _errptr)
  end
  _pcre.pcre_exec(_re, _re_stu, subject, #subject, 0, 0, _ovector, _size)
  for i=0, _n*2, 2 do
    if _ovector[i] >= 0 then
      _ret[i/2] = subject:sub(_ovector[i]+1, _ovector[i+1])
    end
  end
  return _ret
end

time_names = nil

local function extract_event_time(text,pattern,names)
    local namegroup = nil
    local group = match_time(text,pattern)
    if group then
        --print_table(group)
        namegroup = {}
        count = 1
        for k,v in pairs(names) do
            namegroup['_' .. v]=group[count]
--            if group[count] then
--                while group[count] == group[count+1] do
--                    count = count + 1
--                end
--            end
            count = count + 1
        end
        namegroup['_time'] = group[0]
        --namegroup['_pattern'] = pattern
        _pattern = pattern
        time_names = names
    end
    return namegroup
end


local function getTimeMatches(text, expressions)

    for k,expression in pairs(expressions) do
        local matchs = extract_event_time(text,expression.REGEX,expression.names)
        if matchs then
            local extractions = _validateTime(matchs)
            if extractions then
                return matchs
            end
        end
    end

    --print 'no regex match,please check time of the logfile'
    return {hour=nil,minute=nil,second=nil}
end

local function getDateMatches(text, expressions)

    for k,expression in pairs(expressions) do
        local matchs = extract_event_time(text,expression.REGEX,expression.names)
        if matchs then
            local extractions = _validateDate(matchs)
            if extractions then
                return matchs
            end
        end
    end

    --print 'no regex match,please check time of the logfile'
    return {year=nil,month=nil,day=nil}
end

--module(...)

function getAllMatches(text)
    local timematches = getTimeMatches(text,timeinfo[1])
    local datematches = getDateMatches(text,timeinfo[2])
    for k,expression in pairs(timeinfo[3]) do
        local matchs = extract_event_time(text,expression.REGEX,expression.names)
        if matchs then
            extractions = _validateDateTime(matchs)
            if extractions and matchs._year == datematches._year and matchs._hour == timematches._hour then
                return matchs
            end
        end
    end
    return nil
end

local function getAllMatches_test(text)
    local timematches = getTimeMatches(text,timeinfo[1])
    print('===timematches===')
    print_table(timematches)
    local datematches = getDateMatches(text,timeinfo[2])
    print('===datematches===')
    print_table(datematches)
    for k,expression in pairs(timeinfo[3]) do
        local matchs = extract_event_time(text,expression.REGEX,expression.names)
        if matchs then
            extractions = _validateDateTime(matchs)
            print(k,'===matchs===')
            print_table(matchs)
            if extractions and matchs._year == datematches._year and matchs._hour == timematches._hour then
                return matchs
            end
        end
    end                
    --print 'no regex match,please check datetime of the logfile or datetime regex'
    --return {year=nil,month=nil,day=nil,hour=nil,minute=nil,second=nil}
    return nil
end


--f = extract_event(text,expression)

--text = '113.96.151.228 - - [23/Mar/2015:15:07:19 +0800] "GET / HTTP/1.1" 302 20 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"'

--text = '<5>Mar 23 15:24:01 mysql kernel: type=1400 audit(1427095441.779:115): avc:  denied  { name_connect } for  pid=1605 comm=72733A6D61696E20513A526567 dest=11514 scontext=system_u:system_r:syslogd_t:s0 tcontext=system_u:object_r:port_t:s0 tclass=tcp_socket'

--text = '<188>2015-03-23 20:02:54 YunJiSuan_Fw_E1000E_02 %%01FIB/4/log_fib(l): -DevIP=192.168.60.9; FIB timer 272 timeout!'

--text = '<156>Apr 12 2015 12:20:34 NFJD-SW1 %%01NTP/4/STRATUM_CHANGE(l): System stratum changes from 4 to 3 after clock update.'

--text = '<189>: 2015 Apr 13 11:15:10 CST: %ETHPORT-5-SPEED: Interface Ethernet103/1/17, operational speed changed to 1 Gbps'

--text = '<188>Mar 23 2015 08:45:46 Quidway %%01IFNET/4/IF_STATE(l)[143635]:Interface Ethernet0/0/13 has turned into DOWN state.'

--text = '17-Aug-2015 16:12:14.997 INFO [Thread-41] com.duowan.yy.utility.ToolUtility.doGet 执行Get===>http://dcmnew.sysop.duowan.com//webservice/agentmaintencewebservice/sendEmail?applicationKey=openapi&id=743341'

--text = '[2015-08-13 09:58:40.161259] I [rpcsvc.c:2142:rpcsvc_set_outstanding_rpc_limit] 0-rpc-service: Configured rpc.outstanding-rpc-limit with value 16'

--text = '<154>: 2015 Apr 12 09:17:01 CST: last message repeated 4 times'

--text = 'Sep 13 00:10:02 ubuntu CRON[4240]: pam_unix(cron:session): session closed for user root'



--(?P<year>\\d+)(?P<month>[01]\\d(?!:))(?P<day>[0123]\\d(?!:))(?!:)

--text = '13-Aug-2013 16:12:14.997 INFO [Thread-21] com.splunk.ip.utility.FxhfVbmvgtp.loRis 执行Get===>http://kurtis.denis.splunk.com//hermelinda/dqsxcnvlqruggckifigrewgd/roseMarie?gwjwsixwvrcXld=yolande&id=331211'

--text = '117.136.0.164 10.162.206.227:8080 0.427 - [21/Nov/2015:08:05:29 +0800] "POST mobile.oneapm.com/mobile/data" 200 877 566 "-" "Dalvik/1.6.0 (Linux; U; Android 4.4.2; MI 3W MIUI/eng.android.20140822213815)"'

--text = '58.20.20.195 10.162.206.227:8080 0.011 - [21/Nov/2015:08:00:00 +0800] "POST mobile.oneapm.com/mobile/data" 200 815 566 "-" "Dalvik/1.6.0 (Linux; U; Android 4.4.2; SM-N9008V Build/KOT49H)"'

--text = '115.208.81.86 10.173.3.39:8080 0.023 - [21/Nov/2015:08:00:45 +0800] "POST mobile.oneapm.com/mobile/data" 200 861 566 "-" "Dalvik/1.6.0 (Linux; U; Android 4.4.2; Lenovo 2 A7-30TC Build/KOT49H)"'

--text = '123.12.31.107 10.162.206.227:8080 0.009 - [23/Nov/2015:09:09:27 +0800] "POST mobile.oneapm.com/mobile/data" 200 977 566 "-" "Dalvik/1.6.0 Compatible (TVM xx; YunOS 3.0; Linux; U; Android 4.4.4 Compatible; AF101_HCB Build/KTU84P)"'

--text = '120.2.2.157 10.162.206.227:8080 0.017 - [21/Nov/2015:08:00:14 +0800] "POST mobile.oneapm.com/mobile/data" 200 858 566 "-" "Dalvik/1.6.0 Compatible (TVM xx; YunOS 3.0; Linux; U; Android 4.4.4 Compatible; AF101_HCB Build/KTU84P)"'

--text = '221.2.21.32 10.173.3.39:8080 0.009 - [21/Nov/2015:08:08:08 +0800] "POST mobile.oneapm.com/mobile/data" 200 719 566 "-" "Dalvik/1.6.0 (Linux; U; Android 4.4.4; MI 3W MIUI/5.11.13)"'

text = '17-Aug-2015 16:12:14.997 INFO [Thread-41] com.duowan.yy.utility.ToolUtility.doGet 执行Get===>http://dcmnew.sysop.duowan.com//webservice/'


function print_table(f)
    for k,v in pairs(f) do
        print(k,v)
    end
end

datetimematch = getAllMatches_test(text)

if datetimematch then
print('===datetimematch===')
print_table(datetimematch)
else
    print('no matchs')
end
print('===_pattern===\n',_pattern)
print('===_n===\n',_n)
print_table(match_datetime(text))
print('===time_names===\n')
print_table(time_names)

