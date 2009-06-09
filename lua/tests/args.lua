-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local setmetatable, type = setmetatable, type

local series = require("test.series")
local args = require("rima.args")

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  -- fail
  T:expect_error(function() args.fail("number" ,"arg", "string", "fn()", "fname") end,
    "fname: expecting a string for 'arg', got 'number'%.\n  Usage: fn()")

  local function f() args.fail("number", "arg", "string") end
  T:expect_error(function() f() end, "f: expecting a string for 'arg', got 'number'%.")
  T:expect_error(function() args.fail("number", "arg", "string", "fn()") end,
    "anonymous function: expecting a string for 'arg', got 'number'")

  -- args.check_type
  T:expect_error(function() args.check_type(1, "arg", 1, "fn()", "fname") end,
    "rima.args.check_type: expecting a type description for 'expected', got 'number'")
  T:expect_error(function() args.check_type(1, "arg", {1}, "fn()", "fname") end,
    "rima.args.check_type: expecting a type description for 'expected', got 'table'")

  -- args.check_type with types
  T:expect_error(function() args.check_type(1, "arg", "string", "fn()", "fname") end,
    "fname: expecting a string for 'arg', got 'number'%.\n  Usage: fn()")
  T:expect_ok(function() args.check_type("a string", "arg", "string", "fn()", "fname") end)

  local function g() args.check_type("a string", "arg", "number") end
  T:expect_error(function() g() end, "g: expecting a number for 'arg', got 'string'%.")
  T:expect_ok(function() args.check_type(1, "arg", "number", "fn()") end)

  -- args.check_type with metatables
  T:expect_error(function() args.check_type(1, "arg", {{}, "my_class"}) end,
    "anonymous function: expecting a my_class for 'arg', got 'number'")
  T:expect_error(function() args.check_type("a", "arg", {{}, "my_class"}) end,
    "expecting a my_class for 'arg', got 'string'")
  T:expect_error(function() args.check_type({}, "arg", {{}, "my_class"}) end,
    "expecting a my_class for 'arg', got 'table'")
  T:expect_error(function() args.check_type(setmetatable({}, {}), "arg", {{}, "my_class"}) end,
    "expecting a my_class for 'arg', got 'table'")
  local mt = {}
  T:expect_ok(function() args.check_type(setmetatable({}, mt), "arg", {mt, "my_class"}) end)

  -- args.check_type with functions
  T:expect_error(function() args.check_type(1, "arg", {function() return false end, "nothing, not even nil"}) end,
    "expecting a nothing, not even nil for 'arg', got 'number'")
  T:expect_ok(function() args.check_type(1, "arg", {function() return true end, "anything"}) end)

  T:expect_error(function() args.check_type(1, "arg", {function(x) return type(x) == "string" end, "string"}) end,
    "expecting a string for 'arg', got 'number'")
  T:expect_ok(function() args.check_type("a", "arg", {function(x) return type(x) == "string" end, "string"}) end)

  -- args.check_types
  T:expect_error(function() args.check_types(1, "arg", 1, "fn()", "fname") end,
    "rima.args.check_types: expecting a type description for 'expected', got 'number'")
  T:expect_error(function() args.check_types(1, "arg", {1}, "fn()", "fname") end,
    "rima.args.check_types: expecting a type description for 'expected', got 'table'")
  T:expect_error(function() args.check_types(1, "arg", {{1}}, "fn()", "fname") end,
    "rima.args.check_types: expecting a type description for 'expected', got 'table'")

  T:expect_error(function() args.check_types({}, "arg", {"string", "number"}, "fn()") end,
    "anonymous function: expecting a string or number for 'arg', got 'table'%.\n  Usage: fn()")
  T:expect_ok(function() args.check_types("a", "arg", {"string", "number"}) end)
  T:expect_ok(function() args.check_types(1, "arg", {"string", "number"}) end)

  local function h() args.check_types({}, "arg", {"string", {{}, "my_class"}}) end
  T:expect_error(function() h() end,
    "h: expecting a string or my_class for 'arg', got 'table'")
  T:expect_error(function() args.check_types(nil, "arg", {"string", "number", {{}, "my_class"}})  end,
    "expecting a string, number or my_class for 'arg', got 'nil'")
  T:expect_ok(function() args.check_types(setmetatable({}, mt), "arg", {"string", "number", {mt, "my_class"}})  end)

  local function no() return false end
  local function yes() return true end
  T:expect_error(function() args.check_types(1, "arg", {"string", {no, "nothing"}})  end,
    "expecting a string or nothing for 'arg', got 'number'")
  T:expect_ok(function() args.check_types("a", "arg", {"string", {no, "nothing"}})  end)
  T:expect_ok(function() args.check_types(1, "arg", {"string", {yes, "anything"}})  end)
  T:expect_ok(function() args.check_types("a", "arg", {"string", {yes, "anything"}})  end)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

