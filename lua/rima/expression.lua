-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local error, pcall = error, pcall
local ipairs, pairs = ipairs, pairs
local rawget, require, setmetatable, rawtype = rawget, require, setmetatable, type

local object = require("rima.object")
local proxy = require("rima.proxy")
local types = require("rima.types")
require("rima.private")
local rima = rima

module(...)

local scope = require("rima.scope")
local ref = require("rima.ref")
local operators = require("rima.operators")

-- Constructor -----------------------------------------------------------------

local expression = object:new(_M, "expression")
expression_proxy_mt = setmetatable({}, expression)

function expression:new(x, ...)
  local e = {...}
  e.op = x

--  e:check()
  return proxy:new(object.new(self, e), expression_proxy_mt)
end

function expression:new_table(x, t)
  local e = { op=x }
  for i, a in ipairs(t) do e[i] = a end

--  e:check()
  return proxy:new(object.new(self, e), expression_proxy_mt)
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

function expression.operator(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  return type(op and op or e)
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
      return object.type(op).."("..table.concat(rima.imap(dump, e), ", ")..")"
    end
  else                                        -- it's a literal
    local m = get_field(e, "dump")
    return m and m(e) or object.type(e).."("..rima.tostring(e)..")"
  end
end


function expression.__tostring(e)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "_tostring")
    if m then                                 -- the operator can handle itself
      return m(op, e)
    else
      return object.type(op).."(".. table.concat(rima.imap(rima.tostring, e), ", ")..")"
    end
  else                                        -- it's a literal
    local m = get_field(e, "_tostring")
    return m and m(e) or rima.tostring(e)
  end
end
expression_proxy_mt.__tostring = expression.__tostring


function expression.parenthise(e, parent_precedence)
  e = proxy.O(e)
  parent_precedence = parent_precedence or 1
  local s = rima.tostring(e)
  local op = get_field(e, "op")
  if op then                                    -- this is an expression
    local precedence = get_field(op, "precedence") or 1
    if precedence > parent_precedence then
      s = "("..s..")"
    end
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

function expression.eval(e, S)
  e = proxy.O(e)
  local op = get_field(e, "op")
  if op then                                  -- it's an expression or lookalike
    local m = get_field(op, "eval")
    if m then                                 -- the operator can handle itself
      return m(op, S, e)
    else
      error(("unable to evaluate '%s': the operator can't be evaluated"):format(rima.tostring(e)), 0)
    end
  else                                        -- it's a literal
    local m = get_field(e, "eval")
    return m and m(e, S) or e
  end
end


-- Getting a linear form -------------------------------------------------------

function expression._linearise(l, S)
  l = proxy.O(l)
  local constant, terms = 0, {}
  local fail = false

  local function add_variable(n, v, coeff)
    local s = rima.tostring(n)
    if terms[s] then
      error(("the reference '%s' appears more than once"):format(s), 0)
    end
    v = proxy.O(v)
    local t = scope.lookup(S, v.name, v.scope)
    if not isa(t, rima.types.number_t) then
      error(("expecting a number type for '%s', got '%s'"):format(s, t:describe(s)), 0)
    end
    terms[s] = { variable=v, coeff=coeff, lower=t.lower, upper=t.upper, integer=t.integer }
  end

  if type(l) == "number" then
    constant = l
  elseif type(l) == "ref" then
    add_variable(l, l, 1)
  elseif l.op == operators.add then
    for i, a in ipairs(l) do
      a = proxy.O(a)
      local c, x = a[1], a[2]
      if type(x) == "number" then
        if i ~= 1 then
          error(("term %d is constant (%s).  Only the first term should be constant"):
            format(i, rima.tostring(x)), 0)
        end
        if constant ~= 0 then
          error(("term %d is constant (%s), and so is an earlier term.  There can only be one constant in the expression"):
            format(i, rima.tostring(x)), 0)
        end
        constant = c * x
      elseif type(x) == "ref" then
        add_variable(x, x, c)
      else
        error(("term %d (%s) is not linear"):format(i, rima.tostring(x)), 0)
      end
    end
  else
    error("the expression does not evaluate to a sum of terms", 0)
  end
  
  return constant, terms
end


function expression.linearise(e, S)
  local l = eval(0 + e, S)
  local status, constant, terms = pcall(function() return expression._linearise(l, S) end)
  if not status then
    error(("error while linearising '%s':\n  linear form: %s\n  error:\n    %s"):
      format(rima.tostring(e), rima.tostring(l), constant:gsub("\n", "\n    ")), 0)
  else
    return constant, terms
  end
end


-- Overloaded operators --------------------------------------------------------

function expression.__add(a, b)
  return expression:new(operators.add, {1, a}, {1, b})
end

function expression.__sub(a, b)
  return expression:new(operators.add, {1, a}, {-1, b})
end

function expression.__unm(a)
  return expression:new(operators.add, {-1, a})
end

function expression.__mul(a, b, c)
  return expression:new(operators.mul, {1, a}, {1, b})
end

function expression.__div(a, b)
  return expression:new(operators.mul, {1, a}, {-1, b})
end

function expression.__pow(a, b)
  return expression:new(operators.pow, a, b)
end

function expression.__call(...)
  return expression:new(operators.call, ...)
end

expression_proxy_mt.__add = expression.__add
expression_proxy_mt.__sub = expression.__sub
expression_proxy_mt.__unm = expression.__unm
expression_proxy_mt.__mul = expression.__mul
expression_proxy_mt.__div = expression.__div
expression_proxy_mt.__pow = expression.__pow
expression_proxy_mt.__call = expression.__call

--[[
function expression_proxy_mt.__index(...)
  return expression:new(rima.operators.index, ...)
end
--]]


-- EOF -------------------------------------------------------------------------

