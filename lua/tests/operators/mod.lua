-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local mod = require("rima.operators.mod")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local R = index.R
  local E = core.eval
  local D = lib.dump

  T:test(object.typeinfo(mod:new()).mod, "typeinfo(mod:new()).mod")
  T:check_equal(object.typename(mod:new()), "mod", "typename(mod:new()) == 'mod'")

  local a, b = R"a, b"
  local S = { a = 5 }

  T:check_equal(D(a%2), '%(index(address{"a"}), 2)')
  T:check_equal(a%2, "a%2")
  T:check_equal(a%b, "a%b")
  T:check_equal(E(a%2, S), 1)
  T:check_equal(D(2%a), '%(2, index(address{"a"}))')
  T:check_equal(E(7%a, S), 2)

  -- Identities
  T:check_equal(E(0%b, S), 0)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

