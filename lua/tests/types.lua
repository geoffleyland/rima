-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("tests.series")
require("tests.types.undefined_t")
require("tests.types.number_t")
local tests = tests

module(...)

--------------------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:run(tests.types.undefined_t.test)
  T:run(tests.types.number_t.test)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

