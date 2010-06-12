-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, require = ipairs, require

local lfs = require("lfs")
local series = require("test.series")

module(...)

--------------------------------------------------------------------------------

local function run_one(T, path, show_passes, patterns)
  path = path:gsub("/", "."):gsub("%.lua$", "")

  local to_run = 1
  local run = 0
  if not patterns or #patterns == 0 then
    to_run = 0
  else
    for _, p in ipairs(patterns) do
      if p:sub(1,1) == "-" then
        to_run = 0
        if path:match(p:sub(2)) then
          run = -1
          break
        end
      else
        if path:match(p) then
          run = 1
          break
        end
      end
    end
  end

  if run >= to_run then
    local m = require(path)
    T:run(m.test)
  end
end


function test(name, path, show_passes, patterns)
  local T = series:new(name, show_passes)

  for f in lfs.dir(path) do
    if not f:match("^%.") then
      f = path.."/"..f
      local mode = lfs.attributes(f, "mode")
      if mode == "directory" then
        T:run(function(show_passes) return test(f:gsub("/", "."), f, show_passes, patterns) end)
      elseif f:match("%.lua$") then
        run_one(T, f, show_passes, patterns)
      end
    end
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------
