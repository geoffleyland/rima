-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local add = require("rima.operators.add")

local series = require("test.series")
local expression_tester = require("test.expression_tester")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")
local scope = require("rima.scope")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local R = index.R
  local E = core.eval
  local D = lib.dump

  local OD = function(e) return add.__repr(e, { format="dump" }) end
  local OS = function(e) return add.__repr(e, {}) end
  local OE = function(e, S) return add.__eval(e, S) end

  T:test(object.typeinfo(add:new()).add, "typeinfo(add:new()).add")
  T:check_equal(object.typename(add:new()), "add", "typename(add:new()) == 'add'")

  T:check_equal(OD({{1, 1}}), "+(1*1)")
  T:check_equal(OS({{1, 1}}), "1")
  T:check_equal(OD({{1, 2}, {3, 4}}), "+(1*2, 3*4)")
  T:check_equal(OS({{1, 2}, {3, 4}}), "2 + 12")
  T:check_equal(OS({{-1, 2}, {3, 4}}), "-2 + 12")
  T:check_equal(OS({{-1, 2}, {-3, 4}}), "-2 - 12")

  local S = scope.new()
  T:check_equal(OE({{1, 2}}, S), 2)
  T:check_equal(OE({{1, 2}, {3, 4}}, S), 14)
  T:check_equal(OE({{1, 2}, {3, 4}, {5, 6}}, S), 44)
  T:check_equal(OE({{1, 2}, {3, 4}, {-5, 6}}, S), -16)
  T:check_equal(OE({{1, 2}, {3, 4}, {5, -6}}, S), -16)

  local a, b, c = R"a,b,c"
  S.a = 5
  T:check_equal(OD({{1, a}}), '+(1*index(address{"a"}))')

  T:check_equal(OE({{1, a}}, S), 5)
  T:check_equal(OE({{1, a}, {2, a}}, S), 15)

  local U = expression_tester(T, "a, b, c", { a = 5 })  

  U{ "b - b", S="b - b", D='+(1*index(address{"b"}), -1*index(address{"b"}))', ES=0 }
  U{ "b + b", S="b + b", D='+(1*index(address{"b"}), 1*index(address{"b"}))', ES="2*b", ED='+(2*index(address{"b"}))' }

  U{ "2 + b + 3", S="2 + b + 3", D='+(1*+(1*2, 1*index(address{"b"})), 1*3)', ES="5 + b" }
  U{ "2 - (3 + b)", S="2 - (3 + b)", D='+(1*2, -1*+(1*3, 1*index(address{"b"})))', ES="-1 - b" }

  U{ "2 + a + 3", S="2 + a + 3", D='+(1*+(1*2, 1*index(address{"a"})), 1*3)', ES=10 }
  U{ "2 - (3 + a)", S="2 - (3 + a)", D='+(1*2, -1*+(1*3, 1*index(address{"a"})))', ES=-6 }
  U{ "-a", S="-a", D='+(-1*index(address{"a"}))', ES=-5 }

  -- Tests with mul
  U{ "2 + 3*b", S="2 + 3*b", D='+(1*2, 1**(3^1, index(address{"b"})^1))', ED='+(1*2, 3*index(address{"b"}))' }
  U{ "2 + b*c", S="2 + b*c", D='+(1*2, 1**(index(address{"b"})^1, index(address{"c"})^1))', ED='+(1*2, 1**(index(address{"b"})^1, index(address{"c"})^1))' }
  U{ "2 + 5*b*c", S="2 + 5*b*c", D='+(1*2, 1**(*(5^1, index(address{"b"})^1)^1, index(address{"c"})^1))', ED='+(1*2, 5**(index(address{"b"})^1, index(address{"c"})^1))' }

  -- Check we simplify the identity (+0)
  U{ "1 + 2*b - 1", S="1 + 2*b - 1", ED='+(2*index(address{"b"}))' }
  U{ "1 + b - 1", S="1 + b - 1", ED='index(address{"b"})' }

  return T:close()
end


-- EOF -------------------------------------------------------------------------

