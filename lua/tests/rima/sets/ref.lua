-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local ref = require("rima.sets.ref")

local lib = require("rima.lib")
local core = require("rima.core")
local scope = require("rima.scope")
local index = require("rima.index")


------------------------------------------------------------------------------

return function(T)
  local R = index.R
  local E = core.eval
  local D = lib.dump

  do
    local a, A, b, c = R"a, A, b, c"
    local S = scope.new{A={{x="onedotx"}}} 
    S.b[{a=A}] = a
    S.c[{a=A}] = A[a]
    T:check_equal(E(b[1].x, S), "onedotx")
    T:check_equal(E(c[1].x, S), "onedotx")
  end
end


------------------------------------------------------------------------------
