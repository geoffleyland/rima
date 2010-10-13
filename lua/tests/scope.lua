-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local scope = require("rima.scope")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local rima = require("rima")

local index = require("rima.index")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local function N(...) return scope.new(...) end
  local D = lib.dump
  local E = rima.E

  -- Constructors
  T:test(scope:isa(N()), "scope:isa(scope.new())")
  T:check_equal(object.type(N()), "scope", "type(scope.new()) == 'scope'")

  -- Indexing
  do
    local S = N()
    T:expect_ok(function() S.a = 1 end)
    T:check_equal(D(S.a), 'index(scope{ 1 = { a = 1 } }, address{"a"})')
    T:expect_error(function() S.a.b = 1 end, "%L: error indexing 'a' as 'a.b': can't index a number")
    T:expect_error(function() S.a.b.c = 1 end, "%L: error indexing 'a' as 'a.b': can't index a number")
    T:expect_ok(function() S.b.c = 1 end)
    T:expect_ok(function() S.b.c = 2 end)

    T:check_equal(E(S.a), 1)
    T:check_equal(E(S.b.c), 2)
  end

  -- Table new
  do
    local S = N{ b=3, c=5, d={e=7, f=11}}
    T:check_equal(E(S.b), 3)
    T:check_equal(E(S.c), 5)
    T:check_equal(E(S.d.e), 7)
    T:check_equal(E(S.d.f), 11)
  end

  -- Table sets
  do
    local S = N()
    T:expect_ok(function() S.a = { b=3, c=5, d={e=7, f=11}} end)
    T:check_equal(E(S.a.b), 3)
    T:check_equal(E(S.a.c), 5)
    T:check_equal(E(S.a.d.e), 7)
    T:check_equal(E(S.a.d.f), 11)
  end

  -- Parent scopes
  do
    local S1 = N{ a=3, b=5, c={ d=7, e=11} }
    local S2 = N(S1, { a=13, c={ d=17 } })
    T:check_equal(E(S1.a), 3)
    T:check_equal(E(S1.b), 5)
    T:check_equal(E(S1.c.d), 7)
    T:check_equal(E(S1.c.e), 11)
    T:check_equal(E(S2.a), 13)
    T:check_equal(E(S2.b), 5)
    T:check_equal(E(S2.c.d), 17)
    T:check_equal(E(S2.c.e), 11)
  end

  -- References
  do
    local S = N()
    S.a.b = S.c.d
    S.c.d = 7
    T:check_equal(E(S.a.b), 7)
    S.e.f = S.g.h
    S.g.h.i.j = 13
    T:check_equal(E(S.e.f.i.j), 13)
  end

  -- references to references
  do
    local a, b, c = rima.R"a, b, c"
    local S = rima.scope.new{ a={x=b}, b={y=7} }
    S.a.q = S.c
    S.c.r = 13
    T:check_equal(E(a.x.y, S), 7)
    T:expect_error(function() S.a.x.z = 17 end, "%L: error assigning setting 'a%.x%.z' to '17':.*error setting 'b%.z' to '17': 'b%.z' isn't bound to a table or scope")
    T:check_equal(E(a.q.r, S), 13)
    T:expect_ok(function() S.a.q.s = 19 end)
    T:check_equal(E(c.s, S), 19)
  end

  -- References to undefined things
  do
    local x, i = rima.R"x, i"
    T:check_equal(E(x.y.z, { x=i[1][2] }), "i[1, 2].y.z")
    T:check_equal(E(x.y.z, scope.new{ x=i[1][2] }), "i[1, 2].y.z")
    T:check_equal(E(x.a, { x = i, i={b=1} }), "i.a")
    T:check_equal(E(x.a, scope.new{ x = i }), "i.a")
    T:check_equal(E(x.a, scope.new{ x = i, i={b=1} }), "i.a")
  end

  -- Variable indexes
  do
    local S = N()
    local i, j, m = rima.R"i, j, m"
    T:expect_ok(function() S.a[1] = 11 end)
    T:expect_ok(function() S.a[i] = 13 end)
    T:expect_ok(function() S.a[5] = 17 end)
    T:check_equal(E(S.a[1]), 11)
    T:check_equal(E(S.a[2]), 13)
    T:check_equal(E(S.a[3]), 13)
    T:check_equal(E(S.a[4]), 13)
    T:check_equal(E(S.a[5]), 17)
    T:check_equal(E(S.a.b), 13)

    S.b[i].c[j].d = 19
    T:check_equal(E(S.b.k.c.l.d), 19)

    T:expect_error(function() S.c[i.j].d = 29 end, "%L: error indexing 'c' as 'c%[i%.j%]': variable indexes must be unbound identifiers")

    T:expect_ok(function() S.c[i].d[j].k = m[i][j] end)
    T:check_equal(E(S.c[1].d[2].k), "m[1, 2]")
    S.m[1][2] = 31
    T:check_equal(E(S.c[1].d[2].k), 31)

    T:expect_ok(function() S.d[i] = i end)
    T:check_equal(E(S.d[3]), 3)
    T:check_equal(E(S.d[17]), 17)
    T:check_equal(E(S.d["hello"]), "hello")
    
    T:expect_ok(function() S.e[i].f = i end)
    T:expect_ok(function() S.e[13].f = 29 end)
    T:expect_ok(function() S.e[19].g = 31 end)
    T:check_equal(E(S.e[11].f), 11)
    T:check_equal(E(S.e[13].f), 29)
    T:check_equal(E(S.e[17].f), 17)
    T:check_equal(E(S.e[19].f), 19)
    T:check_equal(E(S.e[11].g), "e[11].g")
    T:check_equal(E(S.e[13].g), "e[13].g")
    T:check_equal(E(S.e[17].g), "e[17].g")
    T:check_equal(E(S.e[19].g), 31)
    T:check_equal(E(S.e["hello"].f), "hello")
  end

  do
    local S = N()
    local a, x, X = rima.R("a, x, X")
    T:expect_ok(function() S.a[{x=X}] = x end)
  end

  -- Subscopes
  do
    local c, f = rima.R("c, f")
    local subscope = scope.new()
    subscope.a.b = c.d
    subscope.c.d.e = 23
    local superscope = scope.new()
    superscope.c.d.e = 29
    superscope.f.g = subscope
    
    T:check_equal(E(c.d.e, subscope), 23)
    T:check_equal(E(c.d.e, superscope), 29)
    T:check_equal(E(f.g.c.d.e, superscope), 23)
    T:check_equal(E(f.g.a.b.e, superscope), 23)
  end

  do
    local c, f = rima.R("c, f")
    local subscope = scope.new()
    subscope.a.b = c.d
    local superscope = scope.new()
    superscope.c.d.e = 37
    superscope.f.g.c.d.e = 41
    superscope.f.g = subscope

    T:check_equal(E(f.g.a.b.e, superscope), 41)
  end

  do
    local b, c, d = rima.R("b, c, d")
    local subscope = scope.new()
    subscope.a = b
    local superscope = scope.new()
    superscope.c = subscope
    superscope.c.b = d
    superscope.d = 47
    superscope.a.d = 53

    T:check_equal(E(c.a, superscope), 47)
  end

  do
    local c, f, h = rima.R("c, f, h")
    local subscope = scope.new()
    subscope.a.b = c.d
    local superscope = scope.new()
    superscope.f.g = subscope
    superscope.f.g.c.d.e = h.i
    superscope.h.i.j = 47
    superscope.f.g.h.i.j = 53

    T:check_equal(E(f.g.a.b.e.j, superscope), 47)
  end

  do
    local c, g = rima.R"c, g"
    local subsub = scope.new{a={b=c.d}}
    local sub = scope.new{e={f=subsub}}
    local sup = scope.new{g={h=sub}}
    subsub.c.d = 59
    
    T:check_equal(E(g.h.e.f.a.b, sup), 59)
  end

  do
    local c, g = rima.R"c, g"
    local subsub = scope.new{a={b=c.d}}
    local sub = scope.new{e={f=subsub}}
    local sup = scope.new{g={h=sub}}
    sub.e.f.c.d = 59
    
    T:check_equal(E(g.h.e.f.a.b, sup), 59)
  end

  do
    local c, g = rima.R"c, g"
    local subsub = scope.new{a={b=c.d}}
    local sub = scope.new{e={f=subsub}}
    local sup = scope.new{g={h=sub}}
    sup.g.h.e.f.c.d = 59
    
    T:check_equal(E(g.h.e.f.a.b, sup), 59)
  end

  do
    local c, g, i = rima.R"c, g, i"
    local subsub = scope.new{a={b=c.d}}
    local sub = scope.new{e={f=subsub}}
    local sup = scope.new{g={h=sub}}
    sub.e.f.c.d = i.j
    sub.i.j = 67
    
    T:check_equal(E(g.h.e.f.a.b, sup), 67)
  end

  do
    local c, g, i = rima.R"c, g, i"
    local subsub = scope.new{a={b=c.d}}
    local sub = scope.new{e={f=subsub}}
    local sup = scope.new{g={h=sub}}
    sup.g.h.e.f.c.d = i.j
    sup.i.j = 67
    
    T:check_equal(E(g.h.e.f.a.b, sup), 67)
  end

  do
    local c, g, i, k, m, o, q = rima.R"c, g, i, k, m, o, q"
    local subsub = scope.new{a={b=c.d}}
    local sub = scope.new{e={f=subsub}}
    local sup = scope.new{g={h=sub}}
    subsub.c.d = i.j
    sub.e.f.i.j = k.l
    sub.k.l = m.n
    sup.g.h.m.n = o.p
    sup.o.p = q.r
    sup.q.r = 71

    T:check_equal(E(g.h.e.f.a.b, sup), 71)
  end

  -- Set subscope
  do
    local a, i = rima.R"a, i"
    local subscope = scope.new()
    subscope.b = 13
    local superscope = N()
    superscope.a[i] = subscope
    superscope.a[i].c = 17
    superscope.a[3].b = 19
    superscope.a[7].c = 23
    
    T:check_equal(E(a[3].b, superscope), 19)
    T:check_equal(E(a[7].b, superscope), 13)
    T:check_equal(E(a[11].b, superscope), 13)
    T:check_equal(E(a[3].c, superscope), 17)
    T:check_equal(E(a[7].c, superscope), 23)
    T:check_equal(E(a[11].c, superscope), 17)
  end

  -- Expressions with set subscopes
  do
    local a, b, sub = rima.R"a, b, sub"
    local subscope = N()
    subscope.a = b
    local superscope = N()
    superscope.sub = subscope
    T:check_equal(E(sub.a, superscope), "sub.b")
  end

  do
    local a, b, c, sub = rima.R"a, b, c, sub"
    local subscope = N()
    subscope.a = b + c
    local superscope = N()
    superscope.sub = subscope

    T:check_equal(E(sub.a, superscope), "sub.b + sub.c")
  end
  do
    local a, b, c, d, e, sub = rima.R"a, b, c, d, e, sub"
    local subscope = N()
    subscope.a.b = c + d.e
    local superscope = N()
    superscope.sub = subscope

    T:check_equal(E(sub.a.b, superscope), "sub.c + sub.d.e")
  end

  do
    local a, b, c, d, e, i, s, sub = rima.R"a, b, c, d, e, i, s, sub"

    local subscope = N()
    subscope.e1 = a
    subscope.e2 = a + b
    subscope.e3 = c
    subscope.e4 = c + d
    subscope.e5 = a * c
    subscope.e6 = rima.sum{e}(e.a)
    subscope.e7 = rima.sum{e}(e.b)
    subscope.e8 = rima.sum{e}(e.a * e.b)
    
    local superscope = N()
    superscope.sub[i] = subscope
    superscope.sub[1].a = 7
    superscope.sub[1].b = 11
    superscope.sub[2].a = 13
    superscope.sub[2].b = 17
    superscope.sub[1].e = { { a=23 }, { a=29 } }
    superscope.sub[2].e = { { a=31 }, { a=37 } }
    
    T:check_equal(E(rima.sum{s=sub}(s.a), superscope), 20)
    T:check_equal(E(rima.sum{s=sub}(s.b), superscope), 28)
    T:check_equal(E(rima.sum{s=sub}(s.e1), superscope), 20)
    T:check_equal(E(rima.sum{s=sub}(s.e2), superscope), 48)

    T:check_equal(E(rima.sum{s=sub}(s.c), superscope), "sub[1].c + sub[2].c")
    T:check_equal(E(rima.sum{s=sub}(s.d), superscope), "sub[1].d + sub[2].d")
    T:check_equal(E(rima.sum{s=sub}(s.e3), superscope), "sub[1].c + sub[2].c")
    T:check_equal(E(rima.sum{s=sub}(s.e4), superscope), "sub[1].c + sub[1].d + sub[2].c + sub[2].d")

    T:check_equal(E(rima.sum{s=sub}(s.e5), superscope), "7*sub[1].c + 13*sub[2].c")
    T:check_equal(E(rima.sum{s=sub}(s.e6), superscope), 120)
    T:check_equal(E(rima.sum{s=sub}(s.e7), superscope), "sub[1].e[1].b + sub[1].e[2].b + sub[2].e[1].b + sub[2].e[2].b")
    T:check_equal(E(rima.sum{s=sub}(s.e8), superscope), "23*sub[1].e[1].b + 29*sub[1].e[2].b + 31*sub[2].e[1].b + 37*sub[2].e[2].b")
  end

  -- sums in closures
  do
    local a, b, c, d, i = rima.R"a, b, c, d, i"
    local S = scope.new()
    S.a[i] = rima.sum{c=b[i]}(c)
    S.b = { { 3, 5, 7 }, { 11, 13 }}
    T:check_equal(E(a[1], S), 15)
    T:check_equal(E(a[2], S), 24)
