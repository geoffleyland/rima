-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local getfenv = getfenv
local select, unpack = select, unpack

module(...)
local rima = getfenv(0).rima

-- Private functionality -------------------------------------------------------

function rima.packn(...)
  return { n=select("#", ...), ... }
end

function rima.packs(status, ...)
  return status, { n=select("#", ...), ... }
end

function rima.unpackn(t)
  return unpack(t, 1, t.n)
end


-- EOF -------------------------------------------------------------------------

