-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local unpack = unpack
local debug, io = require("debug"), require("io")

local lib = require("rima.lib")

module(...)


-- Evaluation tracing ----------------------------------------------------------

trace = false
depth = 0

function tron()
  trace = true
end


function troff()
  trace = false
end


function reset_depth()
  depth = 0
end


function tracein(f, e)
  local f2 = debug.getinfo(3, "Sln")
  io.write(("%s%s>: %s {%s} from %s (%s:%d)\n"):format(("|  "):rep(depth), f, lib.repr(e), lib.dump(e), f2.name or "?", f2.short_src, f2.currentline))
  depth = depth + 1
end


function traceout(f, e, r)
  depth = depth - 1
  io.write(("%s%s<: %s = %s {%s}\n"):format(("|  "):rep(depth), f, lib.repr(e), lib.repr(r), lib.dump(r)))
end


-- Is an expression defined? ---------------------------------------------------

function defined(e)
  if trace then tracein("defd", e) end
  local d
  local f = lib.getmetamethod(e, "__defined")
  if f then
    d = f(e)
  else
    d = not lib.getmetamethod(e, "__eval")
  end
  if trace then traceout("defd", e, d) end
  return d
end


-- Evaluation ------------------------------------------------------------------

function eval(e, S)
  if trace then tracein("eval", e) end

  local f = lib.getmetamethod(e, "__eval")
  if f then
    local exp, type = f(e, S, eval)
    if trace then traceout("eval", e, r[1]) end
    if type then return exp, type else return exp end
  else
    if trace then traceout("eval", e, e) end
    return e
  end
end


-- Binding ---------------------------------------------------------------------

function bind(e, S)
  if trace then tracein("bind", e) end

  local exp, type

  local b = lib.getmetamethod(e, "__bind")
  if b then
    exp, type = b(e, S)
  else
    local f = lib.getmetamethod(e, "__eval")
    if f then
      exp, type = f(e, S, bind)
    end
  end
  
  if exp then
    if trace then traceout("bind", e, result[1]) end
    if type then return exp, type else return exp end
  else
    if trace then traceout("bind", e, e) end
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

