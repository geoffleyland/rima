-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local string = require("string")
local series = require("test.series")
local object = require("rima.lib.object")
local call = require("rima.operators.call")
local scope = require("rima.scope")
local expression = require("rima.expression")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local D = expression.dump
  local B = expression.bind
  local E = expression.eval

  local S = scope.new{ a = rima.free(), b = rima.free(), x = rima.free() }

  T:test(object.isa(call, expression:new(call)), "isa(call, call)")
  T:check_equal(object.type(expression:new(call)), "call")

  T:check_equal(D(S.a(S.b)), "call(ref(a), ref(b))")
  T:check_equal(S.a(S.b), "a(b)")
  T:check_equal(rima.E(S.a(S.b), S), "a(b)")

  do
    local f, z = rima.R"f, z"
    T:expect_ok(function() f(z) end)
    T:check_equal(D(f(z)), "call(ref(f), ref(z))")
    T:check_equal(f(z), "f(z)")
    T:check_equal(D(B(f(z), S)), "call(ref(f), ref(z))")
    T:check_equal(B(f(z), S), "f(z)")
    T:check_equal(D(E(f(z), S)), "call(ref(f), ref(z))")
    T:check_equal(E(f(z), S), "f(z)")

    T:check_equal(D(B(f(z))), "call(ref(f), ref(z))")
    T:check_equal(B(f(z)), "f(z)")
    T:check_equal(D(E(f(z))), "call(ref(f), ref(z))")
    T:check_equal(E(f(z)), "f(z)")
  end

  -- The a here ISN'T in the global scope, it's in the function scope
  S.f = rima.F({rima.R"a"}, 2 * rima.R"a")

  local c = rima.R"f"(3 + S.x)
  T:check_equal(c, "f(3 + x)")

  T:check_equal(D(c), "call(ref(f), +(1*number(3), 1*ref(x)))")
  T:check_equal(E(c, S), "2*(3 + x)")
  T:check_equal(E(c, scope.spawn(S, { x=5 })), 16)

  local c2 = expression:new(call, rima.R"f")
  T:expect_error(function() E(c2, S) end,
    "error evaluating 'f%(%)' as 'function%(a%) return 2%*a' with arguments %(%):\n  the function needs to be called with at least 1 arguments, got 0")

  do
    local f, a, b = rima.R"f, a, b"
    local S = scope.new{ f = string.sub, a = "hello", b = 2 }
    T:check_equal(E(f(a, b), S), "ello")  
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

