-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error = error
local ipairs, pairs = ipairs, pairs
local require, rawtype, tostring = require, type, tostring
local getmetatable, setmetatable = getmetatable, setmetatable
local rawget, rawset = rawget, rawset

local object = require("rima.object")
local proxy = require("rima.proxy")
local rima = rima

module(...)

local operators = require("rima.operators")

-- Constructor -----------------------------------------------------------------

local expression = object:new(_M, "expression")
expression.proxy_mt = setmetatable({}, expression)


function expression:new(x, ...)
  local e = {...}
  for k, v in pairs(self.proxy_mt) do if not(x[k]) then rawset(x, k, v) end end
--  e:check()
  return proxy:new(object.new(self, e), x)
end

function expression:new_table(x, t)
  local e = {}
  for i, a in ipairs(t) do e[i] = a end
  for k, v in pairs(self.proxy_mt) do if not(x[k]) then rawset(x, k, v) end end
--  e:check()
  return proxy:new(object.new(self, e), x)
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


-- String representation -------------------------------------------------------

local number_format = "%.4g"
function expression.set_number_format(f)
  number_format = f
end


function expression.concat(t, format)
  return rima.concat(t, ", ", function(i) return repr(i, format) end)
end


expression.proxy_mt.__repr = {}

function expression.simple_repr(e, format)
  if rawtype(e) == "number" then
    local nf = (format and format.numbers) or number_format
    return nf:format(e)
  else
    return tostring(e)
  end
end

function expression.repr(e, format)
  local mt = getmetatable(e)
  local f = mt and rawget(mt, "__repr")
  if f then
    if f == proxy_mt.__repr then
      return object.type(mt).."("..concat(proxy.O(e), format)..")"
    else
      return f(proxy.O(e), format)
    end
  elseif format and format.dump then
    return object.type(e).."("..simple_repr(e)..")"
  else
    return simple_repr(e)
  end
end
expression.proxy_mt.__tostring = repr


function expression.dump(e)
  return repr(e, { dump=true })
end


function expression.parenthise(e, format, parent_precedence)
  parent_precedence = parent_precedence or 1
  local s = repr(e, format)
  local mt = getmetatable(e)
  local precedence = (mt and mt.precedence) or 0
  if precedence > parent_precedence then
    s = "("..s..")"
  end
  return s
end


-- Status ----------------------------------------------------------------------

function expression.defined(e)
  local mt = getmetatable(e)
  return not mt or not rawget(mt, "__eval")
end


-- Evaluation ------------------------------------------------------------------

function expression.bind(e, S)
  local mt = getmetatable(e)
  if mt then
    local f = rawget(mt, "__bind")
    if f then
      return f(proxy.O(e), S)
    else
      f = rawget(mt, "__eval")
      if f then
        return f(proxy.O(e), S, bind)
      end
    end
  end
  return e
end


function expression.eval(e, S)
  local mt = getmetatable(e)
  local f = mt and rawget(mt, "__eval")
  return (f and f(proxy.O(e), S, eval)) or e
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

