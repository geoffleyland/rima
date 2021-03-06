-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local call = require("rima.operators.call")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = interface.eval
  local D = lib.dump
  local R = interface.R

  T:test(object.typeinfo(call:new()).call, "typeinfo(call).call")
  T:check_equal(object.typename(call:new()), "call")

  do
    local a, b = R"a, b"

    T:check_equal(D(a(b)), "expression(call(index(address{\"a\"}), index(address{\"b\"})))")
    T:check_equal(a(b), "a(b)")
    T:check_equal(E(a(b)), "a(b)")
  end

  do
    local f, z = R"f, z"
    T:expect_ok(function() f(z) end)
    T:check_equal(D(f(z)), "expression(call(index(address{\"f\"}), index(address{\"z\"})))")
    T:check_equal(f(z), "f(z)")
    T:check_equal(D(E(f(z))), "expression(call(index(address{\"f\"}), index(address{\"z\"})))")
    T:check_equal(E(f(z)), "f(z)")
  end

  -- The a here ISN'T in the global scope, it's in the function scope
  do
    local a, f, x = R"a, f, x"
    local S = { f = interface.func{a}(2 * a) }

    local c = f(3 + x)
    T:check_equal(c, "f(3 + x)")

    T:check_equal(D(c), "expression(call(index(address{\"f\"}), +(1*3, 1*index(address{\"x\"}))))")
    T:check_equal(E(c, S), "2*(3 + x)")
    S.x = 5
    T:check_equal(E(c, S), 16)
  end

  do
    local f, a, b = R"f, a, b"
    local S = { f = string.sub, a = "hello", b = 2 }
    T:check_equal(E(f(a, b), S), "ello")  
  end
end


------------------------------------------------------------------------------

