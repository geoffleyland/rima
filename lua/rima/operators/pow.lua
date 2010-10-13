-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error = error

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")

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
  
  if type(exponent) == "number" then
    if exponent == 0 then
      return 1
    elseif exponent == 1 then
      return base
    end
  end
  
  if type(base) == "number" then
    if base == 0 then
      return 0
    elseif base == 1 then
      return 1
    end
  end

  return base ^ exponent
end


-- EOF -------------------------------------------------------------------------

