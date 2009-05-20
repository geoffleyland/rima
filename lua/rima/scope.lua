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

local coroutine = require("coroutine")
local error = error
local ipairs, pairs = ipairs, pairs
local getmetatable, setmetatable = getmetatable, setmetatable

local object = require("rima.object")
local proxy = require("rima.proxy")
local tools = require("rima.tools")
local tests = require("rima.tests")
local types = require("rima.types")
local rima = rima

module(...)

-- Constructor -----------------------------------------------------------------

local scope = object:new(_M, "scope")
scope_proxy_mt = setmetatable({}, scope)

function scope.new(S)
  S = S or {}
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
    overwrite = (options.overwrite and true or false), rewrite = (options.rewrite and true or false) }
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
  tools.check_arg_types(parent, "parent", {"nil", {scope, "scope"}}, usage, fname) 

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


-- Accessing and setting -------------------------------------------------------

function scope.find(s, name)
  -- Return values from our own hidden table
  S = proxy.O(s)
  local c = S.values[name]
  if c then return c, s end
  
  -- or look for them in a parent
  if S.parent then return scope.find(S.parent, name) end
  return nil
end


function scope_proxy_mt.__index(S, name)
  local c = scope.find(S, name)
  if c then
    local cc = c[#c]
    -- return a bound variable with the top type (perhaps should be all?) or the value
    return object.isa(cc, types.undefined_t) and rima.ref:new{name=name, type=cc, scope=S} or cc
  end
  return nil
end


function scope.lookup(S, name, bound_scope)
  -- If the variable is bound to a scope, then go looking for it through parents
  -- taking care of overwritable (function) scopes
  local top = S
  if bound_scope then
    while S ~= bound_scope do
      local s = proxy.O(S)
      if s.overwrite then top = s.parent end
      S = s.parent
      if not S then
        error(("the reference '%s' is bound to a scope that is not available"):format(name), 0)
      end
    end
  end
  -- S is the bound scope, and top is the highest non-function child of that scope
  local c, s = scope.find(top, name)
  return c and c[#c] or nil, s
end


function scope.check(S, name, value)
  local s = proxy.O(S)
  local c = s.values[name]

  local function describe(v, name)
    if object.isa(v, types.undefined_t) then
      return v:describe(name)
    else
      return rima.tostring(v)
    end
  end

  if c then
    if not s.rewrite and not object.isa(c[#c], types.undefined_t) then
      error(("cannot set '%s' to '%s': existing definition as '%s'"):
            format(name, describe(value, name), describe(c[#c], name)), 0)
    elseif object.isa(c[#c], types.undefined_t) then
      for _, v in ipairs(c) do
        if not v:includes(value) then
          error(("cannot set '%s' to '%s': violates existing constraint '%s'"):
                format(name, describe(value, name), describe(v, name)), 0)
        end
      end
    end
  end

  if s.parent and not s.overwrite then
    check(s.parent, name, value)
  end
end

function scope_proxy_mt.__newindex(S, name, value)
  local fname, usage =
    "rima.scope:__newindex",
    "__newindex(name: string, value: type or value)"
  tools.check_arg_type(name, "name", "string", usage, fname) 

  check(S, name, value)
  local values = proxy.O(S).values
  local c = values[name]
  if not c then
    c = {}
    values[name] = c
  end
  c[#c+1] = value
end


-- Bulk set --------------------------------------------------------------------

function scope.set(S, values)
  local fname, usage =
    "rima.scope:set",
    "set(values: {string = type or value, ...})"
  tools.check_arg_type(values, "values", "table", usage, fname)
  for k, v in pairs(values) do
    for n in k:gmatch("[%a_][%w_]*") do
      S[n] = v
    end
  end
end


-- Iterating -------------------------------------------------------------------

function scope._iterate(S)
  local s = proxy.O(S)
  for k, v in pairs(s.values) do
    coroutine.yield(k, v[#v])
  end
  if s.parent then
    _iterate(s.parent)
  end
end

function scope.iterate(S)
  local function z()
    _iterate(S)
  end
  return coroutine.wrap(z)
end


-- Test ------------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(object.isa(scope.new(), scope), "isa(scope.new(), scope)")
  T:equal_strings(object.type(scope.new()), "scope", "type(scope.new()) == 'scope'")

  local S = scope.new()

  -- Setting a variable
  T:expect_ok(function() local a = S.a end, "undefined ok")
  T:equal_strings(S.a, nil, "undefined nil")
  T:expect_ok(function() S.a = types.undefined_t:new() end)
  T:expect_ok(function() S.a = rima.free() end)
  T:expect_error(function() S.a = types.undefined_t:new() end, "cannot set 'a' to 'a undefined'")
  T:expect_error(function() S.a = {} end, "cannot set 'a' to 'table")
  T:expect_error(function() S.a = "a" end, "cannot set 'a' to 'a'")
  T:expect_ok(function() S.a = rima.integer() end)
  T:expect_ok(function() S.a = rima.integer(1, 10) end)
  T:expect_error(function() S.a = 11 end, "cannot set 'a' to '11'")
  T:expect_ok(function() S.a = 3 end)
  T:expect_error(function() S.a = 4 end, "cannot set 'a' to '4'")
  T:expect_error(function() S.a = 3 end, "cannot set 'a' to '3'")
  T:expect_error(function() scope.set(S, {a=3}) end, "cannot set 'a' to '3'")

  T:expect_ok(function() scope.set(S, { b=7, c=rima.integer(3, 5) }) end)
  T:equal_strings(object.type(S.a), "number", "type(S.a) == 'number'")
  T:equal_strings(object.type(S.c), "ref", "type(S.c) == 'ref'")
  T:equal_strings(S.a, 3, "S.a == 3")
  T:equal_strings(S.c, "c", "s.c == c")
  T:equal_strings(scope.lookup(S, "a"), 3, "scope.lookup(S, 'a') == 3")
  T:equal_strings(scope.lookup(S, "b"), 7, "scope.lookup(S, 'b') == 7")
  T:equal_strings(rima.ref.describe(S.c), "3 <= c <= 5, c integer")

  -- Setting a variable to an expression
  T:expect_ok(function() S.a2 = S.a end)
  T:expect_ok(function() S.c2 = S.c end)

  local S_no_overwrite = scope.spawn(S)
  T:equal_strings(S_no_overwrite.a, 3, "S.a == 3")
  T:equal_strings(S_no_overwrite.c, "c", "S.c == c")
  T:equal_strings(scope.lookup(S_no_overwrite, "a"), 3, "S.a == a")
  T:equal_strings(scope.lookup(S_no_overwrite, "undefined"), nil, "S.a == a")
  T:expect_error(function() S_no_overwrite.c = 7 end, "cannot set 'c' to '7'")
  T:expect_ok(function() S_no_overwrite.c = 3 end, "can set c to in bounds value")
  T:expect_ok(function() S.c = rima.integer(3, 5) end, "c is not set in parent")

  local r = {}
  for k, v in scope.iterate(S_no_overwrite) do
    r[k] = v
  end
  T:equal_strings(r.a, 3)
  T:equal_strings(r.a2, 3)
  T:equal_strings(r.b, 7)
  T:equal_strings(r.c, "3 <= * <= 5, * integer")
  T:equal_strings(r.c2, "c")
  
  local S_overwrite = scope.spawn(S, nil, {overwrite=true})
  T:expect_ok(function() S_overwrite.c = 7 end, "can overwrite c")

  do
    local S1, S2, S2
    S1 = scope.new()
    S2 = scope.spawn(S1)
    S3 = scope.spawn(S2)
    S1.a = 1
    S2.b = 2
    S3.c = 3
  
    local r = {}
    for k, v in scope.iterate(S3) do
      r[k] = v
    end
    T:equal_strings(r.a, 1)
    T:equal_strings(r.b, 2)
    T:equal_strings(r.c, 3)
  end

  do
    local S1, S2, S3 = scope.new(), scope.new(), scope.new()
    S1.a = 1
    S2.a = 2
    S3.b = 3
    
    scope.set_parent(S3, S1)
    T:equal_strings(scope.lookup(S3, "a"), 1)
    T:expect_error(function() scope.set_parent(S3, S2) end,
      "rima.scope.set_parent: the scope's parent is already set")
    scope.clear_parent(S3)
    scope.set_parent(S3, S2)
    T:equal_strings(scope.lookup(S3, "a"), 2)
    scope.clear_parent(S3)
    T:equal_strings(scope.lookup(S3, "a"), nil)
  end

  -- test bound scope
  do
    local S1, S2, S2
    S1 = scope.new()
    S2 = scope.spawn(S1)
    S3 = scope.spawn(S2, nil, {overwrite=true})
    S2.a = 5
    S3.a = 7
    T:equal_strings(scope.lookup(S1, "a"), nil)
    T:equal_strings(scope.lookup(S2, "a"), 5)
    T:equal_strings(scope.lookup(S3, "a"), 7)
    T:equal_strings(scope.lookup(S3, "a", S1), 5)  
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

