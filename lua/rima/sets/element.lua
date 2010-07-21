-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")

module(...)


-- Elements -------------------------------------------------------------------

element = object:new(_M, "element")

function element:new(base, exp, key, value, set)
  return object.new(self, { base_=base, exp_=exp, key_=key, value_=value, set_=set })
end


function element:key() return self.key_ end
function element:value() return self.value_ end
function element:expression() return self.exp_ end


function element:__eval(S, eval)
  local exp = eval(self.exp_, S)
  return element:new(self.base_, exp, self.key_, self.value_, self.set_)
end


function element:__defined()
  return core.defined(self.exp_)
end


function element:__repr(format)
  if format.dump then
    return ("element(%s, key=%s, value=%s)"):
      format(lib.repr(self.exp_, format), lib.repr(self.key_, format), lib.repr(self.value_, format))
  else
    return lib.repr(self.exp_, format)
  end
end
element.__tostring = lib.__tostring


-- Operators -------------------------------------------------------------------

local function extract(a)
  if element:isa(a) then return a.value_ end
  return a
end

function element.__add(a, b) return extract(a) + extract(b) end
function element.__sub(a, b) return extract(a) - extract(b) end
function element.__mul(a, b) return extract(a) * extract(b) end
function element.__div(a, b) return extract(a) / extract(b) end
function element.__pow(a, b) return extract(a) ^ extract(b) end

function element:__unm() return -self.value_ end

-- Elements don't have an __index, because indexing is more complex than
-- indexing the element's value - there might be default values to deal with.
-- The rewrite might fix this.


-- EOF -------------------------------------------------------------------------

