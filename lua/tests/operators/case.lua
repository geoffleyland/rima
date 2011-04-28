-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local case = require("rima.operators.case")

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

  T:test(object.isa(case, rima.case(1, {1, 1})), "isa(case, case)")
  T:check_equal(object.typename(rima.case(1, {1, 1})), "case", "typename(case) == 'case'")
  
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

