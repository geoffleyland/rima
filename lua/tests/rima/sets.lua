-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local sets = require("rima.sets")
local ref = require("rima.sets.ref")

local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local number_t = require("rima.types.number_t")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = core.eval
  local R = interface.R
  local sum = interface.sum

  do
    local i, j, I, X, Y = R"i, j, I, X, Y"
    local S = { X={10}, Y={a=20}, I={"a"} }
    T:check_equal(sum{i=ref.pairs(I)}(X[i]), "sum{i in pairs(I)}(X[i])")
    T:check_equal(E(sum{i=ref.pairs(I)}(X[i]), S), 10)

    T:check_equal(sum{["i,j"]=ref.pairs(I)}(Y[j]), "sum{i, j in pairs(I)}(Y[j])")
    T:check_equal(E(sum{["i,j"]=ref.pairs(I)}(Y[j]), S), 20)

    T:check_equal(sum{["i,j"]=ref.pairs(I)}((i+1)*X[i]*Y[j]), "sum{i, j in pairs(I)}((1 + i)*X[i]*Y[j])")
    T:check_equal(E(sum{["i,j"]=ref.pairs(I)}((i+1)*X[i]*Y[j]), S), 400)
  end

  do
    local x, y, Q, r = R"x, y, Q, r"
    local S = { x = {10}, Q = {"a"}, y={{z=13}} }
    T:check_equal(sum{r=Q}(x[r]), "sum{r in Q}(x[r])")
    T:check_equal(E(sum{r=Q}(x[r]), S), 10)
    T:check_equal(sum{r=x}(r), "sum{r in x}(r)")
    T:check_equal(E(sum{r=x}(r), S), 10)
    T:check_equal(E(sum{r=x}(r+1), S), 11)
    T:check_equal(E(sum{r=y}(r.z), S), 13)
  end

  do
    local x, y, z, Q = R"x, y, z, Q"
    local S = { Q = {"a"}, x = { number_t.free() }, z = { a=number_t.free() } }
    T:check_equal(E(sum{y=x}(y), S), "x[1]")
    T:check_equal(E(sum{y=z}(y), S), "z.a")
    T:check_equal(E(sum{y=x}(x[y]), S), "x[1]")
    T:check_equal(E(sum{y=z}(z[y]), S), "z.a")
    T:check_equal(E(sum{y=Q}(x[y]), S), "x[1]")
    T:check_equal(lib.dump(E(sum{y=Q}(x[y]), S)), "index(address{\"x\", 1})")
    T:check_equal(lib.dump(E(sum{y=Q}(z[y]), S)), "index(address{\"z\", \"a\"})")
    T:check_equal(E(sum{y=Q}(x[y] + z[y]), S), "x[1] + z.a")
  end

  do
    local x, y, z, Q = R"x, y, z, Q"
    local S =
    {
      Q = {"a", "b", "c"},
      x = { number_t.free(), number_t.free(), number_t.free() },
      z = { a=number_t.free(), b=number_t.free(), c=number_t.free() }
    }
    T:check_equal(E(sum{y=x}(y), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(sum{y=z}(y), S), "z.a + z.b + z.c")
    T:check_equal(E(sum{y=x}(x[y]), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(sum{y=z}(z[y]), S), "z.a + z.b + z.c")
    T:check_equal(E(sum{y=Q}(x[y]), S), "x[1] + x[2] + x[3]")
    T:check_equal(E(sum{y=Q}(x[y] + z[y]), S), "x[1] + x[2] + x[3] + z.a + z.b + z.c")
  end

  do
    local x, y, k, v = R"x, y, k, v"
    local S = { x = { 10, 20, 30 }, y = { 10, 20, 30, a = 10 } }
    T:check_equal(sum{["k, v"]=ref.pairs(x)}(k + v), "sum{k, v in pairs(x)}(k + v)")
    T:check_equal(E(sum{["k, v"]=ref.pairs(x)}(k + v), S), 66)
    T:check_equal(E(sum{["k, v"]=ref.pairs(y)}(v), S), 70)
  end

  do
    local x, y, k, v = R"x, y, k, v"
    local S = { x = { 10, 20, 30 }, y = { 10, 20, 30, a = 10 } }
    T:check_equal(sum{["k, v"]=ref.ipairs(x)}(k + v), "sum{k, v in ipairs(x)}(k + v)")
    T:check_equal(E(sum{["k, v"]=ref.ipairs(x)}(k + v), S), 66)
    T:check_equal(E(sum{["k, v"]=ref.ipairs(y)}(k + v), S), 66)
    T:check_equal(E(sum{["k, v"]=ref.ipairs(y)}(v), S), 60)
  end

  do
    local x, y, z, Q, R, r = R"x, y, z, Q, R, r"
    local S = scope.new{ x = { 10, 20, 30 }, Q = {"a", "b", "c"}, z = { a=100, b=200, c=300 }, R = interface.range(2, r) }  
    T:check_equal(E(sum{r=Q}(x[r]), S), 60)
    T:check_equal(E(sum{Q=Q}(x[Q]), S), 60)
    T:check_equal(sum{y=Q}(x[y]), "sum{y in Q}(x[y])")
    T:check_equal(sum{Q=Q}(x[Q]), "sum{Q in Q}(x[Q])")
    T:check_equal(E(sum{y=Q}(x[y]), S), 60)
    T:check_equal(sum{y=Q}(interface.ord(y)), "sum{y in Q}(ord(y))")
    T:check_equal(E(sum{y=Q}(interface.ord(y)), S), 6)

    T:check_equal(E(sum{y=x}(y), S), 60)
    T:check_equal(E(sum{y=x}(x[y]), S), 60)
    T:check_equal(E(sum{y=x}(x[y] + y), S), 120)
    T:check_equal(E(sum{y=Q}(x[y] + z[y]), S), 660)
  end

  do
    local x, y, z, Q, R, r = R"x, y, z, Q, R, r"
    local S = scope.new{ x = { 10, 20, 30 }, Q = {"a", "b", "c"}, z = { a=100, b=200, c=300 }, R = interface.range(2, r) }  
    T:check_equal(sum{R=R}(R), "sum{R in R}(R)")
    T:check_equal(sum{R=interface.range(2, r)}(R), "sum{R in range(2, r)}(R)")
    T:check_equal(sum{R=interface.range(2, 10)}(R), "sum{R in range(2, 10)}(R)")
    T:check_equal(E(sum{R=R}(R), S), "sum{R in range(2, r)}(R)")
    T:check_equal(E(sum{y=R}(y), S), "sum{y in range(2, r)}(y)")
    T:check_equal(E(sum{y=interface.range(2, r)}(y), S), "sum{y in range(2, r)}(y)")
    T:check_equal(E(sum{y=interface.range(2, 10)}(y), S), 54)
    S.r = 10
    T:check_equal(E(sum{R=R}(R), S), 54)
    T:check_equal(E(sum{y=R}(y), S), 54)
    T:check_equal(E(sum{y=interface.range(2, r)}(y), S), 54)
  end

  do
    local t, v = R"t, v"
    local S = scope.new{ t={ {b=5} }}
    T:check_equal(sum{["_, v"]=ref.ipairs(t)}(v.a * v.b), "sum{_, v in ipairs(t)}(v.a*v.b)")
    T:check_equal(E(sum{["_, v"]=ref.ipairs(t)}(v.b), S), 5)
    T:check_equal(E(sum{["_, v"]=ref.ipairs(t)}(v.a), S), "t[1].a")
    T:check_equal(E(sum{["_, v"]=ref.ipairs(t)}(v.a * v.b), S), "5*t[1].a")
  end

  do
    local t, v = R"t, v"
    local S = scope.new{ t={ {b=5}, {b=6}, {b=7} }}
    T:check_equal(sum{["_, v"]=ref.ipairs(t)}(v.a * v.b), "sum{_, v in ipairs(t)}(v.a*v.b)")
    T:check_equal(E(sum{["_, v"]=ref.ipairs(t)}(v.b), S), 18)
    T:check_equal(E(sum{["_, v"]=ref.ipairs(t)}(v.a * v.b), S), "5*t[1].a + 6*t[2].a + 7*t[3].a")
  end

  do
    local x, X = R"x, X"
    local S = scope.new{ X = {a=1, b=2} }
    T:check_equal(E(sum{["_, x"]=ref.pairs(X)}(x), S), 3)
    local S1 = scope.new(S, { X = {c=3, d=4} })
    T:check_equal(E(sum{["_, x"]=ref.pairs(X)}(x), S1), 10)
  end

  do
    local x, X, r = R"x, X, r"
    local S = scope.new{ r = interface.range(1, 3) }
    S.X[r] = number_t.free()
    T:check_equal(E(sum{r=r}(r), S), 6)
    T:check_equal(E(sum{r=r}(r * x[r]), S), "x[1] + 2*x[2] + 3*x[3]")
  end

  do
    local d, D = R"d, D"
    T:check_equal(E(sum{d=D}(d), scope.new{D={7}}), 7)
    T:check_equal(E(sum{d=D}(d.a), scope.new{D={{a=13}}}), 13)
    local S = scope.new{D={{a=17}}}
    S.D[d].b = 19
    local e = sum{d=D}(d.b)
    T:check_equal(E(e, S), 19)
    T:check_equal(E(sum{d=D}(d.a * d.b), S), 17*19)
  end

  do
    local a, d, D = R"a, d, D"
    T:check_equal(E(sum{d=D}(d^2), scope.new{}), "sum{d in D}(d^2)")
    T:check_equal(E(sum{d=D}(d^2), scope.new{D={7}}), 49)
    T:check_equal(E(sum{d=D}(2+d), scope.new{D={a}}), "2 + a")
    T:check_equal(E(sum{d=D}(d+d), scope.new{D={a}}), "2*a")
    T:check_equal(E(sum{d=D}(2*d), scope.new{D={a}}), "2*a")
    T:check_equal(E(sum{d=D}(d*d), scope.new{D={a}}), "a^2")
    T:check_equal(E(sum{d=D}(d^2), scope.new{D={a}}), "a^2")
  end
end

------------------------------------------------------------------------------

