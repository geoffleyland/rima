-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local coroutine, table = require("coroutine"), require("table")
local ipairs, next, pairs = ipairs, next, pairs
local error, getmetatable, require, type = error, getmetatable, require, type

local object = require("rima.object")
local proxy = require("rima.proxy")
local types = require("rima.types")
require("rima.private")
local rima = rima

module(...)

local scope = require("rima.scope")
local expression = require("rima.expression")
local ref = require("rima.ref")


-- Set elements ----------------------------------------------------------------

element = object:new({}, "element")
function element:new(set, index, value)
  return object.new(self, {set=set, index=index, value=value})
end


function element:__repr(f)
  if f and f.dump then
    return ("element(%s, %s, %s)"):format(
      rima.repr(self.set, f), rima.repr(self.index, f), rima.repr(self.value, f))
  else
    return rima.repr(self.value, f)
  end
end
element.__tostring = element.__repr


-- Ranges ----------------------------------------------------------------------

local range_type = object:new({}, "range_type")
function range_type:new(l, h)
  return object.new(self, { low = l, high = h} )
end


function range_type:__repr(format)
  return ("range(%s, %s)"):format(rima.repr(self.low, format), rima.repr(self.high, format))
end
range_type.__tostring = range_type.__repr


function range_type:__iterate()
  local function iter(a, e)
    local i = e[1] + 1
    if i <= a.high then
      return { i }
    end
  end
  
  return iter, self, { self.low-1 }
end


local range_op = object:new({}, "range")
function range_op.__eval(args, S, eval)
  local l, h = eval(args[1], S), eval(args[2], S)
  if type(l) == "number" and type(h) == "number" then
    return range_type:new(l, h)
  else
    return expression:new(range_op, l, h)
  end
end


function rima.range(l, h)
  return expression:new(range_op, l, h)
end


-- Iterator --------------------------------------------------------------------

iterator = object:new({}, "iterator")


function iterator:new(exp, order, values, names, result)
  return object.new(self, {exp=exp, order=order, values=values, names=names, result=result})
end


function iterator:set_names(names)
  self.names = names
end


function iterator:__repr(format)
  local e = rima.repr(self.exp, format)
  local n = table.concat(self.names, ", ")
  if self.order ~= "a" or self.values ~= "elements" then
    return ("%s in %s%s(%s)"):format(n, self.order, self.values, e)
  else
    if n == e then
      return n
    else
      return ("%s in %s"):format(n, e)
    end
  end
end


function iterator:eval(S)
  return iterator:new(expression.bind(self.exp, S), self.order, self.values,
    self.names, expression.eval(self.exp, S))
end


function iterator:defined()
  return expression.defined(self.result)
end


function iterator:iterate()
  local function iiter(a, e)
    local i = e[1] + 1
    local v = a[i]
    if v then
      return { i, v }
    end
  end

  local function iter(a, e)
    local i, v = next(a, e[1])
    if v then
      return { i, v }
    end
  end

  if self.order == "i" then
    return iiter, self.result, { 0 }
  elseif self.order == "" then
    return iter, self.result, {}
  else -- self.order == "a"
    local m = getmetatable(self.result)
    local i = m and m.__iterate
    if i then
      self.values = "all"
      return i(self.result)
    elseif self.result[1] then
      return iiter, self.result, { 0 }
    else
      return iter, self.result, {}
    end
  end
end


function iterator:results()
  local names = self.names
  local exp = self.exp

  if self.values == "pairs" then
    return function(v, S)
      if names[1] and names[1] ~= "_" then S[names[1]] = v[1] end
      if names[2] and names[2] ~= "_" then S[names[2]] = exp[v[1]] end
    end
  elseif self.values == "values" then
    return function(v, S) S[names[1]] = exp[v[1]] end
  elseif self.values == "elements" then
    local m = getmetatable(self.result)
    local i = m and m.__iterate
    if not i then
      return function(v, S) S[names[1]] = element:new(exp, v[1], exp[v[1]]) end
    else
      return function(v, S)
        local j = #v
        for i, n in ipairs(names) do
          if i > j then return end
          if n ~= "_" then
            S[n] = v[i]
          end
        end
      end
    end
  end
