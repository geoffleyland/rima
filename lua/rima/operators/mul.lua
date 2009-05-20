-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local math, table = require("math"), require("table")
local error, unpack = error, unpack
local ipairs, pairs = ipairs, pairs

local rima = require("rima")
local proxy = require("rima.proxy")
local tests = require("rima.tests")
local types = require("rima.types")
local operators = require("rima.operators")
local expression = rima.expression

module(...)

-- Multiplication --------------------------------------------------------------

local mul = rima.object:new(_M, "mul")
mul.precedence = 3


-- Argument Checking -----------------------------------------------------------

function mul:check(args)
  for i, a in ipairs(args) do
    if not expression.result_type_match(a[2], types.number_t) then
      error(("argument #d to mul (%s) is not in %s"):
        format(i, rima.tostring(a[2]), rima.tostring(types.number_t)), 0)
    end
  end
end

function mul:result_type(args)
  return types.number_t
end


-- String Representation -------------------------------------------------------

function mul:dump(args)
  return "*("..
    table.concat(rima.imap(
      function(a) return expression.dump(a[2]).."^"..rima.tostring(a[1]) end, args), ", ")..
    ")"
end

function mul:_tostring(args)
  local s = ""
  for i, a in ipairs(args) do
    local c, e = a[1], a[2]
    
    -- If it's the first argument and it's 1/something, put a "1/" out front
    if i == 1 then
      if c < 0 then
        s = "1/"
      end
    else
      s = s..((c < 0 and "/") or "*")
    end
    
    -- If the constant's not 1 then we need to parenthise (almost) like an exponentiation
    s = s..expression.parenthise(e, (c == 1 and 3) or 2)

    -- If the constant's not 1, write the constant
    local ac = math.abs(c)
    if ac ~= 1 then
      s = s.."^"..rima.tostring(ac)
    end
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

