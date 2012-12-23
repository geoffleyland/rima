-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")


------------------------------------------------------------------------------

local mod = expression:new_type({}, "mod")
mod.precedence = 3


------------------------------------------------------------------------------

function mod:__repr(format)
  local terms = proxy.O(self)
  local numerator, denominator = terms[1], terms[2]
  local repr = lib.repr
  local paren = core.parenthise
  local prec = mod.precedence

  local ff = format.format
  if ff == "dump" then
    return "%("..repr(numerator, format)..", "..repr(denominator, format)..")"
  elseif ff == "latex" then
    return "{"..paren(numerator, format, prec).."}\\bmod{"..paren(denominator, format, prec).."}"
  else
    return paren(numerator, format, prec).."%"..paren(denominator, format, prec)
  end
end


------------------------------------------------------------------------------

function mod:simplify()
  if proxy.O(self)[1] == 0 then
    return 0
  else
    return self
  end
end


function mod:__eval(...)
  local terms = proxy.O(self)
  local t1, t2 = terms[1], terms[2]
  local numerator, denominator = core.eval(t1, ...), core.eval(t2, ...)

  if numerator == t1 and denominator == t2 then
    return self
  else
    return numerator % denominator
  end
end


------------------------------------------------------------------------------

return mod

------------------------------------------------------------------------------

