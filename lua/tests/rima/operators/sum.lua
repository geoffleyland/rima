-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local sum = require("rima.operators.sum")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local index = require("rima.index")
local sets = require("rima.sets")
local set_ref = require("rima.sets.ref")
local number_t = require("rima.types.number_t")


------------------------------------------------------------------------------

return function(T)
  local R = index.R
  local E = core.eval
  local D = lib.dump

  T:test(object.typeinfo(sum:new()).sum, "typeinfo(sum:new()).sum")
  T:check_equal(object.typename(sum:new()), "sum", "typename(sum:new()) == 'sum'")

  do
    local x, X = R"x, X"
    local S = scope.new{ X={{y=number_t.free()},{y=number_t.free()},{y=number_t.free()}} }
    local S2 = scope.new(S, { X={{y=1},{y=2},{y=3}} })
    local e1 = sum.build{["_, x"]=set_ref.ipairs(X)}(x.y)

--    T:check_equal(TYPE(X[1].y, S), number_t.free())
    T:check_equal(E(X[1].y, S), "X[1].y")

    T:check_equal(e1, "sum{_, x in ipairs(X)}(x.y)")
--    T:check_equal(D(e1), "sum({_, x in ipairs(ref(X))}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e1, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e1, S2), 6)

    local e2 = sum.build{X=X}(X.y)
    T:check_equal(e2, "sum{X in X}(X.y)")
--    T:check_equal(D(e2), "sum({X in ref(X)}, index(ref(X), address{\"y\"}))")
    T:check_equal(E(e2, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e2, S2), 6)

    local e3 = sum.build{x=X}(x.y)
    T:check_equal(e3, "sum{x in X}(x.y)")
--    T:check_equal(D(e3), "sum({x in ref(X)}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e3, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e3, S2), 6)
  end

  do
    local x, X, i = R"x, X, i"
    local S = scope.new()
    S.X[i].y = number_t.free()
    local S2 = scope.new(S, { X={{y=1},{y=2},{y=3}} })
    
--    T:check_equal(TYPE(X[1].y, S), number_t.free())
    T:check_equal(E(X[1].y, S), "X[1].y")

    local e1 = sum.build{["_, x"]=set_ref.ipairs(X)}(x.y)
    T:check_equal(e1, "sum{_, x in ipairs(X)}(x.y)")
--    T:check_equal(D(e1), "sum({_, x in ipairs(ref(X))}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e1, S), "sum{_, x in ipairs(X)}(x.y)")
    T:check_equal(E(e1, S2), 6)

    local e2 = sum.build{X=X}(X.y)
    T:check_equal(e2, "sum{X in X}(X.y)")
--    T:check_equal(D(e2), "sum({X in ref(X)}, index(ref(X), address{\"y\"}))")
    T:check_equal(E(e2, S), "sum{X in X}(X.y)")
    T:check_equal(E(sum.build{x=X}(x.y), S2), 6)
    T:check_equal(E(e2, S2), 6)

    local e3 = sum.build{x=X}(x.y)
    T:check_equal(e3, "sum{x in X}(x.y)")
--    T:check_equal(D(e3), "sum({x in ref(X)}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e3, S), "sum{x in X}(x.y)")
    T:check_equal(E(e3, S2), 6)
  end

  do
    local x, X, i = R"x, X, i"
    local S = scope.new()
    S.X[i].y = number_t.free()
    local S2 = scope.new(S, { X={{z=11}} })
    local S3 = scope.new(S, { X={{z=11},{z=13},{z=17}} })
    local e

    T:check_equal(E(X[1].y, S), "X[1].y")
    T:check_equal(E(X[1].y, S2), "X[1].y")
    T:check_equal(E(X[1].y, S3), "X[1].y")

    e = sum.build{["_, x"]=set_ref.ipairs(X)}(x.y)
    T:check_equal(e, "sum{_, x in ipairs(X)}(x.y)")
    T:check_equal(E(e, S2), "X[1].y")
    T:check_equal(E(e, S3), "X[1].y + X[2].y + X[3].y")

    e = sum.build{["_, x"]=set_ref.ipairs(X)}(x.y * x.z)
    T:check_equal(e, "sum{_, x in ipairs(X)}(x.y*x.z)")
    T:check_equal(E(e, S2), "11*X[1].y")
    T:check_equal(E(e, S3), "11*X[1].y + 13*X[2].y + 17*X[3].y")

    e = sum.build{X=X}(X.y)
    T:check_equal(e, "sum{X in X}(X.y)")
    T:check_equal(E(e, S2), "X[1].y")
    T:check_equal(E(e, S3), "X[1].y + X[2].y + X[3].y")

    e = sum.build{X=X}(X.y * X.z)
    T:check_equal(e, "sum{X in X}(X.y*X.z)")
    T:check_equal(E(e, S2), "11*X[1].y")
    T:check_equal(E(e, S3), "11*X[1].y + 13*X[2].y + 17*X[3].y")

    e = sum.build{x=X}(x.y)
    T:check_equal(e, "sum{x in X}(x.y)")
    T:check_equal(E(e, S2), "X[1].y")
    T:check_equal(E(e, S3), "X[1].y + X[2].y + X[3].y")

    e = sum.build{x=X}(x.y * x.z)
    T:check_equal(e, "sum{x in X}(x.y*x.z)")
    T:check_equal(E(e, S2), "11*X[1].y")
    T:check_equal(E(e, S3), "11*X[1].y + 13*X[2].y + 17*X[3].y")
  end

  -- sums in sums
  do
    local A, i, I, j, J = R"A, i, I, j, J"

    local e = sum.build{i=I}(sum.build{j=J}(A[i][j]))
    local S =
    {
      A = {{3, 5, 7}, {11, 13, 19}},
      I = sets.range(1,2),
      J = sets.range(1,3),
    }
    T:check_equal(E(e, S), 58)
  end
end


------------------------------------------------------------------------------

