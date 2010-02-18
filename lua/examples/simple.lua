-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("rima")

--------------------------------------------------------------------------------

--[[
This simple problem is copied from an OSI example:
  https://projects.coin-or.org/svn/Osi/trunk/Osi/examples/build.cpp
--]]

io.write("\nSimple Test:\n")

local x, y = rima.R"x, y"
local S = rima.new()
S.c1 = rima.C(x + 2*y, "<=", 3)
S.c2 = rima.C(2*x + y, "<=", 3)
S.objective = x + y
S.sense = "maximise"
rima.set(S, { ["x, y"] = rima.positive() })

io.write("Algebraic Form:\n")
rima.lp.write(S)
io.write("\nSparse Form:\n")
rima.lp.write_sparse(S)

io.write("Solutions:\n")
local function s(solver)
  local objective, r = rima.lp.solve(solver, S)
  io.write(("\n%s:\n  objective:  \t% 10.2f\n  variables and constraints:\n"):format(solver, objective))
  for k, v in pairs(r) do io.write(("    %-10s\t% 10.2f\t(% 10.2f)\n"):format(k, v.p, v.d)) end
end

s("lpsolve")
s("clp")
s("cbc")

-- EOF -------------------------------------------------------------------------

