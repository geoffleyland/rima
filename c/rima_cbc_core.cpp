/*******************************************************************************

rima_cbc_core.cpp

Copyright (c) 2009-2010 Incremental IP Limited
see LICENSE for license information

*******************************************************************************/

#include "rima_solver_tools.h"
extern "C"
{
#include "lauxlib.h"
LUALIB_API int luaopen_rima_cbc_core(lua_State *L);
}

#include "OsiClpSolverInterface.hpp"
#include "CbcModel.hpp"

static const char metatable_name[] = "rima.cbc";


/*============================================================================*/

static OsiSolverInterface *get_model(lua_State *L)
{
  CbcModel *cbc = (CbcModel*)luaL_checkudata(L, 1, metatable_name);
  return cbc->solver();
}


static int rima_new(lua_State *L)
{
  CbcModel *model;

  try
  {
    OsiClpSolverInterface osiclp;
    model = new(lua_newuserdata(L, sizeof(CbcModel))) CbcModel(osiclp);

    luaL_getmetatable(L, metatable_name);
    lua_setmetatable(L, -2);
    model->setLogLevel(0);
  }
  catch (std::bad_alloc)        { return error(L, "Memory allocation failure"); }
  catch (std::exception &e)     { return error(L, e.what()); }
  catch (...)                   { return error(L, "Unknown error"); }

  return 1;
}


static const char *build_constraint(void *M, unsigned non_zeroes, int *columns, double *coefficients, double lower, double upper)
{
  ((OsiSolverInterface*)M)->addRow(non_zeroes, &columns[0], &coefficients[0], lower, upper);
  return 0;
}


static int rima_build_rows(lua_State *L)
{
  OsiSolverInterface *model = get_model(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  unsigned constraint_count = lua_objlen(L, 2);
  unsigned column_count = model->getNumCols();

  unsigned max_non_zeroes = 0;
  const char *err = check_constraints(L, constraint_count, column_count, max_non_zeroes);
  if (err) return error(L, err);

  err = build_constraints(L, max_non_zeroes, constraint_count, -1, build_constraint, model);
  if (err) return error(L, err);

  lua_pushboolean(L, 1);
  return 1;
}


static const char *build_variable(void *M, unsigned index, double cost, double lower, double upper, bool integer)
{
  ((OsiSolverInterface*)M)->addCol(0, 0, 0, lower, upper, cost);
  if (integer)
    ((OsiSolverInterface*)M)->setInteger(index);
  return 0;
}


static int rima_set_objective(lua_State *L)
{
  OsiSolverInterface *model = get_model(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  luaL_checktype(L, 3, LUA_TSTRING);
  unsigned variable_count = lua_objlen(L, 2);

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

  model->setObjSense(optimization_direction);

  lua_pushboolean(L, 1);
  return 1;  
}


static int rima_solve(lua_State *L)
{
  CbcModel *model = (CbcModel*)luaL_checkudata(L, 1, metatable_name);

  model->branchAndBound();

  if (!model->isProvenOptimal())
    return error(L, "Model not solved to optimality");

  lua_pushboolean(L, 1);
  return 1;
}


static int rima_get_solution(lua_State *L)
{
  CbcModel *model = (CbcModel*)luaL_checkudata(L, 1, metatable_name);

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
  CbcModel *model = (CbcModel*)luaL_checkudata(L, 1, metatable_name);
  model->~CbcModel();
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
  {"build_rows", rima_build_rows},
  {"set_objective", rima_set_objective},
  {"solve", rima_solve},
  {"get_solution", rima_get_solution},
  {NULL, NULL}
};


LUALIB_API int luaopen_rima_cbc_core(lua_State *L)
{
  // Create a metatable for our object
  luaL_newmetatable(L, metatable_name);
  
  // Set the metatable's index to be the metatable
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  
  // Add the object's methods to the metatable
  luaL_register(L, NULL, rima_methods);
  
  // Register the module functions
  luaL_register(L, "rima_cbc_core", rima_functions);
  return 1;
}


/*============================================================================*/

