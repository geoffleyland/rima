-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

--- Store the address pointed to by an index.
--  An address is an array of keys by which to index tables.  For example,
--  to index `base.a.b.c`, then the address will be `{ "a", "b", "c" }`.
--  @module rima.address

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local element = require("rima.sets.element")

local typeinfo = object.typeinfo


------------------------------------------------------------------------------

local function is_local_string(v)
  return type(v) == "string" and v:sub(1, 1) == "$"
end


------------------------------------------------------------------------------

local address = object:new_class({}, "address")


function address:append(...)
  local l = #self

  for i = 1, select("#", ...) do
    local e = select(i, ...)

    if typeinfo(e).address then
      for _, v in ipairs(e) do
        l = l + 1
        self[l] = v
      end
    elseif e then
      l = l + 1
      self[l] = e
    end
  end
end


function address:new(...)
  local a = object.new(self, {})
  a:append(...)
  return a
end


function address:is_identifier()
  return self[1] and not self[2] and lib.is_identifier_string(self[1])
end


------------------------------------------------------------------------------

--- Get a part of an address.
--  @treturn address: a new address containing the elements [i, j] of `self`.
function address:sub(
  i,                    -- integer: where to start the sub-address.  If
                        -- negative, `i` counts back from the end of the
                        -- address (-1 is the end).  If absent `i` is assumed
                        -- to be 1.
  j)                    -- integer: where to end the sub-address.  If
                        -- negative, `j` counts back from the end of the
                        -- address (-1 is the end).  If absent `j` is assumed
                        -- to be -1.
  local length = #self
  i = i or 1
  j = j or length
  if i < 0 then i = length + i + 1 end
  if j < 0 then j = length + j + 1 end

  local a = {}
  for k = i, j do
    a[k - i + 1] = self[k]
  end
  return object.new(address, a)
end


------------------------------------------------------------------------------

function address.__add(a, b)
  return address:new(a, b)
end


function address:value(i)
  if i < 0 then i = #self + i + 1 end
  return self[i]
end


function address:set(i, v)
  self[i] = v
end


------------------------------------------------------------------------------

local function avnext(a, i)
  i = i + 1
  local v = a[i]
  if v then
    return i, v
  end
end

function address:values()
  return avnext, self, 0
end


------------------------------------------------------------------------------

address.__tostring = lib.__tostring
function address:__repr(format)
  local ff = format.format

  if ff == "dump" then
    return ("address{%s}"):format(lib.concat_repr(self, format))
  end

  if not self[1] then return "?" end
  local append, repr = lib.append, lib.repr
  local r = {}
  
  if ff == "latex" then
    local i = 1
    for _, a in ipairs(self) do
      if typeinfo(a).element then
        a = element.display(a)
      end
      if not is_local_string(a) then
        if i == 2 then
          append(r, "_{")
        elseif i > 2 then
          append(r, ",")
        end
        append(r, lib.repr(a, format))
        i = i + 1
      end
    end
    if #self > 1 then append(r, "}") end
  else
    local lua_format = ff == "lua"
    local mode = "s"

    for _, a in ipairs(self) do
      local t = typeinfo(a)
      if t.element then
        a = element.display(a)
      end
      if is_local_string(a) then
        -- Ignore it!
      elseif lib.is_identifier_string(a) then
        -- for strings that can be identifiers, format as a.b
        if mode ~= "s" then
          mode = "s"
          append(r, "]")
        end
        -- the first index doesn't get a dot - it's the name
        if r[1] or format.continued_address then append(r, ".") end
        append(r, repr(a, format))
      else
        -- otherwise format with square braces
        if mode ~= "v" then
          mode = "v"
          append(r, "[")
        else
          -- lua-readable format is [x][y], otherwise it's [x, y]
          append(r, (lua_format and "][") or ", ")
        end
        if t.string then
          -- non-identifier strings are ['1 str.ing']
          append(r, ("%q"):format(a))
        else
          append(r, repr(a, format))
        end
      end
    end
    if mode == "v" then append(r, "]") end
  end

  return table.concat(r)
end


------------------------------------------------------------------------------

function address:__eq(b)
  for i, a in ipairs(self) do
    if b[i] ~= a then return end
  end
  return true
end


------------------------------------------------------------------------------

function address:__eval(...)
  local new_address

  local length = #self
  for i = 1, length do
    local a = self[i]
    local b = core.eval(a, ...)
    if b ~= a then
      new_address = new_address or {}
      new_address[i] = b
    end
  end

  if new_address then
    for i = 1, length do
      new_address[i] = new_address[i] or self[i]
    end
  end

  if new_address then
    return object.new(address, new_address), true
  else
    return self
  end
end


function address:__defined()
  for _, a in ipairs(self) do
    if not core.defined(a) then
      return false
    end
  end
  return true
end


------------------------------------------------------------------------------

return address

------------------------------------------------------------------------------

