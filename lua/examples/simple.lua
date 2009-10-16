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
local f = rima.formulation:new()
f:add({}, x + 2*y, "<=", 3)
f:add({}, 2*x + y, "<=", 3)
f:set_objective(x + y, "maximise")
f:set{ ["x, y"] = rima.positive() }
io.write("Algebraic Form:\n")
f:write()
io.write("\nSparse Form:\n")
f:write_sparse()

io.write("Solutions:\n")
local function s(solver)
  local r = f:solve(solver)
  io.write(("\n%s:\n  objective:  \t% 10.2f\n  variables:\n"):format(solver, r.objective))
  for k, v in pairs(r.variables) do io.write(("    %-10s\t% 10.2f\t(% 10.2f)\n"):format(k, v.p, v.d)) end
  io.write("  constraints:\n")
  for i, v in ipairs(r.constraints) do io.write(("    %-10d\t% 10.2f\t(% 10.2f)\n"):format(i, v.p, v.d)) end
end

s("lpsolve")
s("clp")
s("cbc")

-- EOF -------------------------------------------------------------------------

