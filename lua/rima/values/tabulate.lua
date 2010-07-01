-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local error, xpcall = error, xpcall
local ipairs, require = ipairs, require

local object = require("rima.lib.object")
local lib = require("rima.lib")
local scope = require("rima.scope")
local rima = rima

module(...)

local ref = require("rima.ref")
local iteration = require("rima.iteration")

-- Tabulation ------------------------------------------------------------------

local tabulate_type = object:new(_M, "tabulate")


function tabulate_type:new(indexes, e)
  return object.new(self, { expression=e, indexes=iteration.set_list:new(indexes) })
end


function tabulate_type:__repr(format)
  return ("tabulate(%s, %s)"):format(
    rima.repr(self.indexes, format),
    rima.repr(self.expression, format))
end
__tostring = lib.__tostring


function tabulate_type:__address(S, a, i, eval)
  if #a - i + 1 < #self.indexes then
    error(("tabulate: error evaluating '%s' as '%s': the tabulation needs %d indexes, got %d"):
      format(__repr(self), rima.repr(self.expression), #self.indexes, #a - i + 1), 0)
  end
  local S2
  if S then
    S2 = scope.spawn(S, nil, {overwrite=true})
  else
    S2 = scope.new(nil, {overwrite=true})
  end

  for _, j in ipairs(self.indexes) do
    for _, n in ipairs(j.names) do
      S2[n] = eval(a:value(i), S)
    end
    i = i + 1
  end

  status, r = xpcall(function() return eval(self.expression, S2) end, debug.traceback)
  if not status then
    local i = 0
    local args = lib.concat(self.indexes, ", ",
      function(si) i = i + 1; return ("%s=%s"):format(si.names[1], rima.repr(a:value(i))) end)
    error(("tabulate: error evaluating '%s' as '%s' where %s:\n  %s"):
      format(__repr(self), rima.repr(self.expression), args, r:gsub("\n", "\n  ")), 0)
  end
  return r, i <= #a and i or nil
end


-- EOF -------------------------------------------------------------------------

