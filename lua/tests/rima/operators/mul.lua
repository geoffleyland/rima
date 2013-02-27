-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local mul = require("rima.operators.mul")

local object = require("rima.lib.object")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local A = mul:new({1,3}, {1, interface.R"a"})

  -- constructors
  T:test(object.typeinfo(A).mul, "typeinfo(mul).mul")
  T:check_equal(object.typename(A), "mul", "typename(mul)=='mul'")

  -- string representation
  T:check_equal(A, "3*a")
  
  local B = mul:new({1,0}, {1,2})
  T:check_equal(B, 0)
end


------------------------------------------------------------------------------

