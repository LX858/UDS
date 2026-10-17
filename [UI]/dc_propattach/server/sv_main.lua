local QBCore, ESX = nil, nil

CreateThread(function()
    if Config.Framework == "qb" then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == "esx" then
        ESX = exports["es_extended"]:getSharedObject()
    end
end)

RegisterNetEvent('dc_propattach:server:checkAdmin', function()
    local src = source
    local canUse = false
    if not Config.OnlyAdmins then
        canUse = true
    else
        if Config.Framework == "qb" then
            if QBCore then
                local Player = QBCore.Functions.GetPlayer(source)
                if Player then
                    if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') then
                        canUse = true
                    end
                end
            end
        elseif Config.Framework == "esx" then
            if ESX then
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer then
                    local playerGroup = xPlayer.getGroup()
                    if playerGroup == "admin" or playerGroup == "superadmin" then
                        canUse = true
                    end
                end
            end
        elseif Config.Framework == "none" then
            canUse = true
        end
    end
    TriggerClientEvent('dc_propattach:client:admincheck', src, canUse)
end)