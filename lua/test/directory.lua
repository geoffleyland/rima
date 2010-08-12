-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local ipairs, require = ipairs, require

local lfs = require("lfs")
local series = require("test.series")

module(...)

--------------------------------------------------------------------------------

local function run_one(T, path, options, patterns)
  path = path:gsub("/", "."):gsub("%.lua$", "")

  local run = true
  if patterns and #patterns > 0 then
    if patterns[1]:sub(1,1) ~= "-" then
      run = false
    end
    for _, p in ipairs(patterns) do
      if p:sub(1,1) == "-" then
        if path:match(p:sub(2)) then
          run = false
        end
      else
        if path:match(p) then
          run = true
        end
      end
    end
  end

  if run then
    local m = require(path)
    T:run(m.test)
  end
end


function test(name, path, options, patterns)
  local T = series:new(name, options)

  for f in lfs.dir(path) do
    if not f:match("^%.") then
      f = path.."/"..f
      local mode = lfs.attributes(f, "mode")
      if mode == "directory" then
        T:run(function(options) return test(f:gsub("/", "."), f, options, patterns) end)
      elseif f:match("%.lua$") then
        run_one(T, f, options, patterns)
      end
    end
  end

  return T:close()
end


-- EOF -------------------------------------------------------------------------
