-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local getmetatable, setmetatable = getmetatable, setmetatable

module(...)

-- Types -----------------------------------------------------------------------

local proxy = _M
local objects = setmetatable({}, { __mode = "k" })

function proxy:new(o, class)
  local proxy = setmetatable({}, class)
  objects[proxy] = o
  return proxy
end


function proxy.O(p)
  return objects[p] or p
end


-- EOF -------------------------------------------------------------------------

