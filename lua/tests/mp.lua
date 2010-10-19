-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local mp = require("rima.mp")

local series = require("test.series")
local lib = require("rima.lib")
local constraint = require("rima.mp.constraint")

local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  do
    local x, y = rima.R"x, y"
    local S = mp.new()
    S.c1 = constraint:new(x + 2*y, "<=", 3)
    S.c2 = constraint:new(2*x + y, "<=", 3)
    S.objective = x + y
    S.sense = "maximise"
    S.x = rima.positive()
    S.y = rima.positive()
    T:check_equal(lib.repr(S),
[[
Maximise:
  x + y
Subject to:
  c1: x + 2*y <= 3
  c2: 2*x + y <= 3
  0 <= x <= inf, x real
  0 <= y <= inf, y real
]])

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
    local S = mp.new()
    S.c1 = constraint:new(x[1][1].a + 2*x[1][2].a, "<=", 3)
    S.c2 = constraint:new(2*x[1][1].a + x[1][2].a, "<=", 3)
    S.objective = x[1][1].a + x[1][2].a
    S.sense = "maximise"
    S.x[i][j].a = rima.positive()
    T:check_equal(S,
[[
Maximise:
  x[1, 1].a + x[1, 2].a
Subject to:
  c1: x[1, 1].a + 2*x[1, 2].a <= 3
  c2: 2*x[1, 1].a + x[1, 2].a <= 3
  0 <= x[i, j].a <= inf, x[i, j].a real for all i, j
]])

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
    local S = mp.new()
    S.constraint[{m=M}] = constraint:new(rima.sum{n=N}(A[m][n] * x[n]), "<=", b[m])
    S.objective = rima.sum{n=N}(c[n] * x[n])
    S.sense = "maximise"
    S.x[n] = rima.positive()
    T:check_equal(S,
[[
Maximise:
  sum{n in N}(c[n]*x[n])
Subject to:
  constraint[m]: sum{n in N}(A[m, n]*x[n]) <= b[m]
  0 <= x[n] <= inf, x[n] real for all n
]])

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

  do
    local a, p, P, q, Q = rima.R"a, p, P, q, Q"
    local S = rima.mp.new()
    S.constraint1[{p=P}][{q=P[p].Q}] = constraint:new(a, "<=", P[p].Q[q])
    S.constraint2[{p=P}][{q=p.Q}] = constraint:new(a, "<=", q)
    S.P = {{Q={3,5}},{Q={7,11,13}}}
    T:check_equal(S,
[[
No objective defined
Subject to:
  constraint1[1, 3]:  a <= 3
  constraint1[1, 5]:  a <= 5
  constraint1[2, 7]:  a <= 7
  constraint1[2, 11]: a <= 11
  constraint1[2, 13]: a <= 13
  constraint2[1, 3]:  a <= 3
  constraint2[1, 5]:  a <= 5
  constraint2[2, 7]:  a <= 7
  constraint2[2, 11]: a <= 11
  constraint2[2, 13]: a <= 13
]])
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------
