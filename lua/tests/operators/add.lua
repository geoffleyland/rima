-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local expression_tester = require("test.expression_tester")
require("rima.ref")
local add = require("rima.operators.add")
local object = require("rima.lib.object")
local expression = require("rima.expression")
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
  local OB = function(e, S) return add.__eval(e, S, B) end
  local OE = function(e, S) return add.__eval(e, S, E) end

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

  T:check_equal(OB({{1, a}}, S), "a")
  T:check_equal(OB({{1, a}, {2, a}}, S), "3*a")

  T:check_equal(OE({{1, a}}, S), 5)
  T:check_equal(OE({{1, a}, {2, a}}, S), 15)

  local U = expression_tester(T, "a, b, c", { a = 5, b = rima.positive() })  

  U{ "b - b", S="b - b", D="+(1*ref(b), -1*ref(b))", ES=0 }
  U{ "b + b", S="b + b", D="+(1*ref(b), 1*ref(b))", ES="2*b", ED="+(2*ref(b))" }

  U{ "2 + b + 3", S="2 + b + 3", D="+(1*+(1*number(2), 1*ref(b)), 1*number(3))", ES="5 + b" }
  U{ "2 - (3 + b)", S="2 - (3 + b)", D="+(1*number(2), -1*+(1*number(3), 1*ref(b)))", ES="-1 - b" }

  U{ "2 + a + 3", S="2 + a + 3", D="+(1*+(1*number(2), 1*ref(a)), 1*number(3))", ES=10 }
  U{ "2 - (3 + a)", S="2 - (3 + a)", D="+(1*number(2), -1*+(1*number(3), 1*ref(a)))", ES=-6 }
  U{ "-a", S="-a", D="+(-1*ref(a))", ES=-5 }

  -- Tests with mul
  U{ "2 + 3*b", S="2 + 3*b", D="+(1*number(2), 1**(number(3)^1, ref(b)^1))", ED="+(1*number(2), 3*ref(b))" }
  U{ "2 + b*c", S="2 + b*c", D="+(1*number(2), 1**(ref(b)^1, ref(c)^1))", ED="+(1*number(2), 1**(ref(b)^1, ref(c)^1))" }
  U{ "2 + 5*b*c", S="2 + 5*b*c", D="+(1*number(2), 1**(*(number(5)^1, ref(b)^1)^1, ref(c)^1))", ED="+(1*number(2), 5**(ref(b)^1, ref(c)^1))" }

  -- Check we simplify the identity (+0)
  U{ "1 + 2*b - 1", S="1 + 2*b - 1", ED="+(2*ref(b))" }
  U{ "1 + b - 1", S="1 + b - 1", ED="ref(b)" }

  return T:close()
end


-- EOF -------------------------------------------------------------------------

