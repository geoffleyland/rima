-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local lib = require("rima.lib")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local x = interface.R"x"
  local opmath = interface.math
  local diff = interface.diff

  T:check_equal(diff(1, x), 0)
  T:check_equal(diff(x, x), 1)
  T:check_equal(diff(x*x, x), "2*x")
  T:check_equal(diff(x*x*x, x), "3*x^2")
  T:check_equal(diff(x^2, x), "2*x")
  T:check_equal(diff(x^3, x), "3*x^2")
  T:check_equal(diff(x^0.5, x), "0.5/x^0.5")
  T:check_equal(diff(2^x, x), "0.6931*2^x")
  T:check_equal(diff(10^x, x), "2.303*10^x")
  T:check_equal(diff(x^x, x), "(1 + log(x))*x^x")
  T:check_equal(diff(opmath.exp(x), x), "exp(x)")
  T:check_equal(diff(opmath.exp(2*x), x), "2*exp(2*x)")
  T:check_equal(diff(opmath.exp(x*x), x), "2*exp(x^2)*x")
  T:check_equal(diff(opmath.exp(x^2), x), "2*exp(x^2)*x")
  T:check_equal(diff(opmath.log(x), x), "1/x")
  T:check_equal(diff(opmath.log(2*x), x), "1/x")
  T:check_equal(diff(opmath.log(x*x), x), "2/x")
  T:check_equal(diff(opmath.log(x^2), x), "2/x")
  T:check_equal(diff(opmath.sin(x), x), "cos(x)")
  T:check_equal(diff(opmath.sin(2*x), x), "2*cos(2*x)")
  T:check_equal(diff(opmath.sin(x*x), x), "2*cos(x^2)*x")
  T:check_equal(diff(opmath.sin(x^2), x), "2*cos(x^2)*x")
  T:check_equal(diff(opmath.cos(x), x), "-1*sin(x)")

  T:check_equal(diff((opmath.sin(x))^(x^2), x), "(cos(x)/sin(x)*x^2 + 2*log(sin(x))*x)*sin(x)^(x^2)")
end


------------------------------------------------------------------------------

