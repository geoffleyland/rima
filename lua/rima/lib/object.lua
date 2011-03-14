-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

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


function object.isa(mt, o)
  if rawtype(mt) ~= "table" then
    error(("bad argument #1 to 'rima.lib.object.isa' (table expected, got %s)"):format(rawtype(mt)), 0)
  end

  repeat
     local o2 = getmetatable(o)
     if o2 == mt then return true end
     if o2 == o then return false end -- avoid recursion if a table is its own metatable
     o = o2
  until not o
  return false
end


function object.type(o)
  local t = rawtype(o)
  if t ~= "table" then return t end
  
  while true do
    t = rawget(o, "__typename")
    if t then return t end
    local o2 = getmetatable(o)
    if not o2 or o2 == o then return "table" end  -- avoid recursion again
    o = o2
  end
end


-- EOF -------------------------------------------------------------------------

