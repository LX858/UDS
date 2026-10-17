WS = {}
local pendingCallbacks = {}
local timers = {}
local cbEvent = '__ws_cb_%s'
local callbackTimeout = GetConvarInt('ox:callbackTimeout', 300000)
local ResourceName = GetCurrentResourceName()
local pcall = pcall

if IsDuplicityVersion() then
  WS.OnReady = function(cb)
    exports["lr_lib"]:WsOnReady(cb)
  end

  WS.TriggerClientEvent = function(eventName, playerId, ...)
    exports["lr_lib"]:WsTriggerClientEvent(eventName, playerId, ...)
  end

  WS.RegisterEventHandler = function(eventName, cb)
    exports["lr_lib"]:WsRegisterEventHandler(eventName, cb)
  end

  WS.RegisterServerEvent = function(eventName, cb)
    exports["lr_lib"]:WsRegisterEventHandler(eventName, cb)
  end

  WS.RegisterEventHandler(cbEvent:format(ResourceName), function(key, ...)
    local cb = pendingCallbacks[key]
    if not cb then return end
    pendingCallbacks[key] = nil
    cb(...)
  end)

  ---@param _ any
  ---@param event string
  ---@param playerId number
  ---@param cb function|false
  ---@param ... any
  ---@return ...
  local function triggerClientCallback(_, event, playerId, cb, ...)
    assert(DoesPlayerExist(playerId --[[@as string]]), ("target playerId '%s' does not exist"):format(playerId))

    local key

    repeat
      key = ('%s:%s:%s'):format(event, math.random(0, 100000), playerId)
    until not pendingCallbacks[key]

    WS.TriggerClientEvent('lr_lib_ws:validateCallback', playerId, event, ResourceName, key)
    WS.TriggerClientEvent(cbEvent:format(event), playerId, ResourceName, key, ...)

    ---@type promise | false
    local promise = not cb and promise.new()

    pendingCallbacks[key] = function(response, ...)
      if response == 'cb_invalid' then
        response = ("callback '%s' does not exist"):format(event)

        return promise and promise:reject(response) or error(response)
      end

      response = { response, ... }

      if promise then
        return promise:resolve(response)
      end

      if cb then
        cb(table.unpack(response))
      end
    end

    if promise then
      SetTimeout(callbackTimeout, function() promise:reject(("callback event '%s' timed out"):format(key)) end)

      return table.unpack(Citizen.Await(promise))
    end
  end

  ---@overload fun(event: string, playerId: number, cb: function, ...)
  WS.SVCallback = setmetatable({}, {
    __call = function(_, event, playerId, cb, ...)
      if not cb then
        warn(("callback event '%s' does not have a function to callback to and will instead await\nuse lib.callback.await or a regular event to remove this warning")
          :format(event))
      else
        local cbType = type(cb)

        if cbType == 'table' and getmetatable(cb)?.__call then
          cbType = 'function'
        end

        assert(cbType == 'function', ("expected argument 3 to have type 'function' (received %s)"):format(cbType))
      end

      return triggerClientCallback(_, event, playerId, cb, ...)
    end
  })

  ---@param event string
  ---@param playerId number
  --- Sends an event to a client and halts the current thread until a response is returned.
  ---@diagnostic disable-next-line: duplicate-set-field
  function WS.SVCallback.await(event, playerId, ...)
    return triggerClientCallback(nil, event, playerId, false, ...)
  end

  local function callbackResponse(success, result, ...)
    if not success then
      if result then
        return print(('^1SCRIPT ERROR: %s^0\n%s'):format(result,
          Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
      end

      return false
    end

    return result, ...
  end

  local pcall = pcall

  ---@param name string
  ---@param cb function
  ---Registers an event handler and callback function to respond to client requests.
  ---@diagnostic disable-next-line: duplicate-set-field
  function WS.SVCallback.register(name, cb)
    local event = cbEvent:format(name)

    exports['lr_lib']:SetValidCallback(name, true)

    WS.RegisterEventHandler(event, function(playerId, resource, key, ...)
      WS.TriggerClientEvent(cbEvent:format(resource), playerId, key, callbackResponse(pcall(cb, playerId, ...)))
    end)
  end
else
  WS.OnReady = function(cb)
    exports["lr_lib"]:WsOnReady(cb)
  end

  WS.TriggerServerEvent = function(eventName, ...)
    exports["lr_lib"]:WsTriggerServerEvent(eventName, ...)
  end

  WS.RegisterEventHandler = function(eventName, cb)
    exports["lr_lib"]:WsRegisterEventHandler(eventName, cb)
  end

  WS.RegisterClientEvent = function(eventName, cb)
    exports["lr_lib"]:WsRegisterEventHandler(eventName, cb)
  end

  WS.RegisterEventHandler(cbEvent:format(ResourceName), function(key, ...)
    local cb = pendingCallbacks[key]
    if not cb then return end
    pendingCallbacks[key] = nil
    cb(...)
  end)

  ---@param event string
  ---@param delay? number | false prevent the event from being called for the given time
  local function eventTimer(event, delay)
    if delay and type(delay) == 'number' and delay > 0 then
      local time = GetGameTimer()
      if (timers[event] or 0) > time then
        return false
      end
      timers[event] = time + delay
    end
    return true
  end

  ---@param _ any
  ---@param event string
  ---@param delay number | false | nil
  ---@param cb function | false
  ---@param ... any
  ---@return ...
  local function triggerServerCallback(_, event, delay, cb, ...)
    if not eventTimer(event, delay) then return end
    local key
    repeat
      key = ('%s:%s'):format(event, math.random(0, 100000))
    until not pendingCallbacks[key]

    WS.TriggerServerEvent('lr_lib_ws:validateCallback', event, ResourceName, key)
    WS.TriggerServerEvent(cbEvent:format(event), ResourceName, key, ...)

    ---@type promise | false
    local promise = not cb and promise.new()

    pendingCallbacks[key] = function(response, ...)
      if response == 'cb_invalid' then
        response = ("callback '%s' does not exist"):format(event)

        return promise and promise:reject(response) or error(response)
      end

      response = { response, ... }

      if promise then
        return promise:resolve(response)
      end

      if cb then
        cb(table.unpack(response))
      end
    end

    if promise then
      SetTimeout(callbackTimeout, function() promise:reject(("callback event '%s' timed out"):format(key)) end)

      return table.unpack(Citizen.Await(promise))
    end
  end

  ---@overload fun(event: string, delay: number | false, cb: function, ...)
  WS.CLCallback = setmetatable({}, {
    __call = function(_, event, delay, cb, ...)
      if not cb then
        warn(("callback event '%s' does not have a function to callback to and will instead await\nuse lib.callback.await or a regular event to remove this warning")
          :format(event))
      else
        local cbType = type(cb)

        if cbType == 'table' and getmetatable(cb)?.__call then
          cbType = 'function'
        end

        assert(cbType == 'function', ("expected argument 3 to have type 'function' (received %s)"):format(cbType))
      end

      return triggerServerCallback(_, event, delay, cb, ...)
    end
  })

  ---@param event string
  ---@param delay? number | false prevent the event from being called for the given time.
  ---Sends an event to the server and halts the current thread until a response is returned.
  ---@diagnostic disable-next-line: duplicate-set-field
  function WS.CLCallback.await(event, delay, ...)
    return triggerServerCallback(nil, event, delay, false, ...)
  end

  local function callbackResponse(success, result, ...)
    if not success then
      if result then
        return print(('^1SCRIPT ERROR: %s^0\n%s'):format(result,
          Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
      end

      return false
    end

    return result, ...
  end

  ---@param name string
  ---@param cb function
  ---Registers an event handler and callback function to respond to server requests.
  ---@diagnostic disable-next-line: duplicate-set-field
  function WS.CLCallback.register(name, cb)
    local event = cbEvent:format(name)
    exports['lr_lib']:SetValidCallback(name, true)
    WS.RegisterEventHandler(event, function(resource, key, ...)
      WS.TriggerServerEvent(cbEvent:format(resource), key, callbackResponse(pcall(cb, ...)))
    end)
  end
end
