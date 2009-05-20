-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

-- Internal tools for Rima

local debug = require("debug")
local error, tostring, type = error, tostring, type
local ipairs = ipairs
local setmetatable = setmetatable

local tests = require("rima.tests")
local object = require("rima.object")

module(...)

-- Argument Checking -----------------------------------------------------------

function fail_arg(got, name, expected, caller_usage, caller_name, depth)
  local fname, usage =
    "rima.tools.fail_arg",
    "fail_arg(got, name, expected, caller_usage, caller_name)"

  depth = depth or 2
  caller_name = caller_name or debug.getinfo(2, "n").name or "anonymous function"
  check_arg_type(got, "got", "string", usage, fname)
  check_arg_type(name, "name", "string", usage, fname)
  check_arg_type(expected, "expected", "string", usage, fname)
  check_arg_types(caller_usage, "caller_usage", {"string", "nil"}, usage, fname)
  check_arg_type(caller_name, "caller_name", "string", usage, fname)
  
  local article = expected:sub(1,1):match("[aeiouAEIOU]") and "an" or "a"

  caller_usage = caller_usage and ("\n  Usage: %s"):format(caller_usage) or ""
  error(("%s: expecting %s %s for '%s', got '%s'.%s"):
    format(caller_name, article, expected, name, got, caller_usage), depth)
end

function check_arg_type(arg, name, expected, caller_usage, caller_name)
  local fname, usage =
    "rima.tools.check_arg_type",
    "check_arg_type(arg, name, expected: typename | {metatable | checkfunction, name}, caller_usage, caller_name)"

  local function caller()
    return caller_name or debug.getinfo(3, "n").name or "anonymous function"
  end

  if type(expected) == "string" then
    if object.type(arg) ~= expected then
      fail_arg(object.type(arg), name, expected, caller_usage, caller())
    end
  elseif type(expected) == "table" then
    if type(expected[1]) == "table" then
      if not object.isa(arg, expected[1]) then
        fail_arg(object.type(arg), name, expected[2], caller_usage, caller(), 3)
      end
    elseif type(expected[1]) == "function" then
      if not expected[1](arg) then
        fail_arg(object.type(arg), name, expected[2], caller_usage, caller(), 3)
      end
    else
      fail_arg(type(expected), "expected", "type description", usage, fname)
    end
  else
    fail_arg(type(expected), "expected", "type description", usage, fname)
  end
end

