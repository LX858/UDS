local QBCore = exports["qb-core"]:GetCoreObject()
local WeedPlants = {}
local ActivePlants = {}

local inZone = 0
local Stations = {}
local inLayNuocStation = false

-- Biến lưu trữ zone ID hiện tại (từ PolyZone)
local currentZoneId = nil
local insideFarmZones = {}
local snapshotSerial = 0
local pendingSnapshot = nil
local applyPlantEvent
local plantMenuRequestId = 0

local function switchPlantZone(zoneId)
    if currentZoneId == zoneId then return end
    plantMenuRequestId = plantMenuRequestId + 1
    local previousZone = currentZoneId
    if previousZone then TriggerServerEvent('xx_farming:leaveZone', previousZone) end
    snapshotSerial = snapshotSerial + 1
    currentZoneId = zoneId
    inZone = zoneId and 1 or 0
    pendingSnapshot = nil
    for _, plant in ipairs(WeedPlants) do removeWeed(plant.id) end
    WeedPlants = {}
    if not zoneId then return end

    local requestId = snapshotSerial
    pendingSnapshot = { zoneId = zoneId, events = {} }
    lib.callback('xx_farming:getPlants', false, function(snapshot)
        if currentZoneId ~= zoneId or snapshotSerial ~= requestId then return end
        local buffered = pendingSnapshot.events
        pendingSnapshot = nil
        WeedPlants = snapshot or {}
        for _, event in ipairs(buffered) do
            applyPlantEvent(event[1], event[2])
        end
    end, zoneId)
end

-- Helper lấy cấu hình loại cây
local function GetCropConfig(cropType)
    return (CropTypes and cropType and CropTypes[cropType]) or Melons
end

local function GetPlantCropType(plant)
    if plant and plant.crop_type and CropTypes and CropTypes[plant.crop_type] then
        return plant.crop_type
    end
    if plant and plant.zone_id and FarmRental and FarmRental.FarmZones then
        local zone = FarmRental.FarmZones[plant.zone_id]
        if zone and zone.cropTypes and zone.cropTypes[1] then
            return zone.cropTypes[1]
        end
    end
    return 'rice'
end

-- Lấy tất cả GrowthObjects từ tất cả loại cây (dùng để kiểm tra/target)
local function GetAllGrowthObjects()
    local objects = {}
    if CropTypes then
        for _, cropConf in pairs(CropTypes) do
            for _, obj in ipairs(cropConf.GrowthObjects) do
                table.insert(objects, obj)
            end
        end
    else
        for _, obj in ipairs(Melons.GrowthObjects) do
            table.insert(objects, obj)
        end
    end
    return objects
end

-- Plantas
RegisterNetEvent('QBCore:playerLogout', function()
    inLayNuocStation = false
    Stations = {}
end)

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

function ResetAnimSet()
    ResetPedMovementClipset(PlayerPedId())
    ResetPedWeaponMovementClipset(PlayerPedId())
    ResetPedStrafeClipset(PlayerPedId())
end

CreateThread(function()
    -- Create blips for all farm zones from config
    for _, zone in pairs(FarmRental.FarmZones) do
        if zone.blip == false then goto continue end
        local c = zone.center
        local Blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(Blip, 253)
        SetBlipDisplay(Blip, 4)
        SetBlipScale(Blip, 0.7)
        SetBlipAsShortRange(Blip, true)
        SetBlipColour(Blip, 5)
        SetBlipAlpha(Blip, 0.7)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(zone.name)
        EndTextCommandSetBlipName(Blip)

        if zone.blipRadius and zone.blipRadius > 0 then
            local radiusBlip = AddBlipForRadius(c.x, c.y, c.z, zone.blipRadius)
            SetBlipColour(radiusBlip, 5)
            SetBlipAlpha(radiusBlip, 80)
            SetBlipAsShortRange(radiusBlip, true)
        end

        ::continue::
    end
end)

Citizen.CreateThread(function()
    local allModels = {}
    local seenModels = {}

    local function addModelHash(hash)
        if hash and not seenModels[hash] then
            seenModels[hash] = true
            table.insert(allModels, hash)
        end
    end

    if CropTypes then
        for _, cropConf in pairs(CropTypes) do
            if cropConf.GrowthObjects then
                for _, obj in ipairs(cropConf.GrowthObjects) do
                    addModelHash(obj.hash)
                end
            end
        end
    end

    if Melons and Melons.GrowthObjects then
        for _, v in ipairs(Melons.GrowthObjects) do
            addModelHash(v.hash)
        end
    end

    TargetPlantModels = allModels

    exports.ox_target:addModel(allModels, {
        {
            name = 'farm_check_plant',
            icon = 'fas fa-cannabis',
            label = 'Kiểm tra',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name, bone)
                return not IsPedInAnyVehicle(PlayerPedId(), false)
            end,
            onSelect = function(data)
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    QBCore.Functions.Notify("Không thể kiểm tra cây khi đang ngồi trên xe!", "error")
                    return
                end
                TriggerEvent('xx_farming:checkPlant', data.entity)
            end
        }
    })
end)

Citizen.CreateThread(function()
    while true do
        local plyCoords = GetEntityCoords(PlayerPedId())
        if WeedPlants == nil then WeedPlants = {} end
        for idx, plant in ipairs(WeedPlants) do
            if idx % 100 == 0 then
                Wait(0) -- Yield frame to prevent freeze
            end
            
            local plantCoords = json.decode(plant.coords)
            local distance = #(plyCoords - vector3(plantCoords.x, plantCoords.y, plantCoords.z))
            
            if distance <= 100.0 then
                local plantGrowth = getPlantGrowthPercent(plant)
                local cropType = GetPlantCropType(plant)
                local cropConfig = GetCropConfig(cropType)
                local curStage = getStageFromPercent(plantGrowth, cropConfig)
                local isChanged = (ActivePlants[plant.id] and ActivePlants[plant.id].stage ~= curStage)

                if isChanged then
                    removeWeed(plant.id)
                end

                if not ActivePlants[plant.id] or isChanged then
                    local weedPlant = createWeedStageAtCoords(curStage, plant.coords, cropType)
                    ActivePlants[plant.id] = {
                        object = weedPlant,
                        stage = curStage
                    }
                end
            else
                if ActivePlants[plant.id] then
                    removeWeed(plant.id)
                end
            end
        end
        Wait(inZone > 0 and 500 or 1000)
    end
end)

