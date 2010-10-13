-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local assert, ipairs, type = assert, ipairs, type

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


local function make_math_function(name)
  local f = assert(math[name], "The math function does not exist")
  local op = object:new({ precedence=0 }, name) 

  op.__eval = function(args, S)
    args = proxy.O(args)
    local r = core.eval(args[1], S)
    if type(r) == "number" then
      return f(r)
    else
      return expression:new(op, r)
    end
  end

  op.__repr = function(args, format)
    local ff = format.format
    if ff == "latex" then
      local o = object.type(args)
      args = proxy.O(args)
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
      return object.type(args).."("..lib.concat_repr(proxy.O(args), format)..")"
    end
  end

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

