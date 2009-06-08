-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local error, pcall = error, pcall
local ipairs, pairs, rawget, old_type = ipairs, pairs, rawget, type
local setmetatable = setmetatable

local rima = require("rima")
local object = require("rima.object")
local proxy = require("rima.proxy")
local tests = require("rima.tests")
local types = require("rima.types")
local operators = require("rima.operators")
local scope = require("rima.scope")
require("rima.private")
local ref = rima.ref

module(...)

-- Constructor -----------------------------------------------------------------

local expression = object:new(_M, "expression")
expression_proxy_mt = setmetatable({}, expression)

function expression:new(x, ...)
  local e = {...}
  e.op = x

--  e:check()
  return proxy:new(object.new(self, e), expression_proxy_mt)
end

function expression:new_table(x, t)
  local e = { op=x }
  for i, a in ipairs(t) do e[i] = a end

--  e:check()
  return proxy:new(object.new(self, e), expression_proxy_mt)
end


-- Argument Checking -----------------------------------------------------------

--[[
function expression:check()
  local m = old_type(self.op) == "table" and self.op.check
  if m then
    return m(self.op, self.args)
  else
    return true
  end
end
--]]

-- Result Types ----------------------------------------------------------------

--[[
function expression.result_type_match(a, t)
  local r = result_type(a)
  return r:includes(t) or t:includes(r)
end

function expression.result_type(a)
  if old_type(a) == "table" then
    local op, args = a.op, a.args
    if op and old_type(args) == "table" then    -- this is an expression
      local m = old_type(op) == "table" and op.result_type
      if m then                                 -- the operator can handle itself
        return m(op, args)
      elseif #args == 0 then                    -- looks like a literal
        return type(op) == "number" and rima.free() or types.undefined_t
      else                                      -- some kind of call
        error(("unable to determine the result type of '%s': the operator doesn't take arguments"):format(rima.tostring(a)), 0)
      end
    else                                        -- this is some other object.  Can it handle itself?
      local m = a.result_type
      if m then return m(a) end
    end
  end
  return type(op) == "number" and rima.free() or types.undefined_t
end
--]]

-- We want to avoid trying to index non-tables and directly indexing
-- references (which will lie and say they have everything)
local function get_field(e, f)
  return old_type(e) == "table" and e[f]
end

function expression.operator(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  return type(op and op or e)
end


-- String representation -------------------------------------------------------

function expression.dump(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "dump")
    if m then                                 -- the operator can handle itself
      return m(op, e)
    else
      return object.type(op).."("..table.concat(rima.imap(dump, e), ", ")..")"
    end
  else                                        -- it's a literal
    local m = get_field(e, "dump")
    return m and m(e) or object.type(e).."("..rima.tostring(e)..")"
  end
end


function expression.__tostring(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "_tostring")
    if m then                                 -- the operator can handle itself
      return m(op, e)
    else
      return object.type(op).."(".. table.concat(rima.imap(rima.tostring, e), ", ")..")"
    end
  else                                        -- it's a literal
    local m = get_field(e, "_tostring")
    return m and m(e) or rima.tostring(e)
  end
end
expression_proxy_mt.__tostring = expression.__tostring

function expression.parenthise(e, parent_precedence)
  e = proxy.O(e)
  parent_precedence = parent_precedence or 1
  local s = rima.tostring(e)
  local op = get_field(e, "op")
  if op then                                    -- this is an expression
    local precedence = get_field(op, "precedence") or 1
    if precedence > parent_precedence then
      s = "("..s..")"
    end
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

function expression.eval(e, S)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "eval")
    if m then                                 -- the operator can handle itself
      return m(op, S, e)
    else
      error(("unable to evaluate '%s': the operator can't be evaluated"):format(rima.tostring(e)), 0)
    end
  else                                        -- it's a literal
    local m = get_field(e, "eval")
    return m and m(e, S) or e
  end
end


-- Getting a linear form -------------------------------------------------------

function expression._linearise(l, S)
  l = proxy.O(l)
  local constant, terms = 0, {}
  local fail = false

  local function add_variable(n, v, coeff)
    local s = rima.tostring(n)
    if terms[s] then
      error(("the reference '%s' appears more than once"):format(s), 0)
    end
    v = proxy.O(v)
    local t = scope.lookup(S, v.name, v.scope)
    if not isa(t, rima.types.number_t) then
      error(("expecting a number type for '%s', got '%s'"):format(s, t:describe(s)), 0)
    end
    terms[s] = { variable=v, coeff=coeff, lower=t.lower, upper=t.upper, integer=t.integer }
  end

  if type(l) == "number" then
    constant = l
  elseif type(l) == "ref" then
    add_variable(l, l, 1)
  elseif l.op == operators.add then
    for i, a in ipairs(l) do
      a = proxy.O(a)
      local c, x = a[1], a[2]
      if type(x) == "number" then
        if i ~= 1 then
          error(("term %d is constant (%s).  Only the first term should be constant"):
            format(i, rima.tostring(x)), 0)
        end
        if constant ~= 0 then
          error(("term %d is constant (%s), and so is an earlier term.  There can only be one constant in the expression"):
            format(i, rima.tostring(x)), 0)
        end
        constant = c * x
      elseif type(x) == "ref" then
        add_variable(x, x, c)
      else
        error(("term %d (%s) is not linear"):format(i, rima.tostring(x)), 0)
      end
    end
  else
    error("the expression does not evaluate to a sum of terms", 0)
  end
  
  return constant, terms
