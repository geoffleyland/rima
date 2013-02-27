-- Copyright (c) 2009-2011 Incremental IP Limited
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
local solvers = require("rima.solvers")

module(...)


-- Model -----------------------------------------------------------------------

local proxy_mt = {}


function new(parent, ...)
  return scope.new_with_metatable(proxy_mt, parent, ...)
end


-- Solve tools -----------------------------------------------------------------

local function sense(M)
  local sense = core.eval(index:new().sense, M)
  local ti = object.typeinfo(sense)
  if ti.index then return end
    if not ti.string then
    error(("Optimisation sense must be a string.  Got '%s'"):format(lib.repr(sense)),2)
  end
  sense = sense:lower():gsub("z", "s")
  if sense ~= "minimise" and sense ~= "maximise" then
    error("Optimisation sense must be 'minimise' or 'maximise'", 2)
  end
  return sense
end


-- Constraint Handling ---------------------------------------------------------

function find_constraints(S, callback)
  local t0 = os.clock()

  local constraints = {}
  local current_address = {}
  local current_sets = set_list:new()

  local function build_ref(S, sets, undefined)
    local r = index:new()
    local set_index, undefined_index = 1, 1
    for i = 1, #current_address do
      local current_index = current_address[i]
      if object.typeinfo(current_index).set_default_thinggy then
        current_index = core.eval(index:new(nil, sets[set_index].names[1]), S)
        if not core.defined(current_index) then
          current_index = sets[set_index]
        end
        set_index = set_index + 1
      end
      r = index:new(r, current_index)
    end
    return r
  end

  local function add_constraint(c, ref, undefined)
    constraints[#constraints+1] = { constraint=c, ref=ref, undefined=undefined }
    if callback then callback(#constraints, t0) end
  end

  local function search(t)
    for k, v in pairs(t) do
      current_address[#current_address+1] = k
      local tik = object.typeinfo(k)
      if tik.set_default_thinggy then
        current_sets:append(k.set_ref)
      end
      local tiv = object.typeinfo(v)
      if tiv.table and not getmetatable(v) then
        search(v)
      elseif tiv.constraint then
        if not current_sets[1] then
          add_constraint(core.eval(v, S), build_ref(S))
        else
          for S2, undefined in current_sets:iterate(scope.new(S), "$mp") do
            local ref = build_ref(S2["$mp"], current_sets, undefined)
            add_constraint(core.eval(ref, S2), ref, undefined) 
          end
        end
      elseif tiv.closure and object.typeinfo(v.exp).constraint then
        local cs2 = current_sets:copy()
        cs2:prepare(nil, v.name)
        for S2, undefined in cs2:iterate(scope.new(S), v.name) do
          add_constraint(core.eval(v.exp, S2), build_ref(S2[v.name], cs2, undefined), undefined)
        end
      end
      current_address[#current_address] = nil
      if tik.set_default_thinggy then
        current_sets:pop()
      end
    end
  end

  search(scope.contents(S))
  if callback then callback(#constraints, t0, true) end
  return constraints
end


-- Preparing problems ----------------------------------------------------------

local tl = 0
local function report_search_time(cc, t0, last)
  local t = os.clock()
  if t - tl > 0.5 or last then
    io.stderr:write(("\rFound %d constraints in %.1f secs..."):format(cc, t - t0))
    tl = t
  end
  if last then io.stderr:write("\n") end
end


local function prepare_constraints(M)
  local constraints = find_constraints(M, report_search_time)

  local constraint_expressions, constraint_info = {}, {}
  local linear = true

  t0 = os.clock()
  for i, c in ipairs(constraints) do
    if c.undefined and c.undefined[1] then
      error(("error while preparing the constraint '%s': Some of the constraint's indices are undefined"):
        format(lib.repr(c.constraint)), 0)
    end

    local lower, upper, exp, linear_exp = c.constraint:characterise(M)
    if not linear_exp then linear = false end

    c.lower = lower
    c.upper = upper
    c.linear_exp = linear_exp
    constraint_info[i] = c
    constraint_expressions[i] = exp

    local t = os.clock()
    if t - tl > 0.5 then
    io.stderr:write(("\rGenerated %d constraints in %.1f secs..."):format(i, os.clock() - t0))
      tl = t
  end
  end
  io.stderr:write(("\rGenerated %d constraints in %.1f secs...\n"):format(#constraints, os.clock() - t0))
  return linear, constraint_expressions, constraint_info
end


local function prepare_variables(M, objective, constraints)
  local has_integer_variables = false

  -- List all the variables in the constraints
  local variable_map = {}
  for _, e in ipairs(constraints) do
    core.list_variables(e, nil, variable_map)
  end

  -- and in the objective
  local objective_variables = {}
  core.list_variables(objective, nil, objective_variables)

  -- and check that everything in the objective appears in a constraint
  for name in pairs(objective_variables) do
    if not variable_map[name] then
      error(("The variable '%s' is not involved in any constraint, but is in the objective\n"):format(lib.repr(name)))
    end
  end

  -- work out the types of the variables...
  local sorted_variables = {}
  local i = 1
  for n, v in pairs(variable_map) do
    local _, t = core.eval(v.ref, M)
    local ti = object.typeinfo(t)
    if not ti.number_t then
      if ti.undefined_t then
        error(("expecting a number type for '%s', got '%s'"):format(v.name, t:describe(v.name)), 0)
      else
        error(("expecting a number type for '%s', got '%s'"):format(v.name, lib.repr(t)), 0)
      end
    end
    if t.integer then has_integer_variables = true end
    v.type = t

    sorted_variables[i] = v
    i = i + 1
  end

  -- and sort them
  table.sort(sorted_variables, function(a, b) return a.name < b.name end)
  
  -- assign indices to the variables
  for i, v in ipairs(sorted_variables) do
    v.index = i
  end

  return has_integer_variables, variable_map, sorted_variables
end


local function choose_solver(objective_is_linear, constraints_are_linear, has_integer_variables)
  local objective_type = objective_is_linear and "linear" or "nonlinear"
  local constraint_type = constraints_are_linear and "linear" or "nonlinear"
  local variable_type = has_integer_variables and "integer" or "continuous"

  local best_preference, best_solver, best_name = math.huge
  for n, s in pairs(solvers) do
    if s.available and
       s.objective[objective_type] and
       s.constraints[constraint_type] and
       s.variables[variable_type] and
       s.preference < best_preference then
      best_preference = s.preference
      best_solver = s
      best_name = n
    end
  end

  return best_solver, best_name
end


local function format_results(r, variables, constraints)
  local primal, dual = {}, {}
  local has_dual = true
  primal.objective = r.objective
  for i, v in ipairs(r.variables) do
    local ref = variables[i].ref
    if type(v) == "table" then
      index.set(ref, primal, v.p)
      index.set(ref, dual, v.d)
    else
      index.set(ref, primal, v)
      has_dual = false
    end
  end
  for i, v in ipairs(r.constraints) do
    local ref = constraints[i].ref
    if type(v) == "table" then
      index.set(ref, primal, v.p)
      index.set(ref, dual, v.d)
    else
      index.set(ref, primal, v)
      has_dual = false
    end
  end
  return primal, has_dual and dual or nil
end


-- String Representation -------------------------------------------------------

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
    sorted_variables[#sorted_variables+1] = v
  end
  table.sort(sorted_variables, function(a, b) return a.name < b.name end)

  for _, v in ipairs(sorted_variables) do
    local _, vt = core.eval(v.ref, M)
    if vt then
      append(r, latex and "& " or "  ", vt:describe(v.ref, format))
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


-- Solving ---------------------------------------------------------------------

function solve(M, ...)
  M = new(M, ...)

  local objective = core.eval(index:new().objective, M)
  local objective_is_linear, objective_constant, linear_objective = pcall(linearise.linearise, objective, M)

  local constraints_are_linear, constraint_expressions, constraint_info = prepare_constraints(M)

  local has_integer_variables, variable_map, ordered_variables = prepare_variables(M, objective, constraint_expressions)

  local solver, solver_name = choose_solver(objective_is_linear, constraints_are_linear, has_integer_variables)

  if not solver then
    return nil, "No available solver can handle this type of problem"
  end

  io.stderr:write(("Solving with %s...\n"):format(solver_name))

  local r, message = solver.solve{
    sense = sense(M),
    objective = objective,
    linear_objective = linear_objective,
    constraint_expressions = constraint_expressions,
    constraint_info = constraint_info,
    variable_map = variable_map,
    ordered_variables = ordered_variables
  }

  if not r then
    return nil, message
  end

  return format_results(r, ordered_variables, constraint_info)
end


function solve_with(solver, M, ...)
  if not solvers[solver].available then
    error("The solver '"..solver.."' is not available: '"..solvers[solver].problem.."'")
  end
  local p0 = solvers[solver].preference
  solvers[solver].preference = -1
  local r1, r2, r3 = solve(M, ...)
  solvers[solver].preference = p0
  return r1, r2, r3
end


-- creating constraints --------------------------------------------------------

function C(lhs, rel, rhs) -- create a constraint
  return constraint:new(lhs, rel, rhs)
end


-- EOF -------------------------------------------------------------------------

