-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local ops = require("rima.operations")

local object = require("rima.lib.object")
local index = require("rima.index")


------------------------------------------------------------------------------

return function(T)
  local A = ops.mul(3, index:new(nil, "a"))

  -- constructors
  T:test(object.typeinfo(A).mul, "typeinfo(mul).mul")
  T:check_equal(object.typename(A), "mul", "typename(mul)=='mul'")

  -- string representation
  T:check_equal(A, "3*a")
  
  local B = ops.mul(0, 2)
  T:check_equal(B, 0)
end


------------------------------------------------------------------------------

