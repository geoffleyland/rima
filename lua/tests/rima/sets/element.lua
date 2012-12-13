-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local element = require("rima.sets.element")

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")


------------------------------------------------------------------------------

return function(T)
  local function N(...) return element:new(...) end
  local E = core.eval
  local D = lib.dump

  -- Constructors
  T:test(object.typeinfo(N()).element, "typeinfo(element:new()).element")
  T:check_equal(object.typename(N()), "element", "typename(element:new()) == 'element'")

  do
    local it
    T:expect_ok(function() it = N(nil, "key", 13) end)
    T:check_equal(it + 17, 30)
    T:check_equal(7 * it, 91)
    T:check_equal(core.defined(it), true)
  end

  do
    local a = index:new().a
    local S = { a = N(nil, "key", 13) }
    T:check_equal(E(a + 19, S), 32)
    T:check_equal(D(E(a + 19, S)), 32)
  end
end


------------------------------------------------------------------------------

