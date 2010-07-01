-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
require("rima.ref")
local pow = require("rima.operators.pow")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
require("rima.public")
local rima = rima

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local E = core.eval

  T:test(pow:isa(pow:new()), "isa(pow, pow:new())")
  T:check_equal(object.type(pow:new()), "pow", "type(pow:new()) == 'pow'")

--  T:expect_error(function() pow:check(1) end, "expecting a table for 'args', got 'number'") 
--  T:expect_error(function() pow:check({}) end,
--    "expecting expressions for base and exponent, got 'nil' %(nil%) and 'nil' %(nil%)")
--  T:expect_ok(function() pow:check({1, 2}) end) 
--  T:expect_error(function() pow:check({{1, 2}}) end,
--    "expecting expressions for base and exponent, got 'table: [^']+' %(table%) and 'nil' %(nil%)") 
--  T:expect_error(function() pow:check({"hello"}) end,
--    "expecting expressions for base and exponent, got 'hello' %(string%) and 'nil' %(nil%)") 

  local a, b = rima.R"a, b"
  local S = rima.scope.new{ a = 5 }
  T:check_equal(lib.dump(a^2), "^(ref(a), 2)")
  T:check_equal(a^2, "a^2")
  T:check_equal(a^b, "a^b")
  T:check_equal(E(a^2, S), 25)
  T:check_equal(lib.dump(2^a), "^(2, ref(a))")
  T:check_equal(E(2^a, S), 32)

  -- Identities
  T:check_equal(E(0^b, S), 0)
  T:check_equal(E(1^b, S), 1)
  T:check_equal(E(b^0, S), 1)
  T:check_equal(lib.dump(E(b^1, S)), "ref(b)")

  -- Tests including add and mul are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

