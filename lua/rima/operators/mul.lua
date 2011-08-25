-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local error, ipairs, require, type =
      error, ipairs, require, type

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local add_mul = require("rima.operators.add_mul")
local expression = require("rima.expression")
local element = require("rima.sets.element")

module(...)

local add = require("rima.operators.add")

-- Multiplication --------------------------------------------------------------

local mul = object:new_class(_M, "mul")
mul.precedence = 3


-- String Representation -------------------------------------------------------

function mul:__repr(format)
  local terms = proxy.O(self)
  local ff = format.format

  if ff == "dump" then
    return "*("..
      lib.concat(terms, ", ",
        function(t) return lib.repr(t[2], format).."^"..lib.simple_repr(t[1], format) end)..
      ")"
  end

  local s = ""
  for i, t in ipairs(terms) do
    local c, e = t[1], t[2]
    
    -- If it's the first argument and it's 1/something, put a "1/" out front
    if i == 1 then
      if c < 0 then
        s = "1/"
      end
    else
      s = s..((c < 0 and "/") or (ff == "latex" and " " or "*"))
    end
    
    -- If the constant's not 1 then we need to parenthise (almost) like an exponentiation
    s = s..core.parenthise(e, format, (c == 1 and 3) or 2)

    -- If the constant's not 1, write the constant
    local ac = math.abs(c)
    if ac ~= 1 then
      local acr = lib.repr(ac, format)
      if ff == "latex" then
        s = "{"..s.."}^{"..acr.."}"
      else
        s = s.."^"..acr
      end
    end
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

local product

-- Simplify a single term
local function simplify(term_map, exponent, e)
  local coeff, changed = 1
  local ti = object.typeinfo(e)
  if core.arithmetic(e) then              -- if the term evaluated to a number, then multiply the coefficient by it
    changed = exponent ~= 1 or e == 1
    coeff = e ^ exponent
  else
    local terms = proxy.O(e)
    if ti.mul then                        -- if the term is another product, hoist its terms
      _, coeff = product(term_map, exponent, terms)
      changed = true
    elseif ti.add and #terms == 1 then    -- if the term is a sum with a single term, hoist it
      coeff = terms[1][1] ^ exponent
      local _, c2 = simplify(term_map, exponent, terms[1][2])
      coeff = coeff * c2
      changed = true
    elseif ti.pow and type(terms[2]) == "number" then
      -- if the term is an exponentiation to a constant power, hoist it
      _, coeff = simplify(term_map, exponent * terms[2], terms[1])
      changed = true
    else                                    -- if there's nothing else to do, add the term
      changed = add_mul.add_term(term_map, exponent, element.extract(e))
    end
  end
  return changed, coeff
end


 -- Run through all the terms in a product
 function product(term_map, exponent, terms)
  local coeff, changed
  for _, t in ipairs(terms) do
    local ch2, c2 = simplify(term_map, exponent * t[1], t[2])
    if ch2 or (coeff and c2 ~= 1) then
      changed = true
    end
    coeff = (coeff or 1) * c2
  end
  return changed, coeff or 1
end


function mul:__eval(S)
  -- Multiply all the arguments, keeping track of the product of any exponents,
  -- and of all remaining unresolved terms
  -- If any subexpressions are products, we dive into them, if any are
  -- sums with one term we pull it up and if any are pows, we try to hoist out
  -- the constant and see if what's left is a product.
  local terms, evaluate_changed = add_mul.evaluate_terms(proxy.O(self), S)

  local term_map = {}
  local simplify_changed, coeff = product(term_map, 1, terms)

  if coeff == 0 then return 0 end

  if coeff ~= 1 then
    term_map[" "] = { name = " ", coeff=1, expression=coeff }
  end

  local ordered_terms, term_count = add_mul.sort_terms(term_map)

  if term_count == 0 then return coeff end

  if coeff ~= 1 and term_count == 1 then        -- if there's no terms, we're just a constant
    return coeff

  elseif coeff == 1 and                         -- if the coefficient is one, and there's one term without an exponent,
         term_count == 1 and                    -- we're the identity, so return the term
         ordered_terms[1].coeff == 1 then
    return ordered_terms[1].expression

  elseif not evaluate_changed and not simplify_changed then
    -- if nothing changed, return the original object
    return self

  else                                          -- return the constant and the terms
    local new_terms = {}
    for i, t in ipairs(ordered_terms) do
      new_terms[i] = { t.coeff, t.expression }
    end
    return expression:new_table(mul, new_terms)
  end
end


-- Automatic differentiation ---------------------------------------------------

function mul:__diff(v)
  local terms = proxy.O(self)
  local diff_terms = {}
  for i in ipairs(terms) do
    local t1 = {}
    for j, t2 in ipairs(terms) do
      local exponent, expression = t2[1], t2[2]
      if i == j then
        local d = core.diff(expression, v)
        if d == 0 then
          t1 = nil
          break
        else
          if d ~= 1 then
            t1[#t1+1] = {1, d}
          end
          if exponent ~= 1 then
            t1[#t1+1] = {exponent-1, expression}
            t1[#t1+1] = {1, exponent}
          end
        end
      else
        t1[#t1+1] = {exponent, expression}
      end
    end
    if t1 then
      diff_terms[#diff_terms+1] = {1, expression:new_table(mul, t1)}
    end
  end
  
  return expression:new_table(add, diff_terms)
end


-- Introspection? --------------------------------------------------------------

function mul:__list_variables(S, list)
  for _, t in ipairs(proxy.O(self)) do
    core.list_variables(t[2], S, list)
  end
end


-- EOF -------------------------------------------------------------------------

