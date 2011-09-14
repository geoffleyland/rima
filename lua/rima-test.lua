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

local directory = require("test.directory")
local expressions = require("test.expression_files")

if strict then
  require("test.strict")
end

local p1, t1, f1 = directory.test("rima", "tests", options, patterns)
local p2, t2, f2 = expressions.test("../expressions")

local passed = p1 and p2
local tests = t1 + t2
local fails = f1 + f2

if passed then
  io.stderr:write("All tests completed successfully\n")
  os.exit(0)
else
  io.stderr:write(("Failed %d/%d tests\n"):format(fails, tests))
  os.exit(fails)
end


-- EOF -------------------------------------------------------------------------
