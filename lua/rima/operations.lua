-- Copyright (c) 2013 Incremental IP Limited
-- see LICENSE for license information

local expression = require("rima.expression")

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
  return expression:new_table(op_modules.add, t)
end


function ops.sub(a, b)
  return expression:new(op_modules.add, { 1, a }, { -1, b })
end


function ops.unm(a)
  return expression:new(op_modules.add, { -1, a })
end


function ops.mul(...)
  local t = {}
  for i = 1, select("#", ...) do
    t[i] = { 1, (select(i, ...)) }
  end
  return expression:new_table(op_modules.mul, t)
end


function ops.div(a, b)
  return expression:new(op_modules.mul, { 1, a }, { -1, b })
end


function ops.pow(a, b)
  return expression:new(op_modules.pow, a, b)
end


function ops.mod(a, b)
  return expression:new(op_modules.mod, a, b)
end


------------------------------------------------------------------------------

return ops

------------------------------------------------------------------------------

