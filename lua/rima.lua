-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local lib = require("rima.lib")
local trace = require("rima.lib.trace")
local core = require("rima.core")
local set_ref = require("rima.sets.ref")
local number_t = require("rima.types.number_t")
local compiler = require("rima.compiler")
local interface = require("rima.interface")


rima = {}
rima.mp = require("rima.mp")
rima.scope = require("rima.scope")


------------------------------------------------------------------------------

rima.repr = lib.repr

------------------------------------------------------------------------------

rima.R = interface.R
rima.define = interface.define


------------------------------------------------------------------------------

--- Evaluate an expression
function rima.E(e, S)
  local status, r = xpcall(function() return core.eval(e, S) end, debug.traceback)
  if status then
    return r
  else
    trace.reset_depth()
    error(("error evaluating '%s':\n  %s"):format(lib.repr(e), r:gsub("\n", "\n  ")), 2)
  end
end


------------------------------------------------------------------------------

function rima.diff(exp, var)
  return (core.eval(core.diff(exp, var)))
end


------------------------------------------------------------------------------

rima.compile = compiler.compile


------------------------------------------------------------------------------

rima.sum     = interface.sum
rima.product = interface.product
rima.case    = interface.case
rima.min     = interface.min
rima.max     = interface.max
rima.F       = interface.func
rima.ord     = interface.ord
rima.range   = interface.range

for k, v in pairs(interface.math) do
  if k:sub(1, 1) ~= "_" then
    rima[k] = v
  end
end


------------------------------------------------------------------------------

rima.pairs = set_ref.pairs
rima.ipairs = set_ref.ipairs


------------------------------------------------------------------------------

rima.free = number_t.free
rima.positive = number_t.positive
rima.negative = number_t.negative
rima.integer = number_t.integer
rima.binary = number_t.binary


------------------------------------------------------------------------------

return rima

------------------------------------------------------------------------------