--    T:check_equal(lib.dump(E(rima.sum{i=d}(a[i])), S), "xxx")
    S.d = {1,2}
    T:check_equal(E(rima.sum{i=d}(a[i]), S), 39)
  end    

  do
    local a, b, c, d, i, j = rima.R"a, b, c, d, i, j"
    local S = scope.new()
    S.a[i] = rima.sum{c=b}(c[i])
    S.b = { { 3, 5, 7 }, { 11, 13 }}
    T:check_equal(E(a[1], S), 14)
    T:check_equal(E(a[2], S), 18)
--    T:check_equal(lib.dump(E(rima.sum{i=d}(a[i])), S), "xxx")
    S.d = {1,2}
    T:check_equal(E(rima.sum{i=d}(a[i]), S), 32)
  end    

  -- Table aggregation
  do
    local a = rima.R"a"
    local S = scope.new{a={b={[1]="hello"}}}
    local S2 = scope.new(S, {a={b={[2]="world"}}})
    T:check_equal(E(a.b[1], S2), "hello")
    T:check_equal(E(a.b[2], S2), "world")
    T:check_equal(E(a.b, S2)[1], "hello")
    T:check_equal(E(a.b, S2)[2], "world")
  end

  -- Table contents
  do
    local i, I = rima.R"i, I"
    local sub, sub3 = rima.R"sub, sub3"
    local def, def2 = rima.R"def, def2"
    local c = rima.R"c"
    local subscope1 = scope.new{a={x=7}}
    local subscope2 = scope.new(subscope1, {b=11, a={y=13}})
    local subscope3 = scope.new{q=23}
    local superscope = scope.new{c=17, I={1, 2, 3}}
    superscope.sub[{i=I}] = subscope2
    superscope.sub[i].a.z = 19+i
    superscope.sub3 = subscope3
    superscope.sub3.r = 29
    superscope.def[i] = 31 + i
    superscope.def2[i].a.x = 37 + i
    T:check_equal(E(sub[1].a.x, superscope), 7)
    T:check_equal(E(sub[1].a.y, superscope), 13)
    T:check_equal(E(sub[1].a.z, superscope), 20)
    T:check_equal(E(sub[2].a.z, superscope), 21)
    T:check_equal(E(sub[1].b, superscope), 11)
    T:check_equal(E(sub3.q, superscope), 23)
    T:check_equal(E(sub3.r, superscope), 29)
    T:check_equal(E(c, superscope), 17)
    T:check_equal(E(def[1], superscope), 32)
    T:check_equal(E(def2[1].a.x, superscope), 38)
    
    local cont = scope.contents(superscope)
    T:check_equal(cont.c, 17)
