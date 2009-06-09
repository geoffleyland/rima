-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local error, pcall = error, pcall
local ipairs, rawget, require, type, unpack = ipairs, rawget, require, type, unpack
local getmetatable, setmetatable = getmetatable, setmetatable

--[[
A ref is a reference to a value or type information that we'll look in a scope.

A reference can have its own type information, and this will be checked against
what's found in the scope.

A reference can be bound to a scope, in which case a lookup in a scope that
doesn't include the bound scope will fail.

Because we wish to be able to index references, we have to hide the real workings
of the reference somewhere tricky.  This is a giant pain in the ass.
--]]

local object = require("rima.object")
local proxy = require("rima.proxy")
local args = require("rima.args")
local tests = require("rima.tests")
local types = require("rima.types")
require("rima.private")
local rima = rima
local expression = rima.expression

module(...)

local scope = require("rima.scope")

-- References to values --------------------------------------------------------

local ref = object:new(_M, "ref")
ref_proxy_mt = setmetatable({}, ref)

function ref:new(r)
  local fname, usage = "rima.ref:new", "new(r: {name, address, type, scope})"
  args.check_type(r, "r", "table", usage, fname)
  args.check_type(r.name, "r.name", "string", usage, fname)
  args.check_types(r.type, "r.type", {"nil", {rima.types.undefined_t, "type"}}, usage, fname)
  args.check_types(r.scope, "r.scope", {"nil", {rima.scope, "scope" }}, usage, fname)
  args.check_types(r.address, "r.address", {"nil", "table"}, usage, fname)

  r.type = r.type or rima.types.undefined_t:new()

  return proxy:new(object.new(ref, { name=r.name, address=r.address or {}, type=r.type, scope=r.scope }), ref_proxy_mt)
end

