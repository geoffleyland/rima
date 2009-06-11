-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local error, ipairs, require = error, ipairs, require

local args = require("rima.args")
local object = require("rima.object")
local call = require("rima.operators.call")
require("rima.private")
local rima = rima

module(...)

local expression = require("rima.expression")
require("rima.public")

-- Function type ---------------------------------------------------------------

local function_v = object:new(_M, "function_v")

function function_v:new(inputs, expression, S, ...)
  local fname, usage =
    "function_v:now",
    "new(inputs, expression, table or scope)"

  args.check_types(S, "S", {"nil", "table", {rima.scope, "scope"}}, usage, frame)

  if S and not isa(S, rima.scope) then S = rima.scope.create(S) end

  local new_inputs = {}
  for i, v in ipairs(inputs) do
    if type(v) == "string" then
      new_inputs[i] = rima.R(v)
    elseif isa(v, rima.ref) then
      if rima.ref.is_simple(v) then
        new_inputs[i] = v
      else
        error(("bad input #%d to function constructor: expected string or simple reference, got '%s' (%s)"):
          format(i, tostring(v), type(v)), 0)
      end
    else
      error(("bad input #%d to function constructor: expected string or simple reference, got '%s' (%s))"):
        format(i, tostring(v), type(v)), 0)
    end
  end

  return object.new(self, { inputs=new_inputs, expression=expression, S=S, outputs={...} })
end


-- String representation -------------------------------------------------------

function function_v:__tostring()
  local s = "function("
  for i, a in ipairs(self.inputs) do
    if i > 1 then s = s..", " end
    s = s..rima.tostring(a)
  end
  s = s..") return "..rima.tostring(self.expression)
--[[
  if self.outputs[1] then
    s = s.." where {"
    for i, a in ipairs(self.outputs) do
      if i > 1 then s = s..", " end
      s = s..a.name.." = "..rima.tostring(self.S:_value(a.name))
    end
    s = s.."}"
  end
--]]
  return s
end

function function_v:call(S, args)
  if not args then return self end

  local outputs = {}
  if #args < #self.inputs then
    error(("the function needs to be called with at least %d arguments, got %d"):format(#self.inputs, #args), 0)
  elseif #args == #self.inputs + 1 then
    if type(args[#args]) ~= "table" then
      error(("the function needs to be called with %d arguments, got %d"):format(#self.inputs, #args), 0)
    else
      outputs = args[#args]
      if #outputs ~= #self.outputs then
        error(("the function needs to be called with %d outputs, got %d"):format(#self.outputs, #outputs), 0)
      end
    end
  elseif #args ~= #self.inputs then
    error(("the function needs to be called with %d arguments, got %d"):format(#self.inputs, #args), 0)
  end

  local caller_scope = rima.scope.spawn(S, nil, {overwrite=true})
  local function_scope = rima.scope.spawn(self.S or S, nil, {overwrite=true})

  for i, a in ipairs(outputs) do
    caller_scope[rima.tostring(a)] = expression:new(call, function_v:new({}, self.outputs[i], function_scope))
  end

  for i, a in ipairs(self.inputs) do
    function_scope[rima.tostring(a)] = expression:new(call, function_v:new({}, args[i], caller_scope))
  end

  return expression.eval(self.expression, function_scope)
end


function function_v:__call(...)
  local S = rima.scope.new()
  return self:call(S, {...})
end

-- EOF -------------------------------------------------------------------------

