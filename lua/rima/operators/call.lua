-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local error, ipairs, require, type, unpack, xpcall =
      error, ipairs, require, type, unpack, xpcall

local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")

module(...)

local expression = require("rima.expression")

-- Addition --------------------------------------------------------------------

local call = _M
call.__typename = "call"
call.precedence = 0


-- String Representation -------------------------------------------------------

function call.__repr(args, format)
  args = proxy.O(args)
  if format.format == "dump" then
    return "call("..lib.concat_repr(args, format)..")"
  else
    return core.parenthise(args[1], format, 0).."("..lib.concat_repr({unpack(args, 2)}, format)..")"
  end
end


-- Evaluation ------------------------------------------------------------------

function call.__eval(args, S)
  args = proxy.O(args)

  local f = core.eval(args[1], S)
  local fargs = {}
  for i = 2, #args do
    fargs[i-1] = core.eval(args[i], S)
  end

  if not core.defined(f) then
    return expression:new(call, f, unpack(fargs))
  else

    local status, r
    if type(f) == "function" then
      status, r = xpcall(function() return f(unpack(fargs)) end, debug.traceback)
    else
      status, r = xpcall(function() return f:call({unpack(fargs)}, S) end, debug.traceback)
    end

    if not status then
      error(("call: error evaluating '%s' as '%s' with arguments (%s):\n  %s"):
        format(__repr(args), lib.repr(f), lib.concat_repr({unpack(args, 2)}), r:gsub("\n", "\n  ")), 0)
    end
    return r
  end
end


-- EOF -------------------------------------------------------------------------

