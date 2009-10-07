-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local string = require("string")
local series = require("test.series")
local call = require("rima.operators.call")
local scope = require("rima.scope")
local expression = require("rima.expression")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local S = scope.create{ a = rima.free(), b = rima.free(), x = rima.free() }

  T:check_equal(expression.dump(S.a(S.b)), "call(ref(a), ref(b))")
  T:check_equal(S.a(S.b), "a(b)")
  T:check_equal(rima.E(S.a(S.b), S), "a(b)")

  -- The a here ISN'T in the global scope, it's in the function scope
  S.f = rima.F({rima.R"a"}, 2 * rima.R"a")

  local c = rima.R"f"(3 + S.x)
  T:check_equal(c, "f(3 + x)")

  T:check_equal(expression.dump(c), "call(ref(f), +(1*number(3), 1*ref(x)))")
  T:check_equal(expression.eval(c, S), "2*(3 + x)")
  T:check_equal(expression.eval(c, scope.spawn(S, { x=5 })), 16)

  local c2 = expression:new(call, rima.R"f")
  T:expect_error(function() expression.eval(c2, S) end,
    "error evaluating 'f%(%)' as 'function%(a%) return 2%*a' with arguments %(%):\n  the function needs to be called with at least 1 arguments, got 0")

  do
    local f, a, b = rima.R"f, a, b"
    local S = scope.create{ f = string.sub, a = "hello", b = 2 }
    T:check_equal(expression.eval(f(a, b), S), "ello")  
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

