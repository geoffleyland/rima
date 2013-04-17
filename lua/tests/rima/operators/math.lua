-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local lib = require("rima.lib")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = interface.eval
  local D = lib.dump
  local R = interface.R
  local opmath = interface.math

  local a, b  = R"a, b"

  T:check_equal(opmath.exp(1), math.exp(1))

  T:check_equal(D(opmath.exp(a)), 'expression(exp(index(address{"a"})))')
  local S = {}
  T:check_equal(E(opmath.exp(a), S), "exp(a)")
  S.a = 4
  T:check_equal(E(opmath.sqrt(a), S), 2)
end


------------------------------------------------------------------------------

