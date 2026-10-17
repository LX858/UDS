local Core
Config.Framework = "STANDALONE"

TriggerEvent("__cfx_export_qb-core_GetCoreObject", function(getCore)
    Core = getCore()
    Config.Framework = "QBCore"
end)

TriggerEvent("__cfx_export_es_extended_getSharedObject", function(getCore)
    Core = getCore()
    Config.Framework = "ESX"
end)

CreateThread(function()
    Citizen.Wait(1000)
    if Core == nil then
        TriggerEvent("esx:getSharedObject", function(obj)
            Core = obj
            Config.Framework = "ESX"
        end)
    end
end)

local cachedNames = {}
function GetPlayerIdentity(source)
    if cachedNames[source] ~= nil then
        return cachedNames[source]
    end

    if Config.Framework == "QBCore" then
        local xPlayer = Core.Functions.GetPlayer(source)

        local timeout = 50
        while xPlayer == nil and timeout > 0 do
            Citizen.Wait(100)
            xPlayer = Core.Functions.GetPlayer(source)
            timeout = timeout - 1
        end

        if xPlayer == nil then return "Example Name" end

        cachedNames[source] = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
    elseif Config.Framework == "ESX" then
        local xPlayer = Core.GetPlayerFromId(source)
        local timeout = 50
        while xPlayer == nil and timeout > 0 do
            Citizen.Wait(100)
            xPlayer = Core.GetPlayerFromId(source)
            timeout = timeout - 1
        end

        if xPlayer == nil then return "Example Name" end

        cachedNames[source] = xPlayer.getName()
    else
        cachedNames[source] = GetPlayerName(source)
    end

    return cachedNames[source]
end

function GetRewardPlayerCountMultiplier(playerCount)
    local count = tonumber(playerCount) or 1
    if count < 1 then count = 1 end

    local penalty = tonumber(Config.RewardPlayerCountPenalty) or 0.2
    local mult = 1 - ((count - 1) * penalty)
    if mult < 0 then mult = 0 end
    return mult
end

function CalcRewardPerPlayer(baseReward, playerCount)
    return math.floor((tonumber(baseReward) or 0) * GetRewardPlayerCountMultiplier(playerCount))
end

function Notify(source, msg)
    if source == nil then return end
    if Config.UseBuiltInNotifications and Config.useModernUI then
        TriggerClientEvent("17mov_DrawDefaultNotification"..GetCurrentResourceName(), source, msg)
    else
        if Config.Framework == "QBCore" then
            TriggerClientEvent("QBCore:Notify", source, msg)
        elseif Config.Framework == "ESX" then
            TriggerClientEvent("esx:showNotification", source, msg)
        else
            TriggerClientEvent("17mov_DrawDefaultNotification"..GetCurrentResourceName(), source, msg)
        end
    end
end

function Pay(source, amount, lobbySize, rawProgress)
    local jobProgress = amount / Config.OnePercentWorth
    local itemsToGive = math.floor(jobProgress)
    if Config.Framework == "QBCore" then
        local Player = Core.Functions.GetPlayer(source)
        if Player ~= nil and Player.Functions ~= nil then
            Player.Functions.AddMoney("bank", amount)
            local itemsToAdd = {}
            for k, item in pairs(Config.RewardItemsToGive) do
                if jobProgress >= item.minimumProgressPercent and math.random(100) <= item.chance then
                    if itemsToAdd[item.item_name] == nil then
                        itemsToAdd[item.item_name] = 0
                    end

                    itemsToAdd[item.item_name] = itemsToAdd[item.item_name] + item.amount
                end
            end

            for k,v in pairs(itemsToAdd) do
                Player.Functions.AddItem(k, v)
            end
        end
    elseif Config.Framework == "ESX" then
        local xPlayer = Core.GetPlayerFromId(source)
        if xPlayer ~= nil and xPlayer.addMoney ~= nil then
            xPlayer.addMoney(amount)

            local itemsToAdd = {}
            for k, item in pairs(Config.RewardItemsToGive) do
                if jobProgress >= item.minimumProgressPercent and math.random(100) <= item.chance then
                    if itemsToAdd[item.item_name] == nil then
                        itemsToAdd[item.item_name] = 0
                    end

                    itemsToAdd[item.item_name] = itemsToAdd[item.item_name] + item.amount
                end
            end

            for k,v in pairs(itemsToAdd) do
                xPlayer.addInventoryItem(k, v)
            end
        end
    else
        -- Configure here ur payment
    end

    exports['xn-sellitem']:xn_sellitem_leaderboard(source, 'xaydung', amount)
