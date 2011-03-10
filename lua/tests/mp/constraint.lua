-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local constraint = require("rima.mp.constraint")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local rima = require("rima")

local math = require("math")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local E = core.eval

  local a, b, c, d, i, I, j, J = rima.R"a, b, c, d, i, I, j, J"
  local S = scope.new()
  S.a = rima.free()
  S.b = 3
  S.c = rima.free()
  S.d = 5
  local C
  T:expect_ok(function() C = constraint:new(a * b + c * d, "<=", 3) end)
  T:check_equal(lib.repr(C), "a*b + c*d <= 3")
  T:expect_ok(function() S.e = C end)
  T:check_equal(lib.repr((core.eval(S.e))), "3*a + 5*c <= 3")

  local lower, upper, lhs
  T:expect_ok(function() lower, upper, _, lhs = C:characterise(S) end)
  T:check_equal(upper, 3)
  T:check_equal(lower, -math.huge)
  T:check_equal(lhs.a.coeff, 3)
  T:check_equal(lhs.c.coeff, 5)

  return T:close()
end


-- EOF -------------------------------------------------------------------------
