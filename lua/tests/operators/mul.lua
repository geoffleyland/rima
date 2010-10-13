-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local mul = require("rima.operators.mul")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = lib.dump
  local E = core.eval

  local OD = function(e) return mul.__repr(e, { format="dump" }) end
  local OS = function(e) return mul.__repr(e, {}) end
  local OE = function(e, S) return mul.__eval(e, S, E) end

  T:test(mul:isa(mul:new()), "isa(mul:new(), mul)")
  T:check_equal(object.type(mul:new()), "mul", "type(mul:new()) == 'mul'")

  T:check_equal(OD({{1, 1}}), "*(1^1)")
  T:check_equal(OS({{1, 1}}), "1")
  T:check_equal(OD({{1, 2}, {3, 4}}), "*(2^1, 4^3)")
  T:check_equal(OS({{1, 2}, {3, 4}}), "2*4^3")
  T:check_equal(OS({{-1, 2}, {3, 4}}), "1/2*4^3")
  T:check_equal(OS({{-1, 2}, {-3, 4}}), "1/2/4^3")

  do
    local S = {}
    T:check_equal(OE({{1, 2}}, S), 2)
    T:check_equal(OE({{1, 2}, {3, 4}}, S), 128)
    T:check_equal(OE({{2, 2}, {1, 4}, {1, 6}}, S), 96)
    T:check_equal(OE({{2, 2}, {1, 4}, {-1, 6}}, S), 8/3)
    T :check_equal(OE({{2, 2}, {1, 4}, {1, -6}}, S), -96)
  end

  do
    local a, b = rima.R"a,b"
    S = { a = 5 }

    T:check_equal(OD({{1, a}}), '*(index(address{"a"})^1)')

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

    T:check_equal(D(E(2 * (b + b), S)), '*(4^1, index(address{"b"})^1)')
    T:check_equal(D(E(2 * b^5, S)), '*(2^1, index(address{"b"})^5)')

    T:check_equal(D(OE({{2, b}}, S)), '*(index(address{"b"})^2)')
    T:check_equal(D(OE({{1, b}}, S)), 'index(address{"b"})', "checking we simplify identity")
    T:check_equal(D(E(1 * b, S)), 'index(address{"b"})', "checking we simplify identity")
    T:check_equal(D(E(2 * b / 2, S)), 'index(address{"b"})', "checking we simplify identity")

    T:check_equal(OE({{0, b}}, S), 1, "checking we simplify 0")
    T:check_equal(E(0 * b, S), 0, "checking we simplify 0")
  end

  -- Tests including add and pow are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

