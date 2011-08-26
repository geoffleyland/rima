-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local ipairs, pairs, require = ipairs, pairs, require

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local closure = require("rima.closure")

module(...)

local add = require("rima.operators.add")
local expression = require("rima.expression")
local set_list = require("rima.sets.list")


-- Subscripts ------------------------------------------------------------------

local sum = expression:new_type(_M, "sum")
sum.precedence = 1

function sum.construct(args)
  local sets, exp = args[1], args[2]
  if not set_list:isa(sets) then
    sets = set_list:read(sets)
  end
  return { closure:new(exp, sets) }
end


-- String Representation -------------------------------------------------------

function sum.__repr(args, format)
  local ar = lib.repr(proxy.O(args)[1], format)
  local ff = format.format
  local f
  if ff == "dump" then
    f = "sum(%s)"
  elseif ff == "lua" then
    f = "rima.sum%s"
  elseif ff == "latex" then
    f = "\\sum_%s"
  else
    f = "sum%s"
  end
  return f:format(ar)
end


-- Evaluation ------------------------------------------------------------------

function sum.__eval(args, S)
  args = proxy.O(args)
  local cl = args[1]
  local defined_terms, undefined_terms = {}, {}

  -- Iterate through all the elements of the sets, collecting defined and
  -- undefined terms
  for S2, undefined in cl:iterate(S) do
    local z = core.eval(cl.exp+0, S2)  -- the +0 helps to "cast" e to a number (if it's a set element)
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

  local total_terms = {}

  -- Run through all the undefined terms, rebuilding the sums
  for n, t in pairs(undefined_terms) do
    local z
    if #t.terms > 1 then
      z = expression:new_table(add, t.terms)
    else
      z = t.terms[1][2]
    end
    total_terms[#total_terms+1] = {1, expression:new(sum, t.iterators, cl:undo(z, t.iterators)) }
  end

  -- Add the defined terms onto the end
  for _, t in ipairs(defined_terms) do
    total_terms[#total_terms+1] = t
  end

  if #total_terms == 1 then
    return total_terms[1][2]
  else
    return core.eval(expression:new_table(add, total_terms), S)
  end
end


-- Introspection? --------------------------------------------------------------

function sum.__list_variables(args, S, list)
  local cl = proxy.O(args)[1]
  for S2, undefined in cl:iterate(S) do
    local S3 = cl:fake_iterate(S2, undefined)
    core.list_variables(core.eval(cl, S3), S3, list)
  end
end


-- EOF -------------------------------------------------------------------------

