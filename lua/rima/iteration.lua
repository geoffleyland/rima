-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local coroutine, table = require("coroutine"), require("table")
local ipairs, next, pairs, rawget = ipairs, next, pairs, rawget
local error, getmetatable, require, type = error, getmetatable, require, type

local object = require("rima.object")
local proxy = require("rima.proxy")
local types = require("rima.types")
local index_op = require("rima.operators.index")
require("rima.private")
local rima = rima

module(...)

local scope = require("rima.scope")
local expression = require("rima.expression")

-- Ord -------------------------------------------------------------------------

ord = object:new({}, "ord")


function ord.__eval(args, S, eval)
  local a = expression.bind(args[1], S)
  local k = expression.tags(a).key
  if not k or eval == expression.bind then
    return expression:new(ord, a)
  else
    return k
  end
end


function rima.ord(e)
  return expression:new(ord, e)
end


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
    local f = (format and format.readable and "%s=rima.%s%s(%s)") or "%s in %s%s(%s)"
    return f:format(n, self.order, self.values, e)
  else
    if n == e then
      return n
    else
      local f = (format and format.readable and "%s=%s") or "%s in %s"
      return f:format(n, e)
    end
  end
end
iterator.__tostring = iterator.__repr


function iterator:eval(S)
  -- We're looking to evaluate to a table.
  -- Unfortunately, the elements of the table might be spread over several
  -- layers of scope, so we have to work backwards through the scopes
  -- looking for other versions of the table.
  -- This might get easier if resolve was rewritten, but I'm just not ready
  -- to face that yet...
  local b = expression.bind(self.exp, S)
  local found = {}
  local es = {}
  local r
  
  while S do
    local e = expression.eval(self.exp, S)
    if not expression.defined(e) and not es[1] then
      r = e
      break
    end
    local m = getmetatable(e)
    local i = m and rawget(m, "__iterate")
    if i then
      r = e
      break
    end
    
    if not found[e] then
      found[e] = true
      es[#es+1] = e
    end
    S = proxy.O(S).parent
  end

  if not r then
    r = {}
    for _, e in ipairs(es) do
      for k, v in pairs(e) do
        if not r[k] then r[k] = v end
      end
    end
  end

  return iterator:new(b, self.order, self.values, self.names, r)
end


function iterator:defined()
  -- we're looking for a table (or something iterable)
  -- if the table is empty, we'll call it undefined.
  -- This could be wrong in some cases (I hope not), but usually
  -- it means we're being evaluated with partial data.
  local r = self.result
  if expression.defined(r) then
    local m = getmetatable(r)
    local i = m and m.__iterate
    if i then
      return true
    elseif next(r) then
      return true
    else
      return false
    end
  else
    return false
  end
end


function iterator:iterate()
  local function iiter(a, e)
    local i = e[1] + 1
    local v = a[i]
    if v then
      return { i, v.value }
    end
  end

  local function iter(a, e)
    local i, v = next(a, e[1])
    if v then
      return { i, v.value }
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
  elseif self.values == "elements" then
    local m = getmetatable(self.result)
    local i = m and m.__iterate
    if not i then
      return function(v, S)
        local e = expression:new(index_op, exp, v[1])
        expression.tag(e, { set_expression=exp, set=self.result, key=v[1], value=v[2] })
        S[names[1]] = e
      end
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
    -- did we get 'l', '"l"', 'a=l' or '{a=l}'?
    local namestring, set
    if type(s[1]) == "number" then
      if type(s[2]) == "string" then -- '"l"'
        namestring, set = s[2], s[2]
      elseif object.type(s[2]) == "ref" then -- 'l'
        namestring, set = rima.repr(s[2]), s[2]
      else -- assume it's a table '{a=l}'
        namestring, set = next(s[2])
      end
    elseif type(s[1]) == "string" then -- 'a=l'
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

  local function z(i, cS)
    i = i or 1
    cS = cS or S
    if not rawget(self, i) then
      local ud
      if undefined_sets[1] then ud = set_list:copy(undefined_sets) end
      coroutine.yield(cS, ud)        
    else
      local it = self[i]:eval(cS)
      if it:defined() then
        local results = it:results()
        for variables in it:iterate() do
          local nS = scope.spawn(cS, nil, {overwrite=true, no_undefined=true})
          results(variables, nS)
          z(i+1, nS)
        end
      else
        local nS = scope.spawn(cS, nil, {overwrite=true, no_undefined=true})
        undefined_sets[#undefined_sets+1] = it
        for _, n in ipairs(it.names) do
          scope.hide(nS, n)
        end
        z(i+1, nS)
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

