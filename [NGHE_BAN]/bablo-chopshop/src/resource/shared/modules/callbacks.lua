local isServer = IsDuplicityVersion()
local unpack = table.unpack
local pack = msgpack.pack
local unpackPacked = msgpack.unpack
local packArgs = msgpack.pack_args

local PROMISE_PENDING = 0

local function validateType(value, expectedType, optionalType, customMessage)
  local actualType = type(value)
  local caller = debug.getinfo(2)
  local message = customMessage

  if not message then
    if optionalType == nil then
      message = caller.name .. " expected %s, but got %s"
    else
      message = caller.name .. " expected %s or %s, but got %s"
    end
  end

  if expectedType == "function" and actualType == "table" and rawget(value, "__cfx_functionReference") then
    return
  end

  if actualType ~= expectedType and actualType ~= optionalType then
    error(message:format(expectedType, optionalType or actualType, actualType))
  end
end

local function unpackArgs(packedArgs)
  return unpack(unpackPacked(packedArgs))
end

local function resolvePacked(callbackPromise, callback, packedReturnValue)
  local returnValues = { unpackArgs(packedReturnValue) }

  if callback and callbackPromise.state == PROMISE_PENDING then
    callback(unpack(returnValues))
  end

  callbackPromise:resolve(unpack(returnValues))
end

local function scheduleTimeout(options, callbackPromise, handler)
  if options.timeout == nil or not options.timedout then
    return
  end

  SetTimeout(options.timeout * 1000, function()
    if callbackPromise.state ~= PROMISE_PENDING then
      return
    end

    options.timedout(callbackPromise.state)
    callbackPromise:reject()

    if handler then
      RemoveEventHandler(handler)
    end
  end)
end

if isServer then
  function RegisterServerCallback(options)
    validateType(options, "table")
    validateType(options.eventName, "string")
    validateType(options.eventCallback, "function")

    local eventName = options.eventName
    local eventCallback = options.eventCallback

    return RegisterNetEvent("bablo_chopshop_callbacks__server_callback:" .. eventName, function(packedArgs, playerSource, cb)
      local callerSource = tonumber(source)

      if not callerSource then
        cb(packArgs(eventCallback(playerSource, unpackArgs(packedArgs))))
        return
      end

      TriggerClientEvent(
        ("bablo_chopshop_callbacks__client_callback_response:%s:%s"):format(eventName, callerSource),
        callerSource,
        packArgs(eventCallback(callerSource, unpackArgs(packedArgs)))
      )
    end)
  end

  exports("RegisterServerCallback", RegisterServerCallback)

  function UnregisterServerCallback(handler)
    RemoveEventHandler(handler)
  end

  exports("UnregisterServerCallback", UnregisterServerCallback)

  function TriggerClientCallback(options)
    validateType(options, "table")
    validateType(options.source, "string", "number")
    validateType(options.eventName, "string")
    validateType(options.args, "table", "nil")
    validateType(options.timeout, "number", "nil")
    validateType(options.timedout, "function", "nil")
    validateType(options.callback, "function", "nil")

    local playerSource = tonumber(options.source)
    if playerSource < 0 then
      error("source should be equal too or higher than 0")
    end

    local requestId = tostring(options.source) .. "x" .. tostring(GetGameTimer())
    local callbackPromise = promise.new()
    local handler

    handler = RegisterNetEvent(
      ("bablo_chopshop_callbacks__callback_retval:%s:%s:%s"):format(options.source, options.eventName, requestId),
      function(packedReturnValue)
        resolvePacked(callbackPromise, options.callback, packedReturnValue)
      end
    )

    TriggerClientEvent(
      ("bablo_chopshop_callbacks__client_callback:%s"):format(options.eventName),
      options.source,
      pack(options.args or {}),
      requestId
    )

    scheduleTimeout(options, callbackPromise, handler)

    if not options.callback then
      local result = Citizen.Await(callbackPromise)
      RemoveEventHandler(handler)
      return result
    end
  end

  exports("TriggerClientCallback", TriggerClientCallback)

  function TriggerServerCallback(options)
    validateType(options, "table")
    validateType(options.source, "string", "number")
    validateType(options.eventName, "string")
    validateType(options.args, "table", "nil")
    validateType(options.timeout, "number", "nil")
    validateType(options.timedout, "function", "nil")
    validateType(options.callback, "function", "nil")

    local callbackPromise = promise.new()

    TriggerEvent(
      "bablo_chopshop_callbacks__server_callback:" .. options.eventName,
      pack(options.args or {}),
      options.source,
      function(packedReturnValue)
        resolvePacked(callbackPromise, options.callback, packedReturnValue)
      end
    )

    scheduleTimeout(options, callbackPromise)

    if not options.callback then
      return Citizen.Await(callbackPromise)
    end
  end

  exports("TriggerServerCallback", TriggerServerCallback)
else
  local serverId = GetPlayerServerId(PlayerId())

  function RegisterClientCallback(options)
    validateType(options, "table")
    validateType(options.eventName, "string")
    validateType(options.eventCallback, "function")

    local eventName = options.eventName
    local eventCallback = options.eventCallback

    return RegisterNetEvent("bablo_chopshop_callbacks__client_callback:" .. eventName, function(packedArgs, requestIdOrCallback)
      local packedReturnValue = packArgs(eventCallback(unpackArgs(packedArgs)))

      if type(requestIdOrCallback) == "function" then
        requestIdOrCallback(packedReturnValue)
      else
        TriggerServerEvent(
          ("bablo_chopshop_callbacks__callback_retval:%s:%s:%s"):format(serverId, eventName, requestIdOrCallback),
          packedReturnValue
        )
      end
    end)
  end

  exports("RegisterClientCallback", RegisterClientCallback)

  function UnregisterClientCallback(handler)
    RemoveEventHandler(handler)
  end

  exports("UnregisterClientCallback", UnregisterClientCallback)

  function TriggerServerCallback(options)
    validateType(options, "table")
    validateType(options.args, "table", "nil")
    validateType(options.eventName, "string")
    validateType(options.timeout, "number", "nil")
    validateType(options.timedout, "function", "nil")
    validateType(options.callback, "function", "nil")

    local callbackPromise = promise.new()
    local handler

    handler = RegisterNetEvent(
      ("bablo_chopshop_callbacks__client_callback_response:%s:%s"):format(options.eventName, serverId),
      function(packedReturnValue)
        resolvePacked(callbackPromise, options.callback, packedReturnValue)
      end
    )

    TriggerServerEvent("bablo_chopshop_callbacks__server_callback:" .. options.eventName, pack(options.args or {}))
    scheduleTimeout(options, callbackPromise, handler)

    if not options.callback then
      local result = Citizen.Await(callbackPromise)
      RemoveEventHandler(handler)
      return result
    end
  end

  exports("TriggerServerCallback", TriggerServerCallback)

  function TriggerClientCallback(options)
    validateType(options, "table")
    validateType(options.eventName, "string")
    validateType(options.args, "table", "nil")
    validateType(options.timeout, "number", "nil")
    validateType(options.timedout, "function", "nil")
    validateType(options.callback, "function", "nil")

    local callbackPromise = promise.new()

    TriggerEvent(
      "bablo_chopshop_callbacks__client_callback:" .. options.eventName,
      pack(options.args or {}),
      function(packedReturnValue)
        resolvePacked(callbackPromise, options.callback, packedReturnValue)
      end
    )

    scheduleTimeout(options, callbackPromise)

    if not options.callback then
      return Citizen.Await(callbackPromise)
    end
  end

  exports("TriggerClientCallback", TriggerClientCallback)
end
