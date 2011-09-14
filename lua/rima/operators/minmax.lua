-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local ipairs, type = ipairs, type

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local core = require("rima.core")
local expression = require("rima.expression")

module(...)


-- Min -------------------------------------------------------------------------

min = expression:new_type({}, "min")
min.precedence = 0

function min.__eval(args, S)
  args = proxy.O(args)
  local a2 = {}
  local m = math.huge
  for _, a in ipairs(args) do
    a = core.eval(a, S)
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
    return expression:new_table(min, a2)
  else
    return m
  end
end


function build_min(...)
  return expression:new(min, ...)
end


-- Max -------------------------------------------------------------------------

max = expression:new_type({}, "max")
max.precedence = 0

function max.__eval(args, S)
  args = proxy.O(args)
  local a2 = {}
  local m = -math.huge
  for _, a in ipairs(args) do
    a = core.eval(a, S)
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
    return expression:new_table(max, a2)
  else
    return m
  end
end


function build_max(...)
  return expression:new(max, ...)
end


-- EOF -------------------------------------------------------------------------

