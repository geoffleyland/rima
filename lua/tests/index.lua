-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local index = require("rima.index")

local series = require("test.series")
local object = require("rima.lib.object")
local core = require("rima.core")

module(...)
 

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local N = function(...) return index:new(...) end
  local IE = index.proxy_mt.__eval
  local E = core.eval

  -- constructors
  T:test(index:isa(N()), "index:isa(index:new())")
  T:test(object.type(N(), "index"), "type(index:new())=='index'")
--  T:expect_error(function() N(B, 1) end, "the first element of this index must be an identifier string")
  T:expect_ok(function() N({}, 1) end)

  -- identifiers
--  T:test(index.is_identifier(N(R, "a")))
--  T:test(not index.is_identifier(N(R, "a", "b")))
--  T:test(not index.is_identifier(N({}, "a")))

  -- indexing
  T:check_equal(N().a.b, "a.b")
  T:check_equal(N().a[1], "a[1]")

  -- resolving
  T:check_equal(IE(N({a=1}).a), 1)
  T:check_equal(IE(N().a, {a=3}), 3)

  -- setting
  local I = N{}
  T:expect_ok(function() I.a = 1 end)
  T:check_equal(IE(I.a), 1)
  T:check_equal(IE(N().a, I), 1)
  T:expect_ok(function() I.b.c.d = 3 end)
  T:check_equal(IE(I.b.c.d), 3)
  T:check_equal(IE(N().b.c.d, I), 3)
  T:check_equal(E(N().f.g.h, I), "f.g.h")

  local I2 = {a=5, b={c={d=7}}}
  T:check_equal(IE(N(I2).a, I), 5)
  T:check_equal(IE(N(I2).b.c.d, I), 7)
  
  T:expect_error(function() N().a.b = 1 end, "%L: error setting 'a.b' to '1': 'a.b' isn't bound to a table or scope")
  
  -- errors
  T:expect_error(function() local dummy = IE(I.a.b) end, "%L: error indexing 'a' as 'a%.b': can't index a number")
  T:expect_error(function() I.a.b = 1 end, "%L: error indexing 'a' as 'a%.b': can't index a number")
  T:expect_error(function() I.a.b.c = 1 end, "%L: error indexing 'a%' as 'a%.b%': can't index a number")

  -- variable indexes
  local I3 = { a={b=5} }
  local i = N().i
  T:check_equal(N().a, "a")
  T:check_equal(N().a.b, "a.b")
  T:check_equal(N().a[i], "a[i]")
  T:check_equal(E(N().a[i], I3), "a[i]")
  I3.i = "b"
  T:check_equal(IE(N().a[i], I3), 5)

  -- table assign
  local t = {}
  local I = N(t)
  T:expect_ok(function() I.a = { x=1, y=2 } end)
  T:check_equal(t.a.x, 1)
  T:check_equal(t.a.y, 2)
  
  -- set
  local t = {}
  local I = N()
  T:expect_ok(function() index.set(I.b, t, 7) end)
  T:expect_ok(function() index.set(I.a, t, { x=1, y=2 }) end)
  T:check_equal(t.b, 7)
  T:check_equal(t.a.x, 1)
  T:check_equal(t.a.y, 2)
  
  -- references to indexes
  local t = { a={b=N().c.d}, c={d={e=N().f.g}}, f={g={h=N().i.j}} }
  T:check_equal(E(N().a.b.z, t), "c.d.z")
  T:check_equal(E(N().a.b.e.z, t), "f.g.z")
  T:check_equal(E(N().a.b.e.h, t), "i.j")
  T:check_equal(E(N().a.b.e.h.k, t), "i.j.k")
  t.i = {j={k=7}}
  T:check_equal(E(N().a.b.e.h.k, t), 7)

  -- index introspection
  local list = {}
  local i = N(nil, "a", 1, "b")
  index.proxy_mt.__list_variables(i, {}, list)
  T:check_equal(list["a[1].b"].ref, "a[1].b")
  
  return T:close()
end


-- EOF -------------------------------------------------------------------------

