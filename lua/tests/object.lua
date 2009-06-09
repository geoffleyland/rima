-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local object = require("rima.object")

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local o = object:new()
  T:test(object.isa(o, object), "isa(o, object)")
  T:check_equal(object.type(o), "object", "type(object) == 'object'")

  local subobj = object:new(nil, "subobj")
  T:check_equal(object.type(subobj), "subobj", "type(subobj) == 'subobj'")
  local s = subobj:new()
  T:test(object.isa(s, object), "isa(s, object)")
  T:test(object.isa(s, subobj), "isa(s, subobj)")
  T:test(not object.isa(s, {}), "isa(s, {})")
  T:test(not object.isa({}, subobj), "isa({}, subobj)")
  T:test(not object.isa({}, object), "isa({}, object)")
  T:test(not object.isa(object:new(), subobj), "isa(object:new(), subobj)")
  
  
  T:check_equal(object.type(s), "subobj", "type(s) == 'subobj'")
  T:check_equal(object.type(1), "number", "type(1) == 'number'")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

