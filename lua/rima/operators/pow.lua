-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error = error

local rima = require("rima")
local tests = require("rima.tests")
local types = require("rima.types")
require("rima.private")
local expression = rima.expression

module(...)

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


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(isa(pow:new(), pow), "isa(pow, pow:new())")
  T:equal_strings(type(pow:new()), "pow", "type(pow:new()) == 'pow'")

--  T:expect_error(function() pow:check(1) end, "expecting a table for 'args', got 'number'") 
--  T:expect_error(function() pow:check({}) end,
--    "expecting expressions for base and exponent, got 'nil' %(nil%) and 'nil' %(nil%)")
--  T:expect_ok(function() pow:check({1, 2}) end) 
--  T:expect_error(function() pow:check({{1, 2}}) end,
--    "expecting expressions for base and exponent, got 'table: [^']+' %(table%) and 'nil' %(nil%)") 
--  T:expect_error(function() pow:check({"hello"}) end,
--    "expecting expressions for base and exponent, got 'hello' %(string%) and 'nil' %(nil%)") 

  local a, b = rima.R"a, b"
  local S = rima.scope.create{ a = 5 }
  T:equal_strings(expression.dump(a^2), "^(ref(a), number(2))")
  T:equal_strings(expression.eval(a^2, S), 25)
  T:equal_strings(expression.dump(2^a), "^(number(2), ref(a))")
  T:equal_strings(expression.eval(2^a, S), 32)

  -- Identities
  T:equal_strings(expression.eval(0^b, S), 0)
  T:equal_strings(expression.eval(1^b, S), 1)
  T:equal_strings(expression.eval(b^0, S), 1)
  T:equal_strings(expression.dump(expression.eval(b^1, S)), "ref(b)")

  -- Tests including add and mul are in rima.expression

  return T:close()
end


-- EOF -------------------------------------------------------------------------

