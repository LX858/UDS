-- ============================================================
--  xn_farming — Core & State Management (Server Side)
--  Tối ưu hóa Core Framework calls + In-Memory State Caching
-- ============================================================

local qbCoreObj = exports["qb-core"]:GetCoreObject()

-- Giữ bản gốc trước khi hook, tránh hàm hook tự gọi lại chính nó (tràn stack)
local origGetPlayer = qbCoreObj.Functions.GetPlayer
local origGetPlayerByCitizenId = qbCoreObj.Functions.GetPlayerByCitizenId

-- ==================== 1. CORE PLAYER CACHE ====================
local playerCache = {}
local pidCache = {}

local hGetPlayer = function(playerSrc)
    playerSrc = tonumber(playerSrc)
    if not playerSrc then return nil end
    
    if not playerCache[playerSrc] then
        local p = origGetPlayer(playerSrc)
        if p then
            playerCache[playerSrc] = p
            local pid = p.PlayerData and (p.PlayerData.pid or p.PlayerData.citizenid)
            if pid then
                pidCache[pid] = p
            end
        end
    end
    return playerCache[playerSrc]
end

local hGetPlayerByCitizenId = function(pid)
    if not pid then return nil end
    if pidCache[pid] then
        return pidCache[pid]
    end
    
    local p = origGetPlayerByCitizenId(pid)
    if p then
        local src = p.PlayerData and p.PlayerData.source
        if src then
            playerCache[src] = p
        end
        pidCache[pid] = p
        return p
    end
    return nil
end

-- Metatable wrapper Framework (hỗ trợ cả QBCore và ESX naming convention)
Framework = {}
setmetatable(Framework, {
    __index = function(self, k)
        if k == "GetPlayer" or k == "GetPlayerFromId" then
            return hGetPlayer
        elseif k == "GetPlayerByCitizenId" or k == "GetPlayerFromIdcard" or k == "GetPlayerByPid" then
            return hGetPlayerByCitizenId
        elseif k == "Functions" then
            return qbCoreObj.Functions
        elseif k == "Shared" then
            return qbCoreObj.Shared
        elseif k == "Commands" then
            return qbCoreObj.Commands
        else
            return qbCoreObj[k]
        end
    end
})

-- Hook thẳng vào QBCore.Functions để tất cả các lời gọi cũ tự động hưởng lợi từ cache
if qbCoreObj and qbCoreObj.Functions then
    qbCoreObj.Functions.GetPlayer = hGetPlayer
    qbCoreObj.Functions.GetPlayerByCitizenId = hGetPlayerByCitizenId
end

-- Tự động giải phóng cache khi người chơi thoát
AddEventHandler("playerDropped", function()
    local src = source
    local p = playerCache[src]
    if p and p.PlayerData then
        local pid = p.PlayerData.pid or p.PlayerData.citizenid
        if pid then pidCache[pid] = nil end
    end
    playerCache[src] = nil
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    local targetSrc = src or source
    local p = playerCache[targetSrc]
    if p and p.PlayerData then
        local pid = p.PlayerData.pid or p.PlayerData.citizenid
        if pid then pidCache[pid] = nil end
    end
    playerCache[targetSrc] = nil
end)

-- ==================== 2. IN-MEMORY STATE CACHE ====================
-- Tất cả các bảng dữ liệu được cache vào RAM, loại bỏ hoàn toàn các truy vấn đồng bộ lặp lại
Plants = {}             -- Plants[plantId] = { id = ..., coords = ..., ... }
PlayerPlantCounts = {}  -- PlayerPlantCounts[pid] = số lượng cây
FarmRentals = {}        -- FarmRentals[zoneId] = { id = ..., owner = ..., end_time = ..., ... }
FarmPermissions = {}    -- FarmPermissions[zoneId] = { [shared_with_pid] = { ... } }
DogProtections = {}     -- DogProtections[zoneId] = { expires_at = ..., renter_pid = ... }

