-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local io, math, table = require("io"), require("math"), require("table")
local assert, error, tostring = assert, error, tostring
local ipairs, pairs = ipairs, pairs
local require = require

local rima = require("rima")
local object = require("rima.object")
local scope = require("rima.scope")
local variable = rima.variable
local expression = rima.expression
local constraint = rima.constraint

module(...)

--------------------------------------------------------------------------------

local formulation = object:new(_M, "formulation")

function formulation:new(o)
  o = o or {}
  o.constraints = {}
  o.S = scope.new()
  return object.new(self, o)
end

function formulation:instance(...)
  local o = { objective = self.objective, sense = self.sense, constraints = {}, S = scope.spawn(self.S)}
  for i, v in ipairs(self.constraints) do
    o.constraints[i] = v
  end
  for _, v in ipairs{...} do
    scope.set(o.S, v)
  end
  return object.new(formulation, o)
end

function formulation:__tostring()
  return "MP formulation"
end

function formulation:set_objective(o, sense)
  -- Try to be neutral about case and "z" and "s"
  sense = sense:lower()
  sense = sense:gsub("z", "s")

  assert(sense == "minimise" or sense == "maximise", "Optimisation sense must be 'minimise' or 'maximise'")
  self.sense = sense
  self.objective = o
end

function formulation:add(sets, lhs, type, rhs)
  self.constraints[#self.constraints+1] = constraint:new(sets, lhs, type, rhs)
end

function formulation:set(values)
  scope.set(self.S, values)
end

function formulation:scope()
  return self.S
end

function formulation:solve(solver, values)
  local S = scope.spawn(self.S)
  if values then scope.set(S, values) end
  local solve_mod = require("rima.solvers."..solver)
  local variables, constraints = self:sparse_form(S)

  local r = solve_mod.solve(self.sense, variables, constraints)

  local r2 = { objective=r.objective, constraints=r.constraints, variables={} }
  for i, v in ipairs(r.variables) do
    expression.set(variables[i].ref, r2.variables, v)
  end
  return r2
end

--[[
function formulation:list_variables2()
  local variables = {}
  if self.objective then
    self.objective:list_variables(variables)
  end
  for _, c in ipairs(self.constraints) do
    c:list_variables(variables)
  end
  local ordered_variables = {}
  for v in pairs(variables) do
    ordered_variables[#ordered_variables+1] = v
  end
  table.sort(ordered_variables, function(a, b) return a.name < b.name end)
  io.write("Given:\n")
  for _, v in ipairs(ordered_variables) do
    io.write(("  %s\n"):format(v:describe()))
  end

  return variables
end


function formulation:list_variables()
  local variables = {}
  self.objective:list_variables(variables)
  for _, c in ipairs(self.constraints) do
    c:list_variables(variables)
  end

  return variables
end
--]]

function formulation:write(values, f)
  local S = scope.spawn(self.S)
  if values then scope.set(S, values) end
  f = f or io.stdout
--[[
  -- List variables
  local variables = self:list_variables()
  local ordered_variables = {}
  for v in pairs(variables) do
    ordered_variables[#ordered_variables+1] = v
  end
  table.sort(ordered_variables, function(a, b) return a.name < b.name end)
  f:write("Given:\n")
  for _, v in ipairs(ordered_variables) do
    f:write(("  %s\n"):format(v:describe()))
  end
--]]

  -- Write the objective
  if self.objective then
    local o = rima.E(self.objective, S)
    f:write(("%s:\n  %s\n"):format((self.sense == "minimise" and "Minimise") or "Maximise", rima.repr(o)))
  else
    f:write("No objective defined\n")
  end

  -- Write constraints
  f:write("Subject to:\n")  
  for i, c in pairs(self.constraints) do
    for s in c:tostring(S) do
      f:write(("  %s\n"):format(s))
    end
  end
--[[
  if not env then
    local ordered_env = {}
    for name, value in pairs(self.S) do
      ordered_env[#ordered_env+1] = {name=name, value=value}
    end
    table.sort(ordered_env, function(a, b) return a.name < b.name end)
    for _, v in ipairs(ordered_env) do
      local vs
      if type(v.value) == "table" and not variable.isa(v.value) and not expression.isa(v.value) then
        vs = "{"
        for i, e in ipairs(v.value) do
          if i > 1 then vs = vs..", " end
          if type(e) == "string" then
            vs = vs..e
          else
            vs = vs..tostring(rima.E(e))
          end
        end
        vs = vs.."}"
      else
        vs = tostring(v.value)
      end
      f:write(("  %s = %s\n"):format(v.name, vs))
    end
  end
--]]
end

function formulation:write_sparse(values, f)
  local S = scope.spawn(self.S)
  if values then scope.set(S, values) end
  f = f or io.stdout

  local variables, constraints = self:sparse_form(S)
  
  f:write("Minimise:\n")
  for i, v in ipairs(variables) do
    f:write(("  %0.4g*%s (index=%d, lower=%0.4g, upper=%0.4g)\n"):format(v.cost, v.name, i, v.l, v.h))
  end

  f:write("Subject to:\n")
  
  for _, c in ipairs(constraints) do
    f:write(("  %0.4g <= "):format(c.l))
    for _, cc in ipairs(c.m) do
      f:write(("%+0.4g*%s "):format(cc[2], variables[cc[1]].name))
    end
    f:write(("<= %0.4g\n"):format(c.h))
  end
end

function formulation:sparse_form(S)

  -- Get the objective and constraints in {a=1, b=2}... form
  local constant, objective = rima.linearise(self.objective, S)
  local constraints = {}
  for _, c in ipairs(self.constraints) do
    for terms, type, rhs in c:linearise(S) do
      constraints[#constraints+1] = { terms, type, rhs }
    end
  end
  
  -- Find all the variables in the constraints
  local variables = {}
  for _, c in pairs(constraints) do
    for name, info in pairs(c[1]) do
      variables[name] = info
    end
  end

  -- Check all the variables in the objective appear in the constraints
  for name in pairs(objective) do
    if not variables[name] then
      error(("The variable '%s' is not involved in any constraint, but is in the objective\n"):format(rima.repr(name)))
    end
  end

  -- Order the variables (for now, alphabetically)
  local ordered_variables = {}
  for name, c in pairs(variables) do
    local cost = 0
    local o = objective[name]
    if o then cost = o.coeff end
    ordered_variables[#ordered_variables+1] = { name=name, cost=cost, ref=c.variable, l=c.lower, h=c.upper, i=c.integer }
  end
  table.sort(ordered_variables, function(a, b) return a.name < b.name end)
  
  for i, v in ipairs(ordered_variables) do
    variables[v.name].index = i
  end

  -- Build a set of sparse constraints
  local sparse_constraints = {}
  for _, c in pairs(constraints) do
    local cc = {}
    for v, k in pairs(c[1]) do
      cc[#cc+1] = { variables[v].index, k.coeff }
    end
    table.sort(cc, function(a, b) return a[1] < b[1] end)
    local low = ((c[2] == "==" or c[2] == ">=") and c[3]) or -math.huge
    local high = ((c[2] == "==" or c[2] == "<=") and c[3]) or math.huge
    sparse_constraints[#sparse_constraints+1] = { l=low, h=high, m=cc }
  end

  return ordered_variables, sparse_constraints
end

-- EOF -------------------------------------------------------------------------
