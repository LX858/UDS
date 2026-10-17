local weed = {}
local CanUseFarm = nil
local Weed_Crafting = {}
local DangTraoDoi = false
local ProcessZones = {}
local PlantZones = {}
local isSpawning = false

local function TriggerServerEventProtected(eventName, ...)
    local args = {...}
    local success = pcall(function()
        exports.loadscript:TriggerServerEvent(eventName, table.unpack(args))
    end)
    if not success then
        TriggerServerEvent(eventName, nil, table.unpack(args))
    end
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function SpawnObject(model, coords, cb)
    local modelHash = (type(model) == 'number' and model or GetHashKey(model))
    CreateThread(function()
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 100 do
            Wait(50)
            timeout = timeout + 1
        end

        if not HasModelLoaded(modelHash) then
            print('^1[xn_haibong] Không thể load model: ' .. tostring(model) .. '^7')
            return
        end

        local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        SetEntityCollision(obj, true, true)
        SetEntityAsMissionEntity(obj, true, true)
        SetModelAsNoLongerNeeded(modelHash)

        if cb ~= nil then
            cb(obj)
        end
    end)
end

local function stopAction(ped, dict, anim, message, stressAmount)
    StopAnimTask(ped, dict, anim, 1.0)
    TriggerServerEvent('hud:server:GainStress', stressAmount)
    if message then
        exports.qbx_core:Notify(message, 'error')
    end
end

local function GetFarmConfig(farmId)
    if farmId and Config.Farms and Config.Farms[farmId] then
        return Config.Farms[farmId], farmId
    end

    if Config.Farms then
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local closestFarm = nil
        local minDistance = 999999.0

        for id, farm in pairs(Config.Farms) do
            if farm.Locations then
                for _, loc in ipairs(farm.Locations) do
                    local dist = #(playerCoords - loc)
                    if dist < minDistance then
                        minDistance = dist
                        closestFarm = id
                    end
                end
            end
            if farm.ProcessLocation then
                local dist = #(playerCoords - vector3(farm.ProcessLocation.x, farm.ProcessLocation.y, farm.ProcessLocation.z))
                if dist < minDistance then
                    minDistance = dist
                    closestFarm = id
                end
            end
        end

        if closestFarm then
            return Config.Farms[closestFarm], closestFarm
        end
    end

    return Config, 'haibong'
end

local function DeleteAllWeed()
    for _, zoneId in pairs(PlantZones) do
        exports.ox_target:removeZone(zoneId)
    end
    PlantZones = {}

    for _, v in pairs(weed) do
        if DoesEntityExist(v) then
            DeleteObject(v)
        end
    end
    weed = {}
end

local function SpawnWeed()
    if isSpawning then return end
    isSpawning = true

    DeleteAllWeed()

    CreateThread(function()
        local farms = Config.Farms or { ['default'] = Config }

        for farmId, farm in pairs(farms) do
            local locations = farm.Locations or farm.WeedLocations or {}
            local plantModel = farm.Object or 'bzzz_plant_cotton_f'

            for k, v in pairs(locations) do
                -- 1. Spawn cây
                SpawnObject(plantModel, vector3(v.x, v.y, v.z - 1.0), function(obj)
                    table.insert(weed, obj)
                end)

                -- 2. Đăng ký duy nhất 1 SphereZone target cho mỗi tọa độ cây
                local plantZoneOption = {
                    name = 'pick_zone_' .. farmId .. '_' .. k,
                    icon = 'fa-solid fa-scissors',
                    label = farm.Label or 'Thu hoạch',
                    distance = 2.5,
                    onSelect = function()
                        TriggerEvent('1307_HaiCan:client:UseScissors', true, farmId)
                    end
                }

                if farm.Job then
                    plantZoneOption.groups = farm.Job
                end

                local zoneId = exports.ox_target:addSphereZone({
                    name = 'farm_plant_' .. farmId .. '_' .. k,
                    coords = v,
                    radius = 1.3,
                    debug = false,
                    options = { plantZoneOption }
                })
                table.insert(PlantZones, zoneId)

                -- 3. PolyZone kiểm tra đứng trong khu vực
                lib.zones.box({
                    coords = v,
                    size = vec3(2.5, 2.5, 2.5),
                    rotation = 45,
                    debug = false,
                    inside = function()
                        CanUseFarm = farmId
                    end,
                    onExit = function()
                        if CanUseFarm == farmId then
                            CanUseFarm = nil
                        end
                    end
                })
            end
        end

        isSpawning = false
    end)
