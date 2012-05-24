-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local setmetatable = setmetatable

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")

local typeinfo = object.typeinfo

module(...)


-- Elements -------------------------------------------------------------------

element = object:new_class(_M, "element")
local elements = setmetatable({}, { __mode="k" })

function element:new(exp, key, value)
  local e = { exp=exp, key=key, value=value }
  local p = object.new(element, {})
  elements[p] = e
  return p
end


function element:key() return elements[self].key end
function element:value() return elements[self].value end
function element:expression() return elements[self].exp end

function element:display()
  self = elements[self]
  local v = self.value
  if v then
    local t = typeinfo(v)
    if not t.undefined_t and not t.table then
      return v
    end
  end
  return self.key
end


function element:__eval(S)
  local s = elements[self]
  if s.value then return self end

  local value, _, exp = core.eval(s.exp, S)
  if value == s.value and lib.repr(exp) == lib.repr(s.exp) then
    return self
  end

  value = core.defined(value) and value or nil
  return element:new(exp or s.exp, s.key, value)
end


function element:__defined()
  return elements[self].value ~= nil
end


function element:__arithmetic()
  return core.arithmetic(elements[self].value)
end


function element:__repr(format)
  self = elements[self]
  if format.format == "dump" then
    return ("element(%s, key=%s, value=%s)"):
      format(lib.repr(self.exp, format), lib.repr(self.key, format), lib.repr(self.value, format))
  else
    if core.arithmetic(self.value) then
      return lib.repr(self.value, format)
    else
      return lib.repr(self.exp, format)
    end
  end
end
element.__tostring = lib.__tostring


-- Operators -------------------------------------------------------------------

function element:extract()
  self = elements[self]
  local v = self.value
  if not v or typeinfo(v).undefined_t then
    return self.exp
  else
    return v
  end
end


local function ex(a)
  return lib.convert(a, "extract")
end


function element.__add(a, b) return ex(a) + ex(b) end
function element.__sub(a, b) return ex(a) - ex(b) end
function element.__mul(a, b) return ex(a) * ex(b) end
function element.__div(a, b) return ex(a) / ex(b) end
function element.__pow(a, b) return ex(a) ^ ex(b) end

function element:__unm() return -elements[self].value end
function element:__index(i) return elements[self].exp[i] end


-- EOF -------------------------------------------------------------------------

