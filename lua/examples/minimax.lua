-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("rima")

--------------------------------------------------------------------------------

-- Set up references to variables
local P, p = rima.R"P, p"               -- set of sampling Points
local T, t = rima.R"T, t"               -- set of Terms we're trying to fit
local s = rima.R"s"                     -- y-coordinates of Samples
local y = rima.R"y"                     -- Y-coordinates of functions at each point

local w = rima.R"w"                     -- set of Weights we're trying to find
local max_error = rima.R"max_error"     -- max error
local sum_error = rima.R"sum_error"     -- sum of errors
local Q, q = rima.R"Q, q"               -- positive and negative error set
local e = rima.R"e"                     -- positive and negative Errors at each point


-- Curve fit formulation
local curve_fit = rima.formulation:new()
curve_fit:add({p=P},
  rima.sum{t=T}(w[t] * y[t][p]) +
  rima.sum{q=Q}(q * e[q][p]), "==",
  s[p])
curve_fit:add({q=Q, p=P}, max_error, ">=", e[q][p])
curve_fit:add({}, sum_error, "==", rima.sum{q=Q, p=P}(e[q][p]))
curve_fit:set{ ["max_error, sum_error"]=rima.positive(), Q = {-1, 1} }
curve_fit:scope().e[rima.default][rima.default] = rima.positive()
curve_fit:scope().w[rima.default] = rima.free()

-- Write the formulation
io.write("\nCurve Fitting\n")
curve_fit:write()
--[[ output:
No objective defined
Subject to:
  -e[-1, p] + e[1, p] + sum(w[t]*y[t, p], t in T) == s[p] for all p in P
  max_error >= e[-1, p] for all p in P
  max_error >= e[1, p] for all p in P
  sum_error == sum(e[-1, p] + e[1, p], p in P)
--]]

-- minimax formulation
local minimax = curve_fit:instance()
minimax:set_objective(max_error, "minimise")

-- minisum formulation
local minisum = curve_fit:instance()
minisum:set_objective(sum_error, "minimise")

-- equally spaced sampling points
local points, x, xmin, xmax = rima.R"points, x, xmin, xmax"
local equispaced_points =
{
  P = rima.range(0, points),
  x = { [rima.default] = rima.tabulate({p}, xmin + (xmax - xmin) * p / points) }
}

-- fit a polynomial with arbitrary order terms
local polynomial_fits = { y = { [rima.default] = { [rima.default] = rima.tabulate({t, p}, x[p]^t) } } }

-- fit polynomial with terms 1, x, x^2
local terms = rima.R"terms"
local consecutive_polynomials = { T = rima.range(1, terms) }

-- fit to a function
local f = rima.R"f"
local samples_from_function = { s = { [rima.default] = rima.tabulate({p}, f(x[p])) } }


-- Put it all together
local Z = minimax:instance(polynomial_fits, consecutive_polynomials, samples_from_function, equispaced_points)

local r = Z:solve("clp",
{
  xmin = 0,
  xmax = 10,
  points = 10,
  terms = 4,
  f = rima.F{x}(rima.exp(x) * rima.sin(x)),
})
io.write(("\nMinimax Polynomial with CLP\n  max error:\t% 10.2f\n"):format(r.objective))
for k, v in pairs(r.variables.w) do io.write(("  w[%d]:\t% 10.2f\t(% 10.2f)\n"):format(k, v.p, v.d)) end


-- EOF -------------------------------------------------------------------------

