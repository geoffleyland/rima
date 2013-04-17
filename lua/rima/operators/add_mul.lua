-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local lib = require("rima.lib")
local core = require("rima.core")

local add_mul = {}


------------------------------------------------------------------------------

function add_mul.evaluate_terms(terms, ...)
  local new_terms
  local term_count = #terms
  for i = 1, term_count do
    local t = terms[i]
    local et2 = core.eval(t[2], ...)
    if et2 ~= t[2] then
      new_terms = new_terms or {}
      new_terms[i] = { t[1], et2 }
    end
  end
  if new_terms then
    for i = 1, term_count do
      if not new_terms[i] then
        new_terms[i] = terms[i]
      end
    end
  end

  return new_terms
end


------------------------------------------------------------------------------

local SCOPE_FORMAT = { scopes = true }

function add_mul.add_term(terms, term_map, coeff, e, id, sort)
  local id = id or lib.repr(e, SCOPE_FORMAT)
  local t = term_map[id]
  if coeff == 0 then
    return true                                 -- Do nothing, but either way we removed a term
  end
  if t then
    t[1] = t[1] + coeff
    return true
  else
    local new_term = { coeff, e, id=id, sort=sort or lib.repr(e) }
    terms[#terms+1] = new_term
    term_map[id] = new_term
  end
end


------------------------------------------------------------------------------

local function term_order(a, b)
  return a.sort < b.sort
end

function add_mul.sort_terms(terms)
  -- sort the new terms alphabetically, so that when we group by a string
  -- representation, like terms look alike
  local term_count = 0
  local prev, need_sort
  for i = 1, #terms do
    local t = terms[i]
    terms[i] = nil
    if t[1] ~= 0 then
      if t[2] == " " then
        t[1], t[2] = 1, t[1]
      end
      term_count = term_count + 1
      terms[term_count] = t
      if prev and prev.sort > t.sort then
        need_sort = true
      end
      prev = t
    end
  end
  if need_sort then
    table.sort(terms, term_order)
  end
  return term_count, need_sort
end


------------------------------------------------------------------------------

function add_mul.extract_constant(e)
  local constant = e[1][2]

  if type(constant) == "number" then
    local term_count = #e

    if term_count == 1 then
      return constant                           -- There was just a constant
    end

    if term_count == 2 and e[2][1] == 1 then
      -- there's a constant and only one other argument with a
      -- coefficient/exponent of 1 - hoist the other argument
      return constant, e[2][2]
    end
            
    local new_terms = {}
    for i = 2, term_count do
      new_terms[i-1] = e[i]
    end
    return constant, getmetatable(e):new(new_terms)
  end
end


------------------------------------------------------------------------------

function add_mul.list_variables(op, S, list)
  for i = 1, #op do
    core.list_variables(op[i][2], S, list)
  end
end


------------------------------------------------------------------------------

return add_mul

------------------------------------------------------------------------------

