-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local func = require("rima.func")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local scope = require("rima.scope")
local number_t = require("rima.types.number_t")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = interface.eval
  local D = lib.dump
  local R = interface.R
  local F = interface.func

  T:test(object.typeinfo(func:new({"a"}, 3)).func, "typeinfo(func:new()).func")
  T:check_equal(object.typename(func:new({"a"}, 3)), "func", "typename(func:new()) == 'func'")

  T:expect_error(function() func:new({1}, 1) end,
    "expected string or identifier, got '1' %(number%)")
  do
    local a = R"a"
    T:expect_error(function() F{a[1]}(1) end,
      "expected string or identifier, got 'a%[1%]' %(index%)")
    local S = scope.new{ b=number_t.free() }
    T:expect_error(function() F{S.b}(1) end,
      "expected string or identifier, got 'b' %(index%)")
  end

  do
    local a = R"a"
    local f
    T:expect_ok(function() f = func:new({"a"}, 3) end)
    T:expect_ok(function() f = F{a}(3) end)
    
    T:check_equal(f, "function(a) return 3")
    T:check_equal(f(5), 3)
  end

  do
    local a, x, y = R"a, x, y"
    local f
    T:expect_ok(function() f = func:new({"a"}, 3 + a) end)
    T:expect_ok(function() f = F{a}(3 + a) end)    
    
    -- repr
    T:check_equal(f, "function(a) return 3 + a")

    -- simple evaluation
    T:check_equal(f(x), "3 + x")
    T:check_equal(f(5), 8)
    T:check_equal(f:call({x}, {x=10}), 13)
    T:check_equal(f(x + y), "3 + x + y")
    T:check_equal(f:call({x + y}, {x=10}), "13 + y")
    
    -- partial evaluation
    T:check_equal(f(), "function(a) return 3 + a")
    T:check_equal(f()(x), "3 + x")
    
    -- name overloading
    T:check_equal(D(f(x)), "+(1*3, 1*index(address{\"x\"}))")
    T:check_equal(E(f(x), {x=10}), 13)
    T:check_equal(D(f(2*a)), "+(1*3, 2*index(address{\"a\"}))")
    T:check_equal(E(f(2*a), {a=10}), 23)
  end

  do
    local a, b, x, y = R"a, b, x, y"
    local f
    T:expect_ok(function() f = func:new({"a"}, a + b) end)
    T:expect_ok(function() f = F{a}(a + b) end)    

    -- repr
    T:check_equal(f, "function(a) return a + b")
    
    -- simple evaluation
    T:check_equal(f(x), "b + x")
    T:check_equal(f(5), "5 + b")
    T:check_equal(f(1 + a), "1 + a + b")
    T:check_equal(f(1 + b), "1 + 2*b")
    T:check_equal(f:call({x}, {b=20}), "20 + x")
    T:check_equal(f:call({5}, {b=20}), 25)
    T:check_equal(f:call({x}, {b=20,x=100}), 120)

    -- partial evaluation
    T:check_equal(f(), "function(a) return a + b")
    T:check_equal(f()(x), "b + x")
    T:check_equal(f:call({}, {b=10}), "function(a) return 10 + a")

    -- name overloading
    T:check_equal(f:call({x}, {b=20,x=100,a=1000}), 120)
  end

  do
    local a, b, x, y = R"a, b, x, y"
    local f
    T:expect_ok(function() f = func:new({"a", "b"}, a + 3*b) end)
    T:expect_ok(function() f = F{"a", b}(a + 3*b) end)    

    -- repr
    T:check_equal(f, "function(a, b) return a + 3*b")
    
    -- simple evaluation
    T:check_equal(f(x, y), "x + 3*y")
    T:check_equal(f(5, 7), 26)
    T:check_equal(f(1+a, 2*b), "1 + a + 6*b")
    T:check_equal(f(b, b), "4*b")
    T:check_equal(f:call({x, y}, {x=1}), "1 + 3*y")
    T:check_equal(f:call({5, y}, {y=10, b=1000}), 35)

    -- partial evaluation
    T:check_equal(f(5), "function(b) return 5 + 3*b")
    T:check_equal(f(nil, 7), "function(a) return 21 + a")
    T:check_equal(f()(x)(y), "x + 3*y")
    T:check_equal(f()(nil, x)(y), "3*x + y")
  end

  do
    local a, b, c, t, s, u = R"a, b, c, t, s, u"
    local S = {
      a={w={{x=10,y={z=100}},{x=20,y={z=200}}}},
      t=interface.func{b}(a.w[b].x),
      s=interface.func{b}(a.w[b].y),
      u=interface.func{b}(a.q[b].y) }

    T:check_equal(D(t(1)), "call(index(address{\"t\"}), 1)")
    T:check_equal(t(1), "t(1)")
    T:expect_ok(function() E(t(1), S) end, "eval")
    T:check_equal(E(t(1), S), 10)
    T:check_equal(E(t(2), S), 20)

    T:check_equal(D(s(1).z), "index(call(index(address{\"s\"}), 1), address{\"z\"})")
    T:check_equal(s(1).z, "s(1).z")
    T:expect_ok(function() E(s(1).z, S) end, "eval")
    T:check_equal(E(s(1).z, S), 100)
    T:check_equal(E(s(2).z, S), 200)

    T:check_equal(s(1).q, "s(1).q")
    T:expect_ok(function() E(s(1).q, S) end, "eval")
    T:check_equal(E(s(1).q, S), "a.w[1].y.q")
    T:check_equal(E(s(2).q, S), "a.w[2].y.q")

    T:check_equal(u(1).z, "u(1).z")
    T:expect_ok(function() E(u(1).z, S) end, "eval")
    T:check_equal(E(u(1).z, S), "a.q[1].y.z")
    T:check_equal(E(u(2).z, S), "a.q[2].y.z")
  end

  do
    local a, b, i = R"a, b, i"
    local S = { a = { { 5 } }, b = interface.func{i}(a[1][i]) }
    T:check_equal(E(a[1][1], S), 5)
    T:check_equal(E(b(1), S), 5)
    T:expect_error(function() E(b(1)[1], S) end, "can't index a number")
  end

  do
    local f, x, y = R"f, x, y"
    local S = { f = interface.func{y}(y + x, { x=5 }) }
    T:check_equal(E(f(x), S), "5 + x")
    S.x = 100
    T:check_equal(E(f(x), S), 105)
  end

  do
    local f, x, y = R"f, x, y"
    local S = scope.new{ f = interface.func{y}(y + x, { x=5 }) }
    local e = E(f(x), S)
    local S2 = scope.new(S, {x=200})
    T:check_equal(E(e, S2), 205)
  end

  do
    local f, x, y, u, v = R"f, x, y, u, v"
    local F = interface.func{x}(x * y, { y=5 })
    local e = E(u * f(v), { f=F })
    T:check_equal(e, 5*u*v)
    T:check_equal(E(e, { u=2, v=3 }), 30)
  end

  do
    local f, x = R"f, x"
    T:check_equal(E(f(x), { f=interface.func{x}(x) }), "x")
  end
end


------------------------------------------------------------------------------

