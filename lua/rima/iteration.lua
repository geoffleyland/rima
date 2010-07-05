-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error, type = error, type

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local iterator = require("rima.iteration.iterator")
local expression = require("rima.expression")
local rima = rima

module(...)


-- Ord -------------------------------------------------------------------------

ord = object:new({}, "ord")


function ord.__eval(args, S, eval)
  args = proxy.O(args)
  local e = core.bind(args[1], S)
  if iterator:isa(e) and eval ~= core.bind then
    return e.key
  else
    if core.defined(e) then
      error("ord can only be applied to iterators")
    else
      return expression:new(ord, e)
    end
  end
end


function rima.ord(e)
  return expression:new(ord, e)
end


-- Ranges ----------------------------------------------------------------------

local range_type = object:new({}, "range_type")
function range_type:new(l, h)
  return object.new(self, { low = l, high = h} )
end


function range_type:__repr(format)
  return ("range(%s, %s)"):format(lib.repr(self.low, format), lib.repr(self.high, format))
end
range_type.__tostring = lib.__tostring


function range_type:__iterate()
  local function iter(a, e)
    local i = e[1] + 1
    if i <= a.high then
      return { i }
    end
  end
  
  return iter, self, { self.low-1 }
end


local range_op = object:new({}, "range")
function range_op.__eval(args, S, eval)
  args = proxy.O(args)
  local l, h = eval(args[1], S), eval(args[2], S)
  if type(l) == "number" and type(h) == "number" then
    return range_type:new(l, h)
  else
    return expression:new(range_op, l, h)
  end
end


function rima.range(l, h)
  return expression:new(range_op, l, h)
end


-- Top-level sequences ---------------------------------------------------------

function rima.pairs(exp)
  return sequence:new(exp, "", "pairs")
end


function rima.ipairs(exp)
  return sequence:new(exp, "i", "pairs")
end


-- EOF -------------------------------------------------------------------------

