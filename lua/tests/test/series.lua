-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local series = require("test.series")


------------------------------------------------------------------------------

return function(T)
  local o2 = {}
  for k, v in pairs(T.options) do o2[k] = v end
  o2.dont_show_fails = true
  local T = series:new(o2, "series")

  local function a(options)
    local o2 = {}
    for k, v in pairs(options) do o2[k] = v end
    if not (options.quiet) then o2.show_passes = true end
    local LT = series:new(o2, "test test")
    local ok, t, f = LT:close()
    T:expect_ok(function() assert(ok == true and t == 0 and f == 0, "empty test") end, "empty test ok")
    LT:test(true, "showing a pass")
    return LT:close()
  end
  T:run(a, "path")

  local LT = series:new(o2, "NOT REAL ERRORS")

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
end


------------------------------------------------------------------------------

