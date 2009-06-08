-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local object = require("rima.object")

module(...)

-- Undefined (base) Type -------------------------------------------------------

local undefined_t = object:new(_M, "undefined_t")


-- String representation -------------------------------------------------------

function undefined_t:__tostring()
  return "undefined"
end


function undefined_t:describe(s)
  return ("%s undefined"):format(s)
end


function undefined_t:includes(v, env)
  return true
end


-- EOF -------------------------------------------------------------------------

