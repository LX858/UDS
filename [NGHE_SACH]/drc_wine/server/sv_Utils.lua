lib.locale()
local ver = '1.0.0'

local RegisterUsable = nil


local function AutoDetectFramework()
    if GetResourceState("es_extended") == "started" then
        return "ESX"
    elseif GetResourceState("qb-core") == "started" then
        return "qbcore"
    else
        return "standalone"
    end
end

if Config.Framework == "auto-detect" then
    Config.Framework = AutoDetectFramework()
end

CreateThread(function()
    if GetResourceState(GetCurrentResourceName()) == 'started' then
        print('DRC_WINE STARTED ON VERSION: ' .. ver)
    end
end)

if Config.Framework == "ESX" then
    if Config.NewESX then
        ESX = exports["es_extended"]:getSharedObject()
        RegisterUsable = ESX.RegisterUsableItem
        TriggerEvent('esx_society:registerSociety', 'wine', 'wine', 'society_wine', 'society_wine',
        'society_wine', { type = 'private' })
    else
        ESX = nil
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        RegisterUsable = ESX.RegisterUsableItem
        TriggerEvent('esx_society:registerSociety', 'wine', 'wine', 'society_wine', 'society_wine',
        'society_wine', { type = 'private' })
    end
elseif Config.Framework == "qbcore" then
    QBCore = nil
    QBCore = exports['qb-core']:GetCoreObject()
    RegisterUsable = QBCore.Functions.CreateUseableItem
elseif Config.Framework == "standalone" then
    -- ADD YOU FRAMEWORK
end

for k, v in pairs(Config.Consumables) do
    RegisterUsable(k, function(source)
        local src = source
        if v.Remove then
            if GetItem(v.RemoveItem, v.RemoveItemCount, src) then
                RemoveItem(v.RemoveItem, v.RemoveItemCount, src)
                if v.Add then
                    AddItem(v.AddItem, v.AddItemCount, src)
                end
                TriggerClientEvent('drc_wine:consumables', src, v.ProgressBar, v.animation, v.duration, v.Effect)
            end
        else
            if v.Add then
                AddItem(v.AddItem, v.AddItemCount, src)
            end
            TriggerClientEvent('drc_wine:consumables', src, v.ProgressBar, v.animation, v.duration, v.Effect)
        end
    end)
end

-- for k, v in pairs(Config.WineCosumables) do
--     RegisterUsable(k, function(source)
--         local src = source
        
--         TriggerClientEvent('drc_wine:WineCosumables', src, {itemname = k, label = v.label, glassitemname = v.glassname, emptyglass = v.emptyglass, emptybottleitemname = v.emptybottlename, prop = v.prop})
--     end) 
-- end

RegisterNetEvent('drc_wine:WineBottle')
AddEventHandler('drc_wine:WineBottle', function(data)
    for k, v in pairs(Config.Bottles) do
        if k == data.item then
            local src = source
            if v.Remove then
                if GetItem(v.RemoveItem, v.RemoveItemCount, src) then
                    RemoveItem(v.RemoveItem, v.RemoveItemCount, src)
                    if v.Add then
                        AddItem(v.AddItem, v.AddItemCount, src)
                    end
                    TriggerClientEvent('drc_wine:consumables', src, v.ProgressBar, v.animation, v.duration, v.Effect)
                end
            else
                if v.Add then
                    AddItem(v.AddItem, v.AddItemCount, src)
                end
                TriggerClientEvent('drc_wine:consumables', src, v.ProgressBar, v.animation, v.duration, v.Effect)
            end
        end
    end
end)

local webhook = "YOUR_WEBHOOK"
function Logs(source, message, type)
    if message ~= nil then
        if Config.Logs.enabled then
            local license = nil
            for k, v in pairs(GetPlayerIdentifiers(source)) do
                if string.sub(v, 1, string.len("license:")) == "license:" then
                    license = v
                end
            end
            if Config.Logs.type == "ox_lib" then
                lib.logger(source, "wine", message)
            elseif Config.Logs.type == "webhook" then
                if type == "job" then
                    webhook = "https://discord.com/api/webhooks/1009031563989745824/KONAO2RihIQ_KmXwbj3x7uHXlCDBQeP0K8nF58aEvWDb6fvQd6jUQnmzBnZMUofKK5MX"

                    local embed = {
                        {
                            ["color"] = 2600155,
                            ["title"] = "Player: **" .. GetPlayerName(source) .. " | License: " .. license .. " **",
                            ["description"] = message,
                            ["footer"] = {
                                ["text"] = "Logs by DRC SCRIPTS for DRC wine!",
                            },
                        }
                    }
                    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST',
                        json.encode({ username = "DRC wine", embeds = embed,
                            avatar_url = "https://i.imgur.com/RclET8O.png" })
                        , { ['Content-Type'] = 'application/json' })
                end
            end
        end
    end
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
        if Config.Inventory == "ox" then
            for _, v in pairs(Config.wine.Stashes) do
                if v.job then
                    exports.ox_inventory:RegisterStash(v.name, v.label, v.Slots, v.Weight, nil, { [v.job] = 0 }, v.coords)
                else
                    exports.ox_inventory:RegisterStash(v.name, v.label, v.Slots, v.Weight, nil, nil, v.coords)
                end
            end
        end
    end
