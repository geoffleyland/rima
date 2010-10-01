-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local error, rawipairs, require, unpack, xpcall =
      error, ipairs,    require, unpack, xpcall

local args = require("rima.lib.args")
local trace = require("rima.lib.trace")
local ref = require("rima.ref")
local expression = require("rima.expression")
local function_v = require("rima.values.function_v")
local sum_op = require("rima.operators.sum")
local case_op = require("rima.operators.case")
local minmax = require("rima.operators.minmax")
local sets = require("rima.sets")
local set_ref = require("rima.sets.ref")
local number_t = require("rima.types.number_t")
local constraint = require("rima.mp.constraint")

module(...)

require("rima.mp")


-- String representation -------------------------------------------------------

set_number_format = lib.set_number_format
repr = lib.repr


-- Creating references ---------------------------------------------------------

function R(names, type)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = ref:new{name=n, type=type}
  end
  return unpack(results)
end


-- Evaluation ------------------------------------------------------------------

function D(e) -- check if an expression is defined
  return core.defined(e)
end


local dgs
local function default_global_scope()
  if not dgs then
    dgs = scope.new(nil, { name="_GLOBAL" })
  end
  return dgs
end


function E(e, S) -- evaluate an expression
  local fname, usage =
    "rima.E",
    "E(e:expression, S:nil, table or scope)"

  args.check_types(S, "S", {"nil", "table", {scope, "scope"}}, usage, fname)

  if not S then
    S = scope.spawn(default_global_scope(), nil, {no_undefined=true})
  elseif not scope:isa(S) then
    S = scope.spawn(default_global_scope(), S, {no_undefined=true})
  end

  local status, r = xpcall(function() return core.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    trace.reset_depth()
    error(("evaluate: error evaluating '%s':\n  %s"):format(lib.repr(e), r:gsub("\n", "\n  ")), 0)
  end
end


-- Creating functions and constraints ------------------------------------------

function F(inputs, e, S) -- create a function
  if e then
    return function_v:new(inputs, e, S)
  else
    return function(e, S) return function_v:new(inputs, e, S) end
  end
end


-- Scopes ----------------------------------------------------------------------

new = scope.new
set = scope.set


function instance(S, ...) -- create a new instance of a scope
  local S2 = scope.spawn(S)
  for _, v in rawipairs{...} do
    scope.set(S2, v)
  end
  return S2
end


-- Operators -------------------------------------------------------------------

function sum(sets, e)
  if e then
    return expression:new(sum_op, sets, e)
  else
    return function(e2) return expression:new(sum_op, sets, e2) end
  end
end


function case(value, cases, default)
  return expression:new(case_op, value, cases, default)
end


function min(...)
  return expression:new(minmax.min, ...)
end


function max(...)
  return expression:new(minmax.max, ...)
end


-- Set tools -------------------------------------------------------------------

function ord(e)
  return expression:new(sets.ord_op, e)
end


function range(l, h)
  return expression:new(sets.range_op, l, h)
end


function pairs(exp)
  return set_ref:new(exp, "", "pairs")
end


function ipairs(exp)
  return set_ref:new(exp, "i", "pairs")
end


-- Types -----------------------------------------------------------------------

free = number_t.free
positive = number_t.positive
negative = number_t.negative
integer = number_t.integer
binary = number_t.binary


-- EOF -------------------------------------------------------------------------

