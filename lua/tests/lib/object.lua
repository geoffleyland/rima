-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local object = require("rima.lib.object")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local o = object:new()
  T:test(object:isa(o), "object:isa(o)")
  T:check_equal(object.type(o), "object", "type(object) == 'object'")

  local subobj = object:new(nil, "subobj")
  T:check_equal(object.type(subobj), "subobj", "type(subobj) == 'subobj'")
  local s = subobj:new()
  T:check_equal(object.type(s), "subobj", "type(s) == 'subobj'")
  T:test(object:isa(s), "object:isa(s)")
  T:test(subobj:isa(s), "subobj:isa(s)")
  T:test(not object.isa({}, s), "isa({}, s)")
  T:test(not subobj:isa({}), "subobj:isa({})")
  T:test(not object:isa({}), "object:isa({})")
  T:test(not subobj:isa(object:new()), "subobj:isa(object:new())")
  
  T:expect_error(function() object.isa("thing", {}) end,
    "bad argument #1 to 'rima%.lib%.object%.isa' %(table expected, got string%)")
  
  T:check_equal(object.type(s), "subobj", "type(s) == 'subobj'")
  T:check_equal(object.type(1), "number", "type(1) == 'number'")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

