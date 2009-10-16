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

value = rima.sum{["_, item"]=rima.pairs(items)}(item.picked * item.value)
weight = rima.sum{["_, item"]=rima.pairs(items)}(item.picked * item.weight)

knapsack = rima.formulation:new()
knapsack:set_objective(value, "maximise")
knapsack:add({}, weight, "<=", capacity)
knapsack:scope().items[rima.default].picked = rima.binary()

io.write("\nKnapsack Problem\n")
knapsack:write()


-- Burglar Bill instance
burglar_bill = knapsack:instance
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
}

io.write("\nBurglar Bill Instance of Knapsack Problem\n")
burglar_bill:write()


-- Solve using cbc and lpsolve and write out the results
function solve(problem, solver, S)
  local r = problem:solve(solver, S)
  io.write(("\nSolution from %s:\n  objective:  \t% 10.2f\n  variables:\n"):format(solver, r.objective))
  for k, v in pairs(r.variables.items) do
    io.write(("    %-10s\t%-3s\n"):format(k, v.picked.p == 1 and "yes" or "no"))
  end
end

solve(burglar_bill, "cbc")
solve(burglar_bill, "lpsolve")


-- EOF -------------------------------------------------------------------------

