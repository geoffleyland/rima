-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local error, xpcall = error, xpcall
local ipairs, type, unpack  = ipairs, type, unpack

local expression = require("rima.expression")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local rima = rima

module(...)


-- Addition --------------------------------------------------------------------

local call = _M
call.__typename = "call"
call.precedence = 0


-- Argument Checking -----------------------------------------------------------
--[[
function call:check(args)
end
--]]

-- String Representation -------------------------------------------------------

function call.__repr(args, format)
  args = proxy.O(args)
  if format and format.dump then
    return "call("..lib.concat_repr(args, format)..")"
  else
    return core.parenthise(args[1], format, 0).."("..lib.concat_repr({unpack(args, 2)}, format)..")"
  end
end


-- Evaluation ------------------------------------------------------------------

function call.__eval(args, S, eval)
  args = proxy.O(args)
  local f = core.eval(args[1], S)
  if not core.defined(f) then
    return expression:new(call, f, unpack(args, 2))
  else
    local status, r
    if type(f) == "function" then
      local fargs = {}
      for i = 2, #args do
        fargs[i-1] = core.eval(args[i], S)
      end
      status, r = xpcall(function() return f(unpack(fargs)) end, debug.traceback)
    else
      status, r = xpcall(function() return f:call({unpack(args, 2)}, S, eval) end, debug.traceback)
    end

    if not status then
      error(("call: error evaluating '%s' as '%s' with arguments (%s):\n  %s"):
        format(__repr(args), rima.repr(f), lib.concat_repr({unpack(args, 2)}), r:gsub("\n", "\n  ")), 0)
    end
    return r
  end
end


-- EOF -------------------------------------------------------------------------

