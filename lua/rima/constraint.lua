-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local coroutine = require("coroutine")
local assert, ipairs = assert, ipairs

local object = require("rima.object")
require("rima.private")
local rima = rima
local expression = rima.expression

module(...)

--------------------------------------------------------------------------------

local constraint = object:new(_M, "constraint")

function constraint:new(lhs, rel, rhs, ...)
  assert(rel == "==" or rel == ">=" or rel == "<=")

  o = { type=rel, lhs=lhs, rhs=rhs, sets=rima.iteration.set_list:new{...} }

  return object.new(self, o)
end

--[[
function constraint:list_variables(variables)
  self.lhs:list_variables(variables)
  self.rhs:list_variables(variables)
end
--]]

function constraint:linearise(S)
  local e = self.lhs - self.rhs

  local function list()
    for S2, undefined in self.sets:iterate(S) do
      if undefined and undefined[1] then
        error("Some of the constraint's indices are undefined")
      end
      local constant, lhs = rima.linearise(e, S2)
      coroutine.yield(lhs, self.type, -constant)
    end
  end
  
  return coroutine.wrap(list)

end


function constraint:tostring(S)

  local function list()
    for S2, undefined in self.sets:iterate(S) do
      local lhs = rima.repr(expression.eval(self.lhs, S2))
      local rhs = rima.repr(expression.eval(self.rhs, S2))
      local s = lhs.." "..self.type.." "..rhs
      if undefined and undefined[1] then s = s.." for all "..rima.repr(undefined) end
      coroutine.yield(s)
    end
  end
  
  return coroutine.wrap(list)
end

function constraint:__tostring()
  local lhs, rhs = rima.repr(self.lhs), rima.repr(self.rhs)
  local s = lhs.." "..self.type.." "..rhs
  return s
end


-- EOF -------------------------------------------------------------------------
