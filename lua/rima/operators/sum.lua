-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local ipairs, require, tostring = ipairs, require, tostring

local object = require("rima.object")
local rima = rima

module(...)

local add = require("rima.operators.add")
local expression = require("rima.expression")

-- Subscripts ------------------------------------------------------------------

local sum = object:new(_M, "sum")
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
  local a = expression.eval(expression:new_table(add, add_args), caller_base_scope)

  if undefined_sets[1] then                     -- if there are undefined sets remaining, return a sum over them
    return expression:new(sum, undefined_sets, a)
  else                                          -- otherwise, just return the sum of the terms
    return a
  end
end


-- EOF -------------------------------------------------------------------------

