-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local object = require("rima.object")
local scope = require("rima.scope")
local expression = require("rima.expression")
local ref = require("rima.ref")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)
  
  local D = expression.dump

  T:test(object.isa(ref:new{name="a"}, ref), "isa(ref:new(), ref)")

  local function check_strings(v, s, d)
    T:check_equal(v, s, "tostring(ref)")
    T:check_equal(ref.describe(v), d, "ref:describe()")
  end

  check_strings(ref:new{name="a"}, "a", "a undefined")
  check_strings(ref:new{name="b", type=rima.free()}, "b", "-inf <= b <= inf, b real")  
  check_strings(ref:new{name="c", type=rima.positive()}, "c", "0 <= c <= inf, c real")  
  check_strings(ref:new{name="d", type=rima.negative()}, "d", "-inf <= d <= 0, d real")  
  check_strings(ref:new{name="e", type=rima.integer()}, "e", "0 <= e <= inf, e integer")  
  check_strings(ref:new{name="f", type=rima.binary()}, "f", "f binary")  

  local S = rima.scope.create{ a = rima.free(1, 10), b = 1, c = "c" }

  T:expect_ok(function() ref.eval(ref:new{name="z"}, S) end, "z undefined")
  T:check_equal(ref.eval(ref:new{name="z"}, S), "z", "undefined remains an unbound variable")
  T:expect_error(function() ref.eval(ref:new{name="a", type=rima.free(11, 20)}, S) end,
    "the type of 'a' %(1 <= a <= 10, a real%) and the type of the reference %(11 <= a <= 20, a real%) are mutually exclusive")
  T:expect_error(function() ref.eval(ref:new{name="b", type=rima.free(11, 20)}, S) end,
    "'b' %(1%) is not of type '11 <= b <= 20, b real'")
  T:check_equal(ref.eval(ref:new{name="a"}, S), "a")
  T:check_equal(ref.eval(ref:new{name="b", rima.binary()}, S), 1)


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

  -- tests for references to references
  -- tests for references to functions
  -- tests for references to expressions

  return T:close()
end

-- EOF -------------------------------------------------------------------------

