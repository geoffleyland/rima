-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")
local undefined_t = require("rima.types.undefined_t")


------------------------------------------------------------------------------

local case = operator:new_class({}, "case")
case.precedence = 1


------------------------------------------------------------------------------

function case:__repr(format)
  local s = ("case %s ("):format(lib.repr(self[1], format))
  for _, v in ipairs(self[2]) do
    s = s..("%s: %s; "):format(lib.repr(v[1], format), lib.repr(v[2], format))
  end
  if rawget(self, 3) then
    s = s..("default: %s; "):format(lib.repr(self[3]))
  end
  s = s..")"
  return s
end


------------------------------------------------------------------------------

local function eval_preserve(value, type, addr, ...)
  local t, a
  value, t, a = core.eval(value, ...)
  return value, t or type, a or addr
end


function case:__eval(...)
  -- Evaluate the test value
  local value = core.eval(self[1], ...)
  local value_defined = core.defined(value)

  -- Run through evaluating all the case values, seeing if we get a match
  local cases = {}
  local found_match
  for i, v in ipairs(self[2]) do
    local match_value = core.eval(v[1], ...)
    if value_defined and core.defined(match_value) then
      if value == match_value then
        local value, type, addr = eval_preserve(v[2], v[3], v[4], ...)
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
      cases[#cases+1] = { match_value, eval_preserve(v[2], v[3], v[4], ...) }
    end
  end
  -- if no cases matched, return the default (if there is one)
  if #cases == 0 and self[3] then
    return eval_preserve(self[3], self[4], self[5], ...)
  end

  -- only keep the default if we didn't find a match (we might be here if we
  -- did find a match, but earlier match values weren't defined)
  if found_match or not self[3] then
    return case:new{value, cases}
  else
    return case:new{value, cases, eval_preserve(self[3], self[4], self[5], ...)}
  end
end


------------------------------------------------------------------------------

return case

------------------------------------------------------------------------------


