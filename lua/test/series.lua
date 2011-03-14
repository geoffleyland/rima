-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local debug, io = require("debug"), require("io")
local xpcall, tostring, type = xpcall, tostring, type
local setmetatable = setmetatable

module(...)

-- Test Tools ------------------------------------------------------------------

series = _M

function series:new(name_or_module, options)
  if type(name_or_module) == "table" then
    name_or_module = name_or_module._NAME
  end

  if not options.quiet then
    io.write(("Testing %s...\n"):format(name_or_module))
  end

  self.__index = self
  return setmetatable({ name=name_or_module, options=options, tests=0, fails=0 }, self)
end


function series:close()
  if not self.options.quiet then
    io.write(("%s: %s - passed %d/%d tests\n"):format(
             self.name, self.fails == 0 and "pass" or "*****FAIL*****",
             self.tests - self.fails, self.tests))
  end
  return self.fails == 0, self.tests, self.fails
end


local function test_source_line(depth)
  local info = debug.getinfo(depth, "Sl")
  return ("%s:%d"):format(info.short_src, info.currentline)
end

function series:test(pass, description, message, depth)
  depth = depth or 2
  self.tests = self.tests + 1
  if not pass and not self.options.dont_show_fails then
    io.write(("%s test, %s%s: *****FAIL*****%s\n"):format(self.name, test_source_line(depth+1),
      description and (" (%s)"):format(description) or "",
      message and (": %s"):format(message) or ""))
    self.fails = self.fails + 1
  elseif self.options.show_passes then
    io.write(("%s test, %s%s: pass%s\n"):format(self.name, test_source_line(depth+1),
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
      ("result mismatch:\n  expected: \"%s\"\n  got:      \"%s\""):format(
        expected:gsub("\n", "\n             "),
        got:gsub("\n", "\n             ")), (depth or 0) + 3)
end


function series:expect_ok(f, description, depth)
  local status, message = xpcall(f, debug.traceback)
  return self:test(status, description, not status and
    ("unexpected error%s"):format(message and (" \"%s\""):format(message) or ""), (depth or 0) + 3)
end


function series:expect_error(f, expected, description, depth)
  depth = (depth or 0) + 3
  expected = expected:gsub("%%L", test_source_line(depth):gsub("%.", "%."))

  local status, message = xpcall(f, debug.traceback)

  if status then
    return self:test(false, description,
      ("got ok, expected error:\n  \"%s\""):format(expected:gsub("\n", "\n   ")), depth)
  elseif not message:match(expected) then
    return self:test(false, description, ("expected error:\n  \"%s\"\ngot error:\n  \"%s\""):
      format(expected:gsub("\n", "\n   "), message:gsub("\n", "\n   ")), depth)
  else
    return self:test(true, description,
      ("got expected error:\n  \"%s\""):format(message:gsub("\n", "\n   ")), depth)
  end
end


function series:run(T)
  local _, t, f = T(self.options)
  self.tests = self.tests + t
  self.fails = self.fails + f
end


-- EOF -------------------------------------------------------------------------

