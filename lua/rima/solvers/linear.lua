-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local table = require("table")
local pairs = pairs

module(...)


--------------------------------------------------------------------------------

function build_linear_problem(M)
  -- add costs to variables
  for name, v in pairs(M.variable_map) do
    local o = M.linear_objective[name]
    v.cost = (o and o.coeff) or 0
  end

  -- Build a set of sparse constraints
  local sparse_constraints = {}
  local i = 1
  for _, c in pairs(M.constraint_info) do
    local elements = {}
    local j = 1
    for name, element in pairs(c.linear_exp) do
      element.index = M.variable_map[name].index
      elements[j] = element    
      j = j + 1
    end
    table.sort(elements, function(a, b) return a.index < b.index end)
    c.elements = elements
    sparse_constraints[i] = c
    i = i + 1
  end

  M.sparse_constraints = sparse_constraints
end


function write_sparse(M, f)
  f = f or io.stdout

  f:write("Minimise:\n")
  for i, v in ipairs(M.ordered_variables) do
    f:write(("  %0.4g*%s (index=%d, lower=%0.4g, upper=%0.4g)\n"):format(v.cost, v.name, i, v.type.lower, v.type.upper))
  end

  f:write("Subject to:\n")
  
  for _, c in ipairs(M.constraint_info) do
    f:write(("  %0.4g <= "):format(c.lower))
    for _, cc in ipairs(c.elements) do
      f:write(("%+0.4g*%s "):format(cc.coeff, M.ordered_variables[cc.index].name))
    end
    f:write(("<= %0.4g\n"):format(c.upper))
  end
end


-- EOF -------------------------------------------------------------------------

