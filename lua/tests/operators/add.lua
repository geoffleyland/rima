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

  local D = expression.dump
  local B = expression.bind
  local E = expression.eval

  local OD = function(e) return add.__repr(e, { dump=true }) end
  local OS = function(e) return add.__repr(e) end
  local OE = function(e, S) return add.__eval(e, S) end

  T:test(object.isa(add:new(), add), "isa(add, add:new())")
  T:check_equal(object.type(add:new()), "add", "type(add:new()) == 'add'")

--  T:expect_ok(function() add:check({}) end)
--  T:expect_ok(function() add:check({{1, 2}}) end) 

  T:check_equal(OD({{1, 1}}), "+(1*number(1))")
  T:check_equal(OS({{1, 1}}), "1")
  T:check_equal(OD({{1, 2}, {3, 4}}), "+(1*number(2), 3*number(4))")
  T:check_equal(OS({{1, 2}, {3, 4}}), "2 + 12")
  T:check_equal(OS({{-1, 2}, {3, 4}}), "-2 + 12")
  T:check_equal(OS({{-1, 2}, {-3, 4}}), "-2 - 12")

  local S = rima.scope.new()
  T:check_equal(OE({{1, 2}}, S), 2)
  T:check_equal(OE({{1, 2}, {3, 4}}, S), 14)
  T:check_equal(OE({{1, 2}, {3, 4}, {5, 6}}, S), 44)
  T:check_equal(OE({{1, 2}, {3, 4}, {-5, 6}}, S), -16)
  T:check_equal(OE({{1, 2}, {3, 4}, {5, -6}}, S), -16)

  local a, b, c = rima.R"a,b,c"
  rima.scope.set(S, { a = 5, b = rima.positive() })
  T:check_equal(OD({{1, a}}), "+(1*ref(a))")
  T:check_equal(OE({{1, a}}, S), 5)
  T:check_equal(OE({{1, a}, {2, a}}, S), 15)

  T:check_equal(2 + (3 + b), "2 + 3 + b")
  T:check_equal(2 - (3 + b), "2 - (3 + b)")

  T:check_equal(E(b - b, S), 0)
  T:check_equal(E(b + b, S), "2*b")
  T:check_equal(E(2 + (3 + b), S), "5 + b")
  T:check_equal(E(2 - (3 + b), S), "-1 - b")

  T:check_equal(E(2 + (3 + a), S), 10)
  T:check_equal(E(2 - (3 + a), S), -6)
  T:check_equal(E(-a, S), -5)

  T:check_equal(D(E(2 + 3*b, S)), "+(1*number(2), 3*ref(b))")
  T:check_equal(D(E(2 + b*c, S)), "+(1*number(2), 1**(ref(b)^1, ref(c)^1))")
  T:check_equal(D(E(2 + 5*b*c, S)), "+(1*number(2), 5**(ref(b)^1, ref(c)^1))")

  T:check_equal(D(OE({{2, S.b}}, S)), "+(2*ref(b))")
  T:check_equal(D(OE({{1, S.b}}, S)), "ref(b)", "checking we simplify identity")

  -- Tests including mul are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

