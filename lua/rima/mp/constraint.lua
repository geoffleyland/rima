-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local assert, ipairs = assert, ipairs

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local linearise = require("rima.mp.linearise")

module(...)


--------------------------------------------------------------------------------

local constraint = object:new(_M, "constraint")

function constraint:new(lhs, rel, rhs)
  assert(rel == "==" or rel == ">=" or rel == "<=")

  o = { type=rel, lhs=lhs, rhs=rhs }

  return object.new(self, o)
end


function constraint:__eval(S)
  return constraint:new(core.eval(self.lhs, S), self.type, core.eval(self.rhs, S))
end


function constraint:linearise(S)
  local constant, lhs = linearise.linearise(0 + self.lhs - self.rhs, S)
  return lhs, self.type, -constant
end


function constraint:tostring(S)
  local lhs = lib.repr((core.eval(self.lhs, S)))
  local rhs = lib.repr((core.eval(self.rhs, S)))
  local s = lhs.." "..self.type.." "..rhs
  return s
end

local latex_compare_translation =
{
  ["<="] = "\\eq",
  ["<="] = "\\leq",
  [">="] = "\\geq",
}
function constraint:__repr(format)
  local lhs, rhs = lib.repr(self.lhs, format), lib.repr(self.rhs, format)
  local type
  if format.format == "latex" then
    type = latex_compare_translation[self.type]
  else
    type = self.type
  end
  local s = lhs.." "..type.." "..rhs
  return s
end
constraint.__tostring = lib.__tostring


-- EOF -------------------------------------------------------------------------
