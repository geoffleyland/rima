-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local tests = require("rima.tests")
local object = require("rima.object")

module(...)

-- Undefined (base) Type -------------------------------------------------------

local undefined_t = object:new(_M, "undefined_t")


-- String representation -------------------------------------------------------

function undefined_t:__tostring()
  return "undefined"
end

function undefined_t:describe(s)
  return ("%s undefined"):format(s)
end

function undefined_t:includes(v, env)
  return true
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(isa(undefined_t:new(), undefined_t), "isa(undefined_t:new(), undefined_t)")
  T:equal_strings(type(undefined_t:new()), 'undefined_t', "type(undefined_t:new()) == 'undefined_t'")
  T:equal_strings(undefined_t:new(), 'undefined', "tostring(undefined_t:new()) == 'undefined'")

  T:equal_strings(undefined_t:new():describe("a"), 'a undefined', "undefined:describe()'")
  T:equal_strings(undefined_t:new():describe("b"), 'b undefined', "undefined:describe()'")
  T:test(undefined_t:new():includes(1), "undefined:includes()'")
  T:test(undefined_t:new():includes("a"), "undefined:includes()'")
  T:test(undefined_t:new():includes({}), "undefined:includes()'")
  T:test(undefined_t:new():includes(nil), "undefined:includes()'")
  
  return T:close()
end


-- EOF -------------------------------------------------------------------------

