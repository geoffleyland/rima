-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local proxy = require("rima.lib.proxy")
local object = require("rima.lib.object")


------------------------------------------------------------------------------

return function(T)
  local my_type = object:new_class({}, "my_type")

  local p = proxy:new({}, my_type)
  T:test(object.typeinfo(p).my_type, "typeinfo(p).my_type")
  T:check_equal(object.typename(p), "my_type", "typename(proxy) == 'my_type'")
  
  local o = {}
  local p = proxy:new(o, my_type)
  T:check_equal(proxy.O(p), o)
  T:check_equal(proxy.O(o), o)
end


------------------------------------------------------------------------------

