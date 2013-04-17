-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local operator = require("rima.operator")
local core = require("rima.core")


------------------------------------------------------------------------------

min = operator:new_class({}, "min")
min.precedence = 0

function min:__eval(...)
  local a2 = {}
  local m = math.huge
  for _, a in ipairs(self) do
    a = core.eval(a, ...)
    if type(a) == "number" then
      if a < m then
        m = a
      end
    else
      a2[#a2+1] = a
    end
  end
  
  if a2[1] then
    a2[#a2+1] = m
    return min:new(a2)
  else
    return m
  end
end


------------------------------------------------------------------------------

max = operator:new_class({}, "max")
max.precedence = 0

function max:__eval(...)
  local a2 = {}
  local m = -math.huge
  for _, a in ipairs(self) do
    a = core.eval(a, ...)
    if type(a) == "number" then
      if a > m then
        m = a
      end
    else
      a2[#a2+1] = a
    end
  end
  
  if a2[1] then
    a2[#a2+1] = m
    return max:new(a2)
  else
    return m
  end
end


------------------------------------------------------------------------------

return { min = min, max = max }

------------------------------------------------------------------------------

