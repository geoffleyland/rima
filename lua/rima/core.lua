-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local getmetatable, type = getmetatable, type

local lib = require("rima.lib")
local trace = require("rima.lib.trace")
local object = require("rima.lib.object")

local typeinfo = object.typeinfo

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
  if trace.on then trace.enter("eval", 1, nil, e) end
  local value, type, addr = eval_to_paths(e, S, 1)
  local f = lib.getmetamethod(value, "__finish")
  if f then
    value, type, addr = f(value)
  end
  if typeinfo(value).undefined_t then
    type = value
    value = nil
  end
  value = value or addr
  if trace.on then trace.leave("eval", 1, e, value, type, addr) end
  return value, type, addr
end


function eval_to_paths(e, s, d)
  local f = lib.getmetamethod(e, "__eval")
  if trace.on then trace.enter("evtp", d and d+1, f, e) end
  local value, type, addr
  if f then
    value, type, addr = f(e, s)
  else
    value = e
  end
  value = value or addr
  if trace.on then trace.leave("evtp", 1, e, value, type, addr) end
  return value, type, addr
end


-- Automatic differentiation ---------------------------------------------------

-- differentiate e with respect to v
function diff(e, v)
  local f = lib.getmetamethod(e, "__diff")
  if trace.on then trace.enter("diff", d and d+1, f, e, v) end
  local dedv
  if f then
    dedv = f(e, v)
  elseif type(e) == "number" then
    dedv = 0
  else
    error(("Can't differentiate %s with respect to %s"):format(lib.repr(e), lib.repr(v)))
  end
  if trace.on then trace.leave("diff", 1, e, v, dedv) end
  return dedv
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

