-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

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


-- EOF -------------------------------------------------------------------------

