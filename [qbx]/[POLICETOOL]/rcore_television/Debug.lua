if Config.GeneralDebug then
    local originalAddEventHandler   = AddEventHandler
    local originalRegisterNetEvent   = RegisterNetEvent
    local originalCreateThread       = CreateThread
    local originalRegisterCommand    = RegisterCommand
    local originalRegisterNUICallback = RegisterNUICallback

    function RegisterNUICallback(eventName, handler)
        originalRegisterNUICallback(eventName, function(...)
            local args = {...}
            local success, err = xpcall(function() handler(table.unpack(args)) end, debug.traceback)
            if not success then
                print(err, "^2RegisterNUICallback^0", "^1" .. eventName .. "^0")
            end
        end)
    end

    function RegisterCommand(commandName, handler)
        originalRegisterCommand(commandName, function(source, args, rawCommand)
            local success, err = xpcall(function() handler(source, args, rawCommand) end, debug.traceback)
            if not success then
                print(err, "^2RegisterCommand^0", "^1" .. commandName .. "^0")
            end
        end)
    end

    function CreateThread(handler, label)
        if not label then label = "non defined" end
        originalCreateThread(function()
            local success, err = xpcall(handler, debug.traceback)
            if not success then
                print(err, "^2CreateThread^0", "^1" .. label .. "^0")
            end
        end)
    end

    function AddEventHandler(eventName, handler)
        originalAddEventHandler(eventName, function(...)
            local args = {...}
            local success, err = xpcall(function() handler(table.unpack(args)) end, debug.traceback)
            if not success then
                print(err, "^2AddEventHandler^0", "^1" .. eventName .. "^0")
            end
        end)
    end

    function RegisterNetEvent(eventName, handler)
        if handler then
            originalRegisterNetEvent(eventName, function(...)
                local args = {...}
                local success, err = xpcall(function() handler(table.unpack(args)) end, debug.traceback)
                if not success then
                    print(err, "^2RegisterNetEvent^0", "^1" .. eventName .. "^0")
                end
            end)
        else
            originalRegisterNetEvent(eventName)
        end
    end
end
