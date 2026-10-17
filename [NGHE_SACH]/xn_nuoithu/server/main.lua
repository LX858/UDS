local ox = exports.ox_inventory

-- Database functions
local function GetPlayerUpgradeData(citizenid)
    local result = MySQL.Sync.fetchAll('SELECT * FROM xn_nuoithu_upgrades WHERE citizenid = ?', {citizenid})
    if result and result[1] then
        return result[1]
    else
        -- Tạo mới nếu chưa có
        MySQL.Async.execute('INSERT INTO xn_nuoithu_upgrades (citizenid, luck_level, time_level, capacity_level, skill_points, overall_level) VALUES (?, 0, 0, 0, 0, 0)', {citizenid})
        return {
            citizenid = citizenid,
            luck_level = 0,
            time_level = 0,
            capacity_level = 0,
            skill_points = 0,
            overall_level = 0
        }
    end
end

local function UpdatePlayerUpgradeData(citizenid, data)
    MySQL.Async.execute('UPDATE xn_nuoithu_upgrades SET luck_level = ?, time_level = ?, capacity_level = ?, skill_points = ?, overall_level = ? WHERE citizenid = ?', {
        data.luck_level,
        data.time_level,
        data.capacity_level,
        data.skill_points,
        data.overall_level,
        citizenid
    })
end

local function CalculateOverallLevel(luck, time, capacity)
    return math.min(luck, time, capacity)
end

for i =1, #Config.Feed, 1 do
    exports.qbx_core:CreateUseableItem(Config.Feed[i].item.use, function(source, item)
        TriggerClientEvent('vie-chamsocthucung:client:Start', source, Config.Feed[i])
    end)
end

RegisterNetEvent('vie-chamsocthucung:server:RemoveItemHeo', function()
    local src = source
    exports.ox_inventory:RemoveItem(source, "trung_thu", 1)
end)

RegisterNetEvent('vie-chamsocthucung:server:RemoveItemthucan', function()
    local src = source
    exports.ox_inventory:RemoveItem(source, Config.ThucAn, 1)
end)

-- Event xử lý phần thưởng khi nhận động vật trưởng thành
exports['monitors']:RegisterProtectedEvent('vie-chamsocthucung:server:GiveReward', function(source, animalType)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Kiểm tra loại động vật có trong config không
    if not Config.AnimalRewards[animalType] then
        animalType = "pigagle" -- Fallback về pig nếu không tìm thấy
    end
    
    local reward = Config.AnimalRewards[animalType]
    
    -- Kiểm tra sức chứa túi đồ trước khi additem
    if not exports.ox_inventory:CanCarryItem(src, reward.item, reward.amount) then
        exports.qbx_core:Notify(src, "Túi đồ của bạn không đủ chỗ chứa!", "error")
        return
    end
    
    -- Thêm vật phẩm vào inventory
    local success = exports.ox_inventory:AddItem(src, reward.item, reward.amount)
    if success then
        exports.qbx_core:Notify(src, "Bạn đã nhận được "..reward.amount.."x "..reward.item, "success")
        
        -- Thêm điểm kỹ năng
        local skillPoints = Config.Upgrade.SkillPoints[animalType] or 0
        if skillPoints > 0 then
            local upgradeData = GetPlayerUpgradeData(citizenid)
            upgradeData.skill_points = upgradeData.skill_points + skillPoints
            UpdatePlayerUpgradeData(citizenid, upgradeData)
            exports.qbx_core:Notify(src, "Bạn nhận được +"..skillPoints.." điểm kỹ năng", "success")
        end
        --event--
        local tile2 = math.random(1, 100)
        if tile2 > 1 and tile2 < 15 then
            if exports.ox_inventory:CanCarryItem(src, 'co_bon_la_1', 1) then
                exports.ox_inventory:AddItem(src, 'co_bon_la_1', 1)
            end
        end

    else
        exports.qbx_core:Notify(src, "Không thể thêm vật phẩm vào túi đồ", "error")
    end
end)

-- Helper: Lấy danh sách quần áo có DoHiem rarity từ inventory
local function GetClothingByRarity(src, rarity)
    local items = {}
    local playerItems = exports.ox_inventory:GetInventoryItems(src) or {}
    
    for _, item in pairs(playerItems) do
        if item and item.name then
            -- Kiểm tra item có trong danh sách quần áo không
            local isClothing = false
            for _, clothName in ipairs(Config.Upgrade.ClothingItems) do
                if item.name == clothName then
                    isClothing = true
                    break
                end
            end
            
            if isClothing and item.metadata and item.metadata.DoHiem == rarity then
                table.insert(items, {
                    slot = item.slot,
                    name = item.name,
                    label = item.metadata.label or item.name,
                    rarity = item.metadata.DoHiem,
                    metadata = item.metadata,
                    count = item.count or 1,
                })
            end
        end
    end
    
    return items
