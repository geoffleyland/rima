-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local call = require("rima.operators.call")

local string = require("string")
local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = lib.dump
  local E = core.eval

  T:test(object.typeinfo(expression:new(call)).call, "typeinfo(call).call")
  T:check_equal(object.typename(expression:new(call)), "call")

  do
    local a, b = rima.R"a, b"

    T:check_equal(D(a(b)), "call(index(address{\"a\"}), index(address{\"b\"}))")
    T:check_equal(a(b), "a(b)")
    T:check_equal(rima.E(a(b)), "a(b)")
  end

  do
    local f, z = rima.R"f, z"
    T:expect_ok(function() f(z) end)
    T:check_equal(D(f(z)), "call(index(address{\"f\"}), index(address{\"z\"}))")
    T:check_equal(f(z), "f(z)")
    T:check_equal(D(E(f(z))), "call(index(address{\"f\"}), index(address{\"z\"}))")
    T:check_equal(E(f(z)), "f(z)")
  end

  -- The a here ISN'T in the global scope, it's in the function scope
  do
    local a, f, x = rima.R"a, f, x"
    local S = { f = rima.F({a}, 2 * a) }

    local c = f(3 + x)
    T:check_equal(c, "f(3 + x)")

    T:check_equal(D(c), "call(index(address{\"f\"}), +(1*3, 1*index(address{\"x\"})))")
    T:check_equal(E(c, S), "2*(3 + x)")
    S.x = 5
    T:check_equal(E(c, S), 16)
  end

  do
    local f, a, b = rima.R"f, a, b"
    local S = { f = string.sub, a = "hello", b = 2 }
    T:check_equal(E(f(a, b), S), "ello")  
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

