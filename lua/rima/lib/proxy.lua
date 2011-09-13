-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local setmetatable = setmetatable

module(...)


-- Types -----------------------------------------------------------------------

local proxy = _M
local objects = setmetatable({}, { __mode = "k" })


function proxy:new(o, class)
  local p = setmetatable({}, class)
  objects[p] = o
  return p
end


function proxy.O(p)
  return objects[p] or p
end


-- EOF -------------------------------------------------------------------------

