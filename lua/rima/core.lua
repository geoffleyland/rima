-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local getmetatable, type = getmetatable, type

local lib = require("rima.lib")
local trace = require("rima.lib.trace")
local undefined_t = require("rima.types.undefined_t")

module(...)


-- Is an expression defined? ---------------------------------------------------

function defined(e)
  local f = lib.getmetamethod(e, "__defined")
  if trace.on then trace.enter("defd", 1, f, e) end
  local d

  if f then
    d = f(e)
  else
    d = not lib.getmetamethod(e, "__eval")
  end
  if trace.on then trace.leave("defd", 1, e, d) end
  return d
end


-- Is an expression arithmetic? (Can you add it?) ------------------------------

function arithmetic(e)
  if trace.on then trace.enter("arth", 1, nil, e) end
  local result

  if type(e) == "number" then
    result = true
  else
    local mt = getmetatable(e)
    if not mt then
      result = false
    else
      local f
      f = mt.__arithmetic
      if f then
        result = f(e)
      else
        f = mt.__defined
        if f then
          result = f(e)
        elseif mt.__eval then 
          result = false
        else
          result = mt.__add and true
        end
      end
    end
  end
  if trace.on then trace.leave("arth", 1, e, result) end
  return result
end


-- Evaluation ------------------------------------------------------------------

function eval(e, S)
  local value, exp = eval_to_paths(e, S, 1)
  local f = lib.getmetamethod(value, "__finish")
  if f then
    value = f(value)
  end
  if value and not undefined_t:isa(value) then
    return value
  else
    return exp
  end
end


function eval_to_paths(e, s, d)
  local f = lib.getmetamethod(e, "__eval")
  if trace.on then trace.enter("eval", d and d+1, f, e) end
  local value, exp
  if f then
    value, exp = f(e, s)
  else
    value = e
  end
  if trace.on then trace.leave("eval", 1, e, value, exp) end
  return value, exp
end


-- Listing variables -----------------------------------------------------------

function list_variables(e, S, list)
  list = list or {}
  local f = lib.getmetamethod(e, "__list_variables")
  if f then f(e, S, list) end
  return list
end


-- Pretty strings --------------------------------------------------------------

function parenthise(e, format, parent_precedence)
  parent_precedence = parent_precedence or 1
  local s = lib.repr(e, format)
  local precedence = lib.getmetamethod(e, "precedence") or 0
  if precedence > parent_precedence then
    s = "("..s..")"
  end
  return s
end


-- EOF -------------------------------------------------------------------------

