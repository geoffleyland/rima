-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local assert, ipairs, pcall = assert, ipairs, pcall

local status, core = pcall(require, "rima_cbc_core")

module(...)

--------------------------------------------------------------------------------

function solve(sense, variables, constraints)
  if not status then return nil, "cbc not available" end
  local m = core.new()
  assert(m:set_objective(variables, sense))
  assert(m:build_rows(constraints))
  assert(m:solve())
  return assert(m:get_solution())
end

-- EOF -------------------------------------------------------------------------

