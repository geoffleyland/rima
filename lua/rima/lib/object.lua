-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local error, getmetatable, pairs, setmetatable, rawget, type =
      error, getmetatable, pairs, setmetatable, rawget, type

module(...)


-- Types -----------------------------------------------------------------------

local object = _M
object.__index = object
object.__typename = "object"
object.__typeinfo = { object = true, [object] = true }


function object:new_class(o, new_type_name)
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


function object:new(o)
  return setmetatable(o or {}, self)
end


local core_type_info =
{
  boolean = { boolean = true },
  ["function"] = { ["function"] = true },
  ["nil"] = { ["nil"] = true },
  number = { number = true },
  string = { string = true },
  table = { table = true },
  thread = { thread = true },
  userdata = { userdata = true },
}


function object.typeinfo(o)
  local mt = getmetatable(o)
  return mt and mt.__typeinfo or core_type_info[type(o)]
end


function object.isa(t, o)
  local mt = getmetatable(o)
  return (mt and mt.__typeinfo or core_type_info[type(o)])[t]
end


function object.typename(o)
  local mt = getmetatable(o)
  return mt and mt.__typename or type(o)
end


-- EOF -------------------------------------------------------------------------

