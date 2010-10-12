-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

require("rima")

--------------------------------------------------------------------------------

--[[
This is the rima version of the "burglar bill" knapsack problem found at
http://dashoptimization.com/home/cgi-bin/example.pl?id=mosel_model_2_2
--]]

-- Formulation of a knapsack
i, items = rima.R"i, items"             -- items to put in the knapsack
capacity = rima.R"capacity"             -- capacity of the knapsack

value = rima.sum{i=items}(i.take * i.value)
size = rima.sum{i=items}(i.take * i.size)

knapsack = rima.new{
  sense = "maximise",
  objective = value,
  capacity_limit = rima.mp.C(size, "<=", capacity),
}
knapsack.items[{i=items}].take = rima.binary()

io.write("\nKnapsack Problem\n")
rima.mp.write(knapsack)
io.write("\n")
--[[
Maximise:
  sum{i in items}(i.take*i.value)
Subject to:
  capacity_limit: sum{i in items}(i.size*i.take) <= capacity
--]]

-- Burglar Bill instance
ITEMS =
{
  camera   = { value =  15, size =  2 },
  necklace = { value = 100, size = 20 },
  vase     = { value =  15, size = 20 },
  picture  = { value =  15, size = 30 },
  tv       = { value =  15, size = 40 },
  video    = { value =  15, size = 30 },
  chest    = { value =  15, size = 60 },
  brick    = { value =   1, size = 10 },
}

burglar_bill = rima.instance(knapsack, { capacity = 102, items = ITEMS })

io.write("Burglar Bill Instance of Knapsack Problem\n")
rima.mp.write(burglar_bill)


-- Solve using cbc and lpsolve and write out the results
function solve(problem, solver, S)
  local primal, dual = rima.mp.solve(solver, problem, S)
  io.write(("\nSolution from %s:\n  objective:  \t% 10.2f\n  variables:\n"):format(solver, primal.objective))
  for k, v in pairs(primal.items) do
    io.write(("    %-10s\t%-3s\n"):format(k, v.take == 1 and "yes" or "no"))
  end
end

solve(burglar_bill, "cbc")
solve(burglar_bill, "lpsolve")


-- EOF -------------------------------------------------------------------------

