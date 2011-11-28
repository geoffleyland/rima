-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local add = require("rima.operators.add")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local index = require("rima.index")
local expression = require("rima.expression")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local A = add:new({1,1}, {1, index.R"a"})

  -- constructors
  T:test(object.typeinfo(A).add, "typeinfo(add).add")
  T:check_equal(object.typename(A), "add", "typename(add)=='add'")
  T:test(lib.getmetamethod(A, "__add"))

  local A2 = expression:new(add, {1,5}, {1,"a"})
  T:test(object.typeinfo(A2).add, "typeinfo(add).add")
  T:check_equal(object.typename(A2), "add", "typename(add)=='add'")
  T:test(lib.getmetamethod(A2, "__add"))
  
  local A3 = 1 + A
  T:test(object.typeinfo(A3).add, "typeinfo(add).add")
  T:check_equal(object.typename(A3), "add", "typename(add)=='add'")
  T:test(lib.getmetamethod(A3, "__add"))

  -- string representation
  T:check_equal(A, "1 + a")
  T:check_equal(A2, "5 + a")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

