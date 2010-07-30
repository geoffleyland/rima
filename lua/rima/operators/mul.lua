-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local math, table = require("math"), require("table")
local error, require, unpack = error, require, unpack
local ipairs, pairs = ipairs, pairs
local getmetatable = getmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")

module(...)

local add = require("rima.operators.add")
local pow = require("rima.operators.pow")

-- Multiplication --------------------------------------------------------------

local mul = object:new(_M, "mul")
mul.precedence = 3


-- String Representation -------------------------------------------------------

function mul.__repr(args, format)
  args = proxy.O(args)
  if format and format.dump then
    return "*("..
      lib.concat(args, ", ",
        function(a) return lib.repr(a[2], format).."^"..lib.simple_repr(a[1], format) end)..
      ")"
  end

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
    s = s..core.parenthise(e, format, (c == 1 and 3) or 2)

    -- If the constant's not 1, write the constant
    local ac = math.abs(c)
    if ac ~= 1 then
      s = s.."^"..lib.repr(ac, format)
    end
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

function mul.__eval(args, S, eval)
  -- Multiply all the arguments, keeping track of the product of any exponents,
  -- and of all remaining unresolved terms
  -- If any subexpressions are products, we dive into them, if any are
  -- sums with one term we pull it up and if any are pows, we try to hoist out
  -- the constant and see if what's left is a product.
  args = proxy.O(args)

  -- evaluate or bind all arguments
  return simplify(lib.imap(function(a) return { a[1], eval(a[2], S) } end, args))
end

function mul.simplify(args)
  local coeff, terms = 1, {}
  
  local function add_term(exp, e)
    local n = lib.repr(e)
    local s = lib.repr(e, { scopes = true })
    local t = terms[s]
    if t then
      t.exponent = t.exponent + exp
    else
      terms[s] = { name=n, exponent=exp, expression=e }
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
        local mt = getmetatable(e)
        if core.defined(e) then                 -- if the term evaluated to a number, then multiply the coefficient by it
          coeff = coeff * e ^ exp
        elseif mt == mul then                   -- if the term is another product, hoist its terms
          prod(E, exp)
        elseif mt == add and                    -- if the term is a sum with a single term, hoist it
               #E == 1 then
          coeff = coeff * E[1][1] ^ exp
          simplify(exp, E[1][2])
        elseif mt == pow and                    -- if the term is an exponentiation to a constant power, hoist it
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
      ordered_terms[#ordered_terms+1] = { name=t.name, exponent=t.exponent, expression=t.expression }
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

