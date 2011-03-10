/*******************************************************************************

rima_solver_tools.cpp

Copyright (c) 2009-2011 Incremental IP Limited
see LICENSE for license information

*******************************************************************************/

#include "rima_solver_tools.h"
extern "C"
{
#include "lauxlib.h"
}
#include <vector>


/*============================================================================*/

int error(lua_State *L, const char *s)
{
  lua_settop(L, 0);
  lua_pushnil(L);
  lua_pushstring(L, s);
  return 2;
}


/*============================================================================*/

const char *check_constraints(lua_State *L, unsigned constraint_count, unsigned column_count, unsigned &max_non_zeroes)
{
  for (unsigned i = 0; i != constraint_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);
    if (lua_type(L, -1) != LUA_TTABLE)
      return "The elements of the constraints table must be tables of constraints";

    lua_pushstring(L, "lower");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return "The lower bound on a constraint (lower) must be a number";
    lua_pop(L, 1);

    lua_pushstring(L, "upper");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return "The upper bound on a constraint (upper) must be a number";
    lua_pop(L, 1);

    lua_pushstring(L, "elements");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TTABLE)
      return "The constraint elements array must be a table";

    unsigned nz = lua_objlen(L, -1);
    for (unsigned j = 0; j != nz; ++j)
    {
      lua_rawgeti(L, -1, j+1);
      if (lua_type(L, -1) != LUA_TTABLE)
        return "The elements of a table of non-zeroes must be a table";
      lua_pushstring(L, "index");
      lua_rawget(L, -2);
      lua_pushstring(L, "coeff");
      lua_rawget(L, -3);
      if (lua_type(L, -1) != LUA_TNUMBER || lua_type(L, -2) != LUA_TNUMBER)
        return "The elements of a table of non-zeroes must be a table with index and coeff fields";
      unsigned column = lua_tointeger(L, -2) - 1;
      if (column > column_count)
        return "An index in the column vector exceeded the number of columns";
      lua_pop(L, 3);
    }
    if (nz > max_non_zeroes)
      max_non_zeroes = nz;
    lua_pop(L, 2);
  }
  return 0;
}


const char *build_constraints(lua_State *L, unsigned max_non_zeroes, unsigned constraint_count, int column_offset, constraint_builder_function *bf, void *bfd)
{
  std::vector<int> columns(max_non_zeroes);
  std::vector<double> coefficients(max_non_zeroes);

  for (unsigned i = 0; i != constraint_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);

    lua_pushstring(L, "lower");
    lua_rawget(L, -2);
    double lower = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "upper");
    lua_rawget(L, -2);
    double upper = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "elements");
    lua_rawget(L, -2);

    unsigned nz = lua_objlen(L, -1);
    for (unsigned j = 0; j != nz; ++j)
    {
      lua_rawgeti(L, -1, j+1);
      lua_pushstring(L, "index");
      lua_rawget(L, -2);
      lua_pushstring(L, "coeff");
      lua_rawget(L, -3);
      unsigned column = lua_tointeger(L, -2) + column_offset;
      double coefficient = lua_tonumber(L, -1);
      columns[j] = column;
      coefficients[j] = coefficient;
      lua_pop(L, 3);
    }

    const char *err = bf(bfd, nz, &columns[0], &coefficients[0], lower, upper);
    if (err) return err;

    lua_pop(L, 2);
  }
  return 0;
}


/*============================================================================*/

const char *check_variables(lua_State *L, unsigned variable_count)
{
  for (unsigned i = 0; i != variable_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);
    if (lua_type(L, -1) != LUA_TTABLE)
      return "The elements of the constraints table must be tables of constraints";

    lua_pushstring(L, "l");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return "The lower bound on a variable (l) must be a number";
    lua_pop(L, 1);

    lua_pushstring(L, "h");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return "The upper bound on a variable (h) must be a number";
    lua_pop(L, 1);

    lua_pushstring(L, "i");
    lua_rawget(L, -2);
    if (!lua_isboolean(L, -1) && !lua_isnil(L, -1))
      return "The integer flag for a variable (i) must be true, false or nil";
    lua_pop(L, 1);

    lua_pushstring(L, "cost");
    lua_rawget(L, -2);
    if (lua_type(L, -1) != LUA_TNUMBER)
      return "The cost of a variable (cost) must be a number";
    lua_pop(L, 1);

    lua_pop(L, 1);
  }
  return 0;
}


const char *build_variables(lua_State *L, unsigned variable_count, variable_builder_function *bf, void *bfd)
{
  for (unsigned i = 0; i != variable_count; ++i)
  {
    lua_rawgeti(L, 2, i+1);

    double lower, upper;
    bool integer;

    lua_pushstring(L, "l");
    lua_rawget(L, -2);
    lower = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "h");
    lua_rawget(L, -2);
    upper = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "i");
    lua_rawget(L, -2);
    integer = lua_toboolean(L, -1);
    lua_pop(L, 1);

    lua_pushstring(L, "cost");
    lua_rawget(L, -2);
    double cost = lua_tonumber(L, -1);
    lua_pop(L, 1);

    const char *err = bf(bfd, i, cost, lower, upper, integer);
    if (err) return err;

    lua_pop(L, 1);
  }
  return 0;
}


/*============================================================================*/

