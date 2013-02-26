-- Copyright (c) 2009-2013 Incremental IP Limited
-- see LICENSE for license information

local object = require"rima.lib.object"
local sum = require"rima.operators.sum"
local product = require"rima.operators.product"
local expression = require"rima.expression"

------------------------------------------------------------------------------

local interface = {}

------------------------------------------------------------------------------

function interface.sum(x)
  local term_count, terms = 1, { x }
  local function next_term(y)
    term_count = term_count + 1
    terms[term_count] = y
    if object.typename(y) == "table" then
      return next_term
    else
      return expression:new_table(sum, terms)
    end
  end
  return next_term
end

------------------------------------------------------------------------------

function interface.product(x)
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


------------------------------------------------------------------------------

return interface

------------------------------------------------------------------------------

