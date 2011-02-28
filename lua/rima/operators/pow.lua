-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error = error
local math = require("math")

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")
local mul = require("rima.operators.mul")
local rima = rima

module(...)


-- Exponentiation --------------------------------------------------------------

local pow = object:new(_M, "pow")
pow.precedence = 0


-- String Representation -------------------------------------------------------

function pow.__repr(args, format)
  args = proxy.O(args)
  local base, exponent = args[1], args[2]
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


-- Evaluation ------------------------------------------------------------------

function pow.__eval(args, S)
  args = proxy.O(args)
  local base, exponent = core.eval(args[1], S), core.eval(args[2], S)
  
  local base_is_number = type(base) == "number"
  
  if base_is_number then
    if base == 0 then
      return 0
    elseif base == 1 then
      return 1
    end
  end

  if type(exponent) == "number" then
    if exponent == 0 then
      return 1
    elseif exponent == 1 then
      return base
    elseif not_base_is_number then
      return expression:new(mul, {exponent, base})
    end
 end

  return base ^ exponent
end


-- Automatic differentiation ---------------------------------------------------

function pow.__diff(args, v)
  args = proxy.O(args)
  local base, exponent = args[1], args[2]

  local base_is_number = type(base) == "number"

  if type(exponent) == "number" then
    if base_is_number then return 0 end
    return core.diff(base, v) * exponent * base ^ (exponent - 1)
  end

  if base_is_number then
    return core.diff(exponent, v) * math.log(base) * base ^ exponent
  end
  
  return core.diff(exponent * rima.log(base), v) * base ^ exponent
end


-- EOF -------------------------------------------------------------------------

