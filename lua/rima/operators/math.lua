-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local math = require("math")
local assert, ipairs, type = assert, ipairs, type

local object = require("rima.object")
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

  op.eval = function(op, S, args)
    local r = expression.eval(args[1], S)
    if type(r) == "number" then
      return f(r)
    else
      return expression:new(op, r)
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

