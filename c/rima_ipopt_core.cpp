/*******************************************************************************

rima_ipopt_core.cpp

Copyright (c) 2010 Incremental IP Limited
see LICENSE for license information

*******************************************************************************/

extern "C"
{
#include "lualib.h"
#include "lauxlib.h"
LUALIB_API int luaopen_rima_ipopt_core(lua_State *L);
}
#include "IpTNLP.hpp"
#include "IpIpoptApplication.hpp"

#include <limits>
#include <vector>

#include <cstdio>
#include <cassert>

static const char metatable_name[] = "rima.ipopt";

/*============================================================================*/

using Ipopt::Index;
using Ipopt::Number;
using Ipopt::SolverReturn;
using Ipopt::IpoptData;
using Ipopt::IpoptCalculatedQuantities;

class rima_ipopt_problem : public Ipopt::TNLP
{
  public:
    rima_ipopt_problem(
      lua_State *L,
      int variable_count,
      int constraint_count,
      int cj_count,
      int hessian_count,
      int model_index);
    ~rima_ipopt_problem(void);

  private:
    rima_ipopt_problem(const rima_ipopt_problem &);
    rima_ipopt_problem &operator=(const rima_ipopt_problem &);

  public:
    /** ipopt specific methods for defining the nlp problem */
    virtual bool get_nlp_info(Index& n, Index& m, Index& nnz_jac_g,
                              Index& nnz_h_lag, IndexStyleEnum& index_style);

    /** Method to return the bounds for my problem */
    virtual bool get_bounds_info(Index n, Number* x_l, Number* x_u,
                                 Index m, Number* g_l, Number* g_u);

    /** Method to return the starting point for the algorithm */
    virtual bool get_starting_point(Index n, bool init_x, Number* x,
                                    bool init_z, Number* z_L, Number* z_U,
                                    Index m, bool init_lambda,
                                    Number* lambda);

    /** Method to return the objective value */
    virtual bool eval_f(Index n, const Number* x, bool new_x, Number& obj_value);

    /** Method to return the gradient of the objective */
    virtual bool eval_grad_f(Index n, const Number* x, bool new_x, Number* grad_f);

    /** Method to return the constraint residuals */
    virtual bool eval_g(Index n, const Number* x, bool new_x, Index m, Number* g);

    /** Method to return:
    *   1) The structure of the jacobian (if "values" is NULL)
    *   2) The values of the jacobian (if "values" is not NULL)
    */
    virtual bool eval_jac_g(Index n, const Number* x, bool new_x,
                            Index m, Index nele_jac, Index* iRow, Index *jCol,
                            Number* values);

    /** Method to return:
    *   1) The structure of the hessian of the lagrangian (if "values" is NULL)
    *   2) The values of the hessian of the lagrangian (if "values" is not NULL)
    */
    virtual bool eval_h(Index n, const Number* x, bool new_x,
                        Number sigma, Index m, const Number* lambda,
                        bool new_lambda, Index nele_hess, Index* iRow,
                        Index* jCol, Number* values);

    /** This method is called when the algorithm is complete so the TNLP can store/write the solution */
    virtual void finalize_solution(SolverReturn status,
                                   Index n, const Number* x, const Number* z_L, const Number* z_U,
                                   Index m, const Number* g, const Number* lambda,
                                   Number obj_value, const IpoptData* ip_data,
                                   IpoptCalculatedQuantities* ip_cq);

//  private:
    lua_State *L_;
    int
      variable_count_,
      constraint_count_,
      cj_count_,
      hessian_count_,
      model_index_;

#ifdef false
virtual bool get_scaling_parameters(Number& obj_scaling,
                                    bool& use_x_scaling, Index n,
                                    Number* x_scaling,
                                    bool& use_g_scaling, Index m,
                                    Number* g_scaling);

#endif
};


/*============================================================================*/

rima_ipopt_problem::rima_ipopt_problem(
  lua_State *L,
  int variable_count,
  int constraint_count,
  int cj_count,
  int hessian_count,
  int model_index) :
  L_(L),
  variable_count_(variable_count),
  constraint_count_(constraint_count),
  cj_count_(cj_count),
  hessian_count_(hessian_count),
  model_index_(model_index)
{
}

rima_ipopt_problem::~rima_ipopt_problem(void)
{
  luaL_unref(L_, LUA_REGISTRYINDEX, model_index_);
}

