-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local product = require("rima.operators.product")

local series = require("test.series")
local expression_tester = require("test.expression_tester")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local rima = require("rima")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = lib.dump
  local E = core.eval

  T:test(object.typeinfo(product:new()).product, "typeinfo(product:new()).product")
  T:check_equal(object.typename(product:new()), "product", "typename(product:new()) == 'product'")

  local x, X = rima.R"x, X"

  T:check_equal(rima.E(rima.product{x=X}(x), {X={1, 2, 3, 4, 5}}), 120)
  T:check_equal(rima.E(rima.product{x=X}(x), {X={rima.free(), rima.free(), rima.free()}}), "X[1]*X[2]*X[3]")

  return T:close()
end


-- EOF ------------------------------------------------------------------------

