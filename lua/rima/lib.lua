-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local typename = object.typename


------------------------------------------------------------------------------

local lib = {}

------------------------------------------------------------------------------

function lib.getmetamethod(obj, methodname)
  local mt = getmetatable(obj)
  return mt and mt[methodname]
end


function lib.append(t, ...)
  local l = #t
  for i = 1, select("#", ...) do
    t[l + i] = select(i, ...)
  end
end


function lib.imap(f, t)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end


function lib.concat(t, s, f)
  t = (f and lib.imap(f, t)) or t
  return table.concat(t, s)
end


------------------------------------------------------------------------------

-- Convert an object if it has a metamethod with the right name
function lib.convert(obj, methodname)
  local f = lib.getmetamethod(obj, methodname)
  if f then
    return f(obj)
  else
    return obj
  end
end


------------------------------------------------------------------------------

local function is_identifier(v)
  return v:match("^[_%a][_%w]*$")
end


function lib.is_identifier_string(v)
  return type(v) == "string" and is_identifier(v)
end


------------------------------------------------------------------------------

local number_format = "%.4g"
function lib.set_number_format(f)
  number_format = f
end


function lib.simple_repr(o, format)
  local t = typename(o)
  if t == "number" then
    local nf = format.numbers or number_format
    return nf:format(o)
  elseif format.format == "dump" then
    if t == "string" then
      return ("%q"):format(o)
    elseif t == "boolean" then
      return tostring(o)
    elseif t == "table" then
      local s = "table"..": { "
      local count = 0
      for k, v in pairs(o) do
        if count == 3 then s = s..",..." break end
        if count > 0 then s = s..", " end
        s = s..tostring(k).."="..tostring(v)
        count = count + 1
      end
      s = s.." }"
      return s
    elseif t == "nil" then
      return "nil"
    else
      return t.."("..tostring(o)..")"
    end
  elseif format.format == "latex" then
    if t == "table" then
      return "\\text{table}"
    elseif t == "boolean" then
      return "\\text{"..tostring(o).."}"
    elseif t == "nil" then
      return "\\text{nil}"
    elseif t == "string" then
      if o:len() == 1 then
        return o
      elseif is_identifier(o) then
        return "\\text{"..o:gsub("_", "\\_").."}"
      else
        return "\\text{``"..o:gsub("_", "\\_").."''}"
      end
    else
      return tostring(o)
    end
  else
    if t == "table" then
      return "table"
    else
      return tostring(o)
    end
  end
end


local no_format = {}

function lib.repr(o, format)
  format = format or no_format

  local f = lib.getmetamethod(o, "__repr")
  if f then
    return f(o, format)
  else
    return lib.simple_repr(o, format)
  end
end


function lib.__tostring(o)
  return getmetatable(o).__repr(o, no_format)
end


function lib.concat_repr(t, format, sep)
  return lib.concat(t, sep or ", ", function(i) return lib.repr(i, format) end)
end


local dump_format = { format="dump" }
function lib.dump(e)
  return lib.repr(e, dump_format)
end


------------------------------------------------------------------------------

return lib

------------------------------------------------------------------------------

