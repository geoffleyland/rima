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
local I = rima.R"I"                     -- ingredients
local N = rima.R"N"                     -- nutrients
local c = rima.R"c"                     -- cost of ingredients
local n = rima.R"n"                     -- nutrients in each product
local l = rima.R"l"                     -- limits on nutrients
local T = rima.R"T"                     -- total amount of product we're producing

local f = rima.R"f"                     -- ingredient fractions (result)


-- Set up the blending problem
blending_problem = rima.formulation:new()
blending_problem:scope().f[rima.default] = rima.positive()
blending_problem:set_objective(rima.sum({I}, c[I] * f[I]), "minimise")
blending_problem:add({}, rima.sum({I}, f[I]), "==", T)
blending_problem:add({N}, rima.sum({I}, n[I][N] * f[I]), ">=", T * l[N])

-- The formulation can describe itself
io.write("\nBlending Problem\n")
blending_problem:write()
--[[
Output is

Minimise:
  sum(c[I]*f[I], I in I)
Subject to:
  sum(f[I], I in I) == T
  sum(f[I]*n[I, N], I in I) >= T*l[N] for all N in N
--]]

--[[
The data comes AFTER the formulation.
This is standard Lua table construction.
--]]
local whiskas_data = {
  I = {"chicken", "beef", "mutton", "rice", "wheat bran", "gel"},
  N = {"protein", "fat", "fibre", "salt"},
  c = { 0.013, 0.008, 0.010, 0.002, 0.005, 0.001 },
  l = { 0.08, 0.06, -0.02, -0.004 },
  n =
  {                   --  protein fat    fibre   salt
    chicken           = { 0.100,  0.080, -0.001, -0.002 },
    beef              = { 0.200,  0.100, -0.005, -0.005 },
    mutton            = { 0.150,  0.110, -0.003, -0.007 },
    rice              = { 0.000,  0.010, -0.100, -0.002 },
    ["wheat bran"]    = { 0.040,  0.010, -0.150, -0.008 },
    gel               = { 0.000,  0.000, -0.000, -0.000 },
  },
}

-- An instance is a formulation plus some data.
-- An instance is actually just another formulation
whiskas = blending_problem:instance(whiskas_data)

local function s(problem, solver, S)
  local r = problem:solve(solver, S)
  io.write(("\n%s:\n  objective:  \t% 10.2f\n  variables:\n"):format(solver, r.objective))
  for k, v in pairs(r.variables.f) do io.write(("    %-10s\t% 10.2f\t(% 10.2f)\n"):format(k, v.p, v.d)) end
end

-- We can choose our solver and set any extra variables when we solve.
s(whiskas, "clp", { T=1 })
-- cbc and lpsolve can solve integer problems
-- Note that we're redefining f as an integer.  What there is of a type
-- system lets this happen because integers are subsets of positive variables.
-- You couldn't set f to a free variable (because a free variable is not a
-- subset of a positive variable).

whiskas_integer = whiskas:instance{ T = 99 }
whiskas_integer:scope().f[rima.default] = rima.integer()

s(whiskas_integer, "cbc")
s(whiskas_integer, "lpsolve")

-- EOF -------------------------------------------------------------------------

