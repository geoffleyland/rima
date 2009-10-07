-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

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
local error, require, setmetatable, unpack = error, require, setmetatable, unpack
local ipairs, pairs = ipairs, pairs

local object = require("rima.object")
local proxy = require("rima.proxy")
local args = require("rima.args")
local undefined_t = require("rima.types.undefined_t")
require("rima.private")
local rima = rima

module(...)

local ref = require("rima.ref")

-- Scope names -----------------------------------------------------------------

local scope_names = setmetatable({}, { __mode="v" })

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
scope.hidden = {}


function scope.new(S)
  S = S or {}
  check_name(S)
  if not S.values then S.values = {} end
  return proxy:new(object.new(scope, S), scope_proxy_mt)
end


function scope.create(values)
  local S = new()
  set(S, values)
  return S
end


function scope.spawn(S, values, options)
  options = options or {}
  local S2 = new{ parent = S,
    overwrite = (options.overwrite and true or false),
    rewrite = (options.rewrite and true or false),
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
  proxy.O(S).parent = nil
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
     -- we're planning to read, and we haven't found anything yet
     ((op == "read" and not results) or
     -- we're planning to write, and we haven't reached a scope we can overwrite
      (op == "write" and not S.overwrite)) then
    results = find(S.parent, name, op, results)
  end
  return results
end


function scope_proxy_mt.__index(S, name)
  -- We either want to return the literal value we've looked up, or, if there's
  -- only type information, a reference.
  -- there's two types of literal value - a value, and nil.  We'd like to
  -- return nil if that's what we find.
  local results = find(S, name, "read")
  if results then
    local c, s = unpack(results[1])
    if object.isa(c, undefined_t) then
      -- There is a value (and it's not hidden), return a reference that I
      -- think should be bound to the top scope.
      -- I'm not sure about this though.  Maybe it should be bound to the scope
      -- the variable was found in (this will come into play with function
      -- scopes, but I haven't worked out how to test it yet)
      return ref:new{name=name, type=c, scope=S}
    elseif c ~= hidden then
      return c
    end
  end
end


function scope.find_bound_scope(S, bound_scope, name)
  -- If the variable is bound to a scope, then go looking for it through parents
  -- taking care of overwritable (function) scopes
  local top = S
  if bound_scope then
    while S ~= bound_scope do
      local s = proxy.O(S)
      if s.overwrite then top = s.parent end
      S = s.parent
      if not S then
        return bound_scope
      end
    end
  end
  return top
end


function scope.lookup(S, name, bound_scope)
  local r = find(find_bound_scope(S, bound_scope, name), name, "read")
  if r and r[1][1] ~= hidden then
    return unpack(r[1])                         -- returning multiple values so no if..and..or
  end
end


function scope.check(S, name, value)
  local results = find(S, name, "write")
  if not results then return end
  local s = proxy.O(S)

  for _, r in ipairs(results) do
    local c, CS = unpack(r)
    if CS == S and not s.rewrite then
      error(("scope: cannot set '%s' to '%s': existing definition as '%s'"):
        format(name, rima.repr(value), rima.repr(c)), 0)
    elseif object.isa(c, undefined_t) then
      if not c:includes(value) then
        error(("scope: cannot set '%s' to '%s': violates existing constraint '%s'"):
          format(name, rima.repr(value), rima.repr(c)), 0)
      end
    elseif CS ~= S then
      error(("scope: cannot set '%s' to '%s': existing definition as '%s'"):
        format(name, rima.repr(value), rima.repr(c)), 0)
    end
  end
end


function scope_proxy_mt.__newindex(S, name, value)
  local fname, usage =
    "rima.scope:__newindex",
    "__newindex(name: string, value: type or value)"
  args.check_type(name, "name", "string", usage, fname) 

  check(S, name, value)
  proxy.O(S).values[name] = value
end


-- Hide ------------------------------------------------------------------------

function scope.hide(S, name)
  proxy.O(S).values[name] = scope.hidden
end


-- Bulk set --------------------------------------------------------------------

function scope.set(S, values)
  local fname, usage =
    "rima.scope:set",
    "set(values: {string = type or value, ...})"
  args.check_type(values, "values", "table", usage, fname)
  for k, v in pairs(values) do
    for n in k:gmatch("[%a_][%w_]*") do
      S[n] = v
    end
  end
end


-- Iterating -------------------------------------------------------------------

function scope.iterate(S, t)
  t = t or {}
  local s = proxy.O(S)
  for k, v in pairs(s.values) do
    t[k] = t[k] or v
  end
  if s.parent then
    iterate(s.parent, t)
  end
  return coroutine.wrap(
    function() for k, v in pairs(t) do coroutine.yield(k, v) end end)
end


-- EOF -------------------------------------------------------------------------

