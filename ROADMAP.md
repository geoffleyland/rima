# Rima Roadmap

## Column-wise Modelling

It's only a short step from the new constraint syntax to column-wise modelling.
`rima.free(), rima.binary()` and others will change (not quite sure how) to
accept an expression:

    model.scope().column_var[{x=X}] = rima.column:new(rima.free(), sum{y=Y}(x * y), cost)

There's a few tricks: 

+ all the free references in a column expression will have to be references to
  columns, (as all the free references in constraint expressions will have to
  be to columns or variables)
+ we'll have to search for columns as well
+ rima will accept a mix of row and column-wise modelling, but any non-zero
  will have to be defined by only one column or row
+ the cost on `column:new` will be optional, and the cost of a variable will
  have to be defined by only one of the column or the objective function.

## Speed things up

Constraint search and generation is pretty slow, so one day I'll have to work on
speed a bit.

## Better solver support

This starts with handling a few solver options, and eventually heads towards
resolves.

## Type constraints

Optional type constraints so you can get static checking when you want it.

## Host-Language Independence

It'd be cool if you could bind Rima to languages other than Lua.  That might
require a rewrite in C.  That's a way off.

## Use Information about Model Structure

We could redefine a knapsack so that it included cover inequalities.  That'd
require the Rima "language" complete enough to write a cover generation
heuristic.

## Previously on Roadmap

+ Getting Rid of rima.tabulate and rima.default (Done for 0.03)
+ Tidying Constraints (Done for 0.03)
+ Local Variables (or Objects) (Done for 0.04)
+ Subproblems (Done for 0.04)
+ Tidying Solve (Partly done for 0.03, more in 0.04)

