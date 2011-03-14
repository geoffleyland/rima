-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

require("rima")


--------------------------------------------------------------------------------

--[[
This simple nonlinear problem is copied from the ipopt documentation:
  http://www.coin-or.org/Ipopt/documentation/node28.html
--]]

rima.define"x, X"

m = rima.mp.new{
  sense = "minimise",
  objective = X[1]*X[4]*(X[1] + X[2] + X[3]) + X[3],
  c1 = rima.mp.C(rima.product{x=X}(x), ">=", 25),
  c2 = rima.mp.C(rima.sum{x=X}(x^2), "==", 40),
  X = { rima.free(1, 5), rima.free(1, 5), rima.free(1, 5), rima.free(1, 5) }
}

local primal, message = rima.mp.solve(m)
if primal then
  io.stderr:write(("Nonlinear solution:\n  objective: %g\n  variables %g %g %g %g\n"):format(
    primal.objective, primal.X[1], primal.X[2], primal.X[3], primal.X[4]))
else
  io.stderr:write(message, "\n")
end


-- EOF -------------------------------------------------------------------------
