-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local assert, tostring = assert, tostring
local ipairs = ipairs

local rima = require("rima")
local tests = require("rima.tests")
local operators = require("rima.operators")
require("rima.private")
local ref = rima.ref
local expression = rima.expression
local scope = rima.scope

module(...)

-- Subscripts ------------------------------------------------------------------

local sum = rima.object:new(_M, "sum")
sum.precedence = 1

function rima.sum(sets, e)
  return expression:new(sum, sets, e)
end

-- String Representation -------------------------------------------------------

function sum:dump(args)
  local sets, e = args[1], args[2]
  return "sum({"..table.concat(rima.imap(expression.dump, sets), ", ").."}, "..expression.dump(e)..")"
end

function sum:_tostring(args)
  local sets, e = args[1], args[2]
  return "sum({"..table.concat(rima.imap(rima.tostring, sets), ", ").."}, "..rima.tostring(e)..")"
end

-- Evaluation ------------------------------------------------------------------

function sum:eval(S, args)
  local sets, e = args[1], args[2]

  local caller_base_scope, defined_sets, undefined_sets =
    rima.iteration.prepare(S, sets)

  -- if nothing's defined, do nothing but evaluate the underlying expression in the current context
  if not defined_sets[1] then
    return expression:new(sum, undefined_sets, expression.eval(e, caller_base_scope))
  end

  local add_args = {}
  for caller_scope in rima.iteration.iterate_all(caller_base_scope, defined_sets) do
    add_args[#add_args+1] = { 1, expression.eval(e, caller_scope) }
  end

  -- add up the accumulated terms
  local a = expression.eval(expression:new_table(operators.add, add_args), caller_base_scope)

  if undefined_sets[1] then                     -- if there are undefined sets remaining, return a sum over them
    return expression:new(sum, undefined_sets, a)
  else                                          -- otherwise, just return the sum of the terms
    return a
  end
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(isa(sum:new(), sum), "isa(sum, sum:new())")
  T:equal_strings(type(sum:new()), "sum", "type(sum:new()) == 'sum'")

  local x, y, Q, q, R, r = rima.R"x,y,Q,q,R,r"

  T:equal_strings(expression.dump(rima.sum({rima.alias(Q, "q")}, x)),
    "sum({alias(q in Q)}, ref(x))")
  T:equal_strings(rima.sum({rima.alias(Q, "q")}, x), "sum({q in Q}, x)")
  T:equal_strings(expression.dump(rima.sum({rima.alias(Q, "q")}, x[q])),
    "sum({alias(q in Q)}, ref(x[ref(q)]))")
  T:equal_strings(rima.sum({rima.alias(Q, "q")}, x[q]), "sum({q in Q}, x[q])")
  T:equal_strings(expression.dump(rima.sum({rima.alias(Q, "q"), R}, x[q][R])),
    "sum({alias(q in Q), ref(R)}, ref(x[ref(q), ref(R)]))")
  T:equal_strings(rima.sum({rima.alias(Q, "q"), "R"}, x[q][R]), "sum({q in Q, R}, x[q, R])")

  local S = rima.scope.new()
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q")}, x), S), "sum({q in Q}, x)")
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q")}, x * y), S), "sum({q in Q}, x*y)")
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q")}, x[q] * y[q]), S), "sum({q in Q}, x[q]*y[q])")
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q"), rima.alias(R, "r")}, x[q][r]), S), "sum({q in Q, r in R}, x[q, r])")
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q"), "R"}, x[q][R]), S), "sum({q in Q, R}, x[q, R])")
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q"), R}, x[q][R] * y[q]), S), "sum({q in Q, R}, x[q, R]*y[q])")
  S.Q = {"a", "b", "c"}
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q")}, x), S), "3*x")
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q")}, x[q]), S), "x[a] + x[b] + x[c]")
  S.x = { 1, 2, 3 }
  T:equal_strings(expression.eval(rima.sum({rima.alias(Q, "q")}, x[q]), S), 6)
  T:equal_strings(expression.eval(rima.sum({"Q"}, x[Q]), S), 6)

  do 
    local S = rima.scope.new()
    local x, Q, R = rima.R"x, Q, R"
    local xx = {{1,2},{3,4},{5,6}}
    local QQ = {"a", "b", "c"}
    local RR = {"d", "e" }
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), S), "sum({Q, R}, x[Q, R])")
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx})), "sum({Q, R}, x[Q, R])")
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {Q=QQ})), "sum({R}, x[a, R] + x[b, R] + x[c, R])")
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {R=RR})), "sum({Q}, x[Q, d] + x[Q, e])")
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ})), "sum({R}, x[a, R] + x[b, R] + x[c, R])")
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,R=RR})), "sum({Q}, x[Q, d] + x[Q, e])")
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {Q=QQ,R=RR})), "x[a, d] + x[a, e] + x[b, d] + x[b, e] + x[c, d] + x[c, e]")
    T:equal_strings(expression.eval(rima.sum({Q, R}, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ,R=RR})), 21)
  end

  do 
    local X, x, y, z = rima.R"X, x, y, z"
    local S = rima.scope.create{ X = rima.range(1, y) }
    T:equal_strings(expression.dump(expression.eval(rima.sum({rima.alias(X, "x")}, rima.value(x)), S)), "sum({iterator(x in range(1, y))}, value(ref(x)))")
    T:equal_strings(expression.eval(rima.sum({rima.alias(X, "x")}, rima.value(x)), S), "sum({x in range(1, y)}, value(x))")
    S.y = 5
    T:equal_strings(expression.eval(rima.sum({rima.alias(X, "x")}, rima.value(x)), S), 15)
    T:equal_strings(expression.eval(rima.sum({rima.alias(X, "x")}, z * rima.value(x)), S), 15*z)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

