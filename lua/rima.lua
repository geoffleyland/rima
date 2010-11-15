-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local error, getfenv, require, unpack, xpcall =
      error, getfenv, require, unpack, xpcall

local lib = require("rima.lib")
local args = require("rima.lib.args")
local trace = require("rima.lib.trace")
local index = require("rima.index")
local core = require("rima.core")
local func = require("rima.func")
local sum_op = require("rima.operators.sum")
local case_op = require("rima.operators.case")
local minmax = require("rima.operators.minmax")
local sets = require("rima.sets")
local set_ref = require("rima.sets.ref")
local number_t = require("rima.types.number_t")

module(...)

require("rima.mp")


-- String representation -------------------------------------------------------

repr = lib.repr

-- Creating references ---------------------------------------------------------

function R(names)
  local fname, usage = "rima.R", "Create references.\n  ref1, ..., refN = R(name: list of comma-separated reference names [string])"
  args.check_type(names, "names", "string", usage, fname)

  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = index:new(nil, n)
  end
  return unpack(results)
end


function define(names)
  local fname, usage = "rima.define", "Create references in the caller's environment.\n  define(name: list of comma-separated reference names [string])"
  args.check_type(names, "names", "string", usage, fname)

  local results = {}
  local env = getfenv(2)
  for n in names:gmatch("[%a_][%w_]*") do
    env[n] = index:new(nil, n)
  end
end


-- Evaluation ------------------------------------------------------------------

function E(e, S) -- evaluate an expression
  local fname, usage = "rima.E", "Evaluate an expression.\n  result = E(e:any expression, s: scope to evaluate e in [nil|table|scope])"
  args.check_types(S, "S", {"nil", "table", "scope"}, usage, fname)

  local status, r = xpcall(function() return core.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    trace.reset_depth()
    error(("error evaluating '%s':\n  %s"):format(lib.repr(e), r:gsub("\n", "\n  ")), 2)
  end
end


-- Creating functions ----------------------------------------------------------

function F(inputs, e, S) -- create a function
  if e then
    return func:new(inputs, e, S)
  else
    return function(e, S) return func:new(inputs, e, S) end
  end
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

