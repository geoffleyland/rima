-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information


--------------------------------------------------------------------------------

local patterns = {}
local show_passes = false
local strict = true

for _, v in ipairs{...} do
  if v == "--show-passes" then
    show_passes = true
  elseif v == "--no-strict" then
    strict = false
  else
    patterns[#patterns+1] = v
  end
end

require("test.directory")
if strict then
  require("test.strict")
end

local passed, tests, fails = test.directory.test("rima", "tests", show_passes, patterns)
if passed then
  io.stderr:write("All tests completed successfully\n")
  os.exit(0)
else
  os.exit(fails)
end


-- EOF -------------------------------------------------------------------------
