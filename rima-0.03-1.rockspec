package = "rima"
version = "0.03-1"
source = {
   url = "http://rima.googlecode.com/files/rima-0.03.tar.gz"
}
external_dependencies =
{
   LIBCOIN =
   {
      header = "coin/utils/CoinBuild.hpp"
   },
   LIBLPSOLVE =
   {
      header = "lpsolve/lp_lib.h"
   }
}
description =
{
   summary = "Linear programming for Lua",
   detailed =
   [[
      Rima is a symbolic math modelling tool.
   ]],
   homepage = "http://www.incremental.co.nz/projects/lua.html",
   license = "MIT/X11",
   maintainer = "Geoff Leyland",
}
dependencies =
{
   "lua >= 5.1"
}
build =
{
   type = "builtin",
   modules =
   {
      rima_clp_core =
      {
         sources = { "c/rima_clp_core.cpp" },
         libraries = { "clp", "coinutils" }, 
         incdirs = { "$(LIBCOIN_INCDIR)/coin/clp", "$(LIBCOIN_INCDIR)/coin/utils", "$(LIBCOIN_INCDIR)/coin/headers", },
         libdirs = { "$(LIBCOIN_LIBDIR)"},
      },
      rima_cbc_core =
      {
         sources = { "c/rima_cbc_core.cpp" },
         libraries = { "cbc", "osiclp" }, 
         incdirs = { "$(LIBCOIN_INCDIR)/coin/cbc", "$(LIBCOIN_INCDIR)/coin/osi", "$(LIBCOIN_INCDIR)/coin/clp", "$(LIBCOIN_INCDIR)/coin/utils", "$(LIBCOIN_INCDIR)/coin/headers", },
         libdirs = { "$(LIBCOIN_LIBDIR)"},
      },
      rima_lpsolve_core =
      {
         sources = { "c/rima_lpsolve_core.cpp" },
         libraries = { "lpsolve55", "stdc++" }, 
         incdirs = { "$(LIBLPSOLVE_INCDIR)/lpsolve", },
         libdirs = { "$(LIBLPSOLVE_LIBDIR)"},
      },
   },
   platforms =
   {
      win32 =
      {
         rima_clp_core = { defines = {"NOMINMAX" } },
         rima_cbc_core = { defines = {"NOMINMAX" } },
         rima_lpsolve_core = { defines = {"NOMINMAX" } },
      }
   }
}
