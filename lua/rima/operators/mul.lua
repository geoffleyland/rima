-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local math, table = require("math"), require("table")
local error, require, unpack = error, require, unpack
local ipairs, pairs = ipairs, pairs

local object = require("rima.object")
local proxy = require("rima.proxy")
require("rima.private")
local rima = rima

module(...)

local add = require("rima.operators.add")
local pow = require("rima.operators.pow")
local expression = require("rima.expression")

-- Multiplication --------------------------------------------------------------

local mul = object:new(_M, "mul")
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
    rima.concat(args, ", ",
      function(a) return expression.dump(a[2]).."^"..rima.tostring(a[1]) end)..
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
  return simplify(args)
end

function mul.simplify(args)
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
        local E = proxy.O(e)
        if type(e) == "number" then             -- if the term evaluated to a number, then multiply the coefficient by it
          coeff = coeff * math.pow(e, exp)
        elseif E.op == mul then                 -- if the term is another product, hoist its terms
          prod(E, exp)
        elseif E.op == add and                  -- if the term is a sum with a single term, hoist it
               #E == 1 then
          coeff = coeff * math.pow(E[1][1], exp)
          simplify(exp, E[1][2])
        elseif E.op == pow and                  -- if the term is an exponentiation to a constant power, hoist it
          type(E[2]) == "number" then
          simplify(exp * E[2], E[1])
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


-- EOF -------------------------------------------------------------------------

