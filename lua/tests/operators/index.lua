-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local expression = require("rima.expression")
local iteration = require("rima.iteration")
local lib = require("rima.lib")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local B = expression.bind
  local E = expression.eval
  local D = lib.dump

  local a, b, c = rima.R"a, b, c"

  -- index tests
  T:check_equal(D(a[b]), "index(ref(a), address(ref(b)))")
  T:check_equal(a[b], "a[b]")
  T:check_equal(a[b][c], "a[b, c]")

  do
    local S = rima.scope.new{ a={ "x", "y" }, b = 2}
    T:check_equal(rima.E(a[b], S), "y")
  end

  do
    local S = rima.scope.new{ a=rima.types.undefined_t:new(), b = 2}
    T:check_equal(D(a[b]), "index(ref(a), address(ref(b)))")
    T:check_equal(D(E(a[b], S)), "index(ref(a), address(2))")
    local e = E(a[b], S)
    T:check_equal(D(e), "index(ref(a), address(2))")
    S2 = rima.scope.spawn(S, {a = { "x" }})
    T:check_equal(D(S2.a), "ref(a)")
    T:check_equal(S2.a[1], "x")
    T:check_equal(D(S2.a[2]), "index(ref(a), address(2))")
    T:check_equal(D(E(e, S2)), "index(ref(a), address(2))")
    T:expect_ok(function() S2.a[2] = "yes" end, "setting a table field")
    T:check_equal(D(E(e, S2)), "\"yes\"")

    S3 = rima.scope.spawn(S, {a = { b="x" }})
    T:check_equal(D(E(a.b, S)), "index(ref(a), address(\"b\"))")
    T:check_equal(D(E(a.b, S3)), "\"x\"")
  end

  do
    local x, y, N = rima.R"x,y,N"
    local S = rima.scope.new{ N={ {1, 2}, {3, 4} } }
    T:check_equal(D(N[x][y]), "index(ref(N), address(ref(x), ref(y)))")
    T:check_equal(E(N[x][y], S), "N[x, y]")
    S.x = 2
    T:check_equal(E(N[x][y], S), "N[2, y]")
    T:check_equal(E(N[y][x], S), "N[y, 2]")
    S.y = 1
    T:check_equal(E(N[x][y], S), 3)
    T:check_equal(E(N[y][x], S), 2)
  end

  do
    local a, b = rima.R"a, b"
    local t = { b = { x = { y = 3}, z = 10 } }
    expression.set(a.b.c, t, 10)
    T:check_equal(t.a.b.c, 10)
    T:expect_error(function() expression.set(b.z.b, t, 5) end, "error setting 'b%.z%.b' to 5: field is not a table %(10%)")
    T:expect_error(function() expression.set(b.x.y, t, 5) end, "error setting 'b%.x%.y' to 5: field already exists %(3%)")
  end

  do
    local a, b, c = rima.R"a, b, c"
    local S = rima.scope.new{ a={x={y={z=3}}}, b={s={t=a.x.y}}, c={s={t=a.q}} }  -- note that c is undefined
    T:check_equal(D(b.s.t), "index(ref(b), address(\"s\", \"t\"))")
    T:check_equal(b.s.t, "b.s.t")
    T:check_equal(D(B(b.s.t, S)), "index(ref(a), address(\"x\", \"y\"))")
    T:check_equal(B(b.s.t, S), "a.x.y")
    T:check_equal(E(b.s.t, S), "a.x.y")

    T:check_equal(D(b.s.t.z), "index(ref(b), address(\"s\", \"t\", \"z\"))")
    T:check_equal(b.s.t.z, "b.s.t.z")
    T:check_equal(D(B(b.s.t.z, S)), "index(ref(a), address(\"x\", \"y\", \"z\"))")
    T:check_equal(B(b.s.t.z, S), "a.x.y.z")
    T:check_equal(E(b.s.t.z, S), 3)

    T:check_equal(D(B(c.s.t, S)), "index(ref(a), address(\"q\"))")
    T:check_equal(B(c.s.t, S), "a.q")
    T:check_equal(E(c.s.t, S), "a.q")

    T:check_equal(D(B(c.s.t.z, S)), "index(ref(a), address(\"q\", \"z\"))")
    T:check_equal(B(c.s.t.z, S), "a.q.z")
    T:check_equal(E(c.s.t.z, S), "a.q.z")
  end

  do
    local f, p, s, x, z, xmax, xmin, points = rima.R"f, p, s, x, z, xmax, xmin, points"
    local S = rima.scope.new 
    {
      f = rima.F({x}, rima.exp(x)*rima.sin(x)),
      xmin = 0,
      xmax = 20,
      points = 10,
    }
    S.s[p] = f(x[p])
    S.x[p] = xmin + (xmax - xmin)*p.key/points
    T:check_equal(E(x[{key=1}], S), 2)
    T:check_equal(E(s[{key=1}], S), E(rima.exp(2)*rima.sin(2)))
  end

  do
    local S = rima.scope.new()
    S.e = 1
    S.f.g = 2
    S.h.i.j = 3
    S.k.l.m.n = 4

    T:check_equal(S.e, 1)    
    T:check_equal(S.f.g, 2)    
    T:check_equal(S.h.i.j, 3)    
    T:check_equal(S.k.l.m.n, 4)    
  end

  do
    local e, f, g, h, i, j, k = rima.R"e, f, g, h, i, j, k"
    local S = rima.scope.new()
    S.e = rima.free()
    S.f[i] = rima.free()
    S.g[i][j] = rima.free()
    S.h[i][j][k] = rima.free()

    T:check_equal(expression.type(e, S), "-inf <= * <= inf, * real")
    T:check_equal(expression.type(f[1], S), "-inf <= * <= inf, * real")
    T:check_equal(expression.type(g.a[2], S), "-inf <= * <= inf, * real")
    T:check_equal(expression.type(h[3].b[8], S), "-inf <= * <= inf, * real")
  end

  return T:close()
end

-- EOF -------------------------------------------------------------------------

