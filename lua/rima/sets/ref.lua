-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local math, table = require("math"), require("table")
local error, getmetatable, ipairs, next, pairs, select =
      error, getmetatable, ipairs, next, pairs, select

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local index_op = require("rima.operators.index")
local iterator = require("rima.sets.iterator")
local expression = require("rima.expression")
local scope = require("rima.scope")
local rima = rima

module(...)


-- Sequence --------------------------------------------------------------------

ref = object:new(_M, "sets.ref")


function ref:new(exp, order, values, names, result)
  return object.new(self, {exp=exp, order=order, values=values, names=names, result=result})
end


function ref:set_names(names)
  self.names = names
end


function ref:read(s)
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
  local result
  if type(set) == "string" then
    result = ref:new(rima.R(set), "a", "elements", names)
  elseif ref:isa(set) then
    set:set_names(names)
    result = set
  elseif not core.defined(set) then
    result = ref:new(set, "a", "elements", names)
  else
    local im = lib.getmetamethod(set, "__iterate")
    if im then
      result = ref:new(set, "a", "elements", names)
    else
      error(("Expected a string, expression or iterable object.  Got '%s'"):format(lib.repr(set)))
    end
  end
  return result
end


function ref:__repr(format)
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
ref.__tostring = lib.__tostring


function ref:eval(S)
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

  return ref:new(b, self.order, self.values, self.names, r)
end


function ref:__defined()
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


-- Iteration -------------------------------------------------------------------

-- It seems we need a new scope for every iteration because bind might
-- be used, and any indexes might need to be remembered for a later evaluation
-- bind is evil.

local function set_ref_ipairs(state, i)
  i = i + 1
  local v = state.resolved_set[i]
  if not v then return end
  local S = scope.spawn(state.scope, nil, {overwrite=true, no_undefined=true})
  local n1, n2 = state.names[1], state.names[2]
  if n1 and n1 ~= "_" then S[n1] = i end
  if n2 and n2 ~= "_" then S[n2] = state.set[i] end
  return i, S
end


local function set_ref_pairs(state, k)
  k = next(state.resolved_set, k)
  if not k then return end
  local S = scope.spawn(state.scope, nil, {overwrite=true, no_undefined=true})
  local n1, n2 = state.names[1], state.names[2]
  if n1 and n1 ~= "_" then S[n1] = k end
  if n2 and n2 ~= "_" then S[n2] = state.set[k] end
  return k, S
end


local function set_ref_ielements(state, i)
  local rs = state.resolved_set
  i = i + 1
  local v = rs[i]
  if not v then return end
  v = v.value
  local s = state.set
  local S = scope.spawn(state.scope, nil, {overwrite=true, no_undefined=true})
  S[state.names[1]] = iterator:new(s, expression:new(index_op, s, i), i, v, rs)
  return i, S
end


local function set_ref_elements(state, k)
  local rs = state.resolved_set
  local v
  k, v = next(rs, k)
  if not k then return end
  v = v.value
  local s = state.set
  local S = scope.spawn(state.scope, nil, {overwrite=true, no_undefined=true})
  S[state.names[1]] = iterator:new(s, expression:new(index_op, s, k), k, v, rs)
  return k, S
end


local function set_ref_subiterate2(state, ...)
  local k = select(1, ...)
  if not k then return end

  local names = state.names
  local name_count = #names
  local arg_count = select("#", ...) + 1
  
  local S = scope.spawn(state.scope, nil, {overwrite=true, no_undefined=true})

  for i = 1, math.min(name_count, arg_count) do
    local n = names[i]
    if n and n ~= "_" then
      S[n] = select(i, ...)
    end
  end
  return k, S
end

local function set_ref_subiterate(state, k)
  return set_ref_subiterate2(state, state.iterate_function(state.iterate_state, k))
end


function ref:iterate(S)
  local state = { scope=S, set=self.exp, names=self.names, resolved_set=self.result }
  local iterate_function = lib.getmetamethod(self.result, "__iterate")

  if self.order == "i" or (self.order == "a" and not iterate_function and self.result[1]) then
    if self.values == "pairs" then
      return set_ref_ipairs, state, 0
    else
      return set_ref_ielements, state, 0
    end
  elseif not iterate_function then
    if self.values == "pairs" then
      return set_ref_pairs, state, nil
    else
      return set_ref_elements, state, nil
    end
  else
    self.values = "all"
    local initial
    state.iterate_function, state.iterate_state, initial = iterate_function(self.result)
    return set_ref_subiterate, state, initial
  end
end


-- EOF -------------------------------------------------------------------------
