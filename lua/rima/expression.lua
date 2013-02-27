-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")


------------------------------------------------------------------------------

local expression = object:new_class({}, "expression")
local expression_methods, expression_ops


local function copy_methods(m, t)
  for k, v in pairs(m) do
    if not rawget(t, k) then
      rawset(t, k, v)
    end
  end
end


function expression:copy_operators(t)
  copy_methods(expression_ops, t)
end


function expression:new_type(t, typename)
  copy_methods(expression_methods, t)
  self:copy_operators(t)
  return self:new_class(t, typename)
end


function expression:_new(op, terms)
  local e = proxy:new(terms, op)
  if op.simplify then e = op.simplify(e) end
  return e
end


function expression:new(op, ...)
  return self:_new(op, {...})
end


function expression:new_table(op, terms)
  return self:_new(op, terms)
end


------------------------------------------------------------------------------

expression_methods =
{
  new        = function(self, ...)    return expression:_new(self, {...}) end,
  new_table  = function(self, t)      return expression:new_table(self, t) end,
  __tostring = lib.__tostring,
  __repr =
    function(self, format)
      return object.typename(self).."("..lib.concat_repr(proxy.O(self), format)..")"
    end,
}


function expression_methods:__list_variables(S, list)
  local terms = proxy.O(self)
  for i = 1, #terms do
    core.list_variables(terms[i], S, list)
  end
end


------------------------------------------------------------------------------

-- The expression operators are lazy loaded to avoid a require conflict between
-- the operators (which require expression) and expression (which requires
-- operators).  It would be nice if there was a better workaround.

local function load_op(t, k) t[k] = require("rima.operators."..k) return t[k] end
local op_mods = setmetatable({}, { __index = load_op })

local function load_index(t, k) t[k] = require("rima."..k) return t[k] end
local index_mods = setmetatable({}, { __index = load_index })

expression_ops =
{
  __add   = function(a, b) return expression:new(op_mods.add, { 1, a}, { 1, b}) end,
  __sub   = function(a, b) return expression:new(op_mods.add, { 1, a}, {-1, b}) end,
  __unm   = function(a)    return expression:new(op_mods.add, {-1, a}) end,
  __mul   = function(a, b) return expression:new(op_mods.mul, { 1, a}, { 1, b}) end,
  __div   = function(a, b) return expression:new(op_mods.mul, { 1, a}, {-1, b}) end,
  __pow   = function(a, b) return expression:new(op_mods.pow, a, b) end,
  __mod   = function(a, b) return expression:new(op_mods.mod, a, b) end,
  __call  = function(...)  return expression:new(op_mods.call, ...) end,
  __index = function(...)  return index_mods.index:new(...) end,
  __newindex = function (t, k, v)
    local tt = object.typename(t)
    if tt == "index" then
      return index_mods.index.newindex(t, k, v, 1)
    else
      error("Can't index an "..object.typename(tt))
    end
  end
}


------------------------------------------------------------------------------

return expression

------------------------------------------------------------------------------

