-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local assert, ipairs = assert, ipairs

local core = require("rima_cbc_core")
local ref = require("rima.ref")

module(...)

--------------------------------------------------------------------------------

function solve(sense, variables, constraints)
  local m = core.new()
  assert(m:set_objective(variables, sense))
  assert(m:build_rows(constraints))
  assert(m:solve())
  local s = assert(m:get_solution())

  local s2 = { objective=s.objective, constraints=s.constraints, variables={} }
  for i, v in ipairs(s.variables) do
    ref.set(variables[i].ref, s2.variables, v)
  end
  return s2
end

-- EOF -------------------------------------------------------------------------
