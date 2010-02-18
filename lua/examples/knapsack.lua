-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("rima")

--------------------------------------------------------------------------------

--[[
This is the rima version of the "burglar bill" knapsack problem found at
http://dashoptimization.com/home/cgi-bin/example.pl?id=mosel_model_2_2
--]]

-- Formulation of a knapsack
items, item = rima.R"items, item"       -- items to put in the knapsack
capacity = rima.R"capacity"             -- capacity of the knapsack

value = rima.sum{item=items}(item.picked * item.value)
weight = rima.sum{item=items}(item.picked * item.weight)

knapsack = rima.new()
knapsack.objective = value
knapsack.sense = "maximise"
knapsack.weight_limit = rima.C(weight, "<=", capacity)
knapsack.items[item].picked = rima.binary()

io.write("\nKnapsack Problem\n")
rima.lp.write(knapsack)
--[[
Maximise:
  sum{item in items}(item.picked*item.value)
Subject to:
  weight_limit: sum{item in items}(item.picked*item.weight) <= capacity
--]]

-- Burglar Bill instance
burglar_bill = rima.instance(knapsack,
{ 
  capacity = 102,
  items =
  {
    camera   = { value =  15, weight =  2 },
    necklace = { value = 100, weight = 20 },
    vase     = { value =  15, weight = 20 },
    picture  = { value =  15, weight = 30 },
    tv       = { value =  15, weight = 40 },
    video    = { value =  15, weight = 30 },
    chest    = { value =  15, weight = 60 },
    brick    = { value =   1, weight = 10 },
  }
})

io.write("\nBurglar Bill Instance of Knapsack Problem\n")
rima.lp.write(burglar_bill)


-- Solve using cbc and lpsolve and write out the results
function solve(problem, solver, S)
  local objective, r = rima.lp.solve(solver, problem, S)
  io.write(("\nSolution from %s:\n  objective:  \t% 10.2f\n  variables:\n"):format(solver, objective))
  for k, v in pairs(r.items) do
    io.write(("    %-10s\t%-3s\n"):format(k, v.picked.p == 1 and "yes" or "no"))
  end
end

solve(burglar_bill, "cbc")
solve(burglar_bill, "lpsolve")


-- EOF -------------------------------------------------------------------------

