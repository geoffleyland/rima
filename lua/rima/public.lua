-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local error, getfenv, unpack, xpcall = error, getfenv, unpack, xpcall

local args = require("rima.args")
local object = require("rima.object")
local ref = require("rima.ref")
local expression = require("rima.expression")
local scope = require("rima.scope")

module(...)
local rima = getfenv(0).rima

-- Module functionality --------------------------------------------------------

function rima.R(names, type)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = ref:new{name=n, type=type}
  end
  return unpack(results)
end


function rima.E(e, S)
  local fname, usage =
    "rima.E",
    "E(e:expression, S:nil, table or scope)"

  args.check_types(S, "S", {"nil", "table", {scope, "scope"}}, usage, frame)

  if not S then
    S = scope.new()
  elseif not object.isa(S, scope) then
    S = scope.create(S)
  end

  local status, r = xpcall(function() return expression.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    error(("error while evaluating '%s':\n  %s"): format(tostring(e), r:gsub("\n", "\n  ")), 0)
  end
end


function rima.F(inputs, expression, S)
  return rima.values.function_v:new(inputs, expression, S)
end


-- EOF -------------------------------------------------------------------------

