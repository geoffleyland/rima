-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local getfenv, ipairs, setmetatable, require, unpack = getfenv, ipairs, setmetatable, require, unpack
local error, xpcall = error, xpcall

module(...)

local args = require("rima.args")
local object = require("rima.object")
local ref = require("rima.ref")
local expression = require("rima.expression")
local scope = require("rima.scope")
local function_v = require("rima.values.function_v")
local linearise = require("rima.linearise")

local rima = getfenv(0).rima

-- Module functionality --------------------------------------------------------

rima.set_number_format = expression.set_number_format
rima.repr = expression.repr


function rima.R(names, type) -- create a reference
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = ref:new{name=n, type=type}
  end
  return unpack(results)
end


function rima.D(e) -- check if an expression is defined
  return expression.defined(e)
end


local dgs
local function default_global_scope()
  if not dgs then
    dgs = scope.new(nil, { name="_GLOBAL" })
  end
  return dgs
end


function rima.E(e, S) -- create an expression
  local fname, usage =
    "rima.E",
    "E(e:expression, S:nil, table or scope)"

  args.check_types(S, "S", {"nil", "table", {scope, "scope"}}, usage, fname)

  if not S then
    S = scope.spawn(default_global_scope(), nil, {no_undefined=true})
  elseif not object.isa(S, scope) then
    S = scope.spawn(default_global_scope(), S, {no_undefined=true})
  end

  local status, r = xpcall(function() return expression.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    error(("evaluate: error evaluating '%s':\n  %s"):format(rima.repr(e), r:gsub("\n", "\n  ")), 0)
  end
end


function rima.F(inputs, e, S) -- create a function
  if e then
    return function_v:new(inputs, e, S)
  else
    return function(e2, S2) return function_v:new(inputs, e2, S2) end
  end
end


function rima.C(lhs, rel, rhs) -- create a constraint
  return rima.constraint:new(lhs, rel, rhs)
end


function rima.sum(sets, e)
  if e then
    return expression:new(rima.operators.sum, sets, e)
  else
    return function(e2) return expression:new(rima.operators.sum, sets, e2) end
  end
end


rima.new = rima.scope.new
rima.set = rima.scope.set


function rima.instance(S, ...) -- create a new instance of a scope
  local S2 = rima.scope.spawn(S)
  for _, v in ipairs{...} do
    scope.set(S2, v)
  end
  return S2
end


function rima.linearise(e, S)
  local l = expression.eval(0 + e, S)
  local status, constant, terms = xpcall(function() return linearise.linearise(l, S) end, debug.traceback)
  if not status then
    error(("error while linearising '%s':\n  linear form: %s\n  error:\n    %s"):
      format(rima.repr(e), rima.repr(l), constant:gsub("\n", "\n    ")), 0)
  else
    return constant, terms
  end
end


-- EOF -------------------------------------------------------------------------

