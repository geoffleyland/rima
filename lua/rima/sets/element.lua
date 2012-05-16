-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local setmetatable = setmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")

local typeinfo = object.typeinfo

module(...)


-- Elements -------------------------------------------------------------------

element = object:new_class(_M, "element")
proxy_mt = setmetatable({}, element)

function element:new(exp, key, value)
  return proxy:new(object.new(self, { exp=exp, key=key, value=value }), proxy_mt)
end


function element:key() return proxy.O(self).key end
function element:value() return proxy.O(self).value end
function element:expression() return proxy.O(self).exp end

function element:display()
  self = proxy.O(self)
  local v = self.value
  if v then
    local t = typeinfo(v)
    if not t.undefined_t and not t.table then
      return v
    end
  end
  return self.key
end


function element:__eval(S)
  local s = proxy.O(self)
  local value, type, addr = core.eval(s.exp, S)
  if value == s.exp then
    return self
  end
  if core.defined(value) then value = addr or s.exp end
  return element:new(value, s.key, s.value)
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
  if not typeinfo(a).element then return a end
  local e = proxy.O(a)
  local v = e.value
  if typeinfo(v).undefined_t then return e.exp end
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