-- A player watches one farm at a time. getPlants registers the initial snapshot;
-- leaving, disconnecting and the periodic distance check remove stale watchers.
local watchedZoneByPlayer = {}
local watchersByZone = {}
local syncPackets = 0
local batchPackets = 0
local batchPlants = 0

function UnsubscribePlantZone(src, expectedZone)
    local zoneId = watchedZoneByPlayer[src]
    if not zoneId or (expectedZone and zoneId ~= tonumber(expectedZone)) then return end
    watchedZoneByPlayer[src] = nil
    local watchers = watchersByZone[zoneId]
    if watchers then
        watchers[src] = nil
        if not next(watchers) then watchersByZone[zoneId] = nil end
    end
end

function SubscribePlantZone(src, zoneId)
    zoneId = tonumber(zoneId)
    if not zoneId or not FarmRental or not FarmRental.FarmZones[zoneId] then return false end
    UnsubscribePlantZone(src)
    watchedZoneByPlayer[src] = zoneId
    watchersByZone[zoneId] = watchersByZone[zoneId] or {}
    watchersByZone[zoneId][src] = true
    return true
end

function BroadcastZonePlantEvent(zoneId, eventType, payload)
    local watchers = watchersByZone[tonumber(zoneId)]
    if not watchers then return end
    for src in pairs(watchers) do
        TriggerClientEvent('xx_farming:trigger_zone', src, eventType, payload)
        syncPackets = syncPackets + 1
    end
end

function BroadcastPlantBatch(zoneId, changes)
    local watchers = watchersByZone[tonumber(zoneId)]
    if not watchers then return end
    for first = 1, #changes, 64 do
        local batch = {}
        for i = first, math.min(first + 63, #changes) do
            batch[#batch + 1] = changes[i]
        end
        for src in pairs(watchers) do
            TriggerClientEvent('xx_farming:plantBatch', src, tonumber(zoneId), batch)
            batchPackets = batchPackets + 1
            batchPlants = batchPlants + #batch
        end
    end
end

RegisterNetEvent('xx_farming:leaveZone', function(zoneId)
    UnsubscribePlantZone(source, zoneId)
end)

AddEventHandler('playerDropped', function()
    UnsubscribePlantZone(source)
end)

CreateThread(function()
    while true do
        Wait(10000)
        for src, zoneId in pairs(watchedZoneByPlayer) do
            local zone = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId]
            local ped = GetPlayerPed(src)
            local coords = ped and ped ~= 0 and GetEntityCoords(ped)
            if not zone or not coords or #(vector2(coords.x, coords.y) - vector2(zone.center.x, zone.center.y)) > zone.radius + 10.0 then
                UnsubscribePlantZone(src)
            end
        end
    end
end)

-- Latest full status wins. A row has at most one UPDATE in flight, and only a
-- matching revision may remove its pending entry after DB acknowledgement.
local pendingPlantWrites = {}
local activePlantWrites = 0
local writeFailures = 0
local lastWriteWarning = 0
local statusColumns = { 'water', 'fertilizer', 'health', 'plantgender' }

local function queuePlantWrite(plant)
    local id = tonumber(plant.id)
    local entry = pendingPlantWrites[id]
    if not entry then
        entry = { revision = 0, nextAttempt = 0, retries = 0, inFlight = false }
        pendingPlantWrites[id] = entry
    end
    entry.revision = entry.revision + 1
    entry.snapshot = { plant.water, plant.fertilizer, plant.health, plant.plantgender, id }
end

function ClearPendingPlantWrites(plantId)
    if plantId then
        pendingPlantWrites[tonumber(plantId)] = nil
    else
        pendingPlantWrites = {}
    end
end

function GetPendingPlantWriteCount()
    local count = 0
    for _ in pairs(pendingPlantWrites) do count = count + 1 end
    return count, activePlantWrites, writeFailures
end

RegisterCommand('xn_farming_dbqueue', function(src)
    if src ~= 0 then return end
    local queued, active, failures = GetPendingPlantWriteCount()
    print(('[xn_farming] DB queue: pending=%d active=%d failures=%d; sync=%d batch=%d batchPlants=%d'):format(
        queued, active, failures, syncPackets, batchPackets, batchPlants))
end, true)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local queued, active = GetPendingPlantWriteCount()
    if queued > 0 or active > 0 then
        print(('[xn_farming] Stopping with pending=%d active=%d plant writes; recent RAM changes may be lost'):format(queued, active))
    end
end)

