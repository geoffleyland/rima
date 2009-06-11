-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
require("rima.values.tabulate")
local scope = require("rima.scope")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local t
  T:expect_ok(function() t = rima.tabulate({"a", "b", "c"}, 3) end, "constructing tabulate")

  do
    local Q, x, y, z = rima.R"Q, x, y"
    local e = rima.sum({Q}, x[Q])
    local S = scope.create{ Q={4, 5, 6} }
    S.x = rima.tabulate({y}, rima.value(y)^2)
    T:check_equal(rima.E(e, S), 77)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

