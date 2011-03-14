/*******************************************************************************

rima_clp_core.cpp

Copyright (c) 2009-2011 Incremental IP Limited
see LICENSE for license information

*******************************************************************************/

#include "rima_solver_tools.h"
extern "C"
{
#include "lauxlib.h"
LUALIB_API int luaopen_rima_clp_core(lua_State *L);
}

#include "ClpSimplex.hpp"
#include "CoinBuild.hpp"

static const char metatable_name[] = "rima.clp";


/*============================================================================*/

static ClpSimplex *get_model(lua_State *L)
{
  return (ClpSimplex*)luaL_checkudata(L, 1, metatable_name);
}


static int rima_new(lua_State *L)
{
  ClpSimplex *model = 0;

  try
  {
    model = new(lua_newuserdata(L, sizeof(ClpSimplex))) ClpSimplex();

    luaL_getmetatable(L, metatable_name);
    lua_setmetatable(L, -2);
    model->setLogLevel(0);
  }
  catch (std::bad_alloc)        { return error(L, "Memory allocation failure"); }
  catch (std::exception &e)     { return error(L, e.what()); }
  catch (...)                   { return error(L, "Unknown error"); }

  return 1;
}


static int rima_resize(lua_State *L)
{
  ClpSimplex *model = (ClpSimplex*)luaL_checkudata(L, 1, metatable_name);
  luaL_checkinteger(L, 2);
  luaL_checkinteger(L, 3);
  int rows = lua_tointeger(L, 2), columns = lua_tointeger(L, 3);
  if (rows < 0) return error(L, "bad argument #1 to 'resize' (positive integer number of rows expected)");
  if (columns < 0) return error(L, "bad argument #2 to 'resize' (positive integer number of rows expected)");

  model->resize(rows, columns);

  lua_pushboolean(L, 1);
  return 1;
}


static const char *build_constraint(void *M, unsigned non_zeroes, int *columns, double *coefficients, double lower, double upper)
{
  ((CoinBuild*)M)->addRow(non_zeroes, &columns[0], &coefficients[0], lower, upper);
  return 0;
}


static int rima_build_rows(lua_State *L)
{
  ClpSimplex *model = get_model(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  unsigned constraint_count = lua_objlen(L, 2);
  unsigned column_count = model->getNumCols();

  unsigned max_non_zeroes = 0;
  const char *err = check_constraints(L, constraint_count, column_count, max_non_zeroes);
  if (err) return error(L, err);

  CoinBuild builder;
  err = build_constraints(L, max_non_zeroes, constraint_count, -1, build_constraint, &builder);
  if (err) return error(L, err);
  model->addRows(builder);

  lua_pushboolean(L, 1);
  return 1;
}


static const char *build_variable(void *M, unsigned index, double cost, double lower, double upper, bool integer)
{
  ((ClpSimplex*)M)->setObjectiveCoefficient(index, cost);
  ((ClpSimplex*)M)->setColumnBounds(index, lower, upper);
  if (integer)
    ((ClpSimplex*)M)->setInteger(index);
  return 0;
}


static int rima_set_objective(lua_State *L)
{
  ClpSimplex *model = get_model(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  luaL_checktype(L, 3, LUA_TSTRING);
  unsigned variable_count = lua_objlen(L, 2);
  unsigned column_count = model->getNumCols();

  if (variable_count != column_count)
    return error(L, "The length of the objective vector does not match the number of variables in the problem");

  double optimization_direction = 0.0;
  const char *sense = lua_tostring(L, 3);
  if (std::strncmp(sense, "minimise", 8) == 0)
    optimization_direction = 1.0;
  else if (std::strncmp(sense, "maximise", 8) == 0)
    optimization_direction = -1.0;
  else
    return error(L, "The the optimisation direction must be 'minimise' or 'maximise'");

  const char *err = check_variables(L, variable_count);
  if (err) return error(L, err);

  err = build_variables(L, variable_count, build_variable, model);
  if (err) return error(L, err);

  model->setOptimizationDirection(optimization_direction);

  lua_pushboolean(L, 1);
  return 1;  
}


static int rima_solve(lua_State *L)
{
  ClpSimplex *model = get_model(L);

  model->primal();

  if (!model->isProvenOptimal())
    return error(L, "Model not solved to optimality");

  lua_pushboolean(L, 1);
  return 1;
}


static int rima_get_solution(lua_State *L)
{
  ClpSimplex *model = get_model(L);

  if (!model->isProvenOptimal())
    return error(L, "Model not solved to optimality");

  lua_newtable(L);
  lua_pushnumber(L, model->getObjValue());
  lua_setfield(L, -2, "objective");

  unsigned column_count = model->getNumCols();
  const double *primal_vars = model->getColSolution();
  const double *dual_vars = model->getReducedCost();
  lua_createtable(L, column_count, 0);
  for (unsigned i = 0; i != column_count; ++i)
  {
    lua_newtable(L);
    lua_pushnumber(L, primal_vars[i]);
    lua_setfield(L, -2, "p");
    lua_pushnumber(L, dual_vars[i]);
    lua_setfield(L, -2, "d");
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "variables");

  unsigned row_count = model->getNumRows();
  const double *primal_constraints = model->getRowActivity();
  const double *dual_constraints = model->getRowPrice();
  lua_createtable(L, row_count, 0);
  for (unsigned i = 0; i != row_count; ++i)
  {
    lua_newtable(L);
    lua_pushnumber(L, primal_constraints[i]);
    lua_setfield(L, -2, "p");
    lua_pushnumber(L, dual_constraints[i]);
    lua_setfield(L, -2, "d");
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "constraints");

  return 1;
}


static int rima_delete(lua_State *L)
{
  get_model(L)->~ClpSimplex();
  return 0;
}


/*============================================================================*/

static luaL_Reg rima_functions[] =
{
  {"new",  rima_new},
  {NULL, NULL}
};


static luaL_Reg rima_methods[] =
{
  {"__gc", rima_delete},
  {"resize", rima_resize},
  {"build_rows", rima_build_rows},
  {"set_objective", rima_set_objective},
  {"solve", rima_solve},
  {"get_solution", rima_get_solution},
  {NULL, NULL}
};


LUALIB_API int luaopen_rima_clp_core(lua_State *L)
{
  // Create a metatable for our object
  luaL_newmetatable(L, metatable_name);
  
  // Set the metatable's index to be the metatable
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  
  // Add the object's methods to the metatable
  luaL_register(L, NULL, rima_methods);
  
  // Register the module functions
  luaL_register(L, "rima_clp_core", rima_functions);
  return 1;
}


/*============================================================================*/

