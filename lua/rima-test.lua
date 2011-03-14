-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local trace = require("rima.lib.trace")

--------------------------------------------------------------------------------

local strict = true
local patterns = {}
local options = {}

for _, v in ipairs{...} do
  if v == "--show-passes" then
    options.show_passes = true
  elseif v == "--quiet" then
    options.quiet = true
  elseif v == "--dont-show-fails" then
    options.dont_show_fails = true
  elseif v == "--no-strict" then
    strict = false
  elseif v == "--tron" then
    trace.tron()
  else
    patterns[#patterns+1] = v
  end
end

require("test.directory")
if strict then
  require("test.strict")
end

local passed, tests, fails = test.directory.test("rima", "tests", options, patterns)
if passed then
  io.stderr:write("All tests completed successfully\n")
  os.exit(0)
else
  io.stderr:write(("Failed %d/%d tests\n"):format(fails, tests))
  os.exit(fails)
end


-- EOF -------------------------------------------------------------------------
