-- server.lua

local inventory = exports.ox_inventory
local QBCore = exports['qb-core']:GetCoreObject()
local activeMissionVehicles = {}
local dealerCooldowns = {}

local function GetPoliceCount()
    local numCops = GlobalState['police_count'] or 0
    return numCops
end

lib.callback.register("yoda-oxyruns:getPoliceCount", function(source)
    return GetPoliceCount()
end)

RegisterNetEvent('yoda-oxyruns:exchangeDrugs')
AddEventHandler('yoda-oxyruns:exchangeDrugs', function(dealerKey)
    local source = source
    
    if not dealerKey or not Config.Dealers.cocaine[dealerKey] then
        dealerKey = "npc1"
    end

    -- Check global dealer cooldown
    if dealerCooldowns[dealerKey] and os.time() < dealerCooldowns[dealerKey] then
        local timeLeft = dealerCooldowns[dealerKey] - os.time()
        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60
        local timeLeftStr = string.format("%d phút %d giây", minutes, seconds)
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', title = 'Giao đu đủ', description = string.format("Địa điểm này đang hồi chiêu, vui lòng đợi %s", timeLeftStr) })
        return
    end

    local policeCount = GetPoliceCount()
    local requiredCops = Config.RequiredCops or 3
    if policeCount < requiredCops then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', title = 'Giao đu đủ', description = string.format(Locales.need_police, requiredCops) })
        return
    end
    
    local checkItem = inventory:GetItem(source, 'goi_dudu_say', nil, true)
    local conversionRate = Config.ConversionRate or 3
    local packagesPerMission = Config.PackagesPerMission or 5
    local requiredGoidudu = packagesPerMission * conversionRate -- 5 * 3 = 15

    if checkItem and checkItem >= requiredGoidudu then
        inventory:RemoveItem(source, 'goi_dudu_say', requiredGoidudu)
        
        -- Spawn random mission vehicle
        local dealerConfig = Config.Dealers.cocaine[dealerKey]
        local spawnCoords = dealerConfig.vehicleSpawn

        local missionVehicles = Config.MissionVehicles
        local randomVehicleModel = missionVehicles[math.random(1, #missionVehicles)]
        local vehicleHash = GetHashKey(randomVehicleModel)
        local vehicle = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, true)
        
        local timeout = 0
        while not DoesEntityExist(vehicle) and timeout < 100 do
            Wait(50)
            timeout = timeout + 1
        end
        
        if DoesEntityExist(vehicle) then
            dealerCooldowns[dealerKey] = os.time() + (Config.Cooldown.globalDealer or 3) * 60
            activeMissionVehicles[source] = vehicle
            local plate = GetVehicleNumberPlateText(vehicle)
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            
            -- Add 5 packages to the vehicle trunk
            local trunkId = 'trunk' .. plate:gsub("%s+", "")
            local success = inventory:AddItem(trunkId, Config.itemhang, packagesPerMission)
            if success then
                if Config.debug then print('^2[OxyRuns]^7 SUCCESS: Added ' .. packagesPerMission .. 'x package to trunk ' .. trunkId) end
                TriggerClientEvent('ox_lib:notify', source, { type = 'success', title = 'Giao đu đủ', description = Locales.trunk_loaded })
            else
                if Config.debug then print('^1[OxyRuns]^7 FAILED: Could not add package to trunk ' .. trunkId) end
                TriggerClientEvent('ox_lib:notify', source, { type = 'error', title = 'Giao đu đủ', description = Locales.trunk_load_fail })
            end
            
            TriggerClientEvent('yoda-oxyruns:startMission', source, netId, plate, spawnCoords, dealerKey)
        else
            -- Refund player if vehicle fails to spawn
            inventory:AddItem(source, 'goi_dudu_say', requiredGoidudu)
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', title = 'Giao đu đủ', description = Locales.vehicle_spawn_fail })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', title = 'Giao đu đủ', description = Locales.need_goi_dudu_say })
    end
end)


RegisterNetEvent('yoda-oxyruns:verifyDrugs')
AddEventHandler('yoda-oxyruns:verifyDrugs', function(priceCocaine)
    local source = source
    local nPackages = inventory:GetItem(source, Config.itemhang, nil, true)

    if nPackages == 0 then
        TriggerClientEvent('yoda-oxyruns:checkDrugs', source, false)
    else 
        TriggerClientEvent('yoda-oxyruns:startSelling', source, priceCocaine, nPackages)
    end
end)


