-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local object = require("rima.object")
local types = require("rima.types")
local scope = require("rima.scope")
local rima = rima

module(...)

-- Test ------------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  T:test(object.isa(scope.new(), scope), "isa(scope.new(), scope)")
  T:check_equal(object.type(scope.new()), "scope", "type(scope.new()) == 'scope'")

  local S = scope.new()

  -- Setting a variable
  T:expect_ok(function() local a = S.a end, "undefined ok")
  T:check_equal(S.a, nil, "undefined nil")
  T:expect_ok(function() S.a = types.undefined_t:new() end)
  T:expect_ok(function() S.a = rima.free() end)
  T:expect_error(function() S.a = types.undefined_t:new() end, "cannot set 'a' to 'a undefined'")
  T:expect_error(function() S.a = {} end, "cannot set 'a' to 'table")
  T:expect_error(function() S.a = "a" end, "cannot set 'a' to 'a'")
  T:expect_ok(function() S.a = rima.integer() end)
  T:expect_ok(function() S.a = rima.integer(1, 10) end)
  T:expect_error(function() S.a = 11 end, "cannot set 'a' to '11'")
  T:expect_ok(function() S.a = 3 end)
  T:expect_error(function() S.a = 4 end, "cannot set 'a' to '4'")
  T:expect_error(function() S.a = 3 end, "cannot set 'a' to '3'")
  T:expect_error(function() scope.set(S, {a=3}) end, "cannot set 'a' to '3'")

  T:expect_ok(function() scope.set(S, { b=7, c=rima.integer(3, 5) }) end)
  T:check_equal(object.type(S.a), "number", "type(S.a) == 'number'")
  T:check_equal(object.type(S.c), "ref", "type(S.c) == 'ref'")
  T:check_equal(S.a, 3, "S.a == 3")
  T:check_equal(S.c, "c", "s.c == c")
  T:check_equal(scope.lookup(S, "a"), 3, "scope.lookup(S, 'a') == 3")
  T:check_equal(scope.lookup(S, "b"), 7, "scope.lookup(S, 'b') == 7")
  T:check_equal(rima.ref.describe(S.c), "3 <= c <= 5, c integer")

  -- Setting a variable to an expression
  T:expect_ok(function() S.a2 = S.a end)
  T:expect_ok(function() S.c2 = S.c end)

  local S_no_overwrite = scope.spawn(S)
  T:check_equal(S_no_overwrite.a, 3, "S.a == 3")
  T:check_equal(S_no_overwrite.c, "c", "S.c == c")
  T:check_equal(scope.lookup(S_no_overwrite, "a"), 3, "S.a == a")
  T:check_equal(scope.lookup(S_no_overwrite, "undefined"), nil, "S.a == a")
  T:expect_error(function() S_no_overwrite.c = 7 end, "cannot set 'c' to '7'")
  T:expect_ok(function() S_no_overwrite.c = 3 end, "can set c to in bounds value")
  T:expect_ok(function() S.c = rima.integer(3, 5) end, "c is not set in parent")

  local r = {}
  for k, v in scope.iterate(S_no_overwrite) do
    r[k] = v
  end
  T:check_equal(r.a, 3)
  T:check_equal(r.a2, 3)
  T:check_equal(r.b, 7)
  T:check_equal(r.c, "3 <= * <= 5, * integer")
  T:check_equal(r.c2, "c")
  
  local S_overwrite = scope.spawn(S, nil, {overwrite=true})
  T:expect_ok(function() S_overwrite.c = 7 end, "can overwrite c")

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
    S2.a = 5
    S3.a = 7
    T:check_equal(scope.lookup(S1, "a"), nil)
    T:check_equal(scope.lookup(S2, "a"), 5)
    T:check_equal(scope.lookup(S3, "a"), 7)
    T:check_equal(scope.lookup(S3, "a", S1), 5)  
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

