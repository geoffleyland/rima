-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local ipairs, pairs, rawget, rawset, require, setmetatable =
      ipairs, pairs, rawget, rawset, require, setmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")

module(...)


-- Constructor -----------------------------------------------------------------

local expression = object:new_class(_M, "expression")
local expression_methods, load_expression_ops


local function copy_methods(m, t)
  for k, v in pairs(m) do
    if not rawget(t, k) then
      rawset(t, k, v)
    end
  end
end


function expression:copy_operators(t)
  copy_methods(load_expression_ops(), t)
end


function expression:new_type(t, typename)
  copy_methods(expression_methods, t)
  copy_methods(load_expression_ops(), t)
  return self:new_class(t, typename)
end


function expression:_new(op, terms)
  if rawget(op, "construct") then terms = op.construct(terms) end
  return proxy:new(terms, op)
end


function expression:new(op, ...)
  return self:_new(op, {...})
end


function expression:new_table(op, terms)
  return self:_new(op, terms)
end


-- String representation -------------------------------------------------------

expression_methods = {}

function expression_methods:new(...)
  return expression:_new(self, {...})
end

function expression_methods.__repr(e, format)
  return object.typename(e).."("..lib.concat_repr(proxy.O(e), format)..")"
end
expression_methods.__tostring = lib.__tostring


-- Introspection? --------------------------------------------------------------

function expression_methods.__list_variables(args, S, list)
  for _, a in ipairs(proxy.O(args)) do
    core.list_variables(a, S, list)
  end
end


-- Overloaded operators --------------------------------------------------------

-- The expression operators are lazy loaded to avoid a require conflict between
-- the operators (which require expression) and expression (which requires
-- operators).  It would be nice if there was a better workaround
local expression_ops
function load_expression_ops()
  if not expression_ops then
    local add_op = require("rima.operators.add")
    local mul_op = require("rima.operators.mul")
    local pow_op = require("rima.operators.pow")
    local call_op = require("rima.operators.call")
    local index = require("rima.index")

    expression_ops =
    {
      __add   = function(a, b) return expression:new(add_op, { 1, a}, { 1, b}) end,
      __sub   = function(a, b) return expression:new(add_op, { 1, a}, {-1, b}) end,
      __unm   = function(a)    return expression:new(add_op, {-1, a}) end,
      __mul   = function(a, b) return expression:new(mul_op, { 1, a}, { 1, b}) end,
      __div   = function(a, b) return expression:new(mul_op, { 1, a}, {-1, b}) end,
      __pow   = function(a, b) return expression:new(pow_op, a, b) end,
      __call  = function(...)  return expression:new(call_op, ...) end,
      __index = function(...)  return index:new(...) end,
    }
  end
  return expression_ops
end


-- EOF -------------------------------------------------------------------------