Citizen.CreateThread(function()
    -- Marker hiển thị theo bán kính radius của FarmZones
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())

        if FarmRental and FarmRental.FarmZones then
            for zoneId, zoneConfig in pairs(FarmRental.FarmZones) do
                local markerConfig = zoneConfig.marker
                if markerConfig and markerConfig.enabled and zoneConfig.center then
                    local radius = zoneConfig.radius or 50.0
                    local drawDist = markerConfig.drawDistance or (radius + 100.0)
                    local distance = #(playerCoords - zoneConfig.center)

                    if distance <= drawDist then
                        sleep = 0
                        local diameter = radius * 2.0
                        local color = markerConfig.color or {}
                        local scale = markerConfig.scale or {}
                        local scaleX = (type(scale) == 'table' and scale.x) or diameter
                        local scaleY = (type(scale) == 'table' and scale.y) or diameter
                        local scaleZ = (type(scale) == 'table' and scale.z) or 50.0
                        local zOffset = markerConfig.zOffset or 5.0

                        DrawMarker(
                            markerConfig.type or 1,
                            zoneConfig.center.x, zoneConfig.center.y, zoneConfig.center.z - zOffset,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            scaleX, scaleY, scaleZ,
                            color.r or 255, color.g or 0, color.b or 0, color.a or 120,
                            false, true, 2, false, nil, nil, false
                        )
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    -- Farm zone 1
    local farmZone1 = PolyZone:Create({
        vector2(2530.2866210938, 4852.3120117188),
        vector2(2496.97265625, 4817.3002929688),
        vector2(2544.3405761719, 4773.7827148438),
        vector2(2588.0646972656, 4799.7587890625)
    }, {
        name = "farm",
    })
    
    -- Farm zone 2
    local farmZone2 = PolyZone:Create({
        vector2(2523.6101074219, 4859.1748046875),
        vector2(2495.7443847656, 4885.0190429688),
        vector2(2455.5815429688, 4843.5932617188),
        vector2(2474.5715332031, 4827.7661132812),
        vector2(2491.9125976562, 4827.7573242188)
    }, {
        name = "farm2",
    })
    
    -- Farm zone 3
    local farmZone3 = PolyZone:Create({
        vector2(1906.7355957031, 4735.859375),
        vector2(1948.0660400391, 4765.8115234375),
        vector2(1924.1115722656, 4791.95703125),
        vector2(1879.1953125, 4761.6669921875)
    }, {
        name = "farm3",
    })
    
    -- Farm zone 4
    local farmZone4 = PolyZone:Create({
        vector2(1875.4427490234, 4767.5493164062),
        vector2(1858.0063476562, 4784.7407226562),
        vector2(1894.7689208984, 4821.3427734375),
        vector2(1918.1320800781, 4797.9370117188)
    }, {
        name = "farm4",
    })
    
    -- Farm zone 5
    local farmZone5 = PolyZone:Create({
        vector2(1890.7977294922, 4824.8344726562),
        vector2(1852.6872558594, 4786.4838867188),
        vector2(1831.4832763672, 4809.8901367188),
        vector2(1869.2967529297, 4847.5083007812)
    }, {
        name = "farm5",
    })
    
    -- Farm zone 6
    local farmZone6 = PolyZone:Create({
        vector2(1928.0131835938, 4794.0595703125),
        vector2(1959.9876708984, 4824.9301757812),
        vector2(1985.0701904297, 4798.9907226562),
        vector2(1953.1300048828, 4765.9028320312)
    }, {
        name = "fram6",
    })
    
    -- Farm zone 7
    local farmZone7 = PolyZone:Create({
        vector2(2032.2202148438, 4851.2724609375),
        vector2(2059.755859375, 4879.591796875),
        vector2(2033.8421630859, 4903.5444335938),
        vector2(2006.8988037109, 4875.0888671875)
    }, {
        name = "fram7",
    })
    
    -- Farm zone 8
    local farmZone8 = PolyZone:Create({
        vector2(2004.3663330078, 4878.1030273438),
        vector2(2031.7095947266, 4905.9038085938),
        vector2(2006.2177734375, 4929.8217773438),
        vector2(1978.7487792969, 4902.869140625)
    }, {
        name = "fram8",
    })
    
    -- Farm zone 9
    local farmZone9 = PolyZone:Create({
        vector2(2016.1180419922, 4939.7143554688),
        vector2(2045.7532958984, 4968.0234375),
        vector2(2071.3959960938, 4942.6313476562),
        vector2(2041.9237060547, 4914.0190429688)
    }, {
        name = "fram 9",
    })
    
    -- Farm zone 10
    local farmZone10 = PolyZone:Create({
        vector2(2043.521484375, 4912.9375),
        vector2(2072.9018554688, 4942.7524414062),
        vector2(2097.1125488281, 4917.7719726562),
        vector2(2067.3295898438, 4887.4243164062)
    }, {
        name = "farm 10",
    })
    
    -- Farm zone 11
    local z11 = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[11]
    local farmZone11 = CircleZone:Create(z11 and z11.center or vector3(1231.5006, -86.8380, 59.6442), (z11 and z11.radius) or 100.0, {
        name = "farm 11",
        useZ = false
    })
    
    -- Farm zone 12
    local z12 = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[12]
    local farmZone12 = CircleZone:Create(z12 and z12.center or vector3(1481.9066, -2354.6516, 71.9142), (z12 and z12.radius) or 100.0, {
        name = "farm 12",
        useZ = false
    })
    
    -- -- Farm zone 13 (Tự động cập nhật theo radius trong config.lua)
    -- local z13 = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[13]
    -- local farmZone13 = CircleZone:Create(z13 and z13.center or vector3(4859.8813, -4582.9717, 18.0563), (z13 and z13.radius) or 100.0, {
    --     name = "farm 13",
    --     useZ = false
    -- })
    
    -- Set up the onPlayerInOut for all zones with zone ID tracking
    local zones = {
        {zone = farmZone1, id = 1},
        {zone = farmZone2, id = 2},
        {zone = farmZone3, id = 3},
        {zone = farmZone4, id = 4},
        {zone = farmZone5, id = 5},
        {zone = farmZone6, id = 6},
        {zone = farmZone7, id = 7},
        {zone = farmZone8, id = 8},
        {zone = farmZone9, id = 9},
        {zone = farmZone10, id = 10},
        {zone = farmZone11, id = 11}
        -- {zone = farmZone12, id = 12},
        -- {zone = farmZone13, id = 13}
    }
    
    for _, zoneData in ipairs(zones) do
        zoneData.zone:onPlayerInOut(function(isPointInside)
            if isPointInside then
                insideFarmZones[zoneData.id] = true
                switchPlantZone(zoneData.id)
            else
                insideFarmZones[zoneData.id] = nil
                if currentZoneId == zoneData.id then
                    local nextZone = next(insideFarmZones)
                    switchPlantZone(nextZone)
                end
            end
        end)
    end
