-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local ipairs = ipairs

local object = require("rima.object")
local expression = require("rima.expression")
require("rima.private")
local rima = rima

module(...)

--------------------------------------------------------------------------------

local address = object:new(_M, "address")


-- string representation -------------------------------------------------------

function address:__repr(format)
  if self[1] then
    return "["..expression.concat(self, format).."]"
  else
    return ""
  end
end


-- evaluation ------------------------------------------------------------------

function address:__eval(S)
  return address:new(rima.imap(function(a) return expression.eval(a, S) end, self))
end


-- lengthening and shortening --------------------------------------------------

function address:__add(b)
  local z = {}
  for i, a in ipairs(self) do
    z[i] = a
  end
  z[#z+1] = b
  return address:new(z)
end


-- EOF -------------------------------------------------------------------------
