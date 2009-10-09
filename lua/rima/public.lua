-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local getfenv, setmetatable, require, unpack = getfenv, setmetatable, require, unpack
local error, xpcall = error, xpcall

module(...)

local args = require("rima.args")
local object = require("rima.object")
local ref = require("rima.ref")
local expression = require("rima.expression")
local scope = require("rima.scope")
local function_v = require("rima.values.function_v")
local tabulate_type = require("rima.values.tabulate")
local linearise = require("rima.linearise")

local rima = getfenv(0).rima

-- Module functionality --------------------------------------------------------

local default_metatable = {}
default_metatable.__repr = function() return "default" end
default_metatable.__tostring = default_metatable.__repr
rima.default = setmetatable({}, default_metatable)

rima.set_number_format = expression.set_number_format
rima.repr = expression.repr


function rima.R(names, type)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = ref:new{name=n, type=type}
  end
  return unpack(results)
end


function rima.D(e)
  return expression.defined(e)
end


function rima.E(e, S)
  local fname, usage =
    "rima.E",
    "E(e:expression, S:nil, table or scope)"

  args.check_types(S, "S", {"nil", "table", {scope, "scope"}}, usage, fname)

  if not S then
    S = scope.new()
  elseif not object.isa(S, scope) then
    S = scope.create(S)
  end

  local status, r = xpcall(function() return expression.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    error(("evaluate: error evaluating '%s':\n  %s"):format(rima.repr(e), r:gsub("\n", "\n  ")), 0)
  end
end


function rima.F(inputs, expression, S)
  return function_v:new(inputs, expression, S)
end


function rima.tabulate(indexes, e)
  return tabulate_type:new(indexes, e)
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

