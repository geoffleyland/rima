-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local error, type = error, type

local lib = require("rima.lib")
local undefined_t = require("rima.types.undefined_t")

module(...)


-- Number type -----------------------------------------------------------------

local number_t = undefined_t:new_class(_M, "number_t")

function number_t:new(lower, upper, integer)
  lower, upper = lower or -math.huge, upper or math.huge
  integer = (integer and true) or false

--  lower, upper = rima.eval(lower), rima.eval(upper)

  if type(lower) == "number" and type(upper) == "number" and lower > upper then
    error(("lower bound must be <= upper bound, got %s and %s."):format(
          lib.repr(lower), lib.repr(upper)))
  end
  if type(lower) == "number" and integer and math.floor(lower) ~= lower then
    error(("lower bound is not integer, got %s."):format(
          lib.repr(lower)))
  end
  if type(upper) == "number" and integer and math.floor(upper) ~= upper then
    error(("upper bound is not integer, got %s."):format(
          lib.repr(upper)))
  end

  return undefined_t.new(self, { lower=lower, upper=upper, integer=integer })
end


-- String representation -------------------------------------------------------

function number_t:__repr(format)
  if self.integer and self.lower == 0 and self.upper == 1 then return "binary" end
--  return ("%s <= V <= %s, V %s"):format(
--    lib.repr(self.lower), lib.repr(self.upper), self.integer and "integer" or "real")
  return ("%s <= * <= %s, * %s"):format(
    lib.repr(self.lower, format), lib.repr(self.upper, format), self.integer and "integer" or "real")
end
number_t.__tostring = lib.__tostring

local no_format = {}
function number_t:describe(vars, format)
--  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  format = format or no_format
  local vr = lib.repr(vars, format)
  local ff = format.format

  if self.integer and self.lower == 0 and self.upper == 1 then
    if ff == "latex" then
      return vr.." \\in \\{0, 1\\}"
    else
      return vr.." binary"
    end
  end
  
  local f, set
  if ff == "latex" then
    f = "%s \\leq %s \\leq %s, %s \\in %s"
    set = self.integer and "\\mathcal{I}" or "\\Re"
  else
    f = "%s <= %s <= %s, %s %s"
    set = self.integer and "integer" or "real"
  end
  
  return f:format(lib.repr(self.lower), vr, lib.repr(self.upper), vr, set)
end

--[[
function number_t:describe(vars, env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  if self.integer and self.lower == 0 and self.upper == 1 then return vars.." binary" end
  return ("%s <= %s <= %s, %s %s"):format(
    lib.repr(lower), vars, lib.repr(upper), vars, self.integer and "integer" or "real")
end
--]]
-- Checks ----------------------------------------------------------------------

function number_t:includes(x)
  local fname, usage =
    "rima.types.number_t:includes",
    "includes(x<number or type>)"

  local tx = typeinfo(x)

  if tx.number then
    if x < self.lower then return false end
    if x > self.upper then return false end
    if self.integer and x ~= math.floor(x) then return false end
    return true
  elseif tx.undefined_t then
    if tx.number_t then
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

local _free = number_t:new()
local _positive = number_t:new(0)
local _negative = number_t:new(nil, 0)
local _integer = number_t:new(0, math.huge, true)
local _binary = number_t:new(0, 1, true)

function free(lower, upper)
--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _free
  else
    return number_t:new(lower, upper)
  end
end

function positive(lower, upper)
--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _positive
  else
    local n = number_t:new(lower, upper)
    if not _positive:includes(n) then
      error("bounds for positive variables must be positive", 1)
    end
    return n
  end
end

function negative(lower, upper)
--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _negative
  else
    local n = number_t:new(lower, upper)
    if not _negative:includes(n) then
      error("bounds for negative variables must be negative", 1)
    end
    return n
  end
end

function integer(lower, upper)
--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _integer
  else
    return number_t:new(lower, upper, true)
  end
end

function binary()
  return _binary
end


-- EOF -------------------------------------------------------------------------

