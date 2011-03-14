-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

require("rima.operators.math")

local math = require("math")

local series = require("test.series")
local lib = require("rima.lib")
local core = require("rima.core")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local E = core.eval
  local D = lib.dump

  local a, b  = rima.R"a, b"

  T:check_equal(rima.exp(1), math.exp(1))

  T:check_equal(D(rima.exp(a)), 'exp(index(address{"a"}))')
  local S = {}
  T:check_equal(E(rima.exp(a), S), "exp(a)")
  S.a = 4
  T:check_equal(E(rima.sqrt(a), S), 2)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

