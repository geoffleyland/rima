-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local lib = require("rima.lib")


------------------------------------------------------------------------------

return function(T)
  local R = lib.repr
  local D = lib.dump

  -- repr
  T:check_equal(R(1), 1)
  T:check_equal(R("a"), "a")
  T:check_equal(R("nil"), "nil")
  
  -- dump
  T:check_equal(D(1), "1")
  T:check_equal(D("a"), '"a"')
  T:check_equal(D(nil), "nil")
end


------------------------------------------------------------------------------

