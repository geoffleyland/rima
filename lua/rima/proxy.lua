-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local getmetatable, setmetatable = getmetatable, setmetatable

module(...)

-- Types -----------------------------------------------------------------------

local proxy = _M
proxy._typename = "proxy"
local objects = setmetatable({}, { __mode = "k" })
local proxies = setmetatable({}, { __mode = "v" })

function proxy:new(o, metatable, typename)
  metatable = metatable or {}
  metatable.__is_proxy = true
  if typename then metatable.__typename = typename end
  local proxy = setmetatable({}, metatable)
  objects[proxy] = o
  proxies[o] = proxy
  return proxy
end


function proxy.O(p)
  return objects[p] or p
end


function proxy.P(o)
  return proxies[o] or o
end


-- EOF -------------------------------------------------------------------------

