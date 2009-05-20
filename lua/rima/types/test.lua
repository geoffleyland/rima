-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local tests = require("rima.tests")
local types = require("rima.types")

module(...)

--------------------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:run(types.undefined_t.test)
  T:run(types.number_t.test)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

