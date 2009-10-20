-- doctest.lua
-- (c) Copyright 2009 Incremental IP Ltd.
-- See http://www.incremental.co.nz/projects/lua.html

--[[
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

--[[
doctest.lua checks Lua snippets embedded in markdown files.

doctest.lua reads a markdown (text?) file, looking for lines starting with
four spaces (markdown marks these up as code).  It tries to execute these
code blocks as the Lua command line would (local variables don't work),
and reports any errors.
Each block is executed in a new environment, so you'll have to redefine any
variables at the start of each block.
It outputs the same file mostly unchanged.

If a line ends with "--> expected output", it will check that the output matches
what's expected.  At the moment it only captures print though.

If a line contains "    --! env <initialisation commands>" then it will
initialise the environment for each block with those commands.
The line will not be included in the output file.
Note that require puts things into the global table of its own environment,
not the new block environment, so you'll have to go
"package = require('package')" rather than just "require('package')"


If the first line in a block is "    --! ignore" then doctest doesn't try to
execute the block and the "   --! ignore" line won't be output.

If the first line in a block is "    --! continue" then the environment from
the last block will be recycled, and you'll be able to use variables from that
block.

Usage: doctest.lua -i <infile name> -o <outfile name>
If a file name is missing it'll read from stdin or write to stdout.
--]]


--------------------------------------------------------------------------------

-- Process command line arguments (the input and output files)
local infilename = "stdin"
local infile = io.stdin
local outfile = io.stdout

local i = 1
while i <= #arg do
  if arg[i] == "-i" then
    i = i + 1
    infilename = arg[i]
    infile = assert(io.open(arg[i], "r"))
  elseif arg[i] == "-o" then
    i = i + 1
    outfile = assert(io.open(arg[i], "w"))
  end
  i = i + 1
end


-- Tricks to capture output.  Of course this doesn't work for io.write yet.
local print_result
local function myprint(...)
  print_result = ""
  for i = 1, select("#", ...) do
    if i > 1 then print_result = print_result.."\t" end
    print_result = print_result..tostring(select(i, ...))
  end
end


-- Create a new sandbox environment
local env_start = ""
local function setenv(s)
  env_start = s
end

local function newenv(type)
  local functions =
[[ require ]]

  local f = loadstring(env_start)
  local e = { print = myprint }
  for w in functions:gmatch("(%S+)") do
    e[w] = _G[w]
  end
  setfenv(f, e)
  f()
  return e
end


local linenumber = 1
local currentenv
local mode = "text"

local function report_error(e, l)
  error(("%s: %s:%d: %s\nline:\n%s\n\n"):format(arg[0], infilename, linenumber, e, l), 0)
end


local function process(l)
  local write = true
  local exec = true

  local code = (l):match("^%s%s%s%s(%S.*)$")
  if code then
    if mode == "text" then
      local kind, rest = code:match(".*%-%-!%s*(%S*)%s*(.*)")
      if kind == "ignore" then
        mode = "ignore"
        write = false
      elseif kind == "continue" then
        if not currentenv then
          report_error("continue with no earlier block", l)
        end
        mode = "lua"
        exec = false
        write = false
      elseif kind == "env" then
        setenv(rest)
        mode = "text"
        exec = false
        write = false
      else
        mode = "lua"
        write = true
        currentenv = newenv(kind)
      end
    end
    if mode == "lua" and exec then
      local output = code:match("%-%->%s*(.*)[\r\n]*")
      local code = code:gsub("%-%->.*", ""):gsub("%s*$", ""):gsub("^%s*=%s*(.+)$", "print(%1)")
      local f, r = loadstring(code)
      if not f then
        report_error(("error:\n  %s"):format(r:gsub("\n", "\n  ")), l) 
      end
      setfenv(f, currentenv)
      local status, r = pcall(f)
      if not status then
        report_error(("error:\n  %s"):format(r:gsub("\n", "\n  ")), l)
      end
      if output then
        output = output:gsub("%s+", " ")
        print_result = print_result:gsub("%s+", " ")
        if output ~= print_result then
          report_error(("output mismatch:\n  expected: %s\n  got     : %s"):format(output, print_result), l)
        end
      end
    end
  else
    mode = "text"
  end
  
  if write then
    outfile:write(l, "\n")
  end
end

for l in infile:lines() do
  local s, m = pcall(process, l)
  if not s then
    io.stderr:write(m)
  end
  linenumber = linenumber + 1
end

infile:close()
outfile:close()


-- EOF -------------------------------------------------------------------------
