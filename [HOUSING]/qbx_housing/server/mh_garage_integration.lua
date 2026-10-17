-- Tích hợp với mh_garage để tạo garage động cho nhà
-- File này chỉ chạy khi mh_garage đang hoạt động

if GetResourceState('mh_garage') ~= 'started' then
    print('^3[QBX Housing]^7 mh_garage not found, garage integration disabled')
    return
end

-- Bảng lưu garages của houses
local HouseGarages = {}

-- Helper lấy config garage chuẩn
local function BuildGarageConfig(houseId, houseConfig, houseType)
    if not houseConfig or not houseConfig.garagePoint or not houseConfig.garageSpawn then
        return nil
    end

    local gPoint = houseConfig.garagePoint
    local gSpawn = houseConfig.garageSpawn
    local spawnHeading = gSpawn.w or gSpawn.h or (type(gSpawn) == 'table' and gSpawn[4]) or 0.0
    local garageInterior = (houseType and houseType.garage and houseType.garage.interior) or 'low_end'
    local maxVehs = (houseType and houseType.garage and houseType.garage.maxVehicles) or 2

    local isGang = (houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or (houseConfig.type == 'gang')
    if isGang then
        local gLevel = tonumber(houseConfig.level) or 1
        local gCfg = Config.GangHouseLevels and Config.GangHouseLevels[gLevel]
        if gCfg and gCfg.garage then
            garageInterior = gCfg.garage.interior or 'low_end'
            maxVehs = gCfg.garage.maxVehicles or 2
        else
            if gLevel == 2 then
                garageInterior = 'medium'
                maxVehs = 6
            elseif gLevel >= 3 then
                garageInterior = 'autoshop'
                maxVehs = 10
            else
                garageInterior = 'low_end'
                maxVehs = 2
            end
        end
    end

    return {
        type = 'car',
        enter = vector3(gPoint.x, gPoint.y, gPoint.z),
        parkVehicle = vector3(gPoint.x, gPoint.y, gPoint.z),
        vehicleSpawnPoint = vector4(gSpawn.x, gSpawn.y, gSpawn.z, spawnHeading),
        price = nil,
        pricetakeout = 0,
        blip = { id = 0, scale = 0, colour = 0 },
        blackListClass = { 14, 15, 16, 19, 21 },
        GarageInfo = 'Garage ' .. (isGang and 'Trụ Sở Xã Đoàn' or ('nhà ' .. houseId)) .. '. Có thể để ' .. maxVehs .. ' xe.',
        interior = garageInterior
    }
end

-- Function để load và tạo garages cho tất cả houses đã mua và toàn bộ nhà Xã Đoàn
local function LoadExistingHouseGarages()
    -- 1. Load houses đã mua từ player_houses
    local result = MySQL.query.await('SELECT house_id FROM player_houses')
    if result then
        for _, house in ipairs(result) do
            local houseId = house.house_id
            local garageName = 'house_' .. houseId
            
            local houseConfig = exports.qbx_housing:GetHouseConfig(houseId)
            if not houseConfig and Config.Houses then
                for _, h in ipairs(Config.Houses) do
                    if h.id == houseId then
                        houseConfig = h
                        break
                    end
                end
            end
            
            if houseConfig and houseConfig.garagePoint and houseConfig.garageSpawn then
                local houseType = Config.HouseTypes[houseConfig.type]
                local garageConfig = BuildGarageConfig(houseId, houseConfig, houseType)
                if garageConfig then
                    HouseGarages[garageName] = garageConfig
                    exports['mh_garage']:InjectServerGarage(garageName, garageConfig)
                end
            end
        end
    end

    -- 2. Tự động kích hoạt garage cho TẤT CẢ nhà Xã Đoàn (mặc định sẵn sàng, không cần mua)
    local gangHouses = MySQL.query.await('SELECT id FROM houses WHERE enabled = 1 AND gang IS NOT NULL AND gang != "" AND gang != "none"')
    if gangHouses then
        for _, gh in ipairs(gangHouses) do
            local houseId = gh.id
            local garageName = 'house_' .. houseId
            if not HouseGarages[garageName] then
                local houseConfig = exports.qbx_housing:GetHouseConfig(houseId)
                if houseConfig and houseConfig.garagePoint and houseConfig.garageSpawn then
                    local houseType = Config.HouseTypes[houseConfig.type]
                    local garageConfig = BuildGarageConfig(houseId, houseConfig, houseType)
                    if garageConfig then
                        HouseGarages[garageName] = garageConfig
                        exports['mh_garage']:InjectServerGarage(garageName, garageConfig)
                    end
                end
            end
        end
    end
end

-- Load existing garages khi resource start
CreateThread(function()
    Wait(2000) -- Wait for database and housing cache to be ready
    LoadExistingHouseGarages()
    
    -- Sync cho tất cả players đang online trong 1 payload
    Wait(500)
    if next(HouseGarages) then
        TriggerClientEvent('qbx_housing:client:SyncAllGarages', -1, HouseGarages)
    end
end)

-- Tạo garage mới cho house (hoạt động tức thì khi mua nhà)
function CreateHouseGarage(src, houseId, houseConfig, houseType)
    if not houseConfig then
        houseConfig = exports.qbx_housing:GetHouseConfig(houseId)
    end
    if not houseType and houseConfig then
        houseType = Config.HouseTypes[houseConfig.type]
    end

    if not houseConfig or not houseType then
        print('^1[QBX Housing]^7 ERROR: Missing houseConfig or houseType for ' .. tostring(houseId))
        return false
    end

    local garageName = 'house_' .. houseId
    local garageConfig = BuildGarageConfig(houseId, houseConfig, houseType)

    if not garageConfig then
        print('^1[QBX Housing]^7 ERROR: Failed to build garageConfig for ' .. tostring(houseId))
        return false
    end

    -- Lưu vào server cache
    HouseGarages[garageName] = garageConfig

    -- Inject vào mh_garage SERVER-side GaragesData
    local success = exports['mh_garage']:InjectServerGarage(garageName, garageConfig)
    if not success then
        print('^1[QBX Housing]^7 ERROR: Failed to inject garage into mh_garage server: ' .. garageName)
    end

    -- Đồng bộ ngay lập tức cho TẤT CẢ client (bao gồm người vừa mua)
    TriggerClientEvent('qbx_housing:client:SyncHouseGarage', -1, garageName, garageConfig)

    return true
end

-- Export để gọi từ code khác
exports('CreateHouseGarage', CreateHouseGarage)

-- Event chuyển nhượng garage khi bán nhà cho người khác
RegisterNetEvent('qbx_housing:server:TransferHouseGarage', function(houseId, newOwnerCitizenId)
    local houseConfig = exports.qbx_housing:GetHouseConfig(houseId)
    if houseConfig then
        local houseType = Config.HouseTypes[houseConfig.type]
        CreateHouseGarage(source, houseId, houseConfig, houseType)
    end
end)

-- Export để lấy garage config
exports('GetHouseGarageConfig', function(garageName)
    return HouseGarages[garageName]
end)

-- Export để kiểm tra xem garage có phải của house không
exports('IsHouseGarage', function(garageName)
    return HouseGarages[garageName] ~= nil
end)

-- Export để lấy bảng HouseGarages (for internal use only)
exports('GetHouseGaragesTable', function()
    return HouseGarages
end)

-- Export để reload tất cả garages (gọi từ admin reload)
exports('ReloadAllHouseGarages', function()
    for garageName in pairs(HouseGarages) do
        pcall(function()
            exports['mh_garage']:RemoveServerGarage(garageName)
        end)
    end
    HouseGarages = {}
    
    LoadExistingHouseGarages()
    
    Wait(200)
    if next(HouseGarages) then
        TriggerClientEvent('qbx_housing:client:SyncAllGarages', -1, HouseGarages)
    end
    
    return true
end)

-- Sync garages khi player join (1 payload thay vì lặp Wait 50)
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    if next(HouseGarages) then
        TriggerClientEvent('qbx_housing:client:SyncAllGarages', src, HouseGarages)
    end
end)

