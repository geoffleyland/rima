-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local tests = require("rima.tests")
local values = require("rima.values")

module(...)

--------------------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:run(values.function_v.test)
  T:run(values.tabulate.test)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