end

function PayPenalty(source, amount)
    if Config.Framework == "QBCore" then
        local Player = Core.Functions.GetPlayer(source)
        if Player ~= nil and Player.Functions ~= nil then
            Player.Functions.RemoveMoney("cash", amount)
        end
    elseif Config.Framework == "ESX" then
        local xPlayer = Core.GetPlayerFromId(source)
        if xPlayer ~= nil and xPlayer.removeMoney ~= nil then
            xPlayer.removeMoney(amount)
        end
    else
        -- Configure here ur remove money func
    end
end

function GetPlayerMoney(source, accountType)
    accountType = accountType or "cash"

    if Config.Framework == "QBCore" then
        local Player = Core.Functions.GetPlayer(source)
        if Player ~= nil and Player.Functions ~= nil then
            return Player.Functions.GetMoney(accountType) or 0
        end
    elseif Config.Framework == "ESX" then
        local xPlayer = Core.GetPlayerFromId(source)
        if xPlayer ~= nil then
            if accountType == "bank" then
                return xPlayer.getAccount("bank").money or 0
            end
            return xPlayer.getMoney() or 0
        end
    else
        -- Configure here ur get money func
    end

    return 0
end

function HasEnoughMoney(source, amount, accountType)
    return GetPlayerMoney(source, accountType) >= (tonumber(amount) or 0)
end

function ChargeVehicleDeposit(source, amount, accountType)
    amount = tonumber(amount) or 0
    if amount <= 0 then
        return true
    end

    accountType = accountType or "cash"

    if not HasEnoughMoney(source, amount, accountType) then
        return false
    end

    if Config.Framework == "QBCore" then
        local Player = Core.Functions.GetPlayer(source)
        if Player ~= nil and Player.Functions ~= nil then
            return Player.Functions.RemoveMoney(accountType, amount)
        end
    elseif Config.Framework == "ESX" then
        local xPlayer = Core.GetPlayerFromId(source)
        if xPlayer ~= nil then
            if accountType == "bank" then
                xPlayer.removeAccountMoney("bank", amount)
            else
                xPlayer.removeMoney(amount)
            end
            return true
        end
    else
        -- Configure here ur remove money func
        return true
    end

    return false
end

function RefundVehicleDeposit(source, amount, accountType)
    amount = tonumber(amount) or 0
    if amount <= 0 then
        return
    end

    accountType = accountType or "cash"

    if Config.Framework == "QBCore" then
        local Player = Core.Functions.GetPlayer(source)
        if Player ~= nil and Player.Functions ~= nil then
            Player.Functions.AddMoney(accountType, amount)
        end
    elseif Config.Framework == "ESX" then
        local xPlayer = Core.GetPlayerFromId(source)
        if xPlayer ~= nil then
            if accountType == "bank" then
                xPlayer.addAccountMoney("bank", amount)
            else
                xPlayer.addMoney(amount)
            end
        end
    else
        -- Configure here ur add money func
    end
end

function IsHaveRequiredItem(source)
    if Config.RequiredItem ~= "none" then
        if Config.Framework == "QBCore" then
            local counter = 0
            for k,v in pairs(Core.Functions.GetPlayer(source).PlayerData.items) do
                if v.name == Config.RequiredItem then
                    local amount = v.amount
                    if amount == nil then amount = v.count end
                    counter = counter + amount
                    if amount > 0 then break end
                end
            end

            return counter > 0
        elseif Config.Framework == "ESX" then
            return Core.GetPlayerFromId(source).getInventoryItem(Config.RequiredItem).count > 0
        end
    end

    return true
end
function GetPlayerJob(source)
    if source == nil or type(source) ~= "number" then return "unknown" end
    if Config.Framework == "QBCore" then
        return Core.Functions.GetPlayer(source).PlayerData.job.name
    elseif Config.Framework == "ESX" then
        return Core.GetPlayerFromId(source).job.name
    else
        return "unknown"
    end
end