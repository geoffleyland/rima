-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error = error
local ipairs = ipairs
local require, setmetatable, rawtype = require, setmetatable, type

local object = require("rima.object")
local proxy = require("rima.proxy")
local rima = rima

module(...)

local ref = require("rima.ref")
local operators = require("rima.operators")

-- Constructor -----------------------------------------------------------------

local expression = object:new(_M, "expression")
expression.proxy_mt = setmetatable({}, expression)

function expression:new(x, ...)
  local e = {...}
  e.op = x

--  e:check()
  return proxy:new(object.new(self, e), expression.proxy_mt)
end

function expression:new_table(x, t)
  local e = { op=x }
  for i, a in ipairs(t) do e[i] = a end

--  e:check()
  return proxy:new(object.new(self, e), expression.proxy_mt)
end


-- Argument Checking -----------------------------------------------------------

--[[
function expression:check()
  local m = rawtype(self.op) == "table" and self.op.check
  if m then
    return m(self.op, self.args)
  else
    return true
  end
end
--]]

-- Result Types ----------------------------------------------------------------

--[[
function expression.result_type_match(a, t)
  local r = result_type(a)
  return r:includes(t) or t:includes(r)
end

function expression.result_type(a)
  if rawtype(a) == "table" then
    local op, args = a.op, a.args
    if op and rawtype(args) == "table" then    -- this is an expression
      local m = rawtype(op) == "table" and op.result_type
      if m then                                 -- the operator can handle itself
        return m(op, args)
      elseif #args == 0 then                    -- looks like a literal
        return type(op) == "number" and rima.free() or types.undefined_t
      else                                      -- some kind of call
        error(("unable to determine the result type of '%s': the operator doesn't take arguments"):format(rima.tostring(a)), 0)
      end
    else                                        -- this is some other object.  Can it handle itself?
      local m = a.result_type
      if m then return m(a) end
    end
  end
  return type(op) == "number" and rima.free() or types.undefined_t
end
--]]

-- We want to avoid trying to index non-tables and directly indexing
-- references (which will lie and say they have everything)
local function get_field(e, f)
  return rawtype(e) == "table" and e[f]
end


-- String representation -------------------------------------------------------

function expression.dump(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "dump")
    if m then                                 -- the operator can handle itself
      return m(op, e)
    else
      return object.type(op).."("..rima.concat(e, ", ", dump)..")"
    end
  else                                        -- it's a literal
    local m = get_field(e, "dump")
    return m and m(e) or object.type(e).."("..rima.tostring(e)..")"
  end
end


function expression.proxy_mt.__tostring(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "_tostring")
    if m then                                 -- the operator can handle itself
      return m(op, e)
    else
      return object.type(op).."(".. rima.concat(e, ", ", rima.tostring)..")"
    end
  else                                        -- it's a literal
    local m = get_field(e, "_tostring")
    return m and m(e) or rima.tostring(e)
  end
end


function expression.parenthise(e, parent_precedence)
  parent_precedence = parent_precedence or 1
  local s = rima.tostring(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                    -- this is an expression
    local precedence = get_field(op, "precedence") or 1
    if precedence > parent_precedence then
      s = "("..s..")"
    end
  end
  return s
end


-- Status ----------------------------------------------------------------------

function expression.defined(e)
  return e and not isa(e, ref) and not isa(e, expression)
end


-- Evaluation ------------------------------------------------------------------

function expression.eval(e, S)
  local E = proxy.O(e)
  local op = get_field(E, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "eval")
    if m then                                 -- the operator can handle itself
      return m(op, S, E)
    else
      error(("unable to evaluate '%s': the operator can't be evaluated"):format(rima.tostring(e)), 0)
    end
  else                                        -- it's a literal
    local m = get_field(E, "eval")
    return m and m(E, S) or e
  end
end


-- Overloaded operators --------------------------------------------------------

function expression.proxy_mt.__add(a, b)
  return expression:new(operators.add, {1, a}, {1, b})
end

function expression.proxy_mt.__sub(a, b)
  return expression:new(operators.add, {1, a}, {-1, b})
end

function expression.proxy_mt.__unm(a)
  return expression:new(operators.add, {-1, a})
end

function expression.proxy_mt.__mul(a, b, c)
  return expression:new(operators.mul, {1, a}, {1, b})
end

function expression.proxy_mt.__div(a, b)
  return expression:new(operators.mul, {1, a}, {-1, b})
end

function expression.proxy_mt.__pow(a, b)
  return expression:new(operators.pow, a, b)
end

function expression.proxy_mt.__call(...)
  return expression:new(operators.call, ...)
end


--[[
function expression_proxy_mt.__index(...)
  return expression:new(rima.operators.index, ...)
end
--]]


-- EOF -------------------------------------------------------------------------