local failedPackages = {}

AddEventHandler('playerDropped', function()
    local source = source
    failedPackages[source] = nil
    if activeMissionVehicles[source] and DoesEntityExist(activeMissionVehicles[source]) then
        DeleteEntity(activeMissionVehicles[source])
    end
    activeMissionVehicles[source] = nil
end)

RegisterNetEvent('yoda-oxyruns:deleteMissionVehicle')
AddEventHandler('yoda-oxyruns:deleteMissionVehicle', function()
    local source = source
    local vehicle = activeMissionVehicles[source]
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
    activeMissionVehicles[source] = nil
end)

lib.callback.register('yoda-oxyruns:sellToBuyer', function(source)
    local nPackages = inventory:GetItem(source, Config.itemhang, nil, true)

    if not nPackages or nPackages < 1 then
        return { success = false, reason = 'no_package' }
    end

    if not inventory:CanCarryItem(source, 'cash', Config.Price.priceCocaineSelling) then
        return { success = false, reason = 'inventory_full' }
    end
    inventory:RemoveItem(source, Config.itemhang, 1)
    inventory:AddItem(source, 'cash', Config.Price.priceCocaineSelling)

    -- Give blueprint chance
    if Config.Blueprint and Config.Blueprint.enabled then
        local chance = math.random(1, 100)
        if chance <= Config.Blueprint.chance then
            if inventory:CanCarryItem(source, Config.Blueprint.item, 1) then
                inventory:AddItem(source, Config.Blueprint.item, 1)
                TriggerClientEvent('ox_lib:notify', source, { type = 'success', title = 'Giao đu đủ', description = 'Bạn đã nhận được 1x Bản vẽ vũ khí!' })
            else
                TriggerClientEvent('ox_lib:notify', source, { type = 'warning', title = 'Giao đu đủ', description = 'Túi đồ đầy, không thể nhận Bản vẽ vũ khí!' })
            end
        end
    end

    return { success = true, sold = true }
end)

RegisterNetEvent('yoda-oxyruns:retrievePackage')
AddEventHandler('yoda-oxyruns:retrievePackage', function()
    local source = source
    local count = failedPackages[source] or 0
    if count > 0 then
        if not inventory:CanCarryItem(source, 'cash', Config.Price.priceCocaineSelling) then
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', title = 'Giao đu đủ', description = Locales.inventory_full })
            return
        end
        failedPackages[source] = count - 1
        inventory:AddItem(source, 'cash', Config.Price.priceCocaineSelling)
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', title = 'Giao đu đủ', description = Locales.package_retrieved })
    else
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', title = 'Giao đu đủ', description = Locales.no_packages_to_retrieve })
    end
end)

RegisterNetEvent('yoda-oxyruns:server:policeDispatch')
AddEventHandler('yoda-oxyruns:server:policeDispatch', function(buyerCoordsList)
    -- Shuffle the coordinates list to hide the delivery sequence from police dispatch numbers
    for i = #buyerCoordsList, 2, -1 do
        local j = math.random(i)
        buyerCoordsList[i], buyerCoordsList[j] = buyerCoordsList[j], buyerCoordsList[i]
    end

    -- Construct coordinates list for ld-dispatch
    local dispatchCoords = {}
    for i = 1, #buyerCoordsList do
        local coords = buyerCoordsList[i]
        dispatchCoords[#dispatchCoords+1] = { x = coords.x, y = coords.y, z = coords.z }
    end

    local data = {
        title = "TÌNH NGHI GIAO ĐU ĐỦ",
        code = "11-10B",
        values = {
            {
                text = "Tình nghi giao đu đủ",
                icon = "fa-solid fa-earth-americas",
            },
            {
                text = "2 sao",
                icon = "fa-solid fa-hashtag",
            },
        },
        valuestwo = {}, -- DON'T TOUCH
        jobs = {"police"},
        active = false,-- DON'T TOUCH
        dispatchnumber = nil,-- DON'T TOUCH
        coords = dispatchCoords,
        blip = {
            blipid = 171,
            blipcolor = 1,
        }
    }
    TriggerEvent('ld-dispatch:addDispatch', data)
end)
