-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local coroutine = require("coroutine")
local tostring, type = tostring, type
local ipairs, pairs = ipairs, pairs
local error, getmetatable, require, type = error, getmetatable, require, type

local object = require("rima.object")
local proxy = require("rima.proxy")
local types = require("rima.types")
require("rima.private")
local rima = rima

module(...)

local scope = require("rima.scope")
local expression = require("rima.expression")

-- Aliases ---------------------------------------------------------------------

alias_type = object:new({}, "alias")
function alias_type:new(exp, name)
  return object.new(self, { exp=exp, name=name })
end


function alias_type:__tostring()
  local name, set = self.name, rima.tostring(self.exp)
  if name == set then
    return name
  else
    return name.." in "..set
  end
end


function rima.alias(exp, name)
  return alias_type:new(exp, name)
end


-- Set element -----------------------------------------------------------------

element = object:new({}, "element")
function element:new(set, index, key)
  return object.new(self, {set=set, index=index, key=key})
end


function element:__tostring()
  return self.key
end

value_op = object:new({}, "value")
function value_op:eval(S, args)
  local e = expression.eval(args[1], S)
  if object.type(e) == "element" then
    return e.key
  else
    return expression:new(value_op, e)
  end
end

function rima.value(e)
  return expression:new(value_op, e)
end

ord_op = object:new({}, "ord")
function ord_op:eval(S, args)
  local e = expression.eval(args[1], S)
  if object.type(e) == "element" then
    return e.index
  else
    return expression:new(ord_op, e)
  end
end

function rima.ord(e)
  return expression:new(ord_op, e)
end


-- Ranges ----------------------------------------------------------------------

local range_type = object:new({}, "range_type")
function range_type:new(l, h)
  return object.new(self, { low = l, high = h} )
end


function range_type:__tostring()
  return "range("..self.low..", "..self.high..")"
end


function range_type:__iterate()
  return coroutine.wrap(
    function()
      local i = 1 
      for v = self.low, self.high do
        coroutine.yield(element:new(self, i, v))
        i = i + 1
      end
    end)
end


local range_op = object:new({}, "range")
function range_op:eval(S, args)
  local l, h = expression.eval(args[1], S), expression.eval(args[2], S)
  if type(l) == "number" and type(h) == "number" then
    return range_type:new(l, h)
  else
    return expression:new(range_op, l, h)
  end
end


function rima.range(l, h)
  return expression:new(range_op, l, h)
end


-- Iteration -------------------------------------------------------------------

ref_iterator = object:new({}, "iterator")


function ref_iterator:__tostring()
  local name, set = self.name, rima.tostring(self.exp)
  if name == set then
    return name
  else
    return name.." in "..set
  end
end


function ref_iterator:eval(S)
  return ref_iterator:new{ exp=rima.E(self.exp, S), name=self.name }
end


function ref_iterator:defined()
  return expression.defined(self.exp)
end


function ref_iterator:names()
  return { self.name }
end


function ref_iterator:__iterate()
  local z = self.exp
  local m = getmetatable(z)
  local i = m and m.__iterate or nil
  if i then
    return coroutine.wrap(
      function()
        for e in i(z) do
          coroutine.yield({[self.name]=e})
        end
      end)
  else
    return coroutine.wrap(
      function()
        for i, v in ipairs(z) do
          coroutine.yield({[self.name]=element:new(z, i, v)})
        end
      end)
  end
end


-- Set list --------------------------------------------------------------------

set_list = object:new({}, "set_list")
function set_list:new(sets)
  local clean_sets = {}
  for i, s in ipairs(sets) do
    if object.isa(s, alias_type) then
      clean_sets[i] = ref_iterator:new{exp=s.exp, name=s.name}
    elseif object.isa(s, rima.ref) then
      clean_sets[i] = ref_iterator:new{exp=s, name=proxy.O(s).name}
    elseif type(s) == "string" then
      clean_sets[i] = ref_iterator:new{exp=rima.R(s), name=s}
    else
      local mt = getmetatable(s)
      if mt and mt.__iterate then
        clean_sets[i] = s
      else
        error(("Bad set #%d to set_list:new: expected a string, alias, reference or something iterable, got '%s' (%s)"):
          format(i, tostring(s), type(s)), 0)
      end
    end
  end
  return object.new(self, clean_sets)
end


function set_list:dump()
  return "{"..rima.concat(self, ", ", expression.dump).."}"
end


function set_list:__tostring()
  return "{"..rima.concat(self, ", ", rima.tostring).."}"
end


function set_list:iterate(S)
  local undefined_sets = {}

  local function z(Sn, i)
    Sn = Sn or S
    i = i or 1
    if not self[i] then
      coroutine.yield(Sn, set_list:new(undefined_sets))
    else
      local iterator = self[i]:eval(Sn)
      if iterator:defined() then
        for variables in iterator:__iterate() do
          local S2 = scope.spawn(Sn, nil, {overwrite=true, rewrite=true})
          for k, v in pairs(variables) do
            S2[k] = v
          end
          z(S2, i+1)
        end
      else
        undefined_sets[#undefined_sets+1] = rima.E(iterator, Sn)
        local S2 = scope.spawn(Sn, nil, {overwrite=true, rewrite=true})
        for _, n in ipairs(iterator:names()) do          scope.hide(S2, n)
        end
        z(S2, i+1)
        undefined_sets[#undefined_sets] = nil
      end
    end
  end
  
  return coroutine.wrap(z)
end


-- Pairs -----------------------------------------------------------------------

pairs_type = object:new({}, "pairs")
function pairs_type:new(exp, key, value, iterator)
  return object.new(self, { exp=exp, key_name=key, value_name=value, iterator=iterator })
end


function pairs_type:__tostring() 
  local s = tostring(self.key_name)
  if self.value_name and self.value_name ~= "_" then
    s = s..", "..tostring(self.value_name)
  end
  if self.iterator == pairs then
    s = s.." in pairs("..tostring(self.exp)..")"
  else
    s = s.." in ipairs("..tostring(self.exp)..")"
  end
  return s
end


function pairs_type:eval(S)
  return pairs_type:new(rima.E(self.exp, S), self.key_name, self.value_name, self.iterator)
end


function pairs_type:defined()
  return expression.defined(self.exp)
end


function pairs_type:names()
  local r = {}
  if key_name ~= "_" then r[#r+1] = key_name end
  if value_name ~= "_" then r[#r+1] = value_name end
end

function pairs_type:__iterate()
  local key_name, value_name = tostring(self.key_name), tostring(self.value_name)
  local z, iterator = self.exp, self.iterator
  
  return coroutine.wrap(
    function()
      for k, v in iterator(z) do
        local r = {}
        if key_name ~= "_" then r[key_name] = k end
        if value_name ~= "_" then r[value_name] = v end
        coroutine.yield(r)
      end
    end)
end


function rima.pairs(exp, key, value)
  return pairs_type:new(exp, key, value, pairs)
end


function rima.ipairs(exp, key, value)
  return pairs_type:new(exp, key, value, ipairs)
end


-- EOF -------------------------------------------------------------------------

