-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local core = require("rima.core")

local setmetatable = setmetatable

local series = require("test.series")
local lib = require("rima.lib")

module(...)


-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)

  local E = core.eval
  local D = lib.dump
  local DE = function(...) return D(E(...)) end

  -- literals --------------------------
  -- evaluating
  T:check_equal(DE(1), 1)
  T:check_equal(DE("a"), '"a"')
  T:check_equal(DE(nil), "nil")
  
  -- defined
  T:check_equal(core.defined(1), true)
  T:check_equal(core.defined("a"), true)
  T:check_equal(core.defined(nil), true)

  -- objects ---------------------------
  do
    local o1 = setmetatable({}, { __eval = function(e) return 17 end })
    T:check_equal(DE(o1), 17)
    T:check_equal(core.defined(o1), false)

    local o2 = setmetatable({}, { __eval = function(e) return 17 end , __defined = function(e) return true end })
    T:check_equal(core.defined(o2), true)
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------