function check_arg_types(arg, name, expected, caller_usage, caller_name)
  local fname, usage =
    "rima.tools.check_arg_types",
    "check_arg_types(arg, name, expected: {typename | {metatable | checkfunction, name} [, ...]}, caller_usage, caller_name)"

  if type(expected) ~= "table" then
    fail_arg(type(expected), "expected", "type description", usage, fname)
  end

  for _, e in ipairs(expected) do
    if type(e) == "string" then
      if object.type(arg) == e then return end
    elseif type(e) == "table" then
      if type(e[1]) == "table" then
        if object.isa(arg, e[1]) then return end
      elseif type(e[1]) == "function" then
        if e[1](arg) then return end
      else
        fail_arg(type(expected), "expected", "type description", usage, fname)
      end
    else
      fail_arg(type(expected), "expected", "type description", usage, fname)
    end
  end
  
  local names = ""
  local n = #expected
  for i, e in ipairs(expected) do
    if i > 1 then
      if i == n then names = names.." or "
      else names = names..", "
      end
    end
    if type(e) == "string" then names = names..e
    elseif type(e) == "table" then names = names..e[2]
    end
  end

  fail_arg(object.type(arg), name, names, caller_usage,
           caller_name or debug.getinfo(2, "n").name or "anonymous function", 3)
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  -- fail_arg
  T:expect_error(function() fail_arg("number" ,"arg", "string", "fn()", "fname") end,
    "fname: expecting a string for 'arg', got 'number'%.\n  Usage: fn()")

  local function f() fail_arg("number", "arg", "string") end
  T:expect_error(function() f() end, "f: expecting a string for 'arg', got 'number'%.$")
  T:expect_error(function() fail_arg("number", "arg", "string", "fn()") end,
    "anonymous function: expecting a string for 'arg', got 'number'")

  -- check_arg_type
  T:expect_error(function() check_arg_type(1, "arg", 1, "fn()", "fname") end,
    "rima.tools.check_arg_type: expecting a type description for 'expected', got 'number'")
  T:expect_error(function() check_arg_type(1, "arg", {1}, "fn()", "fname") end,
    "rima.tools.check_arg_type: expecting a type description for 'expected', got 'table'")

  -- check_arg_type with types
  T:expect_error(function() check_arg_type(1, "arg", "string", "fn()", "fname") end,
    "fname: expecting a string for 'arg', got 'number'%.\n  Usage: fn()")
  T:expect_ok(function() check_arg_type("a string", "arg", "string", "fn()", "fname") end)

  local function g() check_arg_type("a string", "arg", "number") end
  T:expect_error(function() g() end, "g: expecting a number for 'arg', got 'string'%.$")
  T:expect_ok(function() check_arg_type(1, "arg", "number", "fn()") end)

  -- check_arg_type with metatables
  T:expect_error(function() check_arg_type(1, "arg", {{}, "my_class"}) end,
    "anonymous function: expecting a my_class for 'arg', got 'number'")
  T:expect_error(function() check_arg_type("a", "arg", {{}, "my_class"}) end,
    "expecting a my_class for 'arg', got 'string'")
  T:expect_error(function() check_arg_type({}, "arg", {{}, "my_class"}) end,
    "expecting a my_class for 'arg', got 'table'")
  T:expect_error(function() check_arg_type(setmetatable({}, {}), "arg", {{}, "my_class"}) end,
    "expecting a my_class for 'arg', got 'table'")
  local mt = {}
  T:expect_ok(function() check_arg_type(setmetatable({}, mt), "arg", {mt, "my_class"}) end)

  -- check_arg_type with functions
  T:expect_error(function() check_arg_type(1, "arg", {function() return false end, "nothing, not even nil"}) end,
    "expecting a nothing, not even nil for 'arg', got 'number'")
  T:expect_ok(function() check_arg_type(1, "arg", {function() return true end, "anything"}) end)

  T:expect_error(function() check_arg_type(1, "arg", {function(x) return type(x) == "string" end, "string"}) end,
    "expecting a string for 'arg', got 'number'")
  T:expect_ok(function() check_arg_type("a", "arg", {function(x) return type(x) == "string" end, "string"}) end)

  -- check_arg_types
  T:expect_error(function() check_arg_types(1, "arg", 1, "fn()", "fname") end,
    "rima.tools.check_arg_types: expecting a type description for 'expected', got 'number'")
  T:expect_error(function() check_arg_types(1, "arg", {1}, "fn()", "fname") end,
    "rima.tools.check_arg_types: expecting a type description for 'expected', got 'table'")
  T:expect_error(function() check_arg_types(1, "arg", {{1}}, "fn()", "fname") end,
    "rima.tools.check_arg_types: expecting a type description for 'expected', got 'table'")

  T:expect_error(function() check_arg_types({}, "arg", {"string", "number"}, "fn()") end,
    "anonymous function: expecting a string or number for 'arg', got 'table'%.\n  Usage: fn()")
  T:expect_ok(function() check_arg_types("a", "arg", {"string", "number"}) end)
  T:expect_ok(function() check_arg_types(1, "arg", {"string", "number"}) end)

  local function h() check_arg_types({}, "arg", {"string", {{}, "my_class"}}) end
  T:expect_error(function() h() end,
    "h: expecting a string or my_class for 'arg', got 'table'")
  T:expect_error(function() check_arg_types(nil, "arg", {"string", "number", {{}, "my_class"}})  end,
    "expecting a string, number or my_class for 'arg', got 'nil'")
  T:expect_ok(function() check_arg_types(setmetatable({}, mt), "arg", {"string", "number", {mt, "my_class"}})  end)

  local function no() return false end
  local function yes() return true end
  T:expect_error(function() check_arg_types(1, "arg", {"string", {no, "nothing"}})  end,
    "expecting a string or nothing for 'arg', got 'number'")
  T:expect_ok(function() check_arg_types("a", "arg", {"string", {no, "nothing"}})  end)
  T:expect_ok(function() check_arg_types(1, "arg", {"string", {yes, "anything"}})  end)
  T:expect_ok(function() check_arg_types("a", "arg", {"string", {yes, "anything"}})  end)

  return T:close()
end


-- EOF -------------------------------------------------------------------------

