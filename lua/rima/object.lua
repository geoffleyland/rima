-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local rawget, old_type = rawget, type
local getmetatable, setmetatable = getmetatable, setmetatable

local tests = require("rima.tests")

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
  repeat
     o = getmetatable(o)
     if o == mt then return true end
  until not o
  return false
end

function object.type(o)
  function z(p)
    if old_type(p) == "table" then
      local t = rawget(p, "__typename")
      if t then return t end
    end
    local q = getmetatable(p)
    return p == q and old_type(o) or z(q)
  end
  return z(o)
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  local o = object:new()
  T:test(object.isa(o, object), "isa(o, object)")
  T:equal_strings(object.type(o), "object", "type(object) == 'object'")

  local subobj = object:new(nil, "subobj")
  T:equal_strings(object.type(subobj), "subobj", "type(subobj) == 'subobj'")
  local s = subobj:new()
  T:test(object.isa(s, object), "isa(s, object)")
  T:test(object.isa(s, subobj), "isa(s, subobj)")
  T:test(not object.isa(s, {}), "isa(s, {})")
  T:test(not object.isa({}, subobj), "isa({}, subobj)")
  T:test(not object.isa({}, object), "isa({}, object)")
  T:test(not object.isa(object:new(), subobj), "isa(object:new(), subobj)")
  
  
  T:equal_strings(object.type(s), "subobj", "type(s) == 'subobj'")
  T:equal_strings(object.type(1), "number", "type(1) == 'number'")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

