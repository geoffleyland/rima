-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local coroutine = require("coroutine")
local table = require("table")
local ipairs, global_tostring, type, unpack = ipairs, tostring, type, unpack
local setmetatable = setmetatable
local require = require

module(...)

-- Forward declarations ---------------------------------------------------------

expression = {}

-- Subpackages ------------------------------------------------------------------

require("rima.ref")
require("rima.expression")
require("rima.constraint")
require("rima.formulation")
require("rima.values.function_v")


-- Module functionality --------------------------------------------------------

function R(names, type)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = ref:new{name=n, type=type}
  end
  return unpack(results)
end

function E(e, S)
  if not S then
    S = scope.new()
  elseif not object.isa(S, scope) then
    S = scope.create(S)
  end
  return expression.evaluate(e, S)
end

-- Private functionality -------------------------------------------------------

number_format = "%.4g"
function tostring(x)
  if type(x) == "number" then
    return number_format:format(x)
  else
    return global_tostring(x)
  end
end


function imap(f, t)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end


-- Aliases ---------------------------------------------------------------------

alias_type = object:new({}, "alias")
function alias_type:new(exp, name)
  return object.new(self, { exp=exp, name=name })
end

function alias_type:__tostring()
  local name, set = self.name, tostring(self.exp)
  if name == set then
    return name
  else
    return name.." in "..set
  end
end

function alias(exp, name)
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

function value(e)
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

function ord(e)
  return expression:new(ord_op, e)
end


-- Tabulate --------------------------------------------------------------------

local tabulate_type = object:new({}, "tabulate")
function tabulate_type:new(e, ...)
  return object.new(self, { expression=e, indexes={...}})
end

function tabulate_type:__tostring()
  return "tabulate("..tostring(self.expression)..", "..table.concat(imap(tostring, self.indexes), ", ")..")"
end

function tabulate_type:handle_address(S, a)
  if #a ~= #self.indexes then
    error(("the tabulation needs %d indexes, got %d"):format(#self.indexes, #a), 0)
  end
  S2 = scope.spawn(S, nil, {overwrite=true})

  for i, j in ipairs(self.indexes) do
    S2[tostring(j)] = expression.eval(a[i], S)
  end

  return expression.eval(self.expression, S2)
end

function tabulate(e, ...)
  return tabulate_type:new(e, ...)
end


-- Ranges ----------------------------------------------------------------------

local range_type = object:new({}, "range_type")
function range_type:new(l, h)
  return object.new(self, { low = l, high = h} )
end

function range_type:__tostring()
  return "range("..self.low..", "..self.high..")"
end

function range_type:iterate()
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

function range(l, h)
  return expression:new(range_op, l, h)
end

-- Sets ------------------------------------------------------------------------

set = {}

function set.iterate(s, S)
  s = expression.eval(s, S)
  
  if type(s) == "table" and s.iterate then
    return s:iterate()
  else
    return coroutine.wrap(
      function()
        for i, v in ipairs(s) do
          coroutine.yield(element:new(s, i, v))
        end
      end)
  end
end


function set.prepare(S, sets)
  S2 = scope.spawn(S, nil, {overwrite=true})

  local defined_sets, undefined_sets = {}, {} 
  for i, a in ipairs(sets) do
    local r, n
    if object.isa(a, alias_type) then
      r = a.exp
      n = a.name
    else
      r = a
      n = proxy.O(a).name
    end
    S2[n] = types.undefined_t:new()
    local e = expression.evaluate(r, S)
    if e and not object.isa(e, ref) and not object.isa(e, expression) then
      defined_sets[#defined_sets+1] = alias(e, n)
    else
      undefined_sets[#undefined_sets+1] = alias(e, n)
    end
  end
  
  return S2, defined_sets, undefined_sets
end

function set.iterate_all(S, sets)
  local S2 = scope.spawn(S, nil, {rewrite=true})

  local function z(i)
    i = i or 1
    if i > #sets then
      coroutine.yield(S2)
    else
      local s = sets[i]
      for element in set.iterate(s.exp, S) do
        S2[s.name] = element
        z(i+1)
      end
    end
  end
  
  return coroutine.wrap(z)
end


-- EOF -------------------------------------------------------------------------

