-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("test.directory")

--------------------------------------------------------------------------------

local patterns = {}
local show_passes = false

for _, v in ipairs{...} do
  if v == "show_passes" then
    show_passes = true
  else
    patterns[#patterns+1] = v
  end
end

if test.directory.test("rima", "tests", show_passes, patterns) then
  io.stderr:write("All tests completed successfully")
  os.exit(0)
else
  os.exit(1)
end

-- EOF -------------------------------------------------------------------------