bool rima_ipopt_problem::get_nlp_info(Index& n, Index& m, Index& nnz_jac_g,
                                      Index& nnz_h_lag, IndexStyleEnum& index_style)
{
  n = variable_count_;
  m = constraint_count_;
  nnz_jac_g = cj_count_;
  nnz_h_lag = hessian_count_;
  index_style = TNLP::C_STYLE;

  return true;
}

bool rima_ipopt_problem::get_bounds_info(Index n, Number* x_l, Number* x_u,
                                         Index m, Number* g_l, Number* g_u)
{
  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);

  lua_pushstring(L_, "variables");
  lua_rawget(L_, -2);
  for (int i = 1; i <= variable_count_; ++i)
  {
    lua_rawgeti(L_, -1, i);
    lua_pushstring(L_, "type");
    lua_rawget(L_, -2);

    lua_pushstring(L_, "lower");
    lua_rawget(L_, -2);
    x_l[i-1] = lua_tonumber(L_, -1);
    lua_pop(L_, 1);

    lua_pushstring(L_, "upper");
    lua_rawget(L_, -2);
    x_u[i-1] = lua_tonumber(L_, -1);
    lua_pop(L_, 1);

    lua_pop(L_, 1);
    lua_pop(L_, 1);
  }
  lua_pop(L_, 1);

  lua_pushstring(L_, "constraint_bounds");
  lua_rawget(L_, -2);
  for (int i = 1; i <= constraint_count_; ++i)
  {
    lua_rawgeti(L_, -1, i);

    lua_pushstring(L_, "lower");
    lua_rawget(L_, -2);
    g_l[i-1] = lua_tonumber(L_, -1);
    lua_pop(L_, 1);

    lua_pushstring(L_, "upper");
    lua_rawget(L_, -2);
    g_u[i-1] = lua_tonumber(L_, -1);
    lua_pop(L_, 1);
    
    lua_pop(L_, 1);
  }
  lua_pop(L_, 1);

  return true;
}


bool rima_ipopt_problem::get_starting_point(Index n, bool init_x, Number* x,
                                            bool init_z, Number* z_L, Number* z_U,
                                            Index m, bool init_lambda,
                                            Number* lambda)
{
  assert(init_x == true);
  assert(init_z == false);
  assert(init_lambda == false);

  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);

  lua_pushstring(L_, "variables");
  lua_rawget(L_, -2);
  for (int i = 1; i <= variable_count_; ++i)
  {
    lua_rawgeti(L_, -1, i);

    lua_pushstring(L_, "initial");
    lua_rawget(L_, -2);
    x[i-1] = lua_tonumber(L_, -1);
    lua_pop(L_, 1);
    
    lua_pop(L_, 1);
  }
  lua_pop(L_, 1);

  return true;
}


static void push_variables(lua_State *L, int stack_index, const char *name, int variable_count, const Number *x)
{
  lua_pushstring(L, name);
  lua_rawget(L, stack_index-1);
  for (int i = 1; i <= variable_count; ++i)
  {
    lua_pushnumber(L, x[i-1]);
    lua_rawseti(L, -2, i);
  }
}


static void read_result(lua_State *L, int result_count, Number *x)
{
  for (int i = 1; i <= result_count; ++i)
  {
    lua_rawgeti(L, -1, i);
    x[i-1] = lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
}


bool rima_ipopt_problem::eval_f(Index n, const Number *x, bool new_x, Number &obj_value)
{
  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);
  lua_pushstring(L_, "objective_function");
  lua_rawget(L_, -2);
  push_variables(L_, -2, "variable_table", variable_count_, x);

  int err = lua_pcall(L_, 1, 1, 0);
  if (err)
  {
    std::fprintf(stderr, "Error evaluating objective function for ipopt: %s\n", lua_tostring(L_, -1));
    return false;
  }

  obj_value = lua_tonumber(L_, -1);
  lua_settop(L_, 0);

  return true;
}


bool rima_ipopt_problem::eval_grad_f(Index n, const Number *x, bool new_x, Number *grad_f)
{
  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);
  lua_pushstring(L_, "objective_jacobian");
  lua_rawget(L_, -2);
  push_variables(L_, -2, "variable_table", variable_count_, x);

  int err = lua_pcall(L_, 1, 1, 0);
  if (err)
  {
    std::fprintf(stderr, "Error evaluating objective jacobian for ipopt: %s\n", lua_tostring(L_, -1));
    return false;
  }

  read_result(L_, variable_count_, grad_f);
  lua_settop(L_, 0);

  return true;
}


