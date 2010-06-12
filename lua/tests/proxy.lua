-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local proxy = require("rima.proxy")
local object = require("rima.lib.object")

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local mt = {}

  local p = proxy:new({}, mt, "my_type")
  T:test(object.isa(p, mt), "isa(o, mt)")
  T:check_equal(object.type(p), "my_type", "type(proxy) == 'my_type'")
  
  local o = {}
  local p = proxy:new(o, mt, "o")
  T:check_equal(proxy.O(p), o)
  T:check_equal(proxy.O(o), o)
  T:check_equal(proxy.P(o), p)
  T:check_equal(proxy.P(p), p)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

