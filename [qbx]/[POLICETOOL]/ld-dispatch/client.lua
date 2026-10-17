--  _                             _                                  ___                        _     
-- | |_   _ _ __  _ __  _   _  __| | _____   _____ ___  _ __ ___    ( _ )    _ ____      ____ _(_)___ 
-- | | | | | '_ \| '_ \| | | |/ _` |/ _ \ \ / / __/ _ \| '_ ` _ \   / _ \/\ | '_ \ \ /\ / / _` | / __|
-- | | |_| | | | | | | | |_| | (_| |  __/\ V / (_| (_) | | | | | | | (_>  < | |_) \ V  V / (_| | \__ \
-- |_|\__,_|_| |_|_| |_|\__, |\__,_|\___| \_(_)___\___/|_| |_| |_|  \___/\/ | .__/ \_/\_/ \__,_|_|___/
--                      |___/                                               |_|                       

local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand(Config.MenuCommand, function()
    QBCore.Functions.TriggerCallback('ld-dispatch:getDispatchs', function(cb)
        QBCore.Functions.TriggerCallback('ld-dispatch:getMyUnit', function(cba)
            local PlayerData = QBCore.Functions.GetPlayerData()
            SendNUIMessage({
                action="openMenu",
                data = cb,
                unit = cba,
                myjob = PlayerData.job.name
            })
            SetNuiFocus(true, true)
        end)
    end)
end, false)

RegisterKeyMapping(Config.MenuCommand, 'Open Dispatch Menu', 'keyboard', Config.MenuKey)

RegisterNUICallback('getPlayers', function(data,cab)
    QBCore.Functions.TriggerCallback('ld-dispatch:getJobPlayers', function(cb)
        cab(cb)
    end)
end)

RegisterNUICallback('getUnits', function(data,cab)
    QBCore.Functions.TriggerCallback('ld-dispatch:getUnits', function(cb)
        cab(cb)
    end)
end)

RegisterNUICallback('canAddtoUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('ld-dispatch:canAddtoUnit', function(cb)
        cab(cb)
    end, data.id)
end)

RegisterNUICallback('createUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('ld-dispatch:createUnit', function(cb)
        cab(cb)
    end, data)
end)

RegisterNUICallback('leaveUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('ld-dispatch:leaveUnit', function(cb)
        cab(cb)
    end, data)
end)

RegisterNUICallback('deleteUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('ld-dispatch:deleteUnit', function(cb)
        cab(cb)
    end, data)
end)

RegisterNUICallback('closeMenu', function()
    SetNuiFocus(false, false)
end)

function sendDispatch(data)
    TriggerServerEvent('ld-dispatch:addDispatch', data)
end

exports('sendDispatch', sendDispatch)

RegisterNetEvent('ld-dispatch:client:dispatch', function(data)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local canisee = false 
    for k,v in pairs(data.jobs) do 
        if v == PlayerData.job.name then 
            canisee = true 
            break 
        end
    end 
    if not canisee then 
        return 
    end 

    -- Kiểm tra onduty
    if not PlayerData.job.onduty then
        return
    end

    SendNUIMessage({
        action="addispatch",
        data = data
    })

    DispatchBlip(data)
end)

RegisterCommand('dp1', function()
    exports['ld-dispatch']:sendDispatch(
        {
            title = "Test Dispatch 1",
            code = "10-10B",
            values = {
                {
                    text = "Fudge Ln",
                    icon = "fa-solid fa-earth-americas",
                },
                {
                    text = "Priority 1",
                    icon = "fa-solid fa-hashtag",
                },
            },
            valuestwo = {}, -- DON'T TOUCH
            jobs = {"police", "ambulance"},
            active = false,-- DON'T TOUCH
            dispatchnumber = nil,-- DON'T TOUCH
            coords = vector3(0,0,0),
            blip = {
                blipid = 80,
                blipcolor = 1,
            }
        }
    )
end, false)


RegisterCommand('dp2', function()
    exports['ld-dispatch']:sendDispatch(
        {
            title = "Test Dispatch 2",
            code = "10-10A",
            values = {
                {
                    text = "Fudge Ln",
                    icon = "fa-solid fa-earth-americas",
                },
                {
                    text = "Priority 1",
                    icon = "fa-solid fa-hashtag",
                },
            },
            jobs = {"police", "ambulance"},
            coords = vector3(-2011.78,4514.13,28.62),
            blip = {
                blipid = 80,
                blipcolor = 1,
            },
            active = false,-- DON'T TOUCH
            dispatchnumber = nil,-- DON'T TOUCH
            date = nil, -- DONT TOUCH
            valuestwo = {}, -- DON'T TOUCH
        }
    )
end, false)

RegisterNUICallback('setActive', function(data,cb)
    TriggerServerEvent('ld-dispatch:setActive', data.id)
    ExecuteCommand(Config.MenuCommand)
    cb(true)
end)

RegisterNUICallback('setLocation', function(data,cb)
    QBCore.Functions.TriggerCallback('ld-dispatch:getLocation', function(locationData)
        if locationData then
            local x, y
            if type(locationData) == 'table' and locationData[1] and (type(locationData[1]) == 'table' or type(locationData[1]) == 'vector3') then
                local first = locationData[1]
                if type(first) == 'vector3' then
                    x, y = first.x, first.y
                elseif type(first) == 'table' then
                    x, y = first.x or first[1], first.y or first[2]
                end
            elseif type(locationData) == 'vector3' then
                x, y = locationData.x, locationData.y
            elseif type(locationData) == 'table' then
                x, y = locationData.x or locationData[1], locationData.y or locationData[2]
            end

            if x and y then
                SetNewWaypoint(x, y)
            end
        end
        cb(true)
    end, data.id)
end)

--  _                             _                                  ___                        _     
-- | |_   _ _ __  _ __  _   _  __| | _____   _____ ___  _ __ ___    ( _ )    _ ____      ____ _(_)___ 
-- | | | | | '_ \| '_ \| | | |/ _` |/ _ \ \ / / __/ _ \| '_ ` _ \   / _ \/\ | '_ \ \ /\ / / _` | / __|
-- | | |_| | | | | | | | |_| | (_| |  __/\ V / (_| (_) | | | | | | | (_>  < | |_) \ V  V / (_| | \__ \
-- |_|\__,_|_| |_|_| |_|\__, |\__,_|\___| \_(_)___\___/|_| |_| |_|  \___/\/ | .__/ \_/\_/ \__,_|_|___/
--                      |___/                                               |_|                       