-- cl_buyers.lua

local NpcBuyers = Config.Buyers
local priceCocaineSelling = Config.Price.priceCocaineSelling
local target = Config.TARGET

local currentBuyerPed = nil
local currentBuyerZone = nil
local currentBlip = nil
local lastBuyerIndex = nil
local selectedBuyers = {}

local cooldown = Config.Cooldown

local deliveryCount = 0
local missionVehicleNetId = nil
local missionVehiclePlate = nil

local function IsPlayerInMissionVehicle()
    if not missionVehiclePlate then return false end
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate == missionVehiclePlate then
            return true
        end
    end
    return false
end

local function CleanUpBuyer()
    if currentBuyerZone then
        if target == 'ox' then
            exports.ox_target:removeZone(currentBuyerZone)
        else
            exports['qb-target']:RemoveZone('target_sell')
        end
        currentBuyerZone = nil
    end
    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end
    if currentBuyerPed then
        Wait(10000)
        currentBuyerPed = nil
    end
end

local function FailMission(reason)
    if Config.debug then print("DEBUG: FailMission called! Reason: " .. tostring(reason) .. ". Resetting deliveryCount from " .. tostring(deliveryCount) .. " to 0.") end
    exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = reason or Locales.mission_failed })
    CleanUpBuyer()
    TriggerServerEvent('yoda-oxyruns:deleteMissionVehicle')
    TriggerEvent('yoda-oxyruns:endMission')
    missionVehicleNetId = nil
    missionVehiclePlate = nil
    deliveryCount = 0
    exports["orbit-ui"]:Close()
end

local function CreateBuyerNPC()
    if currentBuyerPed then
        return
    end

    local buyerIndex = selectedBuyers[deliveryCount + 1]
    if not buyerIndex then
        repeat
            buyerIndex = math.random(1, 13)
        until buyerIndex ~= 9 and buyerIndex ~= 10
    end

    local buyer = NpcBuyers["npc" .. buyerIndex]
    
    if buyer then
        CleanUpBuyer()

        local npcModels = Config.Models

        local model = npcModels[math.random(1, #npcModels)]
        local modelHash = GetHashKey(model)

        if not lib.requestModel(modelHash) then return end

        currentBuyerPed = CreatePed(1, modelHash, buyer.coords.x, buyer.coords.y, buyer.coords.z, buyer.coords.w, false, true)
        FreezeEntityPosition(currentBuyerPed, true)
        SetEntityInvincible(currentBuyerPed, true)
        SetBlockingOfNonTemporaryEvents(currentBuyerPed, true)

        currentBlip = AddBlipForCoord(buyer.coords.x, buyer.coords.y, buyer.coords.z)
        SetBlipSprite(currentBlip, 1)
        SetBlipDisplay(currentBlip, 4)
        SetBlipScale(currentBlip, 1.0)
        SetBlipColour(currentBlip, 1)
        SetBlipAsShortRange(currentBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Người mua đu đủ sấy")
        EndTextCommandSetBlipName(currentBlip)

        if target == 'ox' then
            currentBuyerZone = exports.ox_target:addBoxZone({
                coords = vec3(buyer.coords.x, buyer.coords.y, buyer.coords.z + 1),
                size = vec3(1.5, 1.5, 1.5),
                rotation = 90,
                debug = drawZones,
                options = {{
                    name = 'yoda-oxyruns:sellToBuyer',
                    icon = 'fa-solid fa-cube',
                    label = 'Giao hàng',
                    onSelect = function()
                        -- Check vehicle proximity
                        if not missionVehicleNetId then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.no_active_mission })
                            return
                        end
                        local vehicle = NetToVeh(missionVehicleNetId)
                        if not DoesEntityExist(vehicle) then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.vehicle_missing })
                            return
                        end
                        local playerPed = PlayerPedId()
                        local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(vehicle))
                        if distance > 30.0 then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.bring_vehicle_close })
                            return
                        end

                        -- Check package in inventory
                        local packageCount = exports.ox_inventory:Search('count', Config.itemhang) or 0
                        if packageCount < 1 then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.no_package })
                            return
                        end

                        local result = lib.callback.await('yoda-oxyruns:sellToBuyer', false)
                        if result.success then
                            TriggerEvent('yoda-oxyruns:sellDrugsAnim', result.sold)
                        else
                            if result.reason == 'inventory_full' then
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.inventory_full })
                            elseif result.reason == 'no_package' then
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.no_package })
                            else
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.mission_failed })
                            end
                        end
                    end
                }}
            })
        else
            local name = 'target_sell'
            local targetId = exports['qb-target']:AddCircleZone(name, vector3(buyer.coords.x, buyer.coords.y, buyer.coords.z + 1), 2.0, {
                name = name, debugPoly = false , useZ = true}, {
                    options = {{label = 'Giao hàng', icon = 'fa-solid fa-cube', 
                    action = function () 
                        -- Check vehicle proximity
                        if not missionVehicleNetId then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.no_active_mission })
                            return
                        end
                        local vehicle = NetToVeh(missionVehicleNetId)
                        if not DoesEntityExist(vehicle) then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.vehicle_missing })
                            return
                        end
                        local playerPed = PlayerPedId()
                        local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(vehicle))
                        if distance > 30.0 then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.bring_vehicle_close })
                            return
                        end

                        -- Check package in inventory
                        local packageCount = exports.ox_inventory:Search('count', Config.itemhang) or 0
                        if packageCount < 1 then
                            exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.no_package })
                            return
                        end

                        local result = lib.callback.await('yoda-oxyruns:sellToBuyer', false)
                        if result.success then
                            TriggerEvent('yoda-oxyruns:sellDrugsAnim', result.sold)
                        else
                            if result.reason == 'inventory_full' then
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.inventory_full })
                            elseif result.reason == 'no_package' then
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.no_package })
                            else
                                exports.ox_lib:notify({ type = 'error', title = 'Giao đu đủ', description = Locales.mission_failed })
                            end
                        end
                    end}},
                    distance = 2.0
            })
        end

        return currentBuyerPed, currentBuyerZone, currentBlip
    end
