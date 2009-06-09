-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local proxy = require("rima.proxy")
local object = require("rima.object")

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local mt = {}

  local p = proxy:new({}, mt, "my_type")
  T:test(object.isa(p, mt), "isa(o, mt)")
  T:check_equal(object.type(p), "my_type", "type(proxy) == 'my_type'")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

