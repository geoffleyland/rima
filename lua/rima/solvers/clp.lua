-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local assert, ipairs = assert, ipairs

local core = require("rima_clp_core")

module(...)

--------------------------------------------------------------------------------

function solve(sense, variables, constraints)
  local m = core.new()
  assert(m:resize(0, #variables))
  assert(m:build_rows(constraints))
  assert(m:set_objective(variables, sense))
  assert(m:solve())
  return assert(m:get_solution())
end

-- EOF -------------------------------------------------------------------------
