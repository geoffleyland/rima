-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local number_t = require("rima.types.number_t")
local object = require("rima.object")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(object.isa(number_t:new(), number_t), "isa(number_t:new(), number_t)")
  T:test(object.isa(number_t:new(), rima.types.undefined_t), "isa(number_t:new(), undefined_t)")
  T:check_equal(object.type(number_t:new()), "number_t", "type(number_t:new()) == 'number_t'")

  T:expect_error(function() number_t:new("lower") end, "expecting a number for 'lower_bound', got 'string'")
  T:expect_error(function() number_t:new(1, {}) end, "expecting a number for 'upper_bound', got 'table'")
  T:expect_error(function() number_t:new(2, 1) end, "lower bound must be <= upper bound")
  T:expect_error(function() number_t:new(1.1, 2, true) end, "lower bound is not integer")
  T:expect_error(function() number_t:new(1, 2.1, true) end, "upper bound is not integer")

  T:check_equal(number_t:new(0, 1, true), "binary")
  T:check_equal(number_t:new(0, 1), "0 <= * <= 1, * real")
  T:check_equal(number_t:new(1, 100, true), "1 <= * <= 100, * integer")

  T:check_equal(number_t:new(0, 1, true):describe("a"), "a binary")
  T:check_equal(number_t:new(0, 1):describe("b"), "0 <= b <= 1, b real")
  T:check_equal(number_t:new(1, 100, true):describe("c"), "1 <= c <= 100, c integer")

  T:test(not number_t:new():includes("a string"), "number does not include string")
  T:test(number_t:new(0, 1):includes(0), "(0, 1) includes 0")
  T:test(number_t:new(0, 1):includes(1), "(0, 1) includes 2")
  T:test(number_t:new(0, 1):includes(0.5), "(0, 1) includes 0.5")
  T:test(not number_t:new(0, 1):includes(-0.1), "(0, 1) does not include -0.1")
  T:test(not number_t:new(0, 1):includes(2), "(0, 1) does not include 2")

  T:test(number_t:new(0, 1, true):includes(0), "(0, 1, int) includes 0")
  T:test(number_t:new(0, 1, true):includes(1), "(0, 1, int) includes 2")
  T:test(not number_t:new(0, 1, true):includes(0.5), "(0, 1, int) does not include 0.5")
  T:test(not number_t:new(0, 1, true):includes(-0.1), "(0, 1, int) does not include -0.1")
  T:test(not number_t:new(0, 1, true):includes(2), "(0, 1, int) does not include 2")

  T:test(not number_t:new(0, 1):includes(rima.types.undefined_t:new()), "(0, 1) does not include undefined")
  T:test(number_t:new(0, 1):includes(number_t:new(0, 1)), "(0, 1) includes (0, 1)")
  T:test(number_t:new(0, 1):includes(number_t:new(0.1, 1)), "(0, 1) includes (0.1, 1)")
  T:test(not number_t:new(0, 1):includes(number_t:new(0, 1.1)), "(0, 1) does not include (0, 1.1)")
  T:test(number_t:new(0, 1):includes(number_t:new(0, 1, true)), "(0, 1) includes (0, 1, int)")
  T:test(not number_t:new(0, 1, true):includes(number_t:new(0, 1)), "(0, 1, int) does not include (0, 1)")

  T:check_equal(object.type(rima.free()), "number_t", "type(rima.free()) == 'number_t'")
  T:test(rima.free():includes(rima.free()), "free includes free")
  T:test(not rima.free(1):includes(rima.free()), "free(1) does not include free")

  T:check_equal(object.type(rima.positive()), "number_t", "type(rima.positive()) == 'number_t'")
  T:expect_ok(function() rima.positive(3, 5) end)
  T:expect_error(function() rima.positive(-3, 5) end, "bounds for positive variables must be positive")

  T:check_equal(object.type(rima.negative()), "number_t", "type(rima.negative()) == 'number_t'")
  T:expect_ok(function() rima.negative(-3, -1) end)
  T:expect_error(function() rima.negative(-3, 5) end, "bounds for negative variables must be negative")

  T:check_equal(object.type(rima.integer()), "number_t", "type(rima.integer()) == 'number_t'")
  T:expect_ok(function() rima.integer(-5, 5) end)
  T:expect_error(function() rima.integer(0.5, 5) end, "lower bound is not integer")

  T:expect_ok(function() rima.binary() end)

  return T:close()
end


-- EOF -------------------------------------------------------------------------
