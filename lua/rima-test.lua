-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("tests.series_test")
require("tests.object")

--------------------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new("rima", show_passes)

  T:run(tests.series_test.test)
  T:run(tests.object.test)

  return T:close()
end

test(false)

-- EOF -------------------------------------------------------------------------

