-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local ipairs, pairs = ipairs, pairs

local object = require("rima.object")
local expression = require("rima.expression")
local add = require("rima.operators.add")
local rima = rima

module(...)

-- Subscripts ------------------------------------------------------------------

local sum = object:new(_M, "sum")
sum.precedence = 1

function sum.construct(args)
  local sets = args[1]
  if not object.isa(sets, rima.iteration.set_list) then
    sets = rima.iteration.set_list:new(sets)
  end
  return { sets, args[2] }
end


-- String Representation -------------------------------------------------------

function sum.__repr(args, format)
  local sets, e = args[1], args[2]
  local name = (format and format.readable and "rima.sum") or "sum"
  if format and format.dump then
    return name.."({"..expression.concat(sets, format).."}, "..rima.repr(e, format)..")"
  else
    return name.."{"..expression.concat(sets, format).."}("..rima.repr(e, format)..")"
  end
end


-- Evaluation ------------------------------------------------------------------


function sum.__eval(args, S, eval)
  local sets, e = args[1], args[2]
  local defined_terms, undefined_terms = {}, {}

  -- Iterate through all the elements of the sets, collecting defined and
  -- undefined terms
  for S2, undefined in sets:iterate(S) do
    local z = eval(e, S2)
    if undefined and undefined[1] then
      -- Undefined terms are stored in groups based on the undefined sum
      -- indices (so we can group them back into sums over the same indices)
      local name = rima.concat(undefined, ",", rima.repr)
      local terms
      local udn = undefined_terms[name]
      if not udn then
        terms = {}
        undefined_terms[name] = { iterators=undefined, terms=terms }
      else
        terms = udn.terms
      end
      terms[#terms+1] = { 1, z }
    else
      -- Defined terms are just stored in a list
      defined_terms[#defined_terms+1] = { 1, z }
    end
  end

  local total_terms = {}

  -- Run through all the undefined terms, rebuilding the sums
  for n, t in pairs(undefined_terms) do
    local z
    if #t.terms > 1 then
      z = expression:new_table(add, t.terms)
    else
      z = t.terms[1][2]
    end
    total_terms[#total_terms+1] = {1, expression:new(sum, t.iterators, z) }
  end

  -- Add the defined terms onto the end
  for _, t in ipairs(defined_terms) do
    total_terms[#total_terms+1] = t
  end

  if #total_terms == 1 then
    return total_terms[1][2]
  else
    return eval(expression:new_table(add, total_terms), S)
  end
end


-- EOF -------------------------------------------------------------------------

