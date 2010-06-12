-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

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
local curve_fit = rima.new()
curve_fit.fit_data[{p=P}] = rima.C(
  rima.sum{t=T}(w[t] * y[t][p]) +
  rima.sum{q=Q}(q * e[q][p]), "==",
  s[p])
curve_fit.find_max_error[{q=Q}][{p=P}] = rima.C(max_error, ">=", e[q][p])
curve_fit.find_error_sum = rima.C(sum_error, "==", rima.sum{q=Q, p=P}(e[q][p]))
rima.set(curve_fit, { ["max_error, sum_error"]=rima.positive(), Q = {-1, 1} })
curve_fit.e[{q=Q}][{p=P}] = rima.positive()
curve_fit.w[{t=T}] = rima.free()
curve_fit.sense = "minimise"

-- Write the formulation
io.write("\nCurve Fitting\n")
rima.lp.write(curve_fit)
--[[ output:
No objective defined
Subject to:
  -e[-1, p] + e[1, p] + sum(w[t]*y[t, p], t in T) == s[p] for all p in P
  max_error >= e[-1, p] for all p in P
  max_error >= e[1, p] for all p in P
  sum_error == sum(e[-1, p] + e[1, p], p in P)
--]]

-- minimax formulation
local minimax = rima.instance(curve_fit)
minimax.objective = max_error

-- minisum formulation
local minisum = rima.instance(curve_fit)
minisum.objective = sum_error

-- equally spaced sampling points
local points, x, xmin, xmax = rima.R"points, x, xmin, xmax"
local equispaced_points =
{
  P = rima.range(0, points),
  x = { [p] = xmin + (xmax - xmin) * p / points }
}

-- fit a polynomial with arbitrary order terms
local polynomial_fits = { y = { [t] = { [p] = x[p]^t } } }

-- fit polynomial with terms 1, x, x^2
local terms = rima.R"terms"
local consecutive_polynomials = { T = rima.range(1, terms) }

-- fit to a function
local f = rima.R"f"
local samples_from_function = { s = { [p] = f(x[p]) } }


-- Put it all together
local Z = rima.instance(minimax, polynomial_fits, consecutive_polynomials, samples_from_function, equispaced_points)

local objective, r = rima.lp.solve("clp", Z,
{
  xmin = 0,
  xmax = 10,
  points = 10,
  terms = 4,
  f = rima.F{x}(rima.exp(x) * rima.sin(x)),
})
io.write(("\nMinimax Polynomial with CLP\n  max error:\t% 10.2f\n"):format(objective))
for k, v in pairs(r.w) do io.write(("  w[%d]:\t% 10.2f\t(% 10.2f)\n"):format(k, v.p, v.d)) end


-- EOF -------------------------------------------------------------------------

