-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local expression = require("rima.expression")
local ref = require("rima.ref")
local iteration = require("rima.iteration")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local B = core.bind
  local E = core.eval
  local D = lib.dump

  T:test(ref:isa(ref:new{name="a"}), "isa(ref:new(), ref)")

  local function check_strings(v, s, d)
    T:check_equal(v, s, "repr(ref)")
    T:check_equal(ref.describe(v), d, "ref:describe()")
  end

  check_strings(ref:new{name="a"}, "a", "a undefined")
  check_strings(ref:new{name="b", type=rima.free()}, "b", "-inf <= b <= inf, b real")  
  check_strings(ref:new{name="c", type=rima.positive()}, "c", "0 <= c <= inf, c real")  
  check_strings(ref:new{name="d", type=rima.negative()}, "d", "-inf <= d <= 0, d real")  
  check_strings(ref:new{name="e", type=rima.integer()}, "e", "0 <= e <= inf, e integer")  
  check_strings(ref:new{name="f", type=rima.binary()}, "f", "f binary")  

  -- simple references and types
  do
    local S = rima.scope.new{ a = rima.free(1, 10), b = 1, c = "c" }

    -- binding
    T:expect_ok(function() B(ref:new{name="z"}, S) end, "bind ok")
    T:check_equal(B(ref:new{name="z"}, S), "z", "undefined returns a ref")
    T:check_equal(B(ref:new{name="b"}, S), "b", "defined returns a ref")

    -- simple reference evaluating
    T:expect_ok(function() E(ref:new{name="z"}, S) end, "z undefined")
    T:check_equal(E(ref:new{name="z"}, S), "z", "undefined remains an unbound variable")
    T:check_equal(E(ref:new{name="b"}, S), 1, "defined returns a value")

    -- types
    T:check_equal(E(ref:new{name="a"}, S), "a")
    T:expect_error(function() E(ref:new{name="a", type=rima.free(11, 20)}, S) end,
      "the type of 'a' %(1 <= a <= 10, a real%) and the type of the reference %(11 <= a <= 20, a real%) are mutually exclusive")
    T:expect_error(function() E(ref:new{name="b", type=rima.free(11, 20)}, S) end,
      "'b' %(1%) is not of type '11 <= b <= 20, b real'")
    T:check_equal(E(ref:new{name="b", rima.binary()}, S), 1)
  end

  -- references to references
  do
    local a, b, c = rima.R"a, b, c"
    local S1 = rima.scope.new{ a = b, b = 17 }
    local S2 = rima.scope.new{ a = b - c, b = 1 }
    
    -- binding
    T:check_equal(B(a, S1), "b")
    T:check_equal(B(a, S2), "b - c")

    -- evaluating
    T:check_equal(E(a, S1), 17)
    T:check_equal(E(a, S2), "1 - c")
  end

  do
    local a = rima.R"a"
    local S = rima.scope.new{ a = rima.free() }
    
    T:check_equal(ref.is_simple(a), true)
    T:check_equal(ref.is_simple(E(a, S)), false)
  end

  do
    local a, b = rima.R"a, b"
    local t = {}
    expression.set(a, t, 10)
    T:check_equal(t.a, 10)
  end

  do
    local x, y = rima.R"x, y"
    local S = rima.scope.new{ x = 2, y = 3 }
    T:check_equal(rima.E(x + y, S), 5)
    T:check_equal(rima.E(x - y, S), -1)
    T:check_equal(rima.E(-x + y, S), 1)
    T:check_equal(rima.E(x * y, S), 6)
    T:check_equal(rima.E(x / y, S), 2/3)
    T:check_equal(rima.E(x ^ y, S), 8)
  end   

  do
    local f, x, y = rima.R"f, x, y"
    local S = rima.scope.new{ x = 2, f = rima.F({y}, y + 5) }
    T:check_equal(rima.E(f(x), S), 7)
  end   

  -- tests for references to references
  -- tests for references to functions
  -- tests for references to expressions

  return T:close()
end

-- EOF -------------------------------------------------------------------------

