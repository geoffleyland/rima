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
    scope.set(S, { ["x, y"] = rima.positive() })
    local objective, r = mp.solve("lpsolve", S)

    T:check_equal(objective, 2)
    T:check_equal(r.x.p, 1)
    T:check_equal(r.y.p, 1)
    T:check_equal(r.c1.p, 3)
    T:check_equal(r.c2.p, 3)
  end

  do
    local m, M, n, N = rima.R"m, M, n, N"
    local A, b, c, x = rima.R"A, b, c, x"
    local S = rima.scope.new()
    S.constraint[{m=M}] = constraint:new(rima.sum{n=N}(A[m][n] * x[n]), "<=", b[m])
    S.objective = rima.sum{n=N}(c[n] * x[n])
    S.sense = "maximise"
    S.x[n] = rima.positive()

    local objective, r = mp.solve("lpsolve", S,
      {
        M = rima.range(1, 2),
        N = rima.range(1, 2),
        A = {{1, 2}, {2, 1}},
        b = {3, 3},
        c = {1, 1},
      })
    T:check_equal(objective, 2)
    T:check_equal(r.x[1].p, 1)
    T:check_equal(r.x[2].p, 1)
    T:check_equal(r.constraint[1].p, 3)
    T:check_equal(r.constraint[2].p, 3)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------
