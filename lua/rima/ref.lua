-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error, pcall = error, pcall
local ipairs, rawget, require, type = ipairs, rawget, require, type
local getmetatable, setmetatable = getmetatable, setmetatable

--[[
A ref is a reference to a value or type information that we'll look in a scope.

A reference can have its own type information, and this will be checked against
what's found in the scope.

A reference can be bound to a scope, in which case a lookup in a scope that
doesn't include the bound scope will fail.

Because we wish to be able to index references, we have to hide the real workings
of the reference somewhere tricky.  This is a giant pain in the ass.
--]]

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local args = require("rima.args")
local undefined_t = require("rima.types.undefined_t")
require("rima.private")
local rima = rima

module(...)

local expression = require("rima.expression")
local scope = require("rima.scope")
local iteration = require("rima.iteration")

-- References to values --------------------------------------------------------

local ref = object:new(_M, "ref")
ref.proxy_mt = setmetatable({}, ref)

function ref:new(r)
  local fname, usage = "rima.ref:new", "new(r: {name, type, scope})"
  args.check_type(r, "r", "table", usage, fname)
  args.check_type(r.name, "r.name", "string", usage, fname)
  args.check_types(r.type, "r.type", {"nil", {undefined_t, "type"}}, usage, fname)
  args.check_types(r.scope, "r.scope", {"nil", "boolean", {scope, "scope" }}, usage, fname)

  return proxy:new(object.new(ref, { name=r.name, type=r.type or undefined_t:new(), scope=r.scope or false }), ref.proxy_mt)
end

function ref.is_simple(r)
  r = proxy.O(r)
  return (not r.scope and true) or false
end


-- String Representation -------------------------------------------------------

function ref.proxy_mt.__repr(r, format)
  local R = proxy.O(r)

  local name
  if R.scope and format and format.scopes then
    name = R.name.."@"..rima.repr(R.scope, format)
  else
    name = R.name
  end
  
  if format and format.dump then
    return "ref("..name..")"
  else
    return name
  end
end
ref.proxy_mt.__tostring = ref.proxy_mt.__repr


function ref.describe(r)
  r = proxy.O(r)
  return r.type:describe(r.name)
end


-- Evaluation ------------------------------------------------------------------

function ref.proxy_mt.__bind(r, S)
  local e, found_scope = scope.lookup(S, r.name, r.scope)
  if not e then
    return ref:new{ name=r.name, type=r.type, scope=r.scope or scope.scope_for_undefined(S) }
  elseif e.hidden then
    return ref:new{ name=r.name, type=r.type, scope=r.scope or found_scope }
  elseif expression.defined(e.value) then
    return ref:new{ name=r.name, type=r.type, scope=r.scope or found_scope }
  else
    return expression.bind(e.value, S)
  end
end


function ref.proxy_mt.__eval(r, S)
  -- look the ref up in the scope
  local e, found_scope = scope.lookup(S, r.name, r.scope)
  if not e or e.hidden then                     -- remain unbound
    return ref:new{name=r.name, type=r.type, scope=r.scope}
  end

  -- evaluate the result of the lookup - it might be an expression, or another ref
  local status, v = pcall(function() return expression.eval(e.value, S) end)
  if not status then
    error(("error evaluating '%s' as '%s':\n  %s"):
      format(r.name, rima.repr(e), v:gsub("\n", "\n  ")), 0)
  end

  if object.isa(v, undefined_t) then
    if not v:includes(r.type) and not r.type:includes(v) then
      error(("the type of '%s' (%s) and the type of the reference (%s) are mutually exclusive"):
        format(r.name, v:describe(r.name), r.type:describe(r.name)), 0)
    else
      -- update the address and bind the reference to the scope if it doesn't already have one
      return ref:new{name=r.name, type=r.type, scope=r.scope or found_scope}, v
    end
  elseif not expression.defined(v) then
    return v
  else
    if not r.type:includes(v) then
      error(("'%s' (%s) is not of type '%s'"):
        format(r.name, rima.repr(v), r.type:describe(r.name)), 0)
    end
    return v
  end
end


function ref.proxy_mt.__type(r, S)
  -- look the ref up in the scope
  local e = scope.lookup(S, r.name, r.scope)
  if not e or e.hidden or not object.isa(e.value, undefined_t) then
    error(("No type information available for '%s'"):format(r.name))
  else
    return e.value
  end
end


-- Setting ---------------------------------------------------------------------

function ref.proxy_mt.__set(r, t, v)
  local name = r.name
  local cv = t[name]
  if cv then
    error(("error setting '%s' to %s: field already exists (%s)"):
      format(name, rima.repr(v), rima.repr(cv)), 0)
  else
    t[name] = v
  end
end


-- Operators -------------------------------------------------------------------

ref.proxy_mt.__add = expression.proxy_mt.__add
ref.proxy_mt.__sub = expression.proxy_mt.__sub
ref.proxy_mt.__unm = expression.proxy_mt.__unm
ref.proxy_mt.__mul = expression.proxy_mt.__mul
ref.proxy_mt.__div = expression.proxy_mt.__div
ref.proxy_mt.__pow = expression.proxy_mt.__pow
ref.proxy_mt.__call = expression.proxy_mt.__call
ref.proxy_mt.__index = expression.proxy_mt.__index
ref.proxy_mt.__newindex = expression.proxy_mt.__newindex


-- EOF -------------------------------------------------------------------------

