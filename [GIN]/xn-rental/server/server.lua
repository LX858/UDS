local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent("ars-rental:removeMoney", function(data)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - vector3(data.coords.xyz))

    if distance > 1 then return print(source .. " probably modder") end
    exports.ox_inventory:RemoveItem(source, 'money', data.price)
end)

-- Callback để kiểm tra có taxi driver nào đang on duty không
lib.callback.register('ars-rental:checkTaxiDrivers', function(source)
    if not Config.TaxiSystem.enable then 
        print("^1[DEBUG] Taxi system disabled^7")
        return false 
    end
    
    local numTaxiDrivers = GlobalState['taxi_count'] or 0    
    -- Fallback to QBCore
    local players = QBCore.Functions.GetQBPlayers()
    print("^3[DEBUG] Fallback to QBCore, checking " .. #players .. " players^7")
    
    for k, v in pairs(players) do
        if v and v.PlayerData and v.PlayerData.job and v.PlayerData.job.name == 'taxi' and v.PlayerData.job.onduty then
            numTaxiDrivers = numTaxiDrivers + 1
            print("^2[DEBUG] Found taxi driver: " .. (v.PlayerData.charinfo.firstname or "Unknown") .. "^7")
        end
    end
    
    print("^1[DEBUG] Total taxi drivers: " .. numTaxiDrivers .. "^7")
    return numTaxiDrivers > 0
end)

-- Callback để kiểm tra xem túi đồ của người chơi có đủ chỗ trống để chứa chìa khóa xe không
lib.callback.register('ars-rental:canCarryKey', function(source)
    return exports.ox_inventory:CanCarryItem(source, 'vehiclekey', 1)
end)

