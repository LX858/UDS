if Config.Framework ~= "esx" then
    return
end

debugprint("Loading ESX")

local export, obj = pcall(function()
    return exports.es_extended:getSharedObject()
end)

if export then
    ESX = obj
else
    TriggerEvent("esx:getSharedObject", function(obj)
        ESX = obj
    end)
end

debugprint("ESX loaded")

function GetIdentifier(source)
    return ESX.GetPlayerFromId(source)?.identifier
end

function GetSourceFromIdentifier(identifier)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)

    if xPlayer then
        return xPlayer.source
    end
end

function IsAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local isAdmin = xPlayer?.getGroup() == "superadmin"

    if not isAdmin then
        return IsPlayerAceAllowed(source, "command.lbphone_admin") == 1
    end

    return isAdmin
end

function HasItem(source, itemName)
    if GetResourceState("ox_inventory") == "started" then
        return (exports.ox_inventory:Search(source, "count", itemName) or 0) > 0
    elseif GetResourceState("qs-inventory") == "started" then
        return (exports["qs-inventory"]:GetItemTotalAmount(source, itemName) or 0) > 0
    end

    local xPlayer = ESX.GetPlayerFromId(source)

    return xPlayer.getInventoryItem(itemName).count > 0
end

function CreateUsableItem(item, cb)
    ESX.RegisterUsableItem(item, cb)
end

function GetCharacterName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local firstName, lastName

    if xPlayer.name then
        firstName = xPlayer.name
        lastName = ""
    else
        local name = MySQL.single.await("SELECT `name` FROM `users` WHERE `identifier` = ?", { GetIdentifier(source) })

        firstName = name?.name or GetPlayerName(source)
        lastName = ""
    end

    return firstName, lastName
end
