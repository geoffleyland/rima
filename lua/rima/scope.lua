-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

--[[
A scope is a table of types and values of variables.
An expression is evaluated in a scope, and all of the references in the
expression are looked up in the scope.  The reference might:
  + not be found, in which case the reference remains
  + find a type in the scope, in which case the reference inherits the type
    found in the scope, and "binds" to the scope
  + find a value in the scope, in which case the value is returned.

Users can set fields of a scope like fields of a table, but scopes are kind-of
write once.
You can set the type of a field, if you subsequently set the type of the field
again, the second type is checked as a subset of the first, and if that's ok,
the second type is added to the type information for the field.
When you set a value to a field, the field is checked against the type
constraints before being set.
Once you've written a value to a field, you can't write the field again.

There can be a hierarchy of scopes - if a field isn't found in a scope, it is
looked up in its parent.  If a child is created with overwrite=false, then
an assignment to a field in the child scope will be checked against its parents
Child.a must be compatible with parent.a.
If a scope is created with overwrite=true, then the child scope can redefine
names from the parent scope (but still access other fields in the parent scope -
think of local and global variables).

Once a reference is bound, it will keep looking in the same scope.  If you
evaluate an expression e1 in a scope S1, and some of its references are bound,
resulting in a new expression e2, and you then try to evaluate e2 in a scope S3
which does not have S1 as a parent, you'll get a scope error.

We want "users" to be able to treat a scope like a table, so we just give
them a proxy, and hide everything we care about in private table.
This means that they have to go scope.set(S, {}) rather than S:set{}, but
it means they can call a variable set if they like (maybe not a huge
advantage) means that we don't have the tackle the problem of working out
whether an S.field is trying to refer to one of "our" fields or one of
"their" fields.
I've tried a few variants on this, and this seems to work.  Alternatives
might be:
  + hide "our" data in a metatable-per-scope
  + start all our field names with _ or some other character.  These are
    fields, not identifiers, so we can use any character we like
--]]

local coroutine, string = require("coroutine"), require("string")
local error, require, unpack = error, require, unpack
local getmetatable, setmetatable = getmetatable, setmetatable
local ipairs, next, pairs = ipairs, next, pairs

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local args = require("rima.lib.args")
local lib = require("rima.lib")
local core = require("rima.core")
local undefined_t = require("rima.types.undefined_t")

module(...)

local ref = require("rima.ref")
local address = require("rima.address")
local set_list = require("rima.sets.list")
local tabulate_type = require("rima.values.tabulate")

-- Scope names -----------------------------------------------------------------

local scope_names = setmetatable({}, { __mode="v" })
free_index_marker = {}

local function new_name(prefix)

  local function z(depth, prefix)
    for c = ("A"):byte(), ("Z"):byte() do
      local n = prefix..string.char(c)
      if depth == 1 then
        if not scope_names[n] then
          return n
        end
      else
        local n = z(depth-1, n)
        if n then return n end
      end
    end
  end

  local i = 1
  local n
  repeat
    n = z(i, prefix)
    i = i + 1
  until n
  return n
end

local function check_name(S)
  if S.name then
    if scope_names[S.name] then
      error(("The scope name '%s' is already in use"):format(S.name))
    end
  else
    S.name = new_name((S.parent and proxy.O(S.parent).name.."_") or "_")
  end
  scope_names[S.name] = S
end


-- Constructor -----------------------------------------------------------------

local scope = object:new(_M, "scope")
scope_proxy_mt = setmetatable({}, scope)


function scope._new(S)
  S = S or {}
  check_name(S)
  if not S.values then S.values = {} end
  return proxy:new(object.new(scope, S), scope_proxy_mt)
end


function scope.new(values, options)
  options = options or {}
  local S = _new{
    parent = false,
    overwrite = (options.overwrite and true or false),
    rewrite = (options.rewrite and true or false),
    no_undefined = (options.no_undefined and true or false),
    name = options.name }
  if values then set(S, values) end
  return S
end


function scope.spawn(S, values, options)
  local fname, usage = "rima.scope.spawn", "spawn(S, values, options})"
  args.check_type(S, "S", {scope, "scope" }, usage, fname)

  options = options or {}
  local S2 = _new{
    parent = S,
    overwrite = (options.overwrite and true or false),
    rewrite = (options.rewrite and true or false),
    no_undefined = (options.no_undefined and true or false),
    name = options.name }
  if values then set(S2, values) end
  return S2
end


function scope.has_parent(S)
  return proxy.O(S).parent and true or false
