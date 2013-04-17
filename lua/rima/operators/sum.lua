-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")
local closure = require("rima.closure")
local add = require("rima.operators.add")
local ops = require("rima.operations")
local set_list = require("rima.sets.list")


------------------------------------------------------------------------------

local sum = operator:new_class({}, "sum")
sum.precedence = 1


function sum:simplify()
  local ti = object.typeinfo(self[1])
  if ti.closure then
    return self
  elseif ti["sets.list"] then
    return sum:new{ closure:new(self[2], self[1]) }
  else
    local term_count = #self
    local sets = set_list:read(self, term_count-1)
    return sum:new{ closure:new(self[term_count], sets) }
  end
end


------------------------------------------------------------------------------

local formats =
{
  dump = "sum(%s)",
  lua = "rima.sum%s",
  latex = "\\sum_%s",
  other = "sum%s"
}

function sum:__repr(format)
  local f = formats[format.format] or formats.other
  return f:format(lib.repr(self[1], format))
end


------------------------------------------------------------------------------

function sum:__eval(S)
  local cl = self[1]

  -- Iterate through all the elements of the sets, collecting defined and
  -- undefined terms
  local defined_terms, undefined_terms = {}, {}
  for S2, undefined in cl:iterate(S) do
    local z = core.eval(ops.add(0, cl.exp), S2)  -- the +0 helps to "cast" e to a number (if it's a set element)
    if undefined and undefined[1] then
      -- Undefined terms are stored in groups based on the undefined sum
      -- indices (so we can group them back into sums over the same indices)
      local name = lib.concat(undefined, ",", lib.repr)
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

  -- Run through all the undefined terms, rebuilding the sums
  local total_terms = {}
  for n, t in pairs(undefined_terms) do
    local z
    if #t.terms > 1 then
      z = add:new(t.terms)
    else
      z = t.terms[1][2]
    end
    total_terms[#total_terms+1] = {1, sum:new{ t.iterators, cl:undo(z, t.iterators) }}
  end

  -- Add the defined terms onto the end
  for _, t in ipairs(defined_terms) do
    total_terms[#total_terms+1] = t
  end

  if #total_terms == 1 then
    return total_terms[1][2]
  else
    return core.eval(add:new(total_terms), S)
  end
end


------------------------------------------------------------------------------

function sum:__list_variables(S, list)
  local cl = self[1]
  for S2, undefined in cl:iterate(S) do
    local S3 = cl:fake_iterate(S2, undefined)
    core.list_variables(core.eval(cl, S3), S3, list)
  end
end


------------------------------------------------------------------------------

return sum

------------------------------------------------------------------------------