end


-- Set list --------------------------------------------------------------------

set_list = object:new({}, "set_list")

function set_list:copy(sets)
  local o = {}
  for i, s in ipairs(sets) do o[i] = s end
  return object.new(self, o)
end


function set_list:new(sets)
  -- first sort the sets - numbered entries first, in numerical order,
  -- and then string keys in alphabetical order
  local sorted_sets = {}
  for k, s in pairs(sets) do
    sorted_sets[#sorted_sets+1] = { k, s }
  end
  table.sort(sorted_sets, function(a, b)
    a, b = a[1], b[1]
    if type(a) == "number" then
      if type(b) == "number" then
        return a < b
      else
        return true
      end
    else
      if type(b) == "number" then
        return false
      else
        return a < b
      end
    end
  end)

  -- now work through the sets to see how to handle each one
  local clean_sets = {}
  for i, s in ipairs(sorted_sets) do
    -- did we get "l", "a=l" or "{a=l}"?
    local namestring, set
    if type(s[1]) == "number" then
      if type(s[2]) == "string" then
        namestring, set = s[2], s[2]
      elseif object.isa(s[2], ref) then
        namestring, set = rima.repr(s[2]), s[2]
      else -- assume it's a table
        namestring, set = next(s[2])
      end
    elseif type(s[1]) == "string" then
      namestring = s[1]
      set = s[2]
    else
      error(("set_list error: didn't understand set argument #%d.  Got '%s'")
        :format(i, rima.repr(s)))
    end

    -- did we get "['a, b']=l"?
    local names = {}
    for n in namestring:gmatch("[%a_][%w_]*") do
      names[#names+1] = n
    end

    -- what was l?
    local it
    if type(set) == "string" then
      it = iterator:new(rima.R(set), "a", "elements", names)
    elseif not expression.defined(set) then
      it = iterator:new(set, "a", "elements", names)
    elseif object.isa(set, iterator) then
      set:set_names(names)
      it = set
    else
      local m = getmetatable(set)
      local i = m and m.__iterate
      if i then
        it = iterator:new(set, "a", "elements", names)
      else
        error(("set_list error: didn't understand set argument #%d.  Expected a string, expression or iterable object.  Got '%s'")
          :format(i, rima.repr(set)))
      end
    end
    clean_sets[i] = it
  end

  return object.new(self, clean_sets)
end


function set_list:__repr(format)
  return "{"..expression.concat(self, format).."}"
end
set_list.__tostring = set_list.__repr


function set_list:iterate(S)
  local scopes = {}
  local undefined_sets = {}

  local function z(i)
    i = i or 1
    if not self[i] then
      local ud
      if undefined_sets[1] then ud = set_list:copy(undefined_sets) end
      coroutine.yield(scopes[i-1] or S, ud)
    else
      if not scopes[i] then
        scopes[i] = scope.spawn(scopes[i-1] or S, nil, {overwrite=true, rewrite=true})
      end
      local it = self[i]:eval(scopes[i-1] or S)
      if it:defined() then
        local results = it:results()
        for variables in it:iterate() do
          results(variables, scopes[i])
          z(i+1)
        end
      else
        undefined_sets[#undefined_sets+1] = it
        for _, n in ipairs(it.names) do
          scope.hide(scopes[i], n)
        end
        z(i+1)
        undefined_sets[#undefined_sets] = nil
      end
    end
  end
  
  return coroutine.wrap(z)
end


-- Top-level iterators ---------------------------------------------------------

function rima.pairs(exp)
  return iterator:new(exp, "", "pairs")
end


function rima.ipairs(exp)
  return iterator:new(exp, "i", "pairs")
end


-- EOF -------------------------------------------------------------------------