bool rima_ipopt_problem::eval_g(Index n, const Number* x, bool new_x, Index m, Number* g)
{
  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);
  lua_pushstring(L_, "constraint_function");
  lua_rawget(L_, -2);
  push_variables(L_, -2, "variable_table", variable_count_, x);

  int err = lua_pcall(L_, 1, 1, 0);
  if (err)
  {
    std::fprintf(stderr, "Error evaluating constraints for ipopt: %s\n", lua_tostring(L_, -1));
    return false;
  }

  read_result(L_, constraint_count_, g);
  lua_settop(L_, 0);

  return true;
}


bool rima_ipopt_problem::eval_jac_g(Index n, const Number* x, bool new_x,
                                    Index m, Index nele_jac, Index* iRow, Index *jCol,
                                    Number* values)
{
  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);

  if (values != 0)
  {
    lua_pushstring(L_, "constraint_jacobian");
    lua_rawget(L_, -2);
    push_variables(L_, -2, "variable_table", variable_count_, x);

    int err = lua_pcall(L_, 1, 1, 0);
    if (err)
    {
      std::fprintf(stderr, "Error evaluating constraint jacobian for ipopt: %s\n", lua_tostring(L_, -1));
      return false;
    }

    read_result(L_, cj_count_, values);
    lua_settop(L_, 0);
  }
  else
  {
    lua_pushstring(L_, "cj_sparsity");
    lua_rawget(L_, -2);
    for (int i = 0; i != nele_jac; ++i)
    {
      lua_rawgeti(L_, -1, i+1);
      lua_rawgeti(L_, -1, 1);
      iRow[i] = lua_tonumber(L_, -1) - 1;
      lua_pop(L_, 1);
      lua_rawgeti(L_, -1, 2);
      jCol[i] = lua_tonumber(L_, -1) - 1;
      lua_pop(L_, 1);
      lua_pop(L_, 1);
    } 
  }
  return true;
}


bool rima_ipopt_problem::eval_h(Index n, const Number* x, bool new_x,
                                Number sigma, Index m, const Number* lambda,
                                bool new_lambda, Index nele_hess, Index* iRow,
                                Index* jCol, Number* values)
{
  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);

  if (values != 0)
  {
    lua_pushstring(L_, "hessian");
    lua_rawget(L_, -2);
    push_variables(L_, -2, "variable_table", variable_count_, x);
    lua_pushnumber(L_, sigma);
    push_variables(L_, -4, "lambda_table", constraint_count_, lambda);

    int err = lua_pcall(L_, 3, 1, 0);
    if (err)
    {
      std::fprintf(stderr, "Error evaluating hessian for ipopt: %s\n", lua_tostring(L_, -1));
      return false;
    }

    read_result(L_, hessian_count_, values);
    lua_settop(L_, 0);
  }
  else
  {
    lua_pushstring(L_, "hessian_sparsity");
    lua_rawget(L_, -2);
    for (int i = 0; i != nele_hess; ++i)
    {
      lua_rawgeti(L_, -1, i+1);
      lua_rawgeti(L_, -1, 1);
      iRow[i] = lua_tonumber(L_, -1) - 1;
      lua_pop(L_, 1);
      lua_rawgeti(L_, -1, 2);
      jCol[i] = lua_tonumber(L_, -1) - 1;
      lua_pop(L_, 1);
      lua_pop(L_, 1);
    } 
  }
  return true;
}


