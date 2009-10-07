-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
local ref = require("rima.ref")
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

  T:test(object.isa(ref:new{name="a"}, ref), "isa(ref:new(), ref)")

  local function check_strings(v, s, d)
    T:check_equal(v, s, "repr(ref)")
    T:check_equal(ref.describe(v), d, "ref:describe()")
  end

  check_strings(ref:new{name="a"}, "a", "a undefined")
  check_strings(ref:new{name="b", type=rima.free()}, "b", "-inf <= b <= inf, b real")  
  check_strings(ref:new{name="c", type=rima.positive()}, "c", "0 <= c <= inf, c real")  
  check_strings(ref:new{name="d", type=rima.negative()}, "d", "-inf <= d <= 0, d real")  
  check_strings(ref:new{name="e", type=rima.integer()}, "e", "0 <= e <= inf, e integer")  
  check_strings(ref:new{name="f", type=rima.binary()}, "f", "f binary")  

  -- simple references and types
  do
    local S = rima.scope.create{ a = rima.free(1, 10), b = 1, c = "c" }

    -- binding
    T:expect_ok(function() B(ref:new{name="z"}, S) end, "bind ok")
    T:check_equal(B(ref:new{name="z"}, S), "z", "undefined returns a ref")
    T:check_equal(B(ref:new{name="b"}, S), "b", "defined returns a ref")

    -- simple reference evaluating
    T:expect_ok(function() E(ref:new{name="z"}, S) end, "z undefined")
    T:check_equal(E(ref:new{name="z"}, S), "z", "undefined remains an unbound variable")
    T:check_equal(E(ref:new{name="b"}, S), 1, "defined returns a value")

    -- types
    T:check_equal(E(ref:new{name="a"}, S), "a")
    T:expect_error(function() E(ref:new{name="a", type=rima.free(11, 20)}, S) end,
      "the type of 'a' %(1 <= a <= 10, a real%) and the type of the reference %(11 <= a <= 20, a real%) are mutually exclusive")
    T:expect_error(function() E(ref:new{name="b", type=rima.free(11, 20)}, S) end,
      "'b' %(1%) is not of type '11 <= b <= 20, b real'")
    T:check_equal(E(ref:new{name="b", rima.binary()}, S), 1)
  end

  -- references to references
  do
    local a, b, c = rima.R"a, b, c"
    local S1 = rima.scope.create{ a = b, b = 17 }
    local S2 = rima.scope.create{ a = b - c, b = 1 }
    
    -- binding
    T:check_equal(B(a, S1), "b")
    T:check_equal(B(a, S2), "b - c")

    -- evaluating
    T:check_equal(E(a, S1), 17)
    T:check_equal(E(a, S2), "1 - c")
  end

  -- index tests
  local a, b, c = rima.R"a, b, c"
  T:check_equal(D(a[b]), "ref(a[ref(b)])")
  T:check_equal(a[b], "a[b]")
  T:check_equal(a[b][c], "a[b, c]")

  do
    local S = rima.scope.create{ a={ "x", "y" }, b = 2}
    T:check_equal(rima.E(a[b], S), "y")
  end

  do
    local S = rima.scope.create{ a=rima.types.undefined_t:new(), b = 2}
    T:check_equal(D(a[b]), "ref(a[ref(b)])")
    T:check_equal(D(rima.E(a[b], S)), "ref(a[number(2)])")
    local e = rima.E(a[b], S)
    T:check_equal(D(e), "ref(a[number(2)])")
    S2 = scope.spawn(S, {a = { "x" }})
    T:check_equal(D(rima.E(e, S2)), "ref(a[number(2)])")
    S2.a[2] = "yes"
    T:check_equal(D(rima.E(e, S2)), "string(yes)")    

    S3 = scope.spawn(S, {a = { b="x" }})
    T:check_equal(D(rima.E(a.b, S)), "ref(a[string(b)])")
    T:check_equal(D(rima.E(a.b, S3)), "string(x)")
  end

  do
    local x, y, N = rima.R"x,y,N"
    local S = rima.scope.create{ N={ {1, 2}, {3, 4} } }
    T:check_equal(D(N[x][y]), "ref(N[ref(x), ref(y)])")
    T:check_equal(rima.E(N[x][y], S), "N[x, y]")
    S.x = 2
    T:check_equal(rima.E(N[x][y], S), "N[2, y]")
    T:check_equal(rima.E(N[y][x], S), "N[y, 2]")
    S.y = 1
    T:check_equal(rima.E(N[x][y], S), 3)
    T:check_equal(rima.E(N[y][x], S), 2)
  end

  do
    local a = rima.R"a"
    local S = rima.scope.create{ a = rima.free() }
    
    T:check_equal(ref.is_simple(a), true)
    T:check_equal(ref.is_simple(a.b), false)
    T:check_equal(ref.is_simple(a[2]), false)
    T:check_equal(ref.is_simple(E(a, S)), false)
  end

  do
    local a, b, i = rima.R"a, b, i"
    local S = rima.scope.create{ a = { { 5 } }, b = rima.tabulate({i}, a[1][i]) }
    T:check_equal(rima.E(a[1][1], S), 5)
    T:check_equal(rima.E(b[1], S), 5)
    T:expect_error(function() rima.E(b[1][1], S) end, "evaluate: error evaluating 'b%[1, 1%]")
  end

  do
    local a, b, i = rima.R"a, b, i"
    local S = rima.scope.create{ a = { 5 }, b = { c=3 }, i = iteration.element:new({}, 1, "c") }
    T:check_equal(rima.E(a[i] * b[i], S), 15)
  end
  
  do
    local a, b = rima.R"a, b"
    local t = { b = { x = { y = 3}, z = 10 } }
    ref.set(a.b.c, t, 10)
    T:check_equal(t.a.b.c, 10)
    T:expect_error(function() ref.set(b.z.b, t, 5) end, "error setting 'b%.z%.b' to 5: field is not a table %(10%)")
    T:expect_error(function() ref.set(b.x.y, t, 5) end, "error setting 'b%.x%.y' to 5: field already exists %(3%)")
  end   

  do
    local x, y = rima.R"x, y"
    local S = rima.scope.create{ x = 2, y = 3 }
    T:check_equal(rima.E(x + y, S), 5)
    T:check_equal(rima.E(x - y, S), -1)
    T:check_equal(rima.E(-x + y, S), 1)
    T:check_equal(rima.E(x * y, S), 6)
    T:check_equal(rima.E(x / y, S), 2/3)
    T:check_equal(rima.E(x ^ y, S), 8)
  end   

  do
    local f, x, y = rima.R"f, x, y"
    local S = rima.scope.create{ x = 2, f = rima.F({y}, y + 5) }
    T:check_equal(rima.E(f(x), S), 7)
  end   

  -- tests for references to references
  -- tests for references to functions
  -- tests for references to expressions

  return T:close()
end

-- EOF -------------------------------------------------------------------------

