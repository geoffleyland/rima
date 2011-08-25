-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local ipairs = ipairs

local lib = require("rima.lib")
local core = require("rima.core")

module(...)


-- Evaluate all terms, and return the same object if nothing changed -----------

function evaluate_terms(terms, S)
  local new_terms
  for i, t in ipairs(terms) do
    local et2 = core.eval(t[2], S)
    if et2 ~= t[2] then
      new_terms = new_terms or {}
      new_terms[i] = { t[1], et2 }
    end
  end
  if new_terms then
    for i, t in ipairs(terms) do
      if not new_terms[i] then
        new_terms[i] = t
      end
    end
  end

  return new_terms or terms, new_terms and true or false
end


-- Add a term to the term_map --------------------------------------------------

local SCOPE_FORMAT = { scopes = true }

function add_term(term_map, coeff, e)
  local s = lib.repr(e, SCOPE_FORMAT)
  local t = term_map[s]
  if coeff == 0 then
    return true                                 -- Do nothing, but either way we removed a term
  end
  if t then
    t.coeff = t.coeff + coeff
    return true
  else
    term_map[s] = { name=lib.repr(e), coeff=coeff, expression=e }
  end
end


-- EOF -------------------------------------------------------------------------

