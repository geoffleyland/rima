-- Copyright (c) 2009-2011 Incremental IP Limited
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

knapsack = rima.mp.new{
  sense = "maximise",
  objective = value,
  capacity_limit = rima.mp.C(size, "<=", capacity),
  [items[{i=items}].take] = rima.binary()
}

io.write("\nKnapsack Problem:\n", tostring(knapsack), "\n")
--[[
Maximise:
  sum{i in items}(i.take*i.value)
Subject to:
  capacity_limit: sum{i in items}(i.size*i.take) <= capacity
  items[i].take binary for all i in items
--]]

io.write("\nKnapsack Problem in LaTeX:\n", rima.repr(knapsack, { format="latex"}), "\n")
--[[
\text{\bf maximise} & \sum_{i \in \text{items}} i_{\text{take}} i_{\text{value}} \\
\text{\bf subject to} \\
\text{capacity\_limit}: & \sum_{i \in \text{items}} i_{\text{take}} i_{\text{size}} \leq \text{capacity} \\
& \text{items}_{i,\text{take}} \in \{ 0, 1 \} \forall i \in \text{items}
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

burglar_bill = rima.mp.new(knapsack, { capacity = 102, items = ITEMS })

io.write("Burglar Bill Instance of Knapsack Problem:\n", tostring(burglar_bill), "\n")


-- Solve using cbc and lpsolve and write out the results
function solve(problem, solver, S)
  local primal, dual = rima.mp.solve_with(solver, problem, S)
  if primal then
    io.write(("\nSolution from %s:\n  objective:  \t% 10.2f\n  variables:\n"):format(solver, primal.objective))
    for k, v in pairs(primal.items) do
      io.write(("    %-10s\t%-3s\n"):format(k, v.take == 1 and "yes" or "no"))
    end
  end
end

solve(burglar_bill, "cbc")
solve(burglar_bill, "lpsolve")


-- Side constraint -------------------------------------------------------------

side_constrained_knapsack = rima.mp.new(knapsack, {
  camera_xor_vase =
    rima.mp.C(items.camera.take + items.vase.take, "<=", 1)
})
io.write("\nSide-constrained knapsack:\n", tostring(side_constrained_knapsack), "\n")
solve(side_constrained_knapsack, "cbc", {capacity=102, items=ITEMS})


-- Calculated size -------------------------------------------------------------

ITEMS2 =
{
  camera   = { value =  15, volume =  2 },
  necklace = { value = 100, volume = 20 },
  vase     = { value =  15, volume = 20 },
  picture  = { value =  15, volume = 30 },
  tv       = { value =  15, volume = 40 },
  video    = { value =  15, volume = 30 },
  chest    = { value =  15, volume = 60 },
  brick    = { value =   1, volume = 10 },
}

calculated_knapsack = rima.mp.new(knapsack, { [items[{i=items}].size] = items[i].volume^(2/3) })
-- this should be:
-- calculated_knapsack = rima.mp.new(knapsack, { [items[{i=items}].size] = i.volume^(2/3) })
io.write("\nCalculated knapsack:\n", tostring(calculated_knapsack), "\n")
-- This writes incorrectly.  Should be
--[[
Maximise:
  sum{i in items}(i.take*i.value)
Subject to:
  capacity_limit: sum{i in items}(i.volume^(0.666)*i.take) <= capacity
  items[i].take binary for all i in items
--]]

solve(calculated_knapsack, "cbc", { capacity = 22, items = ITEMS2 })


-- Multiple knapsacks ----------------------------------------------------------

local s, sacks, once = rima.R"s, sacks, once"
multiple_sack = rima.mp.new{
  sense = "maximise",
  objective = rima.sum{s=sacks}(s.objective),
  [once[{i=items}]] = rima.mp.C(rima.sum{s=sacks}(s.items[i].take), "<=", 1)
}

io.write("\nMultiple sack:\n", tostring(multiple_sack), "\n")

local multiple_knapsack = rima.mp.new(multiple_sack, { [sacks[{s=sacks}]] = knapsack })
io.write("Multiple knapsack:\n", tostring(multiple_knapsack), "\n")


multiple_sack_data = rima.mp.new(multiple_sack, {
  items = ITEMS,
  sacks = { {capacity = 51}, {capacity = 51} },
  [sacks[s].items] = items
  })

local function solve_multiple(problem, ...)
  primal, dual = rima.mp.solve(problem, ...)
  if primal then
    io.write(("\nSolution from %s:\n  objective:  \t% 10.2f\n  variables:\n               "):format("cbc", primal.objective))
    for s in pairs(primal.sacks) do io.write(("subsack %-5s "):format(tostring(s))) end
    io.write("\n")
    for i in pairs(ITEMS) do
      io.write(("    %-10s  "):format(i))
      for _, s in pairs(primal.sacks) do io.write(("% 7s       "):format(s.items[i].take == 1 and "yes" or "no")) end
      io.write("\n") 
    end
  end
end

solve_multiple(multiple_sack_data, { [sacks[{s=sacks}]] = knapsack })

local multiple_sc_knapsack = rima.mp.new(multiple_sack, { [sacks[{s=sacks}]] = side_constrained_knapsack })
io.write("\nMultiple side-constrained knapsack:\n", tostring(multiple_sc_knapsack), "\n")

solve_multiple(multiple_sack_data, { [sacks[{s=sacks}]] = side_constrained_knapsack })

-- EOF -------------------------------------------------------------------------

