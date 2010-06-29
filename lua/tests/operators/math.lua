-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")

local series = require("test.series")
local scope = require("rima.scope")
local expression = require("rima.expression")
local lib = require("rima.lib")
require("rima.operators.math")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local a, b  = rima.R"a, b"

  T:check_equal(rima.exp(1), math.exp(1))

  T:check_equal(lib.dump(rima.exp(a)), "exp(ref(a))")
  local S = scope.new()
  T:check_equal(expression.eval(rima.exp(a), S), "exp(a)")
  S.a = 4
  T:check_equal(expression.eval(rima.sqrt(a), S), 2)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

