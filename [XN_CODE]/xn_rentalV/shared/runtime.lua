ScootRuntime = {
  callback = {},
}

local isServer = IsDuplicityVersion()
local resourceName = GetCurrentResourceName()
local rpcRequestEvent = resourceName .. ":rpc:request"
local rpcReplyEvent = resourceName .. ":rpc:reply"
local registeredCallbacks = {}
local pendingRequests = {}
local rateLimits = {}
local nextRequestId = 0

function IsRpcNumber(value)
  return type(value) == "number"
end

function ScootRuntime.callback.register(name, handler)
  registeredCallbacks[name] = handler
end

RegisterNetEvent(rpcRequestEvent, function(requestId, name, payload)
  local src = source
  if isServer then
    if src <= 0 then
      return
    end
  else
    if src ~= 65535 then
      return
    end
  end

  if not IsRpcNumber(requestId) then
    return
  end
  if type(name) ~= "string" then
    return
  end
  if not registeredCallbacks[name] then
    return
  end
  if type(payload) ~= "table" then
    return
  end

  local argCount = payload.count
  local argValues = payload.values
  if argCount == nil then
    local n = payload.n
    if not n then
      n = #payload
    end
    argValues = payload
    argCount = n
  end

  if type(argValues) ~= "table" then
    return
  end
  if type(argCount) ~= "number" then
    return
  end
  if argCount % 1 ~= 0 or argCount < 0 or argCount > 4 then
    return
  end

  if isServer then
    local now = GetGameTimer()
    local bucket = rateLimits[src]
    if not bucket or (now - bucket.at >= 1000) then
      bucket = {
        at = now,
        count = 0,
      }
      rateLimits[src] = bucket
    end
    bucket.count = bucket.count + 1
    if bucket.count > 20 then
      return
    end
  end

  local ok, result
  if isServer then
    ok, result = pcall(
      registeredCallbacks[name],
      src,
      table.unpack(argValues, 1, argCount)
    )
  else
    ok, result = pcall(
      registeredCallbacks[name],
      table.unpack(argValues, 1, argCount)
    )
  end

  if not ok then
    print(("[%s] callback %s failed: %s"):format(resourceName, name, result))
    result = {
      ok = false,
      error = ScootT("unavailable"),
    }
  end

  if isServer then
    TriggerClientEvent(rpcReplyEvent, src, requestId, result)
  else
    TriggerServerEvent(rpcReplyEvent, requestId, result)
  end
end)

RegisterNetEvent(rpcReplyEvent, function(requestId, result)
  if not IsRpcNumber(requestId) then
    return
  end

  local pending = pendingRequests[requestId]
  if not pending then
    return
  end
  if source ~= pending.peer then
    return
  end

  pendingRequests[requestId] = nil
  pending.promise:resolve({
    value = result,
  })
end)

function ScootRuntime.callback.await(name, targetOrFlag, ...)
  if isServer then
    if type(targetOrFlag) ~= "number" or targetOrFlag <= 0 or targetOrFlag % 1 ~= 0 then
      return false
    end
  end

  local requestId
  repeat
    nextRequestId = nextRequestId % 2147483647 + 1
    requestId = nextRequestId
  until not pendingRequests[requestId]

  local peer = targetOrFlag or isServer
  if not peer or not targetOrFlag then
    peer = 65535
  end

  local pending = {
    peer = peer,
    promise = promise.new(),
  }
  pendingRequests[requestId] = pending

  SetTimeout(15000, function()
    if pendingRequests[requestId] == pending then
      pendingRequests[requestId] = nil
      pending.promise:resolve({
        value = {
          ok = false,
          error = ScootT("connection_error"),
        },
      })
    end
  end)

  local payload = {
    count = select("#", ...),
    values = {
      ...,
    },
  }

  local sendOk, sendErr
  if isServer then
    sendOk, sendErr = pcall(
      TriggerClientEvent,
      rpcRequestEvent,
      targetOrFlag,
      requestId,
      name,
      payload
    )
  else
    sendOk, sendErr = pcall(
      TriggerServerEvent,
      rpcRequestEvent,
      requestId,
      name,
      payload
    )
  end

  if not sendOk then
    pendingRequests[requestId] = nil
    print(("[%s] RPC send failed (%s): %s"):format(resourceName, name, sendErr))
    return {
      ok = false,
      error = ScootT("connection_error"),
    }
  end

  return Citizen.Await(pending.promise).value
end

if isServer then
  AddEventHandler("playerDropped", function()
    local src = source
    rateLimits[src] = nil
    for id, pending in pairs(pendingRequests) do
      if pending.peer == src then
        pendingRequests[id] = nil
        pending.promise:resolve({
          value = false,
        })
      end
    end
  end)
else
  ScootCache = setmetatable({
    resource = resourceName,
  }, {
    __index = function(_, key)
      if key == "ped" then
        return PlayerPedId()
      end
      if key == "serverId" then
        return GetPlayerServerId(PlayerId())
      end
    end,
  })

  function ScootRuntime.requestModel(model, timeout)
    if type(model) == "string" then
      model = joaat(model)
    end
    assert(IsModelInCdimage(model), "Model is not available: " .. tostring(model))

    local deadline = GetGameTimer() + (timeout or 10000)
    repeat
      RequestModel(model)
      if HasModelLoaded(model) then
        return model
      end
      Wait(0)
    until deadline <= GetGameTimer()

    error("Model load timed out: " .. tostring(model))
  end

  function ScootRuntime.requestAnimDict(dict, timeout)
    local deadline = GetGameTimer() + (timeout or 10000)
    repeat
      RequestAnimDict(dict)
      if HasAnimDictLoaded(dict) then
        return true
      end
      Wait(0)
    until deadline <= GetGameTimer()

    error("Animation load timed out: " .. tostring(dict))
  end

  function ScootRuntime.notify(data)
    ScootClientBridge.notify(data)
  end

  function ScootRuntime.showTextUI(text, options)
    ScootClientBridge.showPrompt(text, options)
  end

  function ScootRuntime.hideTextUI()
    ScootClientBridge.hidePrompt()
  end
end
