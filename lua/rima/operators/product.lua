-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local ipairs, pairs, require = ipairs, pairs, require

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local closure = require("rima.closure")

module(...)

local mul = require("rima.operators.mul")
local expression = require("rima.expression")
local set_list = require("rima.sets.list")


-- Subscripts ------------------------------------------------------------------

local product = expression:new_type(_M, "product")
product.precedence = 1


function product:simplify()
  local terms = proxy.O(self)
  if not object.typeinfo(terms[1]).closure then
    local sets = set_list:read(terms[1])
    return expression:new_table(product, { closure:new(terms[2], sets) })
  end
  return self
end


-- String Representation -------------------------------------------------------

function product.__repr(args, format)
  local ar = lib.repr(proxy.O(args)[1], format)
  local ff = format.format
  local f
  if ff == "dump" then
    f = "product(%s)"
  elseif ff == "lua" then
    f = "rima.product%s"
  elseif ff == "latex" then
    f = "\\prod_%s"
  else
    f = "product%s"
  end
  return f:format(ar)
end


-- Evaluation ------------------------------------------------------------------

function product.__eval(args, S)
  args = proxy.O(args)
  local cl = args[1]
  local defined_terms, undefined_terms = {}, {}

  -- Iterate through all the elements of the sets, collecting defined and
  -- undefined terms
  for S2, undefined in cl:iterate(S) do
    local z = core.eval(cl.exp+0, S2)  -- the +0 helps to "cast" e to a number (if it's a set element)
    if undefined and undefined[1] then
      -- Undefined terms are stored in groups based on the undefined product
      -- indices (so we can group them back into prods over the same indices)
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

  -- Run through all the undefined terms, rebuilding the prods
  for n, t in pairs(undefined_terms) do
    local z
    if #t.terms > 1 then
      z = expression:new_table(mul, t.terms)
    else
      z = t.terms[1][2]
    end
    total_terms[#total_terms+1] = {1, expression:new(product, t.iterators, cl:undo(z, t.iterators)) }
  end

  -- mul the defined terms onto the end
  for _, t in ipairs(defined_terms) do
    total_terms[#total_terms+1] = t
  end

  if #total_terms == 1 then
    return total_terms[1][2]
  else
    return core.eval(expression:new_table(mul, total_terms), S)
  end
end


-- Introspection? --------------------------------------------------------------

function product.__list_variables(args, S, list)
  local cl = proxy.O(args)[1]
  for S2, undefined in cl:iterate(S) do
    local S3 = cl:fake_iterate(S2, undefined)
    core.list_variables(core.eval(cl, S3), S3, list)
  end
end


-- product constuctor ----------------------------------------------------------

function build(x)
  local term_count, terms = 1, { x }
  local function next_term(y)
    term_count = term_count + 1
    terms[term_count] = y
    if object.typename(y) == "table" then
      return next_term
    else
      return expression:new_table(product, terms)
    end
  end
  return next_term
end


-- EOF -------------------------------------------------------------------------

