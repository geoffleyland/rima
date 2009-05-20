-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local object = require("rima.object")
local tests = require("rima.tests")

module(...)

-- Base Value Type -------------------------------------------------------------

local value = object:new(_M, "value")


-- String representation -------------------------------------------------------

function value:__tostring()
  return "value"
end


-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = tests.series:new(_M, show_passes)

  T:test(isa(value:new(), value), "isa(value:new(), value)")
  T:equal_strings(type(value:new()), 'value', "type(value:new()) == 'value'")
  T:equal_strings(value:new(), 'value', "tostring(value:new()) == 'value'")
  
  return T:close()
end


-- EOF -------------------------------------------------------------------------

