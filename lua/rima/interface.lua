-- Copyright (c) 2009-2013 Incremental IP Limited
-- see LICENSE for license information

local object = require"rima.lib.object"
local index = require"rima.index"
local sum = require"rima.operators.sum"
local product = require"rima.operators.product"
local case = require"rima.operators.case"
local minmax = require"rima.operators.minmax"
local func = require"rima.func"
local sets = require"rima.sets"
local ref = require"rima.sets.ref"
local opmath = require"rima.operators.math"
local expression = require"rima.expression"
local core = require"rima.core"
local scope = require"rima.scope"
local compiler = require"rima.compiler"
local constraint = require"rima.mp.constraint"

local interface = {}

local W, U = expression.wrap, expression.unwrap
local tunwrap = expression.tunwrap
local vtunwrap = expression.vtunwrap
local vunwrap = expression.vunwrap

interface.unwrap = U


------------------------------------------------------------------------------


function interface.new_index(...)
  return W(index:new(...))
end


function interface.set_index(i, t, v)
  index.set(U(i), t, U(v))
end


function interface.R(names)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = W(index:new(nil, n))
  end
  return unpack(results)
end


function interface.define(names, depth)
  local env = getfenv(2 + (depth or 0))
  for n in names:gmatch("[%a_][%w_]*") do
    env[n] = W(index:new(nil, n))
  end
end


------------------------------------------------------------------------------

function interface.sum(x)
  local term_count, terms = 1, { tunwrap(x) }
  local function next_term(y)
    term_count = term_count + 1
    if object.typename(y) == "table" then
      terms[term_count] = tunwrap(y)
      return next_term
    else
      terms[term_count] = U(y)
      return W(sum:new(terms))
    end
  end
  return next_term
end


function interface.product(x)
  local term_count, terms = 1, { tunwrap(x) }
  local function next_term(y)
    term_count = term_count + 1
    terms[term_count] = y
    if object.typename(y) == "table" then
      terms[term_count] = tunwrap(y)
      return next_term
    else
      terms[term_count] = U(y)
      return W(product:new(terms))
    end
  end
  return next_term
end


function interface.case(value, cases, default)
  local c2 = {}
  for i, v in ipairs(cases) do
    c2[i] = { U(v[1]), U(v[2]) }
  end
  return W(case:new{U(value), c2, U(default)})
end


function interface.min(...)
  return W(minmax.min:new(vtunwrap(...)))
end


function interface.max(...)
  return W(minmax.max:new(vtunwrap(...)))
end


function interface.func(inputs)
  return function(e, S) return func:new(tunwrap(inputs), U(e), S) end
end


function interface.ord(e)
  return W(sets.ord:new{U(e)})
end


function interface.range(l, h)
  return W(sets.range:new{U(l), U(h)})
end


function interface.pairs(exp)
  return ref:new(U(exp), "", "pairs")
end


function interface.ipairs(exp)
  return ref:new(U(exp), "i", "pairs")
end


interface.math = {}
for k, v in pairs(opmath) do
  interface.math[k] = function(e) return W(v(U(e))) end
end


------------------------------------------------------------------------------

function interface.eval(e, s, ...)
  if not object.typeinfo(s).scope then
    s = scope.new(s)
  end
  return W(core.eval(U(e), U(s), vunwrap(...)))
end


function interface.diff(e, v)
  return W(core.eval(core.diff(U(e), U(v))))
end


------------------------------------------------------------------------------

function interface.compile(expressions, variables, arg_names)
  local v2 = {}
  for i, v in ipairs(variables) do
    v2[i] = {}
    for k, u in pairs(v) do
      v2[i][k] = U(u)
    end
  end
  
  local e2
  if getmetatable(expressions) then
    e2 = U(expressions)
  else
    e2 = {}
    for i, v in ipairs(expressions) do
      e2[i] = U(v)
    end
  end

  return compiler.compile(e2, v2, arg_names)
end


------------------------------------------------------------------------------

interface.mp = {}

function interface.mp.constraint(lhs, rel, rhs)
  return constraint:new(U(lhs), rel, U(rhs))
end


------------------------------------------------------------------------------


return interface

------------------------------------------------------------------------------

