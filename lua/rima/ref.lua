-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error, pcall = error, pcall
local ipairs, rawget, require, type, unpack = ipairs, rawget, require, type, unpack
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

local object = require("rima.object")
local proxy = require("rima.proxy")
local args = require("rima.args")
local undefined_t = require("rima.types.undefined_t")
require("rima.private")
local rima = rima

module(...)

local scope = require("rima.scope")
local expression = require("rima.expression")
local iteration = require("rima.iteration")
local address = require("rima.address")

-- References to values --------------------------------------------------------

local ref = object:new(_M, "ref")
ref_proxy_mt = setmetatable({}, ref)

function ref:new(r)
  local fname, usage = "rima.ref:new", "new(r: {name, address, type, scope})"
  args.check_type(r, "r", "table", usage, fname)
  args.check_type(r.name, "r.name", "string", usage, fname)
  args.check_types(r.type, "r.type", {"nil", {undefined_t, "type"}}, usage, fname)
  args.check_types(r.scope, "r.scope", {"nil", {scope, "scope" }}, usage, fname)
  args.check_types(r.address, "r.address", {"nil", "table", "address"}, usage, fname)

  r.type = r.type or undefined_t:new()

  return proxy:new(object.new(ref, { name=r.name, address=address:new(r.address), type=r.type, scope=r.scope }), ref_proxy_mt)
end

function ref.is_simple(r)
  r = proxy.O(r)
  return (not r.scope and r.address[1] == nil) and true or false
end


-- String Representation -------------------------------------------------------

function ref.dump(r)
  -- possibly have a way of showing that a variable is bound?
  r = proxy.O(r)
  return "ref("..r.name..r.address:dump()..")"
end

function ref.__tostring(r)
  -- possibly have a way of showing that a variable is bound?
  r = proxy.O(r)
  return r.name..rima.tostring(r.address)
end

ref_proxy_mt.__tostring = ref.__tostring

function ref.describe(r)
  r = proxy.O(r)
  return r.type:describe(r.name)
end


-- Evaluation ------------------------------------------------------------------

function ref.eval(r, S)
  local R = proxy.O(r)

  -- evaluate the address of the ref if there is one
  local new_address = R.address:eval(S)
  
  -- look the ref up in the scope
  local e, found_scope = scope.lookup(S, R.name, R.scope)
  if not e then                                 -- remain unbound
    return ref:new{name=R.name, address=new_address, type=R.type, scope=R.scope}
  end

  -- evaluate the result of the lookup - it might be an expression, or another ref
  local status, v = pcall(function() return expression.eval(e, S) end)
  if not status then
    error(("error evaluating '%s' as '%s':\n  %s"):
      format(R.name, rima.tostring(e), v:gsub("\n", "\n  ")), 0)
  end

  if object.isa(v, undefined_t) then
    if not v:includes(R.type) and not R.type:includes(v) then
      error(("the type of '%s' (%s) and the type of the reference (%s) are mutually exclusive"):
        format(R.name, v:describe(R.name), R.type:describe(R.name)), 0)
    else
      -- update the address and bind the reference to the scope if it doesn't already have one
      return ref:new{name=R.name, address=new_address, type=R.type, scope=R.scope or found_scope}
    end
  elseif not expression.defined(v) then
    return v
  else
    if not R.type:includes(v) then
      error(("'%s' (%s) is not of type '%s'"):
        format(R.name, rima.tostring(v), R.type:describe(R.name)), 0)
    else
      v = proxy.O(v)
      if type(v) == "table" and v.handle_address then
        local status, v = pcall(function() return v:handle_address(S, new_address) end)
        if not status then
          error(("error evaluating '%s' as '%s':\n  %s"):
            format(R.name, rima.tostring(e), v:gsub("\n", "\n  ")), 0)
        end
        return v
      end
      for _, i in ipairs(new_address) do
        if object.isa(i, iteration.element) then
          v = v[1] and v[i.index] or v[i.key]
        else
          v = v[i]
        end
        if not v then
          return ref:new{name=R.name, address=new_address, type=R.type, scope=R.scope or found_scope}
        end
      end
    end
    return v
  end
end


-- Setting ---------------------------------------------------------------------

function ref.set(r, t, v)
  local r = proxy.O(r)
  local name = r.name
  local address = r.address

  function s(t, name, i)
    if object.type(name) == "element" then name = name.key end
    local cv = t[name]
    if #address == i then
      if cv then
        error(("error setting '%s' to %s: field already exists (%s)"):
          format(rima.tostring(r), rima.tostring(v), rima.tostring(cv)), 0)
      end
      t[name] = v
    else
      if cv and type(cv) ~= "table" then
        error(("error setting '%s' to %s: field is not a table (%s)"):
          format(rima.tostring(r), rima.tostring(v), rima.tostring(cv)), 0)
      end
      if not cv then t[name] = {} end
      s(t[name], address[i+1], i+1)
    end
  end
  s(t, name, 0)
end

-- Operators -------------------------------------------------------------------

function ref.__add(a, b)
  return expression.__add(a, b)
end

function ref.__sub(a, b)
  return expression.__sub(a, b)
end

function ref.__unm(a)
  return expression.__unm(a)
end

function ref.__mul(a, b)
  return expression.__mul(a, b)
end

function ref.__div(a, b)
  return expression.__div(a, b)
end

function ref.__pow(a, b)
  return expression.__pow(a, b)
end

function ref.__call(...)
  return expression.__call(...)
end

ref_proxy_mt.__add = ref.__add
ref_proxy_mt.__sub = ref.__sub
ref_proxy_mt.__unm = ref.__unm
ref_proxy_mt.__mul = ref.__mul
ref_proxy_mt.__div = ref.__div
ref_proxy_mt.__pow = ref.__pow
ref_proxy_mt.__call = ref.__call

--[[
function ref_proxy_mt.__index(r, i)
  return expression:new(addresss, r, i)
end

--]]
function ref_proxy_mt.__index(r, i)
  r = proxy.O(r)
  return ref:new{name=r.name, address=r.address+i, type=r.type, scope=r.scope}
end


-- EOF -------------------------------------------------------------------------

