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

local function eval_preserve(S, value, type, addr)
  local t, a
  value, t, a = core.eval(value, S)
  return value, t or type, a or addr
end


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
    if value_defined and core.defined(match_value) then
      if value == match_value then
        local value, type, addr = eval_preserve(S, v[2], v[3], v[4])
        if #cases == 0 then  -- if it's the first match, and none of the
                             -- preceeding ones were undefined, we're done
          return value, type, addr
        end
        -- otherwise, collect it and stop
        cases[#cases+1] = { match_value, value, type, addr }
        found_match = true
        break
      end
    else -- if we can't compare it, collect it
      cases[#cases+1] = { match_value, eval_preserve(S, v[2], v[3], v[4]) }
    end
  end
  -- if no cases matched, return the default (if there is one)
  if #cases == 0 and args[3] then
    return eval_preserve(S, args[3], args[4], args[5])
  end

  -- only keep the default if we didn't find a match (we might be here if we
  -- did find a match, but earlier match values weren't defined)
  if found_match or not args[3] then
    return expression:new(case, value, cases)
  else
    return expression:new(case, value, cases, eval_preserve(S, args[3], args[4], args[5]))
  end
end


-- EOF -------------------------------------------------------------------------