RegisterNetEvent('qbx_core:server:playerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if src and next(HouseGarages) then
        TriggerClientEvent('qbx_housing:client:SyncAllGarages', src, HouseGarages)
    end
end)

-- Callback để client request garage config
lib.callback.register('qbx_housing:server:getHouseGarage', function(source, houseId)
    local garageName = 'house_' .. houseId
    local garageConfig = HouseGarages[garageName]
    
    if garageConfig then
        TriggerClientEvent('qbx_housing:client:SyncHouseGarage', source, garageName, garageConfig)
        return garageConfig
    else
        -- Thử build động nếu nhà đã được mua HOẶC là nhà Xã Đoàn (mặc định có garage)
        local houseData = exports.qbx_housing:GetHouseData(houseId)
        local houseConfig = exports.qbx_housing:GetHouseConfig(houseId)
        local isGangHouse = houseConfig and ((houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang')
        if houseData or isGangHouse then
            local houseConfig = exports.qbx_housing:GetHouseConfig(houseId)
            if houseConfig then
                local houseType = Config.HouseTypes[houseConfig.type]
                local newConfig = BuildGarageConfig(houseId, houseConfig, houseType)
                if newConfig then
                    HouseGarages[garageName] = newConfig
                    exports['mh_garage']:InjectServerGarage(garageName, newConfig)
                    TriggerClientEvent('qbx_housing:client:SyncHouseGarage', -1, garageName, newConfig)
                    return newConfig
                end
            end
        end
        return false
    end
end)

-- Xóa garage khi reset nhà
RegisterNetEvent('qbx_housing:server:DeleteHouseGarage', function(houseId)
    local garageName = 'house_' .. houseId
    HouseGarages[garageName] = nil
    
    pcall(function()
        exports['mh_garage']:RemoveServerGarage(garageName)
    end)
    
    TriggerClientEvent('qbx_housing:client:RemoveHouseGarage', -1, garageName)
end)

-- Command để sync lại tất cả garages (debug console)
RegisterCommand('syncgarages', function(source, args, rawCommand)
    if source == 0 then
        local count = 0
        for _ in pairs(HouseGarages) do count = count + 1 end
        print('^3[QBX Housing]^7 Manual sync: Broadcasting ' .. count .. ' garages to all players')
        TriggerClientEvent('qbx_housing:client:SyncAllGarages', -1, HouseGarages)
    end
end, false)

-- Thêm export để mh_garage có thể check ownership
exports('CanAccessHouseGarage', function(source, garageName)
    if not garageName or not garageName:find('^house_') then
        return true
    end
    
    local houseId = garageName:gsub('house_', '')
    local QBX = exports.qbx_core
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    return exports.qbx_housing:IsOwner(player.PlayerData.citizenid, houseId)
end)


-- Event cập nhật garage động (khi nâng cấp cấp độ nhà gang hoặc đổi config)
RegisterNetEvent('qbx_housing:server:UpdateHouseGarage', function(houseId)
    local houseConfig = exports.qbx_housing:GetHouseConfig(houseId)
    if houseConfig then
        local houseType = Config.HouseTypes[houseConfig.type]
        CreateHouseGarage(-1, houseId, houseConfig, houseType)
        print('^2[QBX Housing]^7 Successfully updated and synced garage for house: ' .. tostring(houseId))
    end
end)
