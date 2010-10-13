-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, rawget = ipairs, rawget

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local expression = require("rima.expression")
local undefined_t = require("rima.types.undefined_t")

module(...)


-- Subscripts ------------------------------------------------------------------

local case = object:new(_M, "case")
case.precedence = 1


-- String Representation -------------------------------------------------------

function case.__repr(args, format)
  args = proxy.O(args)
  local s = ("case %s ("):format(lib.repr(args[1], format))
  for _, v in ipairs(args[2]) do
    s = s..("%s: %s; "):format(lib.repr(v[1], format), lib.repr(v[2], format))
  end
  if rawget(args, 3) then
    s = s..("default: %s; "):format(lib.repr(args[3]))
  end
  s = s..")"
  return s
end


-- Evaluation ------------------------------------------------------------------

function case.__eval(args, S)
  args = proxy.O(args)
  local value = core.eval(args[1], S)
  local cases = {}
  for i, v in ipairs(args[2]) do
    local match_value = core.eval(v[1], S)
    local result
    if undefined_t:isa(v[2]) then
      result = v[2]
    else
      result = core.eval(v[2], S)
    end
    cases[i] = { match_value, result }
  end
  local default
  if args[3] then default = core.eval(args[3], S) end
  
  local remaining_cases = {}
  local matched = false

  if core.defined(value) then
    for i, v in ipairs(cases) do
      if core.defined(v[1]) then
        if value == v[1] then
          if remaining_cases[1] then
            remaining_cases[#remaining_cases+1] = v
            matched = true
            default = nil
          else
            return v[2]  -- first definite match
          end
        end
      else
        if not matched then
          remaining_cases[#remaining_cases+1] = v
        end
      end
    end
    if remaining_cases[1] then
      return expression:new(case, value, remaining_cases, default)
    else
      return default
    end
  else
    return expression:new(case, value, cases, default)
  end
end


-- EOF -------------------------------------------------------------------------

