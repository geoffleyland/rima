-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local sum = require("rima.operators.sum")
local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
require("rima.iteration")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(object.isa(sum:new(), sum), "isa(sum, sum:new())")
  T:check_equal(object.type(sum:new()), "sum", "type(sum:new()) == 'sum'")

  local x, y, Q, q, R, r = rima.R"x,y,Q,q,R,r"

  T:check_equal(expression.dump(rima.sum({rima.alias(Q, "q")}, x)),
    "sum({alias(q in Q)}, ref(x))")
  T:check_equal(rima.sum({rima.alias(Q, "q")}, x), "sum({q in Q}, x)")
  T:check_equal(expression.dump(rima.sum({rima.alias(Q, "q")}, x[q])),
    "sum({alias(q in Q)}, ref(x[ref(q)]))")
  T:check_equal(rima.sum({rima.alias(Q, "q")}, x[q]), "sum({q in Q}, x[q])")
  T:check_equal(expression.dump(rima.sum({rima.alias(Q, "q"), R}, x[q][R])),
    "sum({alias(q in Q), ref(R)}, ref(x[ref(q), ref(R)]))")
  T:check_equal(rima.sum({rima.alias(Q, "q"), "R"}, x[q][R]), "sum({q in Q, R}, x[q, R])")

  local S = rima.scope.new()
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q")}, x), S), "sum({q in Q}, x)")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q")}, x * y), S), "sum({q in Q}, x*y)")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q")}, x[q] * y[q]), S), "sum({q in Q}, x[q]*y[q])")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q"), rima.alias(R, "r")}, x[q][r]), S), "sum({q in Q, r in R}, x[q, r])")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q"), "R"}, x[q][R]), S), "sum({q in Q, R}, x[q, R])")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q"), R}, x[q][R] * y[q]), S), "sum({q in Q, R}, x[q, R]*y[q])")
  S.Q = {"a", "b", "c"}
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q")}, x), S), "3*x")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q")}, x[q]), S), "x[a] + x[b] + x[c]")
  S.x = { 1, 2, 3 }
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "q")}, x[q]), S), 6)
  T:check_equal(rima.E(rima.sum({"Q"}, x[Q]), S), 6)

  do 
    local S = rima.scope.new()
    local x, Q, R = rima.R"x, Q, R"
    local xx = {{1,2},{3,4},{5,6}}
    local QQ = {"a", "b", "c"}
    local RR = {"d", "e" }
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), S), "sum({Q, R}, x[Q, R])")
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx})), "sum({Q, R}, x[Q, R])")
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {Q=QQ})), "sum({R}, x[a, R] + x[b, R] + x[c, R])")
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {R=RR})), "sum({Q}, x[Q, d] + x[Q, e])")
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ})), "sum({R}, x[a, R] + x[b, R] + x[c, R])")
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,R=RR})), "sum({Q}, x[Q, d] + x[Q, e])")
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {Q=QQ,R=RR})), "x[a, d] + x[a, e] + x[b, d] + x[b, e] + x[c, d] + x[c, e]")
    T:check_equal(rima.E(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ,R=RR})), 21)
  end

  do 
    local X, x, y, z = rima.R"X, x, y, z"
    local S = rima.scope.create{ X = rima.range(1, y) }
    T:check_equal(expression.dump(rima.E(rima.sum({rima.alias(X, "x")}, rima.value(x)), S)), "sum({iterator(x in range(1, y))}, value(ref(x)))")
    T:check_equal(rima.E(rima.sum({rima.alias(X, "x")}, rima.value(x)), S), "sum({x in range(1, y)}, value(x))")
    S.y = 5
    T:check_equal(rima.E(rima.sum({rima.alias(X, "x")}, rima.value(x)), S), 15)
    T:check_equal(rima.E(rima.sum({rima.alias(X, "x")}, z * rima.value(x)), S), 15*z)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

