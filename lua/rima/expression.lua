-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")


------------------------------------------------------------------------------

local expression = object:new_class({}, "expression")
local expressions = setmetatable({}, { __mode = "k" })


local function wrap(op)
  if type(op) ~= "table" then return op end 

  local top = object.typeinfo(op)
  if top.index or top.operator then
    local e = setmetatable({}, expression)
    expressions[e] = op
    return e
  else
    return op
  end
end


local function vtwrap(...)
  local r = {}
  for i = 1, select("#", ...) do
    r[i] = wrap(select(i, ...))
  end
  return r
end


local function vwrap(...)
  return unpack(vtwrap(...))
end


local function unwrap(e)
  return expressions[e] or e
end


local function tunwrap(t)
  local r = {}
  for k, v in pairs(t) do
    r[k] = unwrap(v)
  end
  return r
end


local function vtunwrap(...)
  local r = {}
  for i = 1, select("#", ...) do
    r[i] = unwrap(select(i, ...))
  end
  return r
end


local function vunwrap(...)
  return unpack(vtunwrap(...))
end


expression.wrap = wrap
expression.vtwrap = vtwrap
expression.vwrap = vwrap
expression.unwrap = unwrap
expression.tunwrap = tunwrap
expression.vtunwrap = vtunwrap
expression.vunwrap = vunwrap


------------------------------------------------------------------------------

local W, U = wrap, unwrap


function expression:__list_variables(S, list)
  return core.list_variables(U(self), S, list)
end


function expression:__repr(format, ...)
  local s = lib.repr(unwrap(self), format, ...) 
  if format.format == "dump" then
    return "expression("..s..")"
  else
    return s
  end
end
expression.__tostring = lib.__tostring


------------------------------------------------------------------------------

local ops = require"rima.operations"
local call = require"rima.operators.call"
local index = require"rima.index"


function expression.__add  (a, b) return W(ops.add(U(a), U(b))) end
function expression.__sub  (a, b) return W(ops.sub(U(a), U(b))) end
function expression.__unm  (a)    return W(ops.unm(U(a))) end
function expression.__mul  (a, b) return W(ops.mul(U(a), U(b))) end
function expression.__div  (a, b) return W(ops.div(U(a), U(b))) end
function expression.__pow  (a, b) return W(ops.pow(U(a), U(b))) end
function expression.__mod  (a, b) return W(ops.mod(U(a), U(b))) end
function expression.__call (...)  return W(call:new(vtunwrap(...))) end


function expression.__index(t, k, ...)
  if type(k) == "table" and not getmetatable(k) then
    local k2 = {}
    for k, v in pairs(k) do
      k2[U(k)] = U(v)
    end
    k = k2
  else
    k = U(k)
  end
  return W(index:new(U(t), k, vunwrap(...)))
end


function expression.__newindex(e, k, v)
  e = U(e)

  if type(k) == "table" and not getmetatable(k) then
    local k2 = {}
    for k, v in pairs(k) do
      k2[U(k)] = U(v)
    end
    k = k2
  else
    k = U(k)
  end

  if object.typename(e) == "index" then
    index.newindex(e, k, U(v), 1)
  else
    error("You can't do that!")
  end
end


------------------------------------------------------------------------------

return expression

------------------------------------------------------------------------------