--    T:check_equal(cont.sub[scope.set_default_marker].a.z, "{i}(19 + i)")
--    T:check_equal(lib.dump(cont.sub[scope.set_default_marker].b), 11)
--    T:check_equal(lib.dump(cont.sub[scope.set_default_marker].a.x), 7)
--    T:check_equal(lib.dump(cont.sub[scope.set_default_marker].a.y), 13)
    T:check_equal(lib.dump(cont.sub3.q), 23)
    T:check_equal(lib.dump(cont.sub3.r), 29)
--    T:check_equal(cont.def[scope.set_default_marker], "{i}(31 + i)")
--    T:check_equal(cont.def2[scope.set_default_marker].a.x, "{i}(37 + i)")
  end

  -- index introspection
  do
    local a, i, I = rima.R"a, i, I"
    local S = scope.new()
    S.a[{i=I}].b = 10
    local list = {}
    index.proxy_mt.__list_variables(a[1].b, S, list)
    index.proxy_mt.__list_variables(a[2].b, S, list)
    T:check_equal(list["a[i].b"].index, "a[i].b")
    T:check_equal(list["a[i].b"].sets[1], "i in I")
    
    list = {}
    index.proxy_mt.__list_variables(a[i.j].b, S, list)
    T:check_equal(list["a[i].b"].index, "a[i].b")

    list = core.list_variables(a[1].b + a[2].b + a[3].c, S)
    T:check_equal(list["a[i].b"].index, "a[i].b")
    T:check_equal(list["a[i].b"].sets[1], "i in I")
    T:check_equal(list["a[i].c"].index, "a[i].c")
    T:check_equal(list["a[i].c"].sets[1], "i in I")
  end
  
  -- what happens if I do this?
  do
    local a, i = rima.R"a, i"
    T:check_equal(E(a[i.j], { a={3, 5, 7}, i={j=2,k=3}}), 5)
    T:check_equal(E(a[i.j], { a={3, 5, 7}, i={}}), "a[i.j]")
    T:check_equal(E(a[i.j], { a={3, 5, 7} }), "a[i.j]")
    T:check_equal(E(a[i.j], { i={j=2,k=3} }), "a[2]")
  end

  -- Bug in knapsack
  do
    local a, i, sub0 = rima.R"a i, sub0"
    local sub = scope.new()
    sub.b = a
    sub.c.d = a
    sub.e[i] = a
    sub.f[i].g = a

    local super = scope.new()
    super.sub0 = sub
    T:check_equal(E(sub0.b, super), "sub0.a")
    T:check_equal(E(sub0.c.d, super), "sub0.a")
    T:check_equal(E(sub0.e[i], super), "sub0.a")
    T:check_equal(E(sub0.f[i].g, super), "sub0.a")
  end

  do
    local a, i, I, j, sub0 = rima.R"a i, I, j, sub0"
    local sub = scope.new()
    sub.a = rima.sum{i=I}(i.x)

    local super1 = scope.new()
    super1.sub0.I = { {y=1}, {y=2} }
    super1.sub0 = sub
    T:check_equal(E(sub0.a, super1), "sub0.I[1].x + sub0.I[2].x")
    
    local super2 = scope.new()
    super2.sub0.I = { {y=1}, {y=2} }
    local super3 = scope.new(super2)
    super3.sub0 = sub
    T:check_equal(E(sub0.a, super3), "sub0.I[1].x + sub0.I[2].x")
  end

  do
    local a, b, i, I, s, sub0, S = rima.R"a, b, i, I, s, sub0, S"
    local sub = scope.new()
    sub.a = rima.sum{i=I}(i.x)

    local super1 = scope.new()
    super1.a = rima.sum{s=sub0}(s.a)
    super1.b = rima.sum{s=S}(sub0[s].a)
    T:check_equal(E(a, super1), "sum{s in sub0}(s.a)")

    local super2 = scope.new(super1)
    super2.sub0[{s=sub0}] = sub

    T:check_equal(E(sub0[1].a, super2), "sum{i in sub0[1].I}(i.x)")
    T:check_equal(E(a, super2), "sum{s in sub0}(sum{i in s.I}(i.x))")
    T:check_equal(E(b, super2), "sum{s in S}(sum{i in sub0[s].I}(i.x))")
    
    local super3 = scope.new(super2, { sub0={{I={{x=3},{x=5}}},{I={{x=7},{x=11}}}} })
    T:check_equal(E(a, super3), 26)
  end

  do
    local a, z, i, j = rima.R"a, z, i, j"
    local S
    T:expect_ok(function() S = scope.new{ [a[i].b[j].c] = 13 } end)
    T:check_equal(E(a[1].b[2].c, S), 13)

    T:expect_ok(function() S = scope.new{ z = {[a[i].b[j].c] = 17 }} end)
    T:check_equal(E(z.a[1].b[2].c, S), 17)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

