-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local product = require("rima.operators.product")

local series = require("test.series")
local expression_tester = require("test.expression_tester")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local index = require("rima.index")
local number_t = require("rima.types.number_t")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local R = index.R
  local E = core.eval
  local D = lib.dump

  T:test(object.typeinfo(product:new()).product, "typeinfo(product:new()).product")
  T:check_equal(object.typename(product:new()), "product", "typename(product:new()) == 'product'")

  local x, X = R"x, X"

  T:check_equal(E(product.build{x=X}(x), {X={1, 2, 3, 4, 5}}), 120)
  T:check_equal(E(product.build{x=X}(x), {X={number_t.free(), number_t.free(), number_t.free()}}), "X[1]*X[2]*X[3]")

  return T:close()
end


-- EOF ------------------------------------------------------------------------

