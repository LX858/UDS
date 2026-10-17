local isUiOpen = false
local QBCore = nil

if GetResourceState('qb-core') == 'started' then
    pcall(function()
        QBCore = exports['qb-core']:GetCoreObject()
    end)
end

-- Open UI helper
local function OpenUpdateUI()
    if isUiOpen then return end

    if QBCore and QBCore.Functions and QBCore.Functions.TriggerCallback then
        QBCore.Functions.TriggerCallback('xn_update:server:getUpdatesData', function(updates, isAdmin)
            isUiOpen = true
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'open',
                updates = updates or {},
                isAdmin = isAdmin or false,
                serverName = Config.ServerName or "UNDER STAR ROLEPLAY",
                categories = Config.Categories or {}
            })
        end)
    else
        TriggerServerEvent('xn_update:server:getUpdatesData')
    end
end

-- Close UI helper
local function CloseUpdateUI()
    if not isUiOpen then return end
    isUiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

-- Event receive fallback for non-callback method
RegisterNetEvent('xn_update:client:receiveUpdatesData', function(updates, isAdmin)
    if isUiOpen then return end
    isUiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        updates = updates or {},
        isAdmin = isAdmin or false,
        serverName = Config.ServerName or "UNDER STAR ROLEPLAY",
        categories = Config.Categories or {}
    })
end)

-- Auto Open on player join / spawn
local hasLoaded = false

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    if Config.AutoOpenOnJoin and not hasLoaded then
        hasLoaded = true
        Citizen.SetTimeout(2000, function()
            OpenUpdateUI()
        end)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if Config.AutoOpenOnJoin and not hasLoaded then
        hasLoaded = true
        Citizen.SetTimeout(2000, function()
            OpenUpdateUI()
        end)
    end
end)

-- Event trigger from other scripts
RegisterNetEvent('xn_update:client:openUI', function()
    OpenUpdateUI()
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseUpdateUI()
    cb('ok')
end)

RegisterNUICallback('postUpdate', function(data, cb)
    TriggerServerEvent('xn_update:server:postUpdate', data)
    cb('ok')
end)

RegisterNUICallback('editUpdate', function(data, cb)
    TriggerServerEvent('xn_update:server:editUpdate', data)
    cb('ok')
end)

RegisterNUICallback('deleteUpdate', function(data, cb)
    TriggerServerEvent('xn_update:server:deleteUpdate', data.id)
    cb('ok')
end)

RegisterNUICallback('openUrl', function(data, cb)
    if data and data.url then
        -- Open via NUI native invoke
    end
    cb('ok')
end)

-- Client Event to refresh updates after post/delete
RegisterNetEvent('xn_update:client:refreshUpdates', function(updates)
    if isUiOpen then
        SendNUIMessage({
            action = 'updateList',
            updates = updates
        })
    end
end)

-- Register Single Command (/newupdate -> opens update list UI)
RegisterCommand(Config.CommandName or 'newupdate', function()
    OpenUpdateUI()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. (Config.CommandName or 'newupdate'), 'Xem nhật ký cập nhật mới nhất của máy chủ')
