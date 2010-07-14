-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")

module(...)


-- Iterators -------------------------------------------------------------------

iterator = object:new(_M, "iterator")

function iterator:new(base, exp, key, value, set)
  return object.new(self, { base=base, exp=exp, key=key, value=value, set=set })
end


function iterator:__eval(S, eval)
  local exp = eval(self.exp, S)
  return iterator:new(self.base, exp, self.key, self.value, self.set)
end


function iterator:__defined()
  return core.defined(self.exp)
end


function iterator:__repr(format)
  if format.dump then
    return ("iterator(%s, key=%s, value=%s)"):
      format(lib.repr(self.exp, format), lib.repr(self.key, format), lib.repr(self.value, format))
  else
    return lib.repr(self.exp, format)
  end
end
iterator.__tostring = lib.__tostring


-- Operators -------------------------------------------------------------------

local function extract(a)
  if iterator:isa(a) then return a.value end
  return a
end

function iterator.__add(a, b) return extract(a) + extract(b) end
function iterator.__sub(a, b) return extract(a) - extract(b) end
function iterator.__mul(a, b) return extract(a) * extract(b) end
function iterator.__div(a, b) return extract(a) / extract(b) end
function iterator.__pow(a, b) return extract(a) ^ extract(b) end

function iterator:__unm() return -self.value end
function iterator:__index(i) return self.value[i] end


-- EOF -------------------------------------------------------------------------

