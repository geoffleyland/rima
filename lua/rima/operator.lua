-- Copyright (c) 2013 Incremental IP Limited
-- see LICENSE for license information

local object = require"rima.lib.object"
local lib = require"rima.lib"
local core = require"rima.core"


------------------------------------------------------------------------------

local operator = object:new_class({}, "operator")
local ops = {}

function operator:new_class(...)
  local op = object.new_class(self, ...)
  op.__tostring = lib.__tostring
  return op
end


------------------------------------------------------------------------------

function operator:new(t)
  t = object.new(self, t)
  if self.simplify then t = self.simplify(t) end
  return t
end


------------------------------------------------------------------------------

function operator.__repr(self, format)
  return object.typename(self).."("..lib.concat_repr(self, format)..")"
end

function operator:__list_variables(S, list)
  for i = 1, #self do
    core.list_variables(self[i], S, list)
  end
end


------------------------------------------------------------------------------

function operator:evaluate_terms(...)
  local new_terms
  local term_count = #self
  for i = 1, term_count do
    local e = core.eval(self[i], ...)
    if e ~= self[i] then
      new_terms = new_terms or {}
      new_terms[i] = e
    end
  end
  if new_terms then
    for i = 1, term_count do
      new_terms[i] = new_terms[i] or self[i]
    end
  end

  return new_terms
end


------------------------------------------------------------------------------

return operator

------------------------------------------------------------------------------

