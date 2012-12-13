-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local case = require("rima.operators.case")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")



------------------------------------------------------------------------------

return function(T)
  local R = index.R
  local E = core.eval
  local D = lib.dump

  T:test(object.typeinfo(case.build(1, {1, 1})).case, "typeinfo(case).case")
  T:check_equal(object.typename(case.build(1, {1, 1})), "case", "typename(case) == 'case'")
  
  do
    local a, b, c, d, e, f, g, h = R"a, b, c, d, e, f, g, h"
    local C = case.build(a, {{b, c},{d, e},{f, g}}, h)

    T:check_equal(C, "case a (b: c; d: e; f: g; default: h; )")
    T:check_equal(E(C, {a = 1, f = 1}), "case 1 (b: c; d: e; 1: g; )")
    T:check_equal(E(C, {a = 1, d = 1}), "case 1 (b: c; 1: e; )")
    T:check_equal(E(C, {a = 1, f = 2}), "case 1 (b: c; d: e; default: h; )")
    T:check_equal(E(C, {a = 1, b = 3, d = 1}), "e")
    T:check_equal(E(C, {a = 1, b = 3, d = 3, f = 3}), "h")
  end
end


------------------------------------------------------------------------------

