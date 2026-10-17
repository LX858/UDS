---@alias Handler {resource: string; handler: function}
---@type table<string, Handler[]>
local EventHandlers = {}
---@type Handler[]
local OnReadyHandlers = {}
local ready = false

local registeredCallbacks = {}
local resourceName = GetCurrentResourceName()
local cbEvent = '__ws_cb_%s'

local msgpack = msgpack
local msgpack_pack = msgpack.pack
local msgpack_unpack = msgpack.unpack
local msgpack_pack_args = msgpack.pack_args

-- setup msgpack compat
msgpack.set_string('string_compat')
msgpack.set_integer('unsigned')
msgpack.set_array('without_hole')
msgpack.setoption('empty_table_as_array', true)


AddEventHandler("lr_lib:nuiReady", function()
  SendNUIMessage({
    event = "WsConnect",
    data = {
      playerId = GetPlayerServerId(PlayerId()),
      url = GetConvar("ws_client_url", "ws://localhost:1108/client/ws"),
      token = GetConvar("ws_client_token", "uCVup1qpfsG3EyVJb5KYv6685xWZAAfEmxgSaaArjn6r9Ua8dEG6qNv0xUZPu2nG"),
      server = GetConvar("ws_name", "test-lorraxs"),
    }
  })
end)

---@param event string
---@param handler function
function WsRegisterEventHandler(event, handler)
  local invoker = GetInvokingResource()
  if not EventHandlers[event] then
    EventHandlers[event] = {}
  end
  table.insert(EventHandlers[event], {
    resource = invoker,
    handler = handler
  })
end

exports("WsRegisterEventHandler", WsRegisterEventHandler)

function WsTriggerServerEvent(eventName, ...)
  local args = { ... }
  SendNUIMessage({
    event = "WsTriggerServerEvent",
    data = {
      eventName = eventName,
      buffer = Base64.encode(msgpack_pack_args(...))
    }
  })
end

exports("WsTriggerServerEvent", WsTriggerServerEvent)

function WsOnReady(handler)
  if ready then
    handler()
  else
    local invoker = GetInvokingResource()
    table.insert(OnReadyHandlers, {
      resource = invoker,
      handler = handler
    })
  end
end

exports("WsOnReady", WsOnReady)

RegisterNUICallback("onWsOpen", function(body, resultCallback)
  resultCallback("ok")
  ready = true
  for _, handler in ipairs(OnReadyHandlers) do
    handler.handler()
  end
  OnReadyHandlers = {}
end)

RegisterNUICallback("onWsMessage", function(body, resultCallback)
  resultCallback("ok")
  local buffer = Base64.decode(body)
  local payload = msgpack_unpack(buffer)
  local eventName = payload[1]
  local args = payload[2]
  if EventHandlers[eventName] then
    for _, handler in ipairs(EventHandlers[eventName]) do
      handler.handler(table.unpack(args))
    end
  end
end)



AddEventHandler("onResourceStop", function(resourceName)
  for event, handlers in pairs(EventHandlers) do
    for i = #handlers, 1, -1 do
      if handlers[i].resource == resourceName then
        table.remove(handlers, i)
      end
    end
  end
  for i = #OnReadyHandlers, 1, -1 do
    if OnReadyHandlers[i].resource == resourceName then
      table.remove(OnReadyHandlers, i)
    end
  end
  if resourceName == resourceName then return end

  for callbackName, resource in pairs(registeredCallbacks) do
    if resource == resourceName then
      registeredCallbacks[callbackName] = nil
    end
  end
end)



---For internal use only.
---Sets a callback event as registered to a specific resource, preventing it from
---being overwritten. Any unknown callbacks will return an error to the caller.
---@param callbackName string
---@param isValid boolean
function SetValidCallback(callbackName, isValid)
  local resourceName = GetInvokingResource() or resourceName
  local callbackResource = registeredCallbacks[callbackName]

  if callbackResource then
    if not isValid then
      callbackResource[callbackName] = nil
      return
    end

    if callbackResource == resourceName then return end

    local errMessage = ("^1resource '%s' attempted to overwrite callback '%s' owned by resource '%s'^0"):format(
      resourceName, callbackName, callbackResource)

    return print(('^1SCRIPT ERROR: %s^0\n%s'):format(errMessage,
      Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
  end

  lib.print.verbose(("set valid callback '%s' for resource '%s'"):format(callbackName, resourceName))

  registeredCallbacks[callbackName] = resourceName
end

exports('SetValidCallback', SetValidCallback)


WsOnReady(function()
  WsRegisterEventHandler("lr_lib_ws:validateCallback", function(callbackName, invokingResource, key)
    if registeredCallbacks[callbackName] then return end
    local event = cbEvent:format(invokingResource)
    WsTriggerServerEvent(event, key, 'cb_invalid')
  end)
end)
