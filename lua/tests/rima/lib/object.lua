-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")


------------------------------------------------------------------------------

return function(T)
  local o = object:new()
  T:test(object.typeinfo(o).object, "typeinfo(o).object")
  T:check_equal(object.typename(o), "object", "typename(object) == 'object'")

  local subobj = object:new_class(nil, "subobj")
  T:check_equal(object.typename(subobj), "object", "typename(subobj) == 'object'")
  local s = subobj:new()
  T:check_equal(object.typename(s), "subobj", "typename(s) == 'subobj'")
  T:test(object.typeinfo(s).object, "typeinfo(s).object")
  T:test(object.typeinfo(s).subobj, "typeinfo(s).subobj")
  T:test(not object.typeinfo(s).table, "not typeinfo(s).table")

  T:test(not object.typeinfo({}).object, "not typeinfo({}).object")
  T:test(not object.typeinfo({}).subobj, "not typeinfo({}).suboj")
  T:test(not object.typeinfo(o).subobj, "not typeinfo(object:new()).subobj")

  T:check_equal(object.typename(s), "subobj", "typename(s) == 'subobj'")
  T:check_equal(object.typename(1), "number", "typename(1) == 'number'")
end


------------------------------------------------------------------------------

