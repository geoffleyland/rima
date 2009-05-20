-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

-- Testing tools that test themselves...

local debug, io = require("debug"), require("io")
local assert, error, pcall, tostring, type = assert, error, pcall, tostring, type
local setmetatable = setmetatable

module(...)

-- Test Tools ------------------------------------------------------------------

series = {}

function series:new(name_or_module, show_passes)
  if type(name_or_module) == "table" then
    name_or_module = name_or_module._NAME
  end

  io.write(("Testing %s...\n"):format(name_or_module))

  self.__index = self
  return setmetatable({ name=name_or_module, show_passes=show_passes and true or false, tests=0, fails=0 }, self)
end

function series:close()
  io.write(("%s: %s - passed %d/%d tests\n"):format(
           self.name, self.fails == 0 and "pass" or "*****FAIL*****",
           self.tests - self.fails, self.tests))
  return self.fails == 0, self.tests, self.fails
end

function series:test(pass, description, message, depth)
  depth = depth or 2
  self.tests = self.tests + 1
  if not pass then
    local info = debug.getinfo(depth, "Sl")
    io.write(("%s test, %s:%s%s: *****FAIL*****%s\n"):format(self.name, info.short_src, info.currentline,
      description and (" (%s)"):format(description) or "",
      message and (": %s"):format(message) or ""))
    self.fails = self.fails + 1
  elseif self.show_passes then
    local info = debug.getinfo(depth, "Sl")
    io.write(("%s test, %s:%s%s: pass%s\n"):format(self.name, info.short_src, info.currentline,
      description and (" (%s)"):format(description) or "",
      message and (": %s"):format(message) or ""))
  end
  return pass
end

function series:equal_strings(got, expected, description, depth)
  got, expected = tostring(got), tostring(expected)
  local pass = got == expected
  return self:test(pass, description,
    pass and ("got expected string \"%s\""):format(got) or
      ("expected string \"%s\", got \"%s\""):format(expected, got), (depth or 0) + 3)
end

function series:expect_ok(f, description, depth)
  local status, message = pcall(f)
  return self:test(status, description, not status and
    ("unexpected error%s"):format(message and (" \"%s\""):format(message) or ""), (depth or 0) + 3)
end

function series:expect_error(f, expected, description, depth)
  local status, message = pcall(f)

  if status then
    return self:test(false, description,
      ("got ok, expected error:\n  \"%s\""):format(expected:gsub("\n", "\n   ")), (depth or 0) + 3)
  elseif not message:match(expected) then
    return self:test(false, description, ("expected error:\n  \"%s\"\ngot error:\n  \"%s\""):
      format(expected:gsub("\n", "\n   "), message:gsub("\n", "\n   ")), (depth or 0) + 3)
  else
    return self:test(true, description,
      ("got expected error:\n  \"%s\""):format(message:gsub("\n", "\n   ")), (depth or 0) + 3)
  end
end

function series:run(T)
  local _, t, f = T(self.show_passes)
  self.tests = self.tests + t
  self.fails = self.fails + f
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local function a(show_passes)
    local LT = series:new("test test", not show_passes)
    local ok, t, f = LT:close()
    T:expect_ok(function() assert(ok == true and t == 0 and f == 0, "empty test") end, "empty test ok")
    LT:test(true, "showing a pass")
    return LT:close()
  end
  T:run(a)

  local LT = series:new("NOT REAL ERRORS", false)

  -- series:test()    
  T:expect_ok(function() LT:test(true, "description", "message") end, "series:test")
  T:expect_ok(function() LT:test(false, "THIS IS NOT A FAIL", "THIS IS NOT A FAIL") end, "series:test")
  T:test(LT:test(true, "description", "message"), "series:test")
  T:test(not LT:test(false, "THIS IS NOT A FAIL", "THIS IS NOT A FAIL"), "series:test")

  -- series:equal_strings
  T:expect_ok(function() LT:equal_strings("a", "b", "THIS IS NOT A FAIL") end, "series:equal_strings")
  T:expect_ok(function() LT:equal_strings("a", "a", "THIS IS NOT A FAIL") end, "series:equal_strings")
  T:expect_ok(function() LT:equal_strings(1, 2, "THIS IS NOT A FAIL") end, "series:equal_strings")
  T:expect_ok(function() LT:equal_strings(1, 1, "THIS IS NOT A FAIL") end, "series:equal_strings")

  T:test(not LT:equal_strings("a", "b", "THIS IS NOT A FAIL"), "series:equal_strings")
  T:test(LT:equal_strings("a", "a", "THIS IS NOT A FAIL"), "series:equal_strings")
  T:test(not LT:equal_strings(1, 2, "THIS IS NOT A FAIL"), "series:equal_strings")
  T:test(LT:equal_strings(1, 1, "THIS IS NOT A FAIL"), "series:equal_strings")

  -- series:expect_error
  T:expect_ok(function() LT:expect_error(function() error("an error!") end, "another_error") end, "series:expect_error")
  T:expect_ok(function() LT:expect_error(function() error("an error!") end, "an error!") end, "series:expect_error")
  T:expect_ok(function() LT:expect_error(function() end, "no error") end, "series:expect_error")

  T:test(not LT:expect_error(function() error("an error!") end, "another_error"), "series:expect_error")
  T:test(LT:expect_error(function() error("an error!") end, "an error!"), "series:expect_error")
  T:test(not LT:expect_error(function() end, "no error"), "series:expect_error")
  

  return T:close()
end


-- EOF -------------------------------------------------------------------------

