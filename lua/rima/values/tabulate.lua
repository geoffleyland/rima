-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local error, xpcall = error, xpcall
local ipairs = ipairs

local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
local rima = rima

module(...)

-- Tabulation ------------------------------------------------------------------

local tabulate_type = object:new(_M, "tabulate")


function tabulate_type:new(indexes, e)
  local new_indexes = {}
  for i, v in ipairs(indexes) do
    if type(v) == "string" then
      new_indexes[i] = rima.R(v)
    elseif isa(v, rima.ref) then
      if rima.ref.is_simple(v) then
        new_indexes[i] = v
      else
        error(("bad index #%d to tabulate: expected string or simple reference, got '%s' (%s)"):
          format(i, rima.repr(v), type(v)), 0)
      end
    else
      error(("bad index #%d to tabulate: expected string or simple reference, got '%s' (%s)"):
        format(i, rima.repr(v), type(v)), 0)
    end
  end

  return object.new(self, { expression=e, indexes=new_indexes})
end


function tabulate_type:__repr(format)
  return ("tabulate({%s}, %s)"):format(expression.concat(self.indexes, format), rima.repr(self.expression, format))
end
__tostring = __repr


function tabulate_type:handle_address(S, a)
  if #a ~= #self.indexes then
    error(("tabulate: error evaluating '%s' as '%s': the tabulation needs %d indexes, got %d (%s)"):
      format(__repr(self), rima.repr(self.expression), #self.indexes, #a, expression.concat(a)), 0)
  end
  S2 = scope.spawn(S, nil, {overwrite=true})

  for i, j in ipairs(self.indexes) do
    S2[rima.repr(j)] = expression.eval(a[i], S)
  end

  status, r = xpcall(function() return expression.eval(self.expression, S2) end, debug.traceback)
  if not status then
    local i = 0
    local args = rima.concat(self.indexes, ", ",
      function(si) i = i + 1; return ("%s=%s"):format(rima.repr(si), rima.repr(a[i])) end)
    error(("tabulate: error evaluating '%s' as '%s' where %s:\n  %s"):
      format(__repr(self), rima.repr(self.expression), args, r:gsub("\n", "\n  ")), 0)
  end
  return r
end


-- EOF -------------------------------------------------------------------------

