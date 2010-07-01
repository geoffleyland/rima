-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error, ipairs, require = error, ipairs, require
local getmetatable = getmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local types = require("rima.types")
local rima = rima

module(...)

local scope = require("rima.scope")
local operators = require("rima.operators")
local expression = require("rima.expression")

-- Getting a linear form -------------------------------------------------------

function linearise(l, S)
  local constant, terms = 0, {}
  local fail = false

  local function add_variable(n, v, coeff)
    local s = rima.repr(n)
    if terms[s] then
      error(("the reference '%s' appears more than once"):format(s), 0)
    end
    local t = expression.type(v, S)
    if not rima.types.number_t:isa(t) then
      error(("expecting a number type for '%s', got '%s'"):format(s, t:describe(s)), 0)
    end
    terms[s] = { variable=v, coeff=coeff, lower=t.lower, upper=t.upper, integer=t.integer }
  end

  if object.type(l) == "number" then
    constant = l
  elseif object.type(l) == "ref" then
    add_variable(l, l, 1)
  elseif object.type(l) == "index" then
    add_variable(l, l, 1)
  elseif object.type(l) == "iterator" then
    add_variable(l.exp, l.exp, 1)
  elseif getmetatable(l) == operators.add then
    for i, a in ipairs(proxy.O(l)) do
      a = proxy.O(a)
      local c, x = a[1], a[2]
      if object.type(x) == "number" then
        if i ~= 1 then
          error(("term %d is constant (%s).  Only the first term should be constant"):
            format(i, rima.repr(x)), 0)
        end
        if constant ~= 0 then
          error(("term %d is constant (%s), and so is an earlier term.  There can only be one constant in the expression"):
            format(i, rima.repr(x)), 0)
        end
        constant = c * x
      elseif object.type(x) == "ref" then
        add_variable(x, x, c)
      elseif object.type(x) == "index" then
        add_variable(x, x, c)
      elseif object.type(x) == "iterator" then
        add_variable(x.exp, x.exp, c)
      else
        error(("term %d is not linear (got '%s', %s)"):format(i, rima.repr(x), object.type(x)), 0)
      end
    end
  else
    error("the expression does not evaluate to a sum of terms", 0)
  end
  
  return constant, terms
end


-- EOF -------------------------------------------------------------------------

