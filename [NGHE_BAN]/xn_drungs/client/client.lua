-- client.lua
local NpcLoc = {}
local Dealers = Config.Dealers
local sellRandom = math.random(1, 10)
local priceCocaine = Config.Price.cocaine
local target = Config.TARGET
local cooldownActive = false
local cooldownTime = 0
local vehicleBlip = nil
local missionVehiclePlate = nil
local dealerPeds = {}
local dealerZones = {}

local cooldown = Config.Cooldown

local function StartCooldown()
    cooldownActive = true
    local delay = math.random(cooldown.delivery.min, cooldown.delivery.max) * 60000
    cooldownTime = delay
    Citizen.CreateThread(function()
        while cooldownTime > 0 do
            Citizen.Wait(1000)
            cooldownTime = cooldownTime - 1000
        end
        cooldownActive = false
    end)
end

local function DebugPrint(...)
    if Config.debug then
        print(...)
    end
end

Citizen.CreateThread(function()
    DebugPrint("[xn_drungs] Thread started, loading model...")
    local model = GetHashKey('a_m_m_og_boss_01')
    local isLoaded = lib.requestModel(model)
    DebugPrint("[xn_drungs] Model load status:", isLoaded)
    if not isLoaded then 
        DebugPrint("[xn_drungs] ERROR: Failed to load model 'a_m_m_og_boss_01'")
        return 
    end

    for dealerKey, dealer in pairs(Config.Dealers.cocaine) do
        DebugPrint("[xn_drungs] Spawning ped for dealer: " .. dealerKey .. " at coords: " .. tostring(dealer.coords))
        
        -- Delete if already exists
        if dealerPeds[dealerKey] and DoesEntityExist(dealerPeds[dealerKey]) then
            DeleteEntity(dealerPeds[dealerKey])
        end

        local npc = CreatePed(1, model, dealer.coords.x, dealer.coords.y, dealer.coords.z, dealer.coords.w, false, true)
        FreezeEntityPosition(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedDiesWhenInjured(npc, false)
        SetPedCanPlayAmbientAnims(npc, false)
        SetPedCanRagdollFromPlayerImpact(npc, false)
        SetEntityInvincible(npc, true)
        
        dealerPeds[dealerKey] = npc
        DebugPrint("[xn_drungs] Ped spawned successfully for: " .. dealerKey .. " Entity ID: " .. npc)

        if target == 'ox' then
            local zoneId = exports.ox_target:addBoxZone({
                coords = vec3(dealer.coords.x, dealer.coords.y, dealer.coords.z + 1),
                size = vec3(1.5, 1.5, 1.5),
                rotation = 90,
                debug = drawZones,
                options = {{
                    name = 'yoda-oxyruns:buyCocaine_' .. dealerKey,
                    icon = 'fa-solid fa-cube',
                    label = 'Bắt đầu giao đu đủ',
                    onSelect = function()
                        Citizen.CreateThread(function()
                            if cooldownActive then
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = string.format(Locales.cooldown_wait, math.ceil(cooldownTime/60000)) })
                            else
                                local count = exports.ox_inventory:Search('count', 'goi_dudu_say') or 0
                                if count >= (Config.PackagesPerMission * Config.ConversionRate) then
                                    local policeCount = lib.callback.await("yoda-oxyruns:getPoliceCount", false) or 0
                                    local requiredCops = Config.RequiredCops or 3
                                    if policeCount < requiredCops then
                                        exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = string.format(Locales.need_police, requiredCops) })
                                        return
                                    end
                                    DebugPrint('TriggerServerEvent exchangeDrugs called for dealer ' .. dealerKey)
                                    TriggerServerEvent('yoda-oxyruns:exchangeDrugs', dealerKey)
                                else
                                    exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.need_goi_dudu_say })
                                end
                            end
                        end)
                    end
                }}
            })
            dealerZones[dealerKey] = zoneId
        else
            local name = 'target_buy_' .. dealerKey
            exports['qb-target']:AddCircleZone(name, vector3(dealer.coords.x, dealer.coords.y, dealer.coords.z + 1), 2.0, {
                name = name, debugPoly = false , useZ = true}, {
                options = {{label = 'Bắt đầu giao đu đủ', icon = 'fa-solid fa-cube', 
                action = function () 
                    Citizen.CreateThread(function()
                        if cooldownActive then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = string.format(Locales.cooldown_wait, math.ceil(cooldownTime/60000)) })
                        else
                            local count = exports.ox_inventory:Search('count', 'goi_dudu_say') or 0
                            if count >= (Config.PackagesPerMission * Config.ConversionRate) then
                                local policeCount = lib.callback.await("yoda-oxyruns:getPoliceCount", false) or 0
                                local requiredCops = Config.RequiredCops or 3
                                if policeCount < requiredCops then
                                    exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = string.format(Locales.need_police, requiredCops) })
                                    return
                                end
                                DebugPrint('TriggerServerEvent exchangeDrugs called for dealer ' .. dealerKey)
                                TriggerServerEvent('yoda-oxyruns:exchangeDrugs', dealerKey)
                            else
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.need_goi_dudu_say })
                            end
                        end
                    end)
                end}},
                distance = 2.0
            })
            dealerZones[dealerKey] = name
        end
    end
