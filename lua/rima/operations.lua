-- Copyright (c) 2013 Incremental IP Limited
-- see LICENSE for license information

------------------------------------------------------------------------------
-- The operators are lazy loaded to avoid a require conflict between
-- the operators themselves (some of which use this module) and this module
-- (which requires the operators).
-- It would be nice if there was a better workaround.

local op_modules = setmetatable({},
  {
    __index = function(t, k)
        t[k] = require("rima.operators."..k)
        return t[k]
      end
  })


------------------------------------------------------------------------------

local ops = {}


function ops.add(...)
  local t = {}
  for i = 1, select("#", ...) do
    t[i] = { 1, (select(i, ...)) }
  end
  return op_modules.add:new(t)
end


function ops.sub(a, b)
  return op_modules.add:new{{ 1, a }, { -1, b }}
end


function ops.unm(a)
  return op_modules.add:new{{ -1, a }}
end


function ops.mul(...)
  local t = {}
  for i = 1, select("#", ...) do
    t[i] = { 1, (select(i, ...)) }
  end
  return op_modules.mul:new(t)
end


function ops.div(a, b)
  return op_modules.mul:new{{ 1, a }, { -1, b }}
end


function ops.pow(a, b)
  return op_modules.pow:new{ a, b }
end


function ops.mod(a, b)
  return op_modules.mod:new{ a, b }
end


------------------------------------------------------------------------------

return ops

------------------------------------------------------------------------------

