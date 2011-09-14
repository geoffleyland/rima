-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local add = require("rima.operators.add")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")
local scope = require("rima.scope")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local R = index.R
  local E = core.eval
  local D = lib.dump

  local OD = function(e) return add.__repr(e, { format="dump" }) end
  local OS = function(e) return add.__repr(e, {}) end
  local OE = function(e, S) return add.__eval(e, S) end

  T:test(object.typeinfo(add:new()).add, "typeinfo(add:new()).add")
  T:check_equal(object.typename(add:new()), "add", "typename(add:new()) == 'add'")

  T:check_equal(OD({{1, 1}}), "+(1*1)")
  T:check_equal(OS({{1, 1}}), "1")
  T:check_equal(OD({{1, 2}, {3, 4}}), "+(1*2, 3*4)")
  T:check_equal(OS({{1, 2}, {3, 4}}), "2 + 12")
  T:check_equal(OS({{-1, 2}, {3, 4}}), "-2 + 12")
  T:check_equal(OS({{-1, 2}, {-3, 4}}), "-2 - 12")

  local S = scope.new()
  T:check_equal(OE({{1, 2}}, S), 2)
  T:check_equal(OE({{1, 2}, {3, 4}}, S), 14)
  T:check_equal(OE({{1, 2}, {3, 4}, {5, 6}}, S), 44)
  T:check_equal(OE({{1, 2}, {3, 4}, {-5, 6}}, S), -16)
  T:check_equal(OE({{1, 2}, {3, 4}, {5, -6}}, S), -16)

  local a, b, c = R"a,b,c"
  S.a = 5
  T:check_equal(OD({{1, a}}), '+(1*index(address{"a"}))')

  T:check_equal(OE({{1, a}}, S), 5)
  T:check_equal(OE({{1, a}, {2, a}}, S), 15)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

