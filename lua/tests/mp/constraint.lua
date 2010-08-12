-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local constraint = require("rima.mp.constraint")
local lib = require("rima.lib")
local scope = require("rima.scope")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local a, b, c, d, i, I, j, J = rima.R"a, b, c, d, i, I, j, J"
  local S = scope.new()
  S.a = rima.free()
  S.b = 3
  S.c = rima.free()
  S.d = 5
  T:expect_ok(function() S.e = constraint:new(a * b + c * d, "<=", 3) end)
  T:check_equal(lib.repr(S.e), "a*b + c*d <= 3")

  return T:close()
end


-- EOF -------------------------------------------------------------------------