-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local assert, ipairs = assert, ipairs

local object = require("rima.object")
require("rima.private")
local rima = rima
local expression = rima.expression

module(...)

--------------------------------------------------------------------------------

local constraint = object:new(_M, "constraint")

function constraint:new(lhs, rel, rhs)
  assert(rel == "==" or rel == ">=" or rel == "<=")

  o = { type=rel, lhs=lhs, rhs=rhs }

  return object.new(self, o)
end

function constraint:trivial(S)
  local e = expression.eval(self.lhs - self.rhs, S)
  return e == 0
end

function constraint:linearise(S)
  local constant, lhs = rima.linearise(self.lhs - self.rhs, S)
  return lhs, self.type, -constant
end


function constraint:tostring(S)
  local lhs = rima.repr(expression.eval(self.lhs, S))
  local rhs = rima.repr(expression.eval(self.rhs, S))
  local s = lhs.." "..self.type.." "..rhs
  return s
end

function constraint:__tostring()
  local lhs, rhs = rima.repr(self.lhs), rima.repr(self.rhs)
  local s = lhs.." "..self.type.." "..rhs
  return s
end


-- EOF -------------------------------------------------------------------------
