-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local add = require("rima.operators.add")
local object = require("rima.object")
local expression = require("rima.expression")
require("rima.types.number_t")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(object.isa(add:new(), add), "isa(add, add:new())")
  T:check_equal(object.type(add:new()), "add", "type(add:new()) == 'add'")

--  T:expect_ok(function() add:check({}) end)
--  T:expect_ok(function() add:check({{1, 2}}) end) 

  T:check_equal(add:dump({{1, 1}}), "+(1*number(1))")
  T:check_equal(add:_tostring({{1, 1}}), "1")
  T:check_equal(add:dump({{1, 2}, {3, 4}}), "+(1*number(2), 3*number(4))")
  T:check_equal(add:_tostring({{1, 2}, {3, 4}}), "2 + 12")
  T:check_equal(add:_tostring({{-1, 2}, {3, 4}}), "-2 + 12")
  T:check_equal(add:_tostring({{-1, 2}, {-3, 4}}), "-2 - 12")

  local S = rima.scope.new()
  T:check_equal(add:eval(S, {{1, 2}}), 2)
  T:check_equal(add:eval(S, {{1, 2}, {3, 4}}), 14)
  T:check_equal(add:eval(S, {{1, 2}, {3, 4}, {5, 6}}), 44)
  T:check_equal(add:eval(S, {{1, 2}, {3, 4}, {-5, 6}}), -16)
  T:check_equal(add:eval(S, {{1, 2}, {3, 4}, {5, -6}}), -16)

  local a, b = rima.R"a,b"
  rima.scope.set(S, { a = 5, b = rima.positive() })
  T:check_equal(add:dump({{1, a}}), "+(1*ref(a))")
  T:check_equal(add:eval(S, {{1, a}}), 5)
  T:check_equal(add:eval(S, {{1, a}, {2, a}}), 15)

  T:check_equal(2 + (3 + b), "2 + 3 + b")
  T:check_equal(2 - (3 + b), "2 - (3 + b)")

  T:check_equal(rima.E(b - b, S), 0)
  T:check_equal(rima.E(b + b, S), "2*b")
  T:check_equal(rima.E(2 + (3 + b), S), "5 + b")
  T:check_equal(rima.E(2 - (3 + b), S), "-1 - b")

  T:check_equal(rima.E(2 + (3 + a), S), 10)
  T:check_equal(rima.E(2 - (3 + a), S), -6)
  T:check_equal(rima.E(-a, S), -5)
  T:check_equal(rima.E(2 + (3 + b), S), "5 + b")

  T:check_equal(expression.dump(add:eval(S, {{2, S.b}})), "+(2*ref(b))")
  T:check_equal(expression.dump(add:eval(S, {{1, S.b}})), "ref(b)", "checking we simplify identity")

  -- Tests including mul are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

