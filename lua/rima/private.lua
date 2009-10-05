-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local table = require("table")
local getfenv, ipairs = getfenv, ipairs

module(...)
local rima = getfenv(0).rima

-- Private functionality -------------------------------------------------------

function rima.imap(f, t)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end


function rima.concat(t, s, f)
  if f then return table.concat(rima.imap(f, t), s)
  else return table.concat(t, s)
  end
end


-- EOF -------------------------------------------------------------------------