end


function scope.set_parent(S, parent)
  local fname, usage =
    "rima.scope.set_parent",
    "new(parent, overwrite)"
  args.check_types(parent, "parent", {"nil", {scope, "scope"}}, usage, fname) 

  S = proxy.O(S)
  if S.parent then
    error(("%s: the scope's parent is already set"):format(fname))
  end
  S.parent = parent
  S.overwrite = true
end


function scope.clear_parent(S)
  proxy.O(S).parent = false
end


-- Scope values ----------------------------------------------------------------

svalue = object:new({}, "svalue")

function svalue:new(o)
  return object.new(self, o)
end


function svalue:__repr(format)
  if format and format.dump then
    return "svalue{ value = "..lib.repr(self.value, format).." }"
  else
    return lib.repr(self.value, format)
  end
end
svalue.__tostring = lib.__tostring


function scope.pack(v)
  return (svalue:isa(v) and v) or svalue:new{value=v}
end

function scope.unpack(v)
  return (svalue:isa(v) and v.value) or v
end


-- String representation -------------------------------------------------------

function scope_proxy_mt.__repr(s)
  return proxy.O(s).name
end
scope_proxy_mt.__tostring = scope_proxy_mt.__repr


-- Accessing and setting -------------------------------------------------------

function scope.find(s, name, op, results)
  -- return all the values that could bind to the name in this and parent scopes
  local S = proxy.O(s)
  local c = S.values[name]
  if c then
    results = results or {}
    results[#results+1] = { c, s }
  end

  -- We have to keep looking if there's a parent scope and
  if S.parent and
     -- we're planning to read
     (op == "read" or
     -- we're planning to write, and we haven't reached a scope we can overwrite
      (op == "write" and not S.overwrite)) then
    results = find(S.parent, name, op, results)
  end
  return results
end


function scope_proxy_mt.__index(s, name)
  -- We either want to return the literal value we've looked up, or, if there's
  -- only type information, a reference.
  -- there's two types of literal value - a value, and nil.  We'd like to
  -- return nil if that's what we find.
  local results = find(s, name, "read")
  if results then
    local c, fs = unpack(results[1])
    if undefined_t:isa(c.value) then
      -- There is a value (and it's not hidden), return a reference that I
      -- think should be bound to the top scope.
      -- I'm not sure about this though.  Maybe it should be bound to the scope
      -- the variable was found in (this will come into play with function
      -- scopes, but I haven't worked out how to test it yet)
      return ref:new{name=name, type=c.value, scope=s}
    elseif c.hidden then
      return nil
    elseif type(c.value) == "table" and not getmetatable(c.value) then
      return ref:new{name=name, scope=s}
    else
      return c.value
    end
  else
    return ref:new{name=name, scope=s}
  end
end


function scope.find_bound_scope(s, bound_scope, name)
  -- If the variable is bound to a scope, then go looking for it through parents
  -- taking care of overwritable (function) scopes
  if not s then return bound_scope end
  local top = s
  if bound_scope then
    while s ~= bound_scope do
      local S = proxy.O(s)
      if S.overwrite then top = S.parent end
      s = S.parent
      if not s then
        return bound_scope
      end
    end
  end
  return top
end


function scope.lookup(s, name, bound_scope)
  s = find_bound_scope(s, bound_scope, name)
  if not s then return end
  local r = find(s, name, "read")
  if r then
    return r[1][1], r[1][2]
  end
end


function scope.check(s, name, address, value)
  local results = find(s, name, "write")
  if not results then return end
  local S = proxy.O(s)
  address = (address and address[1] and address) or nil
  local r = address and ref:new{ name = name }

  for _, r in ipairs(results) do
    local c, cs = unpack(r)
    local collected
    if address then
      local status, nc
      status, nc, _, _, collected = address:resolve(s, c, 1, r, core.eval)
      c = status and nc or nil
    end
    if c then
      if type(value) == "table" and not getmetatable(value) and
         type(c.value) == "table" and not getmetatable(c.value) then
        -- this is ok - we can merge two tables
      elseif collected and #collected > 0 then
        -- this is ok, we can override a prototype
      elseif cs == s and not S.rewrite then
        error(("scope: cannot set '%s%s' to '%s': existing definition as '%s'"):
          format(name, address and lib.repr(address) or "", lib.repr(value), lib.repr(c)), 0)
      elseif cs ~= s and undefined_t:isa(c.value) then
        if not c.value:includes(value) then
          error(("scope: cannot set '%s%s' to '%s': violates existing constraint '%s'"):
            format(name, address and lib.repr(address) or "", lib.repr(value), lib.repr(c)), 0)
        end
      elseif cs ~= s then
        error(("scope: cannot set '%s%s' to '%s': existing definition as '%s'"):
          format(name, address and lib.repr(address) or "", lib.repr(value), lib.repr(c)), 0)
      end
    end
  end
end


function scope_proxy_mt.__newindex(s, name, value)
  local fname, usage =
    "rima.scope:__newindex",
    "__newindex(name: string, value: type or value)"
  args.check_type(name, "name", "string", usage, fname) 

  check(s, name, nil, value)
  local S = proxy.O(s)

  if type(value) == "table" and not getmetatable(value) then
    S.values[name] = S.values[name] or scope.pack{}
    for k, v in pairs(value) do
      scope.newindex(s, name, nil, k, v)
    end
  else
    S.values[name] = scope.pack(value)
  end
end


function scope.newindex(s, name, addr, index, value, free_indexes)
  local new_address = addr and addr+index or address:new(index)
  scope.check(s, name, new_address, value)

  local S = proxy.O(s)

  local function is_free_index(index)
    local ti = type(index)
    return ti == "ref" or (ti == "table" and not getmetatable(index))
  end

  local function append_free_index(index)
    free_indexes = free_indexes or set_list:new()
    free_indexes:append(index)
  end

  local function get_prototype(t)
    local p = t.prototype
    if not p then
      p = scope.pack{}
      t.prototype = p
    end
    return p
  end

  local function apply_index(t, index)
    if is_free_index(index) then
      append_free_index(index)
      return get_prototype(t)
    else
      -- just a normal index: t...["index"]... = value
      local z = t.value[index]
      if not z then
        z = scope.pack{}
        t.value[index] = z
      end
      return z
    end
  end

  local c = S.values[name]
  if not c then
    c = scope.pack{}
    S.values[name] = c
  end

  -- we can be fairly cavalier about resolving the address because
  -- check() made sure it's ok for us.  Here we're just building any
  -- necessary intermediate tables.
  if addr then
    for i, a in addr:values() do
      c = apply_index(c, a)
    end
  end

  if type(value) == "table" and not getmetatable(value) then
    -- s.name[addr1][addr2]...[addrN][index] = { a = b, c = d ... }
    -- Go through all of this again with one extra index.
    -- Clearly a waste of time, there must be a better way to do this...
    for k, v in pairs(value) do
      scope.newindex(s, name, new_address, k, v, free_indexes and set_list.copy(free_indexes))
    end
  else
    if is_free_index(index) then
      append_free_index(index)
    end

    -- if there are any free indexes, then wrap their details up with the value
    if free_indexes then
      value = tabulate_type:new(free_indexes, value)
    end

    if is_free_index(index) then
      c.prototype = scope.pack(value)
    else
      c.value[index] = scope.pack(value)
    end
  end
end


-- Hide ------------------------------------------------------------------------

function scope.hide(S, name)
  proxy.O(S).values[name] = svalue:new{hidden=true}
end


-- Bulk set --------------------------------------------------------------------

function scope.set(s, values)
  local fname, usage =
    "rima.scope:set",
    "set(values: {string = type or value, ...})"
  args.check_type(values, "values", "table", usage, fname)
  for k, v in pairs(values) do
    for n in k:gmatch("[%a_][%w_]*") do
      s[n] = v
    end
  end
end


-- Iterating -------------------------------------------------------------------

local function copy(to, from)
  local function z(k, v)
    local c = to[k]
    if c then
      if type(c) == "table" and not getmetatable(c) then
        copy(c, v)
      end
    else
      if type(v.value) == "table" and not getmetatable(v.value) then
        local c = {}
        to[k] = c
        copy(c, v)
      else
        to[k] = v.value
      end
    end
  end

  local f = pack(from)
  for k, v in pairs(f.value) do z(k, v) end
  local d = f.prototype
  if d then z(free_index_marker, d) end
end

function scope.contents(s, t)
  t = t or {}
  local S = proxy.O(s)
  copy(t, S.values)
  if S.parent then
    contents(S.parent, t)
  end
  return t
end

function scope.iterate(s, t)
  t = t or {}
  local S = proxy.O(s)
  copy(t, S.values)
  return coroutine.wrap(
    function() for k, v in pairs(contents(s, t)) do coroutine.yield(k, v) end end)
end


-- EOF -------------------------------------------------------------------------

