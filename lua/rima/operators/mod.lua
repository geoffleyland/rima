-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")


------------------------------------------------------------------------------

local mod = operator:new_class({}, "mod")
mod.precedence = 3


------------------------------------------------------------------------------

function mod:__repr(format)
  local numerator, denominator = self[1], self[2]
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
  if self[1] == 0 then
    return 0
  else
    return self
  end
end


function mod:__eval(...)
  local t1, t2 = self[1], self[2]
  local numerator, denominator = core.eval(t1, ...), core.eval(t2, ...)

  if numerator == t1 and denominator == t2 then
    return self
  elseif type(numerator) == "number" and type(denominator) == "number" then
    return numerator % denominator
  else
    return mod:new{ numerator, denominator }
  end
end


------------------------------------------------------------------------------

return mod

------------------------------------------------------------------------------

