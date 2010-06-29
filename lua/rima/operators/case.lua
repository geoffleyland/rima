-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, rawget = ipairs, rawget

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local core = require("rima.core")
local expression = require("rima.expression")
local rima = rima

module(...)

-- Subscripts ------------------------------------------------------------------

local case = object:new(_M, "case")
case.precedence = 1

rima.case = function(value, cases, default)
  return expression:new(case, value, cases, default)
end


-- String Representation -------------------------------------------------------

function case.__repr(args, format)
  args = proxy.O(args)
  local s = ("case %s ("):format(rima.repr(args[1], format))
  for _, v in ipairs(args[2]) do
    s = s..("%s: %s; "):format(rima.repr(v[1], format), rima.repr(v[2], format))
  end
  if rawget(args, 3) then
    s = s..("default: %s; "):format(rima.repr(args[3]))
  end
  s = s..")"
  return s
end


-- Evaluation ------------------------------------------------------------------

function case.__eval(args, S, eval)
  local value = eval(args[1], S)
  local cases = {}
  for i, v in ipairs(args[2]) do
    cases[i] = { eval(v[1], S), eval(v[2], S) }
  end
  local default
  if args[3] then default = eval(args[3], S) end
  
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
      return rima.case(value, remaining_cases, default)
    else
      return default
    end
  else
    return rima.case(value, cases, default)
  end
end


-- EOF -------------------------------------------------------------------------

