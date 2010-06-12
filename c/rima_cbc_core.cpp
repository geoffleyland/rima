/*******************************************************************************

rima_cbc_core.cpp

Copyright (c) 2009-2010 Incremental IP Limited
see LICENSE for license information

*******************************************************************************/

extern "C"
{
#include "lualib.h"
#include "lauxlib.h"
LUALIB_API int luaopen_rima_cbc_core(lua_State *L);
}

#include "OsiClpSolverInterface.hpp"
#include "CbcModel.hpp"
#include <vector>

static const char metatable_name[] = "rima.cbc";

/*============================================================================*/

static int error(lua_State *L, const char *s)
{
  lua_settop(L, 0);
  lua_pushnil(L);
  lua_pushstring(L, s);
  return 2;
}

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

static int rima_build_rows(lua_State *L)
{
  OsiSolverInterface *model = get_model(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  unsigned constraint_count = lua_objlen(L, 2);
  unsigned max_non_zeroes = 0;
  unsigned column_count = model->getNumCols();

  for (unsigned i = 0; i != constraint_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);
    if (lua_type(L, -1) != LUA_TTABLE)
      return error(L, "The elements of the constraints table must be tables of constraints");

    lua_pushstring(L, "l");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return error(L, "The lower bound on a constraint (l) must be a number");
    lua_pop(L, 1);

    lua_pushstring(L, "h");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return error(L, "The upper bound on a constraint (h) must be a number");
    lua_pop(L, 1);

    lua_pushstring(L, "m");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TTABLE)
      return error(L, "The constraint members array must be a table");

    unsigned nz = lua_objlen(L, -1);
    for (unsigned j = 0; j != nz; ++j)
    {
      lua_rawgeti(L, -1, j+1);
      if (lua_type(L, -1) != LUA_TTABLE && lua_objlen(L, -1) != 2)
        return error(L, "The elements of a table of non-zeroes must be a table of two numbers");
      lua_rawgeti(L, -1, 1);
      lua_rawgeti(L, -2, 2);
      if (lua_type(L, -1) != LUA_TNUMBER || lua_type(L, -2) != LUA_TNUMBER)
        return error(L, "The elements of a table of non-zeroes must be a table of two numbers");
      unsigned column = lua_tointeger(L, -2) - 1;
      if (column > column_count)
        return error(L, "An index in the column vector exceeded the number of columns");
      lua_pop(L, 3);
    }
    if (nz > max_non_zeroes)
      max_non_zeroes = nz;
    lua_pop(L, 2);
  }

  std::vector<int> columns(max_non_zeroes);
  std::vector<double> coefficients(max_non_zeroes);

  for (unsigned i = 0; i != constraint_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);

    lua_pushstring(L, "l");
    lua_rawget(L, -2);
    double lower = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "h");
    lua_rawget(L, -2);
    double upper = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "m");
    lua_rawget(L, -2);

    unsigned nz = lua_objlen(L, -1);
    for (unsigned j = 0; j != nz; ++j)
    {
      lua_rawgeti(L, -1, j+1);
      lua_rawgeti(L, -1, 1);
      lua_rawgeti(L, -2, 2);
      unsigned column = lua_tointeger(L, -2) - 1;
      double coefficient = lua_tonumber(L, -1);
      columns[j] = column;
      coefficients[j] = coefficient;
      lua_pop(L, 3);
    }
    model->addRow(nz, &columns[0], &coefficients[0], lower, upper);
    lua_pop(L, 2);
  }
  
  lua_pushboolean(L, 1);
  return 1;
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

  for (unsigned i = 0; i != variable_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);
    if (lua_type(L, -1) != LUA_TTABLE)
      return error(L, "The elements of the constraints table must be tables of constraints");
      
    lua_pushstring(L, "l");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return error(L, "The lower bound on a variable (l) must be a number");
    lua_pop(L, 1);

    lua_pushstring(L, "h");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return error(L, "The upper bound on a variable (h) must be a number");
    lua_pop(L, 1);

    lua_pushstring(L, "i");
    lua_rawget(L, -2);
    if (!lua_isboolean(L, -1) && !lua_isnil(L, -1))
      return error(L, "The integer flag for a variable (i) must be true, false or nil");
    lua_pop(L, 1);

    lua_pushstring(L, "cost");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return error(L, "The cost of a variable (cost) must be a number");
    lua_pop(L, 1);

    lua_pop(L, 1);
  }

  for (unsigned i = 0; i != variable_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);

    lua_pushstring(L, "l");
    lua_rawget(L, -2);
    double lower = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "h");
    lua_rawget(L, -2);
    double upper = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "i");
    lua_rawget(L, -2);
    bool integer = lua_toboolean(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "cost");
    lua_rawget(L, -2);
    double cost = lua_tonumber(L, -1);
    lua_pop(L, 1);

    model->addCol(0, 0, 0, lower, upper, cost);
    if (integer)
      model->setInteger(i);

    lua_pop(L, 1);
  }
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

