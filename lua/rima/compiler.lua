-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local error, getmetatable, ipairs, loadstring, pcall =
      error, getmetatable, ipairs, loadstring, pcall
local table = require("table")

local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local index = require("rima.index")

module(...)


-- compiling expressions -------------------------------------------------------

local function build_scope(variables, arg_name)
  arg_name = arg_name or "args"

  local S = scope.new()
  local count = 1
  for i, v in ipairs(variables) do
    if v.sets then
      error(("The variable %s is not fully defined"):format(lib.repr(v.ref)))
    end
    local a = proxy.O(v.ref).address
    if #a > 1 then
      local v2 = index:new(S, a:sub(1, -2))
      v2[a:value(-1)] = index:new(nil, arg_name, count)
    else
      S[a:value(1)] = index:new(nil, arg_name, count)
    end
    count = count + 1
  end
  return S
end


local COMPILE_FORMAT = { format = "lua" }
local function stringify(e, S)
  return lib.repr(core.eval(e, S), COMPILE_FORMAT)
end


function compile(expressions, variables, arg_names)
  arg_names = arg_names or "args"
  local S = build_scope(variables)

  local function_string
  if not getmetatable(expressions) then
    local strings = {}
    for i, e in ipairs(expressions) do
      strings[i] = stringify(e, S)
    end
    function_string = "\n  {\n    "..table.concat(strings, ",\n    ").."\n  }"
  else
    function_string = " "..stringify(expressions, S)
  end
  
  function_string = "return function("..arg_names..")\n  return"..function_string.."\nend"

  local status, b = pcall(loadstring, function_string)
  if not status then
    error(("Error compiling following function: %s\n%s"):format(message, function_string))
  end
  return b(), function_string
end


-- EOF -------------------------------------------------------------------------