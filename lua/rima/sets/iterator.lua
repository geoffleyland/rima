-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local setmetatable = setmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")

module(...)


-- Iterators -------------------------------------------------------------------

iterator = object:new(_M, "iterator")
iterator.proxy_mt = setmetatable({}, iterator)

function iterator:new(base, exp, key, value, set)
  return proxy:new(object.new(self, { base=base, exp=exp, key=key, value=value, set=set }), proxy_mt)
end


function iterator:key() return proxy.O(self).key end
function iterator:value() return proxy.O(self).value end
function iterator:expression() return proxy.O(self).exp end


function proxy_mt:__eval(S, eval)
  self = proxy.O(self)
  local exp = eval(self.exp, S)
  return iterator:new(self.base, exp, self.key, self.value, self.set)
end


function proxy_mt:__defined()
  self = proxy.O(self)
  return core.defined(self.exp)
end


function proxy_mt:__repr(format)
  self = proxy.O(self)
  if format.dump then
    return ("iterator(%s, key=%s, value=%s)"):
      format(lib.repr(self.exp, format), lib.repr(self.key, format), lib.repr(self.value, format))
  else
    return lib.repr(self.exp, format)
  end
end
proxy_mt.__tostring = lib.__tostring


-- Operators -------------------------------------------------------------------

local function extract(a)
  if iterator:isa(a) then return proxy.O(a).value end
  return a
end

function proxy_mt.__add(a, b) return extract(a) + extract(b) end
function proxy_mt.__sub(a, b) return extract(a) - extract(b) end
function proxy_mt.__mul(a, b) return extract(a) * extract(b) end
function proxy_mt.__div(a, b) return extract(a) / extract(b) end
function proxy_mt.__pow(a, b) return extract(a) ^ extract(b) end

function proxy_mt:__unm() return -proxy.O(self).value end
function proxy_mt:__index(i) return proxy.O(self).value[i] end


-- EOF -------------------------------------------------------------------------

