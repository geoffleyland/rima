-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local error, ipairs, select, type =
      error, ipairs, select, type

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local element = require("rima.sets.element")

local typeinfo = object.typeinfo

module(...)


-- Utilities -------------------------------------------------------------------

local function is_local_string(v)
  return type(v) == "string" and v:sub(1, 1) == "$"
end


-- Constructor -----------------------------------------------------------------

local address = object:new_class(_M, "address")


local function add_element(a, v)
  a[#a+1] = v
end


function address:append(...)
  for i = 1, select("#", ...) do
    local e = select(i, ...)

    if typeinfo(e).address then
      for i, v in ipairs(e) do
        add_element(self, v)
      end
    elseif e then
      add_element(self, e)
    end
  end
end


function address:new(...)
  local a = object.new(self, {})
  a:append(...)
  return a
end


function address:starts_with_identifier()
  return lib.is_identifier_string(self[1])
end


function address:is_identifier()
  return #self == 1 and lib.is_identifier_string(self[1])
end


-- Substrings ------------------------------------------------------------------

function address:sub(i, j)
  local length = #self
  i = i or 1
  j = j or length
  if i < 0 then i = length + i + 1 end
  if j < 0 then j = length + j + 1 end

  local a = {}
  for k = i, j do
    add_element(a, self[k])
  end
  return object.new(address, a)
end


-- Appending -------------------------------------------------------------------

function address.__add(a, b)
  return address:new(a, b)
end


-- Element access --------------------------------------------------------------

function address:value(i)
  if i < 0 then i = #self + i + 1 end
  return self[i]
end


-- Modifying -------------------------------------------------------------------

function address:set(i, v)
  self[i] = v
end


-- Iterating -------------------------------------------------------------------

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


-- string representation -------------------------------------------------------

function address:__repr(format)
  local ff = format.format

  if ff == "dump" then
    return ("address{%s}"):format(lib.concat_repr(self, format))
  end

  if not self[1] then return "" end
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
        local s = lib.repr(a, format)
          append(r, s)
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
          -- lua-readable format is [x][y], otherwise it's [x, y] for mathematicans
          append(r, (lua_format and "][") or ", ")
        end
        if t.string then
          -- non-identifier strings are ['1 str.ing']
          append(r, "'", a, "'")
        else
          append(r, repr(a, format))
        end
      end
    end
    if mode == "v" then append(r, "]") end
  end

  return lib.concat(r)
end
__tostring = lib.__tostring


-- equality --------------------------------------------------------------------

function address:__eq(b)
  for i, a in ipairs(self) do
    if b[i] ~= a then return end
  end
  return true
end


-- evaluation ------------------------------------------------------------------

function address:__eval(S)
  local new_address
  for i, a in ipairs(self) do
    local a2 = core.eval(a, S)
    if not new_address and a2 ~= a then
      new_address = {}
      for j = 1, i-1 do new_address[j] = self[j] end
    end
    if new_address then
      if a2 == a then
        new_address[i] = a
      else
        new_address[i] = a2
      end
    end
  end
  if new_address then
    return object.new(address, new_address)
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


-- EOF -------------------------------------------------------------------------

