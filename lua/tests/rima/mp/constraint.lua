-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local constraint = require("rima.mp.constraint")

local core = require("rima.core")
local number_t = require("rima.types.number_t")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = interface.eval
  local R = interface.R

  local a, b, c, d = R"a, b, c, d"
  local S = { a = number_t.free(), b = 3, c = number_t.free(), d = 5 }
  local C
  T:expect_ok(function() C = constraint:new(a * b + c * d, "<=", 3) end)
  T:check_equal(C, "a*b + c*d <= 3")
  T:check_equal(E(C, S), "3*a + 5*c <= 3")

  local lower, upper, lhs, _
  T:expect_ok(function() lower, upper, _, lhs = C:characterise(S) end)
  T:check_equal(upper, 3)
  T:check_equal(lower, -math.huge)
  T:check_equal(lhs.a.coeff, 3)
  T:check_equal(lhs.c.coeff, 5)
end


------------------------------------------------------------------------------
