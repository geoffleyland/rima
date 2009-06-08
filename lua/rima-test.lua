-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("tests.series")

--------------------------------------------------------------------------------

test_names =
{
  "series_test",
  "object",
  "proxy",
  "args",
  "types.undefined_t",
  "types.number_t",
}


--------------------------------------------------------------------------------

function test(prefix, names, show_passes, patterns)
  local T = tests.series:new("rima", show_passes)

  for _, t in ipairs(names) do
    local run = false
    if not patterns or #patterns == 0 then
      run = true
    else
      for _, p in ipairs(patterns) do
        if t:match(p) then
          run = true
          break
        end
      end
    end
    
    if run then
      local m = require(prefix.."."..t)
      T:run(m.test)
    end
  end
  
  return T:close()
end


--------------------------------------------------------------------------------

local patterns = {}
local show_passes = false

for _, v in ipairs{...} do
  if v == "show_passes" then
    patterns = true
  else
    patterns[#patterns+1] = v
  end
end

test("tests", test_names, show_passes, patterns)

-- EOF -------------------------------------------------------------------------
