-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local coroutine, table = require("coroutine"), require("table")
local error, ipairs, pairs, pcall, require, type =
      error, ipairs, pairs, pcall, require, type

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")

module(...)

local ref = require("rima.sets.ref")
local scope = require("rima.scope")


-- Set list --------------------------------------------------------------------

list = object:new_class(_M, "sets.list")


function list:new(l)
  return object.new(self, l or {})
end


function list.copy(sets)
  local new_list = {}
  for i, s in ipairs(sets) do new_list[i] = s end
  return list:new(new_list)
end


function list:read(sets, count)
  if not sets or count == 0 then return object.new(self, {}) end

  local new_sets = {}
  for i = 1, count do
    local status
    status, message = pcall(function()
        local s = sets[i]
        if s[1] then
          new_sets[i] = ref:read(s[1])
        else
          new_sets[i] = ref:read(s)
        end
      end)
    if not status then
      error(("error: sets.list:read: didn't understand set argument %s.\n  %s")
        :format(lib.repr(sets[i]), message))
    end
  end
  return list:new(new_sets)
end


function list:__add(i)
  new_list = {}
  for j, v in ipairs(self) do new_list[j] = v end
  new_list[#new_list+1] = ref:read(i)
  return list:new(new_list)
end


function list:append(i)
  self[#self+1] = ref:read(i)
end


function list:pop()
  self[#self] = nil
end


function list:__repr(format)
  return "{"..lib.concat_repr(self, format, "}{").."}"
end
list.__tostring = lib.__tostring


-- Prepare an expression for evaluation ----------------------------------------

function list:prepare(e, name)
  local S = scope.new()
  for i, s in ipairs(self) do
    self[i] = core.eval(s, S)
    for _, n in ipairs(s.names) do
      scope.newindex(S, n, index:new(nil, name, n))
    end
  end
  if e then
    return core.eval(e, S)
  end
end


function list:unprepare(e, name)
  local S = scope.new()
  local Sl = scope.index(S, name)
  for i, s in ipairs(self) do
    for _, n in ipairs(s.names) do
      index.newindex(Sl, n, index:new(nil, n))
    end    
  end
  return core.eval(e, S)
end


-- Set a ref in a scope --------------------------------------------------------

function list:set_args(S, Sn, i, a)
  self[i]:index(S, Sn, a)
end


-- Iteration -------------------------------------------------------------------

function list:iterate(S, name)
  local undefined_sets = {}
  local Sn = scope.index(S, name)

  local function z(i)
    i = i or 1
    if not self[i] then
      local ud
      if undefined_sets[1] then ud = list.copy(undefined_sets) end
      coroutine.yield(S, ud)
    else
      local it = core.eval(self[i], S)
      if core.defined(it) then
        for _ in it:iterate(Sn) do
          z(i+1)
        end
      else
        undefined_sets[#undefined_sets+1] = it
        for _, n in ipairs(it.names) do
          index.newindex(Sn, n, nil)
        end
        z(i+1)
        undefined_sets[#undefined_sets] = nil
      end
    end
  end

  return coroutine.wrap(z)
end


-- EOF -------------------------------------------------------------------------

