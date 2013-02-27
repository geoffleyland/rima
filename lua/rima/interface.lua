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
local opmath = require"rima.operators.math"
local expression = require"rima.expression"

local interface = {}


------------------------------------------------------------------------------

function interface.R(names)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = index:new(nil, n)
  end
  return unpack(results)
end


function interface.define(names, depth)
  local env = getfenv(2 + (depth or 0))
  for n in names:gmatch("[%a_][%w_]*") do
    env[n] = index:new(nil, n)
  end
end


------------------------------------------------------------------------------

function interface.sum(x)
  local term_count, terms = 1, { x }
  local function next_term(y)
    term_count = term_count + 1
    terms[term_count] = y
    if object.typename(y) == "table" then
      return next_term
    else
      return expression:new_table(sum, terms)
    end
  end
  return next_term
end


function interface.product(x)
  local term_count, terms = 1, { x }
  local function next_term(y)
    term_count = term_count + 1
    terms[term_count] = y
    if object.typename(y) == "table" then
      return next_term
    else
      return expression:new_table(product, terms)
    end
  end
  return next_term
end


function interface.case(value, cases, default)
  return expression:new(case, value, cases, default)
end


function interface.min(...)
  return expression:new(minmax.min, ...)
end


function interface.max(...)
  return expression:new(minmax.max, ...)
end


function interface.func(inputs)
  return function(e, S) return func:new(inputs, e, S) end
end


function interface.ord(e)
  return expression:new(sets.ord, e)
end


function interface.range(l, h)
  return expression:new(sets.range, l, h)
end


interface.math = {}
for k, v in pairs(opmath) do
  interface.math[k] = function(e) return v(e) end
end


------------------------------------------------------------------------------

return interface

------------------------------------------------------------------------------

