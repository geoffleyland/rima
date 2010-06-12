-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local debug, io = require("debug"), require("io")
local xpcall, tostring, type = xpcall, tostring, type
local setmetatable = setmetatable

module(...)

-- Test Tools ------------------------------------------------------------------

series = _M

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


function series:check_equal(got, expected, description, depth)
  got, expected = tostring(got), tostring(expected)
  local pass = got == expected
  return self:test(pass, description,
    pass and ("got expected string \"%s\""):format(got) or
      ("result mismatch:\n  expected: \"%s\"\n  got:      \"%s\""):format(expected, got), (depth or 0) + 3)
end


function series:expect_ok(f, description, depth)
  local status, message = xpcall(f, debug.traceback)
  return self:test(status, description, not status and
    ("unexpected error%s"):format(message and (" \"%s\""):format(message) or ""), (depth or 0) + 3)
end


function series:expect_error(f, expected, description, depth)
  local status, message = xpcall(f, debug.traceback)

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


-- EOF -------------------------------------------------------------------------

