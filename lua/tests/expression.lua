-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local pairs = pairs

local series = require("test.series")
local expression = require("rima.expression")
local scope = require("rima.scope")
local object = require("rima.object")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

local function equal(T, expected, got)
  local function prep(z)
    if object.type(z) == "table" then
      local e = z[1]
      for i = 3, #z do
        e = expression[z[i]](e, z[2])
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
  equal(T, "number(1)", {1, nil, "dump"})
  equal(T, 1, {1, S, "eval"})

  -- variables
  local a = rima.R"a"
  equal(T, "ref(a)", {a, nil, "dump"})
  T:expect_ok(function() rima.E(a, S) end)
  equal(T, "a", {a, S, "eval"})
  S.a = rima.free()
  equal(T, "a", {a, S, "eval"})
  S.a = 5
  equal(T, 5, {a, S, "eval"})

  -- dump and tostring
  T:check_equal(expression.dump(1), "number(1)")
  T:check_equal(expression.dump(expression:new(function() end, 1)), "function(number(1))")
  T:check_equal(expression.__tostring(1), "1")
  T:check_equal(expression:new(function() end, 1), "function(1)")

  -- eval
  T:expect_error(function() expression.eval(expression:new({}), {}) end,
    "unable to evaluate 'table%(%)': the operator can't be evaluated")

  -- tests with add, mul and pow
  do
    local a, b = rima.R"a, b"
    local S = rima.scope.create{ ["a,b"]=rima.free() }
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


    equal(T, "*(number(3)^1, ^(ref(a), number(2))^1)", {3 * a^2, nil, "dump"})
    equal(T, "*(number(3)^1, ref(a)^2)", {3 * a^2, S, "eval", "dump"})
    equal(T, "*(number(3)^1, +(1*number(1), 1*ref(a))^2)", {3 * (a+1)^2, S, "eval", "dump"})
  end

  -- tests with references to expressions
  do
    local a, b = rima.R"a,b"
    local S = rima.scope.create{ a = rima.free(), b = 3 * (a + 1)^2 }
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
    local S = rima.scope.create{ x = 2, f = rima.F({y}, y + 5) }
    T:check_equal(rima.E(f(x), S), 7)
  end

  -- linearisation
  local a, b, c = rima.R"a, b, c"
  local S = rima.scope.create{ ["a,b"] = rima.free(), c=rima.types.undefined_t:new() }

  T:expect_ok(function() expression.linearise(a, S) end)
  T:expect_ok(function() expression.linearise(1 + a, S) end)
  T:expect_error(function() expression.linearise(1 + (3 + a^2), S) end,
    "error while linearising '1 %+ 3 %+ a^2'.-linear form: 4 %+ a^2.-term 2 %(a^2%) is not linear")
  T:expect_error(function() expression.linearise(1 + c, S) end,
    "error while linearising '1 %+ c'.-linear form: 1 %+ c.-expecting a number type for 'c', got 'c undefined'")
  T:expect_error(function() expression.linearise(a * b, S) end,
    "error while linearising 'a%*b'.-linear form: a%*b.-the expression does not evaluate to a sum of terms")

  local function check_nonlinear(e, S)
    T:expect_error(function() expression.linearise(e, S) end, "error while linearising")
  end

  local function check_linear(e, expected_constant, expected_terms, S)
    local got_constant, got_terms = expression.linearise(e, S)
    for v, c in pairs(got_terms) do got_terms[v] = c.coeff end
    
    local pass = true
    if expected_constant ~= got_constant then
      pass = false
    else
      for k, v in pairs(expected_terms) do
        if got_terms[k] ~= v then
          pass = false
        end
      end
      for k, v in pairs(got_terms) do
        if expected_terms[k] ~= v then
          pass = false
        end
      end      
    end

    if not pass then
      local s = ""
      s = s..("error linearising %s:\n"):format(rima.tostring(e))
      s = s..("  Evaluated to %s\n"): format(rima.tostring(e:evaluate(S)))
      s = s..("  Constant: %.4g %s %.4g\n"):format(expected_constant,
        (expected_constant==got_constant and "==") or "~=", got_constant)
      local all = {}
      for k, v in pairs(expected_terms) do all[k] = true end
      for k, v in pairs(got_terms) do all[k] = true end
      local ordered = {}
      for k in pairs(all) do ordered[#ordered+1] = k end
      table.sort(ordered)
      for _, k in ipairs(ordered) do
        local a, b = expected_terms[k], got_terms[k]
        s = s..("  %s: %s %s %s\n"):format(k, rima.tostring(a), (a==b and "==") or "~=", rima.tostring(b))
      end
      T:test(false, s)
    else
      T:test(true)
    end
  end

  check_linear(1, 1, {}, S)
  check_linear(1 + a*5, 1, {a=5}, S)
  check_nonlinear(1 + a*b, S)
  check_linear(1 + a*b, 1, {a=5}, scope.spawn(S, {b=5}))
  check_linear(1 + a[2]*5, 1, {["a[2]"]=5}, S)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

