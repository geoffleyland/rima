-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local minmax = require("rima.operators.minmax")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local rima = require("rima")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = lib.dump
  local E = core.eval

  -- min
  T:test(object.typeinfo(rima.min(1, {1, 1})).min, "typeinfo(min).min")
  T:check_equal(object.typename(rima.min(1, {1, 1})), "min", "typename(min) == 'min'")
  
  do
    local a, b, c, d = rima.R"a, b, c, d"
    local C = rima.min(a, b, c, d)

    T:check_equal(C, "min(a, b, c, d)")
    T:check_equal(E(C, {a = 1}), "min(b, c, d, 1)")
    T:check_equal(E(C, {a = 1, b = 2}), "min(c, d, 1)")
    T:check_equal(E(C, {a = 1, b = 2, c = 3, d = 4}), 1)
  end

  -- max
  T:test(object.typeinfo(rima.max(1, {1, 1})).max, "typeinfo(max).max")
  T:check_equal(object.typename(rima.max(1, {1, 1})), "max", "typename(max) == 'max'")
  
  do
    local a, b, c, d = rima.R"a, b, c, d"
    local C = rima.max(a, b, c, d)

    T:check_equal(C, "max(a, b, c, d)")
    T:check_equal(E(C, {a = 1}), "max(b, c, d, 1)")
    T:check_equal(E(C, {a = 1, b = 2}), "max(c, d, 2)")
    T:check_equal(E(C, {a = 1, b = 2, c = 3, d = 4}), 4)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

