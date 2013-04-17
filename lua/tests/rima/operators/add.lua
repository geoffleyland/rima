-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local ops = require("rima.operations")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local expression = require("rima.expression")
local index = require("rima.index")

------------------------------------------------------------------------------

return function(T)
  local A = ops.add(1, index:new(nil, "a"))
  local W = expression.wrap
  local U = expression.unwrap

  -- constructors
  T:test(object.typeinfo(A).add, "typeinfo(add).add")
  T:check_equal(object.typename(A), "add", "typename(add)=='add'")

  local A2 = ops.add(5, "a")
  T:test(object.typeinfo(A2).add, "typeinfo(add).add")
  T:check_equal(object.typename(A2), "add", "typename(add)=='add'")

  local A3 = 1 + W(A)
  T:test(object.typeinfo(U(A3)).add, "typeinfo(add).add")
  T:check_equal(object.typename(U(A3)), "add", "typename(add)=='add'")
  T:test(lib.getmetamethod(A3, "__add"))

  -- string representation
  T:check_equal(A, "1 + a")
  T:check_equal(A2, "5 + a")
end


------------------------------------------------------------------------------