function ref.is_simple(r)
  r = proxy.O(r)
  return (r.scope or #r.address > 0) and false or true
end


-- String Representation -------------------------------------------------------

function ref.dump(r)
  -- possibly have a way of showing that a variable is bound?
  r = proxy.O(r)
  local s = "ref("..r.name
  local a = r.address
  if a and a[1] then
    s = s.."["..table.concat(rima.imap(expression.dump, a), ", ").."]"
  end
  return s..")"
end

function ref.__tostring(r)
  -- possibly have a way of showing that a variable is bound?
  r = proxy.O(r)
  local s = r.name
  local a = r.address
  if a and a[1] then
    s = s.."["..table.concat(rima.imap(rima.tostring, a), ", ").."]"
  end
  return s
end

ref_proxy_mt.__tostring = ref.__tostring

function ref.describe(r)
  r = proxy.O(r)
  return r.type:describe(r.name)
end


-- Evaluation ------------------------------------------------------------------

function ref.eval(r, S, args)
  local R = proxy.O(r)

  if args and args[1] then
    error(("can't evaluate the reference '%s' with arguments"):format(R.name), 0)
  end

  -- evaluate the address of the ref if there is one
  local new_address = {}
  for i, a in ipairs(R.address) do
    new_address[i] = expression.eval(a, S)
  end
  
  -- look the ref up in the scope
  local e, found_scope = scope.lookup(S, R.name, R.scope)
  if not e then                                 -- remain unbound
    return ref:new{name=R.name, address=new_address, type=R.type, scope=R.scope}
  end

  -- evaluate the result of the lookup - it might be an expression, or another ref
  local status, v = pcall(function() return expression.eval(e, S) end)
  if not status then
    error(("error evaluating '%s' as '%s':\n  %s"):
      format(R.name, rima.tostring(e), v:gsub("\n", "\n  ")), 0)
  end

  if object.isa(v, types.undefined_t) then
    if not v:includes(R.type) and not R.type:includes(v) then
      error(("the type of '%s' (%s) and the type of the reference (%s) are mutually exclusive"):
        format(R.name, v:describe(R.name), R.type:describe(R.name)), 0)
    else
      -- update the address and bind the reference to the scope if it doesn't already have one
      return ref:new{name=R.name, address=new_address, type=R.type, scope=R.scope or found_scope}
    end
  elseif object.isa(v, expression) then
    return v
  else
    if not R.type:includes(v) then
      error(("'%s' (%s) is not of type '%s'"):
        format(R.name, rima.tostring(v), R.type:describe(R.name)), 0)
    else
      v = proxy.O(v)
      if type(v) == "table" and v.handle_address then
        local status, v = pcall(function() return v:handle_address(S, new_address) end)
        if not status then
          error(("error evaluating '%s' as '%s':\n  %s"):
            format(R.name, rima.tostring(e), v:gsub("\n", "\n  ")), 0)
        end
        return v
      end
      for _, i in ipairs(new_address) do
        if object.isa(i, rima.iteration.element) then
          v = v[1] and v[i.index] or v[i.key]
        else
          v = v[i]
        end
        if not v then
          return ref:new{name=R.name, address=new_address, type=R.type, scope=R.scope or found_scope}
        end
      end
    end
    return v
  end
end


-- Setting ---------------------------------------------------------------------

function ref.set(r, t, v)
  local r = proxy.O(r)
  local name = r.name
  local address = r.address

  function s(t, name, i)
    if object.type(name) == "element" then name = name.key end
    local cv = t[name]
    if #address == i then
      if cv then
        error(("error setting '%s' to %s: field already exists (%s)"):
          format(rima.tostring(r), rima.tostring(v), rima.tostring(cv)), 0)
      end
      t[name] = v
    else
      if cv and type(cv) ~= "table" then
        error(("error setting '%s' to %s: field is not a table (%s)"):
          format(rima.tostring(r), rima.tostring(v), rima.tostring(cv)), 0)
      end
      if not cv then t[name] = {} end
      s(t[name], address[i+1], i+1)
    end
  end
  s(t, name, 0)
end

-- Operators -------------------------------------------------------------------

function ref.__add(a, b)
  return expression.__add(a, b)
end

function ref.__sub(a, b)
  return expression.__sub(a, b)
end

function ref.__unm(a)
  return expression.__unm(a)
end

function ref.__mul(a, b)
  return expression.__mul(a, b)
end

function ref.__div(a, b)
  return expression.__div(a, b)
end

function ref.__pow(a, b)
  return expression.__pow(a, b)
end

function ref.__call(...)
  return expression.__call(...)
end

ref_proxy_mt.__add = ref.__add
ref_proxy_mt.__sub = ref.__sub
ref_proxy_mt.__unm = ref.__unm
ref_proxy_mt.__mul = ref.__mul
ref_proxy_mt.__div = ref.__div
ref_proxy_mt.__pow = ref.__pow
ref_proxy_mt.__call = ref.__call

--[[
function ref_proxy_mt.__index(r, i)
  return expression:new(addresss, r, i)
end

--]]
function ref_proxy_mt.__index(r, i)
  r = proxy.O(r)
  local address = {}
  for j, a in ipairs(r.address) do address[j] = a end
  address[#address+1] = i
  return ref:new{name=r.name, address=address, type=r.type, scope=r.scope}
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(object.isa(ref:new{name="a"}, ref), "isa(ref:new(), ref)")

  local function check_strings(v, s, d)
    T:equal_strings(v, s, "tostring(ref)")
    T:equal_strings(ref.describe(v), d, "ref:describe()")
  end

  check_strings(ref:new{name="a"}, "a", "a undefined")
  check_strings(ref:new{name="b", type=rima.free()}, "b", "-inf <= b <= inf, b real")  
  check_strings(ref:new{name="c", type=rima.positive()}, "c", "0 <= c <= inf, c real")  
  check_strings(ref:new{name="d", type=rima.negative()}, "d", "-inf <= d <= 0, d real")  
  check_strings(ref:new{name="e", type=rima.integer()}, "e", "0 <= e <= inf, e integer")  
  check_strings(ref:new{name="f", type=rima.binary()}, "f", "f binary")  

  local S = rima.scope.create{ a = rima.free(1, 10), b = 1, c = "c" }

  T:expect_ok(function() ref.eval(ref:new{name="z"}, S) end, "z undefined")
  T:equal_strings(ref.eval(ref:new{name="z"}, S), "z", "undefined remains an unbound variable")
  T:expect_error(function() ref.eval(ref:new{name="a", type=rima.free(11, 20)}, S) end,
    "the type of 'a' %(1 <= a <= 10, a real%) and the type of the reference %(11 <= a <= 20, a real%) are mutually exclusive")
  T:expect_error(function() ref.eval(ref:new{name="b", type=rima.free(11, 20)}, S) end,
    "'b' %(1%) is not of type '11 <= b <= 20, b real'")
  T:equal_strings(ref.eval(ref:new{name="a"}, S), "a")
  T:equal_strings(ref.eval(ref:new{name="b", rima.binary()}, S), 1)


  -- index tests
  local a, b, c = rima.R"a, b, c"
  T:equal_strings(expression.dump(a[b]), "ref(a[ref(b)])")
  T:equal_strings(a[b], "a[b]")
  T:equal_strings(a[b][c], "a[b, c]")

  do
    local S = rima.scope.create{ a={ "x", "y" }, b = 2}
    T:equal_strings(expression.eval(a[b], S), "y")
  end

  do
    local S = rima.scope.create{ a=rima.types.undefined_t:new(), b = 2}
    T:equal_strings(expression.dump(a[b]), "ref(a[ref(b)])")
    T:equal_strings(expression.dump(expression.eval(a[b], S)), "ref(a[number(2)])")
    local e = expression.eval(a[b], S)
    T:equal_strings(expression.dump(e), "ref(a[number(2)])")
    S2 = scope.spawn(S, {a = { "x" }})
    T:equal_strings(expression.dump(expression.eval(e, S2)), "ref(a[number(2)])")
    S2.a[2] = "yes"
    T:equal_strings(expression.dump(expression.eval(e, S2)), "string(yes)")    

    S3 = scope.spawn(S, {a = { b="x" }})
    T:equal_strings(expression.dump(expression.eval(a.b, S)), "ref(a[string(b)])")
    T:equal_strings(expression.dump(expression.eval(a.b, S3)), "string(x)")
  end

  do
    local x, y, N = rima.R"x,y,N"
    local S = rima.scope.create{ N={ {1, 2}, {3, 4} } }
    T:equal_strings(expression.dump(N[x][y]), "ref(N[ref(x), ref(y)])")
    T:equal_strings(expression.eval(N[x][y], S), "N[x, y]")
    S.x = 2
    T:equal_strings(expression.eval(N[x][y], S), "N[2, y]")
    T:equal_strings(expression.eval(N[y][x], S), "N[y, 2]")
    S.y = 1
    T:equal_strings(expression.eval(N[x][y], S), 3)
    T:equal_strings(expression.eval(N[y][x], S), 2)
  end

  -- tests for references to references
  -- tests for references to functions
  -- tests for references to expressions

  return T:close()
end

-- EOF -------------------------------------------------------------------------

