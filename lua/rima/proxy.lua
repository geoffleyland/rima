-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local getmetatable, setmetatable = getmetatable, setmetatable

local tests = require("rima.tests")
local object = require("rima.object")

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


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  local mt = {}

  local p = proxy:new({}, mt, "my_type")
  T:test(object.isa(p, mt), "isa(o, mt)")
  T:equal_strings(object.type(p), "my_type", "type(proxy) == 'my_type'")

  return T:close()
end


-- EOF -------------------------------------------------------------------------

