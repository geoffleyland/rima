-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")
local add_mul = require("rima.operators.add_mul")
local ops = require("rima.operations")


------------------------------------------------------------------------------

local add = operator:new_class({}, "add")
add.precedence = 5


------------------------------------------------------------------------------

function add:__repr(format)
  local ff = format.format

  if ff == "dump" then
    return "+("..
      lib.concat(self, ", ",
        function(t) return lib.simple_repr(t[1], format).."*"..lib.repr(t[2], format) end)..
      ")"
  end

  local s = ""
  for i, t in ipairs(self) do
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
    e = ac == 1 and e or core.eval(ops.mul(ac, e))

    -- If the constant's not 1 then we need to parenthise (almost) like a multiplication
    s = s..core.parenthise(e, format, (c == 1 and 5) or 4)
  end
  return s
end


------------------------------------------------------------------------------

local sum

-- Simplify a single term
local function _simplify(new_terms, term_map, coeff, e, id, sort)
  local changed
  if core.arithmetic(e) then                    -- if the term evaluated to a number, then add it to the constant
    -- if the coeff isn't 1, it's a change.
    -- If this constant isn't the first term we've seen, then we're going to put it first, and that's a change
    if coeff ~= 1 or new_terms[1] then changed = true end
    if add_mul.add_term(new_terms, term_map, coeff * e, " ", " ", " ") then
                                                -- use space because it has a low sort order
      changed = true
    end
  else
    local ti = object.typeinfo(e)
    if ti.add then                              -- if the term is another sum, hoist its terms
      sum(new_terms, term_map, coeff, e)
      changed = true
    elseif ti.mul then                          -- if the term is a multiplication, try to hoist any constant
      local new_c, new_e = add_mul.extract_constant(e)
      if new_c then                             -- if we did hoist a constant, re-simplify the resulting expression
        if new_e then
          _simplify(new_terms, term_map, coeff * new_c, new_e)
        else
          add_mul.add_term(new_terms, term_map, coeff * new_c, " ", " ", " ")
        end
        changed = true
      else                                      -- otherwise just add it
        local e2 = lib.convert(e, "extract")
        changed = add_mul.add_term(new_terms, term_map, coeff, e2, id, sort) or e2 ~= e
      end
    else                                        -- if there's nothing else to do, add the term
      local e2 = lib.convert(e, "extract")
      changed = add_mul.add_term(new_terms, term_map, coeff, e2, id, sort) or e2 ~= e
    end
  end
  return changed
end


-- Run through all the terms in a sum
function sum(new_terms, term_map, coeff, terms)
  local changed
  for i = 1, #terms do
    local t = terms[i]
    if _simplify(new_terms, term_map, coeff * t[1], t[2], t.id, t.sort) then
      changed = true
    end
  end
  return changed
end


function add:simplify()
  local ordered_terms, term_map = {}, {}
  local simplify_changed = sum(ordered_terms, term_map, 1, self)

  local term_count, sort_changed = add_mul.sort_terms(ordered_terms)

  if term_count == 0 then return 0 end

  local constant_term = ordered_terms[1]
  local constant = constant_term and constant_term.id == " " and constant_term[2]
  if constant == 0 then constant = nil end

  if constant and term_count == 1 then          -- if there's no terms, we're just a constant
    return constant

  elseif not constant and                       -- if there's no constant
         term_count == 1 and                    -- and one term
         ordered_terms[1][1] == 1 then          -- without a coefficent,
    return ordered_terms[1][2]                  -- then we're the identity, so return the expression
  end

  if simplify_changed or sort_changed then
    return add:new(ordered_terms)
  end

  return self
end


function add:__eval(...)
  local terms = add_mul.evaluate_terms(self, ...)
  if not terms then return self end
  return add:new(terms)
end


------------------------------------------------------------------------------

function add:__diff(v)
  local diff_terms = {}
  for _, t in ipairs(self) do
    local c, e = t[1], t[2]
    local dedv = core.diff(e, v)
    if dedv ~= 0 then
      diff_terms[#diff_terms+1] = {c, dedv}
    end
  end
  
  return add:new(diff_terms)
end


------------------------------------------------------------------------------

add.__list_variables = add_mul.list_variables


------------------------------------------------------------------------------

return add

------------------------------------------------------------------------------

