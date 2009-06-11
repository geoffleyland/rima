-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error, require = error, require

require("rima.private")
local rima = rima

module(...)

local expression = require("rima.expression")

-- Exponentiation --------------------------------------------------------------

local pow = rima.object:new(_M, "pow")


-- Argument Checking -----------------------------------------------------------

function pow:check(a)
  if not expression.result_type_match(a[1], types.number_t) then
    error(("base (%s) of power expression '%s' is not in %s"):
      format(rima.tostring(a[1]), _tostring(args), rima.tostring(types.number_t)), 0)
  end
  if not expression.result_type_match(a[2], types.number_t) then
    error(("base (%s) of power expression '%s' is not in %s"):
      format(rima.tostring(a[2]), _tostring(args), rima.tostring(types.number_t)), 0)
  end
end


function pow:result_type(args)
  return types.number_t
end


-- String Representation -------------------------------------------------------

function pow:dump(args)
  local base, exponent = args[1], args[2]
  return "^("..expression.dump(base)..", "..expression.dump(exponent)..")"
end

function pow:_tostring(args)
  local base, exponent = args[1], args[2]
  return expression.parenthise(base, self.precedence).."^"..expression.parenthise(exponent, self.precedence)
end


-- Evaluation ------------------------------------------------------------------

function pow:eval(S, args)
  local base, exponent = expression.eval(args[1], S), expression.eval(args[2], S)
  
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

