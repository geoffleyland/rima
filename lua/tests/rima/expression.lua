-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local expression = require("rima.expression")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local interface = require("rima.interface")


------------------------------------------------------------------------------

local function equal(T, expected, got)
  local function prep(z)
    if object.typename(z) == "table" then
      local e = z[1]
      for i = 3, #z do
        local arg = z[2]
        arg = (arg ~= "" and arg) or nil
        e = z[i](e, arg)
      end
      return e
    else
      return z
    end
  end

  local e, g = prep(expected), prep(got)
  T:check_equal(g, e, nil, 1)
end

return function(T)
  local E = core.eval
  local D = lib.dump
  local R = interface.R

  -- tests with add, mul and pow
  do
    local a, b = R"a, b"
    local S = {}
    equal(T, '+(1*3, 4*index(address{"a"}))', {3 + 4 * a, S, E, D})
    equal(T, "3 - 4*a", {4 * -a + 3, S, E})
    equal(T, '+(1*3, 4**(index(address{"a"})^1, index(address{"b"})^1))', {3 + 4 * a * b, S, E, D})
    equal(T, "3 - 4*a*b", {3 - 4 * a * b, S, E})

    equal(T, '*(6^1, index(address{"a"})^1)', {3 * (a + a), S, E, D})
    equal(T, "6*a", {3 * (a + a), S, E})
    equal(T, '+(1*1, 6*index(address{"a"}))', {1 + 3 * (a + a), S, E, D})
    equal(T, "1 + 6*a", {1 + 3 * (a + a), S, E})

    equal(T, '*(1.5^1, index(address{"a"})^-1)', {3 / (a + a), S, E, D})
    equal(T, "1.5/a", {3 / (a + a), S, E})
    equal(T, '+(1*1, 1.5**(index(address{"a"})^-1))', {1 + 3 / (a + a), S, E, D})
    equal(T, "1 + 1.5/a", {1 + 3 / (a + a), S, E})

    equal(T, '*(3^1, index(address{"a"})^2)', {3 * a^2, "", D})
    equal(T, '*(3^1, index(address{"a"})^2)', {3 * a^2, S, E, D})
    equal(T, '*(3^1, +(1*1, 1*index(address{"a"}))^2)', {3 * (a+1)^2, S, E, D})
  end

  -- tests with references to expressions
  do
    local a, b = R"a,b"
    local S = { b = 3 * (a + 1)^2 }
    equal(T, {b, S, E, D}, {3 * (a + 1)^2, S, E, D})
    equal(T, {5 * b, S, E, D}, {5 * (3 * (a + 1)^2), S, E, D} )
    
    local c, d = R"c,d"
    S.d = 3 + (c * 5)^2
    T:expect_ok(function() E(5 * d, S) end)
    equal(T, "5*(3 + 25*c^2)", {5 * d, S, E})
  end

end


------------------------------------------------------------------------------

