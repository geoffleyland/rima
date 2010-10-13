-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local type = type

local series = require("test.series")
local undefined_t = require("rima.types.undefined_t")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local E = core.eval

  T:test(undefined_t:isa(undefined_t:new()), "isa(undefined_t:new(), undefined_t)")
  T:check_equal(object.type(undefined_t:new()), 'undefined_t', "type(undefined_t:new()) == 'undefined_t'")
  T:check_equal(undefined_t:new(), 'undefined', "repr(undefined_t:new()) == 'undefined'")

  T:check_equal(undefined_t:new():describe("a"), 'a undefined', "undefined:describe()'")
  T:check_equal(undefined_t:new():describe("b"), 'b undefined', "undefined:describe()'")
  T:test(undefined_t:new():includes(1), "undefined:includes()'")
  T:test(undefined_t:new():includes("a"), "undefined:includes()'")
  T:test(undefined_t:new():includes({}), "undefined:includes()'")
  T:test(undefined_t:new():includes(nil), "undefined:includes()'")
  
  do
    local x = rima.R"x"
    local S = { x = undefined_t:new() }
    T:check_equal(E(x, S), "x")
    T:check_equal(E(x + 1, S), "1 + x")
  end

  do
    local x, y, z = rima.R"x, y, z"
    local S = { x = { undefined_t:new() }}
    local e = rima.sum{y=x}(x[y])
    T:check_equal(E(e, S), "x[1]")
    T:check_equal(lib.dump(E(e, S)), "index(address{\"x\", 1})")
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

