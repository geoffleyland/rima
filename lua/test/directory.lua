-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local lfs = require("lfs")
local series = require("test.series")


------------------------------------------------------------------------------

local function run_one(T, path, options, patterns)
  path = path:gsub("/", "."):gsub("%.lua$", "")

  local run = true
  if patterns and patterns[1] then
    if patterns[1]:sub(1,1) ~= "-" then
      run = false
    end
    for _, p in ipairs(patterns) do
      if p:sub(1,1) == "-" then
        if path:match(p:sub(2)) then
          run = false
        end
      elseif path:match(p) then
        run = true
      end
    end
  end

  if run then
    local test = require(path)
    T:run(test, path)
  end
end


local function _test(path, options, patterns, T)
  for f in lfs.dir(path) do
    if not f:match("^%.") then
      f = path.."/"..f
      local mode = lfs.attributes(f, "mode")
      if mode == "directory" then
        T:run(function(T)
            return _test(f, options, patterns, T)
          end, f:gsub("/", "."))
      elseif f:match("%.lua$") then
        run_one(T, f, options, patterns)
      end
    end
  end
end


local function test(path, options, patterns)
  local T = series:new(options, path:gsub("/", "."))
  _test(path, options, patterns, T)
  return T:close()
end


------------------------------------------------------------------------------

return { test = test }


------------------------------------------------------------------------------

