-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local mod = require("rima.operators.mod")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = interface.eval
  local D = lib.dump
  local R = interface.R

  T:test(object.typeinfo(mod:new()).mod, "typeinfo(mod:new()).mod")
  T:check_equal(object.typename(mod:new()), "mod", "typename(mod:new()) == 'mod'")

  local a, b = R"a, b"
  local S = { a = 5 }

  T:check_equal(D(a%2), 'expression(%(index(address{"a"}), 2))')
  T:check_equal(a%2, "a%2")
  T:check_equal(a%b, "a%b")
  T:check_equal(E(a%2, S), 1)
  T:check_equal(D(2%a), 'expression(%(2, index(address{"a"})))')
  T:check_equal(E(7%a, S), 2)

  -- Identities
  T:check_equal(E(0%b, S), 0)
end


------------------------------------------------------------------------------

