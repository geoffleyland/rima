-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local assert, error = assert, error

local series = require("test.series")

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)

  local function a(show_passes)
    local LT = series:new("test test", not show_passes)
    local ok, t, f = LT:close()
    T:expect_ok(function() assert(ok == true and t == 0 and f == 0, "empty test") end, "empty test ok")
    LT:test(true, "showing a pass")
    return LT:close()
  end
  T:run(a)

  local LT = series:new("NOT REAL ERRORS", false)

  -- series:test()    
  T:expect_ok(function() LT:test(true, "description", "message") end, "series:test")
  T:expect_ok(function() LT:test(false, "THIS IS NOT A FAIL", "THIS IS NOT A FAIL") end, "series:test")
  T:test(LT:test(true, "description", "message"), "series:test")
  T:test(not LT:test(false, "THIS IS NOT A FAIL", "THIS IS NOT A FAIL"), "series:test")

  -- series:check_equal
  T:expect_ok(function() LT:check_equal("a", "b", "THIS IS NOT A FAIL") end, "series:check_equal")
  T:expect_ok(function() LT:check_equal("a", "a", "THIS IS NOT A FAIL") end, "series:check_equal")
  T:expect_ok(function() LT:check_equal(1, 2, "THIS IS NOT A FAIL") end, "series:check_equal")
  T:expect_ok(function() LT:check_equal(1, 1, "THIS IS NOT A FAIL") end, "series:check_equal")

  T:test(not LT:check_equal("a", "b", "THIS IS NOT A FAIL"), "series:check_equal")
  T:test(LT:check_equal("a", "a", "THIS IS NOT A FAIL"), "series:check_equal")
  T:test(not LT:check_equal(1, 2, "THIS IS NOT A FAIL"), "series:check_equal")
  T:test(LT:check_equal(1, 1, "THIS IS NOT A FAIL"), "series:check_equal")

  -- series:expect_error
  T:expect_ok(function() LT:expect_error(function() error("an error!") end, "another_error") end, "series:expect_error")
  T:expect_ok(function() LT:expect_error(function() error("an error!") end, "an error!") end, "series:expect_error")
  T:expect_ok(function() LT:expect_error(function() end, "no error") end, "series:expect_error")

  T:test(not LT:expect_error(function() error("an error!") end, "another_error"), "series:expect_error")
  T:test(LT:expect_error(function() error("an error!") end, "an error!"), "series:expect_error")
  T:test(not LT:expect_error(function() end, "no error"), "series:expect_error")
  

  return T:close()
end


-- EOF -------------------------------------------------------------------------