CreateThread(function()
    while true do
        Wait(100)
        if activePlantWrites < 4 then
            local now = os.time()
            for id, entry in pairs(pendingPlantWrites) do
                if activePlantWrites >= 4 then break end
                if not entry.inFlight and entry.nextAttempt <= now then
                    entry.inFlight = true
                    activePlantWrites = activePlantWrites + 1
                    local revision = entry.revision
                    local snapshot = entry.snapshot
                    CreateThread(function()
                        local ok, result = pcall(MySQL.update.await,
                            'UPDATE tomato_db SET water = ?, fertilizer = ?, health = ?, plantgender = ? WHERE id = ?', snapshot)
                        activePlantWrites = activePlantWrites - 1
                        if pendingPlantWrites[id] ~= entry then return end
                        entry.inFlight = false
                        if ok and result ~= nil and result ~= false then
                            entry.retries = 0
                            if entry.revision == revision then
                                pendingPlantWrites[id] = nil
                            else
                                entry.nextAttempt = 0
                            end
                        else
                            writeFailures = writeFailures + 1
                            entry.retries = entry.retries + 1
                            entry.nextAttempt = os.time() + math.min(30, 2 ^ math.min(entry.retries - 1, 5))
                            if os.time() - lastWriteWarning >= 30 then
                                lastWriteWarning = os.time()
                                print(('[xn_farming] DB plant UPDATE failed; pending=%d, retrying (error=%s)'):format(GetPendingPlantWriteCount(), tostring(result)))
                            end
                        end
                    end)
                end
            end
        end
    end
end)

-- Debug helper
function FarmDebugPrint(...)
    if Config and Config.Debug then
        print(...)
    end
end

-- Hàm lấy cây trồng theo ID từ RAM (O(1))
getPlantById = function(plantId)
    plantId = tonumber(plantId)
    if not plantId then return nil end
    return Plants[plantId]
end

-- Hàm lấy số lượng cây trồng của người chơi từ RAM (O(1))
function getPlayerPlantCount(playerId)
    if not playerId then return 0 end
    return PlayerPlantCounts[playerId] or 0
end

-- Hàm cập nhật số lượng cây trồng của người chơi
function updatePlayerPlantCount(playerId, count)
    if not playerId then return end
    if count == nil then
        return getPlayerPlantCount(playerId)
    end
    PlayerPlantCounts[playerId] = math.max(0, count)
end

-- Hàm kiểm tra xem có thể trồng thêm cây không
function canPlantMore(playerId, cropType, zoneId)
    local cropConf = (CropTypes and cropType and CropTypes[cropType]) or Melons
    local baseLimit = cropConf.planamount or Melons.planamount or 60
    local zoneConf = FarmRental and FarmRental.FarmZones and zoneId and FarmRental.FarmZones[zoneId]
    local multiplier = (zoneConf and zoneConf.plantLimitMultiplier) or (zoneId == 13 and 3) or 1
    local maxLimit = math.floor(baseLimit * multiplier)
    local currentCount = getPlayerPlantCount(playerId)
    return currentCount < maxLimit, currentCount, maxLimit
end

-- Hàm xóa cây khỏi RAM và cập nhật số lượng cây
function deletePlantFromMemory(plantId)
    plantId = tonumber(plantId)
    if not plantId then return end
    local plant = Plants[plantId]
    ClearPendingPlantWrites(plantId)
    if plant then
        local owner = plant.owner
        if owner and PlayerPlantCounts[owner] then
            PlayerPlantCounts[owner] = math.max(0, PlayerPlantCounts[owner] - 1)
        end
        Plants[plantId] = nil
    end