end

-- Event lấy dữ liệu nâng cấp
RegisterNetEvent('vie-chamsocthucung:server:GetUpgradeData', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local upgradeData = GetPlayerUpgradeData(citizenid)
    
    -- Tính toán capacity dựa trên level
    local maxCapacity = Config.Upgrade.Stats.capacity.baseCapacity + upgradeData.capacity_level
    
    TriggerClientEvent('vie-chamsocthucung:client:ReceiveUpgradeData', src, upgradeData, maxCapacity)
end)

-- Event lấy quần áo inventory cho NUI
RegisterNetEvent('vie-chamsocthucung:server:GetClothingInventory', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local allClothing = {}
    local playerItems = exports.ox_inventory:GetInventoryItems(src) or {}
    
    for _, item in pairs(playerItems) do
        if item and item.name then
            local isClothing = false
            for _, clothName in ipairs(Config.Upgrade.ClothingItems) do
                if item.name == clothName then
                    isClothing = true
                    break
                end
            end
            
            if isClothing and item.metadata and item.metadata.DoHiem and not (item.slot >= 6 and item.slot <= 21) then
                table.insert(allClothing, {
                    slot = item.slot,
                    name = item.name,
                    label = item.metadata.label or item.name,
                    rarity = item.metadata.DoHiem,
                    metadata = item.metadata,
                    count = item.count or 1,
                })
            end
        end
    end
    
    TriggerClientEvent('vie-chamsocthucung:client:ReceiveClothingInventory', src, allClothing)
end)

-- Event lấy dữ liệu nâng cấp cho command (mở panel)
RegisterNetEvent('vie-chamsocthucung:server:GetUpgradeDataForCommand', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local upgradeData = GetPlayerUpgradeData(citizenid)
    
    -- Tính toán capacity dựa trên level
    local maxCapacity = Config.Upgrade.Stats.capacity.baseCapacity + upgradeData.capacity_level
    
    TriggerClientEvent('vie-chamsocthucung:client:OpenUpgradePanel', src, upgradeData, maxCapacity)
end)

