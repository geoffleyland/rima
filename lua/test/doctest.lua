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
It outputs the same file mostly unchanged, unless you ask it to highlight
syntax, in which case it'll mark things up for 
http://alexgorbatchev.com/wiki/SyntaxHighlighter

If a line ends with "--> expected output", it will check that the output matches
what's expected.
If there's nothing after the "-->" then output will be matched against 
subsequent "-->" lines with nothing to execute.
If the expected output is "/pattern/ other", then the output will be matched
against the pattern, but the "/pattern/" will not be output to markdown, only
"other" will (so you can expect "/3%.14*/", but have "pi" in the documention)
The ">" on the end of the "--" will not be sent to markdown, and any trailing
"--"s on lines with nothing after them will be stripped. 

If a line ends with "--# expected output", it will behave exactly like "-->"
except that it'll expect an error, and the output will be matched against the
error message.
If you don't have "--#" and there's an error, it'll be reported as an
unexpected error.

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

Usage: doctest.lua -sh -i <infile name> -o <outfile name>
If a file name is missing it'll read from stdin or write to stdout.
The -sh option will set up your code blocks for syntax highlighting with
http://alexgorbatchev.com/wiki/SyntaxHighlighter
The exit code of doctest.lua is the number of problems it found.
--]]


--------------------------------------------------------------------------------

-- Process command line arguments (the input and output files)
local infilename = "stdin"
local infile = io.stdin
local outfile = io.stdout
local syntax_highlighting = false

local i = 1
while i <= #arg do
  if arg[i] == "-i" then
    i = i + 1
    infilename = arg[i]
    infile = assert(io.open(arg[i], "r"))
  elseif arg[i] == "-o" then
    i = i + 1
    outfile = assert(io.open(arg[i], "w"))
  elseif arg[i] == "-sh" then
    syntax_highlighting = true
  end
  i = i + 1
end


-- Tricks to capture output.  Of course this doesn't work for io.write yet.
local current_output = ""
local function reset_output()
  current_output = ""
end

local function doctest_print(...)
  for i = 1, select("#", ...) do
    if i > 1 then current_output = current_output.."\t" end
    current_output = current_output..tostring(select(i, ...))
  end
end

local function doctest_io_write(...)
  for _, s in ipairs{...} do
    current_output = current_output..s
  end
end


local function doctest_obj_io_write(o, ...)
  for _, s in ipairs{...} do
    current_output = current_output..s
  end
end


-- Save io.stderr:write

local saved_stderr = io.stderr
local saved_stdout = io.stdout

-- overwrite print, io.write, io.stdout and io.stderr in the
-- GLOBAL (yes, GLOBAL) scope

print = doctest_print
io.write = doctest_io_write
io.stdout = { write = doctest_obj_io_write, read = function(o, ...) return saved_stdout:read(...) end }
io.stderr = { write = doctest_obj_io_write, read = function(o, ...) return saved_stderr:read(...) end }


-- Create a new sandbox environment
local env_start = ""
local function setenv(s)
  env_start = s
end

local function newenv(type)
  local functions =
[[ require print ]]

  local f = loadstring(env_start)
  local e = {}
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


local function process(line)
  local write = true
  local exec = true
  
  local outline = line

  local code = (line):match("^%s%s%s%s(%S.*)$")
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
        if syntax_highlighting then
          outfile:write("<pre><code class='brush: lua'>\n")
        end
      elseif kind == "env" then
        setenv(rest)
        mode = "text"
        exec = false
        write = false
      else
        mode = "lua"
        write = true
        currentenv = newenv(kind)
        if syntax_highlighting then
          outfile:write("<pre><code class='brush: lua'>\n")
        end
      end
    end
    if mode == "lua" and exec then
      if syntax_highlighting then
        outline = outline:gsub("^    ", "")
      end
      -- tidy up the line
      --   get rid of any match output: "--[!>] /blah/
      --   get rid of the ">" or "!" after the --
      --   remove any trailing --
      outline = outline:gsub("%-%-([#>])%s*/.-/", "--%1"):gsub("%-%-[#>]", "--"):gsub("%s*%-%-%s*$", "")
      local behaviour, expected_output = code:match("%-%-([#>])%s?(.*)[\r\n]*")
      local expect_error = false
      if behaviour == "#" then
        expect_error = true
      end

      local code = code:gsub("%-%->.*", ""):gsub("%s*$", ""):gsub("^%s*=%s*(.+)$", "print(%1)")

      -- run the line
      if code and code ~= "" then
        reset_output()
        local f, r = loadstring(code)
        if not f then
          if expect_error then
            io.write(r) 
          else
            report_error(("unexpected error:\n  %s"):format(r:gsub("\n", "\n  ")), line) 
          end
        end
        setfenv(f, currentenv)
        local status, r = pcall(f)
        if not status then
          if expect_error then
            io.write(r) 
          else
            report_error(("unexpected error:\n  %s"):format(r:gsub("\n", "\n  ")), line)
          end
        end
      end

      if expected_output and expected_output ~= "" then
        local actual_output
        if current_output:find("\n") then
          actual_output = current_output:match("(.-)\n")
          current_output = current_output:match(".-\n(.*)")
        else
          actual_output = current_output
          reset_output()
        end

        actual_output = actual_output:gsub("%s+", " ")
        local pattern_expect = expected_output:match("/(.-)/")
        if pattern_expect then
          if not actual_output:match(pattern_expect) then
            report_error(("output mismatch:\n  expected: %s\n  got     : %s")
              :format(pattern_expect, actual_output), line)
          end
        else
          expected_output = expected_output:gsub("%s+", " ")
          if expected_output ~= actual_output then
            report_error(("output mismatch:\n  expected: %s\n  got     : %s")
              :format(expected_output, actual_output), line)
          end
        end
      end
    end
  else
    if syntax_highlighting then
      if mode == "lua" then
        outfile:write("</code></pre>\n")
      end
      outline = outline:gsub("`(.-)`", "<code class='brush: lua inline: true'>%1</code>")
    end
      
    mode = "text"
  end
  
  if write then
    outfile:write(outline, "\n")
  end
end

local error_count = 0

for l in infile:lines() do
  local s, m = pcall(process, l)
  if not s then
    error_count = error_count + 1
    saved_stderr:write(m)
  end
  linenumber = linenumber + 1
end

infile:close()
outfile:close()

os.exit(error_count)


-- EOF -------------------------------------------------------------------------
