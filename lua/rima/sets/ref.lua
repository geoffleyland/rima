-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math, table = require("math"), require("table")
local error, getmetatable, next, require, select, type =
      error, getmetatable, next, require, select, type

local object = require("rima.lib.object")
local index = require("rima.index")
local lib = require("rima.lib")
local core = require("rima.core")
local element = require("rima.sets.element")

module(...)

local scope = require("rima.scope")


-- Set references --------------------------------------------------------------

ref = object:new_class(_M, "sets.ref")


function ref:new(set, order, values, names, literal)
  return object.new(self,
    { set=set, order=order, values=values, names=names, literal=literal })
end


function ref:set_names(names)
  self.names = names
end


function ref:read(s)
  local tis = object.typeinfo(s)
  if tis["sets.ref"] then return s end

  -- did we get 'S', '"S"' or '{n=S}'?
  local namestring, set
  if tis.index then -- 's'
    namestring, set = index:identifier(s), nil
  elseif tis.string then -- '"s"'
    namestring, set = s, nil
  elseif tis.table and not getmetatable(s) then -- '{n=S}'
    namestring, set = next(s)
  else
    error(("Got '%s', (%s)"):format(lib.repr(s), object.typename(s)))
  end

  -- did we get "['a, b']=l"?
  local names = {}
  for n in namestring:gmatch("[%a_][%w_]*") do
    names[#names+1] = n
  end

  -- what was l?
  local result
  local tis = object.typeinfo(set)
  if not set then
    result = ref:new(nil, "a", "elements", names)  
  elseif tis.string then
    result = ref:new(index:new(nil, set), "a", "elements", names)
  elseif tis["sets.ref"] then
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


-- String representation -------------------------------------------------------

function ref:__repr(format)
  local s = lib.repr(self.set, format)
  local n = (self.names and table.concat(self.names, ", ")) or ""

  local ff = format.format

  if ff == "dump" then
    return ("ref{names={%s}, order={%s%s}, set=%s}"):format(n, self.order, self.values, s)
  end

  if self.set then
    local f
    if self.order ~= "a" or self.values ~= "elements" then
      f = ("%s%s(%%s)"):format(self.order, self.values)
      if ff == "lua" then f = "rima."..f end
    else
      f = "%s"
    end

    if ff == "latex" then
      f = "%s \\in "..f
    elseif ff == "lua" then
      f = "%s="..f
    else
      f = "%s in "..f
    end

    return f:format(n, s)
  else
    return n
  end
end
ref.__tostring = lib.__tostring


-- Evaluation ------------------------------------------------------------------

function ref:__eval(S)
  if not self.set then return self end

  local value, _, addr = core.eval(self.set, S)

  if value == self.set then
    return self
  end

  if not core.defined(value) then
    return ref:new(value, self.order, self.values, self.names)
  end

  if typename(value) ~= "table" and not lib.getmetamethod(value, "__iterate") then
    error(("expecting a table or iterable object when evaluating %s, but got '%s' (%s)"):
      format(lib.repr(self.set), lib.repr(value), typename(value)))
  end
  
  -- assume empty tables mean we're undefined - might be wrong on this
  if not next(value) then
    return ref:new(addr, self.order, self.values, self.names)
  end
  
  return ref:new(self.set, self.order, self.values, self.names, value)
end


function ref:__defined()
  return self.literal ~= nil
end


-- Injection into a scope ------------------------------------------------------

function ref:set_args(S, ...)
  local names = self.names
  if not names then error("no names") end
  for i = 1, math.min(#names, select('#', ...)) do
    local n = names[i]
    if n and n ~= "_" then
      S[n] = select(i, ...)
    end
  end
end


function ref:index(S, Sn, i)
  if not self.set then
    self:set_args(Sn, i)
    return
  end

  local literal = self.literal or core.eval(self.set, S)
  if not core.defined(literal) or not next(literal) then
    literal = nil
  end
  local iterate_function = lib.getmetamethod(literal, "__iterate")

  if iterate_function then
    local iterindex = lib.getmetamethod(literal, "__iterindex")
    if not iterindex then
      error(("Can't directly index the iterable set '%s'"):format(lib.repr(self)))
    else
      self:set_args(Sn, iterindex(literal, i))
    end
    return
  end

  if self.values == "pairs" then
    self:set_args(Sn, i, self.set[i])
  else
    local v = literal and literal[i]
    if l and not v then
      error(("Index out of bounds when indexing %s as %s[%s]"):format(lib.repr(self), lib.repr(self.set), lib.repr(i)))
    end
    local value = v and v.value
    self:set_args(Sn, element:new(self.set[i], i, v, literal))
  end
end


-- Iteration -------------------------------------------------------------------

local function set_ref_ipairs(state, i)
  local r = state.ref
  i = i + 1
  local v = r.literal[i]
  if not v then return end
  r:set_args(state.scope, i, r.set[i])
  return i
end


local function set_ref_pairs(state, k)
  local r = state.ref
  k = next(r.literal, k)
  if not k then return end
  r:set_args(state.scope, k, r.set[k])
  return k
end


local function set_ref_ielements(state, i)
  local r = state.ref
  local l = r.literal
  i = i + 1
  local v = l[i]
  if not v then return end
  r:set_args(state.scope, element:new(r.set[i], i, v.value, l))
  return i
end


local function set_ref_elements(state, k)
  local r = state.ref
  local l = r.literal
  local v
  k, v = next(l, k)
  if not k then return end
  r:set_args(state.scope, element:new(r.set[k], k, v.value, l))
  return k
end


local function set_ref_subiterate2(state, ...)
  local r = state.ref
  local k = select(1, ...)
  if not k then return end
  r:set_args(state.scope, ...)
  return k
end

local function set_ref_subiterate(state, k)
  return set_ref_subiterate2(state, state.iterate_function(state.iterate_state, k))
end


function ref:iterate(S)
  local state = { ref=self, scope=S }
  local iterate_function = lib.getmetamethod(self.literal, "__iterate")

  if self.order == "i" or (self.order == "a" and not iterate_function and self.literal[1]) then
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
    state.iterate_function, state.iterate_state, initial = iterate_function(self.literal)
    return set_ref_subiterate, state, initial
  end
end


function ref:fake_iterate(S)
  if self.values == "pairs" then
    self:set_args(S, nil, self.set[index:new(nil, self.names[2])])
  else
    self:set_args(S, element:new(self.set[index:new(nil, self.names[1])], nil, nil, nil))
  end
end


-- Building iterators ----------------------------------------------------------

function pairs(exp)
  return ref:new(exp, "", "pairs")
end


function ipairs(exp)
  return ref:new(exp, "i", "pairs")
end


-- EOF -------------------------------------------------------------------------

