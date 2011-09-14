-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local error, getfenv, require, unpack, xpcall =
      error, getfenv, require, unpack, xpcall
local rawpairs = pairs

local lib = require("rima.lib")
local args = require("rima.lib.args")
local trace = require("rima.lib.trace")
local index = require("rima.index")
local core = require("rima.core")
local func = require("rima.func")
local sum_op = require("rima.operators.sum")
local prod_op = require("rima.operators.product")
local case_op = require("rima.operators.case")
local math_op = require("rima.operators.math")
local minmax = require("rima.operators.minmax")
local sets = require("rima.sets")
local set_ref = require("rima.sets.ref")
local number_t = require("rima.types.number_t")
local compiler = require("rima.compiler")
local mp = require("rima.mp")

module(...)



-- String representation -------------------------------------------------------

repr = lib.repr

-- Creating references ---------------------------------------------------------

function R(names)
  local fname, usage = "rima.R", "Create references.\n  ref1, ..., refN = R(name: list of comma-separated reference names [string])"
  args.check_type(names, "names", "string", usage, fname)

  return index.R(names)
end


function define(names)
  local fname, usage = "rima.define", "Create references in the caller's environment.\n  define(name: list of comma-separated reference names [string])"
  args.check_type(names, "names", "string", usage, fname)

  index.define(names, 1)
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


-- Automatic differentiation ---------------------------------------------------

function diff(exp, var)
  return (core.eval(core.diff(exp, var)))
end


-- Compiling expressions -------------------------------------------------------

compile = compiler.compile


-- Operators -------------------------------------------------------------------

sum = sum_op.build
product = prod_op.build


function case(value, cases, default)
  return expression:new(case_op, value, cases, default)
end


function min(...)
  return expression:new(minmax.min, ...)
end


function max(...)
  return expression:new(minmax.max, ...)
end


for k, v in rawpairs(math_op) do
  if k:sub(1, 1) ~= "_" then
    _M[k] = v
  end
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

