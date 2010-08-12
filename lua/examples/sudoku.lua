-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

require("rima")

--------------------------------------------------------------------------------

--[[
This is the rima version of the sudoku problem.
The PuLP version is at http://code.google.com/p/pulp-or/source/browse/trunk/pulp-or/examples/Sudoku1.py
and a python-zibopt version at http://code.google.com/p/python-zibopt/source/browse/trunk/examples/sudoku.py
--]]

r, rows = rima.R"r, rows"
c, columns = rima.R"c, columns"
v, values = rima.R"v, values"
g1, g2, groups = rima.R"g1, g2, groups"  -- groups for the little 3x3 blocks
answer = rima.R"answer"
initial = rima.R"initial"                -- the starting solution

-- Create the model and set up the constraints
sudoku = rima.new()
sudoku.one_value_per_cell[{r=rows}][{c=columns}] = rima.C(rima.sum{v=values}(answer[r][c][v]), "==", 1)
sudoku.each_value_once_per_row[{r=rows}][{v=values}] = rima.C(rima.sum{c=columns}(answer[r][c][v]), "==", 1)
sudoku.each_value_once_per_column[{c=columns}][{v=values}] = rima.C(rima.sum{r=rows}(answer[r][c][v]), "==", 1)
sudoku.each_value_once_per_square[{g1=groups}][{g2=groups}][{v=values}] = rima.C(rima.sum{r=rima.range(g1, g1+2),c=rima.range(g2, g2+2)}(answer[r][c][v]), "==", 1)

-- We use the initial solution to decide whether each of the elements of answer
-- is a variable or a constant.
sudoku.answer[{r=rows}][{c=columns}][{v=values}] = rima.case(initial[r][c],
  {
    { v, 1 },
    { 0, rima.binary() },
  }, 0)

-- We don't have an objective, we just want a feasible solution
sudoku.objective = 1
sudoku.sense = "minimise"


-- Write out our model
rima.mp.write(sudoku)
--[[
Minimise:
  1
Subject to:
  one_value_per_cell[r in rows, c in columns]:                         sum{v in values}(answer[r, c, v]) == 1
  each_value_once_per_column[c in columns, v in values]:               sum{r in rows}(answer[r, c, v]) == 1
  each_value_once_per_row[r in rows, v in values]:                     sum{c in columns}(answer[r, c, v]) == 1
  each_value_once_per_square[g1 in groups, g2 in groups, v in values]: sum{c in range(g2, 2 + g2), r in range(g1, 2 + g1)}(answer[r, c, v]) == 1
--]]

-- Set up a 9 by 9 sudoku problem
sudoku_9_by_9 = rima.instance(sudoku,
  {
    rows = rima.range(1, 9),
    columns = rima.range(1, 9),
    values = rima.range(1, 9),
    groups = {1, 4, 7},
  })


-- The example sudoku grid from zibopt
zibopt_problem =
{
  {0, 0, 0,   6, 9, 2,   0, 4, 0},
  {7, 0, 0,   0, 0, 0,   8, 9, 0},
  {0, 0, 0,   0, 0, 0,   0, 0, 6},

  {0, 0, 9,   0, 1, 7,   0, 0, 3},
  {0, 0, 7,   0, 8, 0,   5, 0, 0},
  {8, 0, 0,   4, 6, 0,   1, 0, 0},

  {5, 0, 0,   0, 0, 0,   0, 0, 0},
  {0, 8, 6,   0, 0, 0,   0, 0, 1},
  {0, 3, 0,   7, 2, 8,   0, 0, 0}
}
sudoku_zibopt = rima.instance(sudoku_9_by_9, { initial = zibopt_problem })

-- Solve the problem
local objective, result = rima.mp.solve("cbc", sudoku_zibopt)

-- Print the answer nicely.  There's probably an easier way to do this.
io.write("\nSudoku answer\n")

for i, v in pairs(result.answer) do
  for j, w in pairs(v) do
    for k, x in pairs(w) do
      if x.p == 1 then zibopt_problem[i][j] = k end
    end
  end
end

for i, r in ipairs(zibopt_problem) do
  for j, v in ipairs(r) do
    io.write(("%d "):format(v))
    if j == 3 or j == 6 then io.write(" ") end
  end
  io.write("\n")
  if i == 3 or i == 6 then io.write("\n") end
end


-- EOF -------------------------------------------------------------------------