end)

RegisterNetEvent('yoda-oxyruns:startMission')
AddEventHandler('yoda-oxyruns:startMission', function(netId, plate, spawnCoords, dealerKey)
    StartCooldown()
    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local animDict = 'mp_common'
        local animName = 'givetake1_a'
        
        ClearPedTasks(playerPed)
        
        if not lib.requestAnimDict(animDict) then return end
        
        local propBag = CreateObject(GetHashKey("xm3_prop_xm3_bag_coke_01a"), 0, 0, 0, true, true, true)
        AttachEntityToEntity(propBag, playerPed, GetPedBoneIndex(playerPed, 0x188E), 0.08, -0.06, -0.01, 96.0, 20.0, 180.0, true, true, false, true, 1, true)
        
        local targetPed = dealerPeds[dealerKey]
        if targetPed and DoesEntityExist(targetPed) then
            TaskPlayAnim(targetPed, animDict, animName, 1.0, -1.0, 1000, 49, 0, false, false, false)
        end
        TaskPlayAnim(playerPed, animDict, animName, 1.0, -1.0, 1000, 49, 0, false, false, false)
        Citizen.Wait(1000)
        if targetPed and DoesEntityExist(targetPed) then
            ClearPedTasks(targetPed)
        end
        ClearPedTasks(playerPed)
        DeleteObject(propBag)

        exports.ox_lib:notify({ type = 'info', title = 'Giao đu đủ', description = Locales.vehicle_ready })

        missionVehiclePlate = plate
        exports['Renewed-Vehiclekeys']:addKey(plate)

        if vehicleBlip then
            RemoveBlip(vehicleBlip)
        end
        vehicleBlip = AddBlipForCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
        SetBlipSprite(vehicleBlip, 326)
        SetBlipColour(vehicleBlip, 3)
        SetBlipScale(vehicleBlip, 1.0)
        SetBlipAsShortRange(vehicleBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Mission Vehicle")
        EndTextCommandSetBlipName(vehicleBlip)

        TriggerEvent('yoda-oxyruns:initiateDelivery', netId, plate)
    end)
end)

RegisterNetEvent('yoda-oxyruns:endMission')
AddEventHandler('yoda-oxyruns:endMission', function()
    if vehicleBlip then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end
    missionVehiclePlate = nil
    exports["orbit-ui"]:Close()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if vehicleBlip and missionVehiclePlate then
            local playerPed = PlayerPedId()
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate == missionVehiclePlate then
                    RemoveBlip(vehicleBlip)
                    vehicleBlip = nil
                end
            end
        end
    end
end)


local function GetNPCLoc(index)
    return NpcLoc[index]
end

local function CreateNPCLoc(index)
    if (NpcLoc[index]) then
        DeleteLocalNPC(index)
    end

    NpcLoc[index] = {}

    local npc = CreatePed(5, 'a_m_m_og_boss_01' , Dealers.cocaine.npc1.coords.x, Dealers.cocaine.npc1.coords.y, Dealers.cocaine.npc1.coords.z, 0, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedComponentVariation(npc, 3, 1, 4, 1) -- Shirt
    SetPedComponentVariation(npc, 4, 0, 0, 1) -- Pants
    SetPedComponentVariation(npc, 0, 0, 1, 0) -- Hat

    NpcLoc[index].npc = npc
end

local function DeleteLocalNPC(index)
    if (NpcLoc[index]) then 
        DeleteEntity(NpcLoc[index].npc)
        NpcLoc[index] = nil
    end 
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        exports["orbit-ui"]:Close()
        for _, npc in pairs(dealerPeds) do
            if npc and DoesEntityExist(npc) then
                DeleteEntity(npc)
            end
        end
    end
end)
