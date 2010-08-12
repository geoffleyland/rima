-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local constraint2 = require("rima.mp.constraint")
local scope = require("rima.scope")
local mp = require("rima.mp")
local rima = require("rima")

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local x, y = rima.R"x, y"
  local S = rima.scope.new()
  S.c1 = constraint2:new(x + 2*y, "<=", 3)
  S.c2 = constraint2:new(2*x + y, "<=", 3)
  S.objective = x + y
  S.sense = "maximise"
  scope.set(S, { ["x, y"] = rima.positive() })
  local objective, r = mp.solve("lpsolve", S)
  T:check_equal(objective, 2)
  T:check_equal(r.x.p, 1)
  T:check_equal(r.y.p, 1)
  T:check_equal(r.c1.p, 3)
  T:check_equal(r.c2.p, 3)

  return T:close()
end


-- EOF -------------------------------------------------------------------------
