-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local io, math = require("io"), require("math")
local assert, error, ipairs, getmetatable, pairs, pcall, require, table, type =
      assert, error, ipairs, getmetatable, pairs, pcall, require, table, type

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local constraint = require("rima.mp.constraint")
local tabulate = require("rima.values.tabulate")
local linearise = require("rima.mp.linearise")
local rima = require("rima")

local print = print
local os = os

module(...)

-- Constraint Handling ---------------------------------------------------------

local build_ref_time, tabulate_time, inner_time = 0, 0, 0

local function find_constraints(S, f)
  local constraints = {}
  local current_address = {}

  local function build_ref(S, sets, undefined)
    local brt = os.clock()
    local r = rima.R(current_address[1])
    local set_index, undefined_index = 1, 1
    for i = 2, #current_address do
      local index = current_address[i]
      if index == scope.free_index_marker then
        index = scope.lookup(S, sets[set_index].names[1])
        if not index or not index.value then
          index = undefined[undefined_index]
          undefined_index = undefined_index + 1
        else
          index = index.value
          set_index = set_index + 1
        end
      end
      r = r[index]
    end
    build_ref_time = build_ref_time + os.clock() - brt
    return r
  end

  local function add_constraint(e, S, sets, undefined)
    local r1, r2, r3, r4, r5 = f(e, S, undefined)
    if r1 then
      constraints[#constraints+1] = { ref=build_ref(S, sets, undefined), r1, r2, r3, r4, r5 }
    end
  end


  local function search(t)
    for k, v in pairs(t) do
      current_address[#current_address+1] = k
      if type(v) == "table" and not getmetatable(v) then
        search(v)
      elseif constraint:isa(v) then
        add_constraint(v, S)
      elseif tabulate:isa(v) and constraint:isa(v.expression) then
        local tt = os.clock()
        for S2, undefined in v.indexes:iterate(S) do
          local itt = os.clock()
          inner_time = inner_time + os.clock() - itt
          add_constraint(v.expression, S2, v.indexes, undefined)
          inner_time = inner_time + os.clock() - itt
        end
        tabulate_time = tabulate_time + os.clock() - tt
      end
      current_address[#current_address] = nil
    end
  end

  search(scope.contents(S))
  return constraints
end

local function linearise_constraints(S)
  local count = 0
  local search_time, linearise_time = os.clock(), 0
  build_ref_time, tabulate_time, inner_time = 0, 0, 0
  local result = find_constraints(S,
    function(c, S, undefined)
      if undefined and undefined[1] then
        error(("error while linearising the constraint '%s': Some of the constraint's indices are undefined"):
          format(lib.repr(c)), 0)
      end
      local st = os.clock()
      local status, lhs, type, constant = pcall(c.linearise, c, S)
      if not status then
        error(("error while linearising the constraint '%s':\n   %s"):
          format(lib.repr(c), lhs:gsub("\n", "\n    ")), 0)
      end
      linearise_time = linearise_time + os.clock() - st
      count = count + 1
      io.stderr:write(("\rGenerated %d constraints..."):format(count))
      return lhs, type, constant
    end)
  io.stderr:write("\n")
  search_time = os.clock() - search_time
  io.write(("Search time: %f, linearise time: %f, build_ref time: %f, tabulate time %f, inner_time %f\n"):
    format(search_time, linearise_time, build_ref_time, tabulate_time, inner_time))
  return result
end


local function tostring_constraints(S)
  return find_constraints(S,
    function(c, S, undefined)
      local s = c:tostring(S)
      return s
    end)
end


-- Utilities -------------------------------------------------------------------

local function new_scope(S, values)
  if values then
    local S2 = scope.spawn(S)
    scope.set(S2, values)
    S = S2
  end
  return S
end

local function sense(S)
  local sense = S.sense
  if not core.defined(sense) then return end
  assert(type(sense) == "string", "Optimisation sense must be a string")
  sense = sense:lower():gsub("z", "s")
  assert(sense == "minimise" or sense == "maximise", "Optimisation sense must be 'minimise' or 'maximise'")
  return sense
end


-- Sparse Form -----------------------------------------------------------------

function sparse_form(S)

  local constant, objective = linearise.linearise(S.objective, S)
  local constraints = linearise_constraints(S)
  
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
      error(("The variable '%s' is not involved in any constraint, but is in the objective\n"):format(lib.repr(name)))
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
    sparse_constraints[#sparse_constraints+1] = { ref=c.ref, l=low, h=high, m=cc }
  end

  return ordered_variables, sparse_constraints
end


-- Writing ---------------------------------------------------------------------

function write(S, values, f)
  S = new_scope(S, values)
  f = f or io.stdout

  -- Write the objective
  local sense = sense(S)
  local objective = scope.lookup(S, "objective")
  if objective and sense then
    local o = rima.E(objective.value, S)
    f:write(("%s:\n  %s\n"):format((sense == "minimise" and "Minimise") or "Maximise", lib.repr(o)))
  else
    f:write("No objective defined\n")
  end

  -- Write constraints
  f:write("Subject to:\n")  
  local constraints = tostring_constraints(S)
  local maxlen = 0
  for _, c in ipairs(constraints) do
    c.name = lib.repr(c.ref)
    maxlen = math.max(maxlen, c.name:len())
  end
  for i, c in ipairs(constraints) do
    f:write(("  %s:%s %s\n"):format(c.name, (" "):rep(maxlen - c.name:len()), c[1]))
  end
end


function write_sparse(S, values, f)
  S = new_scope(S, values)
  f = f or io.stdout

  local variables, constraints = sparse_form(S)
  
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


-- Solving ---------------------------------------------------------------------

function solve(solver, S, values)
  S = new_scope(S, values)
  local solve_mod = require("rima.solvers."..solver)
  local variables, constraints = sparse_form(S, S.objective)
  io.stderr:write(("Problem generated: %d variables, %d constraints.  Solving...\n"):format(#variables, #constraints))

  local r = solve_mod.solve(sense(S), variables, constraints)

  local r2 = {}
  for i, v in ipairs(r.variables) do
    core.set(variables[i].ref, r2, v)
  end
  for i, v in ipairs(r.constraints) do
    core.set(constraints[i].ref, r2, v)
  end
  return r.objective, r2
end


-- creating constraints --------------------------------------------------------

function C(lhs, rel, rhs) -- create a constraint
  return constraint:new(lhs, rel, rhs)
end


-- EOF -------------------------------------------------------------------------