end


function expression.linearise(e, S)
  local l = eval(0 + e, S)
  local status, constant, terms = pcall(function() return expression._linearise(l, S) end)
  if not status then
    error(("error while linearising '%s':\n  linear form: %s\n  error:\n    %s"):
      format(rima.tostring(e), rima.tostring(l), constant:gsub("\n", "\n    ")), 0)
  else
    return constant, terms
  end
end


-- Overloaded operators --------------------------------------------------------

function expression.__add(a, b)
  return expression:new(operators.add, {1, a}, {1, b})
end

function expression.__sub(a, b)
  return expression:new(operators.add, {1, a}, {-1, b})
end

function expression.__unm(a)
  return expression:new(operators.add, {-1, a})
end

function expression.__mul(a, b, c)
  return expression:new(operators.mul, {1, a}, {1, b})
end

function expression.__div(a, b)
  return expression:new(operators.mul, {1, a}, {-1, b})
end

function expression.__pow(a, b)
  return expression:new(operators.pow, a, b)
end

function expression.__call(...)
  return expression:new(operators.call, ...)
end

expression_proxy_mt.__add = expression.__add
expression_proxy_mt.__sub = expression.__sub
expression_proxy_mt.__unm = expression.__unm
expression_proxy_mt.__mul = expression.__mul
expression_proxy_mt.__div = expression.__div
expression_proxy_mt.__pow = expression.__pow
expression_proxy_mt.__call = expression.__call

--[[
function expression_proxy_mt.__index(...)
  return expression:new(rima.operators.index, ...)
end
--]]

-- Test ------------------------------------------------------------------------

local function equal(T, expected, got)
  local function prep(z)
    if type(z) == "table" then
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
  T:equal_strings(g, e, nil, 1)
end

function test1(show_passes)
  local T = tests.series:new(_M, show_passes)

--  local o = operators.operator:new()

--  T:expect_error(function() expression:new({}) end,
--    "rima.expression:new: expecting an operator, variable or number for 'operator', got 'table'")
--  T:expect_error(function() expression:new("a") end,
--    "expecting an operator, variable or number for 'operator', got 'string'")
--  T:expect_ok(function() expression:new(o) end)
--  T:test(isa(expression:new(o), expression), "isa(expression:new(), expression)")
--  T:equal_strings(type(expression:new(o)), "expression", "type(expression:new() == 'expression'")

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

  return T:close()
end


function expression.test2(show_passes)
  local T = tests.series:new(_M, show_passes)

  -- tests with add, mul and pow
  do
    local a, b = rima.R"a, b"
    local S = rima.scope.create{ ["a,b"]=rima.free() }
    equal(T, "+(1*number(3), 4*ref(a))", {3 + 4 * a, S, "eval", "dump"})
    equal(T, "3 + 4*a", {3 + 4 * a, S, "eval"})
    equal(T, "+(1*number(3), 4**(ref(a)^1, ref(b)^1))", {3 + 4 * a * b, S, "eval", "dump"})
    equal(T, "3 + 4*a*b", {3 + 4 * a * b, S, "eval"})

    equal(T, "*(number(6)^1, ref(a)^1)", {3 * (a + a), S, "eval", "dump"})
    equal(T, "6*a", {3 * (a + a), S, "eval"})
    equal(T, "+(1*number(1), 6*ref(a))", {1 + 3 * (a + a), S, "eval", "dump"})
    equal(T, "1 + 6*a", {1 + 3 * (a + a), S, "eval"})

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

  T:run(test_linearisation)

  return T:close()
end


function expression:test_linearisation(show_passes)
  local T = tests.series:new(_M, show_passes)

  local a, b = rima.R"a, b"
  local S = rima.scope.create{ ["a,b"] = rima.free() }

  T:expect_ok(function() expression.linearise(a, S) end)
  T:expect_ok(function() expression.linearise(1 + a, S) end)
  T:expect_error(function() expression.linearise(1 + (3 + a^2), S) end,
    "error while linearising '1 %+ 3 %+ a^2'.-linear form: 4 %+ a^2.-term 2 %(a^2%) is not linear")

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

  check_linear(1 + a*5, 1, {a=5}, S)
  check_nonlinear(1 + a*b, S)
  check_linear(1 + a*b, 1, {a=5}, scope.spawn(S, {b=5}))
  check_linear(1 + a[2]*5, 1, {["a[2]"]=5}, S)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

