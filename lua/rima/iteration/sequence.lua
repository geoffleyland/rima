-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local table = require("table")
local error, getmetatable, ipairs, next, pairs =
      error, getmetatable, ipairs, next, pairs

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local index_op = require("rima.operators.index")
local iterator = require("rima.iteration.iterator")
local expression = require("rima.expression")
local rima = rima

module(...)



-- Sequence --------------------------------------------------------------------

sequence = object:new(_M, "sequence")

function sequence:new(exp, order, values, names, result)
  return object.new(self, {exp=exp, order=order, values=values, names=names, result=result})
end


function sequence:read(s)
  -- did we get 'S', '"S"' or '{n=S}'?
  local namestring, set
  local t = object.type(s)
  if t == "ref" then -- 's'
    namestring, set = lib.repr(s), s
  elseif t == "string" then -- '"s"'
    namestring, set = s, s
  elseif t == "table" and not getmetatable(s) then -- '{n=S}'
    namestring, set = next(s)
  else
    error(("Got '%s'"):format(lib.repr(s)))
  end

  -- did we get "['a, b']=l"?
  local names = {}
  for n in namestring:gmatch("[%a_][%w_]*") do
    names[#names+1] = n
  end

  -- what was l?
  local seq
  if type(set) == "string" then
    seq = sequence:new(rima.R(set), "a", "elements", names)
  elseif sequence:isa(set) then
    set:set_names(names)
    seq = set
  elseif not core.defined(set) then
    seq = sequence:new(set, "a", "elements", names)
  else
    local im = lib.getmetamethod(set, "__iterate")
    if im then
      seq = sequence:new(set, "a", "elements", names)
    else
      error(("Expected a string, expression or iterable object.  Got '%s'"):format(lib.repr(set)))
    end
  end
  return seq
end


function sequence:set_names(names)
  self.names = names
end


function sequence:__repr(format)
  local e = lib.repr(self.exp, format)
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
sequence.__tostring = lib.__tostring


function sequence:eval(S)
  -- We're looking to evaluate to a table.
  -- Unfortunately, the elements of the table might be spread over several
  -- layers of scope, so we have to work backwards through the scopes
  -- looking for other versions of the table.
  -- This might get easier if resolve was rewritten, but I'm just not ready
  -- to face that yet...
  local b = core.bind(self.exp, S)
  local found = {}
  local es = {}
  local r
  
  while S do
    local e = core.eval(self.exp, S)
    if not core.defined(e) and not es[1] then
      r = e
      break
    end
    local i = lib.getmetamethod(e, "__iterate")
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

  return sequence:new(b, self.order, self.values, self.names, r)
end


function sequence:__defined()
  -- we're looking for a table (or something iterable)
  -- if the table is empty, we'll call it undefined.
  -- This could be wrong in some cases (I hope not), but usually
  -- it means we're being evaluated with partial data.
  local r = self.result
  if core.defined(r) then
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


function sequence:iterate()
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


function sequence:results()
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
        S[names[1]] = iterator:new(exp, expression:new(index_op, exp, v[1]), v[1], v[2], self.result)
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


-- EOF -------------------------------------------------------------------------

