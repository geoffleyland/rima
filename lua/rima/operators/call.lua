-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error, ipairs, unpack, pcall = error, ipairs, unpack, pcall

local object = require("rima.object")
local scope = require("rima.scope")
local ref = require("rima.ref")
local expression = require("rima.expression")
require("rima.private")
local rima = rima

module(...)

-- Addition --------------------------------------------------------------------

local call = object:new(_M, "call")


-- Argument Checking -----------------------------------------------------------

function call:check(args)
end


-- String Representation -------------------------------------------------------

function call:_tostring(args)
  local s = expression.parenthise(args[1], 0).."("
  for i = 2, #args do
    if i > 2 then s = s..", " end
    s = s..rima.tostring(args[i])
  end
  return s..")"
end


-- Evaluation ------------------------------------------------------------------

function call:eval(S, args)
  local e = expression.eval(args[1], S)
  if isa(e, ref) or isa(e, expression) then
    return expression:new(call, e, unpack(args, 2))
  else
    local status, r
    if type(e) == "function" then
      for i, a in ipairs(args) do
        args[i] = expression.eval(a, S)
      end
      status, r = pcall(function() return e(unpack(args, 2)) end)
    else
      status, r = pcall(function() return e:call(S, {unpack(args, 2)}) end)
    end

    if not status then
      error(("error while evaluating '%s':\n  %s"):
        format(self:_tostring(args), r:gsub("\n", "\n  ")), 0)
    end
    return r
  end
end


-- EOF -------------------------------------------------------------------------

