-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local assert, ipairs, pcall = assert, ipairs, pcall

local linear = require("rima.solvers.linear")

local status, core = pcall(require, "rima_cbc_core")

module(...)


--------------------------------------------------------------------------------

available = status
objective = { linear = true }
constraints = { linear = true }
variables = { continuous = true, integer = true }

preference = 1


--------------------------------------------------------------------------------

local function solve_(options)
  linear.build_linear_problem(options)
  local m = core.new()
  assert(m:set_objective(options.ordered_variables, options.sense))
  assert(m:build_rows(options.constraint_info))
  assert(m:solve())
  return assert(m:get_solution())
end

solve = (status and solve_) or nil


-- EOF -------------------------------------------------------------------------

