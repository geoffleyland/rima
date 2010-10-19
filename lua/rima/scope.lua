-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error, getmetatable, ipairs, pairs, select, rawget, require, setmetatable =
      error, getmetatable, ipairs, pairs, select, rawget, require, setmetatable

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local index = require("rima.index")
local core = require("rima.core")
local undefined_t = require("rima.types.undefined_t")
local number_t = require("rima.types.number_t")

module(...)

local set_list = require("rima.sets.list")
local set_ref = require("rima.sets.ref")
local element = require("rima.sets.element")
local closure = require("rima.closure")


--- Constructor ----------------------------------------------------------------

local scope = object:new(_M, "scope")
scope.proxy_mt = setmetatable({}, scope)


function scope.append(nodes, ...)
  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    if arg then
      if type(arg) == "scope.node" then
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


function scope.new_with_metatable(mt, parent, ...)
  if mt then
    setmetatable(mt, scope)
    for k, v in pairs(proxy_mt) do
      if not rawget(mt, k) then mt[k] = v end
    end
  else
    mt = proxy_mt
  end

  local v1
  if type(parent) ~= "scope" then
    v1 = parent
    parent = nil
  end

  local s = object.new(scope, copy(node:new(), parent))

  local S = proxy:new(s, mt)

  if v1 then
    for k, v in pairs(v1) do
      S[k] = v
    end
  end

  for i = 1, select("#", ...) do
    local values = select(i, ...)
    if values then
      for k, v in pairs(values) do
        S[k] = v
      end
    end
  end

  return S
end


function scope.new(parent, ...)
  return new_with_metatable(nil, parent, ...)
end


-- Indexing --------------------------------------------------------------------

function proxy_mt.__index(s, i)
  return index:new(s, i)
end


function proxy_mt.__newindex(s, i, value)
  index:new(s)[i] = value
end


-- Contents --------------------------------------------------------------------

set_default_marker = setmetatable({}, { __repr=function() return "<default>" end, __tostring=function() return "<default>" end })

set_default_thinggy = object:new({}, "set_default_thinggy")

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
      if scope:isa(v.prototype) or (type(v.value) == "table" and not getmetatable(v.value)) then
        c = {}
        t[k] = c
        copy(v, c)
      else
        t[k] = v.value
      end
    end
  end

  if scope:isa(n) then
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

node = object:new({}, "scope.node")


function node:new(...)
  local n = {}
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    if arg then
      for k, v in pairs(arg) do
        if k == "value_or_prototype" then
          if scope:isa(v) then
            k = "prototype"
          else
            k = "value"
          end
        end
        n[k] = v
      end
    end
  end

  return object.new(node, n)
end


function node:create_element(index, ...)
  local v = self.value
  if not v then
    v = {}  -- scope table?
    self.value = v
  end

  v[index] = node:new(v[index], ...)
end


node.__tostring = lib.__tostring
function node:__repr(format)
  if format.format == "dump" then
    local f, r 
    if type(self.value) == "table" then
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

local write_ref = object:new({}, "scope.write_ref")


function write_ref.new(node, free_indexes)
  free_indexes = free_indexes or set_list:new()
  return proxy:new({ node=node, free_indexes=free_indexes }, write_ref)
end


local function is_literal(i)
  local t = type(i)
  return t == "number" or t == "string" or t == "sets.ref"
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

  if not core.defined(value) then
    if index_names[1] then
      new_node.value = closure:new(value, index_names)
    else
      new_node.value_or_prototype = value
    end
  else
    new_node.value_or_prototype = value
  end

  if is_literal(i) then
    node:create_element(i, new_node)
  else
    if scope:isa(value) then
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

local read_ref = object:new({}, "scope.read_ref")


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


local function step_path(new_paths, parent, index)
  local used_prototype
  
  if parent.value and core.defined(index) then
    if number_t:isa(parent.value) then
      error("can't index a number", 0)
    end
    local next_node = parent.value[index]
    if next_node then
      if not node:isa(next_node) then
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
    ci[#ci+1] = index
    new_paths[#new_paths+1] = node:new({ scope=parent.scope, collected_indexes=ci, parent=parent }, default)
  end

  local prototype = parent.set_prototype and parent.set_prototype.prototype
  if prototype and not used_prototype then
    local ci = {}
    if parent.collected_indexes then for i, c in ipairs(parent.collected_indexes) do ci[i] = c end end
    ci[#ci+1] = index
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
  local addr = r.address[i]
  
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


local function return_paths(paths)
  if #paths > 0 then
    return read_ref.new(paths), paths.address
  else
    return nil, paths.address
  end
end


function read_ref.__index(r, i)
  return return_paths(step_paths(r, i))
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
  if #r == 1 and index:isa(r1v) then
    local prefix = proxy.O(r[1].scope or s).prefix
    if prefix then
      a = index:new(prefix, proxy.O(r1v).address)
    else
      a = r1v
    end
  else
    a = r.address
  end
  local new_paths = { address = a, prefix = r.prefix }

  for _, path in ipairs(r) do
    local result = path.value
    local eval_scope = path.scope or s

    if not core.defined(result) then
      if closure:isa(result) and path.collected_indexes then
        local prefix = proxy.O(eval_scope).prefix
        eval_scope = result:set_args(eval_scope, path.collected_indexes)
        proxy.O(eval_scope).prefix = prefix
      end
      result = core.eval_to_paths(result, eval_scope)
    end

    if read_ref:isa(result) then
      for _, p2 in ipairs(proxy.O(result)) do
        new_paths[#new_paths+1] = node:new({ scope=path.scope or s}, p2)
      end
    elseif result then
      new_paths[#new_paths+1] = node:new(path, { value=result })
    end
  end

  return return_paths(new_paths)
end


function read_ref:__finish()
  self = proxy.O(self)
  for _, v in ipairs(self) do
    v = v.value
    if v and not undefined_t:isa(v) then
      if type(v) ~= "table" then
        return v
      end
      break
    end
  end

  if type(self[1].value) == "table" then
    local result = {}
    for i, t in ipairs(self) do
      for k, v in pairs(t.value) do
        result[k] = result[k] or v
      end
    end
    return result
  end
end


function read_ref:__type()
  self = proxy.O(self)
  for _, v in ipairs(self) do
    v = v.value
    if undefined_t:isa(v) then
      return v
    end
  end
end


read_ref.__tostring = lib.__tostring
read_ref.__repr = scope.__repr

function proxy_mt.__read_ref(s)
  return read_ref.copy(s)
end


-- EOF -------------------------------------------------------------------------

