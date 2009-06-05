-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local error, ipairs, tostring = error, ipairs, tostring


local rima = require("rima")
local tests = require("rima.tests")
local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")

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
      error(("bad index #%d to tabulate: expected string or simple reference, got '%s' (%s))"):
        format(i, tostring(v), type(v)), 0)
    end
  end

  return object.new(self, { expression=e, indexes=new_indexes})
end

function tabulate_type:__tostring()
  return "tabulate({"..table.concat(rima.imap(tostring, self.indexes), ", ").."}, "..tostring(self.expression)..")"
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

function rima.tabulate(indexes, e)
  return tabulate_type:new(indexes, e)
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  local t
  
  T:expect_ok(function() t = rima.tabulate({"a", "b", "c"}, 3) end, "constructing tabulate")

  do
    local Q, x, y, z = rima.R"Q, x, y"
    local e = rima.sum({Q}, x[Q])
    local S = rima.scope.create{ Q={4, 5, 6} }
    S.x = rima.tabulate({y}, rima.value(y)^2)
    T:equal_strings(rima.E(e, S), 77)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