end

local function SetupProcessZones()
    local farms = Config.Farms or { ['default'] = Config }

    for farmId, farm in pairs(farms) do
        if farm.ProcessLocation then
            local coords = vector3(farm.ProcessLocation.x, farm.ProcessLocation.y, farm.ProcessLocation.z)
            local heading = farm.ProcessLocation.w or farm.ProcessLocation.h or 0.0

            local option = {
                name = "farm_process_" .. farmId,
                icon = "fa-solid fa-industry",
                label = farm.ProcessLabel or 'Chế biến',
                distance = 2.5,
                onSelect = function()
                    TriggerEvent('1307_HaiCan:client:ProcessWeed', farmId)
                end
            }

            if farm.Job then
                option.groups = farm.Job
            end

            local zoneId = exports.ox_target:addBoxZone({
                name = "farm_process_" .. farmId,
                coords = coords,
                size = vec3(2.0, 2.0, 2.0),
                rotation = heading,
                debug = false,
                drawSprite = true,
                options = { option }
            })
            table.insert(ProcessZones, zoneId)
        end
    end
end

CreateThread(function()
    SetupProcessZones()
    SpawnWeed()
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    SpawnWeed()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    DeleteAllWeed()
    for _, v in pairs(Weed_Crafting) do
        if DoesEntityExist(v) then
            DeleteObject(v)
        end
    end
    Weed_Crafting = {}
end)


RegisterNetEvent('1307_HaiCan:client:UseScissors', function(isTargeting, targetFarmId)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, true) then
        return exports.qbx_core:Notify('Vui lòng xuống xe!', 'error')
    end

    local farmId = targetFarmId or CanUseFarm
    local farmConfig, resolvedFarmId = GetFarmConfig(farmId)

    if farmConfig.Job then
        local playerData = QBPlayerData or exports.qbx_core:GetPlayerData()
        local playerJob = playerData and playerData.job and playerData.job.name
        if playerJob ~= farmConfig.Job then
            return exports.qbx_core:Notify('Bạn không có quyền thực hiện công việc này!', 'error')
        end
    end

    local scissorsItem = farmConfig.Scissors
    if scissorsItem and scissorsItem ~= false then
        local hasScissors = exports.ox_inventory:Search('count', scissorsItem)
        if hasScissors <= 0 then
            return exports.qbx_core:Notify('Bạn không có kéo để thu hoạch!', 'error')
        end
    end

    loadAnimDict('missheistfbisetup1')
    TaskPlayAnim(ped, 'missheistfbisetup1', 'hassle_intro_loop_f', -8.0, -8.0, -1, 1, 0, 0, 0, 0)

    local pickTime = (farmConfig.PickTime or 5) * 1000
    local harvestLabel = "Đang " .. (farmConfig.Label or "Thu hoạch")

    if lib.progressCircle({
        duration = pickTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
            use = false,
        },
        label = harvestLabel,
    }) then
        StopAnimTask(ped, "missheistfbisetup1", "hassle_intro_loop_f", 1.0)
        TriggerServerEvent('1307_HaiCan:server:RewardWeed', resolvedFarmId)
    else
        StopAnimTask(ped, "missheistfbisetup1", "hassle_intro_loop_f", 1.0)
        exports.qbx_core:Notify('Đã hủy!', 'error')
    end
end)

