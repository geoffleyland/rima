-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")
local ops = require("rima.operations")

local rmath = {}

------------------------------------------------------------------------------

local math_functions =
{
  "exp", "log", "log10",
  "sin", "asin", "cos", "acos", "tan", "atan",
  "sinh", "cosh", "tanh",
  "sqrt",
}


local function math_repr(args, format)
  local o = object.typename(args)
  local ff = format.format
  if ff == "latex" then
    if o == "sqrt" then
      return "\\sqrt{"..lib.repr(args[1], format).."}"
    elseif o == "exp" then
      return "e^{"..lib.repr(args[1], format).."}"
    elseif o == "log" then
      return "\\ln "..core.parenthise(args[1], format, 1)
    elseif o == "log10" then
      return "\\log_{10} "..core.parenthise(args[1], format, 1)
    else
      if #args > 1 then
        return "\\"..object.type(args).."("..lib.concat_repr(args, format)..")"
      else
        return "\\"..object.type(args).." "..core.parenthise(args[1], format, 1)
      end
    end
  elseif ff == "lua" then
    return "math."..o.."("..lib.concat_repr(args, format)..")"
  else
    return o.."("..lib.concat_repr(args, format)..")"
  end
end


local function math_diff(args, v)
  local o = object.typename(args)
  local a = args[1]

  local dadv = core.diff(a, v)
  if dadv == 0 then return 0 end
  
  if o == "exp" then
    return ops.mul(dadv, rmath.exp(a))
  elseif o == "log" then
    return ops.div(dadv, a)
  elseif o == "log10" then
    return ops.div(dadv, ops.mul(math.log(10), a))
  elseif o == "sin" then
    return ops.mul(dadv, rmath.cos(a))
  elseif o == "cos" then
    return ops.mul(-1, dadv, rmath.sin(a))
  elseif o == "sqrt" then
    return mul:new(dadv, 0.5, ops.pow(a, -0.5))
  else
    error("Can't differentiate "..o, 0)
  end
end


local function make_math_function(name)
  local f = assert(math[name], "The math function does not exist")
  local op = operator:new_class({ precedence = 0 }, name)

  op.simplify = function(self)
    if type(self[1]) == "number" then
      return f(self[1])
    else
      return self
    end
  end

  op.__eval = function(self, ...)
    local e = core.eval(self[1], ...)
    if e == self[1] then return self end
    return op:new{e}
  end

  op.__repr = math_repr
  op.__diff = math_diff

  rmath[name] = function(e)
    return op:new{e}
  end
end


for _, name in ipairs(math_functions) do
  make_math_function(name)
end


------------------------------------------------------------------------------

return rmath

------------------------------------------------------------------------------