function mul:eval(S, raw_args)
  -- Multiply all the arguments, keeping track of the product of any exponents,
  -- and of all remaining unresolved terms
  -- If any subexpressions are products, we dive into them, if any are
  -- sums with one term we pull it up and if any are pows, we try to hoist out
  -- the constant and see if what's left is a product.

  -- evaluate all arguments
  local args = {} 
  for i, a in ipairs(raw_args) do
    args[i] = { a[1], expression.eval(a[2], S) }
  end

  local coeff, terms = 1, {}
  
  local function add_term(exp, e)
    local s = rima.tostring(e)
    local t = terms[s]
    if t then
      t.exponent = t.exponent + exp
    else
      terms[s] = { exponent=exp, expression=e }
    end
  end

  -- Run through all the terms in a product
  local function prod(args, exponent)
    exponent = exponent or 1
    for _, a in ipairs(args) do
      local exp, e = exponent * a[1], a[2]

      -- Simplify a single term
      local function simplify(exp, e)
        e = proxy.O(e)
        if type(e) == "number" then             -- if the term evaluated to a number, then multiply the coefficient by it
          coeff = coeff * math.pow(e, exp)
        elseif e.op == mul then                 -- if the term is another product, hoist its terms
          prod(e, exp)
        elseif e.op == operators.add and        -- if the term is a sum with a single term, hoist it
               #e == 1 then
          coeff = coeff * math.pow(e[1][1], exp)
          simplify(exp, e[1][2])
        elseif e.op == operators.pow and        -- if the term is an exponentiation to a constant power, hoist it
          type(e[2]) == "number" then
          simplify(exp * e[2], e[1])
        else                                    -- if there's nothing else to do, add the term
          add_term(exp, e)
        end
      end
      simplify(exp, e)

    end
  end
  prod(args)

  -- sort the terms alphabetically, so that when we group by a string representation,
  -- like terms look alike
  local ordered_terms = {}
  for name, t in pairs(terms) do
    if t.exponent ~= 0 then
      ordered_terms[#ordered_terms+1] = { name=name, exponent=t.exponent, expression=t.expression }
    end
  end
  table.sort(ordered_terms, function(a, b) return a.name < b.name end)

  if coeff == 0 then
    return 0
  elseif not ordered_terms[1] then              -- if there's no terms, we're just a constant
    return coeff
  elseif coeff == 1 and                         -- if the coefficient is one, and there's one term without an exponent,
         #ordered_terms == 1 and                -- we're the identity, so return the term
         ordered_terms[1].exponent == 1 then
    return ordered_terms[1].expression
  else                                          -- return the constant and the terms
    local new_args = {}
    if coeff ~= 1 then new_args[1] = {1, coeff} end
    for i, t in ipairs(ordered_terms) do
      new_args[#new_args+1] = { t.exponent, t.expression }
    end
    return expression:new(mul, unpack(new_args))
  end
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(isa(mul:new(), mul), "isa(mul:new(), mul)")
  T:equal_strings(type(mul:new()), "mul", "type(mul:new()) == 'mul'")

--  T:expect_ok(function() mul:check({}) end)
--  T:expect_ok(function() mul:check({{1, 2}}) end) 

  T:equal_strings(mul:dump({{1, 1}}), "*(number(1)^1)")
  T:equal_strings(mul:_tostring({{1, 1}}), "1")
  T:equal_strings(mul:dump({{1, 2}, {3, 4}}), "*(number(2)^1, number(4)^3)")
  T:equal_strings(mul:_tostring({{1, 2}, {3, 4}}), "2*4^3")
  T:equal_strings(mul:_tostring({{-1, 2}, {3, 4}}), "1/2*4^3")
  T:equal_strings(mul:_tostring({{-1, 2}, {-3, 4}}), "1/2/4^3")

  local S = rima.scope.new()
  T:equal_strings(mul:eval(S, {{1, 2}}), 2)
  T:equal_strings(mul:eval(S, {{1, 2}, {3, 4}}), 128)
  T:equal_strings(mul:eval(S, {{2, 2}, {1, 4}, {1, 6}}), 96)
  T:equal_strings(mul:eval(S, {{2, 2}, {1, 4}, {-1, 6}}), 8/3)
  T:equal_strings(mul:eval(S, {{2, 2}, {1, 4}, {1, -6}}), -96)

  local a, b = rima.R"a,b"
  rima.scope.set(S, {a = 5, b = rima.positive()})
  T:equal_strings(mul:dump({{1, a}}), "*(ref(a)^1)")
  T:equal_strings(mul:eval(S, {{1, a}}), 5)
  T:equal_strings(mul:eval(S, {{1, a}, {2, a}}), 125)

  T:equal_strings(2 * (3 * b), "2*3*b")
  T:equal_strings(2 / (3 * b), "2/(3*b)")

  T:equal_strings(expression.eval(b / b, S), 1)
  T:equal_strings(expression.eval(b * b, S), "b^2")
  T:equal_strings(expression.eval(2 * (3 * b), S), "6*b")
  T:equal_strings(expression.eval(2 / (3 * b), S), "0.6667/b")

  T:equal_strings(expression.eval(2 * (3 * a), S), 30)
  T:equal_strings(expression.eval(2 / (3 * a), S), 2/15)

  T:equal_strings(expression.dump(mul:eval(S, {{2, b}})), "*(ref(b)^2)")
  T:equal_strings(expression.dump(mul:eval(S, {{1, b}})), "ref(b)", "checking we simplify identity")
  T:equal_strings(expression.dump(expression.eval(1 * b, S)), "ref(b)", "checking we simplify identity")
  T:equal_strings(expression.dump(expression.eval(2 * b / 2, S)), "ref(b)", "checking we simplify identity")

  T:equal_strings(mul:eval(S, {{0, S.b}}), 1, "checking we simplify 0")
  T:equal_strings(expression.eval(0 * S.b, S), 0, "checking we simplify 0")

  -- Tests including add and pow are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

