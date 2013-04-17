-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local error, getmetatable, ipairs, pairs, select, rawget, require, setmetatable, type =
      error, getmetatable, ipairs, pairs, select, rawget, require, setmetatable, type

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local index = require("rima.index")
local core = require("rima.core")

local typeinfo = object.typeinfo

module(...)

local set_list = require("rima.sets.list")
local set_ref = require("rima.sets.ref")
local closure = require("rima.closure")
local expression = require("rima.expression")


--- Constructor ----------------------------------------------------------------

local scope = object:new_class(_M, "scope")
scope.proxy_mt = setmetatable({}, scope)


function scope.append(nodes, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    if arg then
      if typeinfo(arg)["scope.node"] then
        nodes[#nodes+1] = arg
      else
        for _, n in ipairs(proxy.O(arg)) do
          nodes[#nodes+1] = n
        end
      end
    end
  end
  return nodes
end


function scope.copy(...)
  return append({}, ...)
end


function scope.new_from_roots(...)
  return proxy:new(object.new(scope, copy(node:new(), ...)), proxy_mt)
end


function scope.copy_from_roots(...)
  return proxy:new(object.new(scope, copy(...)), proxy_mt)
end


function scope.join(...)
  return proxy:new(object.new(scope, copy(...)), proxy_mt)
end


function scope.real_new(mt, top_node, parent, ...)
  if mt then
    setmetatable(mt, scope)
    for k, v in pairs(proxy_mt) do
      if not rawget(mt, k) then mt[k] = v end
    end
  else
    mt = proxy_mt
  end

  local v1
  if not typeinfo(parent)[scope] then
    v1 = parent
    parent = nil
  end

  local s = object.new(scope, copy(top_node or node:new(), parent))

  local S = proxy:new(s, mt)

  if v1 then
    for k, v in pairs(v1) do
      scope.newindex(S, expression.unwrap(k), expression.unwrap(v))
    end
  end

  for i = 1, select("#", ...) do
    local values = select(i, ...)
    if values then
      for k, v in pairs(values) do
        scope.newindex(S, expression.unwrap(k), expression.unwrap(v))
      end
    end
  end

  return S
end


function scope.new_with_metatable(mt, parent, ...)
  return real_new(mt, nil, parent, ...)
end


function scope.new(parent, ...)
  return real_new(nil, nil, parent, ...)
end


function scope.new_local(parent, ...)
  return real_new(nil, node:new{ is_local=true }, parent, ...)
end


-- Indexing --------------------------------------------------------------------

function scope.index(t, k)
  return index:new(t, k)
end


function scope.newindex(t, k, v)
  index.newindex(index:new(t), k, v)
end


function proxy_mt.__index(t, k)
  return expression.wrap(scope.index(t, k))
end


function proxy_mt.__newindex(t, k, v)
  scope.newindex(t, expression.unwrap(k), expression.unwrap(v))  
end


-- Contents --------------------------------------------------------------------

set_default_marker = setmetatable({}, { __repr=function() return "<default>" end, __tostring=function() return "<default>" end })

set_default_thinggy = object:new_class({}, "set_default_thinggy")

function set_default_thinggy:new(set_ref)
  return object.new(self, { set_ref=set_ref })
end

function set_default_thinggy:__repr(format)
  return "default_marker("..lib.repr(self.set_ref, format)..")"
end
set_default_thinggy.__tostring = lib.__tostring


local function copy(n, t)
  local function z(k, v)
    local c = t[k]
    if c then
      if type(c) == "table" and not getmetatable(c) then
        copy(v, c)
      end
    else
      if typeinfo(v.prototype)[scope] or (type(v.value) == "table" and not getmetatable(v.value)) then
        c = {}
        t[k] = c
        copy(v, c)
      else
        t[k] = v.value
      end
    end
  end

  if typeinfo(n)[scope] then
    local S = proxy.O(n)
    for _, n in ipairs(S) do
      copy(n, t)
    end
  else
    if n.value then
      for k, v in pairs(n.value) do z(k, v) end
    end
    local d = n.prototype
    if d then copy(n.prototype, t) end
    d = n.set_prototype
    if d then z(set_default_thinggy:new(d.set), d) end
    d = n.set_default
    if d then z(set_default_thinggy:new(d.set), d) end
  end
end


function scope.contents(s, t)
  t = t or {}
  local S = proxy.O(s)
  for _, n in ipairs(S) do
    copy(n, t)
  end
  return t
end


-- String representation -------------------------------------------------------

local function newlines_or_spaces(s)
  if s:len() <= 100 then
    return s:gsub("%s+", " ")
  else
    return s:gsub("\n", "\n  ")
  end
end


function scope.__repr(s, format)
  s = proxy.O(s)

  if format.format ~= "dump" then
    return "scope"
  end

  local f = {}
  for k, v in pairs(format) do f[k] = v end
  f.depth_limit = f.depth_limit or 3
  f.depth = f.depth or 1
  
  if f.depth > f.depth_limit then 
    return "scope{...}"
  end

  f.depth = f.depth + 1
  local result = {}
  for j, v in ipairs(s) do
    local r = newlines_or_spaces(lib.repr(v, f))
    lib.append(result, ("  %d = %s\n"):format(j, r))
  end
  local prefix = "scope{"
  if s.address then
    prefix = prefix.." address = "..lib.repr(s.address, format)..", "
  end
  if s.prefix then
    prefix = prefix.." prefix = "..lib.repr(s.prefix, format)..", "
  end
  return newlines_or_spaces(prefix.."\n"..lib.concat(result, ",").."}")
end
proxy_mt.__tostring = lib.__tostring


-- Scope nodes -----------------------------------------------------------------

node = object:new_class({}, "scope.node")


function node:new(...)
  local n = {}
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    if arg then
      for k, v in pairs(arg) do
        n[k] = v
      end
    end
  end
  return object.new(node, n)
end


function node:create_element(k, ...)
  local v = self.value
  if not v then
    v = {}  -- scope table?
    self.value = v
  end

  if object.typename(v) == "index" then
    index.newindex(v, k, node:new(index:new(v, k), ...))
  else
    v[k] = node:new(v[k], ...)
  end
end


node.__tostring = lib.__tostring
function node:__repr(format)
  if format.format == "dump" then
    local f, r 
    if typeinfo(self.value).table then
      if format.depth then
        f = "{%s}"
        if format.depth > (format.depth_limit or 2) then
          return "{...}"
        end
      else
        f = "node{%s}"
      end
      local f2 = {}
      for k, v in pairs(format) do f2[k] = v end
      f2.depth = (f2.depth or 0) + 1
      local result = {}
      if self.scope then
        lib.append(result, (" private scope: prefix=%s\n"):format(lib.repr(proxy.O(self.scope).prefix)))
      end
      if self.set_default then
        lib.append(result, (" <set default> = %s\n"):format(newlines_or_spaces(lib.repr(self.set_default, f2))))
      end
      if self.set_prototype then
        lib.append(result, (" <set prototype> = %s\n"):format(newlines_or_spaces(lib.repr(self.set_prototype, f2))))
      end
      for j, v in pairs(self.value) do
        local r = newlines_or_spaces(lib.repr(v, f2))
        lib.append(result, ("  %s = %s\n"):format(lib.repr(j), r))
      end
      r = lib.concat(result, ", ")

    else
      f = ""
      if self.scope then
        f = ("private scope: prefix=%s, "):format(lib.repr(proxy.O(self.scope).prefix))
      end
      if format.depth then
        f = f.."%s"
      else
        f = f.."node(%s)"
      end
    end

    if not r then
      if self.value then
        r = lib.repr(self.value, format)
      elseif self.prototype then
        r = "prototype("..lib.repr(self.prototype, format)..")"
      else
        r = "nil"
      end
    end
    return f:format(r)
  end
  return lib.repr(self.value, format)
end


-- Setting ---------------------------------------------------------------------

local write_ref = object:new_class({}, "scope.write_ref")


function write_ref.new(node, free_indexes)
  free_indexes = free_indexes or set_list:new()
  return proxy:new({ node=node, free_indexes=free_indexes }, write_ref)
end


local function is_literal(i)
  local t = typeinfo(i)
  return t.number or t.string or t["sets.ref"]
end


function write_ref:__index(i)
  self = proxy.O(self)
  local node = self.node

  if is_literal(i) then
    local value = node.value
    return value and value[i] and write_ref.new(value[i], self.free_indexes)
  else
    local set_default = node.set_default
    if set_default then
      return write_ref.new(node.set_default, self.free_indexes + i)
    end
  end
end


function write_ref:__newindex(i, value)
  self = proxy.O(self)
  local node = self.node
  local new_node = {}

  local index_names
  if is_literal(i) then
    index_names = self.free_indexes:copy()
  else
    new_node.set = set_ref:read(i)
    index_names = self.free_indexes + i
  end

  local is_scope = typeinfo(value)[scope]
  local value_or_prototype = is_scope and "prototype" or "value"
  if not core.defined(value) then
    if index_names[1] then
      new_node.value = closure:new(value, index_names)
    else
      new_node[value_or_prototype] = value
    end
  else
    new_node[value_or_prototype] = value
  end

  if is_literal(i) then
    node:create_element(i, new_node)
  else
    if is_scope then
      node.set_prototype = node:new(node.set_prototype, new_node)
    else
      node.set_default = node:new(node.set_default, new_node)
    end
  end
end


function proxy_mt.__write_ref(s)
  return write_ref.new(proxy.O(s)[1])
end


-- Getting ---------------------------------------------------------------------

local read_ref = object:new_class({}, "scope.read_ref")


function read_ref.new(r)
  r.address = r.address or index:new()
  return proxy:new(object.new(scope, r), read_ref)  
end


function read_ref.copy(s)
  local S = proxy.O(s)
  local paths = {}
  for i, n in ipairs(S) do
    paths[i] = node:new({ scope=s }, n)
  end
  paths.address = S.address
  paths.prefix = S.prefix
  return read_ref.new(paths)
end


local function step_path(new_paths, parent, key)
  local used_prototype

  local pv = parent.value
  if pv and core.defined(key) then
    if typeinfo(pv).number_t then
      error("can't index a number", 0)
    end
    local next_node
    if object.typename(pv) == "index" then
      next_node = index:new(pv, key)
    else
      next_node = pv[key]
    end
    if next_node then
      if not typeinfo(next_node)[node] then
        new_paths[#new_paths+1] = node:new({ scope=parent.scope, collected_indexes=parent.collected_indexes, value=next_node, parent=parent })
      else
        if next_node.value then
          new_paths[#new_paths+1] = node:new({ scope=parent.scope, collected_indexes=parent.collected_indexes, parent=parent }, next_node)
        end
        local prototype = next_node.prototype
        if prototype then
          used_prototype = true
          for _, n in ipairs(proxy.O(prototype)) do
            new_paths[#new_paths+1] = node:new(parent, n, { parent=parent, prototype_=prototype, prefix_=new_paths.address })
          end
        end
      end
    end
  end

  local default = parent.set_default
  if default then
    local ci = {}
    if parent.collected_indexes then for i, c in ipairs(parent.collected_indexes) do ci[i] = c end end
    ci[#ci+1] = key
    new_paths[#new_paths+1] = node:new({ scope=parent.scope, collected_indexes=ci, parent=parent }, default)
  end

  local prototype = parent.set_prototype and parent.set_prototype.prototype
  if prototype and not used_prototype then
    local ci = {}
    if parent.collected_indexes then for i, c in ipairs(parent.collected_indexes) do ci[i] = c end end
    ci[#ci+1] = key
    for _, n in ipairs(proxy.O(prototype)) do
      new_paths[#new_paths+1] = node:new(n, { collected_indexes=ci, parent=parent, prototype_=prototype, prefix_=new_paths.address })
    end
  end
end


local function finish_prototypes(new_paths)
  for i, p in ipairs(new_paths) do
    if p.prototype_ then
      p.scope = scope.copy_from_roots(new_paths)
      proxy.O(p.scope).prefix = p.prefix_
    end
  end
end


local function step_paths(r, i)
  r = proxy.O(r)
  local addr = index:new(r.address, i)
  
  if r.prefix and not (type(i) == "string" and i:sub(1,1) == "$") then
    addr = index:new(r.prefix, proxy.O(addr).address)
  end
  local new_paths = { address = addr }
  for _, path in ipairs(r) do
    step_path(new_paths, path, i)
  end
  finish_prototypes(new_paths)
  return new_paths
end


local function return_paths(paths, r)
  if #paths > 0 then
    return read_ref.new(paths), nil, paths.address
  else
    -- if we found nothing, we might have to add a prefix from the first parent scope that'll accept failure
    if r and not proxy.O(r).prefix then
      for _, p in ipairs(proxy.O(r)) do
        if not p.is_local then
          local prefix = proxy.O(p.scope).prefix
          if prefix then
            paths.address = index:new(prefix, proxy.O(paths.address).address)
          end
          break
        end
      end
    end
    return nil, nil, paths.address
  end
end


function read_ref.__index(r, i)
  return return_paths(step_paths(r, i), r)
end


function read_ref.__is_set(r, i)
  r = proxy.O(r)
  local result = {}
  for _, node in ipairs(r) do
    if node.value and node.value[i] then
      result[#result+1] = { node=node, parent=node.parent, value=i }
    elseif node.set_default then
      result[#result+1] = { node=node, parent=node.parent, value=node.set_default.set }
    elseif node.set_prototype then
      result[#result+1] = { node=node, parent=node.parent, value=node.set_prototype.set }
    end
  end
  return result
end


function read_ref.__eval(r, s)
  r = proxy.O(r)

  local a
  local r1v = r[1].value
  if #r == 1 and typeinfo(r1v).index then
    local prefix = proxy.O(r[1].scope or s).prefix
    if prefix then
      a = index:new(prefix, proxy.O(r1v).address)
    else
      a = r1v
    end
  else
    a = r.address
  end
  local results = {}

  for _, path in ipairs(r) do
    local result = path.value
    local eval_scope = path.scope or s

    if not core.defined(result) then
      if typeinfo(result).closure and path.collected_indexes then
        local prefix = proxy.O(eval_scope).prefix
        eval_scope = result:set_args(eval_scope, path.collected_indexes)
        proxy.O(eval_scope).prefix = prefix
      end
      local rtype
      result, rtype = core.eval_to_paths(result, eval_scope)
      result = result or rtype
    end

    if result then
      results[#results+1] = { result, path, path.scope or s }
    end
  end

  local new_paths
  if #results == 1 and typeinfo(results[1][1])[read_ref] then
    local r1 = results[1]
    local result, path, scope = proxy.O(r1[1]), r1[2], r1[3]
    new_paths = { address=result.address or a, prefix=result.prefix or r.prefix }
    for _, p2 in ipairs(result) do
      new_paths[#new_paths+1] = node:new({ scope=scope }, p2)
    end
  else
    new_paths = { address = a, prefix = r.prefix }
    for _, rp in ipairs(results) do
      local result, path, scope = rp[1], rp[2], rp[3]
      if typeinfo(result).read_ref then
        for _, p2 in ipairs(proxy.O(result)) do
          new_paths[#new_paths+1] = node:new({ scope=scope }, p2)
        end
      else
        new_paths[#new_paths+1] = node:new(path, { value=result })
      end
    end
  end

  return return_paths(new_paths)
end


function read_ref:__finish()
  self = proxy.O(self)

  -- We want to collect value and type information, and, if the result is a
  -- table, we have to assemble it over all layers of scope.

  local value, vtype, is_table

  -- Search for values and types, note if we're a table
  for _, v in ipairs(self) do
    v = v.value
    if v then
      local t = typeinfo(v)
      if t.undefined_t then
        vtype = vtype or v
      elseif t.table then
        if not (value or vtype) then is_table = true end
      else
        value = value or v
      end
    end
  end

  -- if it's a table, build it
  if is_table then
    value = {}
    for i, t in ipairs(self) do
      for k, v in pairs(t.value) do
        value[k] = value[k] or v
      end
    end
  end

  return value, vtype, self.address
end


read_ref.__tostring = lib.__tostring
read_ref.__repr = scope.__repr

function proxy_mt.__read_ref(s)
  return read_ref.copy(s)
end


-- EOF -------------------------------------------------------------------------

