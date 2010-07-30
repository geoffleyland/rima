-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")

local series = require("test.series")
local scope = require("rima.scope")
local lib = require("rima.lib")
local core = require("rima.core")
require("rima.operators.math")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local E = core.eval

  local a, b  = rima.R"a, b"

  T:check_equal(rima.exp(1), math.exp(1))

  T:check_equal(lib.dump(rima.exp(a)), "exp(ref(a))")
  local S = scope.new()
  T:check_equal(E(rima.exp(a), S), "exp(a)")
  S.a = 4
  T:check_equal(E(rima.sqrt(a), S), 2)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

