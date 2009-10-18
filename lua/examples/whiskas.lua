-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("rima")

--------------------------------------------------------------------------------

--[[
This blending problem is copied from
http://130.216.209.237/engsci392/pulp/ABlendingProblem
which I believe is in turn copied from Mike Trick's web pages, though I can't
find the page in question.
--]]

-- Set up references to variables
--[[
Because rima has to interact with Lua, at this stage we're only declaring the
names of the variables we're going to use - no values are bound to them and the
same reference could bind to different variables in different scopes.

"local" is just lua's way of declaring a local (Lua) variable (as opposed to a
global variable)
rima.R is a short-named function that creates a reference.
The syntax rima.R"V" is short for rima.R("V")
rima.R can create more than one reference at a time
 eg: local a, b, c = rima.R"a, b, c"

There's not a lot of type information at the moment (we're not saying what's a
variable, parameter or set, or the dimensions or bounds on variables).
This is partly deliberate - rima doesn't need to know what's a parameter or
a variable - it'll try to solve for what's missing and rima can be a dynamic
language and doesn't need to know much type information in advance - if things
work then it's ok.  However, I have worked on a type system that can be used
to check what you're doing in advance.  It's just not very good yet.
--]]
local i, ingredients = rima.R"i, ingredients"
local n, nutrients   = rima.R"n, nutrients"
local limits         = rima.R"limits"       -- limits on nutrients
local quantity       = rima.R"quantity"     -- quantity of pet food to make

-- Set up the blending problem
total_cost = rima.sum{["_, i"]=rima.pairs(ingredients)}(i.cost * i.quantity)
total_quantity = rima.sum{["_, i"]=rima.pairs(ingredients)}(i.quantity)


blending_problem = rima.formulation:new()
blending_problem:scope().ingredients[rima.default].quantity = rima.positive()

blending_problem:set_objective(total_cost, "minimise")
blending_problem:add({}, total_quantity, "==", quantity)

blending_problem:add({n=nutrients}, rima.sum{["_, i"]=rima.pairs(ingredients)}(i.composition[n] * i.quantity), ">=", quantity * limits[n])

-- The formulation can describe itself
io.write("\nBlending Problem\n")
blending_problem:write()
--[[
Minimise:
  sum{_, i in pairs(ingredients)}(i.cost*i.quantity)
Subject to:
  sum{_, i in pairs(ingredients)}(i.quantity) == quantity
  sum{_, i in pairs(ingredients)}(i.composition[n]*i.quantity) >= limits[n]*quantity for all {n in nutrients}
--]]

--[[
The data comes AFTER the formulation.
This is standard Lua table construction.
--]]
local whiskas_data =
{
  nutrients = {"protein", "fat", "fibre", "salt"},
  limits = { protein = 0.08, fat = 0.06, fibre = -0.02, salt = -0.004 },
  ingredients =
  {                                                 --  protein fat    fibre   salt
    chicken           = { cost = 0.013, composition = { 0.100,  0.080, -0.001, -0.002 } },
    beef              = { cost = 0.008, composition = { 0.200,  0.100, -0.005, -0.005 } },
    mutton            = { cost = 0.010, composition = { 0.150,  0.110, -0.003, -0.007 } },
    rice              = { cost = 0.002, composition = { 0.000,  0.010, -0.100, -0.002 } },
    ["wheat bran"]    = { cost = 0.005, composition = { 0.040,  0.010, -0.150, -0.008 } },
    gel               = { cost = 0.001, composition = { 0.000,  0.000, -0.000, -0.000 } },
  },
}

-- An instance is a formulation plus some data.
-- An instance is actually just another formulation
whiskas = blending_problem:instance(whiskas_data)

local function s(problem, solver, S)
  local r = problem:solve(solver, S)
  io.write(("\n%s:\n  objective:  \t% 10.2f\n  variables:\n"):format(solver, r.objective))
  for k, v in pairs(r.variables.ingredients) do io.write(("    %-10s\t% 10.2f\t(% 10.2f)\n"):format(k, v.quantity.p, v.quantity.d)) end
end

-- We can choose our solver and set any extra variables when we solve.
s(whiskas, "clp", { quantity=1 })

-- cbc and lpsolve can solve integer problems
-- Note that we're redefining f as an integer.  What there is of a type
-- system lets this happen because integers are subsets of positive variables.
-- You couldn't set f to a free variable (because a free variable is not a
-- subset of a positive variable).
whiskas_integer = whiskas:instance{ quantity = 99 }
whiskas_integer:scope().ingredients[rima.default].quantity = rima.integer()

s(whiskas_integer, "cbc")
s(whiskas_integer, "lpsolve")

-- EOF -------------------------------------------------------------------------

