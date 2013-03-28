-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local lfs = require("lfs")

local lib = require("rima.lib")
local scope = require("rima.scope")
local core = require("rima.core")
local rima = require("rima")
local interface = require("rima.interface")


--------------------------------------------------------------------------------

local formats =
{
  P = { name = "plain", f = {}},
  D = { name = "dump",  f = {format="dump"}},
  L = { name = "LaTeX", f = {format="latex"}},
}


--------------------------------------------------------------------------------

local function load_line(infile_name, line_number, whole_line, line, start, type)
  local expression_string = line:gsub("%$([_%a][_%w]*)", 'rima.R"%1"')
  local f, message = loadstring("return function"..start..expression_string.." end")
  if not f then
    io.stderr:write(("%s:%d: Couldn't load %s: %s\n  %s\n"):
      format(infile_name, line_number, type, message, whole_line))
  end
  return f
end


--------------------------------------------------------------------------------

local function test_file(infile, outfile, infile_name)
  local tests, fails = 0, 0

  local base_exp, exp
  local was_scope_line
  local S

  local line_number = 0
  for l in infile:lines() do
    line_number = line_number + 1
    local key, line = l:match("^(.)%s*(.*)%s*$")

    if was_scope_line and (not key or key:upper() ~= "S") then
      exp = interface.eval(base_exp, S)
    end

    if key == "E" then                          -- read a new expression
      local f = load_line(infile_name, line_number, l, line, "(rima) return ", "expression")
      if not f then
        base_exp, exp = nil
      else
        local ok
        base_exp = f()(rima)
        exp = base_exp
      end
      outfile:write(l, "\n")

    elseif key and key:upper() == "S" then      -- Add values to a scope
      if key == "S" then
        S = scope.new()
      end
      if #line > 0 then
        local f = load_line(infile_name, line_number, l, line, "(rima, S) S.", "scope value")
        if not f then
          base_exp, exp = nil
        else
          f()(rima, S)
        end
      end
      outfile:write(l, "\n")

    elseif formats[key] then                    -- compare output
      tests = tests + 1
      local r = exp and lib.repr(exp, formats[key].f)
      if not exp or r == line then
        outfile:write(l, "\n")
      else
        io.stderr:write(("%s:%d: %s output mismatch:\n  expected '%s'\n  got      '%s'\n"):
          format(infile_name, line_number, formats[key].name, line, r))
        outfile:write(key, "     ", r, "\n")
        fails = fails + 1
      end
    
    else
      outfile:write(l, "\n")
    end
    was_scope_line = key and key:upper() == "S"
  end

  return fails == 0, tests, fails
end


--------------------------------------------------------------------------------

local function directory(path)
  local total_tests, total_fails = 0, 0

  for f in lfs.dir(path) do
    if not f:match("^%.") then
      f = path.."/"..f
      local mode = lfs.attributes(f, "mode")
      if mode == "directory" then
        T:run(function(options) return test(f:gsub("/", "."), f, options, patterns) end)
      elseif f:match("%.txt$") and not f:match("%.results%.txt$") then
        local infile = io.open(f, "r")
        local f2 = f:gsub("%.txt$", ".results.txt")
        local outfile = io.open(f2, "w")
        local _, tests, fails = test_file(infile, outfile, f)
        infile:close()
        outfile:close()
        if fails == 0 then
          os.remove(f2)
        end
        total_tests = total_tests + tests
        total_fails = total_fails + fails
        io.stderr:write(("%s: %s - passed %d/%d tests\n"):format(
                        f, fails == 0 and "pass" or "*****FAIL*****",
                        tests - fails, tests))
      end
    end
  end

  io.stderr:write(("%s: %s - passed %d/%d tests\n"):format(
                  path, total_fails == 0 and "pass" or "*****FAIL*****",
                  total_tests - total_fails, total_tests))
  return total_fails == 0, total_tests, total_fails
end


--------------------------------------------------------------------------------

return { test=directory }


-- EOF -------------------------------------------------------------------------

