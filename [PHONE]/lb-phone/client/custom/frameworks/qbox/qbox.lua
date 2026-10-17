if Config.Framework ~= "qbox" then
    return
end

debugprint("Loading Qbox")

QB = exports["qb-core"]:GetCoreObject()

PlayerJob = {}
PlayerData = {}

while not LocalPlayer.state.isLoggedIn do
    Wait(500)
end

FrameworkLoaded = true

debugprint("Qbox loaded")

PlayerJob = QB.Functions.GetPlayerData().job
PlayerData = QB.Functions.GetPlayerData()

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    PlayerData = QB.Functions.GetPlayerData()

    FetchPhone()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    PlayerData = {}

    LogOut()
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(newData)
    PlayerData = newData

    if not Config.Item.Require or Config.Item.Unique then
        return
    end

    Wait(500)

    if currentPhone and not HasPhoneItem() then
        OnDeath()
    end
end)

RegisterNetEvent("qbx_core:client:playerDataUpdated", function(key, value)
    if type(key) ~= "string" then return end
    PlayerData[key] = value
    if key == "items" and Config.Item.Require and not Config.Item.Unique then
        Wait(500)
        if currentPhone and not HasPhoneItem() then OnDeath() end
    end
end)

RegisterNetEvent("qbx_core:client:metadataUpdated", function(key, value)
    PlayerData.metadata = PlayerData.metadata or {}
    PlayerData.metadata[key] = value
end)

RegisterNetEvent("qbx_core:client:moneyUpdated", function(moneyType, balance)
    PlayerData.money = PlayerData.money or {}
    PlayerData.money[moneyType] = balance
    if moneyType == "bank" then SendReactMessage("wallet:setBalance", math.floor(balance)) end
end)

AddEventHandler("ox_inventory:updateInventory", function()
    if not Config.Item.Require or Config.Item.Unique then return end
    PlayerData.items = exports.ox_inventory:GetPlayerItems()
    Wait(500)
    if currentPhone and not HasPhoneItem() then OnDeath() end
end)

function CanOpenPhone()
    local metadata = QB.Functions.GetPlayerData().metadata

    if metadata.ishandcuffed or metadata.isdead or metadata.inlaststand then
        return false
    end

    return true
end
