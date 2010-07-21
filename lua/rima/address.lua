-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local debug = require("debug")
local assert, error, getmetatable, ipairs, next, rawget, require, select, xpcall =
      assert, error, getmetatable, ipairs, next, rawget, require, select, xpcall

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local undefined_t = require("rima.types.undefined_t")
local number_t = require("rima.types.number_t")
local element = require("rima.sets.element")

module(...)

local scope = require("rima.scope")


-- Utilities -------------------------------------------------------------------

local function is_identifier_string(v)
  return type(v) == "string" and v:match("^[_%a][_%w]*$")
end


-- Constructor -----------------------------------------------------------------

local address = object:new(_M, "address")


local function add_element(a, v)
  a[#a+1] = v
end


function address:new(...)
  local a = {}
  
  for i = 1, select("#", ...) do
    local e = select(i, ...)
    local t = type(e)

    if t == "address" then
      for i, v in ipairs(e) do
        add_element(a, v)
      end
    elseif t ~= "nil" then
      add_element(a, e)
    end
  end

  return object.new(self, a)
end


-- Substrings ------------------------------------------------------------------

function address:sub(i, j)
  local length = #self
  i = i or 1
  j = j or length
  if i < 0 then i = length + i + 1 end
  if j < 0 then j = length + j + 1 end

  local a = {}
  for k = i, j do
    add_element(a, self[k])
  end
  return object.new(address, a)
end


-- Appending -------------------------------------------------------------------

function address.__add(a, b)
  return address:new(a, b)
end


-- Element access --------------------------------------------------------------

function address:value(i)
  return self[i]
end


-- Iterating -------------------------------------------------------------------

local function avnext(a, i)
  i = i + 1
  local v = a[i]
  if v then
    return i, v
  end
end

function address:values()
  return avnext, self, 0
end


-- string representation -------------------------------------------------------

function address:__repr(format)
  if format.dump then
    return ("address{%s}"):format(lib.concat_repr(self, format))
  end

  if not self[1] then return "" end
  local append, repr = lib.append, lib.repr
  local readable = format.readable
  local mode = "s"
  local r = {}

  for _, a in ipairs(self) do
    if element:isa(a) then
      a = element.value(a)
    end
    if is_identifier_string(a) then
      -- for strings that can be identifiers, format as a.b
      if mode ~= "s" then
        mode = "s"
        append(r, "]")
      end
      append(r, ".")
      append(r, repr(a, format))
    else
      -- otherwise format with square braces
      if mode ~= "v" then
        mode = "v"
        append(r, "[")
      else
        -- lua-readable format is [x][y], otherwise it's [x, y] for mathematicans
        append(r, (readable and "][") or ", ")
      end
      if type(a) == "string" then
        -- non-identifier strings are ['1 str.ing']
        append(r, "'", a, "'")
      else
        append(r, repr(a, format))
      end
    end
  end

  if mode == "v" then append(r, "]") end
  return lib.concat(r)
end
__tostring = lib.__tostring


-- evaluation ------------------------------------------------------------------

function address:__eval(S, eval)
  local new_address = {}
  for i, a in ipairs(self) do
    new_address[i] = eval(a, S)
  end
  return object.new(address, new_address)
end


function address:__defined()
  for _, a in ipairs(self) do
    if not core.defined(a) and not element:isa(a) then
      return false
    end
  end
  return true
end


-- resolving -------------------------------------------------------------------

-- resolve an address by working through its indexes recursively
-- returns
--   status - did it resolve to something?
--   value - the value it resolved to
--   base - the base of the expression it finally resolved to
--   address - the address of the expression it finally resolved to
--   collected - any free indexes it might have picked up
function address:resolve(S, current, i, base, eval, collected, used)
  assert(scope.svalue:isa(current))

  -- if we've got something that wants to resolve itself, then give it the
  -- collected indexes
  local mt = getmetatable(current.value)
  if mt and rawget(mt, "__address") then
    -- We only want to bind to the result...
    local status, v, j = xpcall(function() return mt.__address(current.value, S, collected:sub(used or 1), 1, core.bind) end, debug.traceback)
    if not status then
      error(("address: error evaluating '%s%s' as '%s':\n  %s"):
        format(lib.repr(base), lib.repr(self), lib.repr(current), v:gsub("\n", "\n  ")), 0)
    end
    -- ... and then, if there are no more indexes left, we'll evaluate it.
    -- otherwise we leave it as a ref for the next call to index.
    if i > #self then v = eval(v, S) end
    return self:resolve(S, scope.pack(v), i, base, eval, collected, #collected)
  end

  -- Otherwise, move on to the next index
  local a = rawget(self, i)
  if not a then
    return true, current, base, self, collected
  end

  local function fail()
    error(("address: error resolving '%s%s': '%s%s' is not indexable (got '%s' %s)"):
      format(lib.repr(base), lib.repr(self:sub(1, i)), lib.repr(base), lib.repr(self:sub(1, i-1)), lib.repr(current), object.type(current.value)))
  end

  local function index(t, j)
    local k, v
    if element:isa(j) then
      k, v = element.key(j), element.value(j)
    end
    local result
    t = t.value
    if not k then
      result = t[j]
    elseif type(k) == "number" and not t[1] then
      self[i] = v
      result = t[v]
    else
      self[i] = k
      result = t[k]
    end
    return result
  end

  -- What do we do when we come across an expression?
  local function handle_expression(c, j)
    if element:isa(c) then
      c = element.expression(c)
    end
    local new_base = core.bind(c, S)
    local new_address = self:sub(j)

    -- if the base is an index, use its base and glue the two addresses together
    if object.type(new_base) == "index" then
      local C = proxy.O(new_base)
      new_base = C[1]
      new_address = C[2] + new_address
    end

    local function try_current(c)
      local status, r = lib.packs(xpcall(function() return new_address:resolve(S, c, 1, new_base, eval) end, debug.traceback))
      if not status then
        error(("address: error evaluating '%s%s' as '%s%s':\n  %s"):
          format(lib.repr(base), lib.repr(self), lib.repr(new_base), lib.repr(new_address), r[1]:gsub("\n", "\n  ")), 0)
      end
      return r
    end

    -- If the base is ref, we have to try to resolve the address in all the
    -- scopes that the ref occurs in.  We do it manually.  This is a real mess.
    if object.type(new_base) == "ref" then
      local R = proxy.O(new_base)

      -- Get the list of values for this reference
      local RS = scope.find_bound_scope(S, R.scope, R.name)
      local values = scope.find(RS, R.name, "read")

      -- Give up if there's none or it's hidden
      if not values or values[1][1].hidden then
        return false, nil, new_base, new_address, collected
      end

      -- Run through the values, seeing if we can find something
      local results = {}
      for k, v in ipairs(values) do

        -- By now we should have bare refs that don't reference other objects.
        -- This should never happen, but I could be wrong.
        if not core.defined(v[1].value) then
          error(("address: internal error evaluating '%s%s' as '%s%s':\n  Got an undefined expression (%s) when I shouldn't"):
            format(lib.repr(base), lib.repr(self), lib.repr(new_base), lib.repr(new_address), lib.repr(v[1])), 0)
        end

        -- try to resolve the address with this version of the ref as a base
        results[#results+1] = try_current(v[1])
        -- and if we find something good, return it
        if results[#results][1] then
          return lib.unpackn(results[#results])
        end
      end
      -- We found nothing good, return the first thing we found (I think we
      -- could return any of the results.
      return lib.unpackn(results[1])

    else
      -- Otherwise, the new base is not a ref.  I'm not sure this can actually happen --
      -- I'll have to write more tests...
      local new_current = core.eval(new_base, S)
      if not core.defined(new_current) then
        return false, nil, new_base, new_address, collected
      end
      return lib.unpackn(try_current(scope.pack(new_current)))
    end
  end

  -- This is where the function proper starts.
  -- We've got an object (current) and we're trying to index it with a.
  -- How should we treat it?

  -- if it's a ref or an expression, evaluate it (and recursively tidy up the remaining indices)
  if not core.defined(current.value) then
    return handle_expression(current.value, i)

  -- if we're trying to index what has to be a scalar, give up
  elseif number_t:isa(current.value) then
    fail()

  -- if we're trying to index an undefined type, return it and say we didn't get to the end
  elseif undefined_t:isa(current.value) then
    return false, current, base, self, collected

  -- if it's hidden then stop here
  elseif current.hidden then
    return true, current, base, self, collected

  -- handle tables and things we can index just by indexing
  elseif (mt and mt.__index) or type(current.value) == "table" then
    local next = index(current, a)
    local r1
    if next then
      r1 = lib.packn(self:resolve(S, next, i+1, base, eval, collected, used))
      if r1[1] then return lib.unpackn(r1) end
    end
    -- including any values from prototypes
    next = current.prototype
    local r2
    if next then
      local new_collected
      if collected then
        new_collected = collected + a
      else
        new_collected = address:new(a)
      end
      r2 = lib.packn(self:resolve(S, next, i+1, base, eval, new_collected, used))
      if r2[1] then return lib.unpackn(r2) end
    end
    if r1 then
      return lib.unpackn(r1)
    elseif r2 then
      return lib.unpackn(r2)
    else
      return false, nil, base, self
    end

  -- we can't index something that's not a table
  else
    fail()
  end
end


-- EOF -------------------------------------------------------------------------

