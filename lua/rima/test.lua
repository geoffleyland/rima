-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("rima")
local tests = require("rima.tests")
require("rima.values.test")
require("rima.operators.test")
local rima = rima

module(...)

--------------------------------------------------------------------------------

function test()
  local T = tests.series:new(_M, false)

  T:run(rima.tests.test)
  T:run(rima.values.test.test)
  T:run(rima.operators.test.test)
  T:run(rima.constraint.test)

  return T:close()
end

return test

-- EOF -------------------------------------------------------------------------

