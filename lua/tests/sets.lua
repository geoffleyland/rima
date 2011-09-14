-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local index = require("rima.index")
local sum = require("rima.operators.sum")
local number_t = require("rima.types.number_t")
local rima = require("rima")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local R = index.R
  local E = core.eval

  do
    local x, Q = R"x, Q"
    T:check_equal(sum.build{Q}(x[Q]), "sum{Q}(x[Q])")
    T:check_equal(E(sum.build{Q}(x[Q])), "sum{Q}(x[Q])")
  end

  do
    local x, y, z, Q, R, r = R"x, y, z, Q, R, r"
    local S = { x = {10}, Q = {"a"}, y={{z=13}} }
    T:check_equal(sum.build{r=Q}(x[r]), "sum{r in Q}(x[r])")
    T:check_equal(E(sum.build{r=Q}(x[r]), S), 10)
    T:check_equal(sum.build{r=x}(r), "sum{r in x}(r)")
    T:check_equal(E(sum.build{r=x}(r), S), 10)
    T:check_equal(E(sum.build{r=x}(r+1), S), 11)
    T:check_equal(E(sum.build{r=y}(r.z), S), 13)
  end

  do 
    local x, y, z, Q, R, r = R"x, y, z, Q, R, r"
    local S = scope.new{ x = { 10, 20, 30 }, Q = {"a", "b", "c"}, z = { a=100, b=200, c=300 }, R = rima.range(2, r) }  
    T:check_equal(E(sum.build{r=Q}(x[r]), S), 60)
    T:check_equal(E(sum.build{Q=Q}(x[Q]), S), 60)
    T:check_equal(sum.build{y=Q}(x[y]), "sum{y in Q}(x[y])")
    T:check_equal(sum.build{Q=Q}(x[Q]), "sum{Q in Q}(x[Q])")
    T:check_equal(E(sum.build{y=Q}(x[y]), S), 60)
    T:check_equal(sum.build{y=Q}(rima.ord(y)), "sum{y in Q}(ord(y))")
    T:check_equal(E(sum.build{y=Q}(rima.ord(y)), S), 6)

    T:check_equal(E(sum.build{y=x}(y), S), 60)
    T:check_equal(E(sum.build{y=x}(x[y]), S), 60)
    T:check_equal(E(sum.build{y=x}(x[y] + y), S), 120)
    T:check_equal(E(sum.build{y=Q}(x[y] + z[y]), S), 660)
  end

  do
    local x, y, z, Q, R, r = R"x, y, z, Q, R, r"
    local S = scope.new{ Q = {"a"}, x = { number_t.free() }, z = { a=number_t.free() } }
    T:check_equal(E(sum.build{y=x}(y), S), "x[1]")
    T:check_equal(E(sum.build{y=z}(y), S), "z.a")
    T:check_equal(E(sum.build{y=x}(x[y]), S), "x[1]")
    T:check_equal(E(sum.build{y=z}(z[y]), S), "z.a")
    T:check_equal(E(sum.build{y=Q}(x[y]), S), "x[1]")
    T:check_equal(lib.dump(E(sum.build{y=Q}(x[y]), S)), "index(address{\"x\", 1})")
    T:check_equal(lib.dump(E(sum.build{y=Q}(z[y]), S)), "index(address{\"z\", \"a\"})")
    T:check_equal(E(sum.build{y=Q}(x[y] + z[y]), S), "x[1] + z.a")
  end

  do
    local x, y, z, Q, R, r = R"x, y, z, Q, R, r"
    local S = scope.new{ Q = {"a", "b", "c"}, x = { number_t.free(), number_t.free(), number_t.free() }, z = { a=number_t.free(), b=number_t.free(), c=number_t.free() } }
    T:check_equal(E(sum.build{y=x}(y), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(sum.build{y=z}(y), S), "z.a + z.b + z.c")
    T:check_equal(E(sum.build{y=x}(x[y]), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(sum.build{y=z}(z[y]), S), "z.a + z.b + z.c")
    T:check_equal(E(sum.build{y=Q}(x[y]), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(sum.build{y=Q}(x[y] + z[y]), S), "x[1] + x[2] + x[3] + z.a + z.b + z.c")
  end

  do
    local x, y, z, Q, R, r = R"x, y, z, Q, R, r"
    local S = scope.new{ x = { 10, 20, 30 }, Q = {"a", "b", "c"}, z = { a=100, b=200, c=300 }, R = rima.range(2, r) }  
    T:check_equal(sum.build{R=R}(R), "sum{R in R}(R)")
    T:check_equal(sum.build{R=rima.range(2, r)}(R), "sum{R in range(2, r)}(R)")
    T:check_equal(sum.build{R=rima.range(2, 10)}(R), "sum{R in range(2, 10)}(R)")
    T:check_equal(E(sum.build{R=R}(R), S), "sum{R in range(2, r)}(R)")
    T:check_equal(E(sum.build{y=R}(y), S), "sum{y in range(2, r)}(y)")
    T:check_equal(E(sum.build{y=rima.range(2, r)}(y), S), "sum{y in range(2, r)}(y)")
    T:check_equal(E(sum.build{y=rima.range(2, 10)}(y), S), 54)
    S.r = 10
    T:check_equal(E(sum.build{R=R}(R), S), 54)
    T:check_equal(E(sum.build{y=R}(y), S), 54)
    T:check_equal(E(sum.build{y=rima.range(2, r)}(y), S), 54)
  end

  do
    local x, y, k, v = R"x, y, k, v"
    local S = scope.new{ x = { 10, 20, 30 }, y = { 10, 20, 30, a = 10 } }
    T:check_equal(sum.build{["k, v"]=rima.pairs(x)}(k + v), "sum{k, v in pairs(x)}(k + v)")
    T:check_equal(sum.build{["k, v"]=rima.ipairs(x)}(k + v), "sum{k, v in ipairs(x)}(k + v)")
    T:check_equal(E(sum.build{["k, v"]=rima.pairs(x)}(k + v), S), 66)
    T:check_equal(E(sum.build{["k, v"]=rima.pairs(y)}(v), S), 70)
    T:check_equal(E(sum.build{["k, v"]=rima.ipairs(y)}(v), S), 60)
  end

  do
    local t, v = R"t, v"
    local S = scope.new{ t={ {b=5} }}
    T:check_equal(sum.build{["_, v"]=rima.ipairs(t)}(v.a * v.b), "sum{_, v in ipairs(t)}(v.a*v.b)")
    T:check_equal(E(sum.build{["_, v"]=rima.ipairs(t)}(v.b), S), 5)
    T:check_equal(E(sum.build{["_, v"]=rima.ipairs(t)}(v.a), S), "t[1].a")
    T:check_equal(E(sum.build{["_, v"]=rima.ipairs(t)}(v.a * v.b), S), "5*t[1].a")
  end

  do
    local t, v = R"t, v"
    local S = scope.new{ t={ {b=5}, {b=6}, {b=7} }}
    T:check_equal(sum.build{["_, v"]=rima.ipairs(t)}(v.a * v.b), "sum{_, v in ipairs(t)}(v.a*v.b)")
    T:check_equal(E(sum.build{["_, v"]=rima.ipairs(t)}(v.b), S), 18)
    T:check_equal(E(sum.build{["_, v"]=rima.ipairs(t)}(v.a * v.b), S), "5*t[1].a + 6*t[2].a + 7*t[3].a")
  end

  do
    local x, X = R"x, X"
    local S = scope.new{ X = {a=1, b=2} }
    T:check_equal(E(sum.build{["_, x"]=rima.pairs(X)}(x), S), 3)
    local S1 = scope.new(S, { X = {c=3, d=4} })
    T:check_equal(E(sum.build{["_, x"]=rima.pairs(X)}(x), S1), 10)
  end

  do
    local x, X, r = R"x, X, r"
    local S = scope.new{ r = rima.range(1, 3) }
    S.X[r] = number_t.free()
    T:check_equal(E(sum.build{r=r}(r), S), 6)
    T:check_equal(E(sum.build{r=r}(r * x[r]), S), "x[1] + 2*x[2] + 3*x[3]")
  end

  do
    local d, D = R"d, D"
    T:check_equal(E(sum.build{d=D}(d), scope.new{D={7}}), 7)
    T:check_equal(E(sum.build{d=D}(d.a), scope.new{D={{a=13}}}), 13)
    local S = scope.new{D={{a=17}}}
    S.D[d].b = 19
    local e = sum.build{d=D}(d.b)
    T:check_equal(E(e, S), 19)
    T:check_equal(E(sum.build{d=D}(d.a * d.b), S), 17*19)
  end

  do
    local a, d, D = R"a, d, D"
    T:check_equal(E(sum.build{d=D}(d^2), scope.new{}), "sum{d in D}(d^2)")
    T:check_equal(E(sum.build{d=D}(d^2), scope.new{D={7}}), 49)
    T:check_equal(E(sum.build{d=D}(2+d), scope.new{D={a}}), "2 + a")
    T:check_equal(E(sum.build{d=D}(d+d), scope.new{D={a}}), "2*a")
    T:check_equal(E(sum.build{d=D}(2*d), scope.new{D={a}}), "2*a")
    T:check_equal(E(sum.build{d=D}(d*d), scope.new{D={a}}), "a^2")
    T:check_equal(E(sum.build{d=D}(d^2), scope.new{D={a}}), "a^2")
  end

  return T:close()
end

-- EOF -------------------------------------------------------------------------

