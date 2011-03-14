-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local proxy = require("rima.lib.proxy")
local object = require("rima.lib.object")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local mt = {}

  local p = proxy:new({}, mt, "my_type")
  T:test(object.isa(mt, p), "isa(mt, p)")
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

