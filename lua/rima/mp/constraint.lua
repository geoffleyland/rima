-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local assert, ipairs, pcall =
      assert, ipairs, pcall

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local linearise = require("rima.mp.linearise")
local add_mul = require("rima.operators.add_mul")

module(...)


--------------------------------------------------------------------------------

local constraint = object:new_class(_M, "constraint")

function constraint:new(lhs, rel, rhs)
  assert(rel == "==" or rel == ">=" or rel == "<=")
  return object.new(self, { type=rel, lhs=lhs, rhs=rhs })
end


function constraint:__eval(S, args)
  local lhs = core.eval(self.lhs, S, args)
  local rhs = core.eval(self.rhs, S, args)
  if lhs == self.lhs and rhs == self.rhs then
    return self
  else
    return constraint:new(lhs, self.type, rhs)
  end
end


function constraint:characterise(S)
  local e = core.eval(0 + self.lhs - self.rhs, S)
  local rhs = 0
  if object.typeinfo(e).add then
    local constant, new_e = add_mul.extract_constant(e)
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
  ["=="] = "=",
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