end

-- Hàm cập nhật dữ liệu cây trong RAM và ghi async xuống DB
function updatePlantInMemoryAndDB(plantId, updates, deferSync)
    plantId = tonumber(plantId)
    if not plantId then return false end
    local plant = Plants[plantId]
    if not plant then return false end
    
    local delta = { id = plantId }
    local changed = false
    for _, key in ipairs(statusColumns) do
        local value = updates[key]
        if value ~= nil and plant[key] ~= value then
            plant[key] = value
            delta[key] = value
            changed = true
        end
    end
    if changed then
        queuePlantWrite(plant)
        if not deferSync then BroadcastZonePlantEvent(plant.zone_id, 3, delta) end
        return true, delta
    end
    return true, nil
end

-- Hàm lấy zone ID từ tọa độ
function GetZoneIdFromCoords(coords)
    if not FarmRental or not FarmRental.FarmZones or not coords then
        return nil
    end
    
    local cX, cY, cZ = coords.x, coords.y, coords.z
    if not cX or not cY or not cZ then return nil end
    local pos = vector3(cX, cY, cZ)
    
    for zoneId, zone in pairs(FarmRental.FarmZones) do
        if zone and zone.center and zone.radius then
            local dist = #(pos - zone.center)
            if dist <= zone.radius then
                return zoneId
            end
        end
    end
    return nil
end

-- Hàm kiểm tra quyền trồng / tương tác trên ruộng (100% RAM Lookup, 0 DB query)
function CheckFarmPermission(playerId, zoneId)
    if not playerId or not zoneId then return false, "none" end
    zoneId = tonumber(zoneId) or zoneId
    
    local zoneConf = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId]

    -- Ruộng chiếm khu: không dùng cơ chế thuê, quyền do gang chiếm khu quyết định
    if zoneConf and zoneConf.capture and ZoneCapture then
        if ZoneCapture.IsLockedFor(playerId, zoneId) then
            return false, "locked"
        end
        return true, "capture"
    end

    -- Nếu ruộng khai báo no_rent = true thì ai cũng được phép (ruộng công cộng)
    if zoneConf and zoneConf.no_rent then
        return true, "public"
    end
    
    local rental = FarmRentals[zoneId]
    if rental and rental.is_active == 1 and rental.end_time > os.time() then
        if rental.owner == playerId then
            return true, "owner"
        end
        if FarmPermissions[zoneId] and FarmPermissions[zoneId][playerId] then
            return true, "shared"
        end
    end
    
    return false, "none"
end

-- Hàm kiểm tra chó bảo vệ từ RAM (O(1))
function HasDogProtection(zoneId)
    if not zoneId then return false, nil end
    zoneId = tonumber(zoneId) or zoneId
    local dp = DogProtections[zoneId]
    if dp and dp.expires_at and dp.expires_at > os.time() then
        return true, dp
    end
    return false, nil
end

-- Helper tính growth % phía server
function GetServerPlantGrowth(plant)
    if not plant then return 0 end
    local cropType = plant.crop_type or 'rice'
    local cropConf = (CropTypes and CropTypes[cropType]) or Melons
    local timeDiff = (os.time() - (tonumber(plant.timestamp) or os.time())) / 60
    local maleFactor = (tonumber(plant.plantgender) == 1 and cropConf.MaleFactor or 1)
    local fertFactor = (tonumber(plant.fertilizer) or 0) >= 50 and cropConf.FertilizerFactor or 1.0
    local growthFactors = (cropConf.GrowthTime or 15) * maleFactor * fertFactor
    local zoneConf = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[tonumber(plant.zone_id)]
    growthFactors = math.max(growthFactors - ((zoneConf and zoneConf.growthTimeReduction) or 0), 1)
    if growthFactors <= 0 then growthFactors = 1 end
    return math.min((timeDiff / growthFactors) * 100, 100.0)
end

-- ==================== 3. KHỞI TẠO VÀ TẢI DỮ LIỆU BAN ĐẦU ====================
local isDataLoaded = false

