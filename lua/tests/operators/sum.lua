-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local sum = require("rima.operators.sum")

local series = require("test.series")
local expression_tester = require("test.expression_tester")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local rima = require("rima")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = lib.dump
  local E = core.eval

  T:test(sum:isa(sum:new()), "isa(sum, sum:new())")
  T:check_equal(object.type(sum:new()), "sum", "type(sum:new()) == 'sum'")

  local U = expression_tester(T, "x, y, z, Q, q, R, r, V, v", { R={"a", "b", "c"}, V={"d", "e"}, y={1, 2, 3}, z={{1,2},{3,4},{5,6}} })
  U{"rima.sum{q=Q}(x)", S="sum{q in Q}(x)", ES="sum{q in Q}(x)"} --, D="sum(closure({ref{names={q}, order={aelements}, set=index(address{\"Q\"})}}, index(address{\"x\"})))"}
  U{"rima.sum{r=R}(x)", S="sum{r in R}(x)", ES="3*x" }
  U{"rima.sum{q=Q}(x[q])", S="sum{q in Q}(x[q])"}
  U{"rima.sum{r=R}(x[r])", S="sum{r in R}(x[r])", ES="x.a + x.b + x.c"}

  U{"rima.sum{r=R}(y[r])", S="sum{r in R}(y[r])", ES=6}

  U{"rima.sum{q=Q}(x*v)", S="sum{q in Q}(v*x)" }
  U{"rima.sum{q=Q}(x[q]*y[q])", S="sum{q in Q}(x[q]*y[q])"}  
  U{"rima.sum{r=R}(x[r]*y[r])", S="sum{r in R}(x[r]*y[r])", ES="x.a + 2*x.b + 3*x.c"}
  U{"rima.sum{q=Q, R=R}(x[q][R])", S="sum{R in R, q in Q}(x[q, R])", ES="sum{q in Q}(x[q].a + x[q].b + x[q].c)"}
  U{"rima.sum{q=Q, r=R}(x[q][r])", S="sum{q in Q, r in R}(x[q, r])", ES="sum{q in Q}(x[q].a + x[q].b + x[q].c)"}
  U{"rima.sum{q=Q, r=R}(x[q][r] * y[q])", S="sum{q in Q, r in R}(x[q, r]*y[q])", ES="sum{q in Q}(x[q].a*y[q] + x[q].b*y[q] + x[q].c*y[q])"}
  U{"rima.sum{q=Q, r=R}(x[q][r] * y[r])", S="sum{q in Q, r in R}(x[q, r]*y[r])", ES="sum{q in Q}(x[q].a + 2*x[q].b + 3*x[q].c)"}

  U{"rima.sum{Q=Q, R=R}(x[Q][R])", S="sum{Q in Q, R in R}(x[Q, R])", ES="sum{Q in Q}(x[Q].a + x[Q].b + x[Q].c)"}
  U{"rima.sum{Q=Q, R=R}(z[Q][R])", S="sum{Q in Q, R in R}(z[Q, R])", ES="sum{Q in Q}(z[Q].a + z[Q].b + z[Q].c)"}
  U{"rima.sum{V=V, Q=Q}(x[V][Q])", S="sum{Q in Q, V in V}(x[V, Q])", ES="sum{Q in Q}(x.d[Q] + x.e[Q])"}
  U{"rima.sum{R=R, V=V}(x[R][V])", S="sum{R in R, V in V}(x[R, V])", ES="x.a.d + x.a.e + x.b.d + x.b.e + x.c.d + x.c.e"}
  U{"rima.sum{R=R, V=V}(z[R][V])", S="sum{R in R, V in V}(z[R, V])", ES=21}

  -- Recursive indexes
  local U = expression_tester(T, "x, y, q, Q, R, r, V", { Q={"a", "b"}, R={ a={ "x", "y" }, b={ "y", "z" } }, y={ x=1, y=2, z=3} })
  U{"rima.sum{q=Q, r=R[q]}(x[r])", S="sum{q in Q, r in R[q]}(x[r])", ES="x.x + 2*x.y + x.z"}
  U{"rima.sum{Q=Q, r=R[Q]}(x[r])", S="sum{Q in Q, r in R[Q]}(x[r])", ES="x.x + 2*x.y + x.z"}
  U{"rima.sum{V=V, r=R[V]}(x[r])", S="sum{V in V, r in R[V]}(x[r])", ES="sum{V in V, r in R[V]}(x[r])"}
  U{"rima.sum{Q=Q, r=V[Q]}(x[r])", S="sum{Q in Q, r in V[Q]}(x[r])", ES="sum{r in V.a}(x[r]) + sum{r in V.b}(x[r])"}
  U{"rima.sum{Q=Q, r=R[Q]}(y[r])", S="sum{Q in Q, r in R[Q]}(y[r])", ES=8}

  -- Ranges
  local y, z = rima.R"y, z"
  local U = expression_tester(T, "x, Y, y, Z, z", { Y=rima.range(1, y), Z=rima.range(1, z), z=5 })
--  U{"rima.sum{x=Y}(x)", S="sum{x in Y}(x)", ES="sum{x in range(1, y)}(x)", ED="sum({x in range(1, ref(y))}, ref(x))"}
  U{"rima.sum{x=Z}(x)", S="sum{x in Z}(x)", ES=15}
  U{"rima.sum{x=Z}(x * y)", S="sum{x in Z}(x*y)", ES=15*y}

  do
    local x, X = rima.R"x, X"
    local S = scope.new{ X={{y=rima.free()},{y=rima.free()},{y=rima.free()}} }
    local S2 = scope.new(S, { X={{y=1},{y=2},{y=3}} })
    local e1 = rima.sum({["_, x"]=rima.ipairs(X)}, x.y)

