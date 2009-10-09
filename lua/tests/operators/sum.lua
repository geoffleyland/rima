-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local sum = require("rima.operators.sum")
local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
require("rima.iteration")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local D = expression.dump
  local E = expression.eval

  T:test(object.isa(sum:new(), sum), "isa(sum, sum:new())")
  T:check_equal(object.type(sum:new()), "sum", "type(sum:new()) == 'sum'")

  local x, y, Q, q, R, r = rima.R"x,y,Q,q,R,r"

  T:check_equal(D(rima.sum({rima.alias(Q, "q")}, x)),
    "sum({alias(q in ref(Q))}, ref(x))")
  T:check_equal(rima.sum({rima.alias(Q, "q")}, x), "sum({q in Q}, x)")
  T:check_equal(D(rima.sum({rima.alias(Q, "q")}, x[q])),
    "sum({alias(q in ref(Q))}, index(ref(x), address(ref(q))))")
  T:check_equal(rima.sum({rima.alias(Q, "q")}, x[q]), "sum({q in Q}, x[q])")
  T:check_equal(D(rima.sum({rima.alias(Q, "q"), R}, x[q][R])),
    "sum({alias(q in ref(Q)), ref(R)}, index(ref(x), address(ref(q), ref(R))))")
  T:check_equal(rima.sum({rima.alias(Q, "q"), "R"}, x[q][R]), "sum({q in Q, R}, x[q, R])")

  local S = rima.scope.new()
  T:check_equal(E(rima.sum({rima.alias(Q, "q")}, x), S), "sum({q in Q}, x)")
  T:check_equal(E(rima.sum({rima.alias(Q, "q")}, x * y), S), "sum({q in Q}, x*y)")
  T:check_equal(E(rima.sum({rima.alias(Q, "q")}, x[q] * y[q]), S), "sum({q in Q}, x[q]*y[q])")
  T:check_equal(E(rima.sum({rima.alias(Q, "q"), rima.alias(R, "r")}, x[q][r]), S), "sum({q in Q, r in R}, x[q, r])")
  T:check_equal(E(rima.sum({rima.alias(Q, "q"), "R"}, x[q][R]), S), "sum({q in Q, R}, x[q, R])")
  T:check_equal(E(rima.sum({rima.alias(Q, "q"), R}, x[q][R] * y[q]), S), "sum({q in Q, R}, x[q, R]*y[q])")
  S.Q = {"a", "b", "c"}
  T:check_equal(E(rima.sum({rima.alias(Q, "q")}, x), S), "3*x")
  T:check_equal(E(rima.sum({rima.alias(Q, "q")}, x[q]), S), "x[a] + x[b] + x[c]")
  S.x = { 1, 2, 3 }
  T:check_equal(E(rima.sum({rima.alias(Q, "q")}, x[q]), S), 6)
  T:check_equal(E(rima.sum({"Q"}, x[Q]), S), 6)

  do 
    local S = rima.scope.new()
    local x, Q, R = rima.R"x, Q, R"
    local xx = {{1,2},{3,4},{5,6}}
    local QQ = {"a", "b", "c"}
    local RR = {"d", "e" }
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), S), "sum({Q, R}, x[Q, R])")
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx})), "sum({Q, R}, x[Q, R])")
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {Q=QQ})), "sum({R}, x[a, R] + x[b, R] + x[c, R])")
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {R=RR})), "sum({Q}, x[Q, d] + x[Q, e])")
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ})), "sum({R}, x[a, R] + x[b, R] + x[c, R])")
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,R=RR})), "sum({Q}, x[Q, d] + x[Q, e])")
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {Q=QQ,R=RR})), "x[a, d] + x[a, e] + x[b, d] + x[b, e] + x[c, d] + x[c, e]")
    T:check_equal(E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ,R=RR})), 21)
  end

  do 
    local S = rima.scope.new()
    local x, Q, R, r = rima.R"x, Q, R, r"
    local xx = { x = 1, y = 2, z = 3}
    local QQ = {"a", "b"}
    local RR = { a = { "x", "y" }, b = { "y", "z" } }
    T:check_equal(E(rima.sum({Q, rima.alias(R[Q], "r")}, x[r]), S), "sum({Q, r in R[Q]}, x[r])")
    T:check_equal(E(rima.sum({Q, rima.alias(R[Q], "r")}, x[r]), scope.spawn(S, {Q=QQ})), "sum({r in R[a]}, x[r]) + sum({r in R[b]}, x[r])")
    T:check_equal(E(rima.sum({Q, rima.alias(R[Q], "r")}, x[r]), scope.spawn(S, {R=RR})), "sum({Q, r in R[Q]}, x[r])")
    T:check_equal(E(rima.sum({Q, rima.alias(R[Q], "r")}, x[r]), scope.spawn(S, {Q=QQ,R=RR})), "x[x] + 2*x[y] + x[z]")
    T:check_equal(E(rima.sum({Q, rima.alias(R[Q], "r")}, x[r]), scope.spawn(S, {Q=QQ,R=RR,x=xx})), 8)
  end

  do 
    local X, x, y, z = rima.R"X, x, y, z"
    local S = rima.scope.create{ X = rima.range(1, y) }
    T:check_equal(D(E(rima.sum({rima.alias(X, "x")}, x.key), S)), "sum({iterator(x in range(number(1), ref(y)))}, index(ref(x), address(string(key))))")
    T:check_equal(E(rima.sum({rima.alias(X, "x")}, x.key), S), "sum({x in range(1, y)}, x.key)")
    S.y = 5
    T:check_equal(E(rima.sum({rima.alias(X, "x")}, x.key), S), 15)
    T:check_equal(E(rima.sum({rima.alias(X, "x")}, z * x.key), S), 15*z)
  end

  do
    local x, X = rima.R"x, X"
    local S = scope.create{ X={{y=rima.free()},{y=rima.free()},{y=rima.free()}} }
    local S2 = scope.spawn(S, { X={{y=1},{y=2},{y=3}} })
    local e1 = rima.sum({rima.ipairs(X, "_", x)}, x.y)

    T:check_equal(expression.type(X[1].y, S), rima.free())
    T:check_equal(E(X[1].y, S), "X[1].y")

    T:check_equal(e1, "sum({_, x in ipairs(X)}, x.y)")
    T:check_equal(D(e1), "sum({string(_), ref(x) in ipairs(ref(X))}, index(ref(x), address(string(y))))")
    T:check_equal(E(e1, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e1, S2), 6)

    local e2 = rima.sum({X}, X.key.y)
    T:check_equal(e2, "sum({X}, X.key.y)")
    T:check_equal(D(e2), "sum({ref(X)}, index(ref(X), address(string(key), string(y))))")
    T:check_equal(E(e2, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e2, S2), 6)

    local e3 = rima.sum({rima.alias(X, "x")}, x.key.y)
    T:check_equal(e3, "sum({x in X}, x.key.y)")
    T:check_equal(D(e3), "sum({alias(x in ref(X))}, index(ref(x), address(string(key), string(y))))")
    T:check_equal(E(e3, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e3, S2), 6)
  end

  do
    local x, X = rima.R"x, X"
    local S = scope.new()
    S.X[rima.default].y = rima.free()
    local S2 = scope.spawn(S, { X={{y=1},{y=2},{y=3}} })
    
    T:check_equal(expression.type(X[1].y, S), rima.free())
    T:check_equal(E(X[1].y, S), "X[1].y")
    
    local e1 = rima.sum({rima.ipairs(X, "_", x)}, x.y)
    T:check_equal(e1, "sum({_, x in ipairs(X)}, x.y)")
    T:check_equal(D(e1), "sum({string(_), ref(x) in ipairs(ref(X))}, index(ref(x), address(string(y))))")
    T:check_equal(E(e1, S), 0)
    T:check_equal(E(e1, S2), 6)

    local e2 = rima.sum({X}, X.key.y)
    T:check_equal(e2, "sum({X}, X.key.y)")
    T:check_equal(D(e2), "sum({ref(X)}, index(ref(X), address(string(key), string(y))))")
    T:check_equal(E(e2, S), 0)
    T:check_equal(E(e2, S2), 6)

    local e3 = rima.sum({rima.alias(X, "x")}, x.key.y)
    T:check_equal(e3, "sum({x in X}, x.key.y)")
    T:check_equal(D(e3), "sum({alias(x in ref(X))}, index(ref(x), address(string(key), string(y))))")
    T:check_equal(E(e3, S), 0)
    T:check_equal(E(e3, S2), 6)
  end

  do
    local x, X = rima.R"x, X"
    local S = scope.new()
    S.X[rima.default].y = rima.free()
    local S2 = scope.spawn(S, { X={{z=11},{z=13},{z=17}} })
    
    T:check_equal(expression.type(X[1].y, S), rima.free())
    T:check_equal(E(X[1].y, S), "X[1].y")
    T:check_equal(expression.type(X[1].y, S2), rima.free())
    T:check_equal(E(X[1].y, S2), "X[1].y")
    
    local e1 = rima.sum({rima.ipairs(X, "_", x)}, x.y * x.z)
    T:check_equal(e1, "sum({_, x in ipairs(X)}, x.y*x.z)")
    T:check_equal(E(e1, S2), "11*X[1].y + 13*X[2].y + 17*X[3].y")

    local e2 = rima.sum({X}, X.key.y * X.key.z)
    T:check_equal(e2, "sum({X}, X.key.y*X.key.z)")
    T:check_equal(E(e2, S2), 11*X[1].y + 13*X[2].y + 17*X[3].y)

    local e3 = rima.sum({rima.alias(X, "x")}, x.key.y * x.key.z)
    T:check_equal(e3, "sum({x in X}, x.key.y*x.key.z)")
    T:check_equal(E(e3, S2), 11*X[1].y + 13*X[2].y + 17*X[3].y)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

