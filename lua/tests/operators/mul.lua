-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
require("rima.ref")
local mul = require("rima.operators.mul")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local expression = require("rima.expression")
require("rima.types.number_t")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = lib.dump
  local B = expression.bind
  local E = expression.eval

  local OD = function(e) return mul.__repr(e, { dump=true }) end
  local OS = function(e) return mul.__repr(e) end
  local OB = function(e, S) return mul.__eval(e, S, B) end
  local OE = function(e, S) return mul.__eval(e, S, E) end

  T:test(mul:isa(mul:new()), "isa(mul:new(), mul)")
  T:check_equal(object.type(mul:new()), "mul", "type(mul:new()) == 'mul'")

--  T:expect_ok(function() mul:check({}) end)
--  T:expect_ok(function() mul:check({{1, 2}}) end) 

  T:check_equal(OD({{1, 1}}), "*(number(1)^1)")
  T:check_equal(OS({{1, 1}}), "1")
  T:check_equal(OD({{1, 2}, {3, 4}}), "*(number(2)^1, number(4)^3)")
  T:check_equal(OS({{1, 2}, {3, 4}}), "2*4^3")
  T:check_equal(OS({{-1, 2}, {3, 4}}), "1/2*4^3")
  T:check_equal(OS({{-1, 2}, {-3, 4}}), "1/2/4^3")

  local S = rima.scope.new()
  T:check_equal(OE({{1, 2}}, S), 2)
  T:check_equal(OE({{1, 2}, {3, 4}}, S), 128)
  T:check_equal(OE({{2, 2}, {1, 4}, {1, 6}}, S), 96)
  T:check_equal(OE({{2, 2}, {1, 4}, {-1, 6}}, S), 8/3)
  T:check_equal(OE({{2, 2}, {1, 4}, {1, -6}}, S), -96)

  local a, b = rima.R"a,b"
  rima.scope.set(S, {a = 5, b = rima.positive()})
  T:check_equal(OD({{1, a}}), "*(ref(a)^1)")

  T:check_equal(OB({{1, a}}, S), "a")
  T:check_equal(OB({{1, a}, {2, a}}, S), "a^3")

  T:check_equal(OE({{1, a}}, S), 5)
  T:check_equal(OE({{1, a}, {2, a}}, S), 125)

  T:check_equal(2 * (3 * b), "2*3*b")
  T:check_equal(2 / (3 * b), "2/(3*b)")

  T:check_equal(E(b / b, S), 1)
  T:check_equal(E(b * b, S), "b^2")
  T:check_equal(E(2 * (3 * b), S), "6*b")
  T:check_equal(E(2 / (3 * b), S), "0.6667/b")

  T:check_equal(E(2 * (3 * a), S), 30)
  T:check_equal(E(2 / (3 * a), S), 2/15)

  T:check_equal(D(E(2 * (b + b), S)), "*(number(4)^1, ref(b)^1)")
  T:check_equal(D(E(2 * b^5, S)), "*(number(2)^1, ref(b)^5)")

  T:check_equal(D(OE({{2, b}}, S)), "*(ref(b)^2)")
  T:check_equal(D(OE({{1, b}}, S)), "ref(b)", "checking we simplify identity")
  T:check_equal(D(E(1 * b, S)), "ref(b)", "checking we simplify identity")
  T:check_equal(D(E(2 * b / 2, S)), "ref(b)", "checking we simplify identity")

  T:check_equal(OE({{0, S.b}}, S), 1, "checking we simplify 0")
  T:check_equal(E(0 * S.b, S), 0, "checking we simplify 0")

  -- Tests including add and pow are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

