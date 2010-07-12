-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error, getmetatable, ipairs, pcall, require =
      error, getmetatable, ipairs, pcall, require

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local types = require("rima.types")

module(...)

local scope = require("rima.scope")
local operators = require("rima.operators")

-- Getting a linear form -------------------------------------------------------

function _linearise(l, S)

  local constant, terms = 0, {}
  local fail = false

  local function add_variable(n, v, coeff)
    local s = lib.repr(n)
    if terms[s] then
      error(("the reference '%s' appears more than once"):format(s), 0)
    end
    local t = core.type(v, S)
    if not types.number_t:isa(t) then
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
            format(i, lib.repr(x)), 0)
        end
        if constant ~= 0 then
          error(("term %d is constant (%s), and so is an earlier term.  There can only be one constant in the expression"):
            format(i, lib.repr(x)), 0)
        end
        constant = c * x
      elseif object.type(x) == "ref" then
        add_variable(x, x, c)
      elseif object.type(x) == "index" then
        add_variable(x, x, c)
      elseif object.type(x) == "iterator" then
        add_variable(x.exp, x.exp, c)
      else
        error(("term %d is not linear (got '%s', %s)"):format(i, lib.repr(x), object.type(x)), 0)
      end
    end
  else
    error("the expression does not evaluate to a sum of terms", 0)
  end
  
  return constant, terms
end


function linearise(e, S)
  local l = core.eval(e, S)
  local status, constant, terms = pcall(_linearise, l, S)
  if not status then
    error(("linear form: '%s':\n  %s"):format(lib.repr(l), constant:gsub("\n", "\n    ")), 0)
  end
  return constant, terms
end


-- EOF -------------------------------------------------------------------------

