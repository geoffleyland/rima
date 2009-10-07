-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local ipairs, require = ipairs, require

local object = require("rima.object")
require("rima.private")
local rima = rima

module(...)

local expression = require("rima.expression")
--------------------------------------------------------------------------------

local address = object:new(_M, "address")


-- string representation -------------------------------------------------------

function address:__repr(format)
  if not self[1] then
    return ""
  else
    if format and format.dump then
      return ("[%s]"):format(expression.concat(self, format))
    else
      local mode = "s"
      local count = 0
      local s = ""
      for _, a in ipairs(self) do
        if type(a) == "string" then
          if mode ~= "s" then
            mode = "s"
            s = s.."]"
          end
          s = s.."."..rima.repr(a, format)
        else
          if mode ~= "v" then
            mode = "v"
            s = s.."["
            count = 0
          end
          if count > 0 then
            s = s..", "
          end
          count = count + 1
          s = s..rima.repr(a, format)
        end
      end
      if mode == "v" then s = s.."]" end
      return s
    end
  end
end
__tostring = __repr


-- lengthening and shortening --------------------------------------------------

function address.__add(a, b)
  local z = {}
  if object.isa(a, address) then
    for i, a in ipairs(a) do
      z[i] = a
    end
  else
    z[1] = a
  end
  if object.isa(b, address) then
    for _, a in ipairs(b) do
      z[#z+1] = a
    end
  else
    z[#z+1] = b
  end
  return address:new(z)
end


function address:sub(i, j)
  local l = #self
  i = i or 1
  j = j or l
  if i < 0 then i = l + i + 1 end
  if j < 0 then j = l + j + 1 end

  local z = {}
  for k = i, j do
    z[#z+1] = self[k]
  end
  return address:new(z)
end


-- evaluation ------------------------------------------------------------------

function address:__eval(S, eval)
  return address:new(rima.imap(function(a) return eval(a, S) end, self))
end


-- EOF -------------------------------------------------------------------------