void rima_ipopt_problem::finalize_solution(SolverReturn status,
                                           Index n, const Number* x, const Number* z_L, const Number* z_U,
                                           Index m, const Number* g, const Number* lambda,
                                           Number obj_value, const IpoptData* ip_data,
                                           IpoptCalculatedQuantities* ip_cq)
{
  lua_rawgeti(L_, LUA_REGISTRYINDEX, model_index_);
  lua_createtable(L_, 0, 3);
  lua_pushstring(L_, "results");
  lua_pushvalue(L_, -2);
  lua_settable(L_, -4);

  lua_pushstring(L_, "success");
  lua_pushboolean(L_, status == Ipopt::SUCCESS);
  lua_settable(L_, -3);

  if (status == Ipopt::SUCCESS)
  {
    lua_pushstring(L_, "success");
    lua_pushboolean(L_, true);
    lua_settable(L_, -3);

    lua_pushstring(L_, "objective");
    lua_pushnumber(L_, obj_value);
    lua_settable(L_, -3);

    lua_createtable(L_, variable_count_, 0);
    lua_pushstring(L_, "variables");
    lua_pushvalue(L_, -2);
    lua_settable(L_, -4);
    
    for (int i = 1; i <= variable_count_; ++i)
    {
      lua_pushnumber(L_, x[i-1]);
      lua_rawseti(L_, -2, i);
    }
    lua_pop(L_, 1);

    lua_createtable(L_, constraint_count_, 0);
    lua_pushstring(L_, "constraints");
    lua_pushvalue(L_, -2);
    lua_settable(L_, -4);
    
    for (int i = 1; i <= constraint_count_; ++i)
    {
      lua_pushnumber(L_, g[i-1]);
      lua_rawseti(L_, -2, i);
    }
    lua_pop(L_, 1);
  }
  lua_pop(L_, 2);
}


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
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_settop(L, 1);

  lua_pushstring(L, "variables");
  lua_rawget(L, -2);
  int variable_count = lua_objlen(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "constraint_bounds");
  lua_rawget(L, -2);
  int constraint_count = lua_objlen(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "cj_sparsity");
  lua_rawget(L, -2);
  int cj_count = lua_objlen(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "hessian_sparsity");
  lua_rawget(L, -2);
  int hessian_count = lua_objlen(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "variable_table");
  lua_createtable(L, variable_count, 0);
  lua_settable(L, -3);

  lua_pushstring(L, "lambda_table");
  lua_createtable(L, constraint_count, 0);
  lua_settable(L, -3);
  
  int model_index = luaL_ref(L, LUA_REGISTRYINDEX);

  rima_ipopt_problem *model = 0;
  try
  {
    void *mptr = lua_newuserdata(L, sizeof(rima_ipopt_problem));
    model = new(mptr)
      rima_ipopt_problem(
        L,
        variable_count,
        constraint_count,
        cj_count,
        hessian_count,
        model_index);
    model->AddRef((Ipopt::Referencer*)L);
    luaL_getmetatable(L, metatable_name);
    lua_setmetatable(L, -2);
  }
  catch (std::bad_alloc)        { return error(L, "Memory allocation failure"); }
  catch (std::exception &e)     { return error(L, e.what()); }
  catch (...)                   { return error(L, "Unknown error"); }

  return 1;
}


static int rima_solve(lua_State *L)
{
  rima_ipopt_problem &model = *(rima_ipopt_problem*)luaL_checkudata(L, 1, metatable_name);

  Ipopt::IpoptApplication app;
  app.Options()->SetNumericValue("tol", 1e-9);
  app.Options()->SetIntegerValue("print_level", 0);
  app.Options()->SetStringValue("mu_strategy", "adaptive");
  app.Initialize();
  Ipopt::ApplicationReturnStatus status = app.OptimizeTNLP(&model);

  lua_rawgeti(L, LUA_REGISTRYINDEX, model.model_index_);
  lua_getfield(L, -1, "results");
  lua_getfield(L, -1, "success");

  unsigned success = lua_toboolean(L, -1);
  lua_pop(L, 1);
  lua_remove(L, -2);

  if (success)
    return 1;
  else
    return error(L, "Solve failed");
}


