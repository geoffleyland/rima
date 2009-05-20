-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local tests = require("rima.tests")
local operators = require("rima.operators")

module(...)

--------------------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:run(operators.add.test)
  T:run(operators.mul.test)
  T:run(operators.pow.test)
  T:run(operators.math.test)
  T:run(operators.call.test)
  T:run(operators.sum.test)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