end)

RegisterNetEvent('xx_farming:client:useitem')
AddEventHandler('xx_farming:client:useitem', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể trồng cây khi đang ngồi trên xe!", "error")
        return
    end

    local x1, y1, z1 = table.unpack(GetEntityCoords(playerPed))
    local nearPlant = false
    for k, v in ipairs(GetAllGrowthObjects()) do
        local closestObject = GetClosestObjectOfType(x1, y1, z1, 1.5, v.hash, false, false, false)
        if closestObject ~= nil and closestObject ~= 0 then
            nearPlant = true
            break
        end
    end
    if not nearPlant then
        if inZone > 0 and currentZoneId then
            -- Kiểm tra ngay hạt giống có phù hợp zone này không (trước khi làm bất cứ thứ gì)
            local _zoneConf = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[currentZoneId]
            local _allowedCropTypes = (_zoneConf and _zoneConf.cropTypes) or {'rice'}
            local _hasMatchingSeed = false
            for _, _ct in ipairs(_allowedCropTypes) do
                local _cropConf = CropTypes and CropTypes[_ct]
                if _cropConf then
                    if (exports.ox_inventory:Search('count', _cropConf.FemaleSeedItem) or 0) > 0 then
                        _hasMatchingSeed = true
                        break
                    end
                end
            end
            if not _hasMatchingSeed then
                local _names = {}
                for _, _ct in ipairs(_allowedCropTypes) do
                    local _cropConf = CropTypes and CropTypes[_ct]
                    if _cropConf then table.insert(_names, (_cropConf.name or _ct)) end
                end
                QBCore.Functions.Notify("Ruộng này chỉ trồng: " .. table.concat(_names, ", ") .. ". Bạn không có hạt giống phù hợp!", "error")
                return
            end
            -- Check if player has permission to plant in this zone BEFORE starting progress bar
            lib.callback('xx_farming:checkPlantingPermissionByZone', false, function(result)
                if not result.canPlant then
                    QBCore.Functions.Notify(result.message or "Bạn cần thuê ruộng này hoặc được chia sẻ quyền trước khi trồng cây!", "error")
                    return
                end
                
                -- Permission granted, proceed with planting
                if lib.progressBar({
                    duration = 5000,
                    label = 'Đang trồng',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                    },
                    anim = {
                        scenario = 'WORLD_HUMAN_GARDENER_PLANT'
                    }
                }) then
                    -- Kiểm tra loại cây được phép trồng trong zone này
                    local zoneConf = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[currentZoneId]
                    local allowedCropTypes = (zoneConf and zoneConf.cropTypes) or {'rice'}
                    -- Tìm hạt giống phù hợp trong túi đồ
                    local selectedCropType = nil
                    for _, ct in ipairs(allowedCropTypes) do
                        local cropConf = CropTypes and CropTypes[ct]
                        if cropConf then
                            local seedCount = exports.ox_inventory:Search('count', cropConf.FemaleSeedItem)
                            if seedCount > 0 then
                                selectedCropType = ct
                                break
                            end
                        end
                    end
                    if selectedCropType then
                        local offsetCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0, 0.8, 0)
                        local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(offsetCoords.x, offsetCoords.y, offsetCoords.z, offsetCoords.x, offsetCoords.y, offsetCoords.z - 2, 1, 0, 4)
                        local retval, hit, endCoords, _, materialHash, _ = GetShapeTestResultIncludingMaterial(rayHandle)
                        TriggerServerEvent("xx_farming:plantSeed", endCoords, currentZoneId, selectedCropType)
                    else
                        local seedNames = {}
                        for _, ct in ipairs(allowedCropTypes) do
                            local cropConf = CropTypes and CropTypes[ct]
                            if cropConf then table.insert(seedNames, cropConf.name or ct) end
                        end
                        QBCore.Functions.Notify("Ruộng này trồng: " .. table.concat(seedNames, ", ") .. ". Bạn không có hạt giống phù hợp!", "error")
                    end  
                end
            end, currentZoneId)
        else
            QBCore.Functions.Notify("Bạn nên tìm một khu vực tốt hơn để trồng cây này !!!", "error")
        end
    else
        QBCore.Functions.Notify("Trồng quá gần với những cây khác", "error")
    end
end)

function CanPlantSeedHere(pos)
    local canPlant = true
    for i = 1, #Melons.GrowthObjects do
        if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Melons.GrowthObjects[i].x, Melons.GrowthObjects[i].y, Melons.GrowthObjects[i].z, true) < 1.3 then
            canPlant = false
        end
    end
    return canPlant
end

