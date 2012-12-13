-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local pow = require("rima.operators.pow")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")


------------------------------------------------------------------------------

return function(T)
  local R = index.R
  local E = core.eval
  local D = lib.dump

  T:test(object.typeinfo(pow:new()).pow, "typeinfo(pow:new()).pow")
  T:check_equal(object.typename(pow:new()), "pow", "typename(pow:new()) == 'pow'")

  local a, b = R"a, b"
  local S = { a = 5 }

  T:check_equal(D(a^2), '*(index(address{"a"})^2)')
  T:check_equal(a^2, "a^2")
  T:check_equal(a^b, "a^b")
  T:check_equal(E(a^2, S), 25)
  T:check_equal(D(2^a), '^(2, index(address{"a"}))')
  T:check_equal(E(2^a, S), 32)

  -- Identities
  T:check_equal(E(0^b, S), 0)
  T:check_equal(E(1^b, S), 1)
  T:check_equal(E(b^0, S), 1)
  T:check_equal(D(E(b^1, S)), 'index(address{"b"})')

  -- Tests including add and mul are in rima.expression
end


------------------------------------------------------------------------------