function InitFarmingData()
    if isDataLoaded then return end
    
    CreateThread(function()
        local currentTime = os.time()
        
        -- 1. Tải toàn bộ cây trồng
        local plantsResult = MySQL.query.await('SELECT * FROM tomato_db', {})
        Plants = {}
        PlayerPlantCounts = {}
        if plantsResult then
            for _, plant in ipairs(plantsResult) do
                local pId = tonumber(plant.id)
                if pId then
                    plant.id = pId
                    plant.plantgender = tonumber(plant.plantgender) or 0
                    plant.water = tonumber(plant.water) or 0
                    plant.fertilizer = tonumber(plant.fertilizer) or 0
                    plant.timestamp = tonumber(plant.timestamp) or currentTime
                    plant.health = tonumber(plant.health) or 100
                    plant.zone_id = tonumber(plant.zone_id) or plant.zone_id
                    
                    Plants[pId] = plant
                    
                    if plant.owner then
                        PlayerPlantCounts[plant.owner] = (PlayerPlantCounts[plant.owner] or 0) + 1
                    end
                end
            end
        end
        
        -- 2. Tải toàn bộ lượt thuê ruộng còn hạn
        local rentalsResult = MySQL.query.await('SELECT * FROM farm_rentals WHERE is_active = 1 AND end_time > ?', { currentTime })
        FarmRentals = {}
        if rentalsResult then
            for _, rental in ipairs(rentalsResult) do
                local zId = tonumber(rental.zone_id) or rental.zone_id
                rental.id = tonumber(rental.id)
                rental.zone_id = zId
                rental.start_time = tonumber(rental.start_time)
                rental.end_time = tonumber(rental.end_time)
                rental.hours_rented = tonumber(rental.hours_rented)
                rental.price_paid = tonumber(rental.price_paid)
                rental.is_active = tonumber(rental.is_active) or 1
                
                FarmRentals[zId] = rental
            end
        end
        
        -- 3. Tải toàn bộ quyền chia sẻ ruộng
        local permsResult = MySQL.query.await([[
            SELECT fp.* FROM farm_permissions fp 
            JOIN farm_rentals fr ON fp.rental_id = fr.id 
            WHERE fr.is_active = 1 AND fr.end_time > ?
        ]], { currentTime })
        FarmPermissions = {}
        if permsResult then
            for _, perm in ipairs(permsResult) do
                local zId = tonumber(perm.zone_id) or perm.zone_id
                if not FarmPermissions[zId] then FarmPermissions[zId] = {} end
                FarmPermissions[zId][perm.shared_with] = {
                    id = tonumber(perm.id),
                    rental_id = tonumber(perm.rental_id),
                    zone_id = zId,
                    owner = perm.owner,
                    shared_with = perm.shared_with,
                    granted_at = tonumber(perm.granted_at)
                }
            end
        end
        
        -- 4. Tải toàn bộ chó bảo vệ còn hạn
        local dogResult = MySQL.query.await([[
            SELECT id, zone_id, renter_pid, UNIX_TIMESTAMP(expires_at) as expires_ts 
            FROM farm_dog_protection 
            WHERE expires_at > NOW()
        ]], {})
        DogProtections = {}
        if dogResult then
            for _, dp in ipairs(dogResult) do
                local zId = tonumber(dp.zone_id) or dp.zone_id
                DogProtections[zId] = {
                    id = tonumber(dp.id),
                    zone_id = zId,
                    renter_pid = dp.renter_pid,
                    expires_at = tonumber(dp.expires_ts) or (currentTime + 3600)
                }
            end
        end
        
        isDataLoaded = true
        print(string.format('^2[xn_farming]^7 Data cached successfully! Loaded %d plants, %d active rentals, %d dog protections.^0', 
            plantsResult and #plantsResult or 0, rentalsResult and #rentalsResult or 0, dogResult and #dogResult or 0))
    end)
end

-- Tự động chạy khi MySQL sẵn sàng
MySQL.ready(function()
    InitFarmingData()
end)
