-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local setmetatable = setmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local undefined_t = require("rima.types.undefined_t")

module(...)


-- Elements -------------------------------------------------------------------

element = object:new(_M, "element")
proxy_mt = setmetatable({}, element)

function element:new(exp, key, value, set)
  return proxy:new(object.new(self, { exp=exp, key=key, value=value, set=set }), proxy_mt)
end


function element:key() return proxy.O(self).key end
function element:value() return proxy.O(self).value end
function element:expression() return proxy.O(self).exp end

function element:display()
  self = proxy.O(self)
  local v = self.value
  if v and not undefined_t:isa(v) and object.type(v) ~= "table" then
    return v
  else
    return self.key
  end
end


function element:__eval(S)
  self = proxy.O(self)
  local value, type, addr = core.eval(self.exp, S)
  if core.defined(value) then value = addr or self.exp end
  return element:new(value, self.key, self.value, self.set)
end


function element:__defined()
  local v = proxy.O(self).value
  return v ~= nil
end


function element:__arithmetic()
  return core.arithmetic(proxy.O(self).value)
end


function element:__repr(format)
  self = proxy.O(self)
  if format.format == "dump" then
    return ("element(%s, key=%s, value=%s)"):
      format(lib.repr(self.exp, format), lib.repr(self.key, format), lib.repr(self.value, format))
  else
    if core.arithmetic(self.value) then
      return lib.repr(self.value, format)
    else
      return lib.repr(self.exp, format)
    end
  end
end
proxy_mt.__tostring = lib.__tostring
element.__tostring = lib.__tostring


-- Operators -------------------------------------------------------------------

function element.extract(a)
  if not element:isa(a) then return a end
  local e = proxy.O(a)
  local v = e.value
  if undefined_t:isa(v) then return e.exp end
  return v
end


function proxy_mt.__add(a, b) return extract(a) + extract(b) end
function proxy_mt.__sub(a, b) return extract(a) - extract(b) end
function proxy_mt.__mul(a, b) return extract(a) * extract(b) end
function proxy_mt.__div(a, b) return extract(a) / extract(b) end
function proxy_mt.__pow(a, b) return extract(a) ^ extract(b) end

function proxy_mt:__unm() return -proxy.O(self).value end
function proxy_mt:__index(i) return proxy.O(self).exp[i] end


-- EOF -------------------------------------------------------------------------