end)

function BanPlayer(source, message)
    if Config.AnticheatBan then
        --Example of usage for SQZ ANTICHEAT (Higly recommended Anticheat!)
        exports['sqz_anticheat']:BanPlayer(source, message)
    end
end

function AddSocietyMoney(count, job)
    if Config.Framework == "ESX" then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. job, function(account)
            account.addMoney(count)
        end)
    elseif Config.Framework == "qbcore" then
        exports['qb-management']:AddMoney(job, count)
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function GetItem(name, count, source)
    if Config.Debug then print("[DRC WINE DEBUG] GetItem check - name:", name, "count:", count, "source:", source) end
    if GetResourceState("ox_inventory") == "started" then
        local itemCount = exports.ox_inventory:Search(source, 'count', name) or 0
        if Config.Debug then print("[DRC WINE DEBUG] GetItem (ox_inventory) found count:", itemCount) end
        return itemCount >= count
    elseif Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getInventoryItem(name).count >= count then
            return true
        else
            return false
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if xPlayer.Functions.GetItemByName(name) ~= nil then
            if xPlayer.Functions.GetItemByName(name).amount >= count then
                return true
            else
                return false
            end
        else
            return false
        end
    elseif Config.Framework == "standalone" then
        -- ADD YOU FRAMEWORK
    end
end

function AddItem(name, count, source)
    if Config.Debug then print("[DRC WINE DEBUG] AddItem - name:", name, "count:", count, "source:", source) end
    if GetResourceState("ox_inventory") == "started" then
        exports.ox_inventory:AddItem(source, name, count)
    elseif Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addInventoryItem(name, count)
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.AddItem(name, count, nil, nil)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[name], "add", count)
    elseif Config.Framework == "standalone" then
        -- ADD YOU FRAMEWORK
    end
end

function RemoveItem(name, count, source)
    if Config.Debug then print("[DRC WINE DEBUG] RemoveItem - name:", name, "count:", count, "source:", source) end
    if GetResourceState("ox_inventory") == "started" then
        exports.ox_inventory:RemoveItem(source, name, count)
    elseif Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeInventoryItem(name, count)
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.RemoveItem(name, count, nil, nil)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[name], "remove", count)
    elseif Config.Framework == "standalone" then
        -- ADD YOU FRAMEWORK
    end
end

function GetMoney(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getMoney() >= count then
            return true
        else
            return false
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if xPlayer.Functions.GetMoney('cash') >= count then
            return true
        else
            return false
        end
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function GetBank(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getAccount('bank').money >= count then
            return true
        else
            return false
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if xPlayer.Functions.GetMoney('bank') >= count then
            return true
        else
            return false
        end
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function TotalBank(source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getAccount('bank').money
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        return xPlayer.Functions.GetMoney('bank')
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function TotalCash(source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getMoney()
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        return xPlayer.Functions.GetMoney('cash')
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function RemoveMoney(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeMoney(count)
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.RemoveMoney('cash', count)
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function RemoveBank(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeAccountMoney('bank', count)
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.RemoveMoney('bank', count)
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function AddMoney(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addMoney(count)
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.AddMoney('cash', count)
    elseif Config.Framework == "standalone" then
        -- ADD YOUR FRAMEWORK
    end
end

function GetJobName(source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.job.name
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        return xPlayer.PlayerData.job.name
    elseif Config.Framework == "standalone" then
        -- ADD YOU FRAMEWORK
    end
end

if Config.Clothing == "esx_skin" then
    ESX.RegisterServerCallback('drc_wine:getPlayerDressing', function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)

        TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
            local count  = store.count('dressing')
            local labels = {}

            for i = 1, count, 1 do
                local entry = store.get('dressing', i)
                table.insert(labels, entry.label)
            end

            cb(labels)
        end)
    end)

    ESX.RegisterServerCallback('drc_wine:getPlayerOutfit', function(source, cb, num)
        local xPlayer = ESX.GetPlayerFromId(source)

        TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
            local outfit = store.get('dressing', num)
            cb(outfit.skin)
        end)
    end)
end

RegisterNetEvent('drc_wine:server:add', function(status, amount)
    if Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)

        if not Player then return end
        if tostring(status) == "thirst" or tostring(status) == "hunger" then
            Player.Functions.SetMetaData(tostring(status), tonumber(amount))
            TriggerClientEvent('hud:client:UpdateNeeds', source, Player.PlayerData.metadata[tostring(status)], tonumber(amount))

        end
    else
        TriggerClientEvent("esx_status:add",source,tostring(status),tonumber(amount))
    end
end)

RegisterNetEvent('drc_wine:server:OpenInventory', function(keyid, weight, slots)
    local src = source
    exports['qb-inventory']:OpenInventory(src, 'stash_' .. keyid, {
            maxweight = weight,
            slots = slots,
    })
end)

RegisterNetEvent('drc_wine:WineCosumables')
AddEventHandler('drc_wine:WineCosumables', function(data)
    local src = source
    if GetItem(data.item, 1, src) and GetItem(data.emptyglass, 1, src) then
        RemoveItem(data.item, 1, src)
        RemoveItem(data.emptyglass, 1, src)
        AddItem(data.bottle, 1, src)
        AddItem(data.glass, 1, src)
    end
end)