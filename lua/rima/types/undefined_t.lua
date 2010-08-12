-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local lib = require("rima.lib")

module(...)


-- Undefined (base) Type -------------------------------------------------------

local undefined_t = object:new(_M, "undefined_t")


-- String representation -------------------------------------------------------

function undefined_t:__repr(format)
  return "undefined"
end
__tostring = lib.__tostring


function undefined_t:describe(s)
  return ("%s undefined"):format(s)
end


function undefined_t:includes(v, env)
  return true
end


-- EOF -------------------------------------------------------------------------

