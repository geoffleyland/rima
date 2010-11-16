-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

require("rima")

--------------------------------------------------------------------------------

--[[
This simple problem is copied from an OSI example:
  https://projects.coin-or.org/svn/Osi/trunk/Osi/examples/build.cpp
--]]

io.write("\nSimple Test:\n")

local x, y = rima.R"x, y"
local S = rima.mp.new()
S.c1 = rima.mp.C(x + 2*y, "<=", 3)
S.c2 = rima.mp.C(2*x + y, "<=", 3)
S.objective = x + y
S.sense = "maximise"
S.x = rima.positive()
S.y = rima.positive()

io.write("Algebraic Form:\n")
io.write(tostring(S))
io.write("\nSparse Form:\n")
rima.mp.write_sparse(S)

io.write("Solutions:\n")
local function s(solver)
  local primal, dual = rima.mp.solve(solver, S)
  if primal then
    io.write(("\n%s:\n  objective:  \t% 10.2f\n  variables and constraints:\n"):format(solver, primal.objective))
    for k, v in pairs(dual) do io.write(("    %-10s\t% 10.2f\t(% 10.2f)\n"):format(k, primal[k], v)) end
  end
end

s("lpsolve")
s("clp")
s("cbc")

-- EOF -------------------------------------------------------------------------

