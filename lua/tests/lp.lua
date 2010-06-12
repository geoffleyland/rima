-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")
local constraint2 = require("rima.constraint")
local scope = require("rima.scope")
local lp = require("rima.lp")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local x, y = rima.R"x, y"
  local S = rima.scope.new()
  S.c1 = constraint2:new(x + 2*y, "<=", 3)
  S.c2 = constraint2:new(2*x + y, "<=", 3)
  S.objective = x + y
  S.sense = "maximise"
  scope.set(S, { ["x, y"] = rima.positive() })
  local objective, r = lp.solve("lpsolve", S)
  T:check_equal(objective, 2)
  T:check_equal(r.x.p, 1)
  T:check_equal(r.y.p, 1)
  T:check_equal(r.c1.p, 3)
  T:check_equal(r.c2.p, 3)

  return T:close()
end


-- EOF -------------------------------------------------------------------------
