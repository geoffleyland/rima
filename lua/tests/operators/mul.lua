-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local mul = require("rima.operators.mul")
local object = require("rima.object")
local expression = require("rima.expression")
require("rima.types.number_t")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(object.isa(mul:new(), mul), "isa(mul:new(), mul)")
  T:check_equal(object.type(mul:new()), "mul", "type(mul:new()) == 'mul'")

--  T:expect_ok(function() mul:check({}) end)
--  T:expect_ok(function() mul:check({{1, 2}}) end) 

  T:check_equal(mul:dump({{1, 1}}), "*(number(1)^1)")
  T:check_equal(mul:_tostring({{1, 1}}), "1")
  T:check_equal(mul:dump({{1, 2}, {3, 4}}), "*(number(2)^1, number(4)^3)")
  T:check_equal(mul:_tostring({{1, 2}, {3, 4}}), "2*4^3")
  T:check_equal(mul:_tostring({{-1, 2}, {3, 4}}), "1/2*4^3")
  T:check_equal(mul:_tostring({{-1, 2}, {-3, 4}}), "1/2/4^3")

  local S = rima.scope.new()
  T:check_equal(mul:eval(S, {{1, 2}}), 2)
  T:check_equal(mul:eval(S, {{1, 2}, {3, 4}}), 128)
  T:check_equal(mul:eval(S, {{2, 2}, {1, 4}, {1, 6}}), 96)
  T:check_equal(mul:eval(S, {{2, 2}, {1, 4}, {-1, 6}}), 8/3)
  T:check_equal(mul:eval(S, {{2, 2}, {1, 4}, {1, -6}}), -96)

  local a, b = rima.R"a,b"
  rima.scope.set(S, {a = 5, b = rima.positive()})
  T:check_equal(mul:dump({{1, a}}), "*(ref(a)^1)")
  T:check_equal(mul:eval(S, {{1, a}}), 5)
  T:check_equal(mul:eval(S, {{1, a}, {2, a}}), 125)

  T:check_equal(2 * (3 * b), "2*3*b")
  T:check_equal(2 / (3 * b), "2/(3*b)")

  T:check_equal(rima.E(b / b, S), 1)
  T:check_equal(rima.E(b * b, S), "b^2")
  T:check_equal(rima.E(2 * (3 * b), S), "6*b")
  T:check_equal(rima.E(2 / (3 * b), S), "0.6667/b")

  T:check_equal(rima.E(2 * (3 * a), S), 30)
  T:check_equal(rima.E(2 / (3 * a), S), 2/15)

  T:check_equal(expression.dump(rima.E(2 * (b + b), S)), "*(number(4)^1, ref(b)^1)")
  T:check_equal(expression.dump(rima.E(2 * b^5, S)), "*(number(2)^1, ref(b)^5)")

  T:check_equal(expression.dump(mul:eval(S, {{2, b}})), "*(ref(b)^2)")
  T:check_equal(expression.dump(mul:eval(S, {{1, b}})), "ref(b)", "checking we simplify identity")
  T:check_equal(expression.dump(rima.E(1 * b, S)), "ref(b)", "checking we simplify identity")
  T:check_equal(expression.dump(rima.E(2 * b / 2, S)), "ref(b)", "checking we simplify identity")

  T:check_equal(mul:eval(S, {{0, S.b}}), 1, "checking we simplify 0")
  T:check_equal(rima.E(0 * S.b, S), 0, "checking we simplify 0")

  -- Tests including add and pow are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

