-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local global_tostring, type, unpack = tostring, type, unpack
local ipairs = ipairs
local error, xpcall = error, xpcall
local require = require

module(...)

-- Forward declarations ---------------------------------------------------------

expression = {}

-- Subpackages ------------------------------------------------------------------

require("rima.ref")
require("rima.expression")
require("rima.constraint")
require("rima.formulation")
require("rima.values.function_v")
require("rima.iteration")


-- Module functionality --------------------------------------------------------

function R(names, type)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = ref:new{name=n, type=type}
  end
  return unpack(results)
end


function E(e, S)
  local fname, usage =
    "rima.E",
    "E(e:expression, S:nil, table or scope)"

  tools.check_arg_types(S, "S", {"nil", "table", {scope, "scope"}}, usage, frame)

  if not S then
    S = scope.new()
  elseif not object.isa(S, scope) then
    S = scope.create(S)
  end

  local status, r = xpcall(function() return expression.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    error(("error while evaluating '%s':\n  %s"):format(tostring(e), r:gsub("\n", "\n  ")), 0)
  end
end

-- Private functionality -------------------------------------------------------

number_format = "%.4g"
function tostring(x)
  if type(x) == "number" then
    return number_format:format(x)
  else
    return global_tostring(x)
  end
end


function imap(f, t)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end


-- EOF -------------------------------------------------------------------------

