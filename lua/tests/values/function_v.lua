-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local object = require("rima.lib.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
local function_v = require("rima.values.function_v")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = expression.dump
  local B = expression.bind
  local E = expression.eval

  T:test(object.isa(function_v, function_v:new({"a"}, 3)),
    "isa(function_v:new(), function_v)")
  T:check_equal(object.type(function_v:new({"a"}, 3)),
    "function_v", "type(function_v:new()) == 'function_v'")

  T:expect_error(function() function_v:new({1}, 1) end,
    "expected string or simple reference, got '1' %(number%)")
  do
    local a = rima.R"a"
    T:expect_error(function() function_v:new({a[1]}, 1) end,
      "expected string or simple reference, got 'a%[1%]' %(index%)")
    local S = scope.new{ b=rima.free() }
    T:expect_error(function() function_v:new({S.b}, 1) end,
      "expected string or simple reference, got 'b' %(ref%)")
  end

  local a, b, c, x = rima.R"a, b, c, x"

  do
    local f = rima.R"f"
    local S = scope.new{ f = function_v:new({a}, 3) }
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
    local S = scope.new{ x = rima.free() }
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
    local S = scope.new{ ["a, b"] = rima.free() }
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
    local S = scope.new{ ["a, b"] = rima.free() }
    T:check_equal(f, "function(a, b) return 1 + a", "function description")
    T:check_equal(f:call({2 + x, 5, {x}}, S, B), "3 + b^2")
    T:check_equal(f:call({2 + x, 5, {x}}, S, E), 28)
    T:check_equal(f:call({5 * x, b, {x}}, S, E), "1 + 5*b^2")
  end

  do
    local f = rima.R"f"
    local S = scope.new{ f = function_v:new({"a", b}, 1 + a, nil, b^2) }
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

  do
    local a, b, c, t, s, u = rima.R"a, b, c, t, s, u"
    local S = scope.new{
      a={w={{x=10,y={z=100}},{x=20,y={z=200}}}},
      t=rima.F({b}, a.w[b].x),
      s=rima.F({b}, a.w[b].y),
      u=rima.F({b}, a.q[b].y) }

    T:check_equal(D(t(1)), "call(ref(t), number(1))")
    T:check_equal(t(1), "t(1)")
    T:expect_ok(function() B(t(1), S) end, "binding")
    T:check_equal(B(t(1), S), "a.w[1].x")
    T:expect_ok(function() E(t(1), S) end, "eval")
    T:check_equal(E(t(1), S), 10)
    T:check_equal(E(t(2), S), 20)
    local e = B(t(1), S)
    T:check_equal(E(e, S), 10)

    T:check_equal(D(s(1).z),
      "index(call(ref(s), number(1)), address(string(z)))")
    T:check_equal(s(1).z, "s(1).z")
    T:expect_ok(function() B(s(1).z, S) end, "binding")
    T:check_equal(B(s(1).z, S), "a.w[1].y.z")
    T:expect_ok(function() E(s(1).z, S) end, "eval")
    T:check_equal(E(s(1).z, S), 100)
    T:check_equal(E(s(2).z, S), 200)
    local e = B(s(1).z, S)
    T:check_equal(E(e, S), 100)

    T:check_equal(s(1).q, "s(1).q")
    T:expect_ok(function() B(s(1).q, S) end, "binding")
    T:check_equal(B(s(1).q, S), "a.w[1].y.q")
    T:expect_ok(function() E(s(1).q, S) end, "eval")
    T:check_equal(E(s(1).q, S), "a.w[1].y.q")
    T:check_equal(E(s(2).q, S), "a.w[2].y.q")
    local e = B(s(1).q, S)
    T:check_equal(E(e, S), "a.w[1].y.q")

    T:check_equal(u(1).z, "u(1).z")
    T:expect_ok(function() B(u(1).z, S) end, "binding")
    T:check_equal(B(u(1).z, S), "a.q[1].y.z")
    T:expect_ok(function() E(u(1).z, S) end, "eval")
    T:check_equal(E(u(1).z, S), "a.q[1].y.z")
    T:check_equal(E(u(2).z, S), "a.q[2].y.z")
    local e = B(u(1).z, S)
    T:check_equal(E(e, S), "a.q[1].y.z")
  end

  do
    local a, b, i = rima.R"a, b, i"
    local S = rima.scope.new{ a = { { 5 } }, b = rima.F({i}, a[1][i]) }
    T:check_equal(E(a[1][1], S), 5)
    T:check_equal(E(b(1), S), 5)
    T:expect_error(function() E(b(1)[1], S) end,
      "error evaluating 'b%(1%)%[1%]' as 'a%[1, 1, 1%]':"..
      ".*address: error resolving 'a%[1, 1, 1%]':"..
      " 'a%[1, 1%]' is not indexable %(got '5' number%)")
  end

  do
    local f, x, y = rima.R"f, x, y"
    local S = rima.scope.new{ f = rima.F({y}, y + x, { x=5 }) }
    T:check_equal(E(f(x), S), "5 + x")
    S.x = 100
    T:check_equal(E(f(x), S), 105)
  end

  do
    local f, x, y = rima.R"f, x, y"
    local S = rima.scope.new{ f = rima.F({y}, y + x, { x=5 }) }
    local e = E(f(x), S)
    local S2 = rima.scope.spawn(S)
    S2.x = 200
    T:check_equal(E(e, S2), 205)
  end

  do
    local f, x, y, u, v = rima.R"f, x, y, u, v"
    local F = rima.F{x}(x * y, { y=5 })
    local e = rima.E(u * f(v), { f=F })
    T:check_equal(e, 5*u*v)
    T:check_equal(rima.E(e, { u=2, v=3 }), 30)
  end

  do
    local f, x = rima.R"f, x"
    T:check_equal(rima.E(f(x), { f=rima.F{x}(x) }), "x")
  end

  -- more tests in expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

