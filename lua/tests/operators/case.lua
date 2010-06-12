-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local expression_tester = require("test.expression_tester")
local case = require("rima.operators.case")
local object = require("rima.lib.object")
local expression = require("rima.expression")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local D = expression.dump
  local E = rima.E

  T:test(object.isa(rima.case(1, {1, 1}), case), "isa(case, case)")
  T:check_equal(object.type(rima.case(1, {1, 1})), "case", "type(case) == 'case'")
  
  do
    local a, b, c, d, e, f, g, h = rima.R"a, b, c, d, e, f, g, h"
    local C = rima.case(a, {{b, c},{d, e},{f, g}}, h)

    T:check_equal(C, "case a (b: c; d: e; f: g; default: h; )")
    T:check_equal(E(C, {a = 1, f = 1}), "case 1 (b: c; d: e; 1: g; )")
    T:check_equal(E(C, {a = 1, d = 1}), "case 1 (b: c; 1: e; )")
    T:check_equal(E(C, {a = 1, f = 2}), "case 1 (b: c; d: e; default: h; )")
    T:check_equal(E(C, {a = 1, b = 3, d = 1}), "e")
    T:check_equal(E(C, {a = 1, b = 3, d = 3, f = 3}), "h")
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

