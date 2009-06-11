-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local constraint = require("rima.constraint")
local scope = require("rima.scope")
require("rima.public")
require("rima.private")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local a, b = rima.R"a,b"
  local S = scope.create{ ["a,b"]=rima.free() }

  local c
  T:expect_ok(function() c = constraint:new(a + b, "==", b) end)
  T:check_equal(rima.tostring(c), "a + b == b")

  return T:close()
end


-- EOF -------------------------------------------------------------------------
