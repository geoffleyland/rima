-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, pairs, rawget, rawset, require, setmetatable =
      ipairs, pairs, rawget, rawset, require, setmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")

module(...)

local add_op = require("rima.operators.add")
local mul_op = require("rima.operators.mul")
local pow_op = require("rima.operators.pow")
local call_op = require("rima.operators.call")
local index = require("rima.index")


-- Constructor -----------------------------------------------------------------

local expression = object:new(_M, "expression")
expression.proxy_mt = setmetatable({}, expression)


function expression:new(x, ...)
  local e = {...}
  if x and rawget(x, "construct") then e = x.construct(e) end
  for k, v in pairs(self.proxy_mt) do if not(rawget(x, k)) then rawset(x, k, v) end end
  return proxy:new(object.new(self, e), x)
end


function expression:new_table(x, t)
  local e
  if x and rawget(x, "construct") then
    e = x.construct(t)
  else
    e = {}
    for i, a in ipairs(t) do e[i] = a end
  end

  for k, v in pairs(self.proxy_mt) do if not(rawget(x, k)) then rawset(x, k, v) end end
  return proxy:new(object.new(self, e), x)
end


-- String representation -------------------------------------------------------

function proxy_mt.__repr(e, format)
  return object.type(e).."("..lib.concat_repr(proxy.O(e), format)..")"
end
proxy_mt.__tostring = lib.__tostring


-- Introspection? --------------------------------------------------------------

function proxy_mt.__list_variables(args, S, list)
  for _, a in ipairs(proxy.O(args)) do
    core.list_variables(a, S, list)
  end
end


-- Overloaded operators --------------------------------------------------------

function proxy_mt.__add(a, b)
  return expression:new(add_op, {1, a}, {1, b})
end

function proxy_mt.__sub(a, b)
  return expression:new(add_op, {1, a}, {-1, b})
end

function proxy_mt.__unm(a)
  return expression:new(add_op, {-1, a})
end

function proxy_mt.__mul(a, b, c)
  return expression:new(mul_op, {1, a}, {1, b})
end

function proxy_mt.__div(a, b)
  return expression:new(mul_op, {1, a}, {-1, b})
end

function proxy_mt.__pow(a, b)
  return expression:new(pow_op, a, b)
end

function proxy_mt.__call(...)
  return expression:new(call_op, ...)
end

function proxy_mt.__index(...)
  return index:new(...)
end

--[[
function expression.proxy_mt.__index(r, i)
  local e = expression:new(operators.index, r, i)
  local f = core.eval(e)
  if not f or (object.type(f) == "table" and not getmetatable(f)) then
    return e
  else
    return f
  end
end


function expression.proxy_mt.__newindex(e, i, v)
  local err
  local R = proxy.O(e)
  if object.type(e) == "ref" then
    if R.scope then
      proxy.O(R.scope).newindex(R.scope, R.name, nil, i, v)
    else
      err = "is not bound to a scope"
    end
  elseif object.type(e) == "index" then
    local r2, address = R[1], R[2]
    if object.type(r2) == "ref" then
      local R2 = proxy.O(r2)
      if R2.scope then
        proxy.O(R2.scope).newindex(R2.scope, R2.name, address, i, v)
      else
        err = "is not bound to a scope"
      end
    else
      err = "isn't an expression that can be set"
    end
  else
    err = "isn't an expression that can be set"
  end
  if err then
    error(("expression new index: error setting '%s' to %s: '%s' %s"):
      format(lib.repr(e[i]), lib.repr(v), lib.repr(e), err), 0)
  end
end
--]]

-- EOF -------------------------------------------------------------------------

