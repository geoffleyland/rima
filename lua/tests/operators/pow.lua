-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local pow = require("rima.operators.pow")
local object = require("rima.object")
local expression = require("rima.expression")
require("rima.public")
local rima = rima

module(...)


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(object.isa(pow:new(), pow), "isa(pow, pow:new())")
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
  local S = rima.scope.create{ a = 5 }
  T:check_equal(expression.dump(a^2), "^(ref(a), number(2))")
  T:check_equal(expression.eval(a^2, S), 25)
  T:check_equal(expression.dump(2^a), "^(number(2), ref(a))")
  T:check_equal(expression.eval(2^a, S), 32)

  -- Identities
  T:check_equal(expression.eval(0^b, S), 0)
  T:check_equal(expression.eval(1^b, S), 1)
  T:check_equal(expression.eval(b^0, S), 1)
  T:check_equal(expression.dump(expression.eval(b^1, S)), "ref(b)")

  -- Tests including add and mul are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

