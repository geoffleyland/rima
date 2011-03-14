-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local rima = require("rima")
require("rima.types.number_t")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local E = core.eval

  local x, y, z, Q, R, r = rima.R"x, y, z, Q, R, r"

  T:check_equal(rima.sum{Q}(x[Q]), "sum{Q}(x[Q])")
  T:check_equal(E(rima.sum{Q}(x[Q])), "sum{Q}(x[Q])")

  do
    local S = { x = {10}, Q = {"a"}, y={{z=13}} }
    T:check_equal(rima.sum{r=Q}(x[r]), "sum{r in Q}(x[r])")
    T:check_equal(E(rima.sum({r=Q}, x[r]), S), 10)
    T:check_equal(rima.sum{r=x}(r), "sum{r in x}(r)")
    T:check_equal(E(rima.sum{r=x}(r), S), 10)
    T:check_equal(E(rima.sum({r=x}, r+1), S), 11)
    T:check_equal(E(rima.sum({r=y}, r.z), S), 13)
  end

  local S = scope.new{ x = { 10, 20, 30 }, Q = {"a", "b", "c"}, z = { a=100, b=200, c=300 }, R = rima.range(2, r) }  
  T:check_equal(E(rima.sum({r=Q}, x[r]), S), 60)
  T:check_equal(E(rima.sum({Q=Q}, x[Q]), S), 60)
  T:check_equal(rima.sum{y=Q}(x[y]), "sum{y in Q}(x[y])")
  T:check_equal(rima.sum{Q=Q}(x[Q]), "sum{Q in Q}(x[Q])")
  T:check_equal(E(rima.sum({y=Q}, x[y]), S), 60)
  T:check_equal(rima.sum({y=Q}, rima.ord(y)), "sum{y in Q}(ord(y))")
  T:check_equal(E(rima.sum{y=Q}(rima.ord(y)), S), 6)

  T:check_equal(E(rima.sum{y=x}(y), S), 60)
  T:check_equal(E(rima.sum{y=x}(x[y]), S), 60)
  T:check_equal(E(rima.sum{y=x}(x[y] + y), S), 120)
  T:check_equal(E(rima.sum{y=Q}(x[y] + z[y]), S), 660)

  do
    local S = scope.new{ Q = {"a"}, x = { rima.free() }, z = { a=rima.free() } }
    T:check_equal(E(rima.sum{y=x}(y), S), "x[1]")
    T:check_equal(E(rima.sum{y=z}(y), S), "z.a")
    T:check_equal(E(rima.sum{y=x}(x[y]), S), "x[1]")
    T:check_equal(E(rima.sum{y=z}(z[y]), S), "z.a")
    T:check_equal(E(rima.sum{y=Q}(x[y]), S), "x[1]")
    T:check_equal(lib.dump(E(rima.sum{y=Q}(x[y]), S)), "index(address{\"x\", 1})")
    T:check_equal(lib.dump(E(rima.sum{y=Q}(z[y]), S)), "index(address{\"z\", \"a\"})")
    T:check_equal(E(rima.sum{y=Q}(x[y] + z[y]), S), "x[1] + z.a")
  end

  do
    local S = scope.new{ Q = {"a", "b", "c"}, x = { rima.free(), rima.free(), rima.free() }, z = { a=rima.free(), b=rima.free(), c=rima.free() } }
    T:check_equal(E(rima.sum{y=x}(y), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(rima.sum{y=z}(y), S), "z.a + z.b + z.c")
    T:check_equal(E(rima.sum{y=x}(x[y]), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(rima.sum{y=z}(z[y]), S), "z.a + z.b + z.c")
    T:check_equal(E(rima.sum{y=Q}(x[y]), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(rima.sum{y=Q}(x[y] + z[y]), S), "x[1] + x[2] + x[3] + z.a + z.b + z.c")
  end

  T:check_equal(rima.sum({R=R}, R), "sum{R in R}(R)")
  T:check_equal(rima.sum({R=rima.range(2, r)}, R), "sum{R in range(2, r)}(R)")
  T:check_equal(rima.sum({R=rima.range(2, 10)}, R), "sum{R in range(2, 10)}(R)")
  T:check_equal(E(rima.sum({R=R}, R), S), "sum{R in range(2, r)}(R)")
  T:check_equal(E(rima.sum({y=R}, y), S), "sum{y in range(2, r)}(y)")
  T:check_equal(E(rima.sum({y=rima.range(2, r)}, y), S), "sum{y in range(2, r)}(y)")
  T:check_equal(E(rima.sum({y=rima.range(2, 10)}, y), S), 54)
  S.r = 10
  T:check_equal(E(rima.sum({R=R}, R), S), 54)
  T:check_equal(E(rima.sum({y=R}, y), S), 54)
  T:check_equal(E(rima.sum({y=rima.range(2, r)}, y), S), 54)

  do
    local x, k, v = rima.R"x, k, v"
    local S = rima.scope.new{ x = { 10, 20, 30 }, y = { 10, 20, 30, a = 10 } }
    T:check_equal(rima.sum{["k, v"]=rima.pairs(x)}(k + v), "sum{k, v in pairs(x)}(k + v)")
    T:check_equal(rima.sum{["k, v"]=rima.ipairs(x)}(k + v), "sum{k, v in ipairs(x)}(k + v)")
    T:check_equal(E(rima.sum({["k, v"]=rima.pairs(x)}, k + v), S), 66)
    T:check_equal(E(rima.sum({["k, v"]=rima.pairs(y)}, v), S), 70)
    T:check_equal(E(rima.sum({["k, v"]=rima.ipairs(y)}, v), S), 60)
  end

  do
    local t, v = rima.R"t, v"
    local S = rima.scope.new{ t={ {b=5} }}
    T:check_equal(rima.sum({["_, v"]=rima.ipairs(t)}, v.a * v.b), "sum{_, v in ipairs(t)}(v.a*v.b)")
    T:check_equal(E(rima.sum({["_, v"]=rima.ipairs(t)}, v.b), S), 5)
    T:check_equal(E(rima.sum{["_, v"]=rima.ipairs(t)}(v.a), S), "t[1].a")
    T:check_equal(E(rima.sum({["_, v"]=rima.ipairs(t)}, v.a * v.b), S), "5*t[1].a")
  end

  do
    local t, v = rima.R"t, v"
    local S = rima.scope.new{ t={ {b=5}, {b=6}, {b=7} }}
    T:check_equal(rima.sum({["_, v"]=rima.ipairs(t)}, v.a * v.b), "sum{_, v in ipairs(t)}(v.a*v.b)")
    T:check_equal(E(rima.sum({["_, v"]=rima.ipairs(t)}, v.b), S), 18)
    T:check_equal(E(rima.sum({["_, v"]=rima.ipairs(t)}, v.a * v.b), S), "5*t[1].a + 6*t[2].a + 7*t[3].a")
  end

  do
    local x, X = rima.R"x, X"
    local S = rima.scope.new{ X = {a=1, b=2} }
    T:check_equal(E(rima.sum({["_, x"]=rima.pairs(X)}, x), S), 3)
    local S1 = rima.scope.new(S, { X = {c=3, d=4} })
    T:check_equal(E(rima.sum({["_, x"]=rima.pairs(X)}, x), S1), 10)
  end

  do
    local x, X, r = rima.R"x, X, r"
    local S = rima.scope.new{ r = rima.range(1, 3) }
    S.X[r] = rima.free()
    T:check_equal(E(rima.sum{r=r}(r), S), 6)
    T:check_equal(E(rima.sum{r=r}(r * x[r]), S), "x[1] + 2*x[2] + 3*x[3]")
  end

  do
    local d, D = rima.R"d, D"
    T:check_equal(E(rima.sum{d=D}(d), rima.scope.new{D={7}}), 7)
    T:check_equal(E(rima.sum{d=D}(d.a), rima.scope.new{D={{a=13}}}), 13)
    local S = rima.scope.new{D={{a=17}}}
    S.D[d].b = 19
    local e = rima.sum{d=D}(d.b)
    T:check_equal(E(e, S), 19)
    T:check_equal(E(rima.sum{d=D}(d.a * d.b), S), 17*19)
  end

  do
    local a, d, D = rima.R"a, d, D"
    T:check_equal(E(rima.sum{d=D}(d^2), rima.scope.new{}), "sum{d in D}(d^2)")
    T:check_equal(E(rima.sum{d=D}(d^2), rima.scope.new{D={7}}), 49)
    T:check_equal(E(rima.sum{d=D}(2+d), rima.scope.new{D={a}}), "2 + a")
    T:check_equal(E(rima.sum{d=D}(d+d), rima.scope.new{D={a}}), "2*a")
    T:check_equal(E(rima.sum{d=D}(2*d), rima.scope.new{D={a}}), "2*a")
    T:check_equal(E(rima.sum{d=D}(d*d), rima.scope.new{D={a}}), "a^2")
    T:check_equal(E(rima.sum{d=D}(d^2), rima.scope.new{D={a}}), "a^2")
  end

  return T:close()
end

-- EOF -------------------------------------------------------------------------

