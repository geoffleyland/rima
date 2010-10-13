-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, require = ipairs, require

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")

module(...)

local scope = require("rima.scope")


-- Closures --------------------------------------------------------------------

local closure = object:new(_M, "closure")
local counter = 1

function closure:new(exp, args)
  local name = "$closure"..counter
  counter = counter + 1
  return object.new(closure, { name=name, args=args, exp=args:prepare(exp, name) })
end


function closure:undo(exp, args)
  return args:unprepare(exp, self.name)
end


function closure:__eval(s)
  return core.eval(self.exp, s)
end


function closure:set_args(s, args)
  local eval_scope = scope.new(s)
  local local_scope = eval_scope[self.name]
  local setc = #self.args
  local arg_offset = #args - setc
  for i = 1, setc do
    self.args:set_args(local_scope, i, args[i + arg_offset])
  end
  return eval_scope
end


function closure:iterate(s)
  return self.args:iterate(scope.new(s), self.name)
end


function closure:fake_iterate(s, undefined)
  local sn = scope.new(s)
  local sf = sn[self.name]
  for _, v in ipairs(undefined) do
    v:fake_iterate(sf)
  end
  return sn
end


function closure:__repr(format)
  local ar, er = lib.repr(self.args, format), lib.repr(self.exp, format)
  local ff = format.format
  local f
  if ff == "dump" then
    f = "closure(%s, %s)" return "closure("..ar..", "..er..")"
  elseif ff == "latex" then
    f = "%s %s"
  else
    f = "%s(%s)"
  end
  
  return f:format(ar, er)
end
closure.__tostring = lib.__tostring

-- Introspection? --------------------------------------------------------------

function closure:__list_variables(S, list)
  core.list_variables(self.exp, S, list)
end


-- EOF -------------------------------------------------------------------------

