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

  -- Evaluate the test value
  local value = core.eval(args[1], S)
  local value_defined = core.defined(value)

  -- Run through evaluating all the case values, seeing if we get a match
  local cases = {}
  local found_match
  for i, v in ipairs(args[2]) do
    local match_value = core.eval(v[1], S)
    if core.defined(match_value) then
      if value_defined and (value == match_value) then
        if #cases == 0 then  -- if it's the first match, and none of the
                             -- preceeding ones were undefined, we're done
          return core.eval(v[2], S)
        end
        -- otherwise, collect it and stop
        cases[#cases+1] = { match_value, (core.eval(v[2], S)) }
        found_match = true
        break
      end
    else -- if we can't compare it, collect it
      cases[#cases+1] = { match_value, (core.eval(v[2], S)) }
    end
  end
  -- if not cases matched, return the default (if there is one
  if #cases == 0 and args[3] then
    return core.eval(args[3], S)
  end

  -- only keep the default if we didn't find a match (we might be here if we
  -- did find a match, but earlier match values weren't defined)
  local default
  if not found_match then default = core.eval(args[3], S) end

  -- If we got this far, return a new case
  return expression:new(case, value, cases, default)
end


-- EOF -------------------------------------------------------------------------

