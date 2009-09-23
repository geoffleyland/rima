-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local scope = require("rima.scope")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local b = rima.R"b"
  local S = scope.create{ a = rima.free() }

  local t
  T:expect_error(function() t = rima.tabulate({1}, 3) end, "expected string or simple reference, got '1' %(number%)")
  T:expect_error(function() rima.tabulate({S.a}, 3) end, "expected string or simple reference, got 'a' %(ref%)")
  T:expect_error(function() rima.tabulate({b[10]}, 3) end, "expected string or simple reference, got 'b%[10%]' %(ref%)")
  T:expect_ok(function() t = rima.tabulate({"a", "b", "c"}, 3) end, "constructing tabulate")

  do
    local Q, x, y, z = rima.R"Q, x, y"
    local e = rima.sum({Q}, x[Q])
    local S = scope.create{ Q={4, 5, 6} }
    S.x = rima.tabulate({y}, y.key^2)
    T:check_equal(rima.E(e, S), 77)
    T:expect_error(function() rima.E(x, S) end, "the tabulation needs 1 indexes, got 0")
    T:expect_error(function() rima.E(x[1][2], S) end, "the tabulation needs 1 indexes, got 2")
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