end

RegisterNetEvent('yoda-oxyruns:initiateDelivery')
AddEventHandler('yoda-oxyruns:initiateDelivery', function(netId, plate)
    if Config.debug then print("DEBUG: initiateDelivery event triggered. Resetting deliveryCount from " .. tostring(deliveryCount) .. " to 0.") end
    CleanUpBuyer()
    missionVehicleNetId = netId
    missionVehiclePlate = plate
    deliveryCount = 0
    exports["orbit-ui"]:Show("Giao du đủ", "đang tìm kiếm khách hàng...")

    -- Pre-generate the 5 random buyer indexes
    selectedBuyers = {}
    local lastIdx = nil
    for i = 1, 5 do
        local buyerIndex
        repeat
            buyerIndex = math.random(1, 13)
        until buyerIndex ~= lastIdx and buyerIndex ~= 9 and buyerIndex ~= 10
        lastIdx = buyerIndex
        selectedBuyers[i] = buyerIndex
    end

    -- Compile list of the 5 pre-selected coordinates and trigger server dispatch
    local buyerCoordsList = {}
    for i = 1, 5 do
        local buyerIndex = selectedBuyers[i]
        local buyer = NpcBuyers["npc" .. buyerIndex]
        if buyer then
            buyerCoordsList[#buyerCoordsList+1] = { x = buyer.coords.x, y = buyer.coords.y, z = buyer.coords.z }
        end
    end
    TriggerServerEvent('yoda-oxyruns:server:policeDispatch', buyerCoordsList)

    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        local buyerPed, buyerZone, blip = CreateBuyerNPC()
        if buyerPed and buyerZone then
            exports.ox_lib:notify(Config.Notify.buyerLocation)
            exports["orbit-ui"]:Show("Giao du đủ", "đang giao đu đủ " .. (deliveryCount + 1) .. "/5 đơn")
        end
    end)
end)

