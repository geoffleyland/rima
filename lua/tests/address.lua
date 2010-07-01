-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local setmetatable, type = setmetatable, type

local series = require("test.series")
local object = require("rima.lib.object")
local address = require("rima.address")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  T:test(address:isa(address:new("a")), "isa(address:new(), address)")
  T:check_equal(object.type(address:new("a")), "address")

  T:check_equal(address:new(), "")
  T:check_equal(address:new("a"), ".a")
  T:check_equal(address:new("a")+1, ".a[1]")
  T:check_equal(1+address:new("a"), "[1].a")

  local a = address:new("a", 1, 2)
  T:check_equal(a, ".a[1, 2]")
  T:check_equal(a+a, ".a[1, 2].a[1, 2]")
  T:check_equal(rima.repr(a, { dump=true }), "address{\"a\", 1, 2}")

  T:check_equal(a:sub(1), ".a[1, 2]")
  T:check_equal(a:sub(2), "[1, 2]")
  T:check_equal(a:sub(3), "[2]")
  T:check_equal(a:sub(1, 1), ".a")
  T:check_equal(a:sub(1, 2), ".a[1]")
  T:check_equal(a:sub(1, 3), ".a[1, 2]")
  T:check_equal(a:sub(2, 2), "[1]")
  T:check_equal(a:sub(2, 3), "[1, 2]")
  T:check_equal(a:sub(3, 3), "[2]")

  T:check_equal(a:sub(-3), ".a[1, 2]")
  T:check_equal(a:sub(-2), "[1, 2]")
  T:check_equal(a:sub(-1), "[2]")
  T:check_equal(a:sub(-3, -3), ".a")
  T:check_equal(a:sub(-3, -2), ".a[1]")
  T:check_equal(a:sub(-3, -1), ".a[1, 2]")
  T:check_equal(a:sub(-2, -2), "[1]")
  T:check_equal(a:sub(-2, -1), "[1, 2]")
  T:check_equal(a:sub(-1, -1), "[2]")

  local a = address:new("a", "index b")
  T:check_equal(a, ".a['index b']")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

