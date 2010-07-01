-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local lib = require("rima.lib")

module(...)


-- Is an expression defined? ---------------------------------------------------

function defined(e)
  local f = lib.getmetamethod(e, "__defined")
  if f then return f(e) end
  return not lib.getmetamethod(e, "__eval")
end


-- EOF -------------------------------------------------------------------------

