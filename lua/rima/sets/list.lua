-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local coroutine, table = require("coroutine"), require("table")
local error, ipairs, pairs, pcall =
      error, ipairs, pairs, pcall

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local set_ref = require("rima.sets.ref")
local scope = require("rima.scope")

module(...)


-- Set list --------------------------------------------------------------------

list = object:new(_M, "sets.list")


function list:new(l)
  l = l or {}
  return object.new(self, l)
end


function list:copy(sets)
  local new_list = {}
  for i, s in ipairs(sets) do new_list[i] = s end
  return list:new(new_list)
end


function list:read(sets)
  if not sets then return object.new(self, {}) end

  local sorted_sets = {}

  for k, s in pairs(sets) do
    local status, seq = pcall(function()
      if type(k) == "number" then
        return set_ref:read(s)
      else
        return set_ref:read({[k]=s})
      end
    end)
    if not status then
      error(("error: sets.list:read: didn't understand set argument %s.  %s")
        :format(lib.repr(k), seq))
    end
    sorted_sets[#sorted_sets+1] = { k, seq }
  end

  -- sort the sets - numbered entries first, in numerical order,
  -- and then string keys in alphabetical order
  table.sort(sorted_sets, function(a, b)
    a, b = a[1], b[1]
    if type(a) == "number" then
      return (type(b) ~= "number" and true) or a < b 
    else
      return (type(b) ~= "number" and a < b) or false
    end
  end)

  local result = {}
  for i, v in ipairs(sorted_sets) do result[i] = v[2] end
  return list:new(result)
end


function list:append(s)
  local status, message = pcall(function()
    self[#self+1] = set_ref:read(s)
    end)
  if not status then
    error(("error: sets.list:append: didn't understand set.  %s") :format(message))
  end
end


function list:__repr(format)
  return "{"..lib.concat_repr(self, format).."}"
end
list.__tostring = lib.__tostring


-- Iteration -------------------------------------------------------------------

-- It seems we need a new scope for every iteration because bind might
-- be used, and any indexes might need to be remembered for a later evaluation
-- bind is evil.

function list:iterate(S)
  local undefined_sets = {}

  local function z(i, cS)
    i = i or 1
    cS = cS or S
    if not self[i] then
      local ud
      if undefined_sets[1] then ud = list:copy(undefined_sets) end
      coroutine.yield(cS, ud)
    else
      local it = core.eval(self[i], cS)
      if core.defined(it) then
        for _, nS in it:iterate(cS) do
          z(i+1, nS)
        end
      else
        local nS = scope.spawn(cS, nil, {overwrite=true, no_undefined=true})
        undefined_sets[#undefined_sets+1] = it
        for _, n in ipairs(it.names) do
          scope.hide(nS, n)
        end
        z(i+1, nS)
        undefined_sets[#undefined_sets] = nil
      end
    end
  end

  return coroutine.wrap(z)
end


-- EOF -------------------------------------------------------------------------

