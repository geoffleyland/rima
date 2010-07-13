-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local coroutine, table = require("coroutine"), require("table")
local error, ipairs, pairs, pcall, rawget =
      error, ipairs, pairs, pcall, rawget

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local sequence = require("rima.iteration.sequence")
local scope = require("rima.scope")

module(...)



-- Set list --------------------------------------------------------------------

list = object:new(_M, "sets.list")

function list:copy(sets)
  local o = {}
  for i, s in ipairs(sets) do o[i] = s end
  return object.new(self, o)
end


function list:new(sets)
  if not sets then return object.new(self, {}) end

  local sorted_sets = {}

  for k, s in pairs(sets) do
    local status, seq = pcall(function()
      if type(k) == "number" then
        return sequence:read(s)
      else
        return sequence:read({[k]=s})
      end
    end)
    if not status then
      error(("error: sets.list:new: didn't understand set argument %s.  %s")
        :format(lib.repr(k), seq))
    end
    sorted_sets[#sorted_sets+1] = { k, seq }
  end

  -- sort the sets - numbered entries first, in numerical order,
  -- and then string keys in alphabetical order
  table.sort(sorted_sets, function(a, b)
    a, b = a[1], b[1]
    if type(a) == "number" then
      if type(b) == "number" then
        return a < b
      else
        return true
      end
    else
      if type(b) == "number" then
        return false
      else
        return a < b
      end
    end
  end)

  local result = {}
  for i, v in ipairs(sorted_sets) do result[i] = v[2] end
  return object.new(self, result)
end


function list:append(s)
  local status, message = pcall(function()
    self[#self+1] = sequence:read(s)
    end)
  if not status then
    error(("error: sets.list:append: didn't understand set.  %s") :format(message))
  end
end


function list:__repr(format)
  return "{"..lib.concat_repr(self, format).."}"
end
list.__tostring = lib.__tostring


function list:iterate(S)
  local undefined_sets = {}

  local function z(i, cS)
    i = i or 1
    cS = cS or S
    if not rawget(self, i) then
      local ud
      if undefined_sets[1] then ud = list:copy(undefined_sets) end
      coroutine.yield(cS, ud)
    else
      local it = self[i]:eval(cS)
      if core.defined(it) then
        local results = it:results()
        for variables in it:iterate() do
          local nS = scope.spawn(cS, nil, {overwrite=true, no_undefined=true})
          results(variables, nS)
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

