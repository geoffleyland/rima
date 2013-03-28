-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local product = require("rima.operators.product")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local scope = require("rima.scope")
local number_t = require("rima.types.number_t")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local E = interface.eval
  local D = lib.dump
  local R = interface.R

  T:test(object.typeinfo(product:new()).product, "typeinfo(product:new()).product")
  T:check_equal(object.typename(product:new()), "product", "typename(product:new()) == 'product'")

  local x, X = R"x, X"

  T:check_equal(E(interface.product{x=X}(x), {X={1, 2, 3, 4, 5}}), 120)
  T:check_equal(E(interface.product{x=X}(x), {X={number_t.free(), number_t.free(), number_t.free()}}), "X[1]*X[2]*X[3]")
end


------------------------------------------------------------------------------

