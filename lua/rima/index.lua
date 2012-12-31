-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local trace = require("rima.lib.trace")
local lib = require("rima.lib")
local address = require("rima.address")
local core = require("rima.core")
local element = require("rima.sets.element")
local undefined_t = require("rima.types.undefined_t")
local number_t = require("rima.types.number_t")
local expression = require("rima.expression")

local typeinfo = object.typeinfo


------------------------------------------------------------------------------

local index = object:new_class(_M, "index")
local proxy_mt = setmetatable({}, index)
index.proxy_mt = proxy_mt
expression:copy_operators(proxy_mt)


function index:new(base, ...)
  local a
  if typeinfo(base).index then
    base = proxy.O(base)
    a = address:new(base.address, ...)
    base = base.base
  else
    a = address:new(...)
  end

  return proxy:new(object.new(self, { base=base, address=a }), proxy_mt)
end


function index:bind(base)
  return index:new(base, proxy.O(self).address)
end


function index:set(base, value)
  local a = proxy.O(self).address
  local i = index:new(base, a:sub(1, -2))
  i[a:value(-1)] = value
end


function index:is_identifier(i)
  local I = proxy.O(i)
  return not I.base and I.address:is_identifier()
end


function index:identifier(i)
  local I = proxy.O(i)
  return lib.repr(I.address:sub(1,1))
end


------------------------------------------------------------------------------

proxy_mt.__tostring = lib.__tostring
function proxy_mt.__repr(i, format)
  local I = proxy.O(i)
  local base, addr = I.base, I.address
  local bt = typeinfo(base)
  if format.format == "dump" then
    if base then
      return ("index(%s, %s)"):format(lib.repr(base, format), lib.repr(addr, format))
    else
      return ("index(%s)"):format(lib.repr(addr, format))
    end
  elseif format.scopes and bt.scope then
    return lib.repr(base, format)..lib.repr(addr, format)
  elseif base and (not bt.scope) and (not bt.table) then
    format.continued_address = true
    local lra = lib.repr(addr, format)
    format.continued_address = false
    return lib.repr(base, format)..lra
  else
    return lib.repr(addr, format)
  end
end


------------------------------------------------------------------------------

function proxy_mt.__index(r, i)
  return index:new(r, i)
end


local function extended_index(t, ii)
  -- we have to call __index ourselves, because scope's __index returns several values.
  local f = lib.getmetamethod(t, "__index")
  if f then
    return f(t, ii)
  else
    return t[ii]
  end
end


local function do_index(t, i, j, address)

  if typeinfo(t).number then
    error("can't index a number", 0)
  end
  if typeinfo(i).element then

    local k = element.key(i)
    local kvalue, ktype, kaddr = extended_index(t, k)

    local v = element.value(i)
    local vvalue, vtype, vaddr
    if lib.repr(v):sub(1,5) ~= "table" then
      vvalue, vtype, vaddr = extended_index(t, v)
    end

    if vvalue then
      address:set(j+1, v)
      return vvalue, vtype, vaddr
    end

    if kvalue then
      address:set(j+1, k)
      return kvalue, ktype, kaddr
    end

    return nil, vtype or ktype, vaddr or kaddr
  else
    return extended_index(t, i)
  end
end


local function safe_index(t, i, base, address, length, depth, allow_undefined)
  if not allow_undefined and typeinfo(i).index and not index:is_identifier(i) then
    local a2 = address:sub(1, length)
    error(("error indexing '%s' as '%s': variable indexes must be unbound identifiers"):format(lib.repr(a2), lib.repr(a2+i)), depth+1)
  end
  if not t then return end
  local value, vtype, vaddr
--  local status, message = xpcall(function() value, vtype, vaddr = do_index(t, i, length, address) end, debug.traceback)
  local status, message = pcall(function() value, vtype, vaddr = do_index(t, i, length, address) end)
  if not status then
    local a2 = address:sub(1, length)
    if base then
      local ba = base
      while ba and object.typename(ba) ~= "address" do
        ba = proxy.O(ba).address
      end
      a2 = ba + a2
    end
    if message:sub(1, 11) == "can't index" then
      error(("error indexing '%s' as '%s': %s"):format(lib.repr(a2), lib.repr(a2+i), message), depth+1)
    else
      local f = lib.getmetamethod(t, "__finish")
      if f then
        t = f(t)
      end
      local tt = object.typename(t)
      local article = ""
      if tt ~= "nil" then
        article = tt:sub(1,1):match("[aeiouAEIOU]") and " an" or " a"
      end
      error(("error indexing '%s' as '%s': can't index%s %s: (%s)"):format(lib.repr(a2), lib.repr(a2+i), article, tt, message), depth+1)
    end
  end
  return value, vtype, vaddr
end


local function newindex_check(t, i, value, base, a, depth)
  if typeinfo(i).index and not index:is_identifier(i) then
    local a2 = address:new(a)
    for j, v in proxy.O(i).address:values() do
      a2:append(v)
      t = safe_index(t, v, base, a2, -1, depth+1)
    end
  else
    t = safe_index(t, i, base, a, -1, depth+1)
  end
  if typeinfo(value).table then
    for k, v in pairs(value) do
      newindex_check(t, k, v, base, a+i, depth+1)
    end
  end
end


local function create_table_element(current, i)
  local next = current[i]
  if not next then
    current[i] = {}
    next = current[i]
  end
  return next
