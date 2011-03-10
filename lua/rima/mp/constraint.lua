-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local assert, getmetatable, ipairs, pcall = assert, getmetatable, ipairs, pcall

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local linearise = require("rima.mp.linearise")
local add = require("rima.operators.add")

module(...)


--------------------------------------------------------------------------------

local constraint = object:new(_M, "constraint")

function constraint:new(lhs, rel, rhs)
  assert(rel == "==" or rel == ">=" or rel == "<=")
  return object.new(self, { type=rel, lhs=lhs, rhs=rhs })
end


function constraint:__eval(S)
  return constraint:new(core.eval(self.lhs, S), self.type, core.eval(self.rhs, S))
end


function constraint:characterise(S)
  local e = core.eval(0 + self.lhs - self.rhs, S)
  local rhs = 0
  if getmetatable(e) == add then
    local constant, new_e = add.extract_constant(e)
    if constant then rhs, e = -constant, new_e end
  end
  local comp = self.type
  local lower = ((comp == "==" or comp == ">=") and rhs) or -math.huge
  local upper = ((comp == "==" or comp == "<=") and rhs) or math.huge

  local status, constant, linear_lhs = pcall(linearise.linearise, e, S)
  assert(not status or constant==0)
  
  return lower, upper, e, linear_lhs
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
