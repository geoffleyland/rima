-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, pairs, pcall = ipairs, pairs, pcall
local table = require("table")

local series = require("test.series")
local scope = require("rima.scope")
local core = require("rima.core")
local lib = require("rima.lib")
local linearise = require("rima.mp.linearise")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)


  local a, b, c, d = rima.R"a, b, c, d"
  local S = rima.scope.new{ ["a,b"] = rima.free(), c=rima.types.undefined_t:new() }
  S.d = { rima.free(), rima.free() }
  
  local L = function(e, _S) return linearise.linearise(e, _S or S) end
  local LF = function(e, _S) return function() linearise.linearise(e, _S or S) end end

  T:expect_ok(LF(a))
  T:expect_ok(LF(1 + a))
  T:expect_error(LF(1 + (3 + a^2)),
    "linear form: '4 %+ a^2'.-term 2 is not linear %(got 'a^2', pow%)")
  T:expect_error(LF(1 + c),
    "linear form: '1 %+ c'.-expecting a number type for 'c', got 'c undefined'")
  T:expect_error(LF(a * b),
    "linear form: 'a%*b'.-the expression does not evaluate to a sum of terms")
  T:expect_error(LF(1 + a[2]*5), "'a' is not indexable")
  T:expect_error(LF(1 + c[2]*5), "No type information available for 'c%[2%]'")
  T:expect_ok(LF(1 + d[2]*5), "d[2] is a number")
  T:expect_ok(LF(1 + d[2]), "d[2] is an index")
  T:expect_ok(LF(d[2]), "d[2] is an index")

  local function check_nonlinear(e, S)
    T:expect_error(function() linearise.linearise(e, S) end, "linear form:")
  end

  local function check_linear(e, expected_constant, expected_terms, S)
    local pass, got_constant, got_terms = pcall(linearise.linearise, e, S)

    if not pass then
      local s = ("error linearising %s:\n  %s"):
        format(lib.repr(e), got_constant:gsub("\n", "\n  "))
      T:test(false, s)
      return
    end

    for v, c in pairs(got_terms) do got_terms[v] = c.coeff end
    if expected_constant ~= got_constant then
      pass = false
    else
      for k, v in pairs(expected_terms) do
        if got_terms[k] ~= v then
          pass = false
        end
      end
      for k, v in pairs(got_terms) do
        if expected_terms[k] ~= v then
          pass = false
        end
      end      
    end

    if not pass then
      local s = ""
      s = s..("error linearising %s:\n"):format(lib.repr(e))
      s = s..("  Evaluated to %s\n"): format(lib.repr(core.eval(e, S)))
      s = s..("  Constant: %.4g %s %.4g\n"):format(expected_constant,
        (expected_constant==got_constant and "==") or "~=", got_constant)
      local all = {}
      for k, v in pairs(expected_terms) do all[k] = true end
      for k, v in pairs(got_terms) do all[k] = true end
      local ordered = {}
      for k in pairs(all) do ordered[#ordered+1] = k end
      table.sort(ordered)
      for _, k in ipairs(ordered) do
        local a, b = expected_terms[k], got_terms[k]
        s = s..("  %s: %s %s %s\n"):format(k, lib.repr(a), (a==b and "==") or "~=", lib.repr(b))
      end
      T:test(false, s)
    else
      T:test(true)
    end
  end

  check_linear(1, 1, {}, S)
  check_linear(1 + a*5, 1, {a=5}, S)
  check_nonlinear(1 + a*b, S)
  check_linear(1 + a*b, 1, {a=5}, scope.spawn(S, {b=5}))
  check_linear(1 + d[2]*5, 1, {["d[2]"]=5}, S)
  check_linear(1 + rima.sum({c=d}, c*5), 1, {["d[1]"]=5, ["d[2]"]=5}, S)
  check_linear(1 + rima.sum({c=d}, d[c]*5), 1, {["d[1]"]=5, ["d[2]"]=5}, S)

  do
    local d, D = rima.R"d, D"
    T:expect_ok(LF(rima.sum{d=D}(d), rima.scope.new{ D = { rima.free() }}))
    T:expect_ok(LF(rima.sum{d=D}(d.a), rima.scope.new{ D = { {a=rima.free()} }}))
    local S = rima.scope.new{ D = { {a=1} }}
    S.D[d].b = rima.free()
    T:expect_ok(LF(rima.sum{d=D}(d.b), S))
    T:expect_ok(LF(rima.sum{d=D}(d.a * d.b), S))
  end

  -- element times variable
  do
    local i, x, q, Q = rima.R"i, x, q, Q"
    local S = scope.new{ Q = { 3, 7, 11, 13 } }
    S.x[i] = rima.free()
    check_linear(rima.sum{q=Q}(q * x[q]), 0, {["x[3]"]=3,["x[7]"]=7,["x[11]"]=11,["x[13]"]=13}, S)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------
