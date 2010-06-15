-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local scope = require("rima.scope")
local expression = require("rima.expression")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local B = expression.bind
  local E = expression.eval

  local b = rima.R"b"
  local S = scope.new{ a = rima.free() }

--  local t
--  T:expect_error(function() t = rima.tabulate({1}, 3) end, "expected string or simple reference, got '1' %(number%)")
--  T:expect_error(function() rima.tabulate({S.a}, 3) end, "expected string or simple reference, got 'a' %(ref%)")
--  T:expect_error(function() rima.tabulate({b[10]}, 3) end, "expected string or simple reference, got 'b%[10%]' %(index%)")
--  T:expect_ok(function() t = rima.tabulate({"a", "b", "c"}, 3) end, "constructing tabulate")

  do
    local v, w, x, y, z = rima.R"v, w, x, y, z"
    local S = scope.new()
    S.x[{y="Y"}] = y + 1
    T:check_equal(E(x[1], S), 2)
    S.z[y] = y + 2
    T:check_equal(E(z[1], S), 3)
    S.v[x][y][{z="Z"}] = x * y * z
    T:check_equal(E(v[2][3][4], S), 24)
    S.w[x][y][z] = x * y * z
    T:check_equal(E(w[2][3][4], S), 24)
  end

  do
    local Q, x, y = rima.R"Q, x, y"
    local e = rima.sum({Q}, x[Q])
    local S = scope.new{ Q={4, 5, 6} }
    S.x[y] = y^2
    T:check_equal(E(x[3], S), 9)
    T:check_equal(E(e, S), 77)
    T:expect_error(function() E(x[1][2], S) end,
      "error evaluating 'x%[1, 2%]' as 'y%^2%[2%]':.*address: error resolving 'y%^2%[2%]': 'y%^2' is not indexable %(got '1' number%)")
  end

  do
    local t, x, y = rima.R"t, x, y"
    local S = scope.new{ x=1 }
    S.t[y] = y + x[1]
    T:expect_error(function() rima.E(t[1], S) end,
      "tabulate: error evaluating 'tabulate%({y}, y %+ x%[1%]%)' as 'y %+ x%[1%]' where y=1:")
  end

  do
    local x, y, z = rima.R"x, y, z"
    local S = scope.new()
    S.x[y][z] = y * z
    T:check_equal(rima.E(x[2][3], S), 6)
  end

  do
    local a, b, c, t, s, u = rima.R"a, b, c, t, s, u"
    local S = scope.new{ a={w={{x=10,y={z=100}},{x=20,y={z=200}}}} }
    S.t[b] = a.w[b].x
    S.s[b] = a.w[b].y
    S.u[b] = a.q[b].y

    T:check_equal(t[1], "t[1]")
    T:expect_ok(function() B(t[1], S) end, "binding")
    T:check_equal(B(t[1], S), "a.w[1].x")
    T:expect_ok(function() E(t[1], S) end, "eval")
    T:check_equal(E(t[1], S), 10)
    T:check_equal(E(t[2], S), 20)
    local e = B(t[1], S)
    T:check_equal(E(e, S), 10)

    T:check_equal(s[1].z, "s[1].z")
    T:expect_ok(function() B(s[1].z, S) end, "binding")
    T:check_equal(B(s[1].z, S), "a.w[1].y.z")
    T:expect_ok(function() E(s[1].z, S) end, "eval")
    T:check_equal(E(s[1].z, S), 100)
    T:check_equal(E(s[2].z, S), 200)
    local e = B(s[1].z, S)
    T:check_equal(E(e, S), 100)

    T:check_equal(s[1].q, "s[1].q")
    T:expect_ok(function() B(s[1].q, S) end, "binding")
    T:check_equal(B(s[1].q, S), "a.w[1].y.q")
    T:expect_ok(function() E(s[1].q, S) end, "eval")
    T:check_equal(E(s[1].q, S), "a.w[1].y.q")
    T:check_equal(E(s[2].q, S), "a.w[2].y.q")
    local e = B(s[1].q, S)
    T:check_equal(E(e, S), "a.w[1].y.q")

    T:check_equal(u[1].z, "u[1].z")
    T:expect_ok(function() B(u[1].z, S) end, "binding")
    T:check_equal(B(u[1].z, S), "a.q[1].y.z")
    T:expect_ok(function() E(u[1].z, S) end, "eval")
    T:check_equal(E(u[1].z, S), "a.q[1].y.z")
    T:check_equal(E(u[2].z, S), "a.q[2].y.z")
    local e = B(u[1].z, S)
    T:check_equal(E(e, S), "a.q[1].y.z")
  end

  do
    local a, b, i = rima.R"a, b, i"
    local S = rima.scope.new{ a = { { 5 } } }
    S.b[i] = a[1][i]
    T:check_equal(E(a[1][1], S), 5)
    T:check_equal(E(b[1], S), 5)
    T:expect_error(function() E(b[1][1], S) end,
      "address: error evaluating 'b%[1, 1%]' as 'a%[1, 1, 1%]':.*address: error resolving 'a%[1, 1, 1%]': 'a%[1, 1%]' is not indexable %(got '5' number%)")
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

