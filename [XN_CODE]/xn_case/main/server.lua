local QBCore = exports['qb-core']:GetCoreObject()

local function DebugPrint(...)
    if Config and Config.EnableDebug then
        print(...)
    end
end

-- =====================================================
-- RATE LIMIT - Chống spam click case open
-- =====================================================
local LastCaseOpen = {} -- [source] = lastTimeMs
local CASE_OPEN_COOLDOWN_MS = 300 -- 300ms giữa 2 lần spin

-- Forward declarations cho gender system (handler dùng trước khi khai báo đầy đủ)
local PlayerPedGender  = {}  -- [source] = "male" | "female"
local _genderRateLimit = {}  -- [source] = lastTimerMs
local GENDER_RATE_MS   = 500 -- tối đa 1 lần sync gender mỗi 500ms / player

local function CheckCaseOpenRateLimit(source)
    local now = GetGameTimer()
    local last = LastCaseOpen[source] or 0
    if (now - last) < CASE_OPEN_COOLDOWN_MS then
        return false
    end
    LastCaseOpen[source] = now
    return true
end

-- =====================================================
-- PENDING REWARDS - Server lưu kết quả thắng để chống client gian lận
-- give event phải khớp với pending reward, nếu không sẽ bị từ chối
-- =====================================================
local PendingRewards = {} -- [source] = { wonItem1, wonItem2, ... }

-- Session tracking & claim locks cho OpenBox, CardBox và BagTypes (chống spam duplicate)
local PendingOpenBoxClaims = {} -- [source] = { items = wonItems, claimed = false, timestamp = ms }
local PendingCardBoxClaims = {} -- [source] = { items = wonItems, flippedCount = 0, claimed = false, timestamp = ms }
local PendingBagTickets    = {} -- [source] = { bagType = bagType, count = count, timestamp = ms }

local function SetPendingReward(source, wonItem)
    if type(wonItem) ~= 'table' then return end
    if not PendingRewards[source] then
        PendingRewards[source] = {}
    end
    if not wonItem.rewardId then
        wonItem.rewardId = tostring(os.time()) .. '_' .. tostring(math.random(100000, 999999))
    end
    table.insert(PendingRewards[source], wonItem)
    return wonItem.rewardId
end

local function ConsumePendingReward(source, requestedData)
    local queue = PendingRewards[source]
    if not queue or #queue == 0 then return nil end

    -- 1. Match bằng rewardId nếu client truyền rewardId
    if type(requestedData) == 'table' and requestedData.rewardId then
        for i, item in ipairs(queue) do
            if item.rewardId == requestedData.rewardId then
                local found = table.remove(queue, i)
                if #queue == 0 then PendingRewards[source] = nil end
                return found
            end
        end
    end

    -- 2. Match bằng item name nếu client truyền data.item
    if type(requestedData) == 'table' and requestedData.item then
        for i, item in ipairs(queue) do
            if item.item == requestedData.item then
                local found = table.remove(queue, i)
                if #queue == 0 then PendingRewards[source] = nil end
                return found
            end
        end
    end

    -- 3. Fallback FIFO: lấy phần thưởng đầu tiên trong hàng đợi
    local item = table.remove(queue, 1)
    if #queue == 0 then PendingRewards[source] = nil end
    return item
end

local AdminAddCoinSessions = {} -- [source] = { code = "...", time = os.time() }

AddEventHandler('playerDropped', function()
    local src = source
    LastCaseOpen[src] = nil
    PendingRewards[src] = nil
    PendingOpenBoxClaims[src] = nil
    PendingCardBoxClaims[src] = nil
    PendingBagTickets[src] = nil
    PlayerPedGender[src] = nil      -- xóa gender cache khi player ngắt kết nối
    _genderRateLimit[src] = nil     -- xóa rate limit cache
    AdminAddCoinSessions[src] = nil -- xóa session admin addcoin
end)

-- =====================================================
-- SERIAL GENERATION - Tạo số serial cho items từ gacha
-- =====================================================
local function GenerateText(len)
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local result = ''
    for i = 1, len do
        local idx = math.random(1, #charset)
        result = result .. charset:sub(idx, idx)
    end
    return result
end

local function GenerateSerial(text)
    if text and text:len() > 3 then
        return text
    end
    -- Format: GC + ngày tháng năm (DDMMYY) + 3 chữ cái ngẫu nhiên + giờ phút giây (HHMMSS)
    local dateStr = os.date("%d%m%y")  -- 230326
    local timeStr = os.date("%H%M%S")  -- 142530
    return ('%s%s%s%s'):format('GC', dateStr, text == nil and GenerateText(3) or text, timeStr)
end

-- =====================================================
-- PITY SYSTEM - Lưu số lần quay của mỗi player
-- =====================================================
local PlayerPityCounters = {}
-- Format: PlayerPityCounters[citizenid] = { rare = 0, epic = 0, legendary = 0, mythic = 0 }

local PlayerPityThresholds = {}
-- Format: PlayerPityThresholds[citizenid] = { rare = 5, epic = 15, legendary = 30, mythic = 60 }
-- Mỗi player có ngưỡng pity khác nhau (random từ config)

-- Hàm random ngưỡng pity cho player
local function RandomizePityThresholds(citizenid)
    if not PlayerPityThresholds[citizenid] then
        PlayerPityThresholds[citizenid] = {
            rare = math.random(Config.PitySystem.Rare.min, Config.PitySystem.Rare.max),
            epic = math.random(Config.PitySystem.Epic.min, Config.PitySystem.Epic.max),
            legendary = math.random(Config.PitySystem.Legendary.min, Config.PitySystem.Legendary.max),
            mythic = math.random(Config.PitySystem.Mythic.min, Config.PitySystem.Mythic.max)
        }
        -- print("🎲 Randomized Pity Thresholds for player:", citizenid, json.encode(PlayerPityThresholds[citizenid]))
    end
    return PlayerPityThresholds[citizenid]
end

-- Hàm lấy hoặc khởi tạo pity counter cho player
local function GetPityCounter(citizenid)
    if not PlayerPityCounters[citizenid] then
        PlayerPityCounters[citizenid] = {
            rare = 0,
            epic = 0,
            legendary = 0,
            mythic = 0
        }
        -- Đồng thời random ngưỡng pity cho player mới
        RandomizePityThresholds(citizenid)
    end
    return PlayerPityCounters[citizenid]
end

-- Hàm reset pity counter sau khi trúng rarity cao
local function ResetPityCounter(citizenid, rarity)
    local counter = GetPityCounter(citizenid)
    local rarityLower = string.lower(rarity)
    
    if rarityLower == "mythic" then
        -- Mythic reset tất cả
        counter.rare = 0
        counter.epic = 0
        counter.legendary = 0
        counter.mythic = 0
    elseif rarityLower == "legendary" then
        -- Legendary reset rare, epic, legendary
        counter.rare = 0
        counter.epic = 0
        counter.legendary = 0
    elseif rarityLower == "epic" then
        -- Epic reset rare, epic
        counter.rare = 0
        counter.epic = 0
    elseif rarityLower == "rare" then
        -- Rare chỉ reset rare
        counter.rare = 0
    end
end

-- Hàm tăng pity counter
local function IncrementPityCounter(citizenid)
    local counter = GetPityCounter(citizenid)
    counter.rare = counter.rare + 1
    counter.epic = counter.epic + 1
    counter.legendary = counter.legendary + 1
    counter.mythic = counter.mythic + 1
end

-- =====================================================
-- FORWARD DECLARATIONS - Bag/Card Pity System
-- Khai báo trước để cả card system (dòng ~1650) và bag system (dòng ~3000) đều dùng được
-- =====================================================
local PlayerBagPityCounters = {}
local PlayerBagPityThresholds = {}
local GetBagPityCounter, IncrementBagPityCounter, ResetBagPityCounter
local GetBagPityThreshold, ResetBagPityThreshold

-- =====================================================
-- SPECIAL ITEM PITY SYSTEM - Lưu RAM + sync DB mỗi 30 phút
-- Load từ DB khi player kết nối, save khi disconnect/restart
-- =====================================================
local PlayerSpecialItemPity = {}
-- Format: PlayerSpecialItemPity[citizenid][caseLabel] = { counter = 0, threshold = 50, dirty = false }

local PITY_SAVE_INTERVAL = 5 * 60 * 1000 -- 5 phút (ms) - batch save để giảm DB load

-- Tạo bảng DB nếu chưa có
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `es_case_special_pity` (
            `citizenid` varchar(50) NOT NULL,
            `case_label` varchar(100) NOT NULL,
            `counter` int(11) NOT NULL DEFAULT 0,
            `threshold` int(11) NOT NULL DEFAULT 50,
            PRIMARY KEY (`citizenid`, `case_label`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ]])
end)

-- Load pity data từ DB cho 1 player
local function LoadSpecialItemPityFromDB(citizenid)
    if not citizenid then return end
    local rows = exports.oxmysql:executeSync(
        'SELECT case_label, counter, threshold FROM es_case_special_pity WHERE citizenid = ?',
        { citizenid }
    )
    if rows and #rows > 0 then
        if not PlayerSpecialItemPity[citizenid] then
            PlayerSpecialItemPity[citizenid] = {}
        end
        for _, row in ipairs(rows) do
            PlayerSpecialItemPity[citizenid][row.case_label] = {
                counter = row.counter,
                threshold = row.threshold,
                dirty = false
            }
        end
    end
end

-- Save 1 entry cụ thể vào DB (async, không lag)
local function SaveOneSpecialItemPity(citizenid, caseLabel, counter, threshold)
    exports.oxmysql:execute(
        'INSERT INTO es_case_special_pity (citizenid, case_label, counter, threshold) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE counter = VALUES(counter), threshold = VALUES(threshold)',
        { citizenid, caseLabel, counter, threshold }
    )
end

-- Save tất cả dirty entries của 1 player vào DB
local function SaveSpecialItemPityToDB(citizenid)
    if not citizenid or not PlayerSpecialItemPity[citizenid] then return end
    for caseLabel, data in pairs(PlayerSpecialItemPity[citizenid]) do
        if data.dirty then
            SaveOneSpecialItemPity(citizenid, caseLabel, data.counter, data.threshold)
            data.dirty = false
        end
    end
end

-- Save tất cả players (dùng cho periodic save và resource stop)
local function SaveAllSpecialItemPity()
    for citizenid, _ in pairs(PlayerSpecialItemPity) do
        SaveSpecialItemPityToDB(citizenid)
    end
end

-- Lấy hoặc khởi tạo pity data cho special item của 1 hòm cụ thể
local function GetSpecialItemPity(citizenid, caseLabel, minPity, maxPity)
    if not PlayerSpecialItemPity[citizenid] then
        PlayerSpecialItemPity[citizenid] = {}
    end
    if not PlayerSpecialItemPity[citizenid][caseLabel] then
        -- Kiểm tra DB trước khi tạo mới (tránh reset counter khi server restart)
        local rows = exports.oxmysql:executeSync(
            'SELECT counter, threshold FROM es_case_special_pity WHERE citizenid = ? AND case_label = ?',
            { citizenid, caseLabel }
        )
        if rows and #rows > 0 then
            -- Khôi phục từ DB
            PlayerSpecialItemPity[citizenid][caseLabel] = {
                counter = rows[1].counter,
                threshold = rows[1].threshold,
                dirty = false
            }
        else
            -- Chưa có trong DB → tạo mới
            local min = tonumber(minPity) or tonumber(maxPity) or 100
            local max = tonumber(maxPity) or min
            if min > max then min, max = max, min end
            local newThreshold = math.random(min, max)
            PlayerSpecialItemPity[citizenid][caseLabel] = {
                counter = 0,
                threshold = newThreshold,
                dirty = false
            }
            -- Lưu DB ngay khi tạo entry mới
            SaveOneSpecialItemPity(citizenid, caseLabel, 0, newThreshold)
        end
    end
    return PlayerSpecialItemPity[citizenid][caseLabel]
end

-- Tăng special item pity counter (đánh dấu dirty, save bởi batch định kỳ / drop / stop)
local function IncrementSpecialItemPity(citizenid, caseLabel)
    if PlayerSpecialItemPity[citizenid] and PlayerSpecialItemPity[citizenid][caseLabel] then
        local data = PlayerSpecialItemPity[citizenid][caseLabel]
        data.counter = data.counter + 1
        data.dirty = true
    end
end

-- Reset special item pity counter (đánh dấu dirty, save bởi batch)
local function ResetSpecialItemPity(citizenid, caseLabel, minPity, maxPity)
    if not PlayerSpecialItemPity[citizenid] then
        PlayerSpecialItemPity[citizenid] = {}
    end
    local min = tonumber(minPity) or tonumber(maxPity) or 100
    local max = tonumber(maxPity) or min
    if min > max then min, max = max, min end
    local newThreshold = math.random(min, max)
    PlayerSpecialItemPity[citizenid][caseLabel] = {
        counter = 0,
        threshold = newThreshold,
        dirty = true
    }
end

-- Tạo special item result object để trả về cho client
local function BuildSpecialItemResult(specialItemConfig)
    local timestamp = os.time()
    local randomId = math.random(10000, 99999)
    return {
        item = specialItemConfig.item,
        label = specialItemConfig.label,
        count = specialItemConfig.count or 1,
        type = "item",
        DoHiem = "Legendary",
        isSpecialItem = true,
        imageurl = Config.OxInventoryImagePath .. specialItemConfig.item .. '.webp?t=' .. timestamp .. '&r=' .. randomId,
        imageFallback = Config.OxInventoryImagePath .. specialItemConfig.item .. '.webp'
    }
end

-- =====================================================
-- CHIBI ITEM PITY SYSTEM
-- =====================================================
local PlayerChibiItemPity = {}
-- Format: PlayerChibiItemPity[citizenid][caseLabel] = { counter = 0, threshold = 15, dirty = false }

-- Tạo bảng DB nếu chưa có
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `es_case_chibi_pity` (
            `citizenid` varchar(50) NOT NULL,
            `case_label` varchar(100) NOT NULL,
            `counter` int(11) NOT NULL DEFAULT 0,
            `threshold` int(11) NOT NULL DEFAULT 15,
            PRIMARY KEY (`citizenid`, `case_label`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ]])
end)

-- =====================================================
-- =====================================================
-- WON COUNTS SYSTEM FOR LIMITED ITEMS (max_slot) - GLOBAL/SERVER-WIDE
-- =====================================================
local GlobalWonCounts = {}

local function LoadGlobalWonCounts()
    GlobalWonCounts = {}
    local rows = exports.oxmysql:executeSync(
        'SELECT box_index, item_name, counter FROM es_case_global_won_counts'
    )
    if rows and #rows > 0 then
        for _, row in ipairs(rows) do
            local boxIdxStr = tostring(row.box_index)
            if boxIdxStr then
                if not GlobalWonCounts[boxIdxStr] then
                    GlobalWonCounts[boxIdxStr] = {}
                end
                GlobalWonCounts[boxIdxStr][row.item_name] = tonumber(row.counter) or 0
            end
        end
    end
end

CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `es_case_global_won_counts` (
            `box_index` int(11) NOT NULL,
            `item_name` varchar(100) NOT NULL,
            `counter` int(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (`box_index`, `item_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ]], {}, function()
        -- Chỉ load sau khi bảng đã được tạo xong
        LoadGlobalWonCounts()
    end)
end)

local function GetGlobalWonCount(boxIndex, itemName)
    if not boxIndex or not itemName then return 0 end
    local boxIdxStr = tostring(boxIndex)
    if not GlobalWonCounts[boxIdxStr] then
        GlobalWonCounts[boxIdxStr] = {}
    end
    return GlobalWonCounts[boxIdxStr][itemName] or 0
end

local function IncrementGlobalWonCount(boxIndex, itemName)
    if not boxIndex or not itemName then return end
    local boxIdxStr = tostring(boxIndex)
    if not GlobalWonCounts[boxIdxStr] then
        GlobalWonCounts[boxIdxStr] = {}
    end
    local current = GlobalWonCounts[boxIdxStr][itemName] or 0
    GlobalWonCounts[boxIdxStr][itemName] = current + 1
    
    exports.oxmysql:execute(
        'INSERT INTO es_case_global_won_counts (box_index, item_name, counter) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE counter = VALUES(counter)',
        { tonumber(boxIndex), itemName, current + 1 }
    )
end

local function IsBoxExpired(boxIndex, boxConfig)
    if not boxIndex or not boxConfig or not boxConfig.items then return false end
    for _, item in ipairs(boxConfig.items) do
        if item.max_slot and item.max_slot > 0 then
            local won = GetGlobalWonCount(boxIndex, item.item)
            if won >= item.max_slot then
                return true
            end
        end
    end
    return false
end

local function LoadChibiItemPityFromDB(citizenid)
    if not citizenid then return end
    local rows = exports.oxmysql:executeSync(
        'SELECT case_label, counter, threshold FROM es_case_chibi_pity WHERE citizenid = ?',
        { citizenid }
    )
    if rows and #rows > 0 then
        if not PlayerChibiItemPity[citizenid] then
            PlayerChibiItemPity[citizenid] = {}
        end
        for _, row in ipairs(rows) do
            PlayerChibiItemPity[citizenid][row.case_label] = {
                counter = row.counter,
                threshold = row.threshold,
                dirty = false
            }
        end
    end
end

local function SaveOneChibiItemPity(citizenid, caseLabel, counter, threshold)
    exports.oxmysql:execute(
        'INSERT INTO es_case_chibi_pity (citizenid, case_label, counter, threshold) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE counter = VALUES(counter), threshold = VALUES(threshold)',
        { citizenid, caseLabel, counter, threshold }
    )
end

local function SaveChibiItemPityToDB(citizenid)
    if not citizenid or not PlayerChibiItemPity[citizenid] then return end
    for caseLabel, data in pairs(PlayerChibiItemPity[citizenid]) do
        if data.dirty then
            SaveOneChibiItemPity(citizenid, caseLabel, data.counter, data.threshold)
            data.dirty = false
        end
    end
end

local function SaveAllChibiItemPity()
    for citizenid, _ in pairs(PlayerChibiItemPity) do
        SaveChibiItemPityToDB(citizenid)
    end
end

local function GetChibiItemPity(citizenid, caseLabel, minPity, maxPity)
    if not PlayerChibiItemPity[citizenid] then
        PlayerChibiItemPity[citizenid] = {}
    end
    if not PlayerChibiItemPity[citizenid][caseLabel] then
        local min = tonumber(minPity) or 10
        local max = tonumber(maxPity) or 20
        if min > max then min, max = max, min end
        local newThreshold = math.random(min, max)
        PlayerChibiItemPity[citizenid][caseLabel] = {
            counter = 0,
            threshold = newThreshold,
            dirty = true
        }
        SaveOneChibiItemPity(citizenid, caseLabel, 0, newThreshold)
    end
    return PlayerChibiItemPity[citizenid][caseLabel]
end

local function IncrementChibiItemPity(citizenid, caseLabel)
    if PlayerChibiItemPity[citizenid] and PlayerChibiItemPity[citizenid][caseLabel] then
        local data = PlayerChibiItemPity[citizenid][caseLabel]
        data.counter = data.counter + 1
        data.dirty = true
    end
end

local function ResetChibiItemPity(citizenid, caseLabel, minPity, maxPity)
    if not PlayerChibiItemPity[citizenid] then
        PlayerChibiItemPity[citizenid] = {}
    end
    local min = tonumber(minPity) or 10
    local max = tonumber(maxPity) or 20
    if min > max then min, max = max, min end
    local newThreshold = math.random(min, max)
    PlayerChibiItemPity[citizenid][caseLabel] = {
        counter = 0,
        threshold = newThreshold,
        dirty = true
    }
end

-- pedConfig: entry cụ thể từ ci.peds (có .metaped, .chance, .minPity, .maxPity, .DoHiem)
local function BuildChibiItemResult(chibiConfig, pedConfig)
    local resolvedMetaped = pedConfig and pedConfig.metaped or chibiConfig.metaped
    local resolvedLabel = (pedConfig and pedConfig.label) or chibiConfig.label or chibiConfig.item
    local imageUrl = 'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/' .. resolvedMetaped .. '.webp'
    return {
        item = chibiConfig.item,
        label = resolvedLabel,
        metaped = resolvedMetaped,
        count = chibiConfig.count or 1,
        type = "item",
        DoHiem = (pedConfig and pedConfig.DoHiem) or "Legendary",
        isChibiItem = true,
        imageurl = imageUrl,
        imageFallback = imageUrl
    }
end

-- =====================================================
-- AUTO SAVE - Lưu DB định kỳ mỗi 30 phút
-- =====================================================
CreateThread(function()
    while true do
        Wait(PITY_SAVE_INTERVAL)
        SaveAllSpecialItemPity()
        SaveAllChibiItemPity()
        DebugPrint('^2[ES-CASE]^7 Special Item & Chibi Item Pity data saved to database (periodic)')
    end
end)

-- Mapping source → citizenid (vì QBCore có thể xóa player data trước khi playerDropped fires)
local SourceToCitizenId = {}

-- Load pity data khi player kết nối
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        local citizenid = Player.PlayerData.citizenid
        SourceToCitizenId[src] = citizenid
        LoadSpecialItemPityFromDB(citizenid)
        LoadChibiItemPityFromDB(citizenid)
        DebugPrint('^2[ES-CASE]^7 Loaded Special Item & Chibi Item Pity for: ' .. citizenid)
    end
end)

-- Save + xóa RAM khi player ngắt kết nối
AddEventHandler('playerDropped', function()
    local src = source
    local citizenid = SourceToCitizenId[src]
    if citizenid then
        SaveSpecialItemPityToDB(citizenid)
        PlayerSpecialItemPity[citizenid] = nil
        SaveChibiItemPityToDB(citizenid)
        PlayerChibiItemPity[citizenid] = nil
        SourceToCitizenId[src] = nil
    end
end)

-- Load pity cho tất cả player đang online khi resource khởi động lại
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local players = GetPlayers()
        for _, src in ipairs(players) do
            local Player = QBCore.Functions.GetPlayer(tonumber(src))
            if Player and Player.PlayerData and Player.PlayerData.citizenid then
                local citizenid = Player.PlayerData.citizenid
                SourceToCitizenId[tonumber(src)] = citizenid
                LoadSpecialItemPityFromDB(citizenid)
                LoadChibiItemPityFromDB(citizenid)
            end
        end
        DebugPrint('^2[ES-CASE]^7 Loaded Special Item & Chibi Item Pity for all online players on resource start')
    end
end)

-- Save tất cả khi resource dừng
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SaveAllSpecialItemPity()
        SaveAllChibiItemPity()
        DebugPrint('^2[ES-CASE]^7 Special Item & Chibi Item Pity data saved to database (resource stop)')
    end
end)

local function GetPlayerLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "license:") then
            return identifier
        end
    end
    return nil
end

local function ExecuteSqlOptimized(query, params)
    local IsBusy = true
    local result = nil
    if Config.MySQL == "oxmysql" then
        exports.oxmysql:execute(query, params or {}, function(data)
            result = data
            IsBusy = false
        end)
    elseif Config.MySQL == "ghmattimysql" then
        exports.ghmattimysql:execute(query, params or {}, function(data)
            result = data
            IsBusy = false
        end)
    elseif Config.MySQL == "mysql-async" then   
        exports.oxmysql:execute(query, params or {}, function(data)
            result = data
            IsBusy = false
        end)
    end
    while IsBusy do
        Citizen.Wait(0)
    end
    return result
end

function GetPlayerCoin(source, cb)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        cb(0)
        return
    end

    local citizenid = player.PlayerData and player.PlayerData.citizenid
    if not citizenid then
        cb(0)
        return
    end

    exports.oxmysql:scalar('SELECT coin FROM players WHERE citizenid = ?', {citizenid}, function(coin)
        cb(tonumber(coin) or 0)
    end)
end

function RemovePlayerCoin(source, amount, cb)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then 
        if cb then cb(false) end
        return 
    end

    local citizenid = player.PlayerData and player.PlayerData.citizenid
    if not citizenid then 
        if cb then cb(false) end
        return 
    end

    GetPlayerCoin(source, function(currentCoin)
        local newCoin = math.max(0, currentCoin - amount) -- không âm

        exports.oxmysql:update('UPDATE players SET coin = ? WHERE citizenid = ?', {newCoin, citizenid}, function(affectedRows)
            if cb then cb(affectedRows > 0) end
        end)
    end)
end


function AddPlayerCoin(source, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData and player.PlayerData.citizenid
    if not citizenid then return end

    GetPlayerCoin(source, function(currentCoin)
        local newCoin = currentCoin + amount

        exports.oxmysql:update('UPDATE players SET coin = ? WHERE citizenid = ?', {newCoin, citizenid}, function(affectedRows)
            -- Coin added successfully
        end)
    end)
end

function AddPlayerCoinOffline(pidOrCitizenid, amount, cb)
    if not pidOrCitizenid or not amount or tonumber(amount) <= 0 then
        if cb then cb(false, "Tham số không hợp lệ") end
        return
    end

    amount = tonumber(amount)
    local target = tostring(pidOrCitizenid)
    local query = 'SELECT citizenid, pid, coin, charinfo, license, name FROM players WHERE pid = ? OR citizenid = ? LIMIT 1'
    exports.oxmysql:query(query, { target, target }, function(rows)
        if not rows or not rows[1] then
            if cb then cb(false, "Không tìm thấy người chơi với PID hoặc CitizenID này") end
            return
        end

        local playerData = rows[1]
        local citizenid = playerData.citizenid
        exports.oxmysql:update('UPDATE players SET coin = COALESCE(coin, 0) + ? WHERE citizenid = ?', { amount, citizenid }, function(affectedRows)
            if cb then cb(affectedRows and affectedRows > 0, playerData) end
        end)
    end)
end

-- =====================================================
-- INVENTORY FULL CONFIRMATION - Xác nhận khi kho đầy
-- =====================================================
local PlayerSkipFullInvConfirm = {}
-- Format: PlayerSkipFullInvConfirm[citizenid] = os.time() + 300 (skip đến thời điểm nào)

-- Kiểm tra inventory có slot trống không (ngoài slot 6-21 quần áo)
local function IsInventoryFull(playerId)
    local inventory = exports.ox_inventory:GetInventory(playerId)
    local maxSlots = inventory and inventory.slots or 50
    local playerItems = inventory and exports.ox_inventory:GetInventoryItems(playerId)
    local occupiedSlots = {}

    if playerItems then
        for _, item in pairs(playerItems) do
            if item and item.slot then
                occupiedSlots[item.slot] = true
            end
        end
    end

    -- Kiểm tra có slot trống ngoài slot 6-21 không
    for i = 1, maxSlots do
        if not (i >= 6 and i <= 21) and not occupiedSlots[i] then
            return false -- Có slot trống
        end
    end
    return true -- Tất cả slot đều đầy
end

-- Kiểm tra inventory đầy và hỏi player xác nhận
-- Trả về: true = tiếp tục (gửi về bưu cục), false = hủy
local function CheckInventoryFullAndConfirm(source)
    -- Kiểm tra inventory có đầy không
    if not IsInventoryFull(source) then
        return true -- Inventory còn chỗ, tiếp tục bình thường
    end

    -- Inventory đầy, kiểm tra skip
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local citizenid = Player.PlayerData.citizenid

    local skipUntil = PlayerSkipFullInvConfirm[citizenid]
    if skipUntil and os.time() < skipUntil then
        return true -- Đã chọn "không hỏi lại trong 5 phút", tự động tiếp tục
    end

    -- Hỏi player qua NUI popup
    local result = lib.callback.await('es-case:confirmInventoryFull', source)
    
    if result and result.confirmed then
        -- Player đồng ý tiếp tục
        if result.skipFor5Min then
            PlayerSkipFullInvConfirm[citizenid] = os.time() + 300 -- 5 phút
        end
        return true
    end
    
    return false -- Player hủy
end

-- Tìm slot trống trong inventory, loại trừ slot 6-21 (dành cho quần áo)
local function FindAvailableSlotExcluding(playerId, excludeFrom, excludeTo)
    local inventory = exports.ox_inventory:GetInventory(playerId)
    local maxSlots = inventory and inventory.slots or 50
    local playerItems = inventory and exports.ox_inventory:GetInventoryItems(playerId)
    local occupiedSlots = {}

    if playerItems then
        for _, item in pairs(playerItems) do
            if item and item.slot then
                occupiedSlots[item.slot] = true
            end
        end
    end

    for i = 1, maxSlots do
        if not (i >= excludeFrom and i <= excludeTo) and not occupiedSlots[i] then
            return i
        end
    end
    return nil
end

function AddItemReworks(playerid, give)
    local Player = QBCore.Functions.GetPlayer(playerid)
    if not Player then return end
    
    local Item_Name = give.item
    local count = give.count or 1  -- Sử dụng count từ config, mặc định = 1
    
    -- DEBUG: Log count để kiểm tra
    ----print("=== DEBUG AddItemReworks ===")
    ----print("Item:", Item_Name)
    ----print("Count from give.count:", give.count)
    ----print("Final count used:", count)
    ----print("Type:", give.type)
    ----print("=============================")
    local Config_item = Config.Items[Item_Name]
    if Config_item then
        -- Create imageUrl based on prop setting với force check item name
        local imageUrl = give.imageurl
        if not imageUrl then
            -- Force correct prop detection by item name
            local isPropItem = false
            if Item_Name == "cloth_glasses" or Item_Name == "cloth_helmet" or Item_Name == "cloth_ears" then
                isPropItem = true
            elseif Item_Name == "cloth_mask" or Item_Name == "cloth_tshirt" or Item_Name == "cloth_torso" then
                isPropItem = false
            else
                -- Fallback to Config_item.prop for other items
                isPropItem = Config_item.prop or false
            end
            
            if isPropItem then
                if Config.PropFormat == 1 then
                    -- Format: male_1_1_prop.webp
                    imageUrl = string.format("%s/%s_%s_%s_prop.%s", 
                        Config.Url, give.sex, give.component or Config_item.component, give.drawable or 0, Config.Extension)
                else
                    -- Format: male_prop_1_1.webp
                    imageUrl = string.format("%s/%s_prop_%s_%s.%s", 
                        Config.Url, give.sex, give.component or Config_item.component, give.drawable or 0, Config.Extension)
                end
            else
                imageUrl = string.format("%s/%s_%s_%s.%s", 
                    Config.Url, give.sex, give.component or Config_item.component, give.drawable or 0, Config.Extension)
            end
        end
        local label_sex = give.sex == "male" and "Nam" or "Nữ"
        ------print("=== ADDING ITEM TO INVENTORY ===")
        ------print("Item:", Item_Name)
        ------print("Using imageurl from data:", give.imageurl)
        ------print("Final imageUrl:", imageUrl)
        ------print("DoHiem:", give.DoHiem)
        
        local Metadata = {
            type = give.type,           
            component = give.component or Config_item.component,
            sex = give.sex or "male",
            drawable = give.drawable or 0,
            label = give.label or (Config_item.label .. " #" .. (give.drawable or 0).." ("..label_sex..")"),
            DoHiem = give.DoHiem or nil,
            imageurl = imageUrl,
            prop = Config_item.prop or false, -- Thêm thông tin prop vào metadata
            serial = GenerateSerial(),        -- ✅ Số serial cho item
            fromGacha = true,                 -- ✅ Đánh dấu item từ gacha
            gachaTimestamp = os.time()        -- ✅ Thời điểm quay gacha
        }
        ------print("Final Metadata:", json.encode(Metadata))
        
        -- Hiển thị thông báo độ hiếm TRƯỚC KHI thêm vào inventory (để luôn hiển thị dù kho có đầy)
        if give.DoHiem == 'Rare' or give.DoHiem == 'Epic' or give.DoHiem == 'Legendary' then
            local announceMsg = 'Chúc mừng '.. Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname..' đã quay được '..give.label..' độ hiếm '..give.DoHiem..''
            if give.DoHiem == 'Legendary' then
                -- SendSpecialAnnouncementToAll(title, message, duration, logo) -- không có tham số type
                exports['xn_thongbao']:SendSpecialAnnouncementToAll('GACHA', announceMsg, 20000, imageUrl)
            else
                -- SendAnnouncementToAll(title, message, duration, type, logo)
                exports['xn_thongbao']:SendAnnouncementToAll('GACHA', announceMsg, 20000, 'warning', imageUrl)
            end
        end
        
        -- Thử thêm item vào inventory, nếu không thành công (kho đầy) thì gửi về kho lưu trữ
        -- Quần áo: loại trừ slot 6-21
        local targetSlot = FindAvailableSlotExcluding(playerid, 6, 21)
        local success = false
        if targetSlot then
            success = exports.ox_inventory:AddItem(playerid, Item_Name, count, Metadata, targetSlot)
        end
        
        local boxName = give.caseLabel or give.caseName or "Gacha"
        local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        local pid = Player.PlayerData.pid
        local itemLabel = give.label or Item_Name

        if not success then
            -- Kho đồ đầy, gửi vật phẩm về kho lưu trữ cá nhân
            local citizenid = Player.PlayerData.citizenid
            if citizenid and exports.xn_buucuc then
                local storageSuccess = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, Item_Name, count, Metadata)
                if storageSuccess then
                    TriggerClientEvent('QBCore:Notify', playerid, 'Kho đồ đã đầy! Vật phẩm ' .. itemLabel .. ' đã được gửi về kho lưu trữ cá nhân.', 'warning')
                    lib.logger(playerid, 'Shop_donate', {
                        message = string.format("Người chơi %s | %s nhận được %dx %s từ hòm [%s] (Gửi về Bưu Cục do kho đồ đầy)", playerName, pid, count, itemLabel, boxName),
                        item = Item_Name, amount = count, box_name = boxName, type = 'item', source = 'gacha_buucuc'
                    })
                else
                    -- Bưu cục cũng đầy - hiển thị popup cảnh báo đỏ
                    TriggerClientEvent('es-case:storageFullWarning', playerid, itemLabel)
                    TriggerClientEvent('QBCore:Notify', playerid, 'Kho đồ VÀ bưu cục đều đầy! Vật phẩm ' .. itemLabel .. ' đã bị mất!', 'error')
                    lib.logger(playerid, 'Shop_donate', {
                        message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ hòm [%s] do kho đồ và bưu cục đều đầy", playerName, pid, count, itemLabel, boxName),
                        item = Item_Name, amount = count, box_name = boxName, type = 'item', source = 'gacha_lost_item'
                    })
                end
            else
                -- Bưu cục không khả dụng - hiển thị popup cảnh báo đỏ
                TriggerClientEvent('es-case:storageFullWarning', playerid, itemLabel)
                TriggerClientEvent('QBCore:Notify', playerid, 'Kho đồ đầy và không thể gửi về kho lưu trữ! Vui lòng dọn dẹp kho đồ.', 'error')
                lib.logger(playerid, 'Shop_donate', {
                    message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ hòm [%s] do kho đồ đầy (Bưu cục không khả dụng)", playerName, pid, count, itemLabel, boxName),
                    item = Item_Name, amount = count, box_name = boxName, type = 'item', source = 'gacha_lost_item'
                })
            end
        else
            lib.logger(playerid, 'Shop_donate', {
                message = string.format("Người chơi %s | %s nhận được %dx %s từ hòm [%s]", playerName, pid, count, itemLabel, boxName),
                item = Item_Name, amount = count, box_name = boxName, type = 'item', source = 'gacha'
            })
        end
    else
        ------print('^1[ES-CASE]^7 Item not found in Config.Items: ' .. Item_Name)
    end
end

QBCore.Functions.CreateCallback('GetSell', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false, 0) end
    if data.rewards.item and data.rewards.item ~= '' then 
        AddPlayerCoin(source, data.rewards.sell)
        cb(true, UpSell)
    else
        cb(false, profile[1].gold)
    end
end)

-- =====================================================
-- GENDER HELPERS - Dùng bởi tất cả hệ thống gacha/case/bag/card
-- =====================================================

-- Lấy giới tính thực của player từ charinfo
-- QBCore: charinfo.gender = 0 (male) hoặc 1 (female)
local function GetPlayerRealGender(playerData)
    if playerData and playerData.charinfo then
        local g = playerData.charinfo.gender
        if g == 0 or g == "male" then return "male"
        elseif g == 1 or g == "female" then return "female"
        end
    end
    return nil -- không xác định được
end

-- Chọn giới tính có trọng số
-- Nếu item chỉ có 1 giới → trả về giới đó
-- Nếu item có cả 2 giới → 70% đúng giới player, 30% khác giới
local function WeightedGenderSelect(realGender, hasOtherGender)
    if not realGender then
        -- Không biết giới tính thực → random 50/50
        return math.random(1, 2) == 1 and "male" or "female"
    end
    local otherGender = realGender == "male" and "female" or "male"
    if not hasOtherGender then
        -- Item chỉ có giới tính kia → bắt buộc dùng giới tính đó
        return otherGender
    end
    -- Cả 2 giới đều có → 70% đúng giới, 30% khác giới
    return math.random(1, 100) <= 70 and realGender or otherGender
end

QBCore.Functions.CreateCallback('Case', function(source, cb, data)
    -- Rate limit: chống spam click
    if not CheckCaseOpenRateLimit(source) then
        return cb({check = false, reason = "rate_limited"})
    end
    -- Validate input shape (chống client gửi data lạ)
    if type(data) ~= 'table' or type(data.case) ~= 'table' then
        return cb({check = false, reason = "invalid_input"})
    end
    if type(data.case.label) ~= 'string' then
        return cb({check = false, reason = "invalid_input"})
    end
    -- key_required có thể nil (hòm dùng coin/bank), nhưng nếu có phải là string
    if data.case.key_required ~= nil and type(data.case.key_required) ~= 'string' then
        return cb({check = false, reason = "invalid_input"})
    end
    ------print("=== REGULAR OPEN CALLBACK CALLED ===")
    ------print("Source:", source)
    ------print("Data:", json.encode(data))
    ------print("Data.case.category:", data.case and data.case.category or "nil")
    ------print("Data.case.key_required:", data.case and data.case.key_required or "nil")
    ------print("🚨 RECEIVED KEY_REQUIRED FROM FRONTEND:", data.case and data.case.key_required or "nil")
    ------print("🚨 FULL DATA.CASE:", json.encode(data.case or {}))
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        ------print("REGULAR OPEN - Player not found")
        return cb({success = false, reason = "player_not_found"}) 
    end
    
    -- Kiểm tra inventory đầy và hỏi xác nhận
    if not CheckInventoryFullAndConfirm(source) then
        return cb({success = false, reason = "cancelled"})
    end
    
    -- Reload config to ensure latest values
    if GetResourceMetadata(GetCurrentResourceName(), 'server_script', 1) then
        -- Force reload shared.lua config
    end
    
    -- Lấy thông tin từ config dựa vào key_required
    local keyRequired = data.case.key_required
    local price = 0
    local caseConfig = nil
    
    ------print("SEARCHING for key:", keyRequired)
    
    -- Tìm case config dựa vào key_required và label để tránh conflict
    ------print("DEBUG: Config.Live có", #Config.Live, "cases")
    ----print("🔍 CASE OPEN - SEARCHING for key:", keyRequired, "label:", data.case.label)
    
    for i, case in ipairs(Config.Live) do
        ------print("DEBUG Case", i, ":", json.encode({
        --     key_required = case.key_required,
        --     price = case.price,
        --     price_type = type(case.price),
        --     category = case.category,
        --     label = case.label
        -- }))
        
        -- Match cả key_required VÀ label để tránh conflict khi có nhiều hòm cùng key
        if case.key_required == keyRequired and case.label == data.case.label then
            caseConfig = case
            price = tonumber(case.price) or 0
            ----print("✅ EXACT MATCH FOUND:")
           -- --print("  - Label:", case.label)
            ----print("  - Key Required:", case.key_required)
            ----print("  - Category:", case.category)
            ----print("  - Price:", price)
            ----print("  - Items Count:", #case.items)
            if #case.items > 0 then
                ----print("  - First Item:", case.items[1].item)
            end
            break
        end
    end
    
    -- Fallback: nếu không tìm thấy exact match, tìm theo key_required thôi (backward compatibility)
    if not caseConfig then
        ------print("EXACT MATCH NOT FOUND, trying key-only match...")
        for i, case in ipairs(Config.Live) do
            if case.key_required == keyRequired then
                caseConfig = case
                price = tonumber(case.price) or 0
                ----print("⚠️ FALLBACK CASE CONFIG SELECTED:")
                ----print("  - Label:", case.label)
                ----print("  - Key Required:", case.key_required)
                break
            end
        end
    end
    
    if not caseConfig then
        ------print("CASE NOT FOUND for key:", keyRequired) -- Debug tạm
        return cb({success = false, reason = "case_not_found"})
    end
    
    -- Kiểm tra hòm đã hết hạn chưa (endTime format: "HH:MM:SS DD-MM-YYYY")
    if caseConfig.endTime then
        local h, m, s, d, mo, y = caseConfig.endTime:match("(%d+):(%d+):(%d+)%s+(%d+)-(%d+)-(%d+)")
        if h and d then
            local endTimestamp = os.time({year=tonumber(y), month=tonumber(mo), day=tonumber(d), hour=tonumber(h), min=tonumber(m), sec=tonumber(s)})
            if os.time() >= endTimestamp then
                return cb({success = false, reason = "case_expired"})
            end
        end
    end
    
    -- Kiểm tra chìa khóa cần thiết
    if keyRequired then
        local hasKey = Player.Functions.GetItemByName(keyRequired)
        if not hasKey or hasKey.amount < 1 then
            return cb({success = false, reason = "no_key"})
        end
    end
    
    -- Function to randomly select item based on DoHiem rates
    local function getRandomItem(caseItems)
        -- CHIỆN DÙNG Config.RarityRates từ config2.lua
        local rarityRates = Config.RarityRates
        
        -- Lấy citizenid để check pity system
        local player = QBCore.Functions.GetPlayer(source)
        local citizenid = player and player.PlayerData and player.PlayerData.citizenid
        
        -- Lấy giới tính thực của player (dùng 70/30 weighted khi có cả 2 giới)
        local playerRealGender = player and GetPlayerRealGender(player.PlayerData) or nil
        
        -- =====================================================
        -- SPECIAL ITEM CHECK - Kiểm tra item đặc biệt trước
        -- Ưu tiên: Pity → Tỉ lệ cứng → Roll clothing thường
        -- =====================================================
        if caseConfig.specialItem and citizenid then
            local si = caseConfig.specialItem
            local pityData = GetSpecialItemPity(citizenid, caseConfig.label, si.minPity, si.maxPity)
            
            -- Check 1: Pity - đã quay đủ số lần → ĐẢM BẢO ra special item
            if pityData.counter >= pityData.threshold then
                return BuildSpecialItemResult(si)
            end
            
            -- Check 2: Tỉ lệ cứng - random mỗi lần quay
            local rand = math.random() * 100
            if rand <= (si.chance or 0.1) then
                return BuildSpecialItemResult(si)
            end
        end

        -- =====================================================
        -- CHIBI ITEM CHECK - Kiểm tra từng ped riêng (chance + pity độc lập)
        -- Ưu tiên: Pity → Tỉ lệ cứng → Roll clothing thường
        -- =====================================================
        if caseConfig.Chibi_item and caseConfig.Chibi_item.peds and citizenid then
            local ci = caseConfig.Chibi_item
            for _, pedConfig in ipairs(ci.peds) do
                local pityKey = caseConfig.label .. '_chibi_' .. pedConfig.metaped
                local chibiPityData = GetChibiItemPity(citizenid, pityKey, pedConfig.minPity, pedConfig.maxPity)

                -- Check 1: Pity - đã quay đủ số lần → ĐẢM BẢO ra chibi này
                if chibiPityData.counter >= chibiPityData.threshold then
                    return BuildChibiItemResult(ci, pedConfig)
                end

                -- Check 2: Tỉ lệ cứng - random mỗi lần quay
                local chibiRand = math.random() * 100
                if chibiRand <= (pedConfig.chance or 0.1) then
                    return BuildChibiItemResult(ci, pedConfig)
                end
            end
        end
        
        -- =====================================================
        -- BUILD AVAILABLE ITEMS TRƯỚC - để check rarity nào có available
        -- =====================================================
        local allItems = {}
        for _, item in ipairs(caseItems) do
            if not item.no_add then
                if item.type == "clothing" and item.DoHiem then
                    -- Xác định giới tính có trọng số cho từng item
                    local hasMale = item.DoHiem["male"] ~= nil
                    local hasFemale = item.DoHiem["female"] ~= nil
                    local itemGender
                    if hasMale and hasFemale then
                        itemGender = WeightedGenderSelect(playerRealGender, true)
                    elseif hasMale then
                        itemGender = "male"
                    elseif hasFemale then
                        itemGender = "female"
                    else
                        itemGender = playerRealGender or "male"
                    end

                    if item.DoHiem[itemGender] then
                    for rarityLevel, drawableList in pairs(item.DoHiem[itemGender]) do
                        for _, d in ipairs(drawableList) do
                            local newItem = {}
                            for k, v in pairs(item) do
                                newItem[k] = v
                            end
                            newItem.drawable = d
                            newItem.sex = itemGender
                            newItem.DoHiem = rarityLevel
                            
                            -- Create label and imageurl
                            local base = Config.Items and Config.Items[newItem.item]
                            if base then
                                newItem.label = Config.FormatClothingLabel(newItem.item, itemGender, d)
                                newItem.component = newItem.component or base.component
                                newItem.clothesSlotID = newItem.clothesSlotID or base.clothesSlotID
                                newItem.prop = base.prop
                            else
                                newItem.label = Config.FormatClothingLabel(newItem.item, itemGender, d)
                                newItem.prop = false
                            end
                            
                            -- Add imageurl for clothing items
                            local isPropItem = false
                            if newItem.item == "cloth_glasses" or newItem.item == "cloth_helmet" or newItem.item == "cloth_ears" then
                                isPropItem = true
                            elseif newItem.item == "cloth_mask" or newItem.item == "cloth_tshirt" or newItem.item == "cloth_torso" then
                                isPropItem = false
                            else
                                isPropItem = base and base.prop or false
                            end
                            
                            if isPropItem then
                                if Config.PropFormat == 1 then
                                    newItem.imageurl = string.format("%s/%s_%s_%s_prop.%s", 
                                        Config.Url, itemGender, newItem.component or base.component, d, Config.Extension)
                                else
                                    newItem.imageurl = string.format("%s/%s_prop_%s_%s.%s", 
                                        Config.Url, itemGender, newItem.component or base.component, d, Config.Extension)
                                end
                            else
                                newItem.imageurl = string.format("%s/%s_%s_%s.%s", 
                                    Config.Url, itemGender, newItem.component or base.component, d, Config.Extension)
                            end
                            
                            table.insert(allItems, newItem)
                        end
                    end
                    end
                elseif item.group_items then
                    for _, subItem in ipairs(item.group_items) do
                        local newItem = {}
                        for k, v in pairs(item) do
                            newItem[k] = v
                        end
                        newItem.item = subItem
                        newItem.label = item.group_labels and item.group_labels[subItem] or subItem
                        newItem.rarity = item.group_rarities and item.group_rarities[subItem] or item.rarity
                        newItem.DoHiem = newItem.rarity
                        newItem.uniqueId = newItem.item .. "_" .. (newItem.count or 1) .. "_" .. (newItem.DoHiem or "common")
                        
                        if newItem.type == "item" then
                            local timestamp = os.time()
                            local randomId = math.random(10000, 99999)
                            newItem.imageurl = Config.OxInventoryImagePath .. newItem.item .. '.webp?t=' .. timestamp .. '&r=' .. randomId
                            newItem.imageFallback = Config.OxInventoryImagePath .. newItem.item .. '.webp'
                        else
                            newItem.imageurl = 'https://raw.githubusercontent.com/QuocHuyCrow/imagestellacity/main/Items_KhoDo/' .. newItem.item .. '.webp'
                        end
                        
                        table.insert(allItems, newItem)
                    end
                else
                    local newItem = {}
                    for k, v in pairs(item) do
                        newItem[k] = v
                    end
                    if not newItem.label then
                        local base = Config.Items and Config.Items[newItem.item]
                        if base then
                            newItem.label = base.label
                        else
                            newItem.label = newItem.item
                        end
                    end
                    
                    newItem.uniqueId = newItem.item .. "_" .. (newItem.count or 1) .. "_" .. (newItem.DoHiem or "common")
                    
                    if newItem.type == "item" then
                        local timestamp = os.time()
                        local randomId = math.random(10000, 99999)
                        newItem.imageurl = Config.OxInventoryImagePath .. newItem.item .. '.webp?t=' .. timestamp .. '&r=' .. randomId
                        newItem.imageFallback = Config.OxInventoryImagePath .. newItem.item .. '.webp'
                    else
                        newItem.imageurl = 'https://raw.githubusercontent.com/QuocHuyCrow/imagestellacity/main/Items_KhoDo/' .. newItem.item .. '.webp'
                    end
                    
                    table.insert(allItems, newItem)
                end
            end
        end
        
        -- =====================================================
        -- CHECK AVAILABLE RARITIES - Xem hòm có rarity nào
        -- =====================================================
        local availableRarities = {}
        for _, item in ipairs(allItems) do
            if item.DoHiem then
                availableRarities[item.DoHiem] = true
            end
        end
        
        local function rollRarity()
            -- =====================================================
            -- PITY SYSTEM - Kiểm tra số lần quay với FALLBACK
            -- Return: {pityTier, actualRarity}
            -- - pityTier: Tier đã trigger pity (nil nếu không trigger)
            -- - actualRarity: Rarity thực sự nhận được
            -- =====================================================
            if Config.EnablePitySystem and citizenid then
                local counter = GetPityCounter(citizenid)
                local thresholds = RandomizePityThresholds(citizenid)
                
                -- Kiểm tra pity theo thứ tự từ cao xuống thấp
                -- Nếu hòm không có rarity đó → Fallback xuống tier thấp hơn
                if counter.mythic >= thresholds.mythic then
                    if availableRarities["Mythic"] then
                        --print("🎁 PITY - MYTHIC - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Mythic"}
                    elseif availableRarities["Legendary"] then
                        --print("🎁 PITY FALLBACK - Mythic→Legendary - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Legendary"}
                    elseif availableRarities["Epic"] then
                        --print("🎁 PITY FALLBACK - Mythic→Epic - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Epic"}
                    elseif availableRarities["Rare"] then
                        --print("🎁 PITY FALLBACK - Mythic→Rare - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Rare"}
                    end
                end
                
                if counter.legendary >= thresholds.legendary then
                    if availableRarities["Legendary"] then
                        --print("🎁 PITY - LEGENDARY - Counter:", counter.legendary .. "/" .. thresholds.legendary)
                        return {"Legendary", "Legendary"}
                    elseif availableRarities["Epic"] then
                        --print("🎁 PITY FALLBACK - Legendary→Epic - Counter:", counter.legendary .. "/" .. thresholds.legendary)
                        return {"Legendary", "Epic"}
                    elseif availableRarities["Rare"] then
                        --print("🎁 PITY FALLBACK - Legendary→Rare - Counter:", counter.legendary .. "/" .. thresholds.legendary)
                        return {"Legendary", "Rare"}
                    end
                end
                
                if counter.epic >= thresholds.epic then
                    if availableRarities["Epic"] then
                        --print("🎁 PITY - EPIC - Counter:", counter.epic .. "/" .. thresholds.epic)
                        return {"Epic", "Epic"}
                    elseif availableRarities["Rare"] then
                        --print("🎁 PITY FALLBACK - Epic→Rare - Counter:", counter.epic .. "/" .. thresholds.epic)
                        return {"Epic", "Rare"}
                    end
                end
                
                if counter.rare >= thresholds.rare then
                    if availableRarities["Rare"] then
                        --print("🎁 PITY - RARE - Counter:", counter.rare .. "/" .. thresholds.rare)
                        return {"Rare", "Rare"}
                    end
                    -- Nếu không có Rare → Bỏ qua pity, random normal
                    --print("⚠️ PITY SKIPPED - No Rare items in this case")
                end
            end
            
            -- =====================================================
            -- RANDOM NORMAL - Nếu chưa đạt pity
            -- =====================================================
            local rand = math.random() * 100
            local cumulative = 0
            local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
            
            for _, rarity in ipairs(rarityOrder) do
                local rate = rarityRates[rarity]
                if rate and availableRarities[rarity] then  -- CHỈ CHECK RARITY CÓ TRONG HÒM
                    cumulative = cumulative + rate
                    if rand <= cumulative then
                        return {nil, rarity}  -- Không trigger pity
                    end
                end
            end
            
            -- Fallback to any available rarity
            for _, rarity in ipairs({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
                if availableRarities[rarity] then
                    return {nil, rarity}  -- Không trigger pity
                end
            end
            
            return {nil, "Common"}  -- Không trigger pity
        end
        
        -- Get items with DoHiem
        local withRarity = {}
        local noRarity = {}
        for _, item in ipairs(allItems) do
            if item.DoHiem then
                table.insert(withRarity, item)
            else
                table.insert(noRarity, item)
            end
        end
        
        if #withRarity > 0 then
            local maxRetries = 10  -- Tối đa 10 lần retry để tránh infinite loop
            local attempts = 0
            
            while attempts < maxRetries do
                local result = rollRarity()
                local pityTier = result[1]
                local rarity = result[2]
                ------print("🎲 ROLLED RARITY (attempt", attempts + 1, "):", rarity)
                local pool = {}
                for _, item in ipairs(withRarity) do
                    if item.DoHiem == rarity then
                        table.insert(pool, item)
                    end
                end
                ------print("🎲 POOL SIZE for", rarity, ":", #pool)
                
                if #pool > 0 then
                    local selectedItem = pool[math.random(1, #pool)]
                    selectedItem.pityTier = pityTier  -- Lưu pityTier vào item để reset sau
                    ------print("🎯 SELECTED ITEM:", selectedItem.item, "drawable:", selectedItem.drawable, "rarity:", rarity)
                    return selectedItem
                else
                    ------print("🔄 No items available for", rarity, "- retrying...")
                    attempts = attempts + 1
                end
            end
            
            ------print("⚠️ Max retries reached, falling back to Common items")
            -- Fallback to Common items only
            local commonPool = {}
            for _, item in ipairs(withRarity) do
                if item.DoHiem == "Common" then
                    table.insert(commonPool, item)
                end
            end
            if #commonPool > 0 then
                local selectedItem = commonPool[math.random(1, #commonPool)]
                ------print("🎯 COMMON FALLBACK SELECTED:", selectedItem.item, "drawable:", selectedItem.drawable)
                return selectedItem
            end
        end
        
        -- Fallback to items without rarity
        ------print("🔄 FALLBACK: Using items without rarity, count:", #noRarity)
        if #noRarity > 0 then
            local selectedItem = noRarity[math.random(1, #noRarity)]
            ------print("🎯 FALLBACK SELECTED:", selectedItem.item)
            return selectedItem
        end
        
        -- Final fallback
        ------print("🔄 FINAL FALLBACK: Using all items, count:", #allItems)
        if #allItems > 0 then
            local selectedItem = allItems[math.random(1, #allItems)]
            ------print("🎯 FINAL FALLBACK SELECTED:", selectedItem.item)
            return selectedItem
        end
        
        return nil
    end
    
    -- Random an item to win
    local wonItem = getRandomItem(caseConfig.items)
    ------print("=== SERVER RANDOM ITEM RESULT ===")
    ------print("wonItem exists:", wonItem ~= nil)
    
    if not wonItem then
        return cb({success = false, reason = "no_items_available"})
    end
    
    -- =====================================================
    -- PITY SYSTEM - Cập nhật counter sau khi quay
    -- =====================================================
    local citizenid = Player.PlayerData and Player.PlayerData.citizenid
    if Config.EnablePitySystem and citizenid then
        local wonRarity = wonItem.DoHiem or "Common"
        local pityTier = wonItem.pityTier  -- Tier đã trigger pity (nil nếu random normal)
        
        -- Reset counter: Reset cả pityTier (nếu có) và wonRarity
        if pityTier then
            ResetPityCounter(citizenid, pityTier)  -- Reset tier trigger pity
            if pityTier ~= wonRarity then
                ResetPityCounter(citizenid, wonRarity)  -- Reset cả tier nhận được (nếu khác)
            end
        else
            ResetPityCounter(citizenid, wonRarity)  -- Reset normal
        end
        
        -- Tăng counter cho lần quay tiếp theo
        IncrementPityCounter(citizenid)
        
        --print("📊 Pity Counter - Player:", Player.PlayerData.charinfo.firstname, 
            --   "Won:", wonRarity,
            --   pityTier and (" (Pity: " .. pityTier .. ")") or "",
            --   "Counters:", json.encode(GetPityCounter(citizenid)))
    end
    
    -- =====================================================
    -- SPECIAL ITEM PITY - Cập nhật counter sau khi quay
    -- =====================================================
    if caseConfig.specialItem and citizenid then
        local si = caseConfig.specialItem
        if wonItem.isSpecialItem then
            -- Trúng special item → reset counter và random ngưỡng mới
            ResetSpecialItemPity(citizenid, caseConfig.label, si.minPity, si.maxPity)
        else
            -- Không trúng → tăng counter
            IncrementSpecialItemPity(citizenid, caseConfig.label)
        end
    end

    -- =====================================================
    -- CHIBI ITEM PITY - Cập nhật counter sau khi quay (per-ped)
    -- =====================================================
    if caseConfig.Chibi_item and caseConfig.Chibi_item.peds and citizenid then
        local ci = caseConfig.Chibi_item
        for _, pedConfig in ipairs(ci.peds) do
            local pityKey = caseConfig.label .. '_chibi_' .. pedConfig.metaped
            if wonItem.isChibiItem then
                -- Trúng bất kỳ chibi nào → reset pity của TẤT CẢ ped trong hòm
                ResetChibiItemPity(citizenid, pityKey, pedConfig.minPity, pedConfig.maxPity)
            else
                -- Không trúng → tăng counter của ped này
                IncrementChibiItemPity(citizenid, pityKey)
            end
        end
    end
    
    -- Kiểm tra category để quyết định sử dụng coin hay bank money
    ------print("DEBUG CATEGORY CHECK - caseConfig.category:", caseConfig.category)
    ------print("DEBUG CATEGORY CHECK - type of category:", type(caseConfig.category))
    ------print("DEBUG CATEGORY CHECK - comparison result:", caseConfig.category == "standart")
    
    if caseConfig.category == "standart" then
        -- Sử dụng bank money cho category "standart"
        ------print("USING BANK MONEY for standart case - Player has:", Player.PlayerData.money["bank"], "Need:", price)
        if tonumber(Player.PlayerData.money["bank"]) >= tonumber(price) then
            if price > 0 then
                ------print("REMOVING BANK MONEY:", price)
                Player.Functions.RemoveMoney("bank", tonumber(price))
                ------print("BANK MONEY REMOVED SUCCESSFULLY")
            end
            -- Xóa chìa khóa sau khi sử dụng
            if keyRequired then
                Player.Functions.RemoveItem(keyRequired, 1)
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[keyRequired], "remove")
            end
            ------print("=== SENDING SUCCESS RESPONSE WITH WON ITEM ===")
            ------print("wonItem being sent:", json.encode(wonItem))
            SetPendingReward(source, wonItem)
            cb({success = true, wonItem = wonItem})
        else
            cb({success = false, reason = "no_bank_money"})
        end
    else
        -- Sử dụng coin cho các category khác (premium, etc.)
        GetPlayerCoin(source, function(coin_player)
            ------print("COIN CHECK - Player has:", coin_player, "Need:", price) -- Debug tạm
            if coin_player >= price then 
                if price > 0 then
                    ------print("REMOVING COIN:", price) -- Debug tạm
                    RemovePlayerCoin(source, price, function(success)
                        ------print("REMOVE RESULT:", success) -- Debug tạm
                        if success then
                            -- Xóa chìa khóa sau khi sử dụng
                            if keyRequired then
                                Player.Functions.RemoveItem(keyRequired, 1)
                                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[keyRequired], "remove")
                            end
                            ------print("=== SENDING SUCCESS RESPONSE WITH WON ITEM (COIN) ===")
                            ------print("wonItem being sent:", json.encode(wonItem))
                            SetPendingReward(source, wonItem)
                            cb({success = true, wonItem = wonItem})
                        else
                            cb({success = false, reason = "coin_update_failed"})
                        end
                    end)
                else
                    ------print("PRICE IS 0 - NO COIN NEEDED") -- Debug tạm
                    -- Không cần coin, chỉ cần chìa khóa
                    if keyRequired then
                        Player.Functions.RemoveItem(keyRequired, 1)
                        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[keyRequired], "remove")
                    end
                    ------print("=== SENDING SUCCESS RESPONSE WITH WON ITEM (FREE) ===")
                    ------print("wonItem being sent:", json.encode(wonItem))
                    SetPendingReward(source, wonItem)
                    cb({success = true, wonItem = wonItem})
                end
            else
                cb({success = false, reason = "no_coin"})
            end
        end)
    end
end)

QBCore.Functions.CreateCallback('GetCase', function(source, cb, data)
    -- Rate limit: chống spam click (fast open)
    if not CheckCaseOpenRateLimit(source) then
        return cb({check = false, reason = "rate_limited"})
    end
    -- Validate input shape
    if type(data) ~= 'table' or type(data.case) ~= 'table' then
        return cb({check = false, reason = "invalid_input"})
    end
    if type(data.case.label) ~= 'string' then
        return cb({check = false, reason = "invalid_input"})
    end
    if data.case.key_required ~= nil and type(data.case.key_required) ~= 'string' then
        return cb({check = false, reason = "invalid_input"})
    end
    ------print("=== FAST OPEN CALLBACK CALLED ===")
    ------print("Source:", source)
    ------print("Data:", json.encode(data))
    ------print("Data.case.category:", data.case and data.case.category or "nil")
    ------print("Data.case.key_required:", data.case and data.case.key_required or "nil")
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        ------print("FAST OPEN - Player not found")
        return cb({check = false, reason = "player_not_found"}) 
    end
    
    -- Kiểm tra inventory đầy và hỏi xác nhận
    if not CheckInventoryFullAndConfirm(source) then
        return cb({check = false, reason = "cancelled"})
    end
    
    -- Lấy thông tin từ config dựa vào key_required  
    local keyRequired = data.case.key_required
    local price = 0
    local caseConfig = nil
    
    ------print("FAST OPEN - SEARCHING for key:", keyRequired)
    
    -- Tìm case config dựa vào key_required và label để tránh conflict
    ----print("🔍 FAST OPEN - SEARCHING for key:", keyRequired, "label:", data.case.label)
    
    for i, case in ipairs(Config.Live) do
        -- Match cả key_required VÀ label để tránh conflict khi có nhiều hòm cùng key
        if case.key_required == keyRequired and case.label == data.case.label then
            caseConfig = case
            price = tonumber(case.price) or 0
            ----print("✅ FAST OPEN - EXACT MATCH FOUND - Key:", keyRequired, "Label:", case.label, "Price:", price)
            break
        end
    end
    
    -- Fallback: nếu không tìm thấy exact match, tìm theo key_required thôi
    if not caseConfig then
        ------print("FAST OPEN - EXACT MATCH NOT FOUND, trying key-only match...")
        for i, case in ipairs(Config.Live) do
            if case.key_required == keyRequired then
                caseConfig = case
                price = tonumber(case.price) or 0
                ----print("⚠️ FAST OPEN - FALLBACK FOUND - Key:", keyRequired, "Label:", case.label, "Price:", price)
                break
            end
        end
    end
    
    if not caseConfig then
        ------print("FAST OPEN - CASE NOT FOUND for key:", keyRequired)
        return cb({check = false, reason = "case_not_found"})
    end
    
    -- Kiểm tra hòm đã hết hạn chưa (endTime format: "HH:MM:SS DD-MM-YYYY")
    if caseConfig.endTime then
        local h, m, s, d, mo, y = caseConfig.endTime:match("(%d+):(%d+):(%d+)%s+(%d+)-(%d+)-(%d+)")
        if h and d then
            local endTimestamp = os.time({year=tonumber(y), month=tonumber(mo), day=tonumber(d), hour=tonumber(h), min=tonumber(m), sec=tonumber(s)})
            if os.time() >= endTimestamp then
                return cb({check = false, reason = "case_expired"})
            end
        end
    end
    
    -- Kiểm tra chìa khóa cần thiết
    if keyRequired then
        local hasKey = Player.Functions.GetItemByName(keyRequired)
        if not hasKey or hasKey.amount < 1 then
            ------print("FAST OPEN - NO KEY FOUND")
            return cb({check = false, reason = "no_key"})
        end
        ------print("FAST OPEN - KEY CHECK PASSED - Has:", hasKey.amount)
    end
    
    -- Function to randomly select item based on DoHiem rates - COPIED FROM 'Case' CALLBACK
    local function getRandomItemFast(caseItems)
        -- CHIỆN DÙNG Config.RarityRates từ config2.lua
        local rarityRates = Config.RarityRates
        
        -- Lấy citizenid để check pity system
        local citizenid = Player.PlayerData and Player.PlayerData.citizenid
        
        -- Lấy giới tính thực của player (70% đúng giới / 30% khác)
        local playerRealGender = GetPlayerRealGender(Player.PlayerData)
        
        -- =====================================================
        -- SPECIAL ITEM CHECK - Kiểm tra item đặc biệt trước (FAST OPEN)
        -- Ưu tiên: Pity → Tỉ lệ cứng → Roll clothing thường
        -- =====================================================
        if caseConfig.specialItem and citizenid then
            local si = caseConfig.specialItem
            local pityData = GetSpecialItemPity(citizenid, caseConfig.label, si.minPity, si.maxPity)
            
            -- Check 1: Pity - đã quay đủ số lần → ĐẢM BẢO ra special item
            if pityData.counter >= pityData.threshold then
                return BuildSpecialItemResult(si)
            end
            
            -- Check 2: Tỉ lệ cứng - random mỗi lần quay
            local rand = math.random() * 100
            if rand <= (si.chance or 0.1) then
                return BuildSpecialItemResult(si)
            end
        end

        -- =====================================================
        -- CHIBI ITEM CHECK - Kiểm tra từng ped riêng (chance + pity độc lập) (FAST OPEN)
        -- Ưu tiên: Pity → Tỉ lệ cứng → Roll clothing thường
        -- =====================================================
        if caseConfig.Chibi_item and caseConfig.Chibi_item.peds and citizenid then
            local ci = caseConfig.Chibi_item
            for _, pedConfig in ipairs(ci.peds) do
                local pityKey = caseConfig.label .. '_chibi_' .. pedConfig.metaped
                local chibiPityData = GetChibiItemPity(citizenid, pityKey, pedConfig.minPity, pedConfig.maxPity)

                -- Check 1: Pity - đã quay đủ số lần → ĐẢM BẢO ra chibi này
                if chibiPityData.counter >= chibiPityData.threshold then
                    return BuildChibiItemResult(ci, pedConfig)
                end

                -- Check 2: Tỉ lệ cứng - random mỗi lần quay
                local chibiRand = math.random() * 100
                if chibiRand <= (pedConfig.chance or 0.1) then
                    return BuildChibiItemResult(ci, pedConfig)
                end
            end
        end
        
        -- =====================================================
        -- BUILD AVAILABLE ITEMS TRƯỚC - để check rarity nào có available (FAST OPEN)
        -- =====================================================
        local allItems = {}
        for _, item in ipairs(caseItems) do
            if not item.no_add then
                if item.type == "clothing" and item.DoHiem then
                    -- Xác định giới tính có trọng số cho từng item
                    local hasMale = item.DoHiem["male"] ~= nil
                    local hasFemale = item.DoHiem["female"] ~= nil
                    local itemGender
                    if hasMale and hasFemale then
                        itemGender = WeightedGenderSelect(playerRealGender, true)
                    elseif hasMale then
                        itemGender = "male"
                    elseif hasFemale then
                        itemGender = "female"
                    else
                        itemGender = playerRealGender or "male"
                    end

                    if item.DoHiem[itemGender] then
                    for rarityLevel, drawableList in pairs(item.DoHiem[itemGender]) do
                        for _, d in ipairs(drawableList) do
                            local newItem = {}
                            for k, v in pairs(item) do newItem[k] = v end
                            newItem.drawable = d
                            newItem.sex = itemGender
                            newItem.DoHiem = rarityLevel
                            
                            local base = Config.Items and Config.Items[newItem.item]
                            if base then
                                newItem.label = Config.FormatClothingLabel(newItem.item, itemGender, d)
                                newItem.component = newItem.component or base.component
                                newItem.clothesSlotID = newItem.clothesSlotID or base.clothesSlotID
                                newItem.prop = base.prop
                            else
                                newItem.label = Config.FormatClothingLabel(newItem.item, itemGender, d)
                                newItem.prop = false
                            end
                            
                            local isPropItem = false
                            if newItem.item == "cloth_glasses" or newItem.item == "cloth_helmet" or newItem.item == "cloth_ears" then
                                isPropItem = true
                            elseif newItem.item == "cloth_mask" or newItem.item == "cloth_tshirt" or newItem.item == "cloth_torso" then
                                isPropItem = false
                            else
                                isPropItem = base and base.prop or false
                            end
                            
                            if isPropItem then
                                if Config.PropFormat == 1 then
                                    newItem.imageurl = string.format("%s/%s_%s_%s_prop.%s", 
                                        Config.Url, itemGender, newItem.component or base.component, d, Config.Extension)
                                else
                                    newItem.imageurl = string.format("%s/%s_prop_%s_%s.%s", 
                                        Config.Url, itemGender, newItem.component or base.component, d, Config.Extension)
                                end
                            else
                                newItem.imageurl = string.format("%s/%s_%s_%s.%s", 
                                    Config.Url, itemGender, newItem.component or base.component, d, Config.Extension)
                            end
                            
                            table.insert(allItems, newItem)
                        end
                    end
                    end
                elseif item.group_items then
                    for _, subItem in ipairs(item.group_items) do
                        local newItem = {}
                        for k, v in pairs(item) do
                            newItem[k] = v
                        end
                        newItem.item = subItem
                        newItem.label = item.group_labels and item.group_labels[subItem] or subItem
                        newItem.rarity = item.group_rarities and item.group_rarities[subItem] or item.rarity
                        newItem.DoHiem = newItem.rarity
                        newItem.uniqueId = newItem.item .. "_" .. (newItem.count or 1) .. "_" .. (newItem.DoHiem or "common")
                        
                        if newItem.type == "item" then
                            local timestamp = os.time()
                            local randomId = math.random(10000, 99999)
                            newItem.imageurl = Config.OxInventoryImagePath .. newItem.item .. '.webp?t=' .. timestamp .. '&r=' .. randomId
                            newItem.imageFallback = Config.OxInventoryImagePath .. newItem.item .. '.webp'
                        else
                            newItem.imageurl = 'https://raw.githubusercontent.com/QuocHuyCrow/imagestellacity/main/Items_KhoDo/' .. newItem.item .. '.webp'
                        end
                        
                        table.insert(allItems, newItem)
                    end
                else
                    local newItem = {}
                    for k, v in pairs(item) do newItem[k] = v end
                    if not newItem.label then
                        local base = Config.Items and Config.Items[newItem.item]
                        newItem.label = base and base.label or newItem.item
                    end
                    
                    newItem.uniqueId = newItem.item .. "_" .. (newItem.count or 1) .. "_" .. (newItem.DoHiem or "common")
                    
                    if newItem.type == "item" then
                        local timestamp = os.time()
                        local randomId = math.random(10000, 99999)
                        newItem.imageurl = Config.OxInventoryImagePath .. newItem.item .. '.webp?t=' .. timestamp .. '&r=' .. randomId
                        newItem.imageFallback = Config.OxInventoryImagePath .. newItem.item .. '.webp'
                    else
                        newItem.imageurl = 'https://raw.githubusercontent.com/QuocHuyCrow/imagestellacity/main/Items_KhoDo/' .. newItem.item .. '.webp'
                    end
                    
                    table.insert(allItems, newItem)
                end
            end
        end
        
        -- =====================================================
        -- CHECK AVAILABLE RARITIES - Xem hòm có rarity nào (FAST OPEN)
        -- =====================================================
        local availableRarities = {}
        for _, item in ipairs(allItems) do
            if item.DoHiem then
                availableRarities[item.DoHiem] = true
            end
        end
        
        local function rollRarity()
            -- =====================================================
            -- PITY SYSTEM - Kiểm tra số lần quay với FALLBACK (FAST OPEN)
            -- Return: {pityTier, actualRarity}
            -- =====================================================
            if Config.EnablePitySystem and citizenid then
                local counter = GetPityCounter(citizenid)
                local thresholds = RandomizePityThresholds(citizenid)
                
                if counter.mythic >= thresholds.mythic then
                    if availableRarities["Mythic"] then
                        --print("🎁 FAST PITY - MYTHIC - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Mythic"}
                    elseif availableRarities["Legendary"] then
                        --print("🎁 FAST PITY FALLBACK - Mythic→Legendary - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Legendary"}
                    elseif availableRarities["Epic"] then
                        --print("🎁 FAST PITY FALLBACK - Mythic→Epic - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Epic"}
                    elseif availableRarities["Rare"] then
                        --print("🎁 FAST PITY FALLBACK - Mythic→Rare - Counter:", counter.mythic .. "/" .. thresholds.mythic)
                        return {"Mythic", "Rare"}
                    end
                end
                
                if counter.legendary >= thresholds.legendary then
                    if availableRarities["Legendary"] then
                        --print("🎁 FAST PITY - LEGENDARY - Counter:", counter.legendary .. "/" .. thresholds.legendary)
                        return {"Legendary", "Legendary"}
                    elseif availableRarities["Epic"] then
                        --print("🎁 FAST PITY FALLBACK - Legendary→Epic - Counter:", counter.legendary .. "/" .. thresholds.legendary)
                        return {"Legendary", "Epic"}
                    elseif availableRarities["Rare"] then
                        --print("🎁 FAST PITY FALLBACK - Legendary→Rare - Counter:", counter.legendary .. "/" .. thresholds.legendary)
                        return {"Legendary", "Rare"}
                    end
                end
                
                if counter.epic >= thresholds.epic then
                    if availableRarities["Epic"] then
                        --print("🎁 FAST PITY - EPIC - Counter:", counter.epic .. "/" .. thresholds.epic)
                        return {"Epic", "Epic"}
                    elseif availableRarities["Rare"] then
                        --print("🎁 FAST PITY FALLBACK - Epic→Rare - Counter:", counter.epic .. "/" .. thresholds.epic)
                        return {"Epic", "Rare"}
                    end
                end
                
                if counter.rare >= thresholds.rare then
                    if availableRarities["Rare"] then
                        --print("🎁 FAST PITY - RARE - Counter:", counter.rare .. "/" .. thresholds.rare)
                        return {"Rare", "Rare"}
                    end
                    DebugPrint("⚠️ FAST PITY SKIPPED - No Rare items")
                end
            end
            
            -- =====================================================
            -- RANDOM NORMAL - Nếu chưa đạt pity (FAST OPEN)
            -- =====================================================
            local rand = math.random() * 100
            local cumulative = 0
            local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
            
            for _, rarity in ipairs(rarityOrder) do
                local rate = rarityRates[rarity]
                if rate and availableRarities[rarity] then
                    cumulative = cumulative + rate
                    if rand <= cumulative then
                        return {nil, rarity}  -- Không trigger pity
                    end
                end
            end
            
            for _, rarity in ipairs({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
                if availableRarities[rarity] then
                    return {nil, rarity}  -- Không trigger pity
                end
            end
            
            return {nil, "Common"}  -- Không trigger pity
        end
        
        -- Get items with DoHiem
        local withRarity = {}
        local noRarity = {}
        for _, item in ipairs(allItems) do
            if item.DoHiem then
                table.insert(withRarity, item)
            else
                table.insert(noRarity, item)
            end
        end
        
        if #withRarity > 0 then
            local maxRetries = 10
            local attempts = 0
            
            while attempts < maxRetries do
                local result = rollRarity()
                local pityTier = result[1]
                local rarity = result[2]
                ----print("🎲 FAST OPEN - ROLLED RARITY (attempt", attempts + 1, "):", rarity)
                local pool = {}
                for _, item in ipairs(withRarity) do
                    if item.DoHiem == rarity then
                        table.insert(pool, item)
                    end
                end
                ----print("🎲 FAST OPEN - POOL SIZE for", rarity, ":", #pool)
                
                if #pool > 0 then
                    local selectedItem = pool[math.random(1, #pool)]
                    selectedItem.pityTier = pityTier  -- Lưu pityTier vào item để reset sau
                   -- --print("🎯 FAST OPEN - SELECTED ITEM:", selectedItem.item, "drawable:", selectedItem.drawable, "rarity:", rarity)
                    return selectedItem
                else
                    ----print("🔄 FAST OPEN - No items available for", rarity, "- retrying...")
                    attempts = attempts + 1
                end
            end
            
            ----print("⚠️ FAST OPEN - Max retries reached, falling back to Common items")
            local commonPool = {}
            for _, item in ipairs(withRarity) do
                if item.DoHiem == "Common" then
                    table.insert(commonPool, item)
                end
            end
            if #commonPool > 0 then
                local selectedItem = commonPool[math.random(1, #commonPool)]
                ----print("🎯 FAST OPEN - COMMON FALLBACK SELECTED:", selectedItem.item, "drawable:", selectedItem.drawable)
                return selectedItem
            end
        end
        
        if #noRarity > 0 then
            local selectedItem = noRarity[math.random(1, #noRarity)]
            ----print("🎯 FAST OPEN - FALLBACK SELECTED:", selectedItem.item)
            return selectedItem
        end
        
        if #allItems > 0 then
            local selectedItem = allItems[math.random(1, #allItems)]
            ----print("🎯 FAST OPEN - FINAL FALLBACK SELECTED:", selectedItem.item)
            return selectedItem
        end
        
        return nil
    end
    
    -- Random an item to win - THÊM LOGIC RANDOM VÀO FAST OPEN
    local wonItem = getRandomItemFast(caseConfig.items)
    
    if not wonItem then
        return cb({check = false, reason = "no_items_available"})
    end
    
    -- =====================================================
    -- PITY SYSTEM - Cập nhật counter sau khi quay (Fast Open)
    -- =====================================================
    local citizenid = Player.PlayerData and Player.PlayerData.citizenid
    if Config.EnablePitySystem and citizenid then
        local wonRarity = wonItem.DoHiem or "Common"
        local pityTier = wonItem.pityTier  -- Tier đã trigger pity (nil nếu random normal)
        
        -- Reset counter: Reset cả pityTier (nếu có) và wonRarity
        if pityTier then
            ResetPityCounter(citizenid, pityTier)  -- Reset tier trigger pity
            if pityTier ~= wonRarity then
                ResetPityCounter(citizenid, wonRarity)  -- Reset cả tier nhận được (nếu khác)
            end
        else
            ResetPityCounter(citizenid, wonRarity)  -- Reset normal
        end
        
        -- Tăng counter cho lần quay tiếp theo
        IncrementPityCounter(citizenid)
        
        --print("📊 FAST Pity Counter - Player:", Player.PlayerData.charinfo.firstname, 
            --   "Won:", wonRarity,
            --   pityTier and (" (Pity: " .. pityTier .. ")") or "",
            --   "Counters:", json.encode(GetPityCounter(citizenid)))
    end
    
    -- =====================================================
    -- SPECIAL ITEM PITY - Cập nhật counter sau khi quay (Fast Open)
    -- =====================================================
    if caseConfig.specialItem and citizenid then
        local si = caseConfig.specialItem
        if wonItem.isSpecialItem then
            -- Trúng special item → reset counter và random ngưỡng mới
            ResetSpecialItemPity(citizenid, caseConfig.label, si.minPity, si.maxPity)
        else
            -- Không trúng → tăng counter
            IncrementSpecialItemPity(citizenid, caseConfig.label)
        end
    end

    -- =====================================================
    -- CHIBI ITEM PITY - Cập nhật counter sau khi quay (Fast Open, per-ped)
    -- =====================================================
    if caseConfig.Chibi_item and caseConfig.Chibi_item.peds and citizenid then
        local ci = caseConfig.Chibi_item
        for _, pedConfig in ipairs(ci.peds) do
            local pityKey = caseConfig.label .. '_chibi_' .. pedConfig.metaped
            if wonItem.isChibiItem then
                -- Trúng bất kỳ chibi nào → reset pity của TẤT CẢ ped trong hòm
                ResetChibiItemPity(citizenid, pityKey, pedConfig.minPity, pedConfig.maxPity)
            else
                -- Không trúng → tăng counter của ped này
                IncrementChibiItemPity(citizenid, pityKey)
            end
        end
    end
    
    -- Kiểm tra category để quyết định sử dụng coin hay bank money
    ------print("DEBUG FAST CATEGORY CHECK - caseConfig.category:", caseConfig.category)
    ------print("DEBUG FAST CATEGORY CHECK - type of category:", type(caseConfig.category))
    ------print("DEBUG FAST CATEGORY CHECK - comparison result:", caseConfig.category == "standart")
    
    if caseConfig.category == "standart" then
        -- Sử dụng bank money cho category "standart"
        ------print("FAST OPEN - USING BANK MONEY for standart case - Player has:", Player.PlayerData.money["bank"], "Need:", price)
        if tonumber(Player.PlayerData.money["bank"]) >= tonumber(price) then
            -- Xóa chìa khóa ngay
            if keyRequired then
                Player.Functions.RemoveItem(keyRequired, 1)
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[keyRequired], "remove")
                ------print("FAST OPEN - KEY REMOVED")
            end
            
            if price > 0 then
                ------print("FAST OPEN - REMOVING BANK MONEY:", price)
                Player.Functions.RemoveMoney("bank", tonumber(price))
                ------print("FAST OPEN - BANK MONEY REMOVED SUCCESSFULLY")
            end
            ------print("FAST OPEN - SUCCESS - Returning check=true with wonItem")
            SetPendingReward(source, wonItem)
            cb({check = true, wonItem = wonItem}) -- TRẢY VỀ WONITEM
        else
            ------print("FAST OPEN - NOT ENOUGH BANK MONEY")
            cb({check = false, reason = "no_bank_money"})
        end
    else
        -- Sử dụng coin cho các category khác (premium, etc.)
        GetPlayerCoin(source, function(coin_player)
            ------print("FAST OPEN - COIN CHECK - Player has:", coin_player, "Need:", price)
            if coin_player >= price then 
                -- Xóa chìa khóa ngay
                if keyRequired then
                    Player.Functions.RemoveItem(keyRequired, 1)
                    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[keyRequired], "remove")
                    ------print("FAST OPEN - KEY REMOVED")
                end
                
                if price > 0 then
                    ------print("FAST OPEN - REMOVING COIN:", price)
                    RemovePlayerCoin(source, price, function(success)
                        ------print("FAST OPEN - COIN REMOVE RESULT:", success)
                        if success then
                            ------print("FAST OPEN - SUCCESS - Returning check=true with wonItem")
                            SetPendingReward(source, wonItem)
                            cb({check = true, wonItem = wonItem}) -- TRẢY VỀ WONITEM
                        else
                            ------print("FAST OPEN - COIN REMOVE FAILED")
                            cb({check = false, reason = "coin_update_failed"})
                        end
                    end)
                else
                    ------print("FAST OPEN - FREE CASE - SUCCESS with wonItem")
                    SetPendingReward(source, wonItem)
                    cb({check = true, wonItem = wonItem}) -- TRẢY VỀ WONITEM
                end
            else
                ------print("FAST OPEN - NOT ENOUGH COIN")
                cb({check = false, reason = "no_coin"})
            end
        end)
    end
end)

QBCore.Functions.CreateCallback('GoldBuy', function(source, cb, data)
    -- local Player = QBCore.Functions.GetPlayer(source)
    -- if not Player then return cb(false, 0) end
    
    -- local license = GetPlayerLicense(source)
    -- if not license then return cb(false, 0) end
    
    -- local user = ExecuteSqlOptimized("SELECT * FROM eyes_case WHERE identifier = ?", {license})
    -- if not user[1] then return cb(false, 0) end
    
    -- for k,v in pairs(data) do 
    --     if tonumber(Player.PlayerData.money["bank"]) >= tonumber(v.price) then 
    --         local UpGold = user[1].gold + v.price
    --         Player.Functions.RemoveMoney("bank", tonumber(v.price))
    --         ExecuteSqlOptimized("UPDATE eyes_case SET gold = ? WHERE identifier = ?", {UpGold, license})
    --         cb(true, Player.PlayerData.money["bank"])
    --         return
    --     else
    --         cb(false, Player.PlayerData.money["bank"])
    --     end
    -- end
    -- [[ BẬT NẾU MUA COIN ]]
    cb(false, 0)
end)

-- Callback để mua item từ cửa hàng OC
QBCore.Functions.CreateCallback('BuyShopItem', function(source, cb, data)
    DebugPrint('[BuyShopItem SERVER] Received data:', json.encode(data))
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        DebugPrint('[BuyShopItem SERVER] Player not found!')
        return cb({success = false, reason = "player_not_found"}) 
    end
    
    -- Kiểm tra inventory đầy và hỏi xác nhận
    if not CheckInventoryFullAndConfirm(source) then
        return cb({success = false, reason = "cancelled"})
    end
    
    local itemName = data.name
    local itemPrice = tonumber(data.price) or 0
    local itemLabel = data.label or itemName
    local itemQty = math.max(1, math.min(99, math.floor(tonumber(data.quantity) or 1)))
    local totalPrice = itemPrice * itemQty
    DebugPrint('[BuyShopItem SERVER] Item:', itemName, 'Price:', itemPrice, 'Qty:', itemQty, 'Total:', totalPrice)
    
    -- Kiểm tra coin
    GetPlayerCoin(source, function(coin_player)
        if coin_player >= totalPrice then
            -- Trừ coin
            RemovePlayerCoin(source, totalPrice, function(success)
                if success then
                    -- Thêm item vào inventory
                    local addSuccess = Player.Functions.AddItem(itemName, itemQty)
                    
                    if addSuccess then
                        TriggerClientEvent('QBCore:Notify', source, 'Đã mua ' .. itemQty .. 'x ' .. itemLabel .. ' với giá ' .. totalPrice .. ' Xu', 'success')
                        cb({success = true, newCoin = coin_player - totalPrice})
                    else
                        -- Hoàn coin nếu thêm item thất bại
                        AddPlayerCoin(source, totalPrice)
                        TriggerClientEvent('QBCore:Notify', source, 'Kho đồ đầy! Không thể mua item', 'error')
                        cb({success = false, reason = "inventory_full"})
                    end
                else
                    cb({success = false, reason = "coin_update_failed"})
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', source, 'Không đủ Xu! Cần ' .. totalPrice .. ' Xu', 'error')
            cb({success = false, reason = "no_coin"})
        end
    end)
end)

-- =====================================================
-- CARD OPENING - Mở thẻ bài
-- Cấu trúc giống hệt BagTypes: PitySystem, pity_group, chance, clothing items
-- =====================================================

-- Helper: tính giá lật thẻ theo thứ tự
local function GetFlipPrice(basePrice, cardNumber)
    if cardNumber <= 3 then
        return basePrice
    elseif cardNumber == 4 then
        return basePrice * (Config.Card4Multiplier or 2)
    elseif cardNumber == 5 then
        return basePrice * (Config.Card5Multiplier or 3)
    end
    return basePrice
end

-- Helper: Roll 1 item từ cardBox (dùng cho OpenCardBox)
local function generateCardReward(cardConfig, citizenid, cardBoxKey, playerRealGender, batchPityIncrements)
    local wonItem = nil
    batchPityIncrements = batchPityIncrements or {}

    -- BƯỚC 1A: Kiểm tra pity groups
    local pityGroups = {}
    local processedGroups = {}

    for _, item in ipairs(cardConfig.items) do
        if item.PitySystem and item.pity_group then
            if not item.no_add then
                if not pityGroups[item.pity_group] then
                    pityGroups[item.pity_group] = {
                        items = {},
                        counter = 0,
                        threshold = item.PitySystem.max
                    }
                end
                table.insert(pityGroups[item.pity_group].items, item)

                if not processedGroups[item.pity_group] then
                    local groupCounter = GetBagPityCounter(citizenid, cardBoxKey, item.pity_group) + (batchPityIncrements[item.pity_group] or 0)
                    pityGroups[item.pity_group].counter = groupCounter
                    processedGroups[item.pity_group] = true
                end
            end
        end
    end

    for groupName, groupData in pairs(pityGroups) do
        if #groupData.items > 0 then
            local threshold = GetBagPityThreshold(citizenid, cardBoxKey, groupName, groupData.items[1].PitySystem)
            if groupData.counter >= threshold then
                local randomIndex = math.random(1, #groupData.items)
                wonItem = groupData.items[randomIndex]
                wonItem.isPityHit = true
                wonItem.pityGroupWon = groupName
                ResetBagPityCounter(citizenid, cardBoxKey, groupName)
                ResetBagPityThreshold(citizenid, cardBoxKey, groupName)
                batchPityIncrements[groupName] = 0
                break
            end
        end
    end

    -- BƯỚC 1B: Kiểm tra items có pity riêng (không có group)
    if not wonItem then
        for _, item in ipairs(cardConfig.items) do
            if item.PitySystem and not item.pity_group then
                if not item.no_add then
                    local pityCounter = GetBagPityCounter(citizenid, cardBoxKey, item.item) + (batchPityIncrements[item.item] or 0)
                    local pityThreshold = GetBagPityThreshold(citizenid, cardBoxKey, item.item, item.PitySystem)

                    if pityCounter >= pityThreshold then
                        wonItem = item
                        wonItem.isPityHit = true
                        wonItem.pityItemWon = item.item
                        ResetBagPityCounter(citizenid, cardBoxKey, item.item)
                        ResetBagPityThreshold(citizenid, cardBoxKey, item.item)
                        batchPityIncrements[item.item] = 0
                        break
                    end
                end
            end
        end
    end

    -- =====================================================
    -- BƯỚC 2: NẾU KHÔNG CÓ PER-ITEM PITY, DÙNG Config.RarityRates + Config.PitySystem
    -- (Giống hệ thống hòm gacha / BagTypes)
    -- =====================================================
    if not wonItem then
        local rarityRates = Config.RarityRates

        -- Xác định giới tính dựa trên giới tính thực của player (70% đúng giới / 30% khác)

        -- Build items grouped by rarity (exclude PitySystem items)
        local itemsByRarity = {}
        local availableRarities = {}

        for _, item in ipairs(cardConfig.items) do
            if not item.PitySystem and not item.no_add then
                if type(item.rarity) == "table" then
                    -- Xác định giới tính có trọng số cho từng item
                    local hasMale = item.rarity["male"] and #(item.rarity["male"]["Common"] or item.rarity["male"]["Uncommon"] or item.rarity["male"]["Rare"] or item.rarity["male"]["Epic"] or item.rarity["male"]["Legendary"] or {}) > 0
                    local hasFemale = item.rarity["female"] and #(item.rarity["female"]["Common"] or item.rarity["female"]["Uncommon"] or item.rarity["female"]["Rare"] or item.rarity["female"]["Epic"] or item.rarity["female"]["Legendary"] or {}) > 0
                    local chosenGender
                    if hasMale and hasFemale then
                        chosenGender = WeightedGenderSelect(playerRealGender, true)
                    elseif hasMale then
                        chosenGender = "male"
                    elseif hasFemale then
                        chosenGender = "female"
                    else
                        chosenGender = playerRealGender or "male"
                    end
                    -- Clothing item: expand per rarity per drawable (giống BagTypes)
                    if item.rarity[chosenGender] then
                        for rarityLevel, drawableList in pairs(item.rarity[chosenGender]) do
                            if type(drawableList) == "table" and #drawableList > 0 then
                                if not itemsByRarity[rarityLevel] then
                                    itemsByRarity[rarityLevel] = {}
                                end
                                for _, d in ipairs(drawableList) do
                                    table.insert(itemsByRarity[rarityLevel], {
                                        item = item.item,
                                        label = item.label or item.item,
                                        min_amount = item.min_amount,
                                        max_amount = item.max_amount,
                                        sex = chosenGender,
                                        drawable = d,
                                        DoHiem = rarityLevel,
                                        isClothing = true
                                    })
                                end
                                availableRarities[rarityLevel] = true
                            end
                        end
                    end
                else
                    -- Normal item: group by rarity field
                    local r = item.rarity or "Common"
                    if not itemsByRarity[r] then
                        itemsByRarity[r] = {}
                    end
                    table.insert(itemsByRarity[r], item)
                    availableRarities[r] = true
                end
            end
        end

        -- Check global Config.PitySystem (giống hòm gacha / BagTypes)
        local pityTier = nil
        local wonRarity = nil

        if Config.EnablePitySystem and citizenid then
            local counter = GetPityCounter(citizenid)
            local thresholds = RandomizePityThresholds(citizenid)

            -- Kiểm tra pity theo thứ tự từ cao xuống thấp với fallback
            if counter.mythic >= thresholds.mythic then
                if availableRarities["Mythic"] then pityTier, wonRarity = "Mythic", "Mythic"
                elseif availableRarities["Legendary"] then pityTier, wonRarity = "Mythic", "Legendary"
                elseif availableRarities["Epic"] then pityTier, wonRarity = "Mythic", "Epic"
                elseif availableRarities["Rare"] then pityTier, wonRarity = "Mythic", "Rare"
                end
            end

            if not pityTier and counter.legendary >= thresholds.legendary then
                if availableRarities["Legendary"] then pityTier, wonRarity = "Legendary", "Legendary"
                elseif availableRarities["Epic"] then pityTier, wonRarity = "Legendary", "Epic"
                elseif availableRarities["Rare"] then pityTier, wonRarity = "Legendary", "Rare"
                end
            end

            if not pityTier and counter.epic >= thresholds.epic then
                if availableRarities["Epic"] then pityTier, wonRarity = "Epic", "Epic"
                elseif availableRarities["Rare"] then pityTier, wonRarity = "Epic", "Rare"
                end
            end

            if not pityTier and counter.rare >= thresholds.rare then
                if availableRarities["Rare"] then pityTier, wonRarity = "Rare", "Rare"
                end
            end
        end

        -- Normal roll nếu chưa đạt pity
        if not wonRarity then
            local rand = math.random() * 100
            local cumulative = 0
            local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}

            for _, rarity in ipairs(rarityOrder) do
                local rate = rarityRates[rarity]
                if rate and availableRarities[rarity] then
                    cumulative = cumulative + rate
                    if rand <= cumulative then
                        wonRarity = rarity
                        break
                    end
                end
            end

            -- Fallback to any available rarity
            if not wonRarity then
                for _, rarity in ipairs({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
                    if availableRarities[rarity] then
                        wonRarity = rarity
                        break
                    end
                end
            end
        end

        -- Pick random item from won rarity pool
        if wonRarity and itemsByRarity[wonRarity] and #itemsByRarity[wonRarity] > 0 then
            local pool = itemsByRarity[wonRarity]
            local selected = pool[math.random(1, #pool)]

            if selected.isClothing then
                local clothingConfig = Config.Items and Config.Items[selected.item] or {}
                wonItem = {
                    item = selected.item,
                    label = selected.label,
                    amount = math.random(selected.min_amount or 1, selected.max_amount or 1),
                    rarity = selected.DoHiem,
                    sex = selected.sex,
                    drawable = selected.drawable,
                    DoHiem = selected.DoHiem,
                    component = clothingConfig.component,
                    prop = clothingConfig.prop,
                    isClothing = true,
                    pityTier = pityTier
                }
            else
                wonItem = {
                    item = selected.item,
                    label = selected.label,
                    amount = math.random(selected.min_amount or 1, selected.max_amount or 1),
                    rarity = selected.rarity or wonRarity,
                    serial = selected.serial,
                    pityTier = pityTier
                }
            end
        end

        -- Cập nhật global pity counter (giống hòm gacha / BagTypes)
        if Config.EnablePitySystem and citizenid and wonItem then
            local wonR = wonItem.DoHiem or wonItem.rarity or "Common"
            if pityTier then
                ResetPityCounter(citizenid, pityTier)
                if pityTier ~= wonR then
                    ResetPityCounter(citizenid, wonR)
                end
            else
                ResetPityCounter(citizenid, wonR)
            end
            IncrementPityCounter(citizenid)
        end
    end

    -- =====================================================
    -- BƯỚC 3: XỬ LÝ ITEM TRÚNG (KHÔNG increment pity ở đây - sẽ increment ở CollectCards)
    -- =====================================================
    if wonItem and wonItem.group_items then
        local copyItem = {}
        for k, v in pairs(wonItem) do
            copyItem[k] = v
        end
        local subItem = wonItem.group_items[math.random(1, #wonItem.group_items)]
        copyItem.item = subItem
        copyItem.label = wonItem.group_labels and wonItem.group_labels[subItem] or subItem
        copyItem.rarity = wonItem.group_rarities and wonItem.group_rarities[subItem] or wonItem.rarity
        copyItem.pityItemWon = subItem
        wonItem = copyItem
    end

    if wonItem then
        local rewardData = nil

        -- Nếu wonItem đến từ BƯỚC 2 (đã build sẵn amount/rarity)
        if wonItem.amount then
            if wonItem.isClothing then
                rewardData = {
                    item = wonItem.item,
                    label = wonItem.label or wonItem.item,
                    amount = wonItem.amount,
                    rarity = wonItem.DoHiem or wonItem.rarity,
                    sex = wonItem.sex,
                    drawable = wonItem.drawable,
                    DoHiem = wonItem.DoHiem,
                    component = wonItem.component,
                    prop = wonItem.prop,
                    isClothing = true
                }
            else
                rewardData = {
                    item = wonItem.item,
                    label = wonItem.label,
                    amount = wonItem.amount,
                    rarity = wonItem.rarity,
                    serial = wonItem.serial
                }
            end
        else
            -- wonItem đến từ BƯỚC 1 (per-item pity, format config gốc)
            local amount = math.random(wonItem.min_amount or 1, wonItem.max_amount or 1)
            rewardData = {
                item = wonItem.item,
                label = wonItem.label,
                amount = amount,
                rarity = wonItem.rarity,
                serial = wonItem.serial,
                isPityHit = true,
                pityGroupWon = wonItem.pityGroupWon,
                pityItemWon = wonItem.pityItemWon
            }
        end

        -- Cập nhật batch offset cho các pity groups/items KHÔNG trúng
        local pityGroupWon = rewardData.isPityHit and rewardData.pityGroupWon
        local pityItemWon = (rewardData.isPityHit and not pityGroupWon) and (rewardData.pityItemWon or rewardData.item)
        local incGroupsInReward = {}

        for _, item in ipairs(cardConfig.items) do
            if item.PitySystem and not item.no_add then
                if item.pity_group then
                    if item.pity_group ~= pityGroupWon and not incGroupsInReward[item.pity_group] then
                        batchPityIncrements[item.pity_group] = (batchPityIncrements[item.pity_group] or 0) + 1
                        incGroupsInReward[item.pity_group] = true
                    end
                else
                    local itemKey = item.item
                    if itemKey ~= pityItemWon and not incGroupsInReward[itemKey] then
                        batchPityIncrements[itemKey] = (batchPityIncrements[itemKey] or 0) + 1
                        incGroupsInReward[itemKey] = true
                    end
                end
            end
        end

        DebugPrint(string.format('^2[CARD-PITY]^7 Card reward: %s (%s) - rarity: %s', rewardData.item, rewardData.label, tostring(rewardData.rarity)))
        return rewardData
    end

    DebugPrint('^1[CARD-PITY]^7 WARNING: generateCardReward returned nil!')
    return nil
end

-- Bước 1: Mở gói bài - CHỈ roll 5 items, KHÔNG trừ tiền
QBCore.Functions.CreateCallback('OpenCardBox', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return cb({success = false, reason = "player_not_found"})
    end

    local citizenid = Player.PlayerData.citizenid
    local cardIndex = tonumber(data.cardBox.index)
    local cardConfig = Config.CardBoxes and Config.CardBoxes[cardIndex]
    if not cardConfig then
        if Config.CardBoxes then
            for i, box in ipairs(Config.CardBoxes) do
                if box.label == data.cardBox.label then
                    cardConfig = box
                    cardIndex = i
                    break
                end
            end
        end
    end

    if not cardConfig then
        return cb({success = false, reason = "card_not_found"})
    end

    -- Dùng key duy nhất cho pity tracking (giống bagType key)
    local cardBoxKey = "card_box_" .. tostring(cardIndex)
    DebugPrint(string.format('^3[CARD-OPEN]^7 Player %s opening card box #%d (key: %s, label: %s)', citizenid, cardIndex, cardBoxKey, cardConfig.label))

    -- Kiểm tra kho đầy ngay khi mở, trước khi roll items
    if IsInventoryFull(source) then
        local confirmed = CheckInventoryFullAndConfirm(source)
        if not confirmed then
            return cb({success = false, reason = "cancelled"})
        end
    end

    -- Roll 5 items (không trừ tiền) - dùng generateCardReward giống generateBagRewards
    local wonItems = {}
    local batchPityIncrements = {}
    for i = 1, 5 do
        local reward = generateCardReward(cardConfig, citizenid, cardBoxKey, GetPlayerRealGender(Player.PlayerData), batchPityIncrements)
        if not reward then
            return cb({success = false, reason = "no_items_available"})
        end

        -- Build result item cho UI
        local resultItem = {
            item = reward.item,
            label = reward.label,
            count = reward.amount or 1,
            DoHiem = reward.DoHiem or reward.rarity or "Common",
            rarity = reward.rarity,
            isPityHit = reward.isPityHit,
            pityGroupWon = reward.pityGroupWon,
            pityItemWon = reward.pityItemWon,
        }

        -- Clothing item: thêm thông tin sex, drawable, imageurl
        if reward.isClothing and reward.sex and reward.drawable then
            resultItem.sex = reward.sex
            resultItem.drawable = reward.drawable
            resultItem.component = reward.component
            resultItem.prop = reward.prop

            local Config_item = Config.Items and Config.Items[reward.item]
            if Config_item then
                local isPropItem = false
                if reward.item == "cloth_glasses" or reward.item == "cloth_helmet" or reward.item == "cloth_ears" then
                    isPropItem = true
                elseif reward.item == "cloth_mask" or reward.item == "cloth_tshirt" or reward.item == "cloth_torso" then
                    isPropItem = false
                else
                    isPropItem = Config_item.prop or false
                end
                if isPropItem then
                    if Config.PropFormat == 1 then
                        resultItem.imageurl = string.format("%s/%s_%s_%s_prop.%s",
                            Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                    else
                        resultItem.imageurl = string.format("%s/%s_prop_%s_%s.%s",
                            Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                    end
                else
                    resultItem.imageurl = string.format("%s/%s_%s_%s.%s",
                        Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                end
                local label_sex = reward.sex == "male" and "Nam" or "Nữ"
                resultItem.label = Config_item.label .. " #" .. (reward.drawable or 0) .. " (" .. label_sex .. ")"
            end
        else
            -- Normal item: dùng OxInventory image path
            if not resultItem.imageurl then
                resultItem.imageurl = Config.OxInventoryImagePath .. resultItem.item .. '.webp'
            end
        end

        resultItem.caseLabel = cardConfig.label
        wonItems[i] = resultItem
    end

    -- Shuffle wonItems
    local shuffledItems = {}
    local tempIndices = {1, 2, 3, 4, 5}
    for i = 1, 5 do
        local randIndex = math.random(1, #tempIndices)
        local chosenIndex = table.remove(tempIndices, randIndex)
        shuffledItems[i] = wonItems[chosenIndex]
    end
    wonItems = shuffledItems

    -- Tính giá mỗi thẻ
    local basePrice = tonumber(cardConfig.price) or 0
    local flipPrices = {}
    for i = 1, 5 do
        flipPrices[i] = GetFlipPrice(basePrice, i)
    end

    -- Lưu pending session cho CardBox trên server
    PendingCardBoxClaims[source] = {
        items = wonItems,
        flippedCount = 0,
        claimed = false,
        timestamp = os.time()
    }

    cb({
        success = true,
        wonItems = wonItems,
        currency = cardConfig.currency or "coin",
        basePrice = basePrice,
        flipPrices = flipPrices
    })
end)

-- Bước 2: Lật thẻ - Trừ tiền cho 1 thẻ
QBCore.Functions.CreateCallback('FlipCard', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return cb({success = false, reason = "player_not_found"})
    end

    local flipPrice = tonumber(data.flipPrice) or 0
    local currency = data.currency or "coin"

    local function markCardFlipped()
        if PendingCardBoxClaims[source] and not PendingCardBoxClaims[source].claimed then
            PendingCardBoxClaims[source].flippedCount = (PendingCardBoxClaims[source].flippedCount or 0) + 1
        end
    end

    if flipPrice <= 0 then
        markCardFlipped()
        return cb({success = true, newBank = Player.PlayerData.money["bank"]})
    end

    if currency == "bank" then
        if tonumber(Player.PlayerData.money["bank"]) >= flipPrice then
            Player.Functions.RemoveMoney("bank", flipPrice)
            markCardFlipped()
            cb({success = true, newBank = Player.PlayerData.money["bank"]})
        else
            cb({success = false, reason = "no_bank_money"})
        end
    else
        GetPlayerCoin(source, function(coin_player)
            if coin_player >= flipPrice then
                RemovePlayerCoin(source, flipPrice, function(removeSuccess)
                    if removeSuccess then
                        markCardFlipped()
                        cb({success = true, newCoin = coin_player - flipPrice})
                    else
                        cb({success = false, reason = "coin_update_failed"})
                    end
                end)
            else
                cb({success = false, reason = "no_coin"})
            end
        end)
    end
end)

-- Bước 3: Nhận thưởng - Add items đã lật vào inventory (giống BagTypes: clothing, metadata, announce, storage fallback)
QBCore.Functions.CreateCallback('CollectCards', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return cb({success = false, reason = "player_not_found"})
    end

    local session = PendingCardBoxClaims[source]
    if not session or session.claimed then
        return cb({success = false, reason = "already_claimed_or_invalid"})
    end

    -- Khóa session ngay lập tức để chống spam/duplicate claims
    session.claimed = true
    PendingCardBoxClaims[source] = nil

    local citizenid = Player.PlayerData.citizenid
    local items = data.items
    if not items or #items == 0 then
        return cb({success = false, reason = "no_items"})
    end

    -- Giới hạn số vật phẩm nhận tối đa theo số thẻ thực sự được lật và trả tiền trên server
    local allowedCount = session.flippedCount or 0
    if allowedCount <= 0 then
        return cb({success = false, reason = "no_cards_flipped"})
    end

    if #items > allowedCount then
        local sliced = {}
        for i = 1, allowedCount do
            table.insert(sliced, items[i])
        end
        items = sliced
    end
    if not items or #items == 0 then
        return cb({success = false, reason = "no_items"})
    end

    local addedItems = {}
    local itemsToAnnounce = {}

    for _, item in ipairs(items) do
        local itemName = item.item
        local count = tonumber(item.count) or tonumber(item.amount) or 1
        if itemName then
            local itemMetadata = {}
            local Config_item = Config.Items and Config.Items[itemName]
            local isClothingItem = item.sex and item.drawable and Config_item

            if isClothingItem then
                -- Clothing item: tạo metadata đầy đủ (giống BagTypes)
                local isPropItem = false
                if itemName == "cloth_glasses" or itemName == "cloth_helmet" or itemName == "cloth_ears" then
                    isPropItem = true
                elseif itemName == "cloth_mask" or itemName == "cloth_tshirt" or itemName == "cloth_torso" then
                    isPropItem = false
                else
                    isPropItem = Config_item.prop or false
                end

                local imageUrl = nil
                if isPropItem then
                    if Config.PropFormat == 1 then
                        imageUrl = string.format("%s/%s_%s_%s_prop.%s",
                            Config.Url, item.sex, item.component or Config_item.component, item.drawable or 0, Config.Extension)
                    else
                        imageUrl = string.format("%s/%s_prop_%s_%s.%s",
                            Config.Url, item.sex, item.component or Config_item.component, item.drawable or 0, Config.Extension)
                    end
                else
                    imageUrl = string.format("%s/%s_%s_%s.%s",
                        Config.Url, item.sex, item.component or Config_item.component, item.drawable or 0, Config.Extension)
                end

                local label_sex = item.sex == "male" and "Nam" or "Nữ"

                itemMetadata.type = "clothing"
                itemMetadata.component = item.component or Config_item.component
                itemMetadata.sex = item.sex
                itemMetadata.drawable = item.drawable
                itemMetadata.label = Config_item.label .. " #" .. (item.drawable or 0) .. " (" .. label_sex .. ")"
                itemMetadata.DoHiem = item.DoHiem or item.rarity
                itemMetadata.imageurl = imageUrl
                itemMetadata.prop = Config_item.prop or false
                itemMetadata.serial = GenerateSerial()
                itemMetadata.fromGacha = true
                itemMetadata.gachaTimestamp = os.time()
            else
                -- Normal item
                if item.DoHiem or item.rarity then
                    itemMetadata.DoHiem = item.DoHiem or item.rarity
                end
                if item.serial then
                    itemMetadata.serial = GenerateSerial()
                    itemMetadata.fromGacha = true
                    itemMetadata.gachaTimestamp = os.time()
                end
            end

            -- AddItem (clothing vào slot ngoài 6-21, giống BagTypes)
            local success = false
            if isClothingItem then
                local targetSlot = FindAvailableSlotExcluding(source, 6, 21)
                if targetSlot then
                    success = exports.ox_inventory:AddItem(source, itemName, count, itemMetadata, targetSlot)
                end
            else
                success = exports.ox_inventory:AddItem(source, itemName, count, itemMetadata)
            end

            -- Thu thập items cần thông báo
            local itemRarity = item.DoHiem or item.rarity
            if itemRarity then
                local normalizedRarity = string.lower(tostring(itemRarity)):gsub("^%s*(.-)%s*$", "%1")
                if normalizedRarity == 'epic' or normalizedRarity == 'legendary' then
                    local announceImageUrl = nil
                    if isClothingItem and itemMetadata.imageurl then
                        announceImageUrl = itemMetadata.imageurl
                    else
                        announceImageUrl = string.format("https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp", itemName)
                    end
                    table.insert(itemsToAnnounce, {
                        item = itemName,
                        label = item.label or itemName,
                        rarity = normalizedRarity,
                        imageUrl = announceImageUrl
                    })
                end
            end

            local boxName = item.cardBoxLabel or item.caseLabel
            if not boxName and data.cardBoxIndex and Config.CardBoxes and Config.CardBoxes[data.cardBoxIndex] then
                boxName = Config.CardBoxes[data.cardBoxIndex].label
            end
            boxName = boxName or "Hòm Thẻ Bài"

            local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            local pid = Player.PlayerData.pid
            local itemLabel = item.label or itemName

            if success then
                table.insert(addedItems, itemLabel)
                -- Log nhận item từ card
                lib.logger(Player.PlayerData.source, 'Shop_donate', {
                    message = string.format("Người chơi %s | %s nhận được %dx %s từ hòm thẻ [%s]",
                        playerName, pid, count, itemLabel, boxName),
                    item = itemName,
                    amount = count,
                    box_name = boxName,
                    rarity = itemRarity,
                    type = 'item',
                    source = 'card_opening'
                })
            else
                -- Kho đồ đầy, gửi vật phẩm về kho lưu trữ cá nhân (giống BagTypes)
                if citizenid and exports.xn_buucuc then
                    local storageSuccess = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, itemName, count, itemMetadata)
                    if storageSuccess then
                        TriggerClientEvent('QBCore:Notify', source,
                            'Kho đồ đã đầy! Vật phẩm ' .. count .. 'x ' .. itemLabel .. ' đã được gửi về kho lưu trữ cá nhân.',
                            'warning')
                        table.insert(addedItems, itemLabel)
                        lib.logger(Player.PlayerData.source, 'Shop_donate', {
                            message = string.format("Người chơi %s | %s nhận được %dx %s từ hòm thẻ [%s] (Gửi về Bưu Cục do kho đồ đầy)",
                                playerName, pid, count, itemLabel, boxName),
                            item = itemName, amount = count, box_name = boxName, rarity = itemRarity, type = 'item', source = 'card_opening_buucuc'
                        })
                    else
                        TriggerClientEvent('es-case:storageFullWarning', source, itemLabel)
                        TriggerClientEvent('QBCore:Notify', source,
                            'Kho đồ VÀ bưu cục đều đầy! Vật phẩm ' .. count .. 'x ' .. itemLabel .. ' đã bị mất!',
                            'error')
                        lib.logger(Player.PlayerData.source, 'Shop_donate', {
                            message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ hòm thẻ [%s] do kho đồ và bưu cục đều đầy",
                                playerName, pid, count, itemLabel, boxName),
                            item = itemName, amount = count, box_name = boxName, rarity = itemRarity, type = 'item', source = 'card_opening_lost_item'
                        })
                    end
                else
                    TriggerClientEvent('es-case:storageFullWarning', source, itemLabel)
                    TriggerClientEvent('QBCore:Notify', source,
                        'Kho đồ đầy và không thể gửi về kho lưu trữ! Vui lòng dọn dẹp kho đồ.',
                        'error')
                    lib.logger(Player.PlayerData.source, 'Shop_donate', {
                        message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ hòm thẻ [%s] do kho đồ đầy (Bưu cục không khả dụng)",
                            playerName, pid, count, itemLabel, boxName),
                        item = itemName, amount = count, box_name = boxName, rarity = itemRarity, type = 'item', source = 'card_opening_lost_item'
                    })
                end
            end
        end
    end

    -- Thông báo server-wide cho Epic/Legendary (giống BagTypes)
    if #itemsToAnnounce > 0 then
        local rarityPriority = {legendary = 3, epic = 2, rare = 1}
        table.sort(itemsToAnnounce, function(a, b)
            return (rarityPriority[a.rarity] or 0) > (rarityPriority[b.rarity] or 0)
        end)

        local playerFirstname = Player.PlayerData.charinfo.firstname
        local playerLastname = Player.PlayerData.charinfo.lastname

        for index, announceItem in ipairs(itemsToAnnounce) do
            SetTimeout((index - 1) * 500, function()
                local rarityName = announceItem.rarity:sub(1,1):upper() .. announceItem.rarity:sub(2)
                local imageUrl = announceItem.imageUrl or string.format("https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp", announceItem.item)

                local announceFn = announceItem.rarity == 'legendary' and 'SendSpecialAnnouncementToAll' or 'SendAnnouncementToAll'
                exports['xn_thongbao'][announceFn](exports['xn_thongbao'],
                    'GACHA',
                    'Chúc mừng '.. playerFirstname .. " " .. playerLastname ..' đã mở thẻ bài ra được '..announceItem.label..' độ hiếm '..rarityName..'!',
                    10000,
                    'warning',
                    imageUrl
                )
            end)
        end
    end

    if #addedItems > 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Đã nhận ' .. #addedItems .. ' thẻ bài!', 'success')

        -- INCREMENT PITY: chỉ tăng theo số thẻ thực sự nhận (addedItems count)
        local cardBoxIndex = data.cardBoxIndex
        if cardBoxIndex then
            local cardConfig = Config.CardBoxes[cardBoxIndex]
            if cardConfig and cardConfig.items then
                local cardBoxKey = "card_box_" .. tostring(cardBoxIndex)
                local collectedCount = #addedItems

                DebugPrint(string.format('^2[CARD-PITY]^7 CollectCards: incrementing pity x%d for cardBoxKey: %s', collectedCount, cardBoxKey))

                -- INCREMENT PITY: Tăng counter chuẩn xác theo từng thẻ bài thực sự được lật/nhận
                for _, collected in ipairs(items) do
                    local pityGroupWon = collected.isPityHit and collected.pityGroupWon
                    local pityItemWon = (collected.isPityHit and not pityGroupWon) and (collected.pityItemWon or collected.item)

                    local incrementedGroupsInCard = {}
                    for _, item in ipairs(cardConfig.items) do
                        if item.PitySystem and not item.no_add then
                            if item.pity_group then
                                if item.pity_group ~= pityGroupWon and not incrementedGroupsInCard[item.pity_group] then
                                    IncrementBagPityCounter(citizenid, cardBoxKey, item.pity_group)
                                    incrementedGroupsInCard[item.pity_group] = true
                                end
                            else
                                local itemKey = item.item
                                if itemKey ~= pityItemWon and not incrementedGroupsInCard[itemKey] then
                                    IncrementBagPityCounter(citizenid, cardBoxKey, itemKey)
                                    incrementedGroupsInCard[itemKey] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    cb({success = true, collected = #addedItems})
end)

-- =====================================================
-- OPEN BOX OPENING - Mở Thính
-- Cấu trúc và logic hoạt động y hệt CARD OPENING phía trên
-- Sử dụng Config.OpenBoxes thay vì Config.CardBoxes
-- =====================================================

-- =====================================================
-- GENDER HELPER FUNCTIONS - Hỗ trợ chọn giới tính có trọng số cho clothing
-- Gender được xác định từ ped model phía CLIENT (nguồn chính xác nhất)
-- 70% ra đồ đúng giới tính / 30% ra đồ khác giới tính
-- =====================================================

-- Lưu giới tính ped của player (sync từ client trước khi mở NUI)
-- PlayerPedGender và _genderRateLimit được khai báo forward ở đầu file
-- để playerDropped handler có thể reference chúng.
-- (xem dòng 12-15)

-- Net event: client gửi gender lên khi mở menu
RegisterNetEvent('xn_case:updatePedGender', function(gender)
    local src = source
    -- Rate limit
    local now = GetGameTimer()
    if _genderRateLimit[src] and (now - _genderRateLimit[src]) < GENDER_RATE_MS then
        return
    end
    _genderRateLimit[src] = now
    -- Validate giá trị
    if gender == "male" or gender == "female" then
        PlayerPedGender[src] = gender
        DebugPrint(string.format('^2[xn_case]^7 Source %d ped gender = %s', src, gender))
    end
end)

-- Lấy giới tính thực của player:
-- Ưu tiên: giới tính sync từ ped model phía client
-- Fallback: charinfo.gender từ QBCore PlayerData
local function GetPlayerRealGender(source, playerData)
    -- Ưu tiên dùng gender đã sync từ client (chính xác theo ped model)
    local synced = PlayerPedGender[source]
    if synced then return synced end
    -- Fallback: đọc từ QBCore charinfo
    if playerData and playerData.charinfo then
        local g = playerData.charinfo.gender
        if g == 1 then return "female" end
        if g == 0 then return "male" end
        local gs = tostring(g or ""):lower()
        if gs == "female" or gs == "f" or gs == "nu" or gs == "nữ" then return "female" end
    end
    return "male"
end

-- Chọn giới tính với xác suất có trọng số:
-- 70% trả về đúng giới tính thực của player
-- 30% trả về giới tính ngược lại
-- Nếu hasOtherGender = false thì luôn trả về giới tính thực
local function WeightedGenderSelect(realGender, hasOtherGender)
    if not hasOtherGender then
        return realGender or "male"
    end
    -- 70% đúng giới tính, 30% khác giới tính
    local roll = math.random(1, 100)
    if roll <= 70 then
        return realGender or "male"
    else
        return (realGender == "male") and "female" or "male"
    end
end

-- Helper: kiểm tra bảng rarity có ít nhất 1 drawable không
-- Được kết xuất ra đây để tránh tạo lại closure trong mỗi vòng lặp
local function hasAnyDrawable(rarityTable)
    if type(rarityTable) ~= "table" then return false end
    for _, drawList in pairs(rarityTable) do
        if type(drawList) == "table" and #drawList > 0 then return true end
    end
    return false
end

-- Helper: Roll 1 item từ openbox (y hệt generateCardReward)
local function generateOpenBoxReward(boxConfig, citizenid, boxKey, playerRealGender, boxIndex, batchPityIncrements)
    local wonItem = nil
    batchPityIncrements = batchPityIncrements or {}

    local function isItemLimitReached(itemName)
        if not boxIndex then return false end
        for _, item in ipairs(boxConfig.items) do
            if item.item == itemName and item.max_slot and item.max_slot > 0 then
                local won = GetGlobalWonCount(boxIndex, itemName)
                if won >= item.max_slot then
                    return true
                end
            end
        end
        return false
    end

    -- BƯỚC 1A: Kiểm tra pity groups
    local pityGroups = {}
    local processedGroups = {}

    for _, item in ipairs(boxConfig.items) do
        if item.PitySystem and item.pity_group then
            if not item.no_add then
                if not isItemLimitReached(item.item) then
                    if not pityGroups[item.pity_group] then
                        pityGroups[item.pity_group] = { items = {}, counter = 0, threshold = item.PitySystem.max }
                    end
                    table.insert(pityGroups[item.pity_group].items, item)

                    if not processedGroups[item.pity_group] then
                        local groupCounter = GetBagPityCounter(citizenid, boxKey, item.pity_group) + (batchPityIncrements[item.pity_group] or 0)
                        pityGroups[item.pity_group].counter = groupCounter
                        processedGroups[item.pity_group] = true
                    end
                end
            end
        end
    end

    for groupName, groupData in pairs(pityGroups) do
        if #groupData.items > 0 then
            local threshold = GetBagPityThreshold(citizenid, boxKey, groupName, groupData.items[1].PitySystem)
            if groupData.counter >= threshold then
                local randomIndex = math.random(1, #groupData.items)
                wonItem = groupData.items[randomIndex]
                wonItem.isPityHit = true
                wonItem.pityGroupWon = groupName
                ResetBagPityCounter(citizenid, boxKey, groupName)
                ResetBagPityThreshold(citizenid, boxKey, groupName)
                batchPityIncrements[groupName] = 0
                break
            end
        end
    end

    -- BƯỚC 1B: Kiểm tra items có pity riêng (không có group)
    if not wonItem then
        for _, item in ipairs(boxConfig.items) do
            if item.PitySystem and not item.pity_group then
                if not item.no_add then
                    if not isItemLimitReached(item.item) then
                        local pityCounter = GetBagPityCounter(citizenid, boxKey, item.item) + (batchPityIncrements[item.item] or 0)
                        local pityThreshold = GetBagPityThreshold(citizenid, boxKey, item.item, item.PitySystem)
                        if pityCounter >= pityThreshold then
                            wonItem = item
                            wonItem.isPityHit = true
                            wonItem.pityItemWon = item.item
                            ResetBagPityCounter(citizenid, boxKey, item.item)
                            ResetBagPityThreshold(citizenid, boxKey, item.item)
                            batchPityIncrements[item.item] = 0
                            break
                        end
                    end
                end
            end
        end
    end

    -- BƯỚC 2: Dùng Config.RarityRates + Config.PitySystem nếu chưa có winner
    if not wonItem then
        local rarityRates = Config.RarityRates
        -- Xác định giới tính dựa trên giới tính thực của player (70% đúng giới / 30% khác)
        local itemsByRarity = {}
        local availableRarities = {}

        for _, item in ipairs(boxConfig.items) do
            if not item.PitySystem and not isItemLimitReached(item.item) and not item.no_add then
                if type(item.rarity) == "table" then
                    -- Dùng hasAnyDrawable (định nghĩa ở module level, không tạo closure mỗi vòng lặp)
                    local hasMale   = hasAnyDrawable(item.rarity["male"])
                    local hasFemale = hasAnyDrawable(item.rarity["female"])
                    local chosenGender
                    if hasMale and hasFemale then
                        chosenGender = WeightedGenderSelect(playerRealGender, true)
                    elseif hasMale then
                        chosenGender = "male"
                    elseif hasFemale then
                        chosenGender = "female"
                    else
                        chosenGender = playerRealGender or "male"
                    end
                    if item.rarity[chosenGender] then
                        for rarityLevel, drawableList in pairs(item.rarity[chosenGender]) do
                            if type(drawableList) == "table" and #drawableList > 0 then
                                if not itemsByRarity[rarityLevel] then itemsByRarity[rarityLevel] = {} end
                                for _, d in ipairs(drawableList) do
                                    table.insert(itemsByRarity[rarityLevel], {
                                        item = item.item, label = item.label or item.item,
                                        min_amount = item.min_amount, max_amount = item.max_amount,
                                        sex = chosenGender, drawable = d, DoHiem = rarityLevel, isClothing = true
                                    })
                                end
                                availableRarities[rarityLevel] = true
                            end
                        end
                    end
                else
                    local r = item.rarity or "Common"
                    if not itemsByRarity[r] then itemsByRarity[r] = {} end
                    table.insert(itemsByRarity[r], item)
                    availableRarities[r] = true
                end
            end
        end

        local pityTier, wonRarity = nil, nil

        if Config.EnablePitySystem and citizenid then
            local counter = GetPityCounter(citizenid)
            local thresholds = RandomizePityThresholds(citizenid)

            if counter.mythic >= thresholds.mythic then
                if availableRarities["Mythic"] then pityTier, wonRarity = "Mythic", "Mythic"
                elseif availableRarities["Legendary"] then pityTier, wonRarity = "Mythic", "Legendary"
                elseif availableRarities["Epic"] then pityTier, wonRarity = "Mythic", "Epic"
                elseif availableRarities["Rare"] then pityTier, wonRarity = "Mythic", "Rare"
                end
            end
            if not pityTier and counter.legendary >= thresholds.legendary then
                if availableRarities["Legendary"] then pityTier, wonRarity = "Legendary", "Legendary"
                elseif availableRarities["Epic"] then pityTier, wonRarity = "Legendary", "Epic"
                elseif availableRarities["Rare"] then pityTier, wonRarity = "Legendary", "Rare"
                end
            end
            if not pityTier and counter.epic >= thresholds.epic then
                if availableRarities["Epic"] then pityTier, wonRarity = "Epic", "Epic"
                elseif availableRarities["Rare"] then pityTier, wonRarity = "Epic", "Rare"
                end
            end
            if not pityTier and counter.rare >= thresholds.rare then
                if availableRarities["Rare"] then pityTier, wonRarity = "Rare", "Rare" end
            end
        end

        if not wonRarity then
            local rand = math.random() * 100
            local cumulative = 0
            local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
            for _, rarity in ipairs(rarityOrder) do
                local rate = rarityRates[rarity]
                if rate and availableRarities[rarity] then
                    cumulative = cumulative + rate
                    if rand <= cumulative then wonRarity = rarity; break end
                end
            end
            if not wonRarity then
                for _, rarity in ipairs({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
                    if availableRarities[rarity] then wonRarity = rarity; break end
                end
            end
        end

        if wonRarity and itemsByRarity[wonRarity] and #itemsByRarity[wonRarity] > 0 then
            local pool = itemsByRarity[wonRarity]
            local selected = pool[math.random(1, #pool)]

            if selected.isClothing then
                local clothingConfig = Config.Items and Config.Items[selected.item] or {}
                wonItem = {
                    item = selected.item, label = selected.label,
                    amount = math.random(selected.min_amount or 1, selected.max_amount or 1),
                    rarity = selected.DoHiem, sex = selected.sex, drawable = selected.drawable,
                    DoHiem = selected.DoHiem, component = clothingConfig.component,
                    prop = clothingConfig.prop, isClothing = true, pityTier = pityTier
                }
            else
                wonItem = {
                    item = selected.item, label = selected.label,
                    amount = math.random(selected.min_amount or 1, selected.max_amount or 1),
                    rarity = selected.rarity or wonRarity, serial = selected.serial, pityTier = pityTier
                }
            end
        end

        if Config.EnablePitySystem and citizenid and wonItem then
            local wonR = wonItem.DoHiem or wonItem.rarity or "Common"
            if pityTier then
                ResetPityCounter(citizenid, pityTier)
                if pityTier ~= wonR then ResetPityCounter(citizenid, wonR) end
            else
                ResetPityCounter(citizenid, wonR)
            end
            IncrementPityCounter(citizenid)
        end
    end

    -- BƯỚC 3: Build rewardData trả về
    if wonItem and wonItem.group_items then
        local copyItem = {}
        for k, v in pairs(wonItem) do
            copyItem[k] = v
        end
        local subItem = wonItem.group_items[math.random(1, #wonItem.group_items)]
        copyItem.item = subItem
        copyItem.label = wonItem.group_labels and wonItem.group_labels[subItem] or subItem
        copyItem.rarity = wonItem.group_rarities and wonItem.group_rarities[subItem] or wonItem.rarity
        copyItem.pityItemWon = subItem
        wonItem = copyItem
    end

    if wonItem then
        local rewardData = nil
        if wonItem.amount then
            if wonItem.isClothing then
                rewardData = {
                    item = wonItem.item, label = wonItem.label or wonItem.item,
                    amount = wonItem.amount, rarity = wonItem.DoHiem or wonItem.rarity,
                    sex = wonItem.sex, drawable = wonItem.drawable, DoHiem = wonItem.DoHiem,
                    component = wonItem.component, prop = wonItem.prop, isClothing = true
                }
            else
                rewardData = { item = wonItem.item, label = wonItem.label, amount = wonItem.amount, rarity = wonItem.rarity, serial = wonItem.serial }
            end
        else
            local amount = math.random(wonItem.min_amount or 1, wonItem.max_amount or 1)
            rewardData = {
                item = wonItem.item, label = wonItem.label, amount = amount, rarity = wonItem.rarity, serial = wonItem.serial,
                isPityHit = true, pityGroupWon = wonItem.pityGroupWon, pityItemWon = wonItem.pityItemWon
            }
        end

        -- Check if the won item has max_slot config in this box
        local matchedItemConfig = nil
        for _, it in ipairs(boxConfig.items) do
            if it.item == wonItem.item then
                matchedItemConfig = it
                break
            end
        end

        if matchedItemConfig and matchedItemConfig.max_slot and matchedItemConfig.max_slot > 0 then
            IncrementGlobalWonCount(boxIndex, wonItem.item)
        end

        -- Cập nhật batch offset cho các pity groups/items KHÔNG trúng
        local pityGroupWon = rewardData.isPityHit and rewardData.pityGroupWon
        local pityItemWon = (rewardData.isPityHit and not pityGroupWon) and (rewardData.pityItemWon or rewardData.item)
        local incGroupsInReward = {}

        for _, item in ipairs(boxConfig.items) do
            if item.PitySystem and not item.no_add then
                if item.pity_group then
                    if item.pity_group ~= pityGroupWon and not incGroupsInReward[item.pity_group] then
                        batchPityIncrements[item.pity_group] = (batchPityIncrements[item.pity_group] or 0) + 1
                        incGroupsInReward[item.pity_group] = true
                    end
                else
                    local itemKey = item.item
                    if itemKey ~= pityItemWon and not incGroupsInReward[itemKey] then
                        batchPityIncrements[itemKey] = (batchPityIncrements[itemKey] or 0) + 1
                        incGroupsInReward[itemKey] = true
                    end
                end
            end
        end

        return rewardData
    end

    DebugPrint('^1[OPENBOX-PITY]^7 WARNING: generateOpenBoxReward returned nil!')
    return nil
end

-- Mở thính - Trừ tiền ngay, roll count items (1 hoặc 10)
QBCore.Functions.CreateCallback('OpenOpenBox', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return cb({success = false, reason = "player_not_found"})
    end

    if type(data) ~= 'table' or type(data.cardBox) ~= 'table' then
        return cb({success = false, reason = "invalid_input"})
    end

    local citizenid = Player.PlayerData.citizenid
    local count = math.max(1, math.min(10, tonumber(data.count) or 1))
    local boxIndex = tonumber(data.cardBox.index)
    local boxConfig = boxIndex and Config.OpenBoxes and Config.OpenBoxes[boxIndex] or nil
    if not boxConfig then
        if Config.OpenBoxes then
            for i, box in ipairs(Config.OpenBoxes) do
                if box.label == data.cardBox.label then
                    boxConfig = box
                    boxIndex = i
                    break
                end
            end
        end
    end

    if not boxConfig then
        return cb({success = false, reason = "card_not_found"})
    end

    if IsBoxExpired(boxIndex, boxConfig) then
        return cb({success = false, reason = "box_expired"})
    end

    local boxKey = "open_box_" .. tostring(boxIndex)
    local currency = boxConfig.currency or "coin"
    local totalCost = (tonumber(boxConfig.price) or 0) * count

    if IsInventoryFull(source) then
        local confirmed = CheckInventoryFullAndConfirm(source)
        if not confirmed then
            return cb({success = false, reason = "cancelled"})
        end
    end

    -- Helper: build result items after payment succeeds
    local function doRoll()
        local wonItems = {}
        local batchPityIncrements = {}
        for i = 1, count do
            local reward = generateOpenBoxReward(boxConfig, citizenid, boxKey, GetPlayerRealGender(source, Player.PlayerData), boxIndex, batchPityIncrements)
            if not reward then
                return cb({success = false, reason = "no_items_available"})
            end

            local resultItem = {
                item = reward.item, label = reward.label, count = reward.amount or 1,
                DoHiem = reward.DoHiem or reward.rarity or "Common", rarity = reward.rarity,
                isPityHit = reward.isPityHit, pityGroupWon = reward.pityGroupWon, pityItemWon = reward.pityItemWon
            }

            if reward.isClothing and reward.sex and reward.drawable then
                resultItem.sex = reward.sex
                resultItem.drawable = reward.drawable
                resultItem.component = reward.component
                resultItem.prop = reward.prop

                local Config_item = Config.Items and Config.Items[reward.item]
                if Config_item then
                    local isPropItem = false
                    if reward.item == "cloth_glasses" or reward.item == "cloth_helmet" or reward.item == "cloth_ears" then
                        isPropItem = true
                    elseif reward.item == "cloth_mask" or reward.item == "cloth_tshirt" or reward.item == "cloth_torso" then
                        isPropItem = false
                    else
                        isPropItem = Config_item.prop or false
                    end
                    if isPropItem then
                        if Config.PropFormat == 1 then
                            resultItem.imageurl = string.format("%s/%s_%s_%s_prop.%s",
                                Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                        else
                            resultItem.imageurl = string.format("%s/%s_prop_%s_%s.%s",
                                Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                        end
                    else
                        resultItem.imageurl = string.format("%s/%s_%s_%s.%s",
                            Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                    end
                    local label_sex = reward.sex == "male" and "Nam" or "Nữ"
                    resultItem.label = Config_item.label .. " #" .. (reward.drawable or 0) .. " (" .. label_sex .. ")"
                end
            else
                if not resultItem.imageurl then
                    resultItem.imageurl = Config.OxInventoryImagePath .. resultItem.item .. '.webp'
                end
            end

            resultItem.caseLabel = boxConfig.label
            wonItems[i] = resultItem
        end

        -- Shuffle wonItems
        local shuffledItems = {}
        local tempIndices = {}
        for i = 1, count do
            tempIndices[i] = i
        end
        for i = 1, count do
            local randIndex = math.random(1, #tempIndices)
            local chosenIndex = table.remove(tempIndices, randIndex)
            shuffledItems[i] = wonItems[chosenIndex]
        end
        wonItems = shuffledItems

        -- Lưu pending session cho OpenBox trên server
        PendingOpenBoxClaims[source] = {
            items = wonItems,
            claimed = false,
            timestamp = os.time()
        }

        cb({success = true, wonItems = wonItems, currency = currency})
    end

    -- Deduct payment upfront then roll
    if totalCost <= 0 then
        doRoll()
    elseif currency == "bank" then
        if tonumber(Player.PlayerData.money["bank"]) < totalCost then
            return cb({success = false, reason = "no_bank_money"})
        end
        Player.Functions.RemoveMoney("bank", totalCost)
        doRoll()
    else
        GetPlayerCoin(source, function(currentCoin)
            if currentCoin < totalCost then
                return cb({success = false, reason = "no_coin"})
            end
            RemovePlayerCoin(source, totalCost, function(removeSuccess)
                if not removeSuccess then
                    return cb({success = false, reason = "coin_update_failed"})
                end
                doRoll()
            end)
        end)
    end
end)

-- Bước 3: Nhận thưởng thính - Add items đã lật
QBCore.Functions.CreateCallback('CollectOpenBoxCards', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return cb({success = false, reason = "player_not_found"})
    end

    local claimSession = PendingOpenBoxClaims[source]
    if not claimSession or claimSession.claimed then
        return cb({success = false, reason = "already_claimed_or_invalid"})
    end

    -- Khóa session ngay lập tức để chống spam/duplicate claims
    claimSession.claimed = true
    PendingOpenBoxClaims[source] = nil

    local citizenid = Player.PlayerData.citizenid
    local items = claimSession.items
    if not items or #items == 0 then
        return cb({success = false, reason = "no_items"})
    end

    local addedItems = {}
    local itemsToAnnounce = {}

    for _, item in ipairs(items) do
        local itemName = item.item
        local count = tonumber(item.count) or tonumber(item.amount) or 1
        if itemName then
            local itemMetadata = {}
            local Config_item = Config.Items and Config.Items[itemName]
            local isClothingItem = item.sex and item.drawable and Config_item

            if isClothingItem then
                local isPropItem = false
                if itemName == "cloth_glasses" or itemName == "cloth_helmet" or itemName == "cloth_ears" then
                    isPropItem = true
                elseif itemName == "cloth_mask" or itemName == "cloth_tshirt" or itemName == "cloth_torso" then
                    isPropItem = false
                else
                    isPropItem = Config_item.prop or false
                end

                local imageUrl = nil
                if isPropItem then
                    if Config.PropFormat == 1 then
                        imageUrl = string.format("%s/%s_%s_%s_prop.%s",
                            Config.Url, item.sex, item.component or Config_item.component, item.drawable or 0, Config.Extension)
                    else
                        imageUrl = string.format("%s/%s_prop_%s_%s.%s",
                            Config.Url, item.sex, item.component or Config_item.component, item.drawable or 0, Config.Extension)
                    end
                else
                    imageUrl = string.format("%s/%s_%s_%s.%s",
                        Config.Url, item.sex, item.component or Config_item.component, item.drawable or 0, Config.Extension)
                end

                local label_sex = item.sex == "male" and "Nam" or "Nữ"
                itemMetadata.type = "clothing"
                itemMetadata.component = item.component or Config_item.component
                itemMetadata.sex = item.sex
                itemMetadata.drawable = item.drawable
                itemMetadata.label = Config_item.label .. " #" .. (item.drawable or 0) .. " (" .. label_sex .. ")"
                itemMetadata.DoHiem = item.DoHiem or item.rarity
                itemMetadata.imageurl = imageUrl
                itemMetadata.prop = Config_item.prop or false
                itemMetadata.serial = GenerateSerial()
                itemMetadata.fromGacha = true
                itemMetadata.gachaTimestamp = os.time()
            else
                if item.DoHiem or item.rarity then
                    itemMetadata.DoHiem = item.DoHiem or item.rarity
                end
                if item.serial then
                    itemMetadata.serial = GenerateSerial()
                    itemMetadata.fromGacha = true
                    itemMetadata.gachaTimestamp = os.time()
                end
            end

            local success = false
            if isClothingItem then
                local targetSlot = FindAvailableSlotExcluding(source, 6, 21)
                if targetSlot then
                    success = exports.ox_inventory:AddItem(source, itemName, count, itemMetadata, targetSlot)
                end
            else
                success = exports.ox_inventory:AddItem(source, itemName, count, itemMetadata)
            end

            local itemRarity = item.DoHiem or item.rarity
            if itemRarity then
                local normalizedRarity = string.lower(tostring(itemRarity)):gsub("^%s*(.-)%s*$", "%1")
                if normalizedRarity == 'epic' or normalizedRarity == 'legendary' then
                    local announceImageUrl = nil
                    if isClothingItem and itemMetadata.imageurl then
                        announceImageUrl = itemMetadata.imageurl
                    else
                        announceImageUrl = string.format("https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp", itemName)
                    end
                    table.insert(itemsToAnnounce, {
                        item = itemName, label = item.label or itemName,
                        rarity = normalizedRarity, imageUrl = announceImageUrl
                    })
                end
            end

            local boxName = item.caseLabel
            if not boxName and data.cardBoxIndex and Config.OpenBoxes and Config.OpenBoxes[data.cardBoxIndex] then
                boxName = Config.OpenBoxes[data.cardBoxIndex].label
            end
            boxName = boxName or "Hòm Thính"

            local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            local pid = Player.PlayerData.pid
            local itemLabel = item.label or itemName

            if success then
                table.insert(addedItems, itemLabel)
                lib.logger(Player.PlayerData.source, 'Shop_donate', {
                    message = string.format("Người chơi %s | %s nhận được %dx %s từ [%s]",
                        playerName, pid, count, itemLabel, boxName),
                    item = itemName, amount = count, box_name = boxName, rarity = itemRarity,
                    type = 'item', source = 'openbox_opening'
                })
            else
                if citizenid and exports.xn_buucuc then
                    local storageSuccess = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, itemName, count, itemMetadata)
                    if storageSuccess then
                        TriggerClientEvent('QBCore:Notify', source,
                            'Kho đồ đã đầy! Vật phẩm ' .. count .. 'x ' .. itemLabel .. ' đã được gửi về kho lưu trữ cá nhân.',
                            'warning')
                        table.insert(addedItems, itemLabel)
                        lib.logger(Player.PlayerData.source, 'Shop_donate', {
                            message = string.format("Người chơi %s | %s nhận được %dx %s từ [%s] (Gửi về Bưu Cục do kho đồ đầy)",
                                playerName, pid, count, itemLabel, boxName),
                            item = itemName, amount = count, box_name = boxName, rarity = itemRarity, type = 'item', source = 'openbox_opening_buucuc'
                        })
                    else
                        TriggerClientEvent('es-case:storageFullWarning', source, itemLabel)
                        TriggerClientEvent('QBCore:Notify', source,
                            'Kho đồ VÀ bưu cục đều đầy! Vật phẩm ' .. count .. 'x ' .. itemLabel .. ' đã bị mất!',
                            'error')
                        lib.logger(Player.PlayerData.source, 'Shop_donate', {
                            message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ [%s] do kho đồ và bưu cục đều đầy",
                                playerName, pid, count, itemLabel, boxName),
                            item = itemName, amount = count, box_name = boxName, rarity = itemRarity, type = 'item', source = 'openbox_opening_lost_item'
                        })
                    end
                else
                    TriggerClientEvent('es-case:storageFullWarning', source, itemLabel)
                    TriggerClientEvent('QBCore:Notify', source,
                        'Kho đồ đầy và không thể gửi về kho lưu trữ! Vui lòng dọn dẹp kho đồ.',
                        'error')
                    lib.logger(Player.PlayerData.source, 'Shop_donate', {
                        message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ [%s] do kho đồ đầy (Bưu cục không khả dụng)",
                            playerName, pid, count, itemLabel, boxName),
                        item = itemName, amount = count, box_name = boxName, rarity = itemRarity, type = 'item', source = 'openbox_opening_lost_item'
                    })
                end
            end
        end
    end

    if #itemsToAnnounce > 0 then
        local rarityPriority = {legendary = 3}
        -- {legendary = 3, epic = 2, rare = 1}
        table.sort(itemsToAnnounce, function(a, b)
            return (rarityPriority[a.rarity] or 0) > (rarityPriority[b.rarity] or 0)
        end)

        local playerFirstname = Player.PlayerData.charinfo.firstname
        local playerLastname = Player.PlayerData.charinfo.lastname

        for index, announceItem in ipairs(itemsToAnnounce) do
            SetTimeout((index - 1) * 500, function()
                local rarityName = announceItem.rarity:sub(1,1):upper() .. announceItem.rarity:sub(2)
                local imageUrl = announceItem.imageUrl or string.format("https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp", announceItem.item)
                if exports['xn_thongbao'] then
                    exports['xn_thongbao']:SendSpecialAnnouncementToAll(
                        'GACHA',
                        'Chúc mừng '.. playerFirstname .. " " .. playerLastname ..' đã mở thính ra được '..announceItem.label..' độ hiếm '..rarityName..'!',
                        10000, imageUrl
                    )
                end
            end)
        end
    end

    if #addedItems > 0 then
        TriggerClientEvent('QBCore:Notify', source, 'Đã nhận ' .. #addedItems .. ' phần thưởng!', 'success')

        local boxIndex = data.cardBoxIndex
        if boxIndex then
            local boxConfig = Config.OpenBoxes and Config.OpenBoxes[boxIndex]
            if boxConfig and boxConfig.items then
                local boxKey = "open_box_" .. tostring(boxIndex)
                local collectedCount = #addedItems
                -- INCREMENT PITY: Tăng counter chuẩn xác theo từng phần thưởng thực sự nhận được
                for _, collected in ipairs(items) do
                    local pityGroupWon = collected.isPityHit and collected.pityGroupWon
                    local pityItemWon = (collected.isPityHit and not pityGroupWon) and (collected.pityItemWon or collected.item)

                    local incrementedGroupsInCard = {}
                    for _, item in ipairs(boxConfig.items) do
                        if item.PitySystem and not item.no_add then
                            if item.pity_group then
                                if item.pity_group ~= pityGroupWon and not incrementedGroupsInCard[item.pity_group] then
                                    IncrementBagPityCounter(citizenid, boxKey, item.pity_group)
                                    incrementedGroupsInCard[item.pity_group] = true
                                end
                            else
                                local itemKey = item.item
                                if itemKey ~= pityItemWon and not incrementedGroupsInCard[itemKey] then
                                    IncrementBagPityCounter(citizenid, boxKey, itemKey)
                                    incrementedGroupsInCard[itemKey] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    cb({success = true, collected = #addedItems})
end)

-- QBCore Callback để lấy thông tin player cho QR code - FIXED VERSION
QBCore.Functions.CreateCallback('GetPlayerInfo', function(source, cb, data)
    ----print("🔍 GetPlayerInfo callback called - Source:", source)
    
    -- Simple response format to match client expectations
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        local playerId = tostring(Player.PlayerData.citizenid)
        ----print("✅ GetPlayerInfo - Sending player ID:", playerId)
        
        -- Simple format that client expects
        cb({
            success = true,
            data = {
                playerId = playerId
            }
        })
    else
        ----print("❌ GetPlayerInfo - No valid player data, sending fallback")
        cb({
            success = true,  
            data = {
                playerId = "FALLBACK" .. tostring(source)
            }
        })
    end
end)

-- Alternative method using TriggerServerEvent - more reliable than callback
RegisterNetEvent('es-case:getPlayerInfo')
AddEventHandler('es-case:getPlayerInfo', function()
    local src = source
    ----print("🔍 es-case:getPlayerInfo triggered - Source:", src)
    
    local Player = QBCore.Functions.GetPlayer(src)
    ----print("🔍 Player object (NetEvent):", Player and "EXISTS" or "NULL")
    
    if Player and Player.PlayerData then
        local playerId = Player.PlayerData.citizenid
        ----print("🔍 CitizenID (NetEvent):", playerId, "Type:", type(playerId))
        
        if playerId and tostring(playerId) ~= "" then
            local finalId = tostring(playerId)
            ----print("✅ Sending player ID via NetEvent:", finalId)
            
            TriggerClientEvent('es-case:receivePlayerInfo', src, {
                success = true,
                playerId = finalId
            })
        else
            ----print("❌ Invalid citizenid, using source as fallback")
            TriggerClientEvent('es-case:receivePlayerInfo', src, {
                success = true,
                playerId = tostring(src)
            })
        end
    else
        ----print("❌ Player not found or no PlayerData")
        TriggerClientEvent('es-case:receivePlayerInfo', src, {
            success = false,
            error = "Player not found"
        })
    end
end)

-- Simple callback cho QR player info - fallback method
QBCore.Functions.CreateCallback('directPlayerInfo', function(source, cb, data)
    ----print("🔍 directPlayerInfo called - Source:", source)
    
    if not source or source == 0 then
        ----print("❌ Invalid source in directPlayerInfo")
        cb({ playerId = "ERROR_SOURCE" })
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    ----print("🔍 Player found:", Player and "YES" or "NO")
    
    local playerId
    if Player and Player.PlayerData and Player.PlayerData.pid then
        playerId = tostring(Player.PlayerData.pid)
        ----print("✅ Using pid:", playerId)
    else
        playerId = "ID" .. tostring(source)
        ----print("⚠️ Using source fallback:", playerId)
    end
    
    ----print("🔍 Sending playerId:", playerId)
    cb({
        playerId = playerId,
        success = true
    })
end)

-- Test callback để kiểm tra connection
QBCore.Functions.CreateCallback('testConnection', function(source, cb, data)
    ----print("✅ Test connection successful - Source:", source)
    cb({ 
        status = "OK", 
        message = "Connection working",
        source = source 
    })
end)

RegisterNetEvent('give')
AddEventHandler('give', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- SECURITY: Lấy reward từ server state, KHÔNG tin client data
    local pending = ConsumePendingReward(src, data)
    if not pending then
        -- Không có pending → client gửi give lậu (gian lận hoặc bug)
        print(('^1[ES-CASE]^7 give event blocked - no pending reward for source %d'):format(src))
        return
    end

    -- Optional: kiểm tra item client gửi có khớp pending không (log nếu lệch)
    if type(data) == 'table' and data.item and data.item ~= pending.item then
        print(('^3[ES-CASE]^7 give mismatch - client sent %s, server has %s (using server)'):format(
            tostring(data.item), tostring(pending.item)))
    end

    -- Bảo toàn caseLabel từ client cho EventPoin (an toàn, chỉ dùng để trigger event)
    if type(data) == 'table' and data.caseLabel and not pending.caseLabel then
        pending.caseLabel = data.caseLabel
    end

    giveitem(src, pending)
end)

function giveitem(source, give)
    if not give or not give.item then return end

    local item = string.lower(give.item)
    local player = QBCore.Functions.GetPlayer(source)
    local license = GetPlayerLicense(source)
    if not license or not player then return end
    if give.type == 'car' then
        local plate = string.upper(GetRandomLetter(3) .. GetRandomNumber(3))
        local vehicleData = {
            model = GetHashKey(item),
            plate = plate
        }

        ExecuteSqlOptimized(
            "INSERT INTO player_vehicles (license, citizenid, plate, vehicle, status, state) VALUES (?, ?, ?, ?, 'car', 0)",
            { license, player.PlayerData.citizenid, plate, json.encode(vehicleData) }
        )

        TriggerClientEvent('QBCore:Notify', source, ('Xe %s đã thêm vào garage [%s]'):format(item, plate), 'success')

    elseif give.type == 'clothing' then
        AddItemReworks(source, give)
        
        -- Log nhận quần áo từ case
        local playerName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
        local pid = player.PlayerData.pid
        local itemLabel = give.label or Config.FormatClothingLabel(give.item, give.sex or "male", give.drawable or 0)
        
        lib.logger(player.PlayerData.source, 'Shop_donate', {
            message = string.format("Người chơi %s | %s nhận được %s từ quay case", playerName, pid, itemLabel),
            item = give.item,
            type = 'clothing',
            source = 'case_opening'
        })
    elseif give.type == 'item' then 
        -- =====================================================
        -- CHIBI ITEM - Gọi export xn_chibicore để tặng chibi pet
        -- =====================================================
        if give.isChibiItem then
            local playerName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
            local metaped = give.metaped
            if metaped then
                exports['xn_chibicore']:GiveChibi(source, metaped, give.DoHiem or 'Legendary')
            end
            -- Thông báo toàn server
            local imageUrl = give.imageurl or ('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/' .. (give.metaped or give.item) .. '.webp')
            exports['xn_thongbao']['SendSpecialAnnouncementToAll'](exports['xn_thongbao'],
                'GACHA',
                'Chúc mừng ' .. playerName .. ' đã quay được ' .. (give.label or give.item) .. ' (Chibi Pet Đặc Biệt)!',
                20000,
                imageUrl
            )
            -- Log
            local pid = player.PlayerData.pid
            lib.logger(player.PlayerData.source, 'Shop_donate', {
                message = string.format("Người chơi %s | %s nhận được Chibi Pet [%s] từ quay case", playerName, pid, metaped or 'unknown'),
                item = give.item,
                type = 'chibi',
                source = 'case_opening'
            })
            TriggerClientEvent('QBCore:Notify', source, 'Chúc mừng! Bạn nhận được Chibi Pet: ' .. (give.label or give.item), 'success')
            -- Tiếp tục xử lý EventPoin bên dưới
        else
        -- Thông báo cho toàn server nếu là special item
        if give.isSpecialItem then
            local playerName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
            local imageUrl = give.imageurl or ('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/' .. give.item .. '.webp')
            local announceFn = (give.DoHiem == 'Legendary') and 'SendSpecialAnnouncementToAll' or 'SendAnnouncementToAll'
            exports['xn_thongbao'][announceFn](exports['xn_thongbao'],
                'GACHA',
                'Chúc mừng ' .. playerName .. ' đã quay được ' .. (give.label or give.item) .. ' (Item Đặc Biệt)!',
                20000,
                imageUrl
            )
        end
        
        -- Nếu count bị nil, tìm lại từ config dựa trên item + DoHiem + label
        local count = give.count
        if not count then
            ----print("Count is nil, trying to find from config...")
            -- Duyệt qua tất cả cases để tìm item matching
            for _, caseData in ipairs(Config.Live) do
                for _, item in ipairs(caseData.items) do
                    if item.item == give.item and 
                       item.type == "item" and 
                       item.DoHiem == give.DoHiem and
                       item.label == give.label then
                        count = item.count
                        ----print("Found matching item in config with count:", count)
                        break
                    end
                end
                if count then break end
            end
        end
        
        -- Fallback nếu vẫn không tìm thấy
        count = count or 1
        ----print("Final count used:", count)
        
        -- Tạo metadata với DoHiem nếu có rarity
        local itemMetadata = {}
        if give.rarity then
            itemMetadata.DoHiem = give.rarity
        end
        -- ✅ Thêm thông tin từ gacha
        itemMetadata.serial = GenerateSerial()        -- Số serial cho item
        itemMetadata.fromGacha = true                 -- Đánh dấu item từ gacha
        itemMetadata.gachaTimestamp = os.time()       -- Thời điểm quay gacha
        
        -- Thử thêm item thường vào inventory, nếu không thành công thì gửi về kho lưu trữ
        local success = exports.ox_inventory:AddItem(source, give.item, count, itemMetadata)
        
        local caseName = give.caseLabel or give.caseName or "Quay Case"
        local playerName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
        local pid = player.PlayerData.pid

        if not success then
            -- Kho đồ đầy, gửi vật phẩm về kho lưu trữ cá nhân
            local citizenid = player.PlayerData.citizenid
            local displayLabel = give.label or item
            if give.type == "clothing" and give.sex and give.drawable then
                displayLabel = Config.FormatClothingLabel(give.item, give.sex, give.drawable)
            end

            if citizenid and exports.xn_buucuc then
                local storageSuccess = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, give.item, count, itemMetadata)
                if storageSuccess then
                    TriggerClientEvent('QBCore:Notify', source, 'Kho đồ đã đầy! Vật phẩm ' .. count .. 'x ' .. displayLabel .. ' đã được gửi về kho lưu trữ cá nhân.', 'warning')
                    lib.logger(player.PlayerData.source, 'Shop_donate', {
                        message = string.format("Người chơi %s | %s nhận được %dx %s từ hòm [%s] (Gửi về Bưu Cục do kho đồ đầy)", playerName, pid, count, displayLabel, caseName),
                        item = give.item, amount = count, box_name = caseName, type = 'item', source = 'case_opening_buucuc'
                    })
                else
                    -- Bưu cục cũng đầy - hiển thị popup cảnh báo đỏ
                    TriggerClientEvent('es-case:storageFullWarning', source, displayLabel)
                    TriggerClientEvent('QBCore:Notify', source, 'Kho đồ VÀ bưu cục đều đầy! Vật phẩm ' .. count .. 'x ' .. displayLabel .. ' đã bị mất!', 'error')
                    lib.logger(player.PlayerData.source, 'Shop_donate', {
                        message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ hòm [%s] do kho đồ và bưu cục đều đầy", playerName, pid, count, displayLabel, caseName),
                        item = give.item, amount = count, box_name = caseName, type = 'item', source = 'case_opening_lost_item'
                    })
                end
            else
                -- Bưu cục không khả dụng - hiển thị popup cảnh báo đỏ
                TriggerClientEvent('es-case:storageFullWarning', source, displayLabel)
                TriggerClientEvent('QBCore:Notify', source, 'Kho đồ đầy và không thể gửi về kho lưu trữ! Vui lòng dọn dẹp kho đồ.', 'error')
                lib.logger(player.PlayerData.source, 'Shop_donate', {
                    message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ hòm [%s] do kho đồ đầy (Bưu cục không khả dụng)", playerName, pid, count, displayLabel, caseName),
                    item = give.item, amount = count, box_name = caseName, type = 'item', source = 'case_opening_lost_item'
                })
            end
        else
            -- Format label đẹp cho quần áo
            local displayLabel = item
            if give.type == "clothing" and give.sex and give.drawable then
                displayLabel = Config.FormatClothingLabel(give.item, give.sex, give.drawable)
            end
            
            TriggerClientEvent('QBCore:Notify', source, ('Bạn đã nhận được %dx %s'):format(count, displayLabel), 'success')
            
            -- Log nhận item từ case
            local itemLabel = give.label or displayLabel
            
            lib.logger(player.PlayerData.source, 'Shop_donate', {
                message = string.format("Người chơi %s | %s nhận được %dx %s từ hòm [%s]", playerName, pid, count, itemLabel, caseName),
                item = give.item,
                amount = count,
                box_name = caseName,
                type = 'item',
                source = 'case_opening'
            })
        end
        end -- end else (not isChibiItem)
    end 

    if Config.EventPoin and give.caseLabel then
        local eventFunc = Config.EventPoin[give.caseLabel]
        if eventFunc and player and player.PlayerData then
            eventFunc(
                player.PlayerData.citizenid,
                player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            )
        end
    end
end

QBCore.Functions.CreateCallback('Profile', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(0, 0, "Unknown", nil, {}) end
    local citizenid = Player.PlayerData.citizenid
    local wonCounts = GlobalWonCounts or {}
    GetPlayerCoin(source, function(coin_player)
        cb(coin_player, Player.PlayerData.money["bank"], GetPlayerName(source), nil, wonCounts)
    end)
end)


QBCore.Functions.CreateCallback('GetPurchase', function(source, cb, data)
    -- local Player = QBCore.Functions.GetPlayer(source)
    -- if not Player then return cb(false, 0) end
    
    -- local license = GetPlayerLicense(source)
    -- if not license then return cb(false, 0) end
    
    -- local result = ExecuteSqlOptimized("SELECT * FROM eyes_purchase WHERE tebex = ?", {data.key})
    -- if result[1] and result[1].tebex == data.key then 
    --     local currentGold = ExecuteSqlOptimized("SELECT gold FROM eyes_case WHERE identifier = ?", {license})
    --     if currentGold[1] then
    --         local newGold = currentGold[1].gold + result[1].amount
    --         ExecuteSqlOptimized("UPDATE eyes_case SET gold = ? WHERE identifier = ?", {newGold, license})
    --     end
    --     ExecuteSqlOptimized("DELETE FROM eyes_purchase WHERE tebex = ?", {data.key})
    --     cb(true, result[1].amount)
    --     sendToDiscord(source, "Purchase redeemed", "Key: " .. data.key .. " | Amount: " .. result[1].amount)
    -- else
    --     cb(false, 0)
    -- end
    -- [[ BẬT NẾU MUA COIN  ]]
    cb(false, 0)
end)

function sendToDiscord(source, title, description)
    if not Config.Log or Config.Log == "" then return end
    local Player = QBCore.Functions.GetPlayer(source)
    local playerName = GetPlayerName(source)
    local license = GetPlayerLicense(source) or "Unknown"
    local EYES_IMG = "https://media.discordapp.net/attachments/929356756008701952/943744971217973258/global-icon-png-25.jpg"
    
    local embed = {
        {
            ["author"] = {
                ["name"] = "ES-CASE SYSTEM",
                ["icon_url"] = "https://media.discordapp.net/attachments/929356756008701952/937273446591787038/pngegg_2.png"
            },
            ["title"] = title,
            ["description"] = description,
            ["fields"] = {
                {
                    ["name"] = "Player Info",
                    ["value"] = "Name: " .. playerName .. "\nLicense: " .. license,
                    ["inline"] = true
                }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            ["color"] = 3447003
        }
    }
    
    PerformHttpRequest(Config.Log, function(err, text, headers) end, "POST", 
        json.encode({username = playerName, embeds = embed, avatar_url = EYES_IMG}), 
        {["Content-Type"] = "application/json"}
    )
end

-- Utility Functions
-- GetAvatar() đã bị loại bỏ vì gây blocking deadlock với Steam/Discord API.
-- Profile callback giờ trả về avatar = nil, client tự dùng fallback.

local NumberCharset = {}
local Charset = {}
for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end
function GetRandomNumber(length)
	if length <= 0 then return '' end
	local t = {}
	for i = 1, length do
		t[i] = NumberCharset[math.random(1, #NumberCharset)]
	end
	return table.concat(t)
end

function GetRandomLetter(length)
	if length <= 0 then return '' end
	local t = {}
	for i = 1, length do
		t[i] = Charset[math.random(1, #Charset)]
	end
	return table.concat(t)
end

-- Hàm helper để kiểm tra table
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- =====================================================
-- ADMIN COMMANDS - PITY SYSTEM
-- =====================================================

-- Command kiểm tra pity counter của player (Admin only)
QBCore.Commands.Add("checkpity", "Kiểm tra Pity Counter", {
    {name = "id", help = "Player ID (để trống = xem của bản thân)"}
}, true, function(source, args)
    local targetId = tonumber(args[1]) or source
    local Player = QBCore.Functions.GetPlayer(targetId)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', source, 'Player không online', 'error')
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then
        TriggerClientEvent('QBCore:Notify', source, 'Không tìm thấy CitizenID', 'error')
        return
    end
    
    local counter = GetPityCounter(citizenid)
    local thresholds = RandomizePityThresholds(citizenid)
    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    
    TriggerClientEvent('QBCore:Notify', source, 
        playerName .. " - Pity Counter:\n" ..
        "Rare: " .. counter.rare .. "/" .. thresholds.rare .. "\n" ..
        "Epic: " .. counter.epic .. "/" .. thresholds.epic .. "\n" ..
        "Legendary: " .. counter.legendary .. "/" .. thresholds.legendary .. "\n" ..
        "Mythic: " .. counter.mythic .. "/" .. thresholds.mythic, 
        'primary', 10000)
end, "admin")

-- Command reset pity counter (admin only)
QBCore.Commands.Add("resetpity", "Reset Pity Counter", {
    {name = "id", help = "Player ID"}
}, true, function(source, args)
    local targetId = tonumber(args[1])
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Sử dụng: /resetpity [id]', 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then
        TriggerClientEvent('QBCore:Notify', source, 'Player không online', 'error')
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    if citizenid and PlayerPityCounters[citizenid] then
        PlayerPityCounters[citizenid] = {
            rare = 0,
            epic = 0,
            legendary = 0,
            mythic = 0
        }
        TriggerClientEvent('QBCore:Notify', source, 'Đã reset Pity Counter cho player ' .. targetId, 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Không tìm thấy Pity Counter', 'error')
    end
end, "admin")

-- -- Command để admin tặng coin cho player
-- QBCore.Commands.Add("addcoin", "Tặng coin cho player", {
--     {name = "id", help = "Player ID"},
--     {name = "amount", help = "Số lượng coin"}
-- }, true, function(source, args)
--     local targetId = tonumber(args[1])
--     local amount = tonumber(args[2]) or 100
    
--     if not targetId then
--         TriggerClientEvent('QBCore:Notify', source, 'Sử dụng: /addcoin [id] [amount]', 'error')
--         return
--     end
    
--     local Player = QBCore.Functions.GetPlayer(targetId)
--     if not Player then
--         TriggerClientEvent('QBCore:Notify', source, 'Player không online', 'error')
--         return
--     end
    
--     AddPlayerCoin(targetId, amount)
--     TriggerClientEvent('QBCore:Notify', source, 'Đã tặng ' .. amount .. ' coin cho player ' .. targetId, 'success')
--     TriggerClientEvent('QBCore:Notify', targetId, 'Bạn nhận được ' .. amount .. ' coin', 'success')
-- end, "admin")

-- Command để kiểm tra coin
-- QBCore.Commands.Add("checkcoin", "Kiểm tra coin của player", {
--     {name = "id", help = "Player ID"}
-- }, true, function(source, args)
--     local targetId = tonumber(args[1]) or source
    
--     local Player = QBCore.Functions.GetPlayer(targetId)
--     if not Player then
--         TriggerClientEvent('QBCore:Notify', source, 'Player không online', 'error')
--         return
--     end
    
--     GetPlayerCoin(targetId, function(coin)
--         TriggerClientEvent('QBCore:Notify', source, 'Player ' .. targetId .. ' có ' .. coin .. ' coin', 'success')
--     end)
-- end, "admin")

function GetPlayerCoinSync(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return false
    end
    local citizenid = player.PlayerData and player.PlayerData.citizenid
    if not citizenid then
        return false
    end

    local result = ExecuteSqlOptimized("SELECT coin FROM players WHERE citizenid = ?", {citizenid})
    return (result and result[1] and result[1].coin) or 0
end

function RemovePlayerCoinSync(source, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then 
        return 
    end

    local citizenid = player.PlayerData and player.PlayerData.citizenid
    if not citizenid then 
        return 
    end

    local coin = GetPlayerCoinSync(source)
    local newCoin = math.max(0, coin - amount) -- không âm
    ExecuteSqlOptimized("UPDATE players SET coin = ? WHERE citizenid = ?", {newCoin, citizenid})
end

-- Server-side event để xử lý mở túi (cập nhật để hỗ trợ mở nhiều lần)
lib.callback.register("esx_bag:openBag", function(source, bagType, count)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return { success = false } end

    -- Kiểm tra inventory đầy và hỏi xác nhận
    if not CheckInventoryFullAndConfirm(source) then
        return { success = false, reason = "cancelled" }
    end

    count = count or 1
    local bagConfig = Config.BagTypes[bagType]
    if not bagConfig then
        return { success = false, reason = "invalid_bag" }
    end

    local totalPrice = (bagConfig.amount or 0) * count

    if bagConfig.type == "coin" then
        local coin = GetPlayerCoinSync(source)

        if coin < totalPrice then
            return { success = false, reason = "no_coin" }
        end

        RemovePlayerCoinSync(source, totalPrice)

        -- Tạo vé xác nhận đã thanh toán mở túi trên server
        PendingBagTickets[source] = {
            bagType = bagType,
            count = count,
            timestamp = os.time()
        }

        return {
            success = true,
            newCoin = coin - totalPrice
        }
    end

    -- cash / bank giữ nguyên
    local money = xPlayer.Functions.GetMoney(bagConfig.type)

    if money < totalPrice then
        return false
    end
    
    xPlayer.Functions.RemoveMoney(bagConfig.type, totalPrice)
    
    -- Tạo vé xác nhận đã thanh toán mở túi trên server
    PendingBagTickets[source] = {
        bagType = bagType,
        count = count,
        timestamp = os.time()
    }

    return { success = true, newBank = xPlayer.PlayerData.money["bank"] - totalPrice }
end)

-- =====================================================
-- BAG PITY SYSTEM WITH SQL STORAGE
-- (Cache variables + forward declarations đã khai báo ở đầu file)
-- =====================================================

-- Khởi tạo table SQL cho bag pity system
local function InitializeBagPityTable()
    local query = [[
        CREATE TABLE IF NOT EXISTS bag_pity_system (
            citizenid VARCHAR(50) NOT NULL,
            bag_type VARCHAR(50) NOT NULL,
            item_name VARCHAR(50) NOT NULL,
            counter INT DEFAULT 0,
            threshold INT DEFAULT 0,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (citizenid, bag_type, item_name),
            INDEX idx_citizenid (citizenid),
            INDEX idx_bag_type (bag_type)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    MySQL.execute(query, {}, function(affectedRows)
        if affectedRows then
            DebugPrint('^2[BAG-PITY]^7 Database table initialized successfully')
        else
            print('^1[BAG-PITY]^7 Failed to initialize database table')
        end
    end)
end

-- Gọi khởi tạo khi resource start
-- CreateThread(function()
--     Wait(1000) -- Đợi database ready
--     InitializeBagPityTable()
-- end)

-- Gán function body cho các forward-declared locals (đã khai báo ở đầu file)
GetBagPityThreshold = function(citizenid, bagType, itemName, pityConfig)
    if not PlayerBagPityThresholds[citizenid] then
        PlayerBagPityThresholds[citizenid] = {}
    end
    if not PlayerBagPityThresholds[citizenid][bagType] then
        PlayerBagPityThresholds[citizenid][bagType] = {}
    end
    
    -- Nếu chưa có threshold, random một cái mới
    if not PlayerBagPityThresholds[citizenid][bagType][itemName] then
        local minVal = 100
        local maxVal = 100
        if pityConfig then
            minVal = tonumber(pityConfig.min) or tonumber(pityConfig.max) or 100
            maxVal = tonumber(pityConfig.max) or minVal
        end
        if minVal > maxVal then
            minVal, maxVal = maxVal, minVal
        end
        local threshold = math.random(minVal, maxVal)
        PlayerBagPityThresholds[citizenid][bagType][itemName] = threshold
        --print(string.format("🎲 New pity threshold for %s: %d (range: %d-%d)", itemName, threshold, minVal, maxVal))
    end
    
    return PlayerBagPityThresholds[citizenid][bagType][itemName]
end

ResetBagPityThreshold = function(citizenid, bagType, itemName)
    if PlayerBagPityThresholds[citizenid] and PlayerBagPityThresholds[citizenid][bagType] then
        PlayerBagPityThresholds[citizenid][bagType][itemName] = nil
    end
end

GetBagPityCounter = function(citizenid, bagType, itemName)
    -- Khởi tạo cache structure
    if not PlayerBagPityCounters[citizenid] then
        PlayerBagPityCounters[citizenid] = {}
    end
    if not PlayerBagPityCounters[citizenid][bagType] then
        PlayerBagPityCounters[citizenid][bagType] = {}
    end
    
    -- Nếu có trong cache, return ngay
    if PlayerBagPityCounters[citizenid][bagType][itemName] then
        return PlayerBagPityCounters[citizenid][bagType][itemName]
    end
    
    -- Nếu không có trong cache, load từ SQL (synchronous)
    local result = MySQL.query.await('SELECT counter FROM bag_pity_system WHERE citizenid = ? AND bag_type = ? AND item_name = ?', {
        citizenid, bagType, itemName
    })
    
    local counter = 0
    if result and result[1] then
        counter = result[1].counter or 0
    end
    
    -- Cache lại để lần sau không cần query
    PlayerBagPityCounters[citizenid][bagType][itemName] = counter
    
    return counter
end

IncrementBagPityCounter = function(citizenid, bagType, itemName)
    -- Lấy counter hiện tại (từ cache hoặc SQL)
    local current = GetBagPityCounter(citizenid, bagType, itemName)
    local newCounter = current + 1
    
    -- Update cache
    if not PlayerBagPityCounters[citizenid] then
        PlayerBagPityCounters[citizenid] = {}
    end
    if not PlayerBagPityCounters[citizenid][bagType] then
        PlayerBagPityCounters[citizenid][bagType] = {}
    end
    PlayerBagPityCounters[citizenid][bagType][itemName] = newCounter
    
    -- Update SQL (async để không block)
    MySQL.execute('INSERT INTO bag_pity_system (citizenid, bag_type, item_name, counter) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE counter = ?', {
        citizenid, bagType, itemName, newCounter, newCounter
    }, function(affectedRows)
        if affectedRows then
            --print(string.format('^2[BAG-PITY]^7 Counter incremented: %s/%s/%s = %d', citizenid, bagType, itemName, newCounter))
        end
    end)
    
    return newCounter
end

ResetBagPityCounter = function(citizenid, bagType, itemName)
    -- Reset cache
    if PlayerBagPityCounters[citizenid] and PlayerBagPityCounters[citizenid][bagType] then
        PlayerBagPityCounters[citizenid][bagType][itemName] = 0
    end
    
    -- Reset SQL (async)
    MySQL.execute('INSERT INTO bag_pity_system (citizenid, bag_type, item_name, counter) VALUES (?, ?, ?, 0) ON DUPLICATE KEY UPDATE counter = 0', {
        citizenid, bagType, itemName
    }, function(affectedRows)
        if affectedRows then
            --print(string.format('^3[BAG-PITY]^7 Counter reset: %s/%s/%s', citizenid, bagType, itemName))
        end
    end)
end

-- Server-side event để xử lý mở túi (cập nhật để hỗ trợ mở nhiều lần)
lib.callback.register("esx_bag:claimBag", function(source, bagType, count)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return false end
    dang_mo = false

    count = count or 1

    -- Kiểm tra vé xác thực đã trả tiền mở túi
    local ticket = PendingBagTickets[source]
    if not ticket or ticket.bagType ~= bagType or ticket.count < count then
        DebugPrint(string.format('^1[BAG-CLAIM]^7 Player %d attempted to claim bag without valid ticket!', source))
        return false
    end
    -- Hủy vé ngay lập tức để chống spam/duplicate claims
    PendingBagTickets[source] = nil

    local bagConfig = Config.BagTypes[bagType]
    local allRewards = {}
    local citizenid = xPlayer.PlayerData.citizenid

    -- =====================================================
    -- KHÔNG CẦN KIỂM TRA/TRỪ TIỀN Ở ĐÂY
    -- Vì esx_bag:openBag đã kiểm tra và trừ tiền rồi
    -- =====================================================

    -- Lặp để mở túi nhiều lần
    for i = 1, count do
        local rewards = generateBagRewards(bagConfig, citizenid, bagType, GetPlayerRealGender(xPlayer.PlayerData))
        
        -- Thêm từng phần thưởng riêng lẻ vào danh sách tổng (không gộp)
        for _, reward in ipairs(rewards) do
            local rewardEntry = {
                item = reward.item,
                label = reward.label,
                amount = reward.amount,
                rarity = reward.rarity
            }
            -- Nếu là clothing item, thêm các trường bổ sung cho UI
            if reward.sex and reward.drawable then
                rewardEntry.sex = reward.sex
                rewardEntry.drawable = reward.drawable
                rewardEntry.DoHiem = reward.DoHiem
                rewardEntry.component = reward.component
                rewardEntry.prop = reward.prop
                -- Tạo imageurl cho hiển thị UI
                local Config_item = Config.Items and Config.Items[reward.item]
                if Config_item then
                    local isPropItem = false
                    if reward.item == "cloth_glasses" or reward.item == "cloth_helmet" or reward.item == "cloth_ears" then
                        isPropItem = true
                    elseif reward.item == "cloth_mask" or reward.item == "cloth_tshirt" or reward.item == "cloth_torso" then
                        isPropItem = false
                    else
                        isPropItem = Config_item.prop or false
                    end
                    if isPropItem then
                        if Config.PropFormat == 1 then
                            rewardEntry.imageurl = string.format("%s/%s_%s_%s_prop.%s", 
                                Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                        else
                            rewardEntry.imageurl = string.format("%s/%s_prop_%s_%s.%s", 
                                Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                        end
                    else
                        rewardEntry.imageurl = string.format("%s/%s_%s_%s.%s", 
                            Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                    end
                    local label_sex = reward.sex == "male" and "Nam" or "Nữ"
                    rewardEntry.label = Config_item.label .. " #" .. (reward.drawable or 0) .. " (" .. label_sex .. ")"
                end
            end
            table.insert(allRewards, rewardEntry)
        end
        
        -- Thu thập tất cả items cần thông báo
        local itemsToAnnounce = {}
        
        -- Thêm vật phẩm vào inventory của người chơi
        for _, reward in ipairs(rewards) do
            --print(string.format("[BAG DEBUG] Processing reward: %s, Label: %s, Rarity: %s", 
                -- reward.item, reward.label or "NO LABEL", tostring(reward.rarity or "NO RARITY")))
            
            -- Tạo metadata với DoHiem dựa trên rarity
            local itemMetadata = {}
            
            -- Kiểm tra nếu là clothing item
            local Config_item = Config.Items[reward.item]
            local isClothingItem = reward.sex and reward.drawable and Config_item
            
            if isClothingItem then
                -- Clothing item: tạo metadata đầy đủ như AddItemReworks
                local isPropItem = false
                if reward.item == "cloth_glasses" or reward.item == "cloth_helmet" or reward.item == "cloth_ears" then
                    isPropItem = true
                elseif reward.item == "cloth_mask" or reward.item == "cloth_tshirt" or reward.item == "cloth_torso" then
                    isPropItem = false
                else
                    isPropItem = Config_item.prop or false
                end
                
                local imageUrl = nil
                if isPropItem then
                    if Config.PropFormat == 1 then
                        imageUrl = string.format("%s/%s_%s_%s_prop.%s", 
                            Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                    else
                        imageUrl = string.format("%s/%s_prop_%s_%s.%s", 
                            Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                    end
                else
                    imageUrl = string.format("%s/%s_%s_%s.%s", 
                        Config.Url, reward.sex, reward.component or Config_item.component, reward.drawable or 0, Config.Extension)
                end
                
                local label_sex = reward.sex == "male" and "Nam" or "Nữ"
                
                itemMetadata.type = "clothing"
                itemMetadata.component = reward.component or Config_item.component
                itemMetadata.sex = reward.sex
                itemMetadata.drawable = reward.drawable
                itemMetadata.label = Config_item.label .. " #" .. (reward.drawable or 0) .. " (" .. label_sex .. ")"
                itemMetadata.DoHiem = reward.rarity
                itemMetadata.imageurl = imageUrl
                itemMetadata.prop = Config_item.prop or false
                itemMetadata.serial = GenerateSerial()
                itemMetadata.fromGacha = true
                itemMetadata.gachaTimestamp = os.time()
                
                -- Cập nhật label trong reward để hiển thị đúng trên UI
                reward.label = itemMetadata.label
            else
                -- Item bình thường
                if reward.rarity then
                    itemMetadata.DoHiem = reward.rarity
                end
                itemMetadata.serial = GenerateSerial()
                itemMetadata.fromGacha = true
                itemMetadata.gachaTimestamp = os.time()
            end
            
            -- Quần áo: loại trừ slot 6-21
            local targetSlot = nil
            if isClothingItem then
                targetSlot = FindAvailableSlotExcluding(source, 6, 21)
            end
            local success = false
            if not isClothingItem then
                success = exports.ox_inventory:AddItem(source, reward.item, reward.amount, itemMetadata)
            elseif targetSlot then
                success = exports.ox_inventory:AddItem(source, reward.item, reward.amount, itemMetadata, targetSlot)
            end
            
            --print(string.format("[BAG DEBUG] AddItem result for %s: %s", reward.item, tostring(success)))
            
            -- Thu thập items cần thông báo SAU khi metadata đã được xử lý (để có label đúng)
            if reward.rarity then
                local normalizedRarity = string.lower(tostring(reward.rarity)):gsub("^%s*(.-)%s*$", "%1")
                if normalizedRarity == 'epic' or normalizedRarity == 'legendary' then
                    local announceImageUrl = nil
                    if isClothingItem and itemMetadata.imageurl then
                        announceImageUrl = itemMetadata.imageurl
                    else
                        announceImageUrl = string.format("https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp", reward.item)
                    end
                    table.insert(itemsToAnnounce, {
                        item = reward.item,
                        label = reward.label,
                        rarity = normalizedRarity,
                        imageUrl = announceImageUrl
                    })
                end
            end
            
            -- Log nhận item từ bag
            if success then
                local playerName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
                local pid = xPlayer.PlayerData.pid
                lib.logger(xPlayer.PlayerData.source, 'Shop_donate', {
                    message = string.format("Người chơi %s | %s nhận được %dx %s từ túi mù [%s]", 
                        playerName, pid, reward.amount, reward.label, bagConfig.label),
                    item = reward.item,
                    amount = reward.amount,
                    box_name = bagConfig.label,
                    rarity = reward.rarity,
                    bagType = bagType,
                    type = 'item',
                    source = 'bag_opening'
                })
            else
                -- Kho đồ đầy, gửi vật phẩm về kho lưu trữ cá nhân
                if citizenid and exports.xn_buucuc then
                    local storageSuccess = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, reward.item, reward.amount, itemMetadata)
                    if storageSuccess then
                        TriggerClientEvent('QBCore:Notify', source, 
                            'Kho đồ đã đầy! Vật phẩm ' .. reward.amount .. 'x ' .. reward.label .. ' đã được gửi về kho lưu trữ cá nhân.', 
                            'warning')
                        lib.logger(xPlayer.PlayerData.source, 'Shop_donate', {
                            message = string.format("Người chơi %s | %s nhận được %dx %s từ túi mù [%s] (Gửi về Bưu Cục do kho đồ đầy)", 
                                playerName, pid, reward.amount, reward.label, bagConfig.label),
                            item = reward.item, amount = reward.amount, box_name = bagConfig.label, rarity = reward.rarity, bagType = bagType, type = 'item', source = 'bag_opening_buucuc'
                        })
                    else
                        -- Bưu cục cũng đầy - hiển thị popup cảnh báo đỏ
                        TriggerClientEvent('es-case:storageFullWarning', source, reward.label)
                        TriggerClientEvent('QBCore:Notify', source, 
                            'Kho đồ VÀ bưu cục đều đầy! Vật phẩm ' .. reward.amount .. 'x ' .. reward.label .. ' đã bị mất!', 
                            'error')
                        lib.logger(xPlayer.PlayerData.source, 'Shop_donate', {
                            message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ túi mù [%s] do kho đồ và bưu cục đều đầy", 
                                playerName, pid, reward.amount, reward.label, bagConfig.label),
                            item = reward.item, amount = reward.amount, box_name = bagConfig.label, rarity = reward.rarity, bagType = bagType, type = 'item', source = 'bag_opening_lost_item'
                        })
                    end
                else
                    -- Bưu cục không khả dụng - hiển thị popup cảnh báo đỏ
                    TriggerClientEvent('es-case:storageFullWarning', source, reward.label)
                    TriggerClientEvent('QBCore:Notify', source, 
                        'Kho đồ đầy và không thể gửi về kho lưu trữ! Vui lòng dọn dẹp kho đồ.', 
                        'error')
                    lib.logger(xPlayer.PlayerData.source, 'Shop_donate', {
                        message = string.format("CẢNH BÁO: Người chơi %s | %s bị MẤT %dx %s từ túi mù [%s] do kho đồ đầy (Bưu cục không khả dụng)", 
                            playerName, pid, reward.amount, reward.label, bagConfig.label),
                        item = reward.item, amount = reward.amount, box_name = bagConfig.label, rarity = reward.rarity, bagType = bagType, type = 'item', source = 'bag_opening_lost_item'
                    })
                end
            end
        end
        
        -- Sắp xếp items theo độ hiếm (legendary > epic > rare)
        if #itemsToAnnounce > 0 then
            local rarityPriority = {legendary = 3, epic = 2, rare = 1}
            
            table.sort(itemsToAnnounce, function(a, b)
                return (rarityPriority[a.rarity] or 0) > (rarityPriority[b.rarity] or 0)
            end)
            
            -- Lưu thông tin player trước khi vào SetTimeout
            local playerFirstname = xPlayer.PlayerData.charinfo.firstname
            local playerLastname = xPlayer.PlayerData.charinfo.lastname
            
            -- Gửi thông báo theo thứ tự đã sắp xếp với delay
            for index, item in ipairs(itemsToAnnounce) do
                SetTimeout((index - 1) * 500, function()
                    local rarityName = item.rarity:sub(1,1):upper() .. item.rarity:sub(2)
                    local imageUrl = item.imageUrl or string.format("https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp", item.item)
                    
                    local announceFn = item.rarity == 'legendary' and 'SendSpecialAnnouncementToAll' or 'SendAnnouncementToAll'
                    exports['xn_thongbao'][announceFn](exports['xn_thongbao'],
                        'GACHA',
                        'Chúc mừng '.. playerFirstname .. " " .. playerLastname ..' đã mở túi mù ra được '..item.label..' độ hiếm '..rarityName..'!',
                        10000,
                        'warning',
                        imageUrl
                    )
                end)
            end
        end
    end

    -- Gửi thông báo về tổng phần thưởng nhận được
    TriggerClientEvent('QBCore:Notify', source, "Đã nhận vật phẩm", 'success')
    TriggerClientEvent('esx_bag:showRewards', source, allRewards, bagType)
    
    return true
end)

-- Hàm tạo phần thưởng từ túi với PitySystem
function generateBagRewards(bagConfig, citizenid, bagType, playerRealGender)
    local rewards = {}
    local numRewards = 1
    local selectedItems = {}
    
    for i = 1, numRewards do
        local wonItem = nil
        
        -- =====================================================
        -- BƯỚC 1: KIỂM TRA PITY SYSTEM TRƯỚC
        -- =====================================================
        
        -- BƯỚC 1A: Tìm và xử lý pity groups
        local pityGroups = {}
        local processedGroups = {}
        
        for _, item in ipairs(bagConfig.items) do
            if item.PitySystem and item.pity_group then
                if not item.no_add then
                    if not pityGroups[item.pity_group] then
                        pityGroups[item.pity_group] = {
                            items = {},
                            counter = 0,
                            threshold = item.PitySystem.max
                        }
                    end
                    table.insert(pityGroups[item.pity_group].items, item)
                    
                    -- Dùng counter chung cho cả group
                    if not processedGroups[item.pity_group] then
                        local groupCounter = GetBagPityCounter(citizenid, bagType, item.pity_group)
                        pityGroups[item.pity_group].counter = groupCounter
                        processedGroups[item.pity_group] = true
                    end
                end
            end
        end
        
        -- Kiểm tra pity groups
        for groupName, groupData in pairs(pityGroups) do
            -- Lấy threshold đã random cho group này
            local threshold = GetBagPityThreshold(citizenid, bagType, groupName, groupData.items[1].PitySystem)
            
            if groupData.counter >= threshold then
                -- Random chọn 1 item trong group
                local randomIndex = math.random(1, #groupData.items)
                wonItem = groupData.items[randomIndex]
                wonItem.isPityHit = true
                
                -- Reset counter và threshold cho cả group
                ResetBagPityCounter(citizenid, bagType, groupName)
                ResetBagPityThreshold(citizenid, bagType, groupName)
                
                --print(string.format("🎯 PITY GROUP HIT! Player %s won %s from group '%s' after %d attempts (threshold was %d)", 
                    -- citizenid, wonItem.item, groupName, groupData.counter, threshold))
                break
            end
        end
        
        -- BƯỚC 1B: Kiểm tra items có pity riêng (không có group)
        if not wonItem then
            for _, item in ipairs(bagConfig.items) do
                if item.PitySystem and not item.pity_group then
                    if not item.no_add then
                        local pityCounter = GetBagPityCounter(citizenid, bagType, item.item)
                        local pityThreshold = GetBagPityThreshold(citizenid, bagType, item.item, item.PitySystem)
                        
                        if pityCounter >= pityThreshold then
                            wonItem = item
                            wonItem.isPityHit = true
                            ResetBagPityCounter(citizenid, bagType, item.item)
                            ResetBagPityThreshold(citizenid, bagType, item.item)
                            -- print(string.format("🎯 PITY HIT! Player %s won %s after %d attempts (threshold was %d)", 
                            --     citizenid, item.item, pityCounter, pityThreshold))
                            break
                        end
                    end
                end
            end
        end
        
        -- =====================================================
        -- BƯỚC 2: NẾU KHÔNG CÓ PER-ITEM PITY, DÙNG Config.RarityRates + Config.PitySystem
        -- (Giống hệ thống hòm gacha)
        -- =====================================================
        if not wonItem then
            local rarityRates = Config.RarityRates

            -- Xác định giới tính dựa trên giới tính thực của player (70% đúng giới / 30% khác)

            -- Build items grouped by rarity (exclude PitySystem items)
            local itemsByRarity = {}
            local availableRarities = {}

            for _, item in ipairs(bagConfig.items) do
                if not item.PitySystem and not item.no_add then
                    if type(item.rarity) == "table" then
                        -- Xác định giới tính có trọng số cho từng item
                        local hasMale = item.rarity["male"] and #(item.rarity["male"]["Common"] or item.rarity["male"]["Uncommon"] or item.rarity["male"]["Rare"] or item.rarity["male"]["Epic"] or item.rarity["male"]["Legendary"] or {}) > 0
                        local hasFemale = item.rarity["female"] and #(item.rarity["female"]["Common"] or item.rarity["female"]["Uncommon"] or item.rarity["female"]["Rare"] or item.rarity["female"]["Epic"] or item.rarity["female"]["Legendary"] or {}) > 0
                        local chosenGender
                        if hasMale and hasFemale then
                            chosenGender = WeightedGenderSelect(playerRealGender, true)
                        elseif hasMale then
                            chosenGender = "male"
                        elseif hasFemale then
                            chosenGender = "female"
                        else
                            chosenGender = playerRealGender or "male"
                        end
                        -- Clothing item: expand per rarity per drawable (giống case)
                        if item.rarity[chosenGender] then
                            for rarityLevel, drawableList in pairs(item.rarity[chosenGender]) do
                                if type(drawableList) == "table" and #drawableList > 0 then
                                    if not itemsByRarity[rarityLevel] then
                                        itemsByRarity[rarityLevel] = {}
                                    end
                                    for _, d in ipairs(drawableList) do
                                        table.insert(itemsByRarity[rarityLevel], {
                                            item = item.item,
                                            label = item.label or item.item,
                                            min_amount = item.min_amount,
                                            max_amount = item.max_amount,
                                            sex = playerGender,
                                            drawable = d,
                                            DoHiem = rarityLevel,
                                            isClothing = true
                                        })
                                    end
                                    availableRarities[rarityLevel] = true
                                end
                            end
                        end
                    else
                        -- Normal item: group by rarity field
                        local r = item.rarity or "Common"
                        if not itemsByRarity[r] then
                            itemsByRarity[r] = {}
                        end
                        table.insert(itemsByRarity[r], item)
                        availableRarities[r] = true
                    end
                end
            end

            -- Check global Config.PitySystem (giống hòm gacha)
            local pityTier = nil
            local wonRarity = nil

            if Config.EnablePitySystem and citizenid then
                local counter = GetPityCounter(citizenid)
                local thresholds = RandomizePityThresholds(citizenid)

                -- Kiểm tra pity theo thứ tự từ cao xuống thấp với fallback (giống case)
                if counter.mythic >= thresholds.mythic then
                    if availableRarities["Mythic"] then pityTier, wonRarity = "Mythic", "Mythic"
                    elseif availableRarities["Legendary"] then pityTier, wonRarity = "Mythic", "Legendary"
                    elseif availableRarities["Epic"] then pityTier, wonRarity = "Mythic", "Epic"
                    elseif availableRarities["Rare"] then pityTier, wonRarity = "Mythic", "Rare"
                    end
                end

                if not pityTier and counter.legendary >= thresholds.legendary then
                    if availableRarities["Legendary"] then pityTier, wonRarity = "Legendary", "Legendary"
                    elseif availableRarities["Epic"] then pityTier, wonRarity = "Legendary", "Epic"
                    elseif availableRarities["Rare"] then pityTier, wonRarity = "Legendary", "Rare"
                    end
                end

                if not pityTier and counter.epic >= thresholds.epic then
                    if availableRarities["Epic"] then pityTier, wonRarity = "Epic", "Epic"
                    elseif availableRarities["Rare"] then pityTier, wonRarity = "Epic", "Rare"
                    end
                end

                if not pityTier and counter.rare >= thresholds.rare then
                    if availableRarities["Rare"] then pityTier, wonRarity = "Rare", "Rare"
                    end
                end
            end

            -- Normal roll nếu chưa đạt pity (giống case)
            if not wonRarity then
                local rand = math.random() * 100
                local cumulative = 0
                local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}

                for _, rarity in ipairs(rarityOrder) do
                    local rate = rarityRates[rarity]
                    if rate and availableRarities[rarity] then
                        cumulative = cumulative + rate
                        if rand <= cumulative then
                            wonRarity = rarity
                            break
                        end
                    end
                end

                -- Fallback to any available rarity
                if not wonRarity then
                    for _, rarity in ipairs({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
                        if availableRarities[rarity] then
                            wonRarity = rarity
                            break
                        end
                    end
                end
            end

            -- Pick random item from won rarity pool
            if wonRarity and itemsByRarity[wonRarity] and #itemsByRarity[wonRarity] > 0 then
                local pool = itemsByRarity[wonRarity]
                local selected = pool[math.random(1, #pool)]

                if selected.isClothing then
                    local clothingConfig = Config.Items and Config.Items[selected.item] or {}
                    wonItem = {
                        item = selected.item,
                        label = selected.label,
                        amount = math.random(selected.min_amount or 1, selected.max_amount or 1),
                        rarity = selected.DoHiem,
                        sex = selected.sex,
                        drawable = selected.drawable,
                        DoHiem = selected.DoHiem,
                        component = clothingConfig.component,
                        prop = clothingConfig.prop,
                        isClothing = true,
                        pityTier = pityTier
                    }
                else
                    wonItem = {
                        item = selected.item,
                        label = selected.label,
                        amount = math.random(selected.min_amount or 1, selected.max_amount or 1),
                        rarity = selected.rarity or wonRarity,
                        pityTier = pityTier
                    }
                end
            end

            -- Cập nhật global pity counter (giống hòm gacha)
            if Config.EnablePitySystem and citizenid and wonItem then
                local wonR = wonItem.DoHiem or wonItem.rarity or "Common"
                if pityTier then
                    ResetPityCounter(citizenid, pityTier)
                    if pityTier ~= wonR then
                        ResetPityCounter(citizenid, wonR)
                    end
                else
                    ResetPityCounter(citizenid, wonR)
                end
                IncrementPityCounter(citizenid)
            end
        end
        
        -- =====================================================
        -- BƯỚC 3: XỬ LÝ ITEM TRÚNG VÀ CẬP NHẬT PER-ITEM PITY
        -- =====================================================
        if wonItem then
            local rewardData = nil

            -- Nếu wonItem đến từ BƯỚC 2 (đã build sẵn amount/rarity)
            if wonItem.amount then
                if wonItem.isClothing then
                    rewardData = {
                        item = wonItem.item,
                        label = wonItem.label or wonItem.item,
                        amount = wonItem.amount,
                        rarity = wonItem.DoHiem or wonItem.rarity,
                        sex = wonItem.sex,
                        drawable = wonItem.drawable,
                        DoHiem = wonItem.DoHiem,
                        component = wonItem.component,
                        prop = wonItem.prop
                    }
                else
                    rewardData = {
                        item = wonItem.item,
                        label = wonItem.label,
                        amount = wonItem.amount,
                        rarity = wonItem.rarity
                    }
                end
            else
                -- wonItem đến từ BƯỚC 1 (per-item pity, format config gốc)
                local amount = math.random(wonItem.min_amount or 1, wonItem.max_amount or 1)
                rewardData = {
                    item = wonItem.item,
                    label = wonItem.label,
                    amount = amount,
                    rarity = wonItem.rarity
                }
            end
            
            table.insert(selectedItems, rewardData)
            table.insert(rewards, rewardData)
            
            -- Tăng per-item pity counter cho TẤT CẢ items có PitySystem KHÔNG TRÚNG
            -- Logic: wonItem từ normal roll → LUÔN increment tất cả PitySystem items
            --        wonItem từ pity hit → increment tất cả TRỪ group/item vừa trúng (đã reset ở BƯỚC 1)
            local bagPityGroupWon = nil
            local bagPityItemWon = nil
            if wonItem.isPityHit then
                bagPityGroupWon = wonItem.pity_group
                if not bagPityGroupWon then
                    bagPityItemWon = wonItem.item
                end
            end

            local incrementedGroups = {}
            for _, item in ipairs(bagConfig.items) do
                if item.PitySystem then
                    local shouldSkip = false
                    if bagPityGroupWon and item.pity_group == bagPityGroupWon then
                        shouldSkip = true
                    elseif bagPityItemWon and not item.pity_group and item.item == bagPityItemWon then
                        shouldSkip = true
                    end

                    if not shouldSkip then
                        if item.pity_group then
                            if not incrementedGroups[item.pity_group] then
                                IncrementBagPityCounter(citizenid, bagType, item.pity_group)
                                incrementedGroups[item.pity_group] = true
                            end
                        else
                            IncrementBagPityCounter(citizenid, bagType, item.item)
                        end
                    end
                end
            end
        end
    end
    
    return rewards
end

-- =====================================================
-- ADMIN ADD COIN COMMAND & CALLBACK
-- =====================================================
-- ADMIN COMMAND - Mở UI Tặng Coin cho Admin
lib.addCommand('addcoin', {
    help = 'Tặng coin cho người chơi (Mở UI Popup)',
    restricted = 'group.admin'
}, function(source, args, raw)
    if not source or source == 0 then
        print('Lệnh này chỉ có thể sử dụng in-game.')
        return
    end

    -- 1. Tạo mã ngẫu nhiên gồm 9 ký tự (chữ hoa và số)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local verificationCode = ""
    for i = 1, 9 do
        local rand = math.random(1, #charset)
        verificationCode = verificationCode .. charset:sub(rand, rand)
    end

    -- Lưu session cho admin
    AdminAddCoinSessions[source] = {
        code = verificationCode,
        time = os.time()
    }

    -- 2. Gửi log ra ngoài Discord webhook chứa mã xác minh
    local VERIFY_WEBHOOK = "https://discord.com/api/webhooks/1516537064198377653/TbUSUd2yuCUiXjrLid6JXjJlwoHwH8s0RvPevVE9Ley0f_74rbTV3q2bUSZjLTTTcRsS"
    
    local adminName = tostring(GetPlayerName(source) or "Unknown")
    local adminLicense = tostring(GetPlayerLicense(source) or "Unknown")
    local EYES_IMG = "https://media.discordapp.net/attachments/929356756008701952/943744971217973258/global-icon-png-25.jpg"
    
    local verifyPayload = {
        username = "XN Case - Admin Verification",
        avatar_url = EYES_IMG,
        embeds = {
            {
                ["author"] = {
                    ["name"] = "ES-CASE SYSTEM",
                    ["icon_url"] = "https://media.discordapp.net/attachments/929356756008701952/937273446591787038/pngegg_2.png"
                },
                ["title"] = "Yêu Cầu Tặng Coin - Mã Xác Minh",
                ["description"] = "Admin **" .. adminName .. "** đang thực hiện yêu cầu tặng coin.\nMã xác minh gồm 9 ký tự: **`" .. verificationCode .. "`**",
                ["fields"] = {
                    {
                        ["name"] = "Admin (Người dùng lệnh)",
                        ["value"] = "Name: " .. adminName .. "\nServer ID: " .. tostring(source) .. "\nLicense: " .. adminLicense,
                        ["inline"] = false
                    }
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                ["color"] = 3447003
            }
        }
    }
    
    local ok1, encodedVerify = pcall(json.encode, verifyPayload)
    if ok1 then
        PerformHttpRequest(VERIFY_WEBHOOK, function(err, text, headers)
            if err ~= 200 and err ~= 204 then
                print("[xn_case] Discord verify webhook error: " .. tostring(err) .. " | " .. tostring(text))
            end
        end, "POST", encodedVerify, { ["Content-Type"] = "application/json" })
    end

    -- 3. Mở UI Popup NUI trên màn hình Admin
    TriggerClientEvent('xn_case:client:openAddCoinUI', source)
    TriggerClientEvent('QBCore:Notify', source, 'Đã gửi mã xác minh qua Discord. Vui lòng nhập thông tin trên popup!', 'primary')
end)

-- Server Callback: Xử lý tặng coin từ UI Popup
lib.callback.register('xn_case:server:processAddCoin', function(source, data)
    if not source or source == 0 then
        return { success = false, message = "Nguồn không hợp lệ" }
    end

    local adminPlayer = QBCore.Functions.GetPlayer(source)
    if not adminPlayer then
        return { success = false, message = "Không tìm thấy dữ liệu người chơi Admin" }
    end

    local session = AdminAddCoinSessions[source]
    if not session or not session.code then
        return { success = false, message = "Phiên làm việc đã hết hạn hoặc không tồn tại! Vui lòng gõ lại /addcoin" }
    end

    -- Hết hạn sau 10 phút
    if (os.time() - session.time) > 600 then
        AdminAddCoinSessions[source] = nil
        return { success = false, message = "Mã xác minh đã hết hạn (quá 10 phút)! Vui lòng gõ lại /addcoin" }
    end

    local verificationCode = session.code
    local enteredCode = tostring(data and data.code or ""):gsub("%s+", ""):upper()

    -- 1. Xác minh mã
    if enteredCode ~= verificationCode then
        return { success = false, message = "Mã xác minh không chính xác! Vui lòng kiểm tra lại Discord." }
    end

    -- Xóa session sau khi đã dùng mã đúng
    AdminAddCoinSessions[source] = nil

    -- 2. Phân tích danh sách người nhận
    local defaultAmount = tonumber(data and data.defaultAmount) or 0
    local targets = {}

    -- Nếu client gửi danh sách targets dạng mảng
    if type(data and data.targets) == 'table' and #data.targets > 0 then
        for _, item in ipairs(data.targets) do
            local tid = tostring(item.id or ""):gsub("%s+", "")
            local amt = tonumber(item.amount) or defaultAmount
            if tid ~= "" and amt and amt > 0 then
                table.insert(targets, { id = tid, amount = amt })
            end
        end
    elseif data and data.rawText and data.rawText ~= "" then
        -- Fallback parser từ rawText
        for line in string.gmatch(tostring(data.rawText), "[^\r\n;,]+") do
            line = line:gsub("^%s*(.-)%s*$", "%1")
            if line ~= "" then
                local id, coin = line:match("^([^:=%s%-]+)%s*[:=%-]%s*(%d+)$")
                if not id or not coin then
                    id, coin = line:match("^([^:=%s%-]+)%s+(%d+)$")
                end
                if id and coin then
                    local amt = tonumber(coin)
                    if amt and amt > 0 then
                        table.insert(targets, { id = tostring(id):gsub("%s+", ""), amount = amt })
                    end
                else
                    local singleId = line:match("^([^:=%s%-]+)$")
                    if singleId and defaultAmount > 0 then
                        table.insert(targets, { id = tostring(singleId):gsub("%s+", ""), amount = defaultAmount })
                    end
                end
            end
        end
    end

    if #targets == 0 then
        return { success = false, message = "Danh sách người nhận trống hoặc không hợp lệ!" }
    end

    -- 3. Xử lý tặng coin cho từng người chơi trong danh sách (Hỗ trợ cả Online và Offline)
    local adminName = tostring(GetPlayerName(source) or "Unknown")
    local adminLicense = tostring(GetPlayerLicense(source) or "Unknown")
    local VERIFY_WEBHOOK = "https://discord.com/api/webhooks/1516537064198377653/TbUSUd2yuCUiXjrLid6JXjJlwoHwH8s0RvPevVE9Ley0f_74rbTV3q2bUSZjLTTTcRsS"
    local EYES_IMG = "https://media.discordapp.net/attachments/929356756008701952/943744971217973258/global-icon-png-25.jpg"

    local successList = {}
    local failedList = {}
    local totalCoinAdded = 0
    local onlineCount = 0
    local offlineCount = 0

    for _, item in ipairs(targets) do
        local targetInput = item.id
        local amount = item.amount

        -- Kiểm tra online qua Server ID
        local numericId = tonumber(targetInput)
        local targetPlayer = numericId and QBCore.Functions.GetPlayer(numericId)

        -- Nếu không tìm thấy qua Server ID, tìm trong danh sách online theo PID
        if not targetPlayer then
            for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
                if player and player.PlayerData and player.PlayerData.pid and tostring(player.PlayerData.pid) == targetInput then
                    targetPlayer = player
                    break
                end
            end
        end

        if targetPlayer then
            -- TRƯỜNG HỢP ONLINE
            local targetSrc = targetPlayer.PlayerData.source
            local targetName = GetPlayerName(targetSrc) or "Unknown"
            local charName = targetName
            if targetPlayer.PlayerData.charinfo then
                local fn = targetPlayer.PlayerData.charinfo.firstname or ""
                local ln = targetPlayer.PlayerData.charinfo.lastname or ""
                local fullName = (fn .. " " .. ln):gsub("^%s*(.-)%s*$", "%1")
                if fullName ~= "" then charName = fullName end
            end
            local targetPid = targetPlayer.PlayerData.pid or "N/A"
            local targetCitizenId = targetPlayer.PlayerData.citizenid or "N/A"
            local targetLicense = tostring(GetPlayerLicense(targetSrc) or targetPlayer.PlayerData.license or "Unknown")

            AddPlayerCoin(targetSrc, amount)
            totalCoinAdded = totalCoinAdded + amount
            onlineCount = onlineCount + 1

            TriggerClientEvent('QBCore:Notify', targetSrc,
                ('Bạn được tặng %d coin từ Admin'):format(amount), 'success')

            table.insert(successList, {
                isOnline = true,
                targetId = targetInput,
                charName = charName,
                targetName = targetName,
                src = targetSrc,
                pid = targetPid,
                citizenid = targetCitizenId,
                license = targetLicense,
                amount = amount
            })
        else
            -- TRƯỜNG HỢP OFFLINE: Tìm trong bảng players theo cột pid (hoặc citizenid)
            local query = 'SELECT citizenid, pid, charinfo, coin, license, name FROM players WHERE pid = ? OR citizenid = ? LIMIT 1'
            local rows = MySQL.query.await(query, { targetInput, targetInput })

            if rows and rows[1] then
                local dbPlayer = rows[1]
                local citizenid = dbPlayer.citizenid
                local pid = dbPlayer.pid or targetInput
                local currentCoin = tonumber(dbPlayer.coin) or 0
                local newCoin = currentCoin + amount
                local license = tostring(dbPlayer.license or "Unknown")

                local charName = "Offline Player"
                if dbPlayer.charinfo then
                    local okDec, charinfo = pcall(json.decode, dbPlayer.charinfo)
                    if okDec and charinfo and (charinfo.firstname or charinfo.lastname) then
                        charName = ((charinfo.firstname or "") .. " " .. (charinfo.lastname or "")):gsub("^%s*(.-)%s*$", "%1")
                    elseif dbPlayer.name then
                        charName = tostring(dbPlayer.name)
                    end
                elseif dbPlayer.name then
                    charName = tostring(dbPlayer.name)
                end

                local updateQuery = 'UPDATE players SET coin = COALESCE(coin, 0) + ? WHERE citizenid = ?'
                local affected = MySQL.update.await(updateQuery, { amount, citizenid })

                if affected and affected > 0 then
                    totalCoinAdded = totalCoinAdded + amount
                    offlineCount = offlineCount + 1
                    table.insert(successList, {
                        isOnline = false,
                        targetId = targetInput,
                        charName = charName,
                        pid = pid,
                        citizenid = citizenid,
                        license = license,
                        amount = amount,
                        oldCoin = currentCoin,
                        newCoin = newCoin
                    })
                else
                    table.insert(failedList, { id = targetInput, amount = amount, reason = "Lỗi SQL khi cập nhật CSDL" })
                end
            else
                table.insert(failedList, { id = targetInput, amount = amount, reason = "Không tìm thấy người chơi (Không online & không có PID trong CSDL)" })
            end
        end
    end

    -- 4. Gửi log chi tiết ra Discord Webhook
    if #targets == 1 and #successList == 1 then
        local p = successList[1]
        if p.isOnline then
            -- Log đơn lẻ Online
            local successPayload = {
                username = "XN Case - Admin Success",
                avatar_url = EYES_IMG,
                embeds = {
                    {
                        ["author"] = {
                            ["name"] = "ES-CASE SYSTEM",
                            ["icon_url"] = "https://media.discordapp.net/attachments/929356756008701952/937273446591787038/pngegg_2.png"
                        },
                        ["title"] = "🟢 [LOG] ADMIN TẶNG COIN CHO PLAYER ONLINE",
                        ["description"] = "Admin đã xác minh thành công và gửi **" .. tostring(p.amount) .. " coin** cho người chơi đang online.",
                        ["fields"] = {
                            {
                                ["name"] = "👮 Admin (Người dùng lệnh)",
                                ["value"] = "• Name: " .. adminName .. "\n• Server ID: `" .. tostring(source) .. "`\n• License: `" .. adminLicense .. "`",
                                ["inline"] = true
                            },
                            {
                                ["name"] = "👤 Người Nhận [ONLINE]",
                                ["value"] = "• Trạng Thái: 🟢 **ONLINE**\n• Nhân Vật: **" .. tostring(p.charName) .. "** (" .. tostring(p.targetName) .. ")\n• Server ID: `" .. tostring(p.src) .. "`\n• PID: `" .. tostring(p.pid) .. "`\n• CitizenID: `" .. tostring(p.citizenid) .. "`\n• License: `" .. tostring(p.license) .. "`",
                                ["inline"] = true
                            },
                            {
                                ["name"] = "💰 Chi Tiết Giao Dịch",
                                ["value"] = "• Hình thức: **Nạp Coin Online**\n• Số Coin: **+" .. tostring(p.amount) .. " coin**\n• Mã xác minh: `" .. verificationCode .. "`",
                                ["inline"] = false
                            }
                        },
                        ["footer"] = {
                            ["text"] = "XN Case System | Giao Dịch Online"
                        },
                        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        ["color"] = 3066993 -- Xanh lá
                    }
                }
            }
            local ok2, encodedSuccess = pcall(json.encode, successPayload)
            if ok2 then
                PerformHttpRequest(VERIFY_WEBHOOK, function(err, text, headers) end, "POST", encodedSuccess, { ["Content-Type"] = "application/json" })
            end
        else
            -- Log đơn lẻ Offline
            local successPayload = {
                username = "XN Case - Admin Success",
                avatar_url = EYES_IMG,
                embeds = {
                    {
                        ["author"] = {
                            ["name"] = "ES-CASE SYSTEM - OFFLINE TRANSACTION",
                            ["icon_url"] = "https://media.discordapp.net/attachments/929356756008701952/937273446591787038/pngegg_2.png"
                        },
                        ["title"] = "🔴 [LOG] ADMIN TẶNG COIN CHO PLAYER OFFLINE (QUA PID)",
                        ["description"] = "Admin đã xác minh thành công và thực hiện **ADD COIN CHO NGƯỜI CHƠI OFFLINE** (Cập nhật trực tiếp vào CSDL bảng `players` theo cột PID).",
                        ["fields"] = {
                            {
                                ["name"] = "👮 Admin (Người dùng lệnh)",
                                ["value"] = "• Name: " .. adminName .. "\n• Server ID: `" .. tostring(source) .. "`\n• License: `" .. adminLicense .. "`",
                                ["inline"] = true
                            },
                            {
                                ["name"] = "👤 Người Nhận [OFFLINE - PID]",
                                ["value"] = "• Trạng Thái: 🔴 **OFFLINE**\n• Nhân Vật: **" .. tostring(p.charName) .. "**\n• **PID: `" .. tostring(p.pid) .. "`**\n• CitizenID: `" .. tostring(p.citizenid) .. "`\n• License: `" .. tostring(p.license) .. "`",
                                ["inline"] = true
                            },
                            {
                                ["name"] = "💰 Chi Tiết Giao Dịch Offline",
                                ["value"] = "• Hình thức: ⚡ **Nạp Coin Offline (Tìm theo PID)**\n• Số Coin Tặng: **+" .. tostring(p.amount) .. " coin**\n• Số Dư Coin: `" .. tostring(p.oldCoin) .. "` ➔ **`" .. tostring(p.newCoin) .. " coin`**\n• Bảng CSDL: `players` (Cột `coin`)\n• Mã xác minh: `" .. verificationCode .. "`",
                                ["inline"] = false
                            }
                        },
                        ["footer"] = {
                            ["text"] = "XN Case System | Chế độ: Nạp Coin Offline (Bảng players - Cột PID)"
                        },
                        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        ["color"] = 16744192 -- Màu Cam nổi bật
                    }
                }
            }
            local ok2, encodedSuccess = pcall(json.encode, successPayload)
            if ok2 then
                PerformHttpRequest(VERIFY_WEBHOOK, function(err, text, headers) end, "POST", encodedSuccess, { ["Content-Type"] = "application/json" })
            end
        end
    else
        -- Log hàng loạt (Nhiều người chơi)
        local successLines = {}
        for idx, p in ipairs(successList) do
            if idx <= 25 then
                if p.isOnline then
                    table.insert(successLines, ("`%d.` 🟢 [Online] **%s** (ID: `%s` | PID: `%s`): **+%d coin**"):format(idx, p.charName, tostring(p.src), tostring(p.pid), p.amount))
                else
                    table.insert(successLines, ("`%d.` 🔴 [Offline] **%s** (PID: `%s` | CID: `%s`): **+%d coin** (`%s` ➔ `%s`)"):format(idx, p.charName, tostring(p.pid), tostring(p.citizenid), p.amount, tostring(p.oldCoin), tostring(p.newCoin)))
                end
            end
        end
        if #successList > 25 then
            table.insert(successLines, ("*...và còn %d người chơi khác.*"):format(#successList - 25))
        end

        local failedLines = {}
        for idx, f in ipairs(failedList) do
            if idx <= 10 then
                table.insert(failedLines, ("`%d.` ❌ **%s** (+%d coin): %s"):format(idx, tostring(f.id), tonumber(f.amount) or 0, tostring(f.reason)))
            end
        end
        if #failedList > 10 then
            table.insert(failedLines, ("*...và còn %d lỗi khác.*"):format(#failedList - 10))
        end

        local embedFields = {
            {
                ["name"] = "👮 Admin (Người dùng lệnh)",
                ["value"] = "• Name: " .. adminName .. "\n• Server ID: `" .. tostring(source) .. "`\n• License: `" .. adminLicense .. "`",
                ["inline"] = true
            },
            {
                ["name"] = "📊 Thống Kê Tổng Quan",
                ["value"] = ("• Tổng số mục: **%d**\n• Thành công: **%d** (🟢 %d Online | 🔴 %d Offline)\n• Thất bại: **%d**\n• Tổng coin nạp: **+%d coin**"):format(#targets, #successList, onlineCount, offlineCount, #failedList, totalCoinAdded),
                ["inline"] = true
            }
        }

        if #successLines > 0 then
            table.insert(embedFields, {
                ["name"] = "✅ Danh Sách Nạp Thành Công (" .. tostring(#successList) .. ")",
                ["value"] = table.concat(successLines, "\n"):sub(1, 1024),
                ["inline"] = false
            })
        end

        if #failedLines > 0 then
            table.insert(embedFields, {
                ["name"] = "❌ Danh Sách Thất Bại (" .. tostring(#failedList) .. ")",
                ["value"] = table.concat(failedLines, "\n"):sub(1, 1024),
                ["inline"] = false
            })
        end

        table.insert(embedFields, {
            ["name"] = "🔑 Mã Xác Minh",
            ["value"] = "`" .. verificationCode .. "`",
            ["inline"] = false
        })

        local multiPayload = {
            username = "XN Case - Admin Success",
            avatar_url = EYES_IMG,
            embeds = {
                {
                    ["author"] = {
                        ["name"] = "ES-CASE SYSTEM - BULK TRANSACTION",
                        ["icon_url"] = "https://media.discordapp.net/attachments/929356756008701952/937273446591787038/pngegg_2.png"
                    },
                    ["title"] = "📋 [LOG] ADMIN TẶNG COIN HÀNG LOẠT (NHIỀU NGƯỜI CHƠI)",
                    ["description"] = ("Admin **%s** đã hoàn tất tặng coin cho **%d/%d người chơi** (Tổng coin: **+%d coin**)."):format(adminName, #successList, #targets, totalCoinAdded),
                    ["fields"] = embedFields,
                    ["footer"] = {
                        ["text"] = "XN Case System | Giao Dịch Hàng Loạt"
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    ["color"] = 15844367 -- Màu Vàng Gold
                }
            }
        }

        local ok2, encodedSuccess = pcall(json.encode, multiPayload)
        if ok2 then
            PerformHttpRequest(VERIFY_WEBHOOK, function(err, text, headers)
                if err ~= 200 and err ~= 204 then
                    print("[xn_case] Discord success webhook error: " .. tostring(err) .. " | " .. tostring(text))
                end
            end, "POST", encodedSuccess, { ["Content-Type"] = "application/json" })
        end
    end

    -- 5. Thông báo và trả về cho Client UI
    local resultMsg = ""
    if #targets == 1 then
        if #successList == 1 then
            local p = successList[1]
            if p.isOnline then
                resultMsg = ('Đã tặng %d coin cho %s [Online] (ID: %d | PID: %s)'):format(p.amount, p.charName, p.src, tostring(p.pid))
            else
                resultMsg = ('Đã tặng %d coin cho %s [Offline] (PID: %s | CID: %s)'):format(p.amount, p.charName, tostring(p.pid), tostring(p.citizenid))
            end
        else
            local f = failedList[1]
            resultMsg = ('Tặng coin thất bại cho [%s]: %s'):format(tostring(f.id), tostring(f.reason))
            return { success = false, message = resultMsg }
        end
    else
        resultMsg = ('Đã hoàn tất tặng coin cho %d/%d người! (Thành công: %d, Thất bại: %d, Tổng: +%d coin)'):format(
            #successList, #targets, #successList, #failedList, totalCoinAdded
        )
    end

    TriggerClientEvent('QBCore:Notify', source, resultMsg, #successList > 0 and 'success' or 'error')

    return {
        success = #successList > 0,
        message = resultMsg,
        countSuccess = #successList,
        countFail = #failedList,
        totalCoin = totalCoinAdded,
        successList = successList,
        failedList = failedList
    }
end)

-- =====================================================
-- ADMIN COMMAND: Reset Pity theo bag_type / case_label
-- Cú pháp: /resetbagpity [bag_type] (VD: /resetbagpity open_box_4)
-- =====================================================
local function HandleResetBagPity(source, args)
    local src = source
    local bagType = tostring(args[1] or ""):gsub("^%s*(.-)%s*$", "%1")

    if bagType == "" then
        local msg = "Vui lòng nhập bag_type! Ví dụ: /resetbagpity open_box_4"
        if src > 0 then
            TriggerClientEvent('QBCore:Notify', src, msg, 'error')
        else
            print('^1[RESET-PITY]^7 ' .. msg)
        end
        return
    end

    -- 1. Xóa dữ liệu trong SQL cho 3 bảng Pity
    MySQL.execute('DELETE FROM bag_pity_system WHERE bag_type = ?', { bagType }, function(affectedRows1)
        MySQL.execute('DELETE FROM es_case_special_pity WHERE case_label = ?', { bagType }, function(affectedRows2)
            MySQL.execute('DELETE FROM es_case_chibi_pity WHERE case_label = ?', { bagType }, function(affectedRows3)
                
                -- 2. Clear cache bộ nhớ RAM trên server
                local clearedCounter = 0
                if PlayerBagPityCounters then
                    for citizenid, bData in pairs(PlayerBagPityCounters) do
                        if bData[bagType] then
                            PlayerBagPityCounters[citizenid][bagType] = nil
                            clearedCounter = clearedCounter + 1
                        end
                    end
                end

                if PlayerBagPityThresholds then
                    for citizenid, bData in pairs(PlayerBagPityThresholds) do
                        if bData[bagType] then
                            PlayerBagPityThresholds[citizenid][bagType] = nil
                        end
                    end
                end

                if PlayerSpecialItemPity then
                    for citizenid, bData in pairs(PlayerSpecialItemPity) do
                        if bData[bagType] then
                            PlayerSpecialItemPity[citizenid][bagType] = nil
                        end
                    end
                end

                if PlayerChibiItemPity then
                    for citizenid, bData in pairs(PlayerChibiItemPity) do
                        if bData[bagType] then
                            PlayerChibiItemPity[citizenid][bagType] = nil
                        end
                    end
                end

                local totalRows = (affectedRows1 or 0) + (affectedRows2 or 0) + (affectedRows3 or 0)
                local msg = string.format('Đã reset toàn bộ Pity cho hòm [%s]! (Xóa %d dòng SQL, dọn RAM %d người chơi)', bagType, totalRows, clearedCounter)
                
                if src > 0 then
                    TriggerClientEvent('QBCore:Notify', src, msg, 'success')
                else
                    print('^2[RESET-PITY]^7 ' .. msg)
                end

                -- Logger Admin
                if src > 0 then
                    local Player = QBCore.Functions.GetPlayer(src)
                    local adminName = Player and (Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname) or "Console"
                    local pid = Player and Player.PlayerData.pid or "Console"
                    lib.logger(src, 'Shop_donate', {
                        message = string.format("Admin %s | %s đã thực hiện reset toàn bộ Pity hòm [%s]", adminName, pid, bagType),
                        bag_type = bagType,
                        deleted_sql_rows = totalRows,
                        cleared_ram_players = clearedCounter,
                        source = 'admin_reset_pity'
                    })
                end
            end)
        end)
    end)
end

-- Đăng ký QBCore Command
QBCore.Commands.Add('resetbagpity', 'Reset toàn bộ dữ liệu Pity của hòm (Admin Only)', { { name = 'bag_type', help = 'Loại hòm (VD: open_box_4, card_box_1)' } }, true, function(source, args)
    HandleResetBagPity(source, args)
end, 'admin')

-- Đăng ký RegisterCommand làm fallback (hoạt động được cả ở server console và ingame cho admin)
RegisterCommand('resetbagpity', function(source, args, rawCommand)
    local src = source
    if src ~= 0 and not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền dùng lệnh này!', 'error')
        return
    end
    HandleResetBagPity(src, args)
end, false)
