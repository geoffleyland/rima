-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local coroutine = require("coroutine")
local tostring, type = tostring, type
local ipairs, pairs = ipairs, pairs
local getmetatable, require, type = getmetatable, require, type

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

ref_iterator = object:new(ref_iterator, "iterator")

function ref_iterator:__iterate(S)
  local z = expression.eval(self.exp, S)

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

function ref_iterator:__tostring()
  local name, set = self.name, rima.tostring(self.exp)
  if name == set then
    return name
  else
    return name.." in "..set
  end
end

function ref_iterator:defined(S)
  self.exp = rima.E(self.exp, S)
  local e = self.exp
  return e and not object.isa(e, rima.ref) and not object.isa(e, expression)
end

function prepare(S, sets)
  S2 = scope.spawn(S, nil, {overwrite=true})

  local defined_sets, undefined_sets = {}, {} 
  for i, a in ipairs(sets) do
    local iterator
    if object.isa(a, alias_type) then
      iterator = ref_iterator:new{exp=a.exp, name=a.name}
    elseif object.isa(a, rima.ref) then
      iterator = ref_iterator:new{exp=a, name=proxy.O(a).name}
    elseif type(a) == "string" then
      iterator = ref_iterator:new{exp=rima.R(a), name=a}
    else
      local mt = getmetatable(a)
      if mt and mt.__iterate then
        iterator = a
      else
        error(("Bad set iterator #d to set.prepare: expected a string, alias, reference or something iterable, got '%s' (%s)"):
          format(i, tostring(a), type(a)), 0)
      end
    end
    if iterator:defined(S) then
      defined_sets[#defined_sets+1] = iterator
    else
      undefined_sets[#undefined_sets+1] = iterator
    end
  end
  
  return S2, defined_sets, undefined_sets
end


function iterate_all(S, sets)
  local S2 = scope.spawn(S, nil, {rewrite=true})

  local function z(i)
    i = i or 1
    if i > #sets then
      coroutine.yield(S2)
    else
      for variables in sets[i]:__iterate(S) do
        for k, v in pairs(variables) do
          S2[k] = v
        end
        z(i+1)
      end
    end
  end
  
  return coroutine.wrap(z)
end


-- Pairs -----------------------------------------------------------------------

pairs_type = object:new({}, "pairs")
function pairs_type:new(exp, key, value)
  return object.new(self, { exp=exp, key_name=key, value_name=value })
end

function pairs_type:__tostring() 
  local s = tostring(self.key_name)
  if self.value_name and self.value_name ~= "_" then
    s = s..", "..tostring(self.value_name)
  end
  s = s.." in "..tostring(self.exp)
  return s
end

function pairs_type:__iterate(S)
  local z = expression.eval(self.exp, S)
  local key_name, value_name = tostring(self.key_name), tostring(self.value_name)
  
  return coroutine.wrap(
    function()
      for k, v in ipairs(z) do
        local r = {}
        if key_name ~= "_" then r[key_name] = k end
        if value_name ~= "_" then r[value_name] = v end
        coroutine.yield(r)
      end
    end)
end

function pairs_type:defined(S)
  self.exp = rima.E(self.exp, S)
  local e = self.exp
  return e and not object.isa(e, rima.ref) and not object.isa(e, expression)
end

function rima.pairs(exp, key, value)
  return pairs_type:new(exp, key, value)
end

-- EOF -------------------------------------------------------------------------

