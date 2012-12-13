-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

--- Yet *another* Lua type system.
--  This one uses the type system described in PiL, and adds a `__typename`
--  field to the metatable with the object's typename and a `__typeinfo` 
--  field that's a set of all the object's and its ancestors' names,
--  and all their metatables.
--  @module rima.lib.object

local error, getmetatable, pairs, setmetatable, rawget, type =
      error, getmetatable, pairs, setmetatable, rawget, type


------------------------------------------------------------------------------

--- typeinfo data for the core Lua types.
local core_type_info =
{
  boolean               = { boolean       = true },
  ["function"]          = { ["function"]  = true },
  ["nil"]               = { ["nil"]       = true },
  number                = { number        = true },
  string                = { string        = true },
  table                 = { table         = true },
  thread                = { thread        = true },
  userdata              = { userdata      = true },
}


------------------------------------------------------------------------------

local object = {}
object.__index = object
object.__typename = "object"
object.__typeinfo = { object = true, [object] = true }


--- Create a new class.
--  Create a subclass of self.  Set `__typename` and `__typeinfo`.
--  `__typeinfo` is copied from self and the new typename and class object
--  are added.
--  @treturn table: the new class
function object:new_class(
  o,                    -- ?table: the new class object
  new_type_name)        -- ?string: the name of the new class
  o = o or {}
  if new_type_name then o.__typename = new_type_name end
  local parent_typeinfo = self.__typeinfo
  o.__typeinfo = { [o.__typename] = true, [o] = true }
  if self.__typeinfo then
    for k, v in pairs(self.__typeinfo) do
      o.__typeinfo[k] = v
    end
  end
  o.__index = o
  return setmetatable(o, self)
end


--- Create a new object.
--  All the heavy lifting was done in @{rima.lib.object.object:new_class}, so just
--  set the new object's metatable.
--  @treturn table: the new object
function object:new(
  o)                    -- ?table: the table to turn into the class
  return setmetatable(o or {}, self)
end


--- Get a value's typeinfo.
--  if a value `v` is of type `T` then
--  `object.typeinfo(v).T == true`.
--  This works for the core Lua types.
--  @treturn table: typeinfo about the value
function object.typeinfo(
  v)                    -- ?anything: the value to get typeinfo for
  local mt = getmetatable(v)
  return mt and mt.__typeinfo or core_type_info[type(v)]
end


--- Return a value's typname.
--  This works for the core Lua types.
--  @treturn string: the typename of the value
function object.typename(
  v)                    -- ?anything: the value to get typeinfo for
  local mt = getmetatable(v)
  return mt and mt.__typename or type(v)
end


------------------------------------------------------------------------------

return object

------------------------------------------------------------------------------

