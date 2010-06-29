-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, loadstring, pcall, setfenv = ipairs, loadstring, pcall, setfenv

require("rima.ref")
local lib = require("rima.lib")
local expression = require("rima.expression")
require("rima.public")
local rima = rima

module(...)


-- Tests -----------------------------------------------------------------------

local function load_expression(T, s, variables)
  local fenv = { rima=rima }
  for _, n in ipairs(variables) do
    fenv[n] = rima.R(n)
  end
  local f, m = loadstring("return "..s)
  if not f then
    T:test(false, nil, ("Couldn't load '%s': %s"):format(s, m), 4)
  else
    setfenv(f, fenv)
    local status, e = pcall(f)
    if not status then
      T:test(false, nil, ("Couldn't execute '%s': %s"):format(s, e), 4)
    else
      return e
    end
  end
end


local function expression_tester(T, variables, scope)
  local V = {}
  for n in variables:gmatch("[%a_][%w_]*") do
    V[#V+1] = n
  end
  local S = rima.scope.new(scope or {})

  return function(t)
    local e = load_expression(T, t[1], V)
    if e then
      if t.S then
        T:check_equal(e, t.S, "unevaluated", 1)
      end
      if t.D then
        T:check_equal(lib.dump(e), t.D, "unevaluated dump", 1)
      end
      if t.ES then
        T:check_equal(expression.eval(e, S), t.ES, "evaluated", 1)
      end
      if t.ED then
        T:check_equal(lib.dump(expression.eval(e, S)), t.ED, "evaluated dump", 1)
      end
      
      local s2 = rima.repr(e, { readable=true })
      local e2 = load_expression(T, s2, V)
      if e2 then
        local s3 = rima.repr(e2, { readable=true })
        T:check_equal(s3, s2, "rereading unevaluated", 1)
        T:check_equal(expression.eval(e2, S), expression.eval(e, S), "rereading evaluated", 1)
      end
    end
  end
end


return expression_tester


-- EOF -------------------------------------------------------------------------

