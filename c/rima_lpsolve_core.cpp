/*******************************************************************************

rima_lpsolve_core.cpp

Copyright (c) 2009-2010 Incremental IP Limited
see LICENSE for license information

*******************************************************************************/

#include "rima_solver_tools.h"
extern "C"
{
#include "lauxlib.h"
#include "lp_lib.h"
LUALIB_API int luaopen_rima_lpsolve_core(lua_State *L);
}

#include <limits>
#include <exception>
#include <new>
#include <cstring>

static const char metatable_name[] = "rima.lpsolve";


/*============================================================================*/

static lprec *get_model(lua_State *L)
{
  return *(lprec**)luaL_checkudata(L, 1, metatable_name);
}


static int rima_new(lua_State *L)
{
  luaL_checkinteger(L, 1);
  luaL_checkinteger(L, 2);
  int rows = lua_tointeger(L, 1), columns = lua_tointeger(L, 2);
  if (rows < 0) return error(L, "bad argument #1 to 'new' (positive integer number of rows expected)");
  if (columns < 0) return error(L, "bad argument #2 to 'new' (positive integer number of rows expected)");
  
  lprec **model = 0;
  try
  {
    model = (lprec**)lua_newuserdata(L, sizeof(lprec*));
    *model = make_lp(rows, columns);
    luaL_getmetatable(L, metatable_name);
    lua_setmetatable(L, -2);
    set_verbose(*model, 0);
  }
  catch (std::bad_alloc)        { return error(L, "Memory allocation failure"); }
  catch (std::exception &e)     { return error(L, e.what()); }
  catch (...)                   { return error(L, "Unknown error"); }

  return 1;
}


static int rima_resize(lua_State *L)
{
  lprec *model = get_model(L);
  luaL_checkinteger(L, 2);
  luaL_checkinteger(L, 3);
  int rows = lua_tointeger(L, 2), columns = lua_tointeger(L, 3);
  if (rows < 0) return error(L, "bad argument #1 to 'resize' (positive integer number of rows expected)");
  if (columns < 0) return error(L, "bad argument #2 to 'resize' (positive integer number of rows expected)");

  resize_lp(model, rows, columns);

  lua_pushboolean(L, 1);
  return 1;
}


static const char *build_constraint(void *M, unsigned non_zeroes, int *columns, double *coefficients, double lower, double upper)
{
  int constraint_type;
  double rhs;
  if (lower == -std::numeric_limits<double>::infinity())
  {
    rhs = upper;
    constraint_type = 1;
  }
  else if (upper == std::numeric_limits<double>::infinity())
  {
    rhs = lower;
    constraint_type = 2;
  }
  else if (lower == upper)
  {
    rhs = lower;
    constraint_type = 3;
  }
  else
    return "lpsolve can't handle constraints with upper and lower bounds";

    if (add_constraintex((lprec *)M, non_zeroes, &coefficients[0], &columns[0], constraint_type, rhs) == 0)
      return "couldn't add constraint";
  return 0;
}


static int rima_build_rows(lua_State *L)
{
  lprec *model = get_model(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  unsigned constraint_count = lua_objlen(L, 2);
  unsigned column_count = get_Ncolumns(model);

  unsigned max_non_zeroes = 0;
  const char *err = check_constraints(L, constraint_count, column_count, max_non_zeroes);
  if (err) return error(L, err);

  err = build_constraints(L, max_non_zeroes, constraint_count, 0, build_constraint, model);
  if (err) return error(L, err);

  lua_pushboolean(L, 1);
  return 1;
}


static const char *build_variable(void *M, unsigned index, double cost, double lower, double upper, bool integer)
{
  index += 1;
  if (set_obj((lprec *)M, index, cost) == 0)
    return "couldn't set variable cost";
  set_bounds((lprec *)M, index, lower, upper);
  if (integer)
    set_int((lprec *)M, index, 1);
  return 0;
}


static int rima_set_objective(lua_State *L)
{
  lprec *model = get_model(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  luaL_checktype(L, 3, LUA_TSTRING);
  unsigned variable_count = lua_objlen(L, 2);
  unsigned column_count = get_Ncolumns(model);

  if (variable_count != column_count)
    return error(L, "The length of the objective vector does not match the number of variables in the problem");

  unsigned optimization_direction = 0;
  const char *sense = lua_tostring(L, 3);
  if (std::strncmp(sense, "minimise", 8) == 0)
    optimization_direction = 0;
  else if (std::strncmp(sense, "maximise", 8) == 0)
    optimization_direction = 1;
  else
    return error(L, "The the optimisation direction must be 'minimise' or 'maximise'");

  const char *err = check_variables(L, variable_count);
  if (err) return error(L, err);

  err = build_variables(L, variable_count, build_variable, model);
  if (err) return error(L, err);

  set_sense(model, optimization_direction);

  lua_pushboolean(L, 1);
  return 1;  
}


static int rima_solve(lua_State *L)
{
  lprec *model = get_model(L);

  int result = solve(model);

  if (result != 0)
    return error(L, "Model not solved to optimality");

  lua_pushboolean(L, 1);
  return 1;
}


static int rima_get_solution(lua_State *L)
{
  lprec *model = get_model(L);

  unsigned row_count = get_Nrows(model);
  unsigned column_count = get_Ncolumns(model);
  double *primal, *dual;
  get_ptr_primal_solution(model, &primal);
  get_ptr_dual_solution(model, &dual);

  lua_newtable(L);
  lua_pushnumber(L, *primal);
  lua_setfield(L, -2, "objective");
  ++primal; ++dual;

  lua_createtable(L, row_count, 0);
  for (unsigned i = 0; i != row_count; ++i)
  {
    lua_newtable(L);
    lua_pushnumber(L, *primal);
    lua_setfield(L, -2, "p");
    lua_pushnumber(L, *dual);
    lua_setfield(L, -2, "d");
    lua_rawseti(L, -2, i + 1);
    ++primal; ++dual;    
  }
  lua_setfield(L, -2, "constraints");

  lua_createtable(L, column_count, 0);
  for (unsigned i = 0; i != column_count; ++i)
  {
    lua_newtable(L);
    lua_pushnumber(L, *primal);
    lua_setfield(L, -2, "p");
    lua_pushnumber(L, *dual);
    lua_setfield(L, -2, "d");
    lua_rawseti(L, -2, i + 1);
    ++primal; ++dual;    
  }
  lua_setfield(L, -2, "variables");

  return 1;
}


static int rima_delete(lua_State *L)
{
  delete_lp(get_model(L));
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


LUALIB_API int luaopen_rima_lpsolve_core(lua_State *L)
{
  // Create a metatable for our object
  luaL_newmetatable(L, metatable_name);
  
  // Set the metatable's index to be the metatable
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  
  // Add the object's methods to the metatable
  luaL_register(L, NULL, rima_methods);
  
  // Register the module functions
  luaL_register(L, "rima_lpsolve_core", rima_functions);
  return 1;
}


/*============================================================================*/

