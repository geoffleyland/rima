-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local error, getfenv, require, unpack, xpcall =
      error, getfenv, require, unpack, xpcall
local rawpairs = pairs

local lib = require("rima.lib")
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
  return index.R(names)
end


function define(names)
  index.define(names, 1)
end


-- Evaluation ------------------------------------------------------------------

function E(e, S) -- evaluate an expression
  local status, r = xpcall(function() return core.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    trace.reset_depth()
    error(("error evaluating '%s':\n  %s"):format(lib.repr(e), r:gsub("\n", "\n  ")), 2)
  end
end


-- Creating functions ----------------------------------------------------------

F = func.build


-- Automatic differentiation ---------------------------------------------------

function diff(exp, var)
  return (core.eval(core.diff(exp, var)))
end


-- Compiling expressions -------------------------------------------------------

compile = compiler.compile


-- Operators -------------------------------------------------------------------

sum = sum_op.build
product = prod_op.build
case = case_op.build
min = minmax.build_min
max = minmax.build_max

for k, v in rawpairs(math_op) do
  if k:sub(1, 1) ~= "_" then
    _M[k] = v
  end
end


-- Set tools -------------------------------------------------------------------

ord = sets.ord
range = sets.range
pairs = set_ref.pairs
ipairs = set_ref.ipairs


-- Types -----------------------------------------------------------------------

free = number_t.free
positive = number_t.positive
negative = number_t.negative
integer = number_t.integer
binary = number_t.binary


-- EOF -------------------------------------------------------------------------

