-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("rima")
local tests = require("rima.tests")
require("rima.object")
require("rima.proxy")
require("rima.tools")
require("rima.values.test")
require("rima.types.test")
require("rima.scope")
require("rima.operators.test")
local rima = rima

module(...)

--------------------------------------------------------------------------------

function test()
  local T = tests.series:new(_M, false)

  T:run(rima.tests.test)
  T:run(rima.object.test)
  T:run(rima.proxy.test)
  T:run(rima.tools.test)
  T:run(rima.values.test.test)
  T:run(rima.types.test.test)
  T:run(rima.scope.test)
  T:run(rima.ref.test)
  T:run(rima.expression.test1)
  T:run(rima.operators.test.test)
  T:run(rima.expression.test2)
  T:run(rima.constraint.test)

  return T:close()
end

return test

-- EOF -------------------------------------------------------------------------

