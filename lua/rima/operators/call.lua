-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")


------------------------------------------------------------------------------

local call = operator:new_class({}, "call")


------------------------------------------------------------------------------

function call:__repr(format)
  if format.format == "dump" then
    return "call("..lib.concat_repr(self, format)..")"
  else
    return core.parenthise(self[1], format, 0).."("..lib.concat_repr({unpack(self, 2)}, format)..")"
  end
end


------------------------------------------------------------------------------

local expression
function call:__eval(...)
  local terms = self:evaluate_terms(...)
  if not terms then return self end

  if not core.defined(terms[1]) then
    return call:new(terms)
  else

    local status, value, vtype, addr
    if type(terms[1]) == "function" then
      expression = expression or require("rima.expression")
      status, value, vtype, addr = xpcall(function() return terms[1](expression.vwrap(unpack(terms, 2))) end, debug.traceback)
      if value then
        value, addr = expression.vunwrap(value, addr)
      end
    else
      local eval_args = {...}
      status, value, vtype, addr = xpcall(function() return terms[1]:call({unpack(terms, 2)}, unpack(eval_args)) end, debug.traceback)
    end

    if not status then
      error(("call: error evaluating '%s' as '%s' with arguments (%s):\n  %s"):
        format(lib.repr(self), lib.repr(terms[1]), lib.concat_repr({unpack(self, 2)}), value:gsub("\n", "\n  ")), 0)
    end
    return value, vtype, addr
  end
end


------------------------------------------------------------------------------

return call

------------------------------------------------------------------------------

