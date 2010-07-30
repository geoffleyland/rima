-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local error, ipairs, require = error, ipairs, require

local args = require("rima.lib.args")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
local call = require("rima.operators.call")
local scope = require("rima.scope")

module(...)

local ref = require("rima.ref")

-- Function type ---------------------------------------------------------------

local function_v = object:new(_M, "function_v")


function function_v:new(inputs, exp, S)
  local fname, usage =
    "function_v:now",
    "new(inputs, expression, table or scope)"

  args.check_types(S, "S", {"nil", "table", {scope, "scope"}}, usage, fname)

  if S and not scope:isa(S) then S = scope.new(S) end

  local new_inputs = {}
  for i, v in ipairs(inputs) do
    if type(v) == "string" then
      new_inputs[i] = ref:new{name=v}
    elseif ref:isa(v) then
      if ref.is_simple(v) then
        new_inputs[i] = v
      else
        error(("bad input #%d to function constructor: expected string or simple reference, got '%s' (%s)"):
          format(i, lib.repr(v), type(v)), 0)
      end
    else
      error(("bad input #%d to function constructor: expected string or simple reference, got '%s' (%s)"):
        format(i, lib.repr(v), type(v)), 0)
    end
  end

  local pretty_exp = exp
  if new_inputs[1] then
    S = S or scope.new()
    for i, a in ipairs(new_inputs) do
      S[lib.repr(a)] = ref:new{name="_"..i}
    end
    exp = core.eval(exp, S)
  end

  return object.new(self, { inputs=new_inputs, exp=exp, S=S, pretty_exp=pretty_exp })
end


-- String representation -------------------------------------------------------

function function_v:__repr(format)
  return ("function(%s) return %s"):
    format(lib.concat_repr(self.inputs, format), lib.repr(self.pretty_exp, format))
end
__tostring = lib.__tostring


-- Evaluation ------------------------------------------------------------------

function function_v:check_args(args)
  local outputs = {}
  if #args < #self.inputs then
    error(("the function needs to be called with at least %d arguments, got %d"):format(#self.inputs, #args), 0)
  elseif #args ~= #self.inputs then
    error(("the function needs to be called with %d arguments, got %d"):format(#self.inputs, #args), 0)
  end
end


function function_v:call(args, S, eval)
  if not args then return self end

  self:check_args(args)

  local function_scope
  if self.inputs[1] then
    function_scope = scope.spawn(S, nil, {overwrite=true, rewrite=true, no_undefined=true})
  else
    function_scope = S
  end

  for i in ipairs(self.inputs) do
    function_scope["_"..i] = args[i]
  end

  return eval(self.exp, function_scope)
end


function function_v:__call(...)
  local S = scope.new()
  return self:call({...}, S, core.eval)
end


-- EOF -------------------------------------------------------------------------