RegisterNetEvent('xx_farming:trigger_zone')
applyPlantEvent = function(type, pData)
    --print("trigger_zone called with type:", type, "data:", json.encode(pData))
    
    if type == 1 then
        for _, plant in ipairs(WeedPlants) do
            local keep = false
            for _, newPlant in ipairs(pData) do
                if plant.id == newPlant.id then
                    keep = true
                    break
                end
            end

            if not keep then
                removeWeed(plant.id)
            end
        end
        WeedPlants = pData
    end
    if type == 2 then
        --print("Adding new plant:", pData.id)
        if currentZoneId and pData.zone_id == currentZoneId then
            for _, plant in ipairs(WeedPlants) do
                if plant.id == pData.id then return end
            end
            WeedPlants[#WeedPlants + 1] = pData
        end
    end
    if type == 3 then
        --print("Updating plant:", pData.id)
        for idx, plant in ipairs(WeedPlants) do
            if plant.id == pData.id then
                for k, v in pairs(pData) do
                    plant[k] = v
                end
                break
            end
        end
    end
    if type == 4 then
        --print("Removing plant:", pData)
        for idx, plant in ipairs(WeedPlants) do
            if plant.id == pData then
                --print("Found plant to remove at index:", idx)
                table.remove(WeedPlants, idx)
                removeWeed(plant.id)
                break
            end
        end
    end
end

AddEventHandler('xx_farming:trigger_zone', function(eventType, pData)
    if not currentZoneId then return end
    if pendingSnapshot then
        local events = pendingSnapshot.events
        events[#events + 1] = { eventType, pData }
        return
    end
    applyPlantEvent(eventType, pData)
end)

RegisterNetEvent('xx_farming:plantBatch', function(zoneId, changes)
    if tonumber(zoneId) ~= currentZoneId then return end
    for _, delta in ipairs(changes or {}) do
        if pendingSnapshot then
            local events = pendingSnapshot.events
            events[#events + 1] = { 3, delta }
        else
            applyPlantEvent(3, delta)
        end
    end
end)

AddEventHandler("xx_farming:checkPlant", function(entity)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể kiểm tra cây khi đang ngồi trên xe!", "error")
        return
    end
    -- ox_target already identified the selected object; looking around the player's
    -- feet misses large plants that can be targeted from more than one metre away.
    local plantId = entity and getPlantId(entity)
    if not plantId or not getPlantById(plantId) then
        QBCore.Functions.Notify('Không tìm thấy cây này, vui lòng thử lại.', 'error')
        return
    end
    showPlantMenu(plantId)
end)

AddEventHandler('xx_farming:addWater', function(data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể tưới nước khi đang ngồi trên xe!", "error")
        return
    end
    local countwater = exports.ox_inventory:Search('count', Melons.WaterItem)
    if countwater > 0 then
        if lib.progressBar({
            duration = 2000,
            label = 'Đang tưới cây',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire', flag = 1 },
            prop = { model = 'prop_wateringcan', bone = 28422, pos = vec3(0.4, 0.125, -0.05), rot = vec3(90.0, 180.0, 0.0) }
        }) then
            lib.callback('xx_farming:addWater', false, function(success, newWater)
                if not success then
                    QBCore.Functions.Notify("Tưới nước thất bại !!!", "error")
                else
                    QBCore.Functions.Notify("Tưới nước thành công !!!", "success")
                    if newWater then
                        for _, p in pairs(WeedPlants) do
                            if p.id == data then
                                p.water = newWater
                                break
                            end
                        end
                    end
                    Wait(200)
                    showPlantMenu(data)
                end
            end, data)
        end
    else
        QBCore.Functions.Notify("Thiếu can nước bạn ơi !!!", "error")
    end
end)

AddEventHandler('xx_farming:addFertilizer', function(data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể bón phân khi đang ngồi trên xe!", "error")
        return
    end
    local countfertilizer = exports.ox_inventory:Search('count', Melons.FertilizerItem)
    if countfertilizer > 0 then
        if lib.progressBar({
            duration = 2000,
            label = 'Đang bón phân',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire', flag = 1 },
            prop = { model = 'prop_feed_sack_01', bone = 28422, pos = vec3(0.3239, -0.0328, 0.1253), rot = vec3(49.4678, -18.1732, -79.2577) }
        }) then
            lib.callback('xx_farming:addFertilizer', false, function(success, newFertilizer)
                if not success then
                    QBCore.Functions.Notify("Không thể bón phân !!!", "error")
                else
                    QBCore.Functions.Notify("Bón phân thành công !!!", "success")
                    if newFertilizer then
                        for _, p in pairs(WeedPlants) do
                            if p.id == data.plantId then
                                p.fertilizer = newFertilizer
                                break
                            end
                        end
                    end
                    Wait(200)
                    showPlantMenu(data.plantId)
                end
            end, data.plantId, data.type)
        end
    else
        QBCore.Functions.Notify("Thiếu phân bón bạn ơi !!!", "error")
    end
end)

AddEventHandler('xx_farming:addbugs', function(data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể thả sâu khi đang ngồi trên xe!", "error")
        return
    end
    local cropConf = GetCropConfig(data.cropType or 'rice')
    local bugsItem = cropConf.bugs
    local countBugs = exports.ox_inventory:Search('count', bugsItem)
    if countBugs <= 0 then
        QBCore.Functions.Notify('Để thả sâu bạn cần có vật phẩm: ' .. bugsItem, 'error')
        return
    end

    if lib.progressBar({
        duration = 4000,
        label = 'Đang thả sâu bệnh vào cây...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true },
        anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire', flag = 1 },
        prop = { model = 'p_cs_sack_01_s', bone = 28422, pos = vec3(0.32, -0.03, 0.13), rot = vec3(49.0, -18.0, -79.0) }
    }) then
        lib.callback('xx_farming:addbugs', false, function(success)
            if success then
                QBCore.Functions.Notify('Đã thả sâu vào cây!', 'success')
            else
                QBCore.Functions.Notify('Không thể thả sâu lúc này!', 'error')
            end
        end, data.plantId, data.cropType)
    end
end)

AddEventHandler('xx_farming:applyPesticide', function(data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể phun thuốc khi đang ngồi trên xe!", "error")
        return
    end
    local pesticideType = data.pesticideType
    local treatConf = BugTreatment and BugTreatment[pesticideType]
    if not treatConf then return end

    local count = exports.ox_inventory:Search('count', pesticideType)
    if count <= 0 then
        QBCore.Functions.Notify('Bạn không có ' .. treatConf.label .. '!', 'error')
        return
    end

    if lib.progressBar({
        duration = 3000,
        label = 'Đang phun ' .. treatConf.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true },
        anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire', flag = 1 },
        prop = { model = 'prop_spray_can', bone = 28422, pos = vec3(0.15, -0.02, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    }) then
        lib.callback('xx_farming:applyPesticide', false, function(success, newHealth)
            if not success then
                QBCore.Functions.Notify('Không thể sử dụng thuốc lúc này!', 'error')
            else
                -- Cập nhật health cục bộ trong WeedPlants (không dùng trigger_zone để tránh ghi đè water/fertilizer)
                if newHealth then
                    for _, p in pairs(WeedPlants) do
                        if p.id == data.plantId then
                            p.health = newHealth
                            break
                        end
                    end
                end
                showPlantMenu(data.plantId)
            end
        end, data.plantId, pesticideType)
    end
end)

AddEventHandler('xx_farming:addFertilizerk', function (data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể bón phân khi đang ngồi trên xe!", "error")
        return
    end
    local counttrusau = exports.ox_inventory:Search('count', Melons.thuoctrusau)
    if counttrusau > 0 then
        if lib.progressBar({
            duration = 2000,
            label = 'Đang bón phân',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire', flag = 1 },
            prop = { model = 'prop_feed_sack_01', bone = 28422, pos = vec3(0.3239, -0.0328, 0.1253), rot = vec3(49.4678, -18.1732, -79.2577) }
        }) then
            lib.callback('xx_farming:addFertilizerk', false, function(success, resultData)
                if not success then
                    QBCore.Functions.Notify("Không thể trừ sâu lúc này !!!", "error")
                else
                    if resultData then
                        for _, p in pairs(WeedPlants) do
                            if p.id == data.plantId then
                                if resultData.water then p.water = resultData.water end
                                if resultData.fertilizer then p.fertilizer = resultData.fertilizer end
                                break
                            end
                        end
                    end
                    Wait(200)
                    showPlantMenu(data.plantId)
                end
            end, data.plantId, data.type)
        end
    else
        QBCore.Functions.Notify("Thiếu thuốc trừ sâu bạn ơi !!!", "error")
    end
end)

AddEventHandler('xx_farming:addMaleSeed', function(data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể thực hiện khi đang ngồi trên xe!", "error")
        return
    end
    if lib.progressBar({
        duration = 10000,
        label = 'Đang trồng',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
        anim = {
            scenario = 'WORLD_HUMAN_GARDENER_PLANT'
        }
    }) then
        ClearPedTasks(PlayerPedId())
        lib.callback('xx_farming:addMaleSeed', false, function(success)
            if not success then
                QBCore.Functions.Notify("Không thể thêm hạt giống đực !!!", "error")
            else
                for _, p in pairs(WeedPlants) do
                    if p.id == data then
                        p.plantgender = 1
                        break
                    end
                end
                Wait(200)
                showPlantMenu(data)
            end
        end, data)
    end
end)

AddEventHandler('xx_farming:removePlant', function(data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể phá cây khi đang ngồi trên xe!", "error")
        return
    end
    if lib.progressBar({
        duration = 10000,
        label = 'Đang phá hủy',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
        anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' },
    }) then
        local getFertilizer = getPlantGrowthPercent(getPlantById(data)) > 20.0
        lib.callback('xx_farming:removePlant', false, function(success) 
            if not success then
            else
                removeWeed(data)
            end
        end, data)
    end
end)

AddEventHandler("xx_farming:pickPlant", function(plantId)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể thu hoạch khi đang ngồi trên xe!", "error")
        return
    end
    plantId = tonumber(plantId)
    local plant = getPlantById(plantId)
    if not plant or not ActivePlants[plantId] then
        QBCore.Functions.Notify('Cây này không còn ở gần bạn, vui lòng kiểm tra lại.', 'error')
        return
    end
    local plantCoords = json.decode(plant.coords)
    if #(GetEntityCoords(playerPed) - vector3(plantCoords.x, plantCoords.y, plantCoords.z)) > 5.0 then
        QBCore.Functions.Notify('Bạn cần đến gần cây để thu hoạch.', 'error')
        return
    end
    local pickCropConfig = GetCropConfig(GetPlantCropType(plant))
    local growth = getPlantGrowthPercent(plant)
    if growth < pickCropConfig.HarvestPercent then
        QBCore.Functions.Notify("Cây này chưa sẵn sàng để thu hoạch !!!", "error")
        return
    end
    if lib.progressBar({
        duration = 5000,
        label = 'Đang thu hoạch',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
        anim = {
            scenario = 'WORLD_HUMAN_GARDENER_PLANT'
        }
    }) then
        --print("Starting harvest for plant ID:", plantId)
        lib.callback('xx_farming:harvestPlant', false, function(success)
            --print("Harvest callback received. Success:", success)
            if success then
                -- Thu hoạch thành công, không cần làm gì thêm vì server sẽ trigger update
                --print("Harvest successful")
                QBCore.Functions.Notify("Thu hoạch thành công!", "success")

                -- Tăng stress khi thu hoạch cây đu đủ (dudu) hoặc poppy
                local cropType = GetPlantCropType(plant)
                if cropType == 'dudu' or cropType == 'poppy' then
                    TriggerServerEvent('xx_farming:addDuduHarvestStress')
                end
            else
                --print("Harvest failed")
                QBCore.Functions.Notify("Thu hoạch thất bại!", "error")
            end
        end, plantId)
    else
        --print("Progress bar cancelled or failed")
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for idx, plant in pairs(ActivePlants) do
        DeleteObject(plant.object)
    end
    if TargetPlantModels then
        exports.ox_target:removeModel(TargetPlantModels, 'farm_check_plant')
    end
end)

function createWeedStageAtCoords(pStage, pCoords, cropType)
    local cropConfig = GetCropConfig(cropType)
    local model = cropConfig.GrowthObjects[pStage].hash
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    coords = json.decode(pCoords)
    local plantObject = CreateObject(model, coords.x, coords.y, coords.z + cropConfig.GrowthObjects[pStage].zOffset, 0, 0, 0)
    FreezeEntityPosition(plantObject, true)
    SetEntityHeading(plantObject, math.random(0, 360) + 0.0)
    return plantObject
end

function removeWeed(pPlantId)
    --print("removeWeed called for plant ID:", pPlantId)
    if ActivePlants[pPlantId] then
        --print("Found active plant object, deleting it")
        DeleteObject(ActivePlants[pPlantId].object)
        ActivePlants[pPlantId] = nil
        --print("Plant object deleted successfully")
    else
        --print("No active plant found for ID:", pPlantId)
    end
end

function getStageFromPercent(pPercent, cropConfig)
    cropConfig = cropConfig or Melons
    local growthObjects = #cropConfig.GrowthObjects - 1
    local percentPerStage = 100 / growthObjects
    return math.floor((pPercent / percentPerStage) + 1.5)
end

function getPlantGrowthPercent(pPlant)
    local cropConfig = GetCropConfig(GetPlantCropType(pPlant))
    local timeDiff = (GetCloudTimeAsInt() - pPlant.timestamp) / 60
    local genderFactor = (pPlant.plantgender == 1 and cropConfig.MaleFactor or 1)
    local fertilizerFactor = pPlant.fertilizer >= 50 and cropConfig.FertilizerFactor or 1.0
    local growthFactors = (cropConfig.GrowthTime * genderFactor * fertilizerFactor)
    local growth = math.min((timeDiff / growthFactors) * 100, 100.0)
    return growth
end

function getPlantId(pEntity)
    for plantId, plant in pairs(ActivePlants) do
        if plant.object == pEntity then
            return plantId
        end
    end
end

function getPlantById(pPlantId)
    for _, plant in pairs(WeedPlants) do
        if plant.id == pPlantId then
            return plant
        end
    end
end

function playPourAnimation()
    RequestAnimDict("weapon@w_sp_jerrycan")
    while (not HasAnimDictLoaded("weapon@w_sp_jerrycan")) do
        Wait(0)
    end
    TaskPlayAnim(PlayerPedId(), "weapon@w_sp_jerrycan", "fire", 2.0, -8, -1, 49, 0, 0, 0, 0)
end

function showPlantMenu(pPlantId)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể kiểm tra cây khi đang ngồi trên xe!", "error")
        return
    end
    local plant = getPlantById(pPlantId)
    if not plant then
        QBCore.Functions.Notify('Cây này không còn tồn tại.', 'error')
        return
    end
    plantMenuRequestId = plantMenuRequestId + 1
    local requestId = plantMenuRequestId
    local requestZoneId = currentZoneId
    local growth = getPlantGrowthPercent(plant)
    local water = math.min(plant.water, 100)
    local fertilizer = math.min(plant.fertilizer, 100)
    local health = math.min(math.max(plant.health or 100, 0), 100)

    local options = {}

    -- Kiểm tra quyền trên ruộng thông qua server
    local playerData = QBCore.Functions.GetPlayerData()
    local plantCoords = json.decode(plant.coords)
    
    -- Gọi server để kiểm tra quyền ruộng với tọa độ cây
    lib.callback('xx_farming:checkPlantPermissionByCoords', false, function(result)
        if requestId ~= plantMenuRequestId or requestZoneId ~= currentZoneId or not getPlantById(pPlantId) then return end
        if not result then
            QBCore.Functions.Notify('Không thể kiểm tra quyền tương tác với cây, vui lòng thử lại.', 'error')
            return
        end
        local canInteract = result.canInteract
        local canSteal = result.canSteal
        
        if canInteract then
            -- Menu cho người có quyền (chủ ruộng hoặc được chia sẻ / công an tại ruộng công cộng)
            if growth < 80 then
                table.insert(options, { label = 'Tưới nước', event = 'xx_farming:addWater', args = pPlantId })
            end

            if growth == 100 then
                table.insert(options, { label = 'Phá cây', event = 'xx_farming:removePlant', args = pPlantId })
            end

            if growth < 80 then
                table.insert(options, { label = 'Bón phân', event = 'xx_farming:addFertilizer', args = { plantId = pPlantId, type = "n" } })
            end

            if growth > 80 and growth < 99 then
                table.insert(options, { label = 'Cải thiện cây', event = 'xx_farming:addFertilizerk', args = { plantId = pPlantId, type = "k" } })
            end

            -- Thuốc trừ sâu chỉ khi cây không khỏe VÀ chưa đến 100%
            if health < 100 and growth < 100 then
                table.insert(options, { label = 'Thuốc thường', event = 'xx_farming:applyPesticide', args = { plantId = pPlantId, pesticideType = 'pesticide_basic' } })
                table.insert(options, { label = 'Thuốc cao cấp', event = 'xx_farming:applyPesticide', args = { plantId = pPlantId, pesticideType = 'pesticide_advanced' } })
            end

            if growth == 100 then
                table.insert(options, { label = 'Thu hoạch', event = 'xx_farming:harvestPlant', args = pPlantId })
            end
        else
            -- Menu cho người khác
            if canSteal then
                -- Luôn hiện nút thả sâu cho non-owner (server sẽ kiểm tra item)
                local cropConf = GetCropConfig(GetPlantCropType(plant))
                -- Thả sâu chỉ khi cây chưa trưởng thành (< 90%)
                if growth < 90 then
                    table.insert(options, { label = '🐛 Thả Sâu Bệnh', event = 'xx_farming:addbugs', args = { plantId = pPlantId, cropType = GetPlantCropType(plant) } })
                end
                -- Ăn cắp chỉ khi cây đã đạt 100%
                if growth >= 100 then
                    table.insert(options, { label = '🎭 Ăn Cắp Cây (Rủi Ro Cao)', event = 'xx_farming:attemptSteal', args = { plantId = pPlantId, targetPid = plant.owner } })
                end
                -- Nếu cây đang ở trạng thái không thể tương tác
                if growth >= 90 and growth < 100 then
                    table.insert(options, { label = '⏳ Cây đang trưởng thành (90-99%)', disabled = true })
                end
            else
                table.insert(options, { label = 'Không thể thao tác (Không có quyền)', disabled = true })
            end
        end

        -- Gửi dữ liệu đến NUI
        SendNUIMessage({
            action = "openMenu",
            growth = growth,
            water = water,
            fertilizer = fertilizer,
            health = health,
            options = options,
            canInteract = canInteract,
            canSteal = canSteal
        })

        -- Kích hoạt NUI focus
        SetNuiFocus(true, true)
    end, plantCoords, plant.owner)
end

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    plantMenuRequestId = plantMenuRequestId + 1
    SetNuiFocus(false, false)
    cb({ status = 'ok' })
end)

RegisterNUICallback('xx_farming:addWater', function(data, cb)
    TriggerEvent('xx_farming:addWater', data)
    cb('ok')
end)

RegisterNUICallback('xx_farming:removePlant', function(data, cb)
    TriggerEvent('xx_farming:removePlant', data)
    cb('ok')
end)

RegisterNUICallback('xx_farming:addFertilizer', function(data, cb)
    TriggerEvent('xx_farming:addFertilizer', data)
    cb('ok')
end)

RegisterNUICallback('xx_farming:addFertilizerk', function(data, cb)
    TriggerEvent('xx_farming:addFertilizerk', data)
    cb('ok')
end)

RegisterNUICallback('xx_farming:addbugs', function(data, cb)
    TriggerEvent('xx_farming:addbugs', data)
    cb('ok')
end)

RegisterNUICallback('xx_farming:applyPesticide', function(data, cb)
    TriggerEvent('xx_farming:applyPesticide', data)
    cb('ok')
end)

RegisterNUICallback('xx_farming:attemptSteal', function(data, cb)
    TriggerEvent('xx_farming:attemptSteal', data)
    cb('ok')
end)

-- Event handler cho việc ăn cắp
AddEventHandler('xx_farming:attemptSteal', function(data)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể ăn cắp khi đang ngồi trên xe!", "error")
        return
    end
    SetNuiFocus(false, false) -- Đóng NUI trước
    ShowStealPlantMenu(data.plantId, data.targetPid)
end)

RegisterNUICallback('xx_farming:harvestPlant', function(data, cb)
    TriggerEvent('xx_farming:pickPlant', data)
    cb('ok')
end)

-- Decrease Water and Fertilizer Over Time (Handled Server-side)

-- Xử lý các hành động từ NUI
RegisterNUICallback('fertilize', function(data, cb)
    --print("Fertilizer applied")  -- Thông báo debug
    -- Xử lý logic bón phân
    cb({ status = 'ok' })
end)

RegisterNUICallback('water', function(data, cb)
    --print("Water applied")  -- Thông báo debug
    -- Xử lý logic tưới nước
    cb({ status = 'ok' })
end)

RegisterNUICallback('removeWeeds', function(data, cb)
    --print("Weeds removed")  -- Thông báo debug
    -- Xử lý logic loại bỏ cỏ dại
    cb({ status = 'ok' })
end)

RegisterNUICallback('removePlant', function(data, cb)
    --print("Plant removed")  -- Thông báo debug
    -- Xử lý logic loại bỏ cây
    cb({ status = 'ok' })
end)

-- ==================== HỆ THỐNG BẢO VỆ CÂY TRỒNG & THUÊ CHÓ ====================

-- Event xử lý hiệu ứng bị chó cắn
RegisterNetEvent('xx_farming:dogBiteEffect', function(damage)
    local playerPed = PlayerPedId()
    
    -- Gây sát thương
    local currentHealth = GetEntityHealth(playerPed)
    local newHealth = math.max(0, currentHealth - damage)
    SetEntityHealth(playerPed, newHealth)
    
    -- Hiệu ứng stun
    SetPedToRagdoll(playerPed, 3000, 3000, 0, true, true, false)
    
    -- Âm thanh chó sủa
    PlaySoundFrontend(-1, "Hit_In", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
    
    -- Hiệu ứng máu
    StartScreenEffect("DrugsMichaelAliensFight", 0, false)
    CreateThread(function()
        Wait(5000)
        StopScreenEffect("DrugsMichaelAliensFight")
    end)
    
    -- Thông báo
    QBCore.Functions.Notify('Bạn đã bị chó bảo vệ cắn!', 'error', 5000)
end)

-- Function để hiển thị menu ăn cắp cây trồng
function ShowStealPlantMenu(plantId, targetPid)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể ăn cắp khi đang ngồi trên xe!", "error")
        return
    end
    lib.registerContext({
        id = 'steal_plant_menu',
        title = 'Ăn Cắp Cây Trồng',
        options = {
            {
                title = 'Ăn Cắp Cây',
                description = 'Cố gắng ăn cắp cây trồng này (có rủi ro)',
                icon = 'fas fa-mask',
                onSelect = function()
                    AttemptStealPlant(plantId, targetPid)
                end
            },
            {
                title = 'Hủy Bỏ',
                description = 'Không ăn cắp',
                icon = 'fas fa-times',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })
    lib.showContext('steal_plant_menu')
end

-- Function thực hiện ăn cắp
function AttemptStealPlant(plantId, targetPid)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể ăn cắp khi đang ngồi trên xe!", "error")
        return
    end
    QBCore.Functions.Progressbar("stealing_plant", "Đang ăn cắp cây trồng...", 10000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "amb@world_human_gardener_plant@male@base",
        anim = "base",
        flags = 16,
    }, {}, {}, function() -- Done
        -- Gọi server để thực hiện ăn cắp
        lib.callback('xx_farming:stealPlant', false, function(success, message)
            if success then
                QBCore.Functions.Notify(message, 'success')
                -- Refresh plants để ẩn cây đã bị ăn cắp
                TriggerEvent('xx_farming:client:RefreshPlants')
            else
                QBCore.Functions.Notify(message, 'error')
            end
        end, plantId)
    end, function() -- Cancel
        QBCore.Functions.Notify("Đã hủy ăn cắp", "error")
    end)
end

-- Function hiển thị menu thuê chó bảo vệ
function ShowDogProtectionMenu(zoneId)
    -- Lấy thông tin bảo vệ hiện tại
    lib.callback('xx_farming:getDogProtectionInfo', false, function(info)
        -- Kiểm tra nếu info là nil hoặc không hợp lệ
        if not info then
            info = { hasProtection = false }
        end
        
        local options = {}
        
        if info.hasProtection then
            local timeText = "N/A"
            if info.expiresAt then
                -- Convert timestamp to readable format using FiveM client time
                local currentTime = GetCloudTimeAsInt()
                local expirationTime = tonumber(info.expiresAt) or 0
                
                -- Nếu expirationTime quá lớn (milliseconds), chuyển về seconds
                if expirationTime > 9999999999 then
                    expirationTime = expirationTime / 1000
                end
                
                local timeLeft = expirationTime - currentTime
                
                if timeLeft > 0 then
                    local totalMinutes = math.floor(timeLeft / 60)
                    local hours = math.floor(totalMinutes / 60)
                    local minutes = totalMinutes % 60
                    
                    if hours > 0 then
                        timeText = string.format("còn lại: %d giờ %d phút", hours, minutes)
                    else
                        timeText = string.format("còn lại: %d phút", minutes)
                    end
                else
                    timeText = "Đã hết hạn"
                end
            end
            
            table.insert(options, {
                title = 'Thông Tin Chó Bảo Vệ',
                description = 'Khu vực này đã có chó bảo vệ ' .. timeText,
                icon = 'fas fa-shield-alt',
                disabled = true
            })
        else
            table.insert(options, {
                title = 'Thuê Bảo Vệ 1 Giờ',
                description = 'Giá: $10,000',
                icon = 'fas fa-clock',
                onSelect = function()
                    RentDogProtection(zoneId, 1)
                end
            })
            
            table.insert(options, {
                title = 'Thuê Bảo Vệ 6 Giờ',
                description = 'Giá: $60,000',
                icon = 'fas fa-clock',
                onSelect = function()
                    RentDogProtection(zoneId, 6)
                end
            })
            
            table.insert(options, {
                title = 'Thuê Bảo Vệ 12 Giờ',
                description = 'Giá: $120,000',
                icon = 'fas fa-clock',
                onSelect = function()
                    RentDogProtection(zoneId, 12)
                end
            })
            
            table.insert(options, {
                title = 'Thuê Bảo Vệ 24 Giờ',
                description = 'Giá: $240,000',
                icon = 'fas fa-clock',
                onSelect = function()
                    RentDogProtection(zoneId, 24)
                end
            })
        end
        
        table.insert(options, {
            title = 'Đóng',
            description = 'Đóng menu',
            icon = 'fas fa-times',
            onSelect = function()
                lib.hideContext()
            end
        })
        
        lib.registerContext({
            id = 'dog_protection_menu',
            title = 'Dịch Vụ chó bảo vệ',
            options = options
        })
        lib.showContext('dog_protection_menu')
    end, zoneId)
end

-- Function thuê chó bảo vệ
function RentDogProtection(zoneId, hours)
    lib.callback('xx_farming:rentDogProtection', false, function(success, message)
        if success then
            QBCore.Functions.Notify(message, 'success')
        else
            QBCore.Functions.Notify(message, 'error')
        end
    end, zoneId, hours)
end

-- Biến lưu trữ chó bảo vệ
local GuardDogs = {}

-- Function spawn chó bảo vệ NPC
RegisterNetEvent('xx_farming:spawnGuardDog')
AddEventHandler('xx_farming:spawnGuardDog', function(dogData)
    --print("Spawning guard dog at:", dogData.x, dogData.y, dogData.z)
    
    -- Model chó (sử dụng Rottweiler)
    local dogModel = `a_c_rottweiler`
    
    -- Request model
    RequestModel(dogModel)
    while not HasModelLoaded(dogModel) do
        Wait(100)
    end
    
    -- Spawn chó
    local dog = CreatePed(4, dogModel, dogData.x, dogData.y, dogData.z, 0.0, true, false)
    
    -- Cấu hình chó
    SetEntityHealth(dog, 200)
    SetPedMaxHealth(dog, 200)
    SetPedArmour(dog, 0)
    SetCanAttackFriendly(dog, false, true)
    SetPedRelationshipGroupHash(dog, `AGGRESSIVE_ANIMAL`)
    
    -- Làm cho chó tấn công player
    local targetPlayer = GetPlayerPed(PlayerId())
    if dogData.targetPlayerId and GetPlayerFromServerId(dogData.targetPlayerId) ~= -1 then
        targetPlayer = GetPlayerPed(GetPlayerFromServerId(dogData.targetPlayerId))
    end
    
    -- Cấu hình AI tấn công
    TaskCombatPed(dog, targetPlayer, 0, 16)
    SetPedCombatAttributes(dog, 46, true) -- Làm cho chó quyết liệt hơn
    SetPedCombatAttributes(dog, 0, false) -- Không bỏ cuộc
    
    -- Lưu chó vào danh sách
    table.insert(GuardDogs, {
        entity = dog,
        spawnTime = GetGameTimer(),
        target = targetPlayer
    })
    
    -- Thông báo cho player
    QBCore.Functions.Notify("Chó bảo vệ đã xuất hiện và đang tấn công bạn!", "error", 5000)
    
    -- Tự động xóa chó sau 30 giây
    SetTimeout(30000, function()
        if DoesEntityExist(dog) then
            DeleteEntity(dog)
            --print("Guard dog automatically deleted after 30 seconds")
        end
        
        -- Xóa khỏi danh sách
        for i, guardDog in ipairs(GuardDogs) do
            if guardDog.entity == dog then
                table.remove(GuardDogs, i)
                break
            end
        end
    end)
    
    -- Clean up model
    SetModelAsNoLongerNeeded(dogModel)
end)

-- Event để xóa tất cả chó bảo vệ khi cần
RegisterNetEvent('xx_farming:removeAllGuardDogs')
AddEventHandler('xx_farming:removeAllGuardDogs', function()
    for _, guardDog in ipairs(GuardDogs) do
        if DoesEntityExist(guardDog.entity) then
            DeleteEntity(guardDog.entity)
        end
    end
    GuardDogs = {}
    --print("All guard dogs removed")
end)

-- Thread kiểm tra chó bảo vệ
CreateThread(function()
    while true do
        Wait(5000) -- Kiểm tra mỗi 5 giây
        
        for i = #GuardDogs, 1, -1 do
            local guardDog = GuardDogs[i]
            
            if not DoesEntityExist(guardDog.entity) then
                -- Chó đã bị xóa, loại bỏ khỏi danh sách
                table.remove(GuardDogs, i)
            elseif GetGameTimer() - guardDog.spawnTime > 60000 then
                -- Chó đã tồn tại quá 60 giây, xóa nó
                DeleteEntity(guardDog.entity)
                table.remove(GuardDogs, i)
                --print("Guard dog removed after 60 seconds timeout")
            end
        end
    end
end)

-- Export functions để có thể gọi từ nơi khác
exports('ShowStealPlantMenu', ShowStealPlantMenu)
exports('ShowDogProtectionMenu', ShowDogProtectionMenu)

