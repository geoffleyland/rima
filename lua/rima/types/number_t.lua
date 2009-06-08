-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error = error
local math = require("math")

local tests = require("rima.tests")
local args = require("rima.args")
local undefined_t = require("rima.types.undefined_t")
local types = rima.types
local rima = rima

module(...)

-- Number type -----------------------------------------------------------------

local number_t = undefined_t:new(_M, "number_t")

function number_t:new(lower, upper, integer)
  local fname, usage =
    "rima.types.number_t:new",
    "new([lower_bound [, upper_bound, [, is_integral]]])"

  lower, upper = lower or -math.huge, upper or math.huge
  integer = (integer and true) or false

  args.check_type(lower, "lower_bound", "number", usage, fname)
  args.check_type(upper, "upper_bound", "number", usage, fname)

--  lower, upper = rima.eval(lower), rima.eval(upper)

--  assert((type(lower) == "number" or variable.isa(lower) or expression.isa(lower)) and
--         (type(upper) == "number" or variable.isa(upper) or expression.isa(upper)),
--         "Upper and lower bounds must be numbers, variables or expressions")

  if type(lower) == "number" and type(upper) == "number" and lower > upper then
    error(("%s: lower bound must be <= upper bound, got %s and %s.\n  Usage: %s"):format(
          fname, rima.tostring(lower), rima.tostring(upper), usage))
  end
  if type(lower) == "number" and integer and math.floor(lower) ~= lower then
    error(("%s: lower bound is not integer, got %s.\n  Usage: %s"):format(
          fname, rima.tostring(lower), usage))
  end
  if type(upper) == "number" and integer and math.floor(upper) ~= upper then
    error(("%s: upper bound is not integer, got %s.\n  Usage: %s"):format(
          fname, rima.tostring(upper), usage))
  end

  return undefined_t.new(self, { lower=lower, upper=upper, integer=integer })
end


-- String representation -------------------------------------------------------

function number_t:__tostring()
  if self.integer and self.lower == 0 and self.upper == 1 then return "binary" end
--  return ("%s <= V <= %s, V %s"):format(
--    rima.tostring(self.lower), rima.tostring(self.upper), self.integer and "integer" or "real")
  return ("%s <= * <= %s, * %s"):format(
    rima.tostring(self.lower), rima.tostring(self.upper), self.integer and "integer" or "real")
end

function number_t:describe(vars)
--  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  if self.integer and self.lower == 0 and self.upper == 1 then return vars.." binary" end
  return ("%s <= %s <= %s, %s %s"):format(
    rima.tostring(self.lower), vars, rima.tostring(self.upper), vars, self.integer and "integer" or "real")
end

