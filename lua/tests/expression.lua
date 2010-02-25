-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local expression = require("rima.expression")
local scope = require("rima.scope")
local object = require("rima.object")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

local function equal(T, expected, got)
  local function prep(z)
    if object.type(z) == "table" then
      local e = z[1]
      for i = 3, #z do
        local arg = z[2]
        arg = (arg ~= "" and arg) or nil
        e = expression[z[i]](e, arg)
      end
      return e
    else
      return z
    end
  end

  local e, g = prep(expected), prep(got)
  T:check_equal(g, e, nil, 1)
end

function test(show_passes)
  local T = series:new(_M, show_passes)

--  local o = operators.operator:new()

--  T:expect_error(function() expression:new({}) end,
--    "rima.expression:new: expecting an operator, variable or number for 'operator', got 'table'")
--  T:expect_error(function() expression:new("a") end,
--    "expecting an operator, variable or number for 'operator', got 'string'")
--  T:expect_ok(function() expression:new(o) end)
--  T:test(isa(expression:new(o), expression), "isa(expression:new(), expression)")
--  T:check_equal(type(expression:new(o)), "expression", "type(expression:new() == 'expression'")

  local S = scope.new()

  -- literals
  equal(T, "number(1)", {1, "", "dump"})
  equal(T, 1, {1, S, "eval"})

  -- variables
  local a = rima.R"a"
  equal(T, "ref(a)", {a, "", "dump"})
  T:expect_ok(function() rima.E(a, S) end)
  equal(T, "ref(a)", {a, S, "dump"})
  equal(T, "a", {a, S, "eval"})
  S.a = rima.free()
  equal(T, "a", {a, S, "eval"})
  equal(T, 5, {a, scope.spawn(S, { a=5 }), "eval"})

  -- repr
  T:check_equal(expression.dump(1), "number(1)")

  -- eval
  T:expect_ok(function() expression.eval(expression:new({}), {}) end)
  T:check_equal(expression.eval(expression:new({}), {}), "table()")

  -- tests with add, mul and pow
  do
    local a, b = rima.R"a, b"
    local S = rima.scope.new{ ["a,b"]=rima.free() }
    equal(T, "+(1*number(3), 4*ref(a))", {3 + 4 * a, S, "eval", "dump"})
    equal(T, "3 - 4*a", {4 * -a + 3, S, "eval"})
    equal(T, "+(1*number(3), 4**(ref(a)^1, ref(b)^1))", {3 + 4 * a * b, S, "eval", "dump"})
    equal(T, "3 - 4*a*b", {3 - 4 * a * b, S, "eval"})

    equal(T, "*(number(6)^1, ref(a)^1)", {3 * (a + a), S, "eval", "dump"})
    equal(T, "6*a", {3 * (a + a), S, "eval"})
    equal(T, "+(1*number(1), 6*ref(a))", {1 + 3 * (a + a), S, "eval", "dump"})
    equal(T, "1 + 6*a", {1 + 3 * (a + a), S, "eval"})

    equal(T, "*(number(1.5)^1, ref(a)^-1)", {3 / (a + a), S, "eval", "dump"})
    equal(T, "1.5/a", {3 / (a + a), S, "eval"})
    equal(T, "+(1*number(1), 1.5**(ref(a)^-1))", {1 + 3 / (a + a), S, "eval", "dump"})
    equal(T, "1 + 1.5/a", {1 + 3 / (a + a), S, "eval"})


    equal(T, "*(number(3)^1, ^(ref(a), number(2))^1)", {3 * a^2, "", "dump"})
    equal(T, "*(number(3)^1, ref(a)^2)", {3 * a^2, S, "eval", "dump"})
    equal(T, "*(number(3)^1, +(1*number(1), 1*ref(a))^2)", {3 * (a+1)^2, S, "eval", "dump"})
  end

  -- tests with references to expressions
  do
    local a, b = rima.R"a,b"
    local S = rima.scope.new{ a = rima.free(), b = 3 * (a + 1)^2 }
    equal(T, {b, S, "eval", "dump"}, {3 * (a + 1)^2, S, "eval", "dump"})
    equal(T, {5 * b, S, "eval", "dump"}, {5 * (3 * (a + 1)^2), S, "eval", "dump"} )
    
    local c, d = rima.R"c,d"
    S.d = 3 + (c * 5)^2
    T:expect_ok(function() expression.eval(5 * d, S) end)
    equal(T, "5*(3 + (5*c)^2)", {5 * d, S, "eval"})
  end

  -- references to functions
  do
    local f, x, y = rima.R"f, x, y"
    local S = rima.scope.new{ x = 2, f = rima.F({y}, y + 5) }
    T:check_equal(rima.E(f(x), S), 7)
  end

  -- Tagged expressions
  do
    local x, y = rima.R"x, y"
    local e = x + y
    expression.tag(e, { check = 1 })
    T:check_equal(expression.tags(e).check, 1)
    T:check_equal(expression.tags(rima.E(e, { x=1 })).check, 1)
    T:check_equal(expression.tags(rima.E(e, { y=2 })).check, 1)
    T:expect_ok(function() local a = expression.tags(rima.E(e, { x=1, y=2 })).check end)
    T:check_equal(expression.tags(rima.E(e, { x=1, y=2 })).check, nil)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

