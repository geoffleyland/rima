-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local lib = require("rima.lib")
local trace = require("rima.lib.trace")

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


-- Evaluation ------------------------------------------------------------------

function eval(e, S)
  local f = lib.getmetamethod(e, "__eval")
  if trace.on then trace.enter("eval", 1, f, e) end

  if f then
    local exp, type = f(e, S, eval)
    if trace.on then trace.leave("eval", 1, e, exp) end
    if type then return exp, type else return exp end
  else
    if trace.on then trace.leave("eval", 1, e, e) end
    return e
  end
end


-- Binding ---------------------------------------------------------------------

function bind(e, S)
  local b = lib.getmetamethod(e, "__bind")
  if trace.on then trace.enter("bind", 1, b, e) end

  local exp, type

  if b then
    exp, type = b(e, S)
  else
    local f = lib.getmetamethod(e, "__eval")
    if f then
      exp, type = f(e, S, bind)
    end
  end
  
  if exp then
    if trace.on then trace.leave("bind", 1, e, exp) end
    if type then return exp, type else return exp end
  else
    if trace.on then trace.leave("bind", 1, e, e) end
    return e
  end
end


-- Types -----------------------------------------------------------------------

function type(e, S)
  local f = lib.getmetamethod(e, "__type")
  if f then
    return f(e, S)
  else
    error(("error getting type information for '%s': the object doesn't support type queries"):
      format(lib.repr(e)))
  end
end


-- Setting ---------------------------------------------------------------------

function set(e, t, v)
  local f = lib.getmetamethod(e, "__set")
  if f then
    f(e, t, v)
  else
    error(("error setting result field '%s' to '%s': the object used as a field index doesn't support setting"):
      format(lib.repr(e), lib.repr(v)))
  end
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

