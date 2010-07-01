-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local assert, ipairs = assert, ipairs

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
require("rima.public")
local rima = rima

module(...)

--------------------------------------------------------------------------------

local constraint = object:new(_M, "constraint")

function constraint:new(lhs, rel, rhs)
  assert(rel == "==" or rel == ">=" or rel == "<=")

  o = { type=rel, lhs=lhs, rhs=rhs }

  return object.new(self, o)
end

function constraint:trivial(S)
  local e = core.eval(self.lhs - self.rhs, S)
  return e == 0
end

function constraint:linearise(S)
  local constant, lhs = rima.linearise(self.lhs - self.rhs, S)
  return lhs, self.type, -constant
end


function constraint:tostring(S)
  local lhs = lib.repr(core.eval(self.lhs, S))
  local rhs = lib.repr(core.eval(self.rhs, S))
  local s = lhs.." "..self.type.." "..rhs
  return s
end

function constraint:__tostring()
  local lhs, rhs = lib.repr(self.lhs), lib.repr(self.rhs)
  local s = lhs.." "..self.type.." "..rhs
  return s
end


-- EOF -------------------------------------------------------------------------