--    T:check_equal(TYPE(X[1].y, S), rima.free())
    T:check_equal(E(X[1].y, S), "X[1].y")

    T:check_equal(e1, "sum{_, x in ipairs(X)}(x.y)")
--    T:check_equal(D(e1), "sum({_, x in ipairs(ref(X))}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e1, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e1, S2), 6)

    local e2 = rima.sum({X=X}, X.y)
    T:check_equal(e2, "sum{X in X}(X.y)")
--    T:check_equal(D(e2), "sum({X in ref(X)}, index(ref(X), address{\"y\"}))")
    T:check_equal(E(e2, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e2, S2), 6)

    local e3 = rima.sum({x=X}, x.y)
    T:check_equal(e3, "sum{x in X}(x.y)")
--    T:check_equal(D(e3), "sum({x in ref(X)}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e3, S), "X[1].y + X[2].y + X[3].y")
    T:check_equal(E(e3, S2), 6)
  end

  do
    local x, X, i = rima.R"x, X, i"
    local S = scope.new()
    S.X[i].y = rima.free()
    local S2 = scope.new(S, { X={{y=1},{y=2},{y=3}} })
    
--    T:check_equal(TYPE(X[1].y, S), rima.free())
    T:check_equal(E(X[1].y, S), "X[1].y")

    local e1 = rima.sum({["_, x"]=rima.ipairs(X)}, x.y)
    T:check_equal(e1, "sum{_, x in ipairs(X)}(x.y)")
--    T:check_equal(D(e1), "sum({_, x in ipairs(ref(X))}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e1, S), "sum{_, x in ipairs(X)}(x.y)")
    T:check_equal(E(e1, S2), 6)

    local e2 = rima.sum({X=X}, X.y)
    T:check_equal(e2, "sum{X in X}(X.y)")
--    T:check_equal(D(e2), "sum({X in ref(X)}, index(ref(X), address{\"y\"}))")
    T:check_equal(E(e2, S), "sum{X in X}(X.y)")
    T:check_equal(E(rima.sum{x=X}(x.y), S2), 6)
    T:check_equal(E(e2, S2), 6)

    local e3 = rima.sum({x=X}, x.y)
    T:check_equal(e3, "sum{x in X}(x.y)")
--    T:check_equal(D(e3), "sum({x in ref(X)}, index(ref(x), address{\"y\"}))")
    T:check_equal(E(e3, S), "sum{x in X}(x.y)")
    T:check_equal(E(e3, S2), 6)
  end

  do
    local x, X, i = rima.R"x, X, i"
    local S = scope.new()
    S.X[i].y = rima.free()
    local S2 = scope.new(S, { X={{z=11}} })
    local S3 = scope.new(S, { X={{z=11},{z=13},{z=17}} })
    local e

    T:check_equal(E(X[1].y, S), "X[1].y")
    T:check_equal(E(X[1].y, S2), "X[1].y")
    T:check_equal(E(X[1].y, S3), "X[1].y")

    e = rima.sum{["_, x"]=rima.ipairs(X)}(x.y)
    T:check_equal(e, "sum{_, x in ipairs(X)}(x.y)")
    T:check_equal(E(e, S2), "X[1].y")
    T:check_equal(E(e, S3), "X[1].y + X[2].y + X[3].y")

    e = rima.sum{["_, x"]=rima.ipairs(X)}(x.y * x.z)
    T:check_equal(e, "sum{_, x in ipairs(X)}(x.y*x.z)")
    T:check_equal(E(e, S2), "11*X[1].y")
    T:check_equal(E(e, S3), "11*X[1].y + 13*X[2].y + 17*X[3].y")

    e = rima.sum{X=X}(X.y)
    T:check_equal(e, "sum{X in X}(X.y)")
    T:check_equal(E(e, S2), "X[1].y")
    T:check_equal(E(e, S3), "X[1].y + X[2].y + X[3].y")

    e = rima.sum{X=X}(X.y * X.z)
    T:check_equal(e, "sum{X in X}(X.y*X.z)")
    T:check_equal(E(e, S2), "11*X[1].y")
    T:check_equal(E(e, S3), "11*X[1].y + 13*X[2].y + 17*X[3].y")

    e = rima.sum{x=X}(x.y)
    T:check_equal(e, "sum{x in X}(x.y)")
    T:check_equal(E(e, S2), "X[1].y")
    T:check_equal(E(e, S3), "X[1].y + X[2].y + X[3].y")

    e = rima.sum{x=X}(x.y * x.z)
    T:check_equal(e, "sum{x in X}(x.y*x.z)")
    T:check_equal(E(e, S2), "11*X[1].y")
    T:check_equal(E(e, S3), "11*X[1].y + 13*X[2].y + 17*X[3].y")
  end

  -- sums in sums
  do
    local A, i, I, j, J = rima.R"A, i, I, j, J"

    local e = rima.sum{i=I}(rima.sum{j=J}(A[i][j]))
    local S =
    {
      A = {{3, 5, 7}, {11, 13, 19}},
      I = rima.range(1,2),
      J = rima.range(1,3),
    }
    T:check_equal(E(e, S), 58)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

