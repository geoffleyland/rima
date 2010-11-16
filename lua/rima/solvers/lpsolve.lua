-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local assert, ipairs, pcall = assert, ipairs, pcall

local status, core = pcall(require, "rima_lpsolve_core")

module(...)

--------------------------------------------------------------------------------

function solve(sense, variables, constraints)
  if not status then return nil, "lpsolve not available" end
  local m = core.new(0, #variables)
  assert(m:resize(#constraints, #variables))
  assert(m:build_rows(constraints))
  assert(m:set_objective(variables, sense))
  assert(m:solve())
  return assert(m:get_solution())
end

-- EOF -------------------------------------------------------------------------