end


local function newindex_set(current, i, value)
  if typeinfo(i).index and not index:is_identifier(i) then
    local a2 = proxy.O(i).address
    local a = a2:sub(1,-2)
    i = a2:value(-1)
    for j, v in a:values() do
      current = create_table_element(current, v)
    end
  end

  if typeinfo(value).table then
    current = create_table_element(current, i)
    for k, v in pairs(value) do
      newindex_set(current, k, v)
    end
  else
    current[i] = value
  end
end


function proxy_mt.__newindex(r, i, value)
  local I = proxy.O(r)
  local base, a = I.base, I.address
  if not base then
    local ar = lib.repr(a+i)
    error(("error setting '%s' to '%s': '%s' isn't bound to a table or scope"):format(ar, lib.repr(value), ar), 2)
  end
  
  -- Check it's a legitimate address
  local f = lib.getmetamethod(base, "__read_ref")
  local current = (f and f(base)) or base
  for j, v in a:values() do
    current = safe_index(current, v, base, a, j-1, 2)
  end
  newindex_check(current, i, value, base, a, 2)

  -- Now go ahead and do the assignment, creating intermediate tables as we go
  local f = lib.getmetamethod(base, "__write_ref")
  local current = (f and f(base)) or base
  for j, v in a:values() do
    current = create_table_element(current, v)
  end

  local status, message = xpcall(function() newindex_set(current, i, value) end, debug.traceback)
  if not status then
    error(("error assigning setting '%s' to '%s':\n  %s"):
      format(lib.repr(a+i), lib.repr(value), message:gsub("\n", "\n  ")), 2)
  end
end


------------------------------------------------------------------------------

function index.resolve(r, s)
  local I = proxy.O(r)
  local addr, base
  addr = core.eval(I.address, s)
  base = I.base
  if base then
    local addr2
    base, addr2 = core.eval_to_paths(I.base, s)
    if addr2 then base = addr2 end
  end

  local current, ctype = base or s

  local f = lib.getmetamethod(current, "__read_ref")
  if f then current = f(current) end
  local j = 1
  for _, v in addr:values() do
    local addr2
    if trace.on then trace.enter("indx", 1, nil, v, current) end

    current, ctype, addr2 = safe_index(current, v, base, addr, j-1, 3, true)
    local new_base = current or addr2
    if typeinfo(new_base).index then
      base = new_base
      addr = addr:sub(j+1)
      j = 0
    end

    if trace.on then trace.leave("indx", 1, v, current, ctype, addr2) end
    if not current then break end

    current, ctype, addr2 = core.eval_to_paths(current, s)
    if addr2 then
      base = addr2
      addr = addr:sub(j+1)
      j = 0
    end

    if not current then break end
    j = j + 1
  end

  addr = index:new(base, addr)
  return current or addr, ctype, addr
end


function proxy_mt.__eval(e, s)
  return index.resolve(e, s)
end


------------------------------------------------------------------------------

function proxy_mt.__list_variables(i, s, list)
  local I = proxy.O(i)
  local current, addr = I.base or s, I.address
  local read_f = lib.getmetamethod(current, "__read_ref")
  if read_f then current = read_f(current) end
  local query_f = lib.getmetamethod(current, "__is_set")

  if not query_f then
    local name = lib.repr(i)
    list[name] = { name=name, ref=i }
    return
  end

  -- first, run through all the indexes, collecting information about all the possible paths
  local indexes = {}
  local last
  for i, v in addr:values() do
    local r = query_f(current, v)
    if #r == 0 then
      last = i
      break
    end
    indexes[#indexes+1] = r
    current = current[v]
  end

  local result_index = index:new()
  local result_sets = {}

  -- if we managed to trace a path, work backwards through it from the successful end, collecting indices and sets
  if #indexes > 0 then
    local addr2 = {}
    addr2[#indexes] = indexes[#indexes][1].value
    local search_for = indexes[#indexes][1].parent
    for k = #indexes-1, 1, -1 do
      local index = indexes[k]
      for j, s in ipairs(index) do
        if s.node == search_for then
          addr2[k] = s.value
          search_for = s.parent
          break
        end
      end
    end

    -- now run forwards through that creating an index
    for _, i in ipairs(addr2) do
      if typeinfo(i)["sets.ref"] then
        result_index = result_index[index:new(nil, i.names[1])]
        result_sets[#result_sets+1] = i
      else
        result_index = result_index[i]
      end
    end
  end

  -- and if we need to, tag on any remaining indexes
  if last then
    for i = last, #addr do
      result_index = result_index[addr:value(i)]
    end
  end

  local name = lib.repr(result_index)
  list[name] = { name=name, ref=result_index, sets=result_sets }
end


------------------------------------------------------------------------------

function index.__diff(i, v)
  local I = proxy.O(i)
  local V = proxy.O(v)
  if I.base == V.base and I.address == V.address then
    return 1
  else
    return 0
  end
end


------------------------------------------------------------------------------

function index.R(names)
  local results = {}
  for n in names:gmatch("[%a_][%w_]*") do
    results[#results+1] = index:new(nil, n)
  end
  return unpack(results)
end


function index.define(names, depth)
  local env = getfenv(2 + depth or 0)
  for n in names:gmatch("[%a_][%w_]*") do
    env[n] = index:new(nil, n)
  end
end


------------------------------------------------------------------------------

return index

------------------------------------------------------------------------------

