-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error, ipairs, unpack, pcall = error, ipairs, unpack, pcall

local rima = require("rima")
local proxy = require("rima.proxy")
local tests = require("rima.tests")
local scope = require("rima.scope")
local expression = rima.expression

module(...)

-- Addition --------------------------------------------------------------------

local call = rima.object:new(_M, "call")


-- Argument Checking -----------------------------------------------------------

function call:check(args)
end


-- String Representation -------------------------------------------------------

function call:_tostring(args)
  local s = expression.parenthise(args[1], 0).."("
  for i = 2, #args do
    if i > 2 then s = s..", " end
    s = s..rima.tostring(args[i])
  end
  return s..")"
end


-- Evaluation ------------------------------------------------------------------

function call:eval(S, args)
  local e = expression.eval(args[1], S)
  if isa(e, rima.ref) or isa(e, expression) then
    return expression:new(call, e, unpack(args, 2))
  else
    local status, r
    if type(e) == "function" then
      for i, a in ipairs(args) do
        args[i] = expression.eval(a, S)
      end
      status, r = pcall(function() return e(unpack(args, 2)) end)
    else
      status, r = pcall(function() return e:call(S, {unpack(args, 2)}) end)
    end

    if not status then
      error(("error while evaluating '%s':\n  %s"):
        format(self:_tostring(args), r:gsub("\n", "\n  ")), 0)
    end
    return r
  end
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(isa(call:new(), call), "isa(call:new(), call)")
  T:equal_strings(type(call:new()), "call", "type(call:new()) == 'call'")

  local S = rima.scope.create{ a = rima.free(), b = rima.free(), x = rima.free() }

  T:equal_strings(expression.dump(S.a(S.b)), "call(ref(a), ref(b))")
  T:equal_strings(S.a(S.b), "a(b)")

  -- The a here ISN'T in the global scope, it's in the function scope
  S.f = rima.values.function_v:new({rima.R"a"}, 2 * rima.R"a")

  local c = rima.R"f"(3 + S.x)
  T:equal_strings(c, "f(3 + x)")

  T:equal_strings(expression.dump(c), "call(ref(f), +(1*number(3), 1*ref(x)))")
  T:equal_strings(expression.eval(c, S), "2*(3 + x)")
  S.x = 5
  T:equal_strings(expression.eval(c, S), 16)

  local c2 = expression:new(call, rima.R"f")
  T:expect_error(function() expression.eval(c2, S) end,
    "error while evaluating 'f%(%)':\n  the function needs to be called with at least")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