static int rima_eval(lua_State *L)
{
  rima_ipopt_problem &model = *(rima_ipopt_problem*)luaL_checkudata(L, 1, metatable_name);
  double
    *x = new double[model.variable_count_],
    *x_l = new double[model.variable_count_],
    *x_u = new double[model.variable_count_],
    *x_init = new double[model.variable_count_],
    *x_result = new double[model.variable_count_],
    *lambda = new double[model.constraint_count_],
    *grad = new double[model.variable_count_],
    *constraint = new double[model.constraint_count_],
    *c_l = new double[model.constraint_count_],
    *c_u = new double[model.constraint_count_],
    *cj = new double[model.cj_count_],
    *h = new double[model.hessian_count_];
  int
    *cj_rows = new int[model.cj_count_],
    *cj_cols = new int[model.cj_count_],
    *h_rows = new int[model.hessian_count_],
    *h_cols = new int[model.hessian_count_];

  for (int i = 0; i != model.variable_count_; ++i)
    x[i] = (double)i;
  for (int i = 0; i != model.variable_count_; ++i)
    x_result[i] = 1.5 + (double)i / 10.0;
  for (int i = 0; i != model.constraint_count_; ++i)
    lambda[i] = 1.0;

  double result = 0.0;
  
  int variable_count, constraint_count, cj_count, h_count;
  Ipopt::TNLP::IndexStyleEnum s;
  model.get_nlp_info(variable_count, constraint_count, cj_count, h_count, s);
  model.get_bounds_info(variable_count, x_l, x_u, constraint_count, c_l, c_u);
  model.get_starting_point(variable_count, true, x_init, false, 0, 0, constraint_count, false, 0);
  model.eval_f(model.variable_count_, x, true, result);
  model.eval_grad_f(model.variable_count_, x, true, grad);
  model.eval_g(model.variable_count_, x, true, model.constraint_count_, constraint);
  model.eval_jac_g(model.variable_count_, x, true, model.constraint_count_, model.cj_count_, cj_rows, cj_cols, 0);
  model.eval_jac_g(model.variable_count_, x, true, model.constraint_count_, model.cj_count_, 0, 0, cj);
  model.eval_h(model.variable_count_, x, true, 1.0, model.constraint_count_, lambda, true, model.hessian_count_, h_rows, h_cols, 0);
  model.eval_h(model.variable_count_, x, true, 1.0, model.constraint_count_, lambda, true, model.hessian_count_, 0, 0, h);
  model.finalize_solution(Ipopt::SUCCESS, model.variable_count_, x_result, 0, 0, model.constraint_count_, 0, 0, 0, 0, 0);

  std::fprintf(stderr, "info\n");
  std::fprintf(stderr, "  %d %d %d %d %d\n", variable_count, constraint_count, cj_count, h_count, s);

  std::fprintf(stderr, "variable bounds\n");
  for (int i = 0; i != model.variable_count_; ++i)
    std::fprintf(stderr, "  %f %f\n", x_l[i], x_u[i]);

  std::fprintf(stderr, "constraint bounds\n");
  for (int i = 0; i != model.constraint_count_; ++i)
    std::fprintf(stderr, "  %f %f\n", c_l[i], c_u[i]);

  std::fprintf(stderr, "variable initial values\n");
  for (int i = 0; i != model.variable_count_; ++i)
    std::fprintf(stderr, "  %f\n", x_init[i]);

  std::fprintf(stderr, "f\n");
  std::fprintf(stderr, "  %f\n", result);

  std::fprintf(stderr, "grad_f\n");
  for (int i = 0; i != model.variable_count_; ++i)
    std::fprintf(stderr, "  %f\n", grad[i]);

  std::fprintf(stderr, "g\n");
  for (int i = 0; i != model.constraint_count_; ++i)
    std::fprintf(stderr, "  %f\n", constraint[i]);

  std::fprintf(stderr, "constraint jacobian\n");
  for (int i = 0; i != model.cj_count_; ++i)
    std::fprintf(stderr, "  %d %d %f\n", cj_rows[i], cj_cols[i], cj[i]);

  std::fprintf(stderr, "hessian\n");
  for (int i = 0; i != model.hessian_count_; ++i)
    std::fprintf(stderr, "  %d %d %f\n", h_rows[i], h_cols[i], h[i]);

  delete []x;
  delete []x_l;
  delete []x_u;
  delete []x_init;
  delete []x_result;
  delete []lambda;
  delete []grad;
  delete []constraint;
  delete []c_l;
  delete []c_u;
  delete []cj;
  delete []h;
  delete []cj_rows;
  delete []cj_cols;
  delete []h_rows;
  delete []h_cols;

  lua_pushnumber(L, result);
  return 1;
}


static int rima_delete(lua_State *L)
{
  rima_ipopt_problem *model = (rima_ipopt_problem*)luaL_checkudata(L, 1, metatable_name);
  model->ReleaseRef((Ipopt::Referencer*)L);
  model->~rima_ipopt_problem(); 
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
//  {"resize", rima_resize},
//  {"build_rows", rima_build_rows},
//  {"set_objective", rima_set_objective},
  {"solve", rima_solve},
//  {"get_solution", rima_get_solution},
  {"eval", rima_eval},
  {NULL, NULL}
};

LUALIB_API int luaopen_rima_ipopt_core(lua_State *L)
{
  // Create a metatable for our object
  luaL_newmetatable(L, metatable_name);
  
  // Set the metatable's index to be the metatable
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  
  // Add the object's methods to the metatable
  luaL_register(L, NULL, rima_methods);
  
  // Register the module functions
  luaL_register(L, "rima_ipopt_core", rima_functions);
  return 1;
}


/*============================================================================*/

