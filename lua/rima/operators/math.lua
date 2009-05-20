local assert, type = assert, type
local ipairs = ipairs
local math = require("math")

local rima = require("rima")
local object = require("rima.object")
local tests = require("rima.tests")

module(...)

-- Math functions --------------------------------------------------------------

local math_functions =
{
  "exp", "log", "log10",
  "sin", "asin", "cos", "acos", "tan", "atan",
  "sinh", "cosh", "tanh",
  "sqrt",
}

local function eval(op, S, args)
  local r = rima.expression.eval(args[1], S)
  if type(r) == "number" then
    return op.func(r)
  else
    return rima.expression:new(op, r)
  end
end

local function make_math_function(name)
  local f = assert(math[name], "The math function does not exist")
  local op = object:new({ precedence = 0, func = f, eval=eval }, name) 

  rima[name] = function(e)
    if type(e) == "number" then
      return f(e)
    else
      return rima.expression:new(op, e)
    end
  end
end

for _, name in ipairs(math_functions) do
  make_math_function(name)
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  local a, b  = rima.R"a, b"

  T:equal_strings(rima.exp(1), math.exp(1))

  T:equal_strings(rima.expression.dump(rima.exp(a)), "exp(ref(a))")
  local S = rima.scope.new()
  T:equal_strings(rima.expression.eval(rima.exp(a), S), "exp(a)")
  S.a = 4
  T:equal_strings(rima.expression.eval(rima.sqrt(a), S), 2)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