--[[
function number_t:describe(vars, env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  if self.integer and self.lower == 0 and self.upper == 1 then return vars.." binary" end
  return ("%s <= %s <= %s, %s %s"):format(
    rima.tostring(lower), vars, rima.tostring(upper), vars, self.integer and "integer" or "real")
end
--]]
-- Checks ----------------------------------------------------------------------

function number_t:includes(x)
  local fname, usage =
    "rima.types.number_t:includes",
    "includes(x<number or type>)"

  if type(x) == "number" then
    if x < self.lower then return false end
    if x > self.upper then return false end
    if self.integer and x ~= math.floor(x) then return false end
    return true
  elseif isa(x, undefined_t) then
    if isa(x, number_t) then
      if x.lower < self.lower then return false end
      if x.upper > self.upper then return false end
      if self.integer and not x.integer then return false end
      return true
    else
      return false
    end
  else
    return false
  end
end

--[[

function number_t:defined(env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  return type(lower) == "number" and type(upper) == "number"
end

function number_t:evaluate(env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  return lower, upper, self.integer
end

function number_t:check(v, env)
  v = rima.eval(v, env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  if type(v) == "number" then
    if type(lower) == "number" then
      assert(v >= lower, "The value is less than the lower bound")
    end
    if type(upper) == "number" then
      assert(v <= upper, "The value is greater than the upper bound")
    end
    assert(not self.integer or math.floor(v) == v, "The value in not an integer")
  end
end

--]]
-- Standard number types and shortcuts -----------------------------------------

local _free
local _positive
local _negative
local _integer
local _binary

function rima.free(lower, upper)
  _free = _free or number_t:new()

--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _free
  else
    return number_t:new(lower, upper)
  end
end

function rima.positive(lower, upper)
  local fname, usage =
    "rima.positive",
    "positive([lower_bound [, upper_bound]])"
  _positive = _positive or number_t:new(0)

--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _positive
  else
    local n = number_t:new(lower, upper)
    if not _positive:includes(n) then
      error(("%s: bounds for positive variables must be positive"):format(fname, usage))
    end
    return n
  end
end

function rima.negative(lower, upper)
  local fname, usage =
    "rima.negative",
    "negative([lower_bound [, upper_bound]])"

  _negative = _negative or number_t:new(nil, 0)
--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _negative
  else
    local n = number_t:new(lower, upper)
    if not _negative:includes(n) then
      error(("%s: bounds for negative variables must be negative"):format(fname, usage))
    end
    return n
  end
end

function rima.integer(lower, upper)
  _integer = _integer or number_t:new(0, math.huge, true)

--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _integer
  else
    return number_t:new(lower, upper, true)
  end
end

function rima.binary()
  _binary = _binary or number_t:new(0, 1, true)
  return _binary
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(isa(number_t:new(), number_t), "isa(number_t:new(), number_t)")
  T:test(isa(number_t:new(), undefined_t), "isa(number_t:new(), undefined_t)")
  T:equal_strings(type(number_t:new()), "number_t", "type(number_t:new()) == 'number_t'")

  T:expect_error(function() number_t:new("lower") end, "expecting a number for 'lower_bound', got 'string'")
  T:expect_error(function() number_t:new(1, {}) end, "expecting a number for 'upper_bound', got 'table'")
  T:expect_error(function() number_t:new(2, 1) end, "lower bound must be <= upper bound")
  T:expect_error(function() number_t:new(1.1, 2, true) end, "lower bound is not integer")
  T:expect_error(function() number_t:new(1, 2.1, true) end, "upper bound is not integer")

  T:equal_strings(number_t:new(0, 1, true), "binary")
  T:equal_strings(number_t:new(0, 1), "0 <= * <= 1, * real")
  T:equal_strings(number_t:new(1, 100, true), "1 <= * <= 100, * integer")

  T:equal_strings(number_t:new(0, 1, true):describe("a"), "a binary")
  T:equal_strings(number_t:new(0, 1):describe("b"), "0 <= b <= 1, b real")
  T:equal_strings(number_t:new(1, 100, true):describe("c"), "1 <= c <= 100, c integer")

  T:test(not number_t:new():includes("a string"), "number does not include string")
  T:test(number_t:new(0, 1):includes(0), "(0, 1) includes 0")
  T:test(number_t:new(0, 1):includes(1), "(0, 1) includes 2")
  T:test(number_t:new(0, 1):includes(0.5), "(0, 1) includes 0.5")
  T:test(not number_t:new(0, 1):includes(-0.1), "(0, 1) does not include -0.1")
  T:test(not number_t:new(0, 1):includes(2), "(0, 1) does not include 2")

  T:test(number_t:new(0, 1, true):includes(0), "(0, 1, int) includes 0")
  T:test(number_t:new(0, 1, true):includes(1), "(0, 1, int) includes 2")
  T:test(not number_t:new(0, 1, true):includes(0.5), "(0, 1, int) does not include 0.5")
  T:test(not number_t:new(0, 1, true):includes(-0.1), "(0, 1, int) does not include -0.1")
  T:test(not number_t:new(0, 1, true):includes(2), "(0, 1, int) does not include 2")

  T:test(not number_t:new(0, 1):includes(undefined_t:new()), "(0, 1) does not include undefined")
  T:test(number_t:new(0, 1):includes(number_t:new(0, 1)), "(0, 1) includes (0, 1)")
  T:test(number_t:new(0, 1):includes(number_t:new(0.1, 1)), "(0, 1) includes (0.1, 1)")
  T:test(not number_t:new(0, 1):includes(number_t:new(0, 1.1)), "(0, 1) does not include (0, 1.1)")
  T:test(number_t:new(0, 1):includes(number_t:new(0, 1, true)), "(0, 1) includes (0, 1, int)")
  T:test(not number_t:new(0, 1, true):includes(number_t:new(0, 1)), "(0, 1, int) does not include (0, 1)")

  T:equal_strings(type(rima.free()), "number_t", "type(rima.free()) == 'number_t'")
  T:test(rima.free():includes(rima.free()), "free includes free")
  T:test(not rima.free(1):includes(rima.free()), "free(1) does not include free")

  T:equal_strings(type(rima.positive()), "number_t", "type(rima.positive()) == 'number_t'")
  T:expect_ok(function() rima.positive(3, 5) end)
  T:expect_error(function() rima.positive(-3, 5) end, "bounds for positive variables must be positive")

  T:equal_strings(type(rima.negative()), "number_t", "type(rima.negative()) == 'number_t'")
  T:expect_ok(function() rima.negative(-3, -1) end)
  T:expect_error(function() rima.negative(-3, 5) end, "bounds for negative variables must be negative")

  T:equal_strings(type(rima.integer()), "number_t", "type(rima.integer()) == 'number_t'")
  T:expect_ok(function() rima.integer(-5, 5) end)
  T:expect_error(function() rima.integer(0.5, 5) end, "lower bound is not integer")

  T:expect_ok(function() rima.binary() end)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

