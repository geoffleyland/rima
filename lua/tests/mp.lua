-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local mp = require("rima.mp")

local series = require("test.series")
local lib = require("rima.lib")
local constraint = require("rima.mp.constraint")
local index = require("rima.index")
local number_t = require("rima.types.number_t")
local sum = require("rima.operators.sum")
local sets = require("rima.sets")

local math = require("math")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local R = index.R

  do
    local x, y = R"x, y"
    local S = mp.new()
    S.c1 = constraint:new(x + 2*y, "<=", 3)
    S.c2 = constraint:new(2*x + y, "<=", 3)
    S.objective = x + y
    S.sense = "maximise"
    S.x = number_t.positive()
    S.y = number_t.positive()
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

    local primal, dual = mp.solve(S)
    if primal then
      T:check_equal(primal.objective, 2)
      T:check_equal(primal.x, 1)
      T:check_equal(primal.y, 1)
      T:check_equal(primal.c1, 3)
      T:check_equal(primal.c2, 3)
      T:check_equal(math.abs(dual.x), 0)
      T:check_equal(math.abs(dual.y), 0)
      T:check_equal(dual.c1, 1/3)
      T:check_equal(dual.c2, 1/3)
    end
  end

  do
    local x, i, j = R"x, i, j"
    local S = mp.new()
    S.c1 = constraint:new(x[1][1].a + 2*x[1][2].a, "<=", 3)
    S.c2 = constraint:new(2*x[1][1].a + x[1][2].a, "<=", 3)
    S.objective = x[1][1].a + x[1][2].a
    S.sense = "maximise"
    S.x[i][j].a = number_t.positive()
    T:check_equal(S,
[[
Maximise:
  x[1, 1].a + x[1, 2].a
Subject to:
  c1: x[1, 1].a + 2*x[1, 2].a <= 3
  c2: 2*x[1, 1].a + x[1, 2].a <= 3
  0 <= x[i, j].a <= inf, x[i, j].a real for all i, j
]])

    local primal, dual = mp.solve_with("cbc", S)

    if primal then
      T:check_equal(primal.objective, 2)
      T:check_equal(primal.x[1][1].a, 1)
      T:check_equal(primal.x[1][2].a, 1)
      T:check_equal(primal.c1, 3)
      T:check_equal(primal.c2, 3)
    end
  end

  do
    local m, M, n, N = R"m, M, n, N"
    local A, b, c, x = R"A, b, c, x"
    local S = mp.new()
    S.constraint[{m=M}] = constraint:new(sum.build{n=N}(A[m][n] * x[n]), "<=", b[m])
    S.objective = sum.build{n=N}(c[n] * x[n])
    S.sense = "maximise"
    S.x[n] = number_t.positive()
    T:check_equal(S,
[[
Maximise:
  sum{n in N}(c[n]*x[n])
Subject to:
  constraint[m in M]: sum{n in N}(A[m, n]*x[n]) <= b[m]
  0 <= x[n] <= inf, x[n] real for all n
]])

    local primal, dual = mp.solve_with("lpsolve", S,
      {
        M = sets.range(1, 2),
        N = sets.range(1, 2),
        A = {{1, 2}, {2, 1}},
        b = {3, 3},
        c = {1, 1},
      })

    if primal then
      T:check_equal(primal.objective, 2)
      T:check_equal(primal.x[1], 1)
      T:check_equal(primal.x[2], 1)
      T:check_equal(primal.constraint[1], 3)
      T:check_equal(primal.constraint[2], 3)
    end
  end

  do
    local a, p, P, q, Q = R"a, p, P, q, Q"
    local S = mp.new()
    S.constraint1[{p=P}][{q=P[p].Q}] = constraint:new(a, "<=", P[p].Q[q])
    S.constraint2[{p=P}][{q=p.Q}] = constraint:new(a, "<=", q)
    T:check_equal(S,
[[
No objective defined
Subject to:
  constraint1[p in P, q in P[p].Q]: a <= P[p].Q[q]
  constraint2[p in P, q in p.Q]:    a <= q
]])
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
