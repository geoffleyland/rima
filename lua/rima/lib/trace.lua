-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local debug, io = require("debug"), require("io")
local select = select

local lib = require("rima.lib")

module(...)


-- Evaluation tracing ----------------------------------------------------------

_M.on = false
_M.depth = 0

function tron()
  on = true
end


function troff()
  on = false
end


function reset_depth()
  depth = 0
end


function enter(tag, caller_depth, callee, ...)
  local caller = debug.getinfo(caller_depth and caller_depth+2 or 3, "Sln")
  callee = callee and debug.getinfo(callee, "Sln")
  caller = ("from %s:%d"):format(caller.short_src, caller.currentline)
  callee = (callee and (" to %s:%d"):format(callee.short_src, callee.linedefined)) or ""
  io.write(("%s%s>: "):format(("|  "):rep(depth), tag))
  for i = 1, select('#', ...) do
    local a = select(i, ...)
    io.write(("%s: %s "):format(lib.repr(a), lib.dump(a)))
  end
  io.write(("(%s%s)\n"):format(caller, callee))
  depth = depth + 1
end


function leave(tag, arg_count, ...)
  depth = depth - 1
  io.write(("%s%s<: "):format(("|  "):rep(depth), tag))
  for i = 1, arg_count do
    local a = select(i, ...)
    io.write(("%s "):format(lib.repr(a)))
  end
  io.write("= ")
  for i = arg_count + 1, select('#', ...) do
    local a = select(i, ...)
    if a then
      io.write(("%s: %s "):format(lib.repr(a), lib.dump(a)))
    end
  end
  io.write("\n")
end


-- EOF -------------------------------------------------------------------------

