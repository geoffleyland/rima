-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local io, math, os, table = require("io"), require("math"), require("os"), require("table")
local assert, error, ipairs, getmetatable, pairs, pcall, require, setmetatable, type =
      assert, error, ipairs, getmetatable, pairs, pcall, require, setmetatable, type

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local index = require("rima.index")
local set_list = require("rima.sets.list")
local closure = require("rima.closure")
local constraint = require("rima.mp.constraint")
local linearise = require("rima.mp.linearise")
local rima = require("rima")

module(...)


-- Utilities -------------------------------------------------------------------

local function sense(S)
  local sense = core.eval(index:new(nil, "sense"), S)
  if not core.defined(sense) then return end
  if type(sense) ~= "string" then
    error(("Optimisation sense must be a string.  Got '%s'"):format(lib.repr(sense)),2)
  end
  sense = sense:lower():gsub("z", "s")
  assert(sense == "minimise" or sense == "maximise", "Optimisation sense must be 'minimise' or 'maximise'")
  return sense
end


-- Constraint Handling ---------------------------------------------------------

local function find_constraints(S, f)
  local constraints = {}
  local current_address = {}
  local current_sets = set_list:new()

  local function build_ref(S, sets, undefined)
    local r = index:new()
    local set_index, undefined_index = 1, 1
    for i = 1, #current_address do
      local index = current_address[i]
      if scope.set_default_thinggy:isa(index) then
        index = core.eval(rima.R(current_sets[set_index].names[1]), S)
        if not index then
          index = undefined[undefined_index]
          undefined_index = undefined_index + 1
        else
          set_index = set_index + 1
        end
      end
      r = r[index]
    end
    return r
  end

  local function add_constraint(c, ref, undefined)
    constraints[#constraints+1] = { constraint=c, ref=ref, undefined=undefined }
  end

  local function search(t)
    for k, v in pairs(t) do
      current_address[#current_address+1] = k
      if scope.set_default_thinggy:isa(k) then
        current_sets:append(k.set_ref)
      end
      if type(v) == "table" and not getmetatable(v) then
        search(v)
      elseif constraint:isa(v) then
        if not current_sets[1] then
          add_constraint(core.eval(v, S), build_ref(S))
        else
          for S2, undefined in current_sets:iterate(scope.new(S), "$mp") do
            local ref = build_ref(S2["$mp"], current_sets, undefined)
            add_constraint(core.eval(ref, S2), ref, undefined) 
          end
        end
      elseif closure:isa(v) and constraint:isa(v.exp) then
        for S2, undefined in current_sets:iterate(scope.new(S), v.name) do
            add_constraint(core.eval(v.exp, S2), build_ref(S2[v.name], current_sets, undefined), undefined)
        end
      end
      current_address[#current_address] = nil
      if scope.set_default_thinggy:isa(k) then
        current_sets:pop()
      end
    end
  end

  search(scope.contents(S))
  return constraints
end


local function linearise_constraints(S)
  local t0 = os.clock()
  io.stderr:write("Searching for constraints...")
  local constraints = find_constraints(S)
  io.stderr:write(("\rFound %d constraints in %.1f secs\n"):format(#constraints, os.clock() - t0))

  local linearised = {}
  t0 = os.clock()
  for i, c in ipairs(constraints) do
    if c.undefined and c.undefined[1] then
      error(("error while linearising the constraint '%s': Some of the constraint's indices are undefined"):
        format(lib.repr(c.constraint)), 0)
    end

    local status, lhs, type, constant = pcall(c.constraint.linearise, c.constraint, S)
    if not status then
      error(("error while linearising the constraint '%s':\n   %s"):
        format(lib.repr(c.constraint), lhs:gsub("\n", "\n    ")), 0)
    end
    io.stderr:write(("\rGenerated %d constraints in %.1f secs..."):format(i, os.clock() - t0))
    linearised[i] = { ref=c.ref, constraint=c.constraint, lhs=lhs, type=type, constant=constant }
  end
  io.stderr:write("\n")
  return linearised
end


-- Model -----------------------------------------------------------------------

local proxy_mt = {}

function proxy_mt.__repr(M, format)
  if format.format == "dump" then return scope.proxy_mt.__repr(M, format) end
  local append, repr = lib.append, lib.repr
  local r = {}

  local latex = format.format == "latex"

  -- Write the objective
  local sense = sense(M)
  local objective = core.eval(index:new(nil, "objective"), M)
  if objective and sense then
    local f = latex and "\\text{\\bf %s} & %s \\\\\n" or "%s:\n  %s\n"
    if not latex then sense = sense:sub(1,1):upper()..sense:sub(2) end
    append(r, f:format(sense, repr(objective, format)))
  elseif latex then
    append(r, "\\text{no objective}\\\\\n")
  else
    append(r, "No objective defined\n")
  end

  -- Write constraints
  append(r, latex and "\\text{\\bf subject to} \\\\\n" or "Subject to:\n")  
  local constraints = find_constraints(M)
  local maxlen = 0
  for _, c in ipairs(constraints) do
    c.name = repr(c.ref, format)
    maxlen = math.max(maxlen, c.name:len())
  end
  for i, c in ipairs(constraints) do
    local cr = lib.repr(c.constraint, format)
    if latex then
      append(r, ("%s: & %s \\\\\n"):format(c.name, cr))
    else
      append(r, ("  %s:%s %s\n"):format(c.name, (" "):rep(maxlen - c.name:len()), cr))
    end
  end
  
  -- Write variables
  local variables = {}
  for i, c in ipairs(constraints) do
    c = core.eval(c.constraint.lhs - c.constraint.rhs, M)
    core.list_variables(c, M, variables)
  end
  local sorted_variables = {}
  for n, v in pairs(variables) do
    sorted_variables[#sorted_variables+1] = { name=n, index=v.index, sets=v.sets }
  end
  table.sort(sorted_variables, function(a, b) return a.name < b.name end)

  for _, v in ipairs(sorted_variables) do
    local status, vt = pcall(index.variable_type, v.index, M)
    if status then
      append(r, latex and "& " or "  ", vt:describe(v.index, format))
      if v.sets and v.sets[1] then
        append(r, latex and " \\forall " or " for all ")
        for i, s in ipairs(v.sets) do
          if i > 1 then append(r, ", ") end
          append(r, lib.repr(s, format))
        end
      end
      append(r, latex and " \\\\\n" or "\n")
    end
  end

  return lib.concat(r)
end
proxy_mt.__tostring = lib.__tostring


function new(parent, ...)
  return scope.new_with_metatable(proxy_mt, parent, ...)
end


-- Sparse Form -----------------------------------------------------------------

function sparse_form(S)

  local constant, objective = linearise.linearise(index:new(nil, "objective"), S)
  local constraints = linearise_constraints(S)
  
  -- Find all the variables in the constraints
  local variables = {}
  for _, c in pairs(constraints) do
    for name, info in pairs(c.lhs) do
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
    for v, k in pairs(c.lhs) do
      cc[#cc+1] = { variables[v].index, k.coeff }
    end
    table.sort(cc, function(a, b) return a[1] < b[1] end)
    local type, constant = c.type, c.constant
    local low = ((type == "==" or type == ">=") and constant) or -math.huge
    local high = ((type == "==" or type == "<=") and constant) or math.huge
    sparse_constraints[#sparse_constraints+1] = { ref=c.ref, l=low, h=high, m=cc }
  end

  return ordered_variables, sparse_constraints
end


-- Writing ---------------------------------------------------------------------

function write_sparse(S, values, f)
  S = new(S, values)

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

function solve(solver, S, ...)
  S = new(S, ...)

  local solve_mod = require("rima.solvers."..solver)
  local variables, constraints = sparse_form(S, S.objective)
  io.stderr:write(("Problem generated: %d variables, %d constraints.  Solving...\n"):format(#variables, #constraints))

  local r = solve_mod.solve(sense(S), variables, constraints)

  local primal, dual = {}, {}
  primal.objective = r.objective
  for i, v in ipairs(r.variables) do
    index.set(variables[i].ref, primal, v.p)
    index.set(variables[i].ref, dual, v.d)
  end
  for i, v in ipairs(r.constraints) do
    index.set(constraints[i].ref, primal, v.p)
    index.set(constraints[i].ref, dual, v.d)
  end
  return primal, dual
end


-- creating constraints --------------------------------------------------------

function C(lhs, rel, rhs) -- create a constraint
  return constraint:new(lhs, rel, rhs)
end


-- EOF -------------------------------------------------------------------------

