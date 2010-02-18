-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local constraint = require("rima.constraint")
local scope = require("rima.scope")
require("rima.public")
require("rima.private")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local a, b, c, d, i, I, j, J = rima.R"a, b, c, d, i, I, j, J"
  local S = scope.new()
  S.a = rima.free()
  S.b = 3
  S.c = rima.free()
  S.d = 5
  T:expect_ok(function() S.e = constraint:new(a * b + c * d, "<=", 3) end)
  T:check_equal(rima.repr(S.e), "a*b + c*d <= 3")

  return T:close()
end


-- EOF -------------------------------------------------------------------------