RegisterNetEvent('1307_HaiCan:client:ProcessWeed', function(targetFarmId)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, true) then
        return exports.qbx_core:Notify('Vui lòng xuống xe!', 'error')
    end

    local farmConfig, resolvedFarmId = GetFarmConfig(targetFarmId)

    if farmConfig.Job then
        local playerData = QBPlayerData or exports.qbx_core:GetPlayerData()
        local playerJob = playerData and playerData.job and playerData.job.name
        if playerJob ~= farmConfig.Job then
            return exports.qbx_core:Notify('Bạn không có quyền thực hiện công việc này!', 'error')
        end
    end

    local itemToProcess = farmConfig.Weed or 'bonggon'
    local amountRequired = farmConfig.AmountToProcess or 2
    local processTime = (farmConfig.ProcessTime or 5) * 1000
    local processLabel = "Đang " .. (farmConfig.ProcessLabel or "Chế Biến")

    local countItem = exports.ox_inventory:Search('count', itemToProcess)
    local countMayXay = exports.ox_inventory:Search('count', 'may_xay')

    if countItem < amountRequired then
        return exports.qbx_core:Notify('Bạn không đủ nguyên liệu để chế biến! (Cần ' .. amountRequired .. ')', 'error')
    end

    if countMayXay <= 0 then
        return exports.qbx_core:Notify('Có vẻ như bạn đang thiếu máy xay', 'error')
    end

    loadAnimDict('mini@repair')
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', -8.0, -8.0, -1, 1, 0, 0, 0, 0)

    if lib.progressCircle({
        duration = processTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
            use = false,
        },
        label = processLabel,
    }) then
        StopAnimTask(ped, "mini@repair", "fixing_a_ped", 1.0)
        TriggerServerEvent('1307_HaiCan:server:RewardJoint', resolvedFarmId)
    else
        StopAnimTask(ped, "mini@repair", "fixing_a_ped", 1.0)
        exports.qbx_core:Notify('Đã hủy!', 'error')
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    SpawnWeed()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, zoneId in pairs(ProcessZones) do
        exports.ox_target:removeZone(zoneId)
    end
    DeleteAllWeed()
    for _, v in pairs(Weed_Crafting) do
        if DoesEntityExist(v) then
            DeleteObject(v)
        end
    end
    Weed_Crafting = {}
end)

-- RÃ BIỂN BÁO / TRAO ĐỔI
function TraoDoiCanSa()
    local ped = PlayerPedId()
    local jointItem = Config.Joint or 'bonggon'
    if exports.ox_inventory:Search('count', jointItem) <= 0 then
        return exports.qbx_core:Notify('Bạn làm gì có nguyên liệu trong người ?', 'error')
    end

    if DangTraoDoi then
        return exports.qbx_core:Notify('Vội cái hand thế bro!', 'error')
    end

    DangTraoDoi = true
    loadAnimDict("glap@take-my-heart")
    TaskPlayAnim(ped, "glap@take-my-heart", "take-my-heart", -8.0, -8.0, -1, 1, 0, 0, 0, 0)

    if lib.progressBar({
        duration = 30000,
        position = 'bottom',
        canCancel = false,
        disable = { move = true, car = true, combat = true },
        label = "Đang trao đổi..."
    }) then
        DangTraoDoi = false
        stopAction(ped, "glap@take-my-heart", "take-my-heart", nil, 5)
        TriggerServerEvent("1307_HaiCan:sv:NhanDieuCan")
    else
        DangTraoDoi = false
        stopAction(ped, "glap@take-my-heart", "take-my-heart", 'Đã hủy!', 2)
    end
end

RegisterNetEvent('1307_HaiCan:cl:TraoDoi', function()
    local copsRequired = Config.Cops or 0
    local CurrentCops = GlobalState['police_count'] or 0
    if CurrentCops < copsRequired then
        return exports.qbx_core:Notify("Không đủ cảnh sát! (Cần [" .. copsRequired .. "] trở lên)", "error")
    end
    TraoDoiCanSa()
end)