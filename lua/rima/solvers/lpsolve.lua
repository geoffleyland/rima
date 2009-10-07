-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local assert, ipairs = assert, ipairs

local core = require("rima_lpsolve_core")
local expression = require("rima.expression")

module(...)

--------------------------------------------------------------------------------

function solve(sense, variables, constraints)
  local m = core.new(0, #variables)
  assert(m:resize(#constraints, #variables))
  assert(m:build_rows(constraints))
  assert(m:set_objective(variables, sense))
  assert(m:solve())
  local s = assert(m:get_solution())
  
  local s2 = { objective=s.objective, constraints=s.constraints, variables={} }
  for i, v in ipairs(s.variables) do
    expression.set(variables[i].ref, s2.variables, v)
  end
  return s2
end

-- EOF -------------------------------------------------------------------------