-- Event nâng cấp (nhận selectedSlots = danh sách slot quần áo đã chọn)
RegisterNetEvent('vie-chamsocthucung:server:UpgradeStat', function(statType, selectedSlots)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local upgradeData = GetPlayerUpgradeData(citizenid)
    
    -- Xác định level hiện tại của stat
    local currentLevel = 0
    local statField = ""
    
    if statType == "luck" then
        currentLevel = upgradeData.luck_level
        statField = "luck_level"
    elseif statType == "time" then
        currentLevel = upgradeData.time_level
        statField = "time_level"
    elseif statType == "capacity" then
        currentLevel = upgradeData.capacity_level
        statField = "capacity_level"
    else
        exports.qbx_core:Notify(src, "Loại nâng cấp không hợp lệ", "error")
        return
    end
    
    -- Kiểm tra đã max level chưa
    if currentLevel >= 5 then
        exports.qbx_core:Notify(src, "Chỉ số này đã đạt cấp tối đa", "error")
        return
    end
    
    local nextLevel = currentLevel + 1
    local tierConfig = Config.Upgrade.Tiers[nextLevel]
    
    if not tierConfig then
        exports.qbx_core:Notify(src, "Không tìm thấy cấu hình nâng cấp", "error")
        return
    end
    
    -- Kiểm tra điểm kỹ năng
    if upgradeData.skill_points < tierConfig.skillPoints then
        exports.qbx_core:Notify(src, "Không đủ điểm kỹ năng! Cần "..tierConfig.skillPoints.." điểm", "error")
        return
    end
    
    -- Kiểm tra selectedSlots
    if not selectedSlots or type(selectedSlots) ~= "table" or #selectedSlots ~= tierConfig.itemCount then
        exports.qbx_core:Notify(src, "Không đủ quần áo! Cần chọn "..tierConfig.itemCount.." món quần áo "..tierConfig.rarity, "error")
        return
    end
    
    -- Validate từng slot: kiểm tra item tồn tại, là quần áo, có đúng DoHiem rarity
    local requiredRarity = tierConfig.rarity
    local slotsToRemove = {}
    local usedSlots = {}
    
    for _, slotNum in ipairs(selectedSlots) do
        -- Chống chọn trùng slot
        if usedSlots[slotNum] then
            exports.qbx_core:Notify(src, "Không thể chọn cùng một slot quần áo!", "error")
            return
        end
        usedSlots[slotNum] = true
        
        local slotItem = exports.ox_inventory:GetSlot(src, slotNum)
        if not slotItem or not slotItem.name then
            exports.qbx_core:Notify(src, "Slot "..slotNum.." không có vật phẩm!", "error")
            return
        end
        
        -- Kiểm tra có phải quần áo không
        local isClothing = false
        for _, clothName in ipairs(Config.Upgrade.ClothingItems) do
            if slotItem.name == clothName then
                isClothing = true
                break
            end
        end
        
        if not isClothing then
            exports.qbx_core:Notify(src, slotItem.name.." không phải quần áo hợp lệ!", "error")
            return
        end
        
        -- Kiểm tra metadata DoHiem
        if not slotItem.metadata or slotItem.metadata.DoHiem ~= requiredRarity then
            exports.qbx_core:Notify(src, "Quần áo phải có độ hiếm "..requiredRarity.."!", "error")
            return
        end
        
        table.insert(slotsToRemove, {slot = slotNum, name = slotItem.name})
    end
    
    -- Lấy success rate riêng cho từng stat
    local statConfig = Config.Upgrade.Stats[statType]
    local successRate = statConfig.successRates[nextLevel] or tierConfig.successRate
    
    -- Random thành công
    local random = math.random(1, 100)
    local success = random <= successRate
    
    -- Gửi event bắt đầu animation cho client
    TriggerClientEvent('vie-chamsocthucung:client:StartUpgradeAnimation', src, statType, nextLevel)
    
    -- Trừ quần áo từ các slot đã chọn
    for _, slotInfo in ipairs(slotsToRemove) do
        exports.ox_inventory:RemoveItem(src, slotInfo.name, 1, nil, slotInfo.slot)
    end
    
    -- Trừ điểm kỹ năng
    upgradeData.skill_points = upgradeData.skill_points - tierConfig.skillPoints
    
    if success then
        -- Nâng cấp thành công
        if statType == "luck" then
            upgradeData.luck_level = nextLevel
        elseif statType == "time" then
            upgradeData.time_level = nextLevel
        elseif statType == "capacity" then
            upgradeData.capacity_level = nextLevel
        end
        
        -- Cập nhật overall level
        upgradeData.overall_level = CalculateOverallLevel(upgradeData.luck_level, upgradeData.time_level, upgradeData.capacity_level)
        
        UpdatePlayerUpgradeData(citizenid, upgradeData)
        
        exports.qbx_core:Notify(src, "Nâng cấp thành công! "..Config.Upgrade.Stats[statType].name.." lên cấp "..nextLevel, "success")
        
        -- Gửi lại dữ liệu mới
        local maxCapacity = Config.Upgrade.Stats.capacity.baseCapacity + upgradeData.capacity_level
        TriggerClientEvent('vie-chamsocthucung:client:ReceiveUpgradeData', src, upgradeData, maxCapacity)
    else
        UpdatePlayerUpgradeData(citizenid, upgradeData)
        exports.qbx_core:Notify(src, "Nâng cấp thất bại! Mất quần áo và điểm kỹ năng", "error")
        
        -- Gửi lại dữ liệu (chỉ trừ skill points, level không thay đổi)
        local maxCapacity = Config.Upgrade.Stats.capacity.baseCapacity + upgradeData.capacity_level
        TriggerClientEvent('vie-chamsocthucung:client:ReceiveUpgradeData', src, upgradeData, maxCapacity)
    end
    
    -- Refresh clothing inventory cho NUI
    TriggerEvent('vie-chamsocthucung:server:GetClothingInventory')
    -- Gửi lại cho chính player
    local allClothing = {}
    local playerItems = exports.ox_inventory:GetInventoryItems(src) or {}
    for _, item in pairs(playerItems) do
        if item and item.name then
            local isClothing = false
            for _, clothName in ipairs(Config.Upgrade.ClothingItems) do
                if item.name == clothName then
                    isClothing = true
                    break
                end
            end
            if isClothing and item.metadata and item.metadata.DoHiem then
                table.insert(allClothing, {
                    slot = item.slot,
                    name = item.name,
                    label = item.metadata.label or item.name,
                    rarity = item.metadata.DoHiem,
                    metadata = item.metadata,
                    count = item.count or 1,
                })
            end
        end
    end
    TriggerClientEvent('vie-chamsocthucung:client:ReceiveClothingInventory', src, allClothing)
end)