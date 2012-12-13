-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local number_t = require("rima.types.number_t")

local series = require("test.series")
local object = require("rima.lib.object")
local core = require("rima.core")
local index = require("rima.index")
local undefined_t = require("rima.types.undefined_t")
local sum = require("rima.operators.sum")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local R = index.R
  local E = core.eval

  T:test(object.typeinfo(number_t:new()).number_t, "typeinfo(number_t:new()).number_t")
  T:test(object.typeinfo(number_t:new()).undefined_t, "typeinfo(number_t:new()).undefined_t")
  T:check_equal(object.typename(number_t:new()), "number_t", "typename(number_t:new()) == 'number_t'")

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

  T:test(not number_t:new(0, 1):includes(undefined_t:new()), "(0, 1) does not include undefined")
  T:test(number_t:new(0, 1):includes(number_t:new(0, 1)), "(0, 1) includes (0, 1)")
  T:test(number_t:new(0, 1):includes(number_t:new(0.1, 1)), "(0, 1) includes (0.1, 1)")
  T:test(not number_t:new(0, 1):includes(number_t:new(0, 1.1)), "(0, 1) does not include (0, 1.1)")
  T:test(number_t:new(0, 1):includes(number_t:new(0, 1, true)), "(0, 1) includes (0, 1, int)")
  T:test(not number_t:new(0, 1, true):includes(number_t:new(0, 1)), "(0, 1, int) does not include (0, 1)")

  T:check_equal(object.typename(number_t.free()), "number_t", "typename(number_t.free()) == 'number_t'")
  T:test(number_t.free():includes(number_t.free()), "free includes free")
  T:test(not number_t.free(1):includes(number_t.free()), "free(1) does not include free")

  T:check_equal(object.typename(number_t.positive()), "number_t", "typename(number_t.positive()) == 'number_t'")
  T:expect_ok(function() number_t.positive(3, 5) end)
  T:expect_error(function() number_t.positive(-3, 5) end, "bounds for positive variables must be positive")

  T:check_equal(object.typename(number_t.negative()), "number_t", "typename(number_t.negative()) == 'number_t'")
  T:expect_ok(function() number_t.negative(-3, -1) end)
  T:expect_error(function() number_t.negative(-3, 5) end, "bounds for negative variables must be negative")

  T:check_equal(object.typename(number_t.integer()), "number_t", "typename(number_t.integer()) == 'number_t'")
  T:expect_ok(function() number_t.integer(-5, 5) end)
  T:expect_error(function() number_t.integer(0.5, 5) end, "lower bound is not integer")

  T:expect_ok(function() number_t.binary() end)

  do
    local x = R"x"
    local S1 = { x = 1 }
    local S2 = { x = number_t:new() }  
    T:expect_error(function() E(x.a, S1) end, "error indexing 'x' as 'x.a': can't index a number")
    T:expect_error(function() E(x.a, S2) end, "error indexing 'x' as 'x.a': can't index a number")
  end

  do
    local x = R"x"
    local S1 = { x = {1} }
    local S2 = { x = {number_t:new()} }
    local e = sum.build{x=x}(x.a)
    T:expect_error(function() E(e, S1) end, "error indexing 'x%[1%]' as 'x%[1%]%.a': can't index a number")
    T:expect_error(function() E(e, S2) end, "error indexing 'x%[1%]' as 'x%[1%]%.a': can't index a number")
  end


  return T:close()
end


-- EOF -------------------------------------------------------------------------

