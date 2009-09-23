-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error, ipairs, tostring = error, ipairs, tostring

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
          format(i, tostring(v), type(v)), 0)
      end
    else
      error(("bad index #%d to tabulate: expected string or simple reference, got '%s' (%s)"):
        format(i, tostring(v), type(v)), 0)
    end
  end

  return object.new(self, { expression=e, indexes=new_indexes})
end

function tabulate_type:__tostring()
  return "tabulate({"..rima.concat(self.indexes, ", ", tostring).."}, "..tostring(self.expression)..")"
end

function tabulate_type:handle_address(S, a)
  if #a ~= #self.indexes then
    error(("the tabulation needs %d indexes, got %d"):format(#self.indexes, #a), 0)
  end
  S2 = scope.spawn(S, nil, {overwrite=true})

  for i, j in ipairs(self.indexes) do
    S2[tostring(j)] = expression.eval(a[i], S)
  end

  return expression.eval(self.expression, S2)
end


-- EOF -------------------------------------------------------------------------

