-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

-- Internal tools for Rima

local debug = require("debug")
local error, ipairs, type = error, ipairs, type

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


-- EOF -------------------------------------------------------------------------

