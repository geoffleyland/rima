-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local proxy = require("rima.lib.proxy")
local object = require("rima.lib.object")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local my_type = object:new_class({}, "my_type")

  local p = proxy:new({}, my_type)
  T:test(my_type:isa(p), "my_type:isa(p)")
  T:check_equal(object.type(p), "my_type", "type(proxy) == 'my_type'")
  
  local o = {}
  local p = proxy:new(o, my_type)
  T:check_equal(proxy.O(p), o)
  T:check_equal(proxy.O(o), o)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

