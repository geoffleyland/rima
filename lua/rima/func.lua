-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local error, ipairs, require, type = error, ipairs, require, type

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local index = require("rima.index")

module(...)


-- Function type ---------------------------------------------------------------

local func = object:new_class(_M, "func")
local counter = 1


local function read(args)
  local new_args = {}
  for i, v in ipairs(args) do
    if type(v) == "string" then
      new_args[i] = v
    elseif object.typeinfo(v).index then
      if index:is_identifier(v) then
        new_args[i] = lib.repr(v)
      else
        error(("bad input #%d to function constructor: expected string or identifier, got '%s' (%s)"):
          format(i, lib.repr(v), typename(v)), 0)
      end
    else
      error(("bad input #%d to function constructor: expected string or identifier, got '%s' (%s)"):
        format(i, lib.repr(v), typename(v)), 0)
    end
  end
  return new_args
end


local function prepare(exp, name, args)
  if args[1] then
    local S2 = scope.new()
    for i, a in ipairs(args) do
      S2[a] = index:new(nil, name, a)
    end
    exp = core.eval(exp, S2)
  end
  return exp
end


function func:new(args, exp, S)
  local name = "$func"..counter
  counter = counter + 1
  args = read(args)

  if S then exp = core.eval(exp, S) end

  return object.new(self, { name=name, args=args, exp=prepare(exp, name, args) })
end


-- String representation -------------------------------------------------------

function func:__repr(format)
  return ("function(%s) return %s"):
    format(lib.concat_repr(self.args, format), lib.repr(self.exp, format))
end
__tostring = lib.__tostring


-- Evaluation ------------------------------------------------------------------


function func:call(args, S)
  if not args then return self end
  S = (S and not self.args[1]) and S or scope.new(S)
  local Sn = S[self.name]

  local new_args = {}
  for i, n in ipairs(self.args) do
    local a = args[i]
    if a then
      Sn[n] = a
    else
      Sn[n] = index:new(nil, n)
      new_args[#new_args+1] = n
    end
  end

  local exp = core.eval_to_paths(self.exp, S)
  return new_args[1] and func:new(new_args, exp) or exp
end


function func:__call(...)
  return self:call{...}
end


-- EOF -------------------------------------------------------------------------

