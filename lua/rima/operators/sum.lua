-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local assert, select, tostring, unpack = assert, select, tostring, unpack
local ipairs = ipairs

local rima = require("rima")
local tests = require("rima.tests")
local operators = require("rima.operators")
local ref = rima.ref
local expression = rima.expression
local scope = rima.scope

module(...)

-- Subscripts ------------------------------------------------------------------

local sum = rima.object:new(_M, "sum")
sum.precedence = 1

function rima.sum(...)
  -- Convention means that the indexes over which we sum come before the
  -- expression we're summing, but as they're of variable length, it's far
  -- easier to work with them after the expression, so we turn them around here.
  local args = {...}
  local new_args = { args[#args] }
  for i = 1, #args-1 do
    new_args[i+1] = args[i]
  end
  return expression:new_table(sum, new_args)
end

-- String Representation -------------------------------------------------------

function sum:dump(args)
  return "sum("..table.concat(rima.imap(expression.dump, args), ", ")..")"
end

function sum:_tostring(args)
  return "sum("..
    table.concat(rima.imap(rima.tostring, { select(2, unpack(args)) }), ", ")..
    ", "..rima.tostring(args[1])..")"
end

-- Evaluation ------------------------------------------------------------------

function sum:eval(S, args)
  local e = args[1]

  local caller_base_scope, defined_sets, undefined_sets =
    rima.set.prepare(S, {select(2, unpack(args))})

  -- if nothing's defined, do nothing but evaluate the underlying expression in the current context
  if not defined_sets[1] then
    return expression:new(sum, expression.eval(e, caller_base_scope), unpack(undefined_sets))
  end

  local add_args = {}
  for caller_scope in rima.set.iterate_all(caller_base_scope, defined_sets) do
    add_args[#add_args+1] = { 1, expression.eval(e, caller_scope) }
  end

  -- add up the accumulated terms
  local a = expression.eval(expression:new_table(operators.add, add_args), caller_base_scope)

  if undefined_sets[1] then                     -- if there are undefined sets remaining, return a sum over them
    return expression:new(sum, a, unpack(undefined_sets))
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

  T:equal_strings(expression.dump(rima.sum(rima.alias(Q, "q"), x)),
    "sum(ref(x), alias(q in Q))")
  T:equal_strings(rima.sum(rima.alias(Q, "q"), x), "sum(q in Q, x)")
  T:equal_strings(expression.dump(rima.sum(rima.alias(Q, "q"), x[q])),
    "sum(ref(x[ref(q)]), alias(q in Q))")
  T:equal_strings(rima.sum(rima.alias(Q, "q"), x[q]), "sum(q in Q, x[q])")
  T:equal_strings(expression.dump(rima.sum(rima.alias(Q, "q"), R, x[q][R])),
    "sum(ref(x[ref(q), ref(R)]), alias(q in Q), ref(R))")
  T:equal_strings(rima.sum(rima.alias(Q, "q"), R, x[q][R]), "sum(q in Q, R, x[q, R])")

  local S = rima.scope.new()
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), x), S), "sum(q in Q, x)")
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), x * y), S), "sum(q in Q, x*y)")
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), x[q] * y[q]), S), "sum(q in Q, x[q]*y[q])")
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), rima.alias(R, "r"), x[q][r]), S), "sum(q in Q, r in R, x[q, r])")
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), R, x[q][R]), S), "sum(q in Q, R, x[q, R])")
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), R, x[q][R] * y[q]), S), "sum(q in Q, R, x[q, R]*y[q])")
  S.Q = {"a", "b", "c"}
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), x), S), "3*x")
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), x[q]), S), "x[a] + x[b] + x[c]")
  S.x = { 1, 2, 3 }
  T:equal_strings(expression.eval(rima.sum(rima.alias(Q, "q"), x[q]), S), 6)
  T:equal_strings(expression.eval(rima.sum(Q, x[Q]), S), 6)

  do 
    local S = rima.scope.new()
    local x, Q, R = rima.R"x, Q, R"
    local xx = {{1,2},{3,4},{5,6}}
    local QQ = {"a", "b", "c"}
    local RR = {"d", "e" }
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), S), "sum(Q, R, x[Q, R])")
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), scope.spawn(S, {x=xx})), "sum(Q, R, x[Q, R])")
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), scope.spawn(S, {Q=QQ})), "sum(R, x[a, R] + x[b, R] + x[c, R])")
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), scope.spawn(S, {R=RR})), "sum(Q, x[Q, d] + x[Q, e])")
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ})), "sum(R, x[a, R] + x[b, R] + x[c, R])")
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), scope.spawn(S, {x=xx,R=RR})), "sum(Q, x[Q, d] + x[Q, e])")
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), scope.spawn(S, {Q=QQ,R=RR})), "x[a, d] + x[a, e] + x[b, d] + x[b, e] + x[c, d] + x[c, e]")
    T:equal_strings(expression.eval(rima.sum(Q, R, x[Q][R]), scope.spawn(S, {x=xx,Q=QQ,R=RR})), 21)
  end

  do 
    local X, x, y, z = rima.R"X, x, y, z"
    local S = rima.scope.create{ X = rima.range(1, y) }
    T:equal_strings(expression.dump(expression.eval(rima.sum(rima.alias(X, "x"), rima.value(x)), S)), "sum(value(ref(x)), alias(x in range(1, y)))")
    T:equal_strings(expression.eval(rima.sum(rima.alias(X, "x"), rima.value(x)), S), "sum(x in range(1, y), value(x))")
    S.y = 5
    T:equal_strings(expression.eval(rima.sum(rima.alias(X, "x"), rima.value(x)), S), 15)
    T:equal_strings(expression.eval(rima.sum(rima.alias(X, "x"), z * rima.value(x)), S), 15*z)
  end
  
  do -- this is really a tabulate test!
    local Q, x, y, z = rima.R"Q, x, y"
    local e = rima.sum(Q, x[Q])
    local S = rima.scope.create{ Q={4, 5, 6} }
    S.x = rima.tabulate(rima.value(y)^2, y)
    T:equal_strings(rima.E(e, S), 77)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

