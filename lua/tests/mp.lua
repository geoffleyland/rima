-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local constraint = require("rima.mp.constraint")
local scope = require("rima.scope")
local mp = require("rima.mp")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  do
    local x, y = rima.R"x, y"
    local S = rima.scope.new()
    S.c1 = constraint:new(x + 2*y, "<=", 3)
    S.c2 = constraint:new(2*x + y, "<=", 3)
    S.objective = x + y
    S.sense = "maximise"
    S.x = rima.positive()
    S.y = rima.positive()
    local primal, dual = mp.solve("lpsolve", S)

    T:check_equal(primal.objective, 2)
    T:check_equal(primal.x, 1)
    T:check_equal(primal.y, 1)
    T:check_equal(primal.c1, 3)
    T:check_equal(primal.c2, 3)
    T:check_equal(dual.x, 0)
    T:check_equal(dual.y, 0)
    T:check_equal(dual.c1, 1/3)
    T:check_equal(dual.c2, 1/3)
  end

  do
    local x, i, j = rima.R"x, i, j"
    local S = rima.scope.new()
    S.c1 = constraint:new(x[1][1].a + 2*x[1][2].a, "<=", 3)
    S.c2 = constraint:new(2*x[1][1].a + x[1][2].a, "<=", 3)
    S.objective = x[1][1].a + x[1][2].a
    S.sense = "maximise"
    S.x[i][j].a = rima.positive()

    local primal, dual = mp.solve("lpsolve", S)

    T:check_equal(primal.objective, 2)
    T:check_equal(primal.x[1][1].a, 1)
    T:check_equal(primal.x[1][2].a, 1)
    T:check_equal(primal.c1, 3)
    T:check_equal(primal.c2, 3)
  end

  do
    local m, M, n, N = rima.R"m, M, n, N"
    local A, b, c, x = rima.R"A, b, c, x"
    local S = rima.scope.new()
    S.constraint[{m=M}] = constraint:new(rima.sum{n=N}(A[m][n] * x[n]), "<=", b[m])
    S.objective = rima.sum{n=N}(c[n] * x[n])
    S.sense = "maximise"
    S.x[n] = rima.positive()

    local primal, dual = mp.solve("lpsolve", S,
      {
        M = rima.range(1, 2),
        N = rima.range(1, 2),
        A = {{1, 2}, {2, 1}},
        b = {3, 3},
        c = {1, 1},
      })

    T:check_equal(primal.objective, 2)
    T:check_equal(primal.x[1], 1)
    T:check_equal(primal.x[2], 1)
    T:check_equal(primal.constraint[1], 3)
    T:check_equal(primal.constraint[2], 3)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------
