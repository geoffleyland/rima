-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local expression = require("rima.expression")
local iteration = require("rima.iteration")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local B = expression.bind
  local E = expression.eval
  local D = expression.dump

  local a, b, c = rima.R"a, b, c"

  -- index tests
  T:check_equal(D(a[b]), "index(ref(a), address(ref(b)))")
  T:check_equal(a[b], "a[b]")
  T:check_equal(a[b][c], "a[b, c]")

  do
    local S = rima.scope.create{ a={ "x", "y" }, b = 2}
    T:check_equal(rima.E(a[b], S), "y")
  end

  do
    local S = rima.scope.create{ a=rima.types.undefined_t:new(), b = 2}
    T:check_equal(D(a[b]), "index(ref(a), address(ref(b)))")
    T:check_equal(D(E(a[b], S)), "index(ref(a), address(number(2)))")
    local e = E(a[b], S)
    T:check_equal(D(e), "index(ref(a), address(number(2)))")
    S2 = rima.scope.spawn(S, {a = { "x" }})
    T:check_equal(D(E(e, S2)), "index(ref(a), address(number(2)))")
    S2.a[2] = "yes"
    T:check_equal(D(E(e, S2)), "string(yes)")    

    S3 = rima.scope.spawn(S, {a = { b="x" }})
    T:check_equal(D(E(a.b, S)), "index(ref(a), address(string(b)))")
    T:check_equal(D(E(a.b, S3)), "string(x)")
  end

  do
    local x, y, N = rima.R"x,y,N"
    local S = rima.scope.create{ N={ {1, 2}, {3, 4} } }
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
    local a, b, i = rima.R"a, b, i"
    local S = rima.scope.create{ a = { 5 }, b = { c=3 }, i = iteration.element:new({}, 1, "c") }
    T:check_equal(E(a[i] * b[i], S), 15)
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
    local S = rima.scope.create{ a={x={y={z=3}}}, b={s={t=a.x.y}}, c={s={t=a.q}} }  -- note that c is undefined
    T:check_equal(D(b.s.t), "index(ref(b), address(string(s), string(t)))")
    T:check_equal(b.s.t, "b.s.t")
    T:check_equal(D(B(b.s.t, S)), "index(ref(a), address(string(x), string(y)))")
    T:check_equal(B(b.s.t, S), "a.x.y")
    T:check_equal(E(b.s.t, S), "a.x.y")

    T:check_equal(D(b.s.t.z), "index(ref(b), address(string(s), string(t), string(z)))")
    T:check_equal(b.s.t.z, "b.s.t.z")
    T:check_equal(D(B(b.s.t.z, S)), "index(ref(a), address(string(x), string(y), string(z)))")
    T:check_equal(B(b.s.t.z, S), "a.x.y.z")
    T:check_equal(E(b.s.t.z, S), 3)

    T:check_equal(D(B(c.s.t, S)), "index(ref(a), address(string(q)))")
    T:check_equal(B(c.s.t, S), "a.q")
    T:check_equal(E(c.s.t, S), "a.q")

    T:check_equal(D(B(c.s.t.z, S)), "index(ref(a), address(string(q), string(z)))")
    T:check_equal(B(c.s.t.z, S), "a.q.z")
    T:check_equal(E(c.s.t.z, S), "a.q.z")
  end

  do
    local f, p, s, x, z, xmax, xmin, points = rima.R"f, p, s, x, z, xmax, xmin, points"
    local S = rima.scope.create
    {
      s = rima.tabulate({p}, f(x[p])),
      f = rima.F({x}, rima.exp(x)*rima.sin(x)),
      x = rima.tabulate({p},  xmin + (xmax - xmin)*p.key/points),
      xmin = 0,
      xmax = 20,
      points = 10,
    }
    T:check_equal(E(x[{key=1}], S), 2)
    T:check_equal(E(s[{key=1}], S), E(rima.exp(2)*rima.sin(2)))
  end

  return T:close()
end

-- EOF -------------------------------------------------------------------------