RegisterNetEvent('yoda-oxyruns:sellDrugsAnim')
AddEventHandler('yoda-oxyruns:sellDrugsAnim', function(success)
    -- Increment deliveryCount immediately so notifications display the correct count
    deliveryCount = deliveryCount + 1

    -- Notify player and add loot option immediately if scammed
    if success then
        if deliveryCount < 5 then
            exports.ox_lib:notify({ type = 'info', title = 'Giao đu đủ', description = string.format(Locales.delivery_success, deliveryCount) })
        end
    else
        exports.ox_lib:notify(Config.Notify.dealFailed)

        local scammedPed = currentBuyerPed
        local targetOption = {
            {
                name = 'yoda-oxyruns:retrievePackage',
                icon = 'fa-solid fa-hand-holding-hand',
                label = 'Lấy lại tiền',
                canInteract = function(entity, distance, data)
                    return IsEntityDead(entity) or IsPedDeadOrDying(entity, 1) or IsPedFatallyInjured(entity)
                end,
                action = function(entity)
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                        
                        local checkLoot = exports.ox_lib:progressBar({
                            duration = 5000,
                            label = 'Đang lấy lại tiền...',
                            useActiveKey = false,
                            disable = {
                                move = true,
                                car = true,
                                combat = true,
                            },
                        })
                        
                        ClearPedTasks(playerPed)
                        
                        if checkLoot then
                            TriggerServerEvent('yoda-oxyruns:retrievePackage')
                            if target == 'ox' then
                                exports.ox_target:removeLocalEntity(scammedPed, 'yoda-oxyruns:retrievePackage')
                            else
                                exports['qb-target']:RemoveTargetEntity(scammedPed, 'Lấy lại tiền')
                            end
                        end
                    end)
                end
            }
        }

        if target == 'ox' then
            exports.ox_target:addLocalEntity(scammedPed, targetOption)
        else
            exports['qb-target']:AddTargetEntity(scammedPed, {
                options = targetOption,
                distance = 2.0
            })
        end
    end

    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local ped = currentBuyerPed
        local animDict = 'mp_common'
        local animName = 'givetake1_a'
        
        ClearPedTasks(playerPed)
        
        if not lib.requestAnimDict(animDict) then return end
        
        local cocaineBagped = CreateObject(GetHashKey("xm3_prop_xm3_bag_coke_01a"), 0, 0, 0, true, true, true)
        local cocaineBagplayerPed = CreateObject(GetHashKey("xm3_prop_xm3_bag_coke_01a"), 0, 0, 0, true, true, true)
        AttachEntityToEntity(cocaineBagplayerPed, playerPed, GetPedBoneIndex(playerPed, 0x188E), 0.08, -0.06, -0.01, 96.0, 20.0, 180.0, true, true, false, true, 1, true)
        
        TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, 1000, 49, 0, false, false, false)
        TaskPlayAnim(playerPed, animDict, animName, 1.0, -1.0, 1000, 49, 0, false, false, false)
        Citizen.Wait(1000)
        DeleteObject(cocaineBagplayerPed)
        
        AttachEntityToEntity(cocaineBagped, ped, GetPedBoneIndex(ped, 0x188E), 0.08, -0.06, -0.01, 96.0, 20.0, 180.0, true, true, false, true, 1, true)
        Citizen.Wait(900)
        ClearPedTasks(ped)
        DeleteObject(cocaineBagped)
        FreezeEntityPosition(ped, false)

        TaskWanderStandard(ped)

        CleanUpBuyer()

        if deliveryCount >= 5 then
            exports.ox_lib:notify({ type = 'success', title = 'Giao đu đủ', description = Locales.mission_complete })
            TriggerServerEvent('yoda-oxyruns:deleteMissionVehicle')
            TriggerEvent('yoda-oxyruns:endMission')
            missionVehicleNetId = nil
            missionVehiclePlate = nil
            deliveryCount = 0
            exports["orbit-ui"]:Close()
        else
            CreateBuyerWithDelay()
        end
    end)
end)

function CreateBuyerWithDelay()
    local delay = math.random(cooldown.npc.min, cooldown.npc.max) * 60000
    exports["orbit-ui"]:Show("Giao du đủ", "đang tìm kiếm khách hàng...")
    Citizen.CreateThread(function()
        Citizen.Wait(delay)
        
        -- Check if mission is still active
        if not missionVehiclePlate then return end
        
        -- Check if player is inside the designated vehicle
        if not IsPlayerInMissionVehicle() then
            FailMission(Locales.no_vehicle_for_next)
            return
        end
        
        local buyerPed, buyerZone, blip = CreateBuyerNPC()
        if buyerPed and buyerZone then
            exports.ox_lib:notify(Config.Notify.buyerLocation)
            exports["orbit-ui"]:Show("Giao du đủ", "đang giao đu đủ " .. (deliveryCount + 1) .. "/5 đơn")
        end
    end)
end

