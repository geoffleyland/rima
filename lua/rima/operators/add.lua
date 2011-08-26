-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local ipairs, next, require =
      ipairs, next, require

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local element = require("rima.sets.element")

module(...)

local expression = require("rima.expression")
local add_mul = require("rima.operators.add_mul")


-- Addition --------------------------------------------------------------------

local add = expression:new_type(_M, "add")
add.precedence = 5


-- String Representation -------------------------------------------------------

function add:__repr(format)
  local terms = proxy.O(self)
  if format.format == "dump" then
    return "+("..
      lib.concat(terms, ", ",
        function(t) return lib.simple_repr(t[1], format).."*"..lib.repr(t[2], format) end)..
      ")"
  end

  local s = ""
  for i, t in ipairs(terms) do
    local c, e = t[1], t[2]
    
    -- If it's the first argument and it's negative, put a "-" out front
    if i == 1 then
      if c < 0 then
        s = "-"
      end
    else
      s = s..((c < 0 and " - ") or " + ")
    end

    -- If the coefficient's not 1, make a sub-expression with a multiplication
    local ac = math.abs(c)
    e = ac == 1 and e or core.eval(ac * e)

    -- If the constant's not 1 then we need to parenthise (almost) like a multiplication
    s = s..core.parenthise(e, format, (c == 1 and 5) or 4)
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

local sum

-- Simplify a single term
local function simplify(term_map, coeff, e)
  local changed
  local ti = object.typeinfo(e)
  if core.arithmetic(e) then                    -- if the term evaluated to a number, then add it to the constant
    -- if the coeff isn't 1, it's a change.
    -- If this constant isn't the first term we've seen, then we're going to put it first, and that's a change
    if coeff ~= 1 or next(term_map) then changed = true end
    if add_mul.add_term(term_map, coeff * e, " ") then
                                                -- use space because it has a low sort order
      changed = true
    end
  elseif ti.add then                            -- if the term is another sum, hoist its terms
    sum(term_map, coeff, proxy.O(e))
    changed = true
  elseif ti.mul then                            -- if the term is a multiplication, try to hoist any constant
    local new_c, new_e = add_mul.extract_constant(e)
    if new_c then                               -- if we did hoist a constant, re-simplify the resulting expression
      if new_e then
      simplify(term_map, coeff * new_c, new_e)
      else
        add_mul.add_term(term_map, coeff * new_c, " ")
      end
      changed = true
    else                                        -- otherwise just add it
      changed = add_mul.add_term(term_map, coeff, element.extract(e))
    end
  else                                          -- if there's nothing else to do, add the term
    changed = add_mul.add_term(term_map, coeff, element.extract(e))
  end
  return changed
end


-- Run through all the terms in a sum
function sum(term_map, coeff, terms)
  local changed
  for _, t in ipairs(terms) do
    if simplify(term_map, coeff * t[1], t[2]) then
      changed = true
    end
  end
  return changed
end


function add:__eval(S)
  -- Sum all the arguments, keeping track of the sum of any constants,
  -- and of all remaining unresolved terms.
  -- If any subexpressions are sums, we dive into them, and if any are
  -- products, we try to hoist out the constant and see if what's left is a
  -- sum.
  local terms, evaluate_changed = add_mul.evaluate_terms(proxy.O(self), S)

  local term_map = {}
  local simplify_changed = sum(term_map, 1, terms)

  local ordered_terms, term_count = add_mul.sort_terms(term_map)

  if term_count == 0 then return 0 end

  local constant_term = term_map[" "]
  local constant = constant_term and constant_term.coeff
  if constant == 0 then constant = nil end

  if constant and term_count == 1 then          -- if there's no terms, we're just a constant
    return constant

  elseif not constant and                       -- if there's no constant
         term_count == 1 and                    -- and one term
         ordered_terms[1][1] == 1 then          -- without a coefficent,
    return ordered_terms[1][2]                  -- then we're the identity, so return the expression

  elseif not evaluate_changed and not simplify_changed then
    -- if nothing changed, return the original object
    return self

  else                                          -- return the constant and the terms
    return expression:new_table(add, ordered_terms)
  end
end


-- Automatic differentiation ---------------------------------------------------

function add:__diff(v)
  local diff_terms = {}
  for _, t in ipairs(proxy.O(self)) do
    local c, e = t[1], t[2]
    local dedv = core.diff(e, v)
    if dedv ~= 0 then
      diff_terms[#diff_terms+1] = {c, dedv}
    end
  end
  
  return expression:new_table(add, diff_terms)
end


-- Introspection? --------------------------------------------------------------

function add:__list_variables(S, list)
  for _, t in ipairs(proxy.O(self)) do
    core.list_variables(t[2], S, list)
  end
end


-- EOF -------------------------------------------------------------------------

