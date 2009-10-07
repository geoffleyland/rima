-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local error, xpcall = error, xpcall
local ipairs, type, unpack  = ipairs, type, unpack

local expression = require("rima.expression")
require("rima.private")
local rima = rima

module(...)


-- Addition --------------------------------------------------------------------

local call = _M
call.__typename = "index"


-- Argument Checking -----------------------------------------------------------

function call:check(args)
end


-- String Representation -------------------------------------------------------

function call.__repr(args, format)
  if format and format.dump then
    return "call("..expression.concat(args, format)..")"
  else
    return expression.parenthise(args[1], format, 0).."("..expression.concat({unpack(args, 2)}, format)..")"
  end
end


-- Evaluation ------------------------------------------------------------------

function call.__eval(args, S, eval)
  local f = expression.eval(args[1], S)
  if not expression.defined(f) then
    return expression:new(call, f, unpack(args, 2))
  else
    local status, r
    if type(f) == "function" then
      local fargs = {}
      for i = 2, #args do
        fargs[i-1] = expression.eval(args[i], S)
      end
      status, r = xpcall(function() return f(unpack(fargs)) end, debug.traceback)
    else
      status, r = xpcall(function() return f:call({unpack(args, 2)}, S, eval) end, debug.traceback)
    end

    if not status then
      error(("call: error evaluating '%s' as '%s' with arguments (%s):\n  %s"):
        format(__repr(args), rima.repr(f), expression.concat({unpack(args, 2)}), r:gsub("\n", "\n  ")), 0)
    end
    return r
  end
end


-- EOF -------------------------------------------------------------------------

