-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local assert, error, ipairs, type = assert, error, ipairs, type

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")
local rima = rima

module(...)

-- Math functions --------------------------------------------------------------

local math_functions =
{
  "exp", "log", "log10",
  "sin", "asin", "cos", "acos", "tan", "atan",
  "sinh", "cosh", "tanh",
  "sqrt",
}


local function math_repr(args, format)
  local o = object.typename(args)
  args = proxy.O(args)
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
  else
    return o.."("..lib.concat_repr(args, format)..")"
  end
end


local function math_diff(args, v)
  local o = object.typename(args)
  args = proxy.O(args)
  local a = args[1]

  local dadv = core.diff(a, v)
  if dadv == 0 then return 0 end
  
  if o == "exp" then
    return dadv * rima.exp(a)
  elseif o == "log" then
    return dadv / a 
  elseif o == "log10" then
    return dadv / (math.log(10) * a)
  elseif o == "sin" then
    return dadv * rima.cos(a)
  elseif o == "cos" then
    return -dadv * rima.sin(a)
  elseif o == "sqrt" then
    return dadv * 0.5 * a ^ (-0.5)
  else
    error("Can't differentiate "..o, 0)
  end
end


local function make_math_function(name)
  local f = assert(math[name], "The math function does not exist")
  local op = expression:new_type({ precedence=0 }, name) 

  op.__eval = function(args, S)
    args = proxy.O(args)
    local r = core.eval(args[1], S)
    if type(r) == "number" then
      return f(r)
    else
      return expression:new(op, r)
    end
  end

  op.__repr = math_repr
  op.__diff = math_diff

  rima[name] = function(e)
    if type(e) == "number" then
      return f(e)
    else
      return expression:new(op, e)
    end
  end
end


for _, name in ipairs(math_functions) do
  make_math_function(name)
end


-- EOF -------------------------------------------------------------------------

