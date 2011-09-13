-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local ipairs, require =
      ipairs, require

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local element = require("rima.sets.element")

module(...)

local expression = require("rima.expression")
local add_mul = require("rima.operators.add_mul")
local add = require("rima.operators.add")


-- Multiplication --------------------------------------------------------------

local mul = expression:new_type(_M, "mul")
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
local function simplify(new_terms, term_map, exponent, e, id, sort)
  local coeff, changed = 1
  if core.arithmetic(e) then                    -- if the term evaluated to a number, then multiply the coefficient by it
    -- If the exponent's not one, that's a change.
    -- If the expression is one, then we're going to remove it and that's a change
    -- If this constant isn't the first term we've seen, then it'll move to the front and that's a change
    if exponent ~= 1 or e == 1 or new_terms[1] then changed = true end
    coeff = e ^ exponent
  else
    local ti = object.typeinfo(e)
    local terms = proxy.O(e)
    if ti.mul then                              -- if the term is another product, hoist its terms
      _, coeff = product(new_terms, term_map, exponent, terms)
      changed = true
    elseif ti.add and #terms == 1 then          -- if the term is a sum with a single term, hoist it
      local t1 = terms[1]
      coeff = t1[1] ^ exponent
      local _, c2 = simplify(new_terms, term_map, exponent, t1[2], t1.id, t1.sort)
      coeff = coeff * c2
      changed = true
    elseif ti.pow and core.arithmetic(terms[2]) then
      -- if the term is an exponentiation to a constant power, hoist it
      _, coeff = simplify(new_terms, term_map, exponent * terms[2], terms[1])
      changed = true
    else                                          -- if there's nothing else to do, add the term
      changed = add_mul.add_term(new_terms, term_map, exponent, element.extract(e), id, sort)
    end
  end
  return changed, coeff
end


-- Run through all the terms in a product
function product(new_terms, term_map, exponent, terms)
  local coeff, changed
  for i = 1, #terms do
    local t = terms[i]
    local ch2, c2 = simplify(new_terms, term_map, exponent * t[1], t[2], t.id, t.sort)
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

  local ordered_terms, term_map = {}, {}
  local simplify_changed, coeff = product(ordered_terms, term_map, 1, terms)

  if coeff == 0 then return 0 end

  if coeff ~= 1 then
    ordered_terms[#ordered_terms+1] = { 1, coeff, id=" ", sort=" " }
  end

  local term_count = add_mul.sort_terms(ordered_terms)

  if term_count == 0 then return coeff end

  if coeff ~= 1 and term_count == 1 then        -- if there's no terms, we're just a constant
    return coeff

  elseif coeff == 1 and                         -- if the coefficient is one
         term_count == 1 and                    -- and there's one term
         ordered_terms[1][1] == 1 then          -- without an exponent
    return ordered_terms[1][2]                  -- then we're the identity, so return the expression

  elseif not evaluate_changed and not simplify_changed then
    -- if nothing changed, return the original object
    return self

  else                                          -- return the constant and the terms
    return expression:new_table(mul, ordered_terms)
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

mul.__list_variables = add_mul.list_variables


-- EOF -------------------------------------------------------------------------

