-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local object = require("rima.object")
local expression = require("rima.expression")
local scope = require("rima.scope")
require("rima.iteration")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)
  
  local E = expression.eval
  
  local x, y, Q, R, r = rima.R"x, y, Q, R, r"
  local S = scope.create{ x = { 10, 20, 30 }, Q = {"a", "b", "c"}, R = rima.range(2, r) }
  
  T:check_equal(rima.sum{Q}(x[Q]), "sum{Q}(x[Q])")
  T:check_equal(E(rima.sum{Q}(x[Q])), "sum{Q}(x[Q])")
  T:check_equal(E(rima.sum({Q}, x[Q]), S), 60)
  T:check_equal(rima.sum{y=Q}(x[y]), "sum{y in Q}(x[y])")
  T:check_equal(rima.sum{Q=Q}(x[Q]), "sum{Q}(x[Q])")
  T:check_equal(E(rima.sum({y=Q}, x[y]), S), 60)
  T:check_equal(rima.sum({y=Q}, rima.ord(y)), "sum{y in Q}(ord(y))")
  T:check_equal(E(rima.sum{y=Q}(rima.ord(y)), S), 6)

  T:check_equal(E(rima.sum{y=x}(y), S), 60)

  T:check_equal(rima.sum({R}, R), "sum{R}(R)")
  T:check_equal(rima.sum({R=rima.range(2, r)}, R), "sum{R in range(2, r)}(R)")
  T:check_equal(rima.sum({R=rima.range(2, 10)}, R), "sum{R in range(2, 10)}(R)")
  T:check_equal(E(rima.sum({R}, R), S), "sum{R in range(2, r)}(R)")
  T:check_equal(E(rima.sum({y=R}, y), S), "sum{y in range(2, r)}(y)")
  T:check_equal(E(rima.sum({y=rima.range(2, r)}, y), S), "sum{y in range(2, r)}(y)")
  T:check_equal(E(rima.sum({y=rima.range(2, 10)}, y), S), 54)
  S.r = 10
  T:check_equal(E(rima.sum({R}, R), S), 54)
  T:check_equal(E(rima.sum({y=R}, y), S), 54)
  T:check_equal(E(rima.sum({y=rima.range(2, r)}, y), S), 54)

  do
    local x, k, v = rima.R"x, k, v"
    local S = rima.scope.create{ x = { 10, 20, 30 }, y = { 10, 20, 30, a = 10 } }
    T:check_equal(rima.sum{["k, v"]=rima.pairs(x)}(k + v), "sum{k, v in pairs(x)}(k + v)")
    T:check_equal(rima.sum{["k, v"]=rima.ipairs(x)}(k + v), "sum{k, v in ipairs(x)}(k + v)")
    T:check_equal(E(rima.sum({["k, v"]=rima.pairs(x)}, k + v), S), 66)
    T:check_equal(E(rima.sum({["k, v"]=rima.pairs(y)}, v), S), 70)
    T:check_equal(E(rima.sum({["k, v"]=rima.ipairs(y)}, v), S), 60)
  end
  
  do
    local t, v = rima.R"t, v"
    local S = rima.scope.create{ t={ {b=5}, {b=6}, {b=7} }}
    T:check_equal(rima.sum({["_, v"]=rima.ipairs(t)}, v.a * v.b), "sum{_, v in ipairs(t)}(v.a*v.b)")
    T:check_equal(E(rima.sum({["_, v"]=rima.ipairs(t)}, v.a * v.b), S), "5*t[1].a + 6*t[2].a + 7*t[3].a")
  end

  do
    local x, X = rima.R"x, X"
    local S = rima.scope.create{ X = {a=1, b=2} }
    T:check_equal(E(rima.sum({["_, x"]=rima.pairs(X)}, x), S), 3)
    local S1 = rima.scope.spawn(S, { X = {c=3, d=4} })
    T:check_equal(E(rima.sum({["_, x"]=rima.pairs(X)}, x), S1), 10)
  end
    
  return T:close()
end

-- EOF -------------------------------------------------------------------------

