/*******************************************************************************

rima_solver_tools.h

Copyright (c) 2009-2011 Incremental IP Limited
see LICENSE for license information

*******************************************************************************/

#ifndef rima_solver_tools_h
#define rima_solver_tools_h

extern "C"
{
#include "lualib.h"
}

/*============================================================================*/

int error(lua_State *L, const char *s);

const char *check_constraints(lua_State *L, unsigned constraint_count, unsigned column_count, unsigned &max_non_zeroes);

typedef const char *(constraint_builder_function)(void *data, unsigned non_zeroes, int *columns, double *coefficients, double lower, double upper);
const char *build_constraints(lua_State *L, unsigned max_non_zeroes, unsigned constraint_count, int column_offset, constraint_builder_function *bf, void *bfd);

const char *check_variables(lua_State *L, unsigned variable_count);
typedef const char *(variable_builder_function)(void *data, unsigned index, double cost, double lower, double upper, bool integer);
const char *build_variables(lua_State *L, unsigned variable_count, variable_builder_function *bf, void *bfd);

/*============================================================================*/
#endif

