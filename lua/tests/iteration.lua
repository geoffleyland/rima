-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local object = require("rima.object")
require("rima.iteration")
--local scope = require("rima.scope")
--local expression = require("rima.expression")
--local ref = require("rima.ref")
--local iteration = require("rima.iteration")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)
  
  local x, y, Q, R, r = rima.R"x, y, Q, R, r"
  local S = { x = { 10, 20, 30 }, Q = {"a", "b", "c"}, R = rima.range(1, r) }
  
  T:check_equal(rima.sum({Q}, x[Q]), "sum({Q}, x[Q])")
  T:check_equal(rima.E(rima.sum({Q}, x[Q]), S), 60)
  T:check_equal(rima.sum({rima.alias(Q, "y")}, x[y]), "sum({y in Q}, x[y])")
  T:check_equal(rima.sum({rima.alias(Q, "Q")}, x[Q]), "sum({Q}, x[Q])")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "y")}, x[y]), S), 60)
  T:check_equal(rima.sum({rima.alias(Q, "y")}, rima.ord(y)), "sum({y in Q}, ord(y))")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "y")}, rima.ord(y)), S), 6)
  T:check_equal(rima.E(rima.sum({rima.alias(x, "y")}, rima.value(y)), S), 60)
  T:check_equal(rima.sum({R}, rima.value(R)), "sum({R}, value(R))")
  T:check_equal(rima.E(rima.sum({R}, rima.value(R)), S), "sum({R in range(1, r)}, value(range(1, r)))")
  T:check_equal(rima.E(rima.sum({rima.alias(R, "y")}, rima.value(y)), S), "sum({y in range(1, r)}, value(y))")
  S.r = 10
  T:check_equal(rima.E(rima.sum({rima.alias(R, "y")}, rima.value(y)), S), 55)

  return T:close()
end

-- EOF -------------------------------------------------------------------------

