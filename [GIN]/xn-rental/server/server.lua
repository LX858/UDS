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
    
    print("^1[DEBUG] Total taxi drivers: " .. numTaxiDrivers .. "^7")
    return numTaxiDrivers > 0
end)

-- Callback để kiểm tra xem túi đồ của người chơi có đủ chỗ trống để chứa chìa khóa xe không
lib.callback.register('ars-rental:canCarryKey', function(source)
    return exports.ox_inventory:CanCarryItem(source, 'vehiclekey', 1)
end)

