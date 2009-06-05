-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

--local assert, tostring = assert, tostring
local ipairs = ipairs
local coroutine = require("coroutine")

local assert = assert

local tests = require("rima.tests")
local object = require("rima.object")
local rima = rima
local expression = rima.expression

module(...)

--------------------------------------------------------------------------------

local constraint = object:new(_M, "constraint")

function constraint:new(lhs, rel, rhs, ...)
  assert(rel == "==" or rel == ">=" or rel == "<=")

  o = { type=rel, lhs=lhs, rhs=rhs, sets={...} }

  return object.new(self, o)
end

--[[
function constraint:list_variables(variables)
  self.lhs:list_variables(variables)
  self.rhs:list_variables(variables)
end
--]]

function constraint:linearise(S)
  local caller_base_scope, defined_sets =
    rima.iteration.prepare(S, self.sets)

  assert(#defined_sets == #self.sets, "Some of the constraint's indices are undefined")

--  local e = expression.evaluate(self.lhs - self.rhs, caller_base_scope)
  local e = self.lhs - self.rhs

  local function list()
    for caller_scope in rima.iteration.iterate_all(caller_base_scope, defined_sets) do
      local constant, lhs = expression.linearise(e, caller_scope)
      coroutine.yield(lhs, self.type, -constant)
    end
  end
  
  return coroutine.wrap(list)

end


function constraint:tostring(S)
  local caller_base_scope, defined_sets, undefined_sets =
    rima.iteration.prepare(S, self.sets)

  local function list()
    for caller_scope in rima.iteration.iterate_all(caller_base_scope, defined_sets) do
      local lhs = rima.tostring(expression.eval(self.lhs, caller_scope))
      local rhs = rima.tostring(expression.eval(self.rhs, caller_scope))
      local s = lhs.." "..self.type.." "..rhs
      for i, z in ipairs(undefined_sets) do
        if i == 1 then s = s.." for all "
        else s = s..", "
        end
       s = s..rima.tostring(z)
      end
      coroutine.yield(s)
    end
  end
  
  return coroutine.wrap(list)
end

function constraint:__tostring()
  local lhs, rhs = rima.tostring(self.lhs), rima.tostring(self.rhs)
  local s = lhs.." "..self.type.." "..rhs
  return s
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  local a, b = rima.R"a,b"
  local S = rima.scope.create{ ["a,b"]=rima.free() }

  local c
  T:expect_ok(function() c = constraint:new(a + b, "==", b) end)
  T:equal_strings(rima.tostring(c), "a + b == b")

  return T:close()
end


-- EOF -------------------------------------------------------------------------
