-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local undefined_t = require("rima.types.undefined_t")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local R = index.R
  local E = core.eval
  local sum = interface.sum

  T:test(object.typeinfo(undefined_t:new()).undefined_t, "typeinfo(undefined_t:new()).undefined_t")
  T:check_equal(object.typename(undefined_t:new()), 'undefined_t', "typename(undefined_t:new()) == 'undefined_t'")
  T:check_equal(undefined_t:new(), 'undefined', "repr(undefined_t:new()) == 'undefined'")

  T:check_equal(undefined_t:new():describe("a"), 'a undefined', "undefined:describe()'")
  T:check_equal(undefined_t:new():describe("b"), 'b undefined', "undefined:describe()'")
  T:test(undefined_t:new():includes(1), "undefined:includes()'")
  T:test(undefined_t:new():includes("a"), "undefined:includes()'")
  T:test(undefined_t:new():includes({}), "undefined:includes()'")
  T:test(undefined_t:new():includes(nil), "undefined:includes()'")
  
  do
    local x = R"x"
    local S = { x = undefined_t:new() }
    T:check_equal(E(x, S), "x")
    T:check_equal(E(x + 1, S), "1 + x")
  end

  do
    local x, y, z = R"x, y, z"
    local S = { x = { undefined_t:new() }}
    local e = sum{y=x}(x[y])
    T:check_equal(E(e, S), "x[1]")
    T:check_equal(lib.dump(E(e, S)), "index(address{\"x\", 1})")
  end

  do
    local x, y, z = R"x, y, z"
    local e = sum{y=x}(y.z)

    local S1 = { x = {{}}}
    local S2 = { x = {{z=undefined_t:new()}}}

    T:check_equal(E(e, S1), "x[1].z")
    T:check_equal(lib.dump(E(e, S1)), "index(address{\"x\", 1, \"z\"})")
    T:check_equal(E(e, S2), "x[1].z")
    T:check_equal(lib.dump(E(e, S2)), "index(address{\"x\", 1, \"z\"})")
  end

  do
    local x, X, y, Y, z = R"x, X, y, Y, z"
    local e = sum{x=X}(sum{y=x.Y}(y.z))

    local S1 = { X={{Y={{}}}}}
    local S2 = { X={{Y={{z=undefined_t:new()}}}}}

    T:check_equal(E(e, S1), "X[1].Y[1].z")
    T:check_equal(lib.dump(E(e, S1)), "index(address{\"X\", 1, \"Y\", 1, \"z\"})")
    T:check_equal(E(e, S2), "X[1].Y[1].z")
    T:check_equal(lib.dump(E(e, S2)), "index(address{\"X\", 1, \"Y\", 1, \"z\"})")
  end
end


------------------------------------------------------------------------------

