-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local ipairs = ipairs

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


-- EOF -------------------------------------------------------------------------

