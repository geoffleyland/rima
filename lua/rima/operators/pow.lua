-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")
local mul = require("rima.operators.mul")
local ops = require("rima.operations")


------------------------------------------------------------------------------

local pow = operator:new_class({}, "pow")
pow.precedence = 0


------------------------------------------------------------------------------

function pow:__repr(format)
  local base, exponent = self[1], self[2]
  local repr = lib.repr
  local paren = core.parenthise
  local prec = pow.precedence

  local ff = format.format
  if ff == "dump" then
    return "^("..repr(base, format)..", "..repr(exponent, format)..")"
  elseif ff == "latex" then
    return "{"..paren(base, format, prec).."}^{"..repr(exponent, format).."}"
  else
    return paren(base, format, prec).."^"..paren(exponent, format, prec)
  end
end


------------------------------------------------------------------------------

function pow:simplify()
  local base, exponent = self[1], self[2]

  if base == 0 then
    return 0
  elseif base == 1 or exponent == 0 then
    return 1
  elseif exponent == 1 then
    return base
  elseif type(exponent) == "number" then
    return mul:new{{ exponent, base }}
  else
    return self
  end
end


function pow:__eval(...)
  local t1, t2 = self[1], self[2]
  local base, exponent = core.eval(t1, ...), core.eval(t2, ...)
  if base == t1 and exponent == t2 then
    return self
  elseif type(base) == "number" and type(exponent) == "number" then
    return base ^ exponent
  else
    return pow:new{ base, exponent }
  end
end


------------------------------------------------------------------------------

local log
function pow:__diff(v)
  log = log or require"rima.operators.math".log

  local base, exponent = self[1], self[2]

  local base_is_number = type(base) == "number"

  if type(exponent) == "number" then
    if base_is_number then return 0 end
    return core.eval(ops.mul(exponent, core.diff(base, v), ops.pow(base, exponent - 1)))
  end

  if base_is_number then
    return core.eval(ops.mul(core.diff(exponent, v), math.log(base), ops.pow(base, exponent)))
  end

  return core.eval(ops.mul(core.diff(ops.mul(exponent, log(base)), v), ops.pow(base, exponent)))
end


------------------------------------------------------------------------------

return pow

------------------------------------------------------------------------------

