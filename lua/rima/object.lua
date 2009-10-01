-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local rawget, rawtype = rawget, type
local getmetatable, setmetatable = getmetatable, setmetatable
local error = error

module(...)

-- Types -----------------------------------------------------------------------

local object = _M
object.__typename = "object"


function object:new(o, typename)
  o = o or {}
  if typename then o.__typename = typename end
  self.__index = self
  return setmetatable(o, self)
end


function object.isa(o, mt)
  if rawtype(mt) ~= "table" then
    error(("bad argument #2 to 'rima.object.isa' (table expected, got %s)"):format(rawtype(mt)), 0)
  end

  repeat
     o = getmetatable(o)
     if o == mt then return true end
  until not o
  return false
end


function object.type(o)
  local function z(p)
    if rawtype(p) == "table" then
      local t = rawget(p, "__typename")
      if t then return t end
    end
    local q = getmetatable(p)
    return p == q and rawtype(o) or z(q)
  end
  return z(o)
end


-- EOF -------------------------------------------------------------------------

