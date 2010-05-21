--
-- rima's version of strict.lua
-- also found in the lua distribution, in penlight, in idle and discussed
-- here: http://lua-users.org/wiki/DetectingUndefinedVariables
--
-- In addition to behaving like the original, this version overrides
-- module and setfenv to make any new global environments strict.
-- Because I regularly abuse the module system, it has to be a bit more
-- relaxed with module scopes - sometimes indexing object variables
-- looks like a global access.
--

local GLOBAL_SCOPE = getfenv(1)

local function what ()
  local d = debug.getinfo(3, "S")
  return d and d.what or "C"
end

local function make_environment_metatable_strict(E)
  local mt = getmetatable(E)
  if mt == nil then
    mt = {}
    setmetatable(E, mt)
  end

  mt.__declared = mt.__declared or { setfenv=true, module=true }

  if not mt.__newindex then
    mt.__newindex = function (t, n, v)
      -- only check newindex in the global scope
      if t == GLOBAL_SCOPE and not mt.__declared[n] then
        local w = what()
        if w ~= "main" and w ~= "C" then
          error("assign to undeclared variable '"..n.."'", 2)
        end
      end
      mt.__declared[n] = true
      rawset(t, n, v)
    end
  end

  if not mt.__index then
    mt.__index = function (t, n)
      -- only check if the table appears to be the caller's env
      if t == getfenv(2) and not mt.__declared[n] and what() ~= "C" then
        error("variable '"..n.."' is not declared", 2)
      end
      return rawget(t, n)
    end
  end
end

make_environment_metatable_strict(getfenv(1))

local rawsetfenv = setfenv
function setfenv(f, t)
  make_environment_metatable_strict(t)
  if type(f) == "number" then f = f + 1 end
  rawsetfenv(f, t)
end
local mysetfenv = setfenv

local rawmodule = module
function module(...)
  rawmodule(...)
  mysetfenv(2, _M)
end
