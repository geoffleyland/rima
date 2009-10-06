-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local function_v = require("rima.values.function_v")
local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local B = expression.bind
  local E = expression.eval

  T:test(object.isa(function_v:new({"a"}, 3), function_v), "isa(function_v:new(), function_v)")
  T:check_equal(object.type(function_v:new({"a"}, 3)), "function_v", "type(function_v:new()) == 'function_v'")

  T:expect_error(function() function_v:new({1}, 1) end,
    "expected string or simple reference, got '1' %(number%)")
  do
    local a = rima.R"a"
    T:expect_error(function() function_v:new({a[1]}, 1) end,
      "expected string or simple reference, got 'a%[1%]' %(ref%)")
    local S = scope.create{ b=rima.free() }
    T:expect_error(function() function_v:new({S.b}, 1) end,
      "expected string or simple reference, got 'b' %(ref%)")
  end


  local a, b, c, x = rima.R"a, b, c, x"

  do
    local f = rima.R"f"
    local S = scope.create{ f = function_v:new({a}, 3) }
    T:expect_error(function() rima.E(f(), S) end,
      "the function needs to be called with at least 1 arguments, got 0")
    T:expect_error(function() rima.E(f(1, 2), S) end,
      "the function needs to be called with 1 arguments, got 2")
    T:expect_error(function() rima.E(f(1, 2, 3), S) end,
      "the function needs to be called with 1 arguments, got 3")
  end

  do
    local f = function_v:new({a}, 3)
    local S = scope.new()
    T:check_equal(f, "function(a) return 3", "function description")
    T:check_equal(f:call({5}, S, E), 3)
  end
  
  do
    local f = function_v:new({"a"}, 3 + a)
    local S = scope.create{ x = rima.free() }
    T:check_equal(f, "function(a) return 3 + a", "function description")
    T:check_equal(f:call({x}, S, B), "3 + x")
    T:check_equal(f:call({x}, S, E), "3 + x")
    T:check_equal(f:call({5}, S, B), "3 + a")
    T:check_equal(f:call({5}, S, E), 8)
    T:check_equal(f:call({x}, scope.spawn(S, {x=10}), B), "3 + x")
    T:check_equal(f:call({x}, scope.spawn(S, {x=10}), E), 13)
  end

  do
    local f = function_v:new({a}, b + a)
    local S = scope.create{ ["a, b"] = rima.free() }
    T:check_equal(f, "function(a) return b + a", "function description")
    T:check_equal(f:call({x}, S, E), "b + x")
    T:check_equal(f:call({5}, S, E), "5 + b")
    T:check_equal(f:call({1 + a}, S, E), "1 + a + b")
    T:check_equal(f:call({1 + b}, S, E), "1 + 2*b")
    local S2 = scope.spawn(S, {b=20})
    T:check_equal(f:call({x}, S2, E), "20 + x")
    T:check_equal(f:call({5}, S2, E), 25)
    S2.x = 100
    T:check_equal(f:call({x}, S2, E), 120)
    S2.a = 1000
    T:check_equal(f:call({x}, S2, E), 120)
  end

  do
    local f = function_v:new({a, "b"}, 1 + a, nil, b^2)
    local S = scope.create{ ["a, b"] = rima.free() }
    T:check_equal(f, "function(a, b) return 1 + a", "function description")
    T:check_equal(f:call({2 + x, 5, {x}}, S, B), "3 + b^2")
    T:check_equal(f:call({2 + x, 5, {x}}, S, E), 28)
    T:check_equal(f:call({5 * x, b, {x}}, S, E), "1 + 5*b^2")
  end

  do
    local f = rima.R"f"
    local S = scope.create{ f = function_v:new({"a", b}, 1 + a, nil, b^2) }
    local e = 1 + f(1 + x, 3, {x})
    T:check_equal(rima.E(e, S), 12)
  end

  do
    local f, x, y = rima.R"f, x, y"
    T:check_equal(rima.E(f(x), { f=rima.F({y}, rima.sin(y)) }), "sin(x)")
  end

  do
    local y = rima.R"y"
    T:check_equal(rima.F({y}, y^2)(5), 25)
  end

  -- more tests in expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

