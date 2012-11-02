-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local assert, getmetatable, ipairs, pcall = assert, getmetatable, ipairs, pcall

local core = require("rima.core")
local index = require("rima.index")
local compiler = require("rima.compiler")

local status, ipopt_core = pcall(require, "rima_ipopt_core")

module(...)


--------------------------------------------------------------------------------

available = status
problem = not available and ipopt_core
objective = { linear = true, nonlinear = true }
constraints = { linear = true, nonlinear = true }
variables = { continuous = true }

preference = 3


--------------------------------------------------------------------------------

local function compile_jacobian(expressions, variables)
  local sparsity = {}
  local e2 = {}

  local function add_expression(e, i)
    for j, v in ipairs(variables) do
      local dedv = core.eval(core.diff(e, v.ref))
      if dedv ~= 0 then
        sparsity[#sparsity+1] = {i, j}
        e2[#e2+1] = dedv
      end
    end
  end

  if getmetatable(expressions) then
    add_expression(expressions, 1)
  else
    for i, e in ipairs(expressions) do
      add_expression(e, i)
    end
  end

  local f, function_string = compiler.compile(e2, variables)
  return f, function_string, sparsity
end


local function compile_hessian(objective, constraints, variables)
  local sigma = index:new(nil, "sigma")
  local lambda = index:new(nil, "lambda")

  local sparsity = {}
  local e2 = {}

  for i, v1 in ipairs(variables) do
    for j, v2 in ipairs(variables) do
      local exp, nonzero = 0, false
      local do2dv1dv2 = core.eval(core.diff(core.diff(objective, v1.ref), v2.ref))
      if do2dv1dv2 ~= 0 then
        exp = sigma * do2dv1dv2
        nonzero = true
      end

      for k, c in ipairs(constraints) do
        local dc2dv1dv2 = core.eval(core.diff(core.diff(c, v1.ref), v2.ref))
        if dc2dv1dv2 ~= 0 then
          exp = exp + lambda[k] * dc2dv1dv2
          nonzero = true
        end
      end
      if nonzero then
        sparsity[#sparsity+1] = {i, j}
        e2[#e2+1] = exp
      end
    end
  end

  local f, function_string = compiler.compile(e2, variables, "args, sigma, lambda")
  return f, function_string, sparsity
end


--------------------------------------------------------------------------------

local function solve_(options)
  for _, v in ipairs(options.ordered_variables) do
    if v.type.lower == -math.huge then
      if v.type.upper == math.huge then
        v.initial = 0
      else
        v.initial = v.type.upper
      end
    elseif v.type.upper == math.huge then
      v.initial = v.type.lower
    else
      v.initial = (v.type.lower+v.type.upper)/2
    end
  end

  if options.sense == "maximise" then options.objective = -options.objective end

  local F =
  {
    variables = options.ordered_variables,
    constraint_bounds = options.constraint_info,
    objective_function = compiler.compile(options.objective, options.ordered_variables),
    constraint_function = compiler.compile(options.constraint_expressions, options.ordered_variables)
  }
  F.objective_jacobian, _, F.oj_sparsity = compile_jacobian(options.objective, options.ordered_variables)
  F.constraint_jacobian, _, F.cj_sparsity = compile_jacobian(options.constraint_expressions, options.ordered_variables)
  F.hessian, _, F.hessian_sparsity = compile_hessian(options.objective, options.constraint_expressions, options.ordered_variables)

  local M = assert(ipopt_core.new(F))
  return M:solve()
end

solve = available and solve_ or nil


-- EOF -------------------------------------------------------------------------
