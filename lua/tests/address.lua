-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local address = require("rima.address")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")

local tostring = tostring
local table = require("table")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local function N(...) return address:new(...) end

  -- constructors
  T:test(object.typeinfo(N()).address, "typeinfo(address:new()).address")
  T:test(object.typeinfo(N("a")).address, "typeinfo(address:new()).address")
  T:check_equal(object.typename(N("a")), "address", "typename(address:new())=='address'")

  -- string representation
  T:check_equal(N(), "")
  T:check_equal(N("a"), "a")
  T:check_equal(N("a", "b"), "a.b")
  T:check_equal(N("a", 1), "a[1]")
  T:check_equal(N("a", 1, "b"), "a[1].b")
  T:check_equal(N("a", 1, 2, "b"), "a[1, 2].b")
  T:check_equal(N("a", "b b"), "a['b b']")

  T:check_equal(lib.repr(N("a"), {format="dump"}), "address{\"a\"}")
  T:check_equal(lib.repr(N("a",1), {format="dump"}), "address{\"a\", 1}")
  T:check_equal(lib.repr(N("a",1,2), {format="lua"}), "a[1][2]")

  -- sub
  T:check_equal(N("a", "b", "c", "d"):sub(1,3), "a.b.c")
  T:check_equal(N("a", "b", "c", "d"):sub(2,3), "b.c")
  T:check_equal(N("a", "b", "c", "d"):sub(1,-1), "a.b.c.d")
  T:check_equal(N("a", "b", "c", "d"):sub(-2,-1), "c.d")

  -- checking identifiers
  T:test(not N():starts_with_identifier())
  T:test(N("a"):starts_with_identifier())
  T:test(N("a", 1):starts_with_identifier())
  T:test(not N(1):starts_with_identifier())
  T:test(not N(1, "a"):starts_with_identifier())
  T:test(not N("b b"):starts_with_identifier())
  T:test(not N("b b", "a"):starts_with_identifier())

  T:test(not N():is_identifier())
  T:test(N("a"):is_identifier())
  T:test(not N("a", 1):is_identifier())
  T:test(not N(1):is_identifier())
  T:test(not N(1, "a"):is_identifier())
  T:test(not N("b b"):is_identifier())
  T:test(not N("b b", "a"):is_identifier())

  -- appending
  T:check_equal(address:new("a") + 1 + 2 + "b", "a[1, 2].b")

  -- iterating
  local r = {}
  for i, a in address:new("a",1,"b"):values() do
    r[#r+1] = tostring(a)
  end
  T:check_equal(table.concat(r, ","), "a,1,b")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

