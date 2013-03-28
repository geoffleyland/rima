-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")


------------------------------------------------------------------------------

local call = {}
call.__typename = "call"
call.__typeinfo = { call = "true", [call] = true }
call.precedence = 0
expression:copy_operators(call)


------------------------------------------------------------------------------

function call:new(terms)
  return expression.new(call, terms)
end


function call.__repr(args, format)
  args = proxy.O(args)
  if format.format == "dump" then
    return "call("..lib.concat_repr(args, format)..")"
  else
    return core.parenthise(args[1], format, 0).."("..lib.concat_repr({unpack(args, 2)}, format)..")"
  end
end
call.__tostring = lib.__tostring


------------------------------------------------------------------------------

function call.__eval(args, S)
  args = proxy.O(args)

  local f = core.eval(args[1], S)
  local fargs = {}
  for i = 2, #args do
    fargs[i-1] = core.eval(args[i], S)
  end

  if not core.defined(f) then
    return call:new{f, unpack(fargs)}
  else

    local status, value, vtype, addr
    if type(f) == "function" then
      status, value, vtype, addr = xpcall(function() return f(unpack(fargs)) end, debug.traceback)
    else
      status, value, vtype, addr = xpcall(function() return f:call({unpack(fargs)}, S) end, debug.traceback)
    end

    if not status then
      error(("call: error evaluating '%s' as '%s' with arguments (%s):\n  %s"):
        format(__repr(args), lib.repr(f), lib.concat_repr({unpack(args, 2)}), value:gsub("\n", "\n  ")), 0)
    end
    return value, vtype, addr
  end
end


------------------------------------------------------------------------------

return call

------------------------------------------------------------------------------

