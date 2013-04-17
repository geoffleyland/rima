-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local operator = require("rima.operator")
local lib = require("rima.lib")
local core = require("rima.core")
local element = require("rima.sets.element")


------------------------------------------------------------------------------

local ord = operator:new_class({}, "ord")


function ord:__eval(...)
  local e = core.eval(self[1], ...)

  if object.typeinfo(e).element then
    return element.key(e)
  else
    if core.defined(e) then
      error("ord can only be applied to elements")
    else
      if e == self[1] then
        return self
      else
        return ord:new{e}
      end
    end
  end
end


------------------------------------------------------------------------------

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
  if i < 1 or i > self.high - self.low + 1 then
    error(("index out of range trying to index '%s' with '%s'"):format(lib.repr(self), lib.repr(i)))
  end
  return self.low + i - 1
end


local range = operator:new_class({}, "range")


function range:__eval(...)

  local l, h = core.eval(self[1], ...), core.eval(self[2], ...)
  
  if core.defined(l) and core.defined(h) then
    return range_type:new(l, h)
  else
    if l == self[1] and h == self[2] then
      return self
    else
      return range:new{l, h}
    end
  end
end


------------------------------------------------------------------------------

return { ord = ord, range = range }

------------------------------------------------------------------------------

