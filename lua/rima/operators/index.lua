-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local error, xpcall = error, xpcall
local getmetatable, require, type = getmetatable, require, type

local object = require("rima.object")
local proxy = require("rima.proxy")
local undefined_t = require("rima.types.undefined_t")
require("rima.private")
local rima = rima

module(...)

local scope = require("rima.scope")
local expression = require("rima.expression")
local address = require("rima.address")

-- Addition --------------------------------------------------------------------

local index = _M
index.__typename = "index"
index.precedence = 0


-- Argument Checking -----------------------------------------------------------

function index.construct(args)
  local a, i = args[1], args[2]
  if getmetatable(a) == index then
    local A = proxy.O(a)
    return { A[1], A[2] + i }
  elseif getmetatable(i) == address then
    return { a, i }
  end
  return { a, address:new{i} }
end


-- String Representation -------------------------------------------------------

function index.__repr(args, format)
  if format and format.dump then
    return ("index(%s, %s)"):format(rima.repr(args[1], format), rima.repr(args[2], format))
  else
    return expression.parenthise(args[1], format, 0)..rima.repr(args[2], format)
  end
end


-- Evaluation ------------------------------------------------------------------

function index.resolve(args, S, eval)
  local address = expression.eval(args[2], S)
  if not address:defined() then
    return false, nil, expression.bind(args[1], S), address
  end
  local b = expression.bind(args[1], S)
  if object.isa(b, index) then
    local B = proxy.O(b)
    b = B[1]
    address = B[2] + address
  end

  -- eval can return a reference and a type if we're evaluating a ref, we need
  -- the type...
  local e, v = expression.eval(b, S)

  -- ...because if the first return value from eval is a ref, and the second
  -- is a scalar type, we can't index it.  Here we try to index it - it
  -- might work because it's not a scalar type or it might fail.  Maybe
  -- we could just check that first?
  if expression.defined(e) or v then
    local status, r = rima.packs(xpcall(function() return address:resolve(S, scope.pack(b), 1, b, eval) end, debug.traceback))
    if not status then
      error(("index: error evaluating '%s' as '%s%s':\n  %s"):
        format(__repr(args), rima.repr(b), rima.repr(address), r[1]:gsub("\n", "\n  ")), 0)
    else
      return rima.unpackn(r)
    end
  end

  return false, nil, e, address
end


function index.__bind(args, S, eval)
  local status, value, base, address = resolve(args, S, expression.bind)
  value = scope.unpack(value)
  if not status or expression.defined(value) then
    if address[1] then
      return expression:new(index, base, address)
    else
      return base
    end
  else
    return value
  end
end


function index.__eval(args, S, eval)
  local status, value, base, address = resolve(args, S, eval)
  if not status or value.hidden or
     object.isa(value.value, undefined_t) then
    if address[1] then
      return expression:new(index, base, address)
    else
      return base
    end
  else
    return value.value
  end
end


function index.__type(args, S)
  local status, value, base, address = resolve(args, S, expression.eval)
  value = scope.unpack(value)
  if not status or not object.isa(value, undefined_t) then
    error(("No type information available for '%s'"):format(__repr(args)))
  else
    return value
  end
end


function index.__set(args, t, v)
  local base, address = proxy.O(args[1]), args[2]
  local name = base.name

  function s(t, name, i)
    if object.type(name) == "element" then name = name.key end
    local cv = t[name]
    if #address == i then
      if cv then
        error(("error setting '%s' to %s: field already exists (%s)"):
          format(__repr(args), rima.repr(v), rima.repr(cv)), 0)
      end
      t[name] = v
    else
      if cv and type(cv) ~= "table" then
        error(("error setting '%s' to %s: field is not a table (%s)"):
          format(__repr(args), rima.repr(v), rima.repr(cv)), 0)
      end
      if not cv then t[name] = {} end
      s(t[name], address:value(i+1), i+1)
    end
  end
  s(t, name, 0)
end


-- EOF -------------------------------------------------------------------------

