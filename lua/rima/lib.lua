-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, getmetatable, select, tostring, type, unpack =
      ipairs, getmetatable, select, tostring, type, unpack
local table = require("table")

module(...)


--------------------------------------------------------------------------------

function imap(f, t)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end


function concat(t, s, f)
  if f then
    return table.concat(imap(f, t), s)
  else
    return table.concat(t, s)
  end
end


function packn(...)
  return { n=select("#", ...), ... }
end


function packs(status, ...)
  return status, { n=select("#", ...), ... }
end


function unpackn(t)
  return unpack(t, 1, t.n)
end


function getmetamethod(obj, methodname)
  local mt = getmetatable(obj)
  return mt and mt[methodname]
end


-- String representation -------------------------------------------------------

local number_format = "%.4g"
function set_number_format(f)
  number_format = f
end


function simple_repr(o, format)
  if type(o) == "number" then
    local nf = format.numbers or number_format
    return nf:format(o)
  else
    return tostring(o)
  end
end


local no_format = {}

function repr(o, format)
  format = format or no_format

  local f = getmetamethod(o, "__repr")
  if f then
    return f(o, format)
  elseif format.dump then
    return object.type(o).."("..simple_repr(o, format)..")"
  else
    return simple_repr(o, format)
  end
end


function __tostring(o)
  return getmetatable(o).__repr(o, no_format)
end


function concat_repr(t, format)
  return concat(t, ", ", function(i) return repr(i, format) end)
end


local dump_format = { dump=true }
function dump(e)
  return repr(e, dump_format)
end


-- EOF -------------------------------------------------------------------------
