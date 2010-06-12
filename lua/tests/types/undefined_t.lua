-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local type = type

local series = require("test.series")
local undefined_t = require("rima.types.undefined_t")
local object = require("rima.lib.object")

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(undefined_t:isa(undefined_t:new()), "isa(undefined_t:new(), undefined_t)")
  T:check_equal(object.type(undefined_t:new()), 'undefined_t', "type(undefined_t:new()) == 'undefined_t'")
  T:check_equal(undefined_t:new(), 'undefined', "repr(undefined_t:new()) == 'undefined'")

  T:check_equal(undefined_t:new():describe("a"), 'a undefined', "undefined:describe()'")
  T:check_equal(undefined_t:new():describe("b"), 'b undefined', "undefined:describe()'")
  T:test(undefined_t:new():includes(1), "undefined:includes()'")
  T:test(undefined_t:new():includes("a"), "undefined:includes()'")
  T:test(undefined_t:new():includes({}), "undefined:includes()'")
  T:test(undefined_t:new():includes(nil), "undefined:includes()'")
  
  return T:close()
end


-- EOF -------------------------------------------------------------------------

