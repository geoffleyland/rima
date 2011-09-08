-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local error, type = error, type

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local element = require("rima.sets.element")
local expression = require("rima.expression")

module(...)


-- Ord -------------------------------------------------------------------------

ord_op = expression:new_type({}, "ord")


function ord_op.__eval(args_in, S)
  local args = proxy.O(args_in)
  local e = core.eval(args[1], S)

  if object.typeinfo(e).element then
    return element.key(e)
  else
    if core.defined(e) then
      error("ord can only be applied to elements")
    else
      if e == args[1] then
        return args_in
      else
        return expression:new(ord_op, e)
      end
    end
  end
end


-- Ranges ----------------------------------------------------------------------

local range_type = object:new_class({}, "range_type")
function range_type:new(l, h)
  return object.new(self, { low = l, high = h} )
end


function range_type:__repr(format)
  return ("range(%s, %s)"):format(lib.repr(self.low, format), lib.repr(self.high, format))
end
range_type.__tostring = lib.__tostring


local function range_type_iter(high, i)
  i = i + 1
  if i <= high then return i end
end

function range_type:__iterate()
  -- Cast self.high to a number by adding zero
  return range_type_iter, self.high+0, self.low-1
end


function range_type:__iterindex(i)
  if i < 1 or 1 > self.high - self.low then
    error(("index out of range trying to index '%s' with '%s'"):format(lib.repr(self), lib.repr(i)))
  end
  return self.low + i - 1
end


range_op = expression:new_type({}, "range")
function range_op.__eval(args_in, S)
  local args = proxy.O(args_in)

  local l, h = core.eval(args[1], S), core.eval(args[2], S)
  
  if core.defined(l) and core.defined(h) then
    return range_type:new(l, h)
  else
    if l == args[1] and h == args[2] then
      return args_in
    else
      return expression:new(range_op, l, h)
    end
  end
end


-- EOF -------------------------------------------------------------------------

