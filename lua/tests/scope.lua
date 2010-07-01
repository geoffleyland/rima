-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local types = require("rima.types")
local scope = require("rima.scope")
local ref = require("rima.ref")
local expression = require("rima.expression")
local rima = rima

module(...)

-- Test ------------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local D = lib.dump
  local B = expression.bind
  local E = core.eval

  T:test(scope:isa(scope.new()), "isa(scope.new(), scope)")
  T:check_equal(object.type(scope.new()), "scope", "type(scope.new()) == 'scope'")

  local S1 = scope.new()

  -- Setting a variable
  T:expect_ok(function() local a = S1.a end, "undefined ok")
  T:check_equal(D(S1.a), "ref(a)")
  T:expect_ok(function() S1.a = types.undefined_t:new() end)
  local S2 = scope.spawn(S1)
  T:expect_ok(function() S2.a = rima.free() end)
  local S3 = scope.spawn(S2)
  T:expect_error(function() S3.a = types.undefined_t:new() end, "cannot set 'a' to 'undefined': violates existing constraint")
  T:expect_error(function() S3.a = {} end, "cannot set 'a' to 'table.-': violates existing constraint")
  T:expect_error(function() S3.a = "a" end, "cannot set 'a' to 'a': violates existing constraint")
  T:expect_ok(function() S3.a = rima.integer() end)
  T:expect_error(function() S3.a = rima.integer(1, 10) end, "cannot set 'a' to '1 <= %* <= 10, %* integer': existing definition")
  local S4 = scope.spawn(S3)
  T:expect_ok(function() S4.a = rima.integer(1, 10) end)
  T:expect_error(function() S4.a = 11 end, "cannot set 'a' to '11': existing definition")
  T:expect_error(function() S4.a = 3 end, "cannot set 'a' to '3': existing definition")
  local S5 = scope.spawn(S4)
  T:expect_error(function() S5.a = 11 end, "cannot set 'a' to '11': violates existing constraint")
  T:expect_ok(function() S5.a = 3 end)
  T:expect_error(function() S5.a = 4 end, "cannot set 'a' to '4': existing definition as '3'")
  T:expect_error(function() S5.a = 3 end, "cannot set 'a' to '3': existing definition as '3'")
  T:expect_error(function() scope.set(S5, {a=3}) end, "cannot set 'a' to '3': existing definition as '3'")

  T:expect_ok(function() scope.set(S5, { b=7, c=rima.integer(3, 5) }) end)
  T:check_equal(object.type(S5.a), "number", "type(S.a) == 'number'")
  T:check_equal(object.type(S5.c), "ref", "type(S.c) == 'ref'")
  T:check_equal(S5.a, 3, "S.a == 3")
  T:check_equal(S5.c, "c", "s.c == c")
  T:check_equal(scope.lookup(S5, "a"), 3, "scope.lookup(S, 'a') == 3")
  T:check_equal(scope.lookup(S5, "b"), 7, "scope.lookup(S, 'b') == 7")
  T:check_equal(rima.ref.describe(S5.c), "3 <= c <= 5, c integer")

  -- Setting a variable to an expression
  T:expect_ok(function() S5.a2 = S5.a end)
  T:expect_ok(function() S5.c2 = S5.c end)

  local S_no_overwrite = scope.spawn(S5)
  T:check_equal(S_no_overwrite.a, 3, "S.a == 3")
  T:check_equal(S_no_overwrite.c, "c", "S.c == c")
  T:check_equal(scope.lookup(S_no_overwrite, "a"), 3, "S.a == a")
  T:check_equal(scope.lookup(S_no_overwrite, "undefined"), nil, "S.a == a")
  T:expect_error(function() S_no_overwrite.c = 7 end, "cannot set 'c' to '7'")
  T:expect_ok(function() S_no_overwrite.c = 3 end, "can set c to in bounds value")
  T:check_equal(S_no_overwrite.c, 3)
  T:check_equal(rima.ref.describe(S5.c), "3 <= c <= 5, c integer")

  local r = {}
  for k, v in scope.iterate(S5) do
    r[k] = v
  end
  T:check_equal(r.a, 3)
  T:check_equal(r.a2, 3)
  T:check_equal(r.b, 7)
  T:check_equal(r.c, "3 <= * <= 5, * integer")
  T:check_equal(r.c2, "c")
  
  do
    local S1 = scope.new{ a = { b = 1 } }
    local S2 = scope.spawn(S1, { a = { c = 2 } })
    local r = {}
    for k, v in scope.iterate(S2) do r[k] = v end
    T:check_equal(r.a.b, 1)
    T:check_equal(r.a.c, 2)
  end

  do
    local S1 = scope.new()
    local i = rima.R"i"
    S1.a[i] = i
    S1.a[3] = 20
    local r = scope.contents(S1)
    T:check_equal(r.a[1], nil)
    T:check_equal(r.a[3], 20)
    T:check_equal(r.a[scope.free_index_marker], "tabulate({i}, i)")
  end

  do
    local i, j = rima.R"i, j"
    local S = scope.new()
    S.a[i] = i
    T:expect_ok(function() S.a[2] = 10 end)
    T:check_equal(S.a[1], 1)
    T:check_equal(S.a[2], 10)
    T:check_equal(S.a[3], 3)
  end

  do
    local S = scope.new{ c=5 }
    local S_overwrite = scope.spawn(S, nil, {overwrite=true})
    T:expect_ok(function() S_overwrite.c = 7 end, "can overwrite c")
  end

  do
    local S1, S2, S2
    S1 = scope.new()
    S2 = scope.spawn(S1)
    S3 = scope.spawn(S2)
    S1.a = 1
    S2.b = 2
    S3.c = 3
  
    local r = {}
    for k, v in scope.iterate(S3) do
      r[k] = v
    end
    T:check_equal(r.a, 1)
    T:check_equal(r.b, 2)
    T:check_equal(r.c, 3)
  end

  do
    local S1, S2, S3 = scope.new(), scope.new(), scope.new()
    S1.a = 1
    S2.a = 2
    S3.b = 3
    
    scope.set_parent(S3, S1)
    T:check_equal(scope.lookup(S3, "a"), 1)
    T:expect_error(function() scope.set_parent(S3, S2) end,
      "rima.scope.set_parent: the scope's parent is already set")
    scope.clear_parent(S3)
    scope.set_parent(S3, S2)
    T:check_equal(scope.lookup(S3, "a"), 2)
    scope.clear_parent(S3)
    T:check_equal(scope.lookup(S3, "a"), nil)
  end

  -- test bound scope
  do
    local S1, S2, S2
    S1 = scope.new()
    S2 = scope.spawn(S1)
    S3 = scope.spawn(S2, nil, {overwrite=true})
    T:check_equal(scope.has_parent(S1), false)
    T:check_equal(scope.has_parent(S2), true)
    S2.a = 5
    S3.a = 7
    T:check_equal(scope.lookup(S1, "a"), nil)
    T:check_equal(scope.lookup(S2, "a"), 5)
    T:check_equal(scope.lookup(S3, "a"), 7)
    T:check_equal(scope.lookup(S3, "a", S1), 5)  

    local b, c = rima.R"b, c"
    S1.b = rima.integer()
    T:check_equal(B(b, S3), "b")
    T:check_equal(E(B(b, S3), S2), "b")

    S3.c = 5
    T:check_equal(E(B(c, S3), S2), 5)
    S2.c = 7
    T:check_equal(E(B(c, S3), S2), 5)

    T:check_equal(B(B(c, S3) + c, S2), "c + c")
    T:check_equal(E(B(c, S3) + c, S2), 12)
  end

  do
    local S = scope.new{a=1, ["b, c"]=2, d=4}
    T:check_equal(S.a, 1)
    T:check_equal(S.b, 2)
    T:check_equal(S.c, 2)
    T:check_equal(S.d, 4)
  end

  do
    local S = scope.new{ a={x={y={z=1}}} }
    T:check_equal(S.a.x.y.z, 1)
  end

  do
    local S = scope.new{ a={x=1} }
    local a = S.a
    T:check_equal(object.type(a), "ref")
    T:expect_ok(function() S.a.y = 2 end, "scope newindex")
    T:expect_ok(function() a.z = 3 end, "scope newindex")
    T:expect_ok(function() S.a = {q=10, r=20} end, "scope newindex")
    T:check_equal(S.a.x, 1)
    T:check_equal(S.a.y, 2)
    T:check_equal(S.a.z, 3)
    T:check_equal(S.a.q, 10)
    T:check_equal(S.a.r, 20)
    T:check_equal(a.x, 1)
    T:check_equal(a.y, 2)
    T:check_equal(a.z, 3)
    T:check_equal(a.q, 10)
    T:check_equal(a.r, 20)

    T:expect_ok(function() S.f.g.h = 2 end, "ref newindex")
  end

  do
    local S = scope.new()
    S.a.b = rima.free()
    local S2 = scope.spawn(S)
    T:expect_ok(function() S2.a.b = rima.integer() end)
  end

  do
    local x = rima.R"x"
    local S = scope.new{x={a=1}}
    local S2 = scope.spawn(S, {x={b=2}})
    
    T:check_equal(E(x.a, S), 1)
    T:check_equal(E(x.a, S2), 1)

    S.a.b = rima.free()
    local S2 = scope.spawn(S)
    T:expect_ok(function() S2.a.b = rima.integer() end)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

