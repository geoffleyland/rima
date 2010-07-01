-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")

module(...)


-- Iterators -------------------------------------------------------------------

iterator = object:new(_M, "iterator")

function iterator:new(base, exp, key, value, set)
  return object.new(self, { base=base, exp=exp, key=key, value=value, set=set })
end


function iterator:__eval(S, eval)
  local exp = eval(self.exp, S)
  if core.defined(exp) then
    return exp
  else
    return iterator:new(self.base, exp, self.key, self.value, self.set)
  end
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

-- these being functions rather than direct assignments are a stopgap until
-- I can get some cyclic requires fixed.
iterator.__add = function(...) return expression.proxy_mt.__add(...) end
iterator.__sub = function(...) return expression.proxy_mt.__sub(...) end
iterator.__unm = function(...) return expression.proxy_mt.__unm(...) end
iterator.__mul = function(...) return expression.proxy_mt.__mul(...) end
iterator.__div = function(...) return expression.proxy_mt.__div(...) end
iterator.__pow = function(...) return expression.proxy_mt.__pow(...) end
iterator.__call = function(...) return expression.proxy_mt.__call(...) end
iterator.__index = function(...) return expression.proxy_mt.__index(...) end
iterator.__newindex = function(...) return expression.proxy_mt.__newindex(...) end


-- EOF -------------------------------------------------------------------------

