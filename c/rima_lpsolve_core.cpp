/*******************************************************************************

rima_lpsolve_core.cpp

Copyright (c) 2009 Incremental IP Limited
see license.txt for license information

*******************************************************************************/

extern "C"
{
#include "lualib.h"
#include "lauxlib.h"
#include "lp_lib.h"
LUALIB_API int luaopen_rima_lpsolve_core(lua_State *L);
}

#include <limits>
#include <vector>

static const char metatable_name[] = "rima.lpsolve";

/*============================================================================*/

static int error(lua_State *L, const char *s)
{
  lua_settop(L, 0);
  lua_pushnil(L);
  lua_pushstring(L, s);
  return 2;
}

/*============================================================================*/

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
  lprec *model = *(lprec**)luaL_checkudata(L, 1, metatable_name);
  luaL_checkinteger(L, 2);
  luaL_checkinteger(L, 3);
  int rows = lua_tointeger(L, 2), columns = lua_tointeger(L, 3);
  if (rows < 0) return error(L, "bad argument #1 to 'resize' (positive integer number of rows expected)");
  if (columns < 0) return error(L, "bad argument #2 to 'resize' (positive integer number of rows expected)");

  resize_lp(model, rows, columns);

  lua_pushboolean(L, 1);
  return 1;
}

static int rima_build_rows(lua_State *L)
{
  lprec *model = *(lprec**)luaL_checkudata(L, 1, metatable_name);
  luaL_checktype(L, 2, LUA_TTABLE);
  unsigned constraint_count = lua_objlen(L, 2);
  unsigned max_non_zeroes = 0;
  unsigned column_count = get_Ncolumns(model);

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
      unsigned column = lua_tointeger(L, -2); // - 1;
      double coefficient = lua_tonumber(L, -1);
      columns[j] = column;
      coefficients[j] = coefficient;
      lua_pop(L, 3);
    }
    
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
      return error(L, "lpsolve can't handle constraints with upper and lower bounds");

    if (add_constraintex(model, nz, &coefficients[0], &columns[0], constraint_type, rhs) == 0)
      return error(L, "couldn't add constraint");
    lua_pop(L, 2);
  }
  
  lua_pushboolean(L, 1);
  return 1;
}

static int rima_set_objective(lua_State *L)
{
  lprec *model = *(lprec**)luaL_checkudata(L, 1, metatable_name);
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

    if (set_obj(model, i+1, cost) == 0)
      return error(L, "couldn't set variable cost");
    set_bounds(model, i+1, lower, upper);
    if (integer)
      set_int(model, i+1, 1);

    lua_pop(L, 1);
  }
  set_sense(model, optimization_direction);

  lua_pushboolean(L, 1);
  return 1;  
}

static int rima_solve(lua_State *L)
{
  lprec *model = *(lprec**)luaL_checkudata(L, 1, metatable_name);
  int result = solve(model);

  if (result != 0)
    return error(L, "Model not solved to optimality");

  lua_pushboolean(L, 1);
  return 1;  
}

static int rima_get_solution(lua_State *L)
{
  lprec *model = *(lprec**)luaL_checkudata(L, 1, metatable_name);

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
  lprec *model = *(lprec**)luaL_checkudata(L, 1, metatable_name);
  delete_lp(model); 
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

