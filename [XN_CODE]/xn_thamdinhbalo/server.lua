local QBCore = exports['qb-core']:GetCoreObject()
local MySQL = exports['oxmysql']

-- Lock table để chống duplicate requests khi ping cao
local processingRequests = {}
local COOLDOWN_TIME = 5000 -- 5 giây cooldown

-- Helper function để kiểm tra drawable có thể nâng cấp được không
local function isDrawableUpgradeable(drawable, playerGender)
    --print("Debug: Checking if drawable", drawable, "is upgradeable for gender", playerGender)
    
    -- Debug: Kiểm tra config có tồn tại không
    if not Config.UpgradeLevels then
        --print("Debug: ERROR - Config.UpgradeLevels is nil!")
        return false, nil
    end
    
    if not Config.UpgradeLevels[playerGender] then
        ----print("Debug: ERROR - No config for gender:", playerGender)
        local availableGenders = {}
        for k, v in pairs(Config.UpgradeLevels or {}) do
            table.insert(availableGenders, k)
        end
        --print("Debug: Available genders in config:", json.encode(availableGenders))
        return false, nil
    end
    
    --print("Debug: Gender config found for:", playerGender)
    
    for level, levelConfig in pairs(Config.UpgradeLevels[playerGender] or {}) do
        if levelConfig.upgradeable_drawables then
            for _, upgradeableDrawable in pairs(levelConfig.upgradeable_drawables) do
                if upgradeableDrawable == drawable then
                    --print("Debug: Drawable", drawable, "found in level", level, "upgradeable list")
                    return true, level
                end
            end
        end
    end
    
    --print("Debug: Drawable", drawable, "is NOT upgradeable")
    return false, nil
end

-- Function để lấy coin từ database
local function getPlayerCoin(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    local citizenid = Player.PlayerData.citizenid
    local result = exports.oxmysql:executeSync('SELECT coin FROM players WHERE citizenid = ?', {citizenid})
    
    if result and result[1] then
        return result[1].coin or 0
    end
    return 0
end

-- Function để trừ coin từ database
local function removePlayerCoin(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    local currentCoin = getPlayerCoin(source)
    
    if currentCoin < amount then
        return false
    end
    
    local newCoin = currentCoin - amount
    exports.oxmysql:execute('UPDATE players SET coin = ? WHERE citizenid = ?', {newCoin, citizenid})
    return true
end

-- Helper function để kiểm tra drawable có thể trao đổi được không
local function isDrawableUpgradeable(drawable, playerGender)
    --print("Debug: Checking if drawable", drawable, "is upgradeable for gender", playerGender)
    
    for level, levelConfig in pairs(Config.UpgradeLevels[playerGender] or {}) do
        if levelConfig.upgradeable_drawables then
            for _, upgradeableDrawable in pairs(levelConfig.upgradeable_drawables) do
                if upgradeableDrawable == drawable then
                    --print("Debug: Drawable", drawable, "found in level", level, "upgradeable list")
                    return true, level
                end
            end
        end
    end
    
    --print("Debug: Drawable", drawable, "is NOT upgradeable")
    return false, nil
end

-- Function helper để tạo requirements với số lượng real-time
local function createRequirements(source, level, isCustom)
    local requirements = {}
    level = level or 3 -- Default level 3
    local configByLevel = isCustom and Config.CustomUpgradeRequirementsByLevel or Config.UpgradeRequirementsByLevel
    local configByRarity = isCustom and Config.CustomUpgradeRequirements or Config.UpgradeRequirements
    local requirementsConfig = configByLevel[level] or configByRarity['Rare'] -- Fallback to legacy
    
    --print("Debug: Creating requirements for level", level)
    if requirementsConfig then
        --print("Debug: Creating requirements with", #requirementsConfig, "items")
        for _, req in pairs(requirementsConfig) do
            local playerItem = exports.ox_inventory:Search(source, 'count', req.item)
            local hasCount = 0
            
            -- Xử lý kết quả từ ox_inventory:Search
            if type(playerItem) == 'number' then
                hasCount = playerItem
            elseif type(playerItem) == 'table' and playerItem.count then
                hasCount = playerItem.count
            elseif playerItem then
                hasCount = tonumber(playerItem) or 0
            end
            
            -- Lấy label của item từ ox_inventory
            local itemData = exports.ox_inventory:Items(req.item)
            local label = itemData and itemData.label or req.item
            
            --print("Debug: Item", req.item, "required:", req.amount, "current:", hasCount)
            table.insert(requirements, {
                item = req.item,
                label = label,
                required = req.amount,
                current = hasCount,
                hasEnough = hasCount >= req.amount
            })
        end
    else
        --print("Debug: ERROR - No requirements config found!")
    end
    
    return requirements
end


-- Callback để lấy dữ liệu balo của player
QBCore.Functions.CreateCallback('xn_thamdinhbalo:getBagData', function(source, cb, clientGender)
    --print("Debug: getBagData called with parameters:")
    --print("  - source:", source)
    --print("  - cb:", type(cb))
    --print("  - clientGender:", clientGender, "(type:", type(clientGender), ")")
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end
    
    -- Sử dụng gender từ client, fallback về "male" nếu không có
    local gender = clientGender or "male"
    --print("Debug: Using gender from client:", gender)
    
    -- Lấy tất cả items từ ox_inventory
    local inventory = exports.ox_inventory:GetInventory(source, false)
    if not inventory or not inventory.items then
        --print("Debug: No inventory found for player:", source)
        cb(false)
        return
    end
    
    --print("Debug: Found inventory with", #inventory.items, "items")
    
    -- Lấy danh sách upgrade options dựa theo gender và cấp độ balo được chọn
    local bagData = {
        currentBags = {},
        requirements = {}, -- Luôn được tạo bất kể có balo hay không
        upgradeOptions = {},
        playerGender = gender,
        imageConfig = Config.ImageSettings,
        selectedBagLevel = nil, -- Sẽ được cập nhật khi chọn balo
        selectedBagDrawable = nil
    }
    
    bagData.playerCoin = getPlayerCoin(source)
    
    -- Lấy danh sách balo hiện có
    for slot, item in pairs(inventory.items) do
        if item.name == Config.BagItem then
            --print("Debug: Found bag item:", item.name, "in slot:", slot)
            if item.metadata then
                --print("Debug: Bag metadata:", json.encode(item.metadata))
            end
            
            -- Đảm bảo có metadata mặc định
            local metadata = item.metadata or {}
            if not metadata.drawable then
                metadata.drawable = 89 -- Default drawable
            end
            if not metadata.Capdo then
                metadata.Capdo = 3 -- Default level
            end
            if not metadata.DoHiem then
                metadata.DoHiem = 'Rare' -- Default rarity
            end
            
            -- Tự động set metadata.sex dựa trên drawable nếu chưa có
            if not metadata.sex then
                -- Kiểm tra drawable thuộc gender nào
                local isFemaleDrawable = false
                local isMaleDrawable = false
                
                -- Kiểm tra trong tất cả config levels
                for genderKey, genderConfig in pairs(Config.UpgradeLevels) do
                    for levelKey, levelConfig in pairs(genderConfig) do
                        -- Kiểm tra trong upgradeable_drawables
                        if levelConfig.upgradeable_drawables then
                            for _, drawable in pairs(levelConfig.upgradeable_drawables) do
                                if drawable == metadata.drawable then
                                    if genderKey == "female" then
                                        isFemaleDrawable = true
                                    else
                                        isMaleDrawable = true
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Set metadata.sex dựa trên kết quả kiểm tra
                if isFemaleDrawable and not isMaleDrawable then
                    metadata.sex = 1 -- female
                    --print("Debug: Auto-set metadata.sex = 1 (female) for drawable", metadata.drawable)
                elseif isMaleDrawable and not isFemaleDrawable then
                    metadata.sex = 0 -- male
                    --print("Debug: Auto-set metadata.sex = 0 (male) for drawable", metadata.drawable)
                else
                    -- Nếu drawable xuất hiện trong cả hai hoặc không có trong config, không set
                    --print("Debug: Cannot auto-determine sex for drawable", metadata.drawable, "- keeping unset")
                end
            end
            
            -- ✅ CHỈ CHO ĐỔI BALO CÓ ID VÀ CAPDO (đã được set level)
            local hasValidMetadata = metadata.id and metadata.Capdo
            
            if not hasValidMetadata then
                --print("Debug: Skipped bag drawable", metadata.drawable, "- missing id or Capdo")
                goto continue_bag_loop
            end
            
            -- Kiểm tra xem drawable có thể trao đổi được không với gender hiện tại
            local isUpgradeable, level = isDrawableUpgradeable(metadata.drawable, gender)
            
            -- Kiểm tra metadata.sex nếu có (để lọc theo giới tính)
            local sexMatches = true
            if metadata.sex then
                -- Chuyển đổi giá trị metadata.sex sang format chuẩn
                local metadataSex = "male" -- default
                if metadata.sex == 1 or metadata.sex == "female" then
                    metadataSex = "female"
                elseif metadata.sex == 0 or metadata.sex == "male" then
                    metadataSex = "male"
                end
                
                -- Chỉ hiển thị balo có giới tính phù hợp
                sexMatches = (metadataSex == gender)
                --print("Debug: Bag drawable", metadata.drawable, "metadata.sex:", metadata.sex, "->", metadataSex, "player gender:", gender, "matches:", sexMatches)
            else
                --print("Debug: Bag drawable", metadata.drawable, "has no metadata.sex - showing for all genders")
            end
            
            if isUpgradeable and sexMatches then
                table.insert(bagData.currentBags, {
                    slot = slot,
                    name = item.name,
                    label = item.label or Config.componentMapping[Config.BagItem].label,
                    metadata = metadata,
                    count = item.count or 1
                })
                
                --print("Debug: Added upgradeable bag to list with drawable:", metadata.drawable, "for gender:", gender)
            else
                local reason = ""
                if not isUpgradeable then
                    reason = "not upgradeable for " .. gender
                elseif not sexMatches then
                    reason = "metadata.sex doesn't match " .. gender
                end
                --print("Debug: Skipped bag with drawable:", metadata.drawable, "- reason:", reason)
            end
            
            ::continue_bag_loop::
        end
    end
    
    -- Thêm thông tin để client biết có balo nào có thể trao đổi không
    bagData.hasUpgradeableBags = #bagData.currentBags > 0
    bagData.playerGender = gender
    
    -- LUÔN TẠO REQUIREMENTS - KHÔNG PHỤ THUỘC VÀO VIỆC CÓ BALO HAY KHÔNG
    --print("Debug: Creating requirements...")
    bagData.requirements = createRequirements(source)
    
    --print("Debug: Final bagData.requirements count:", #bagData.requirements)
    if #bagData.requirements > 0 then
        --print("Debug: First requirement:", json.encode(bagData.requirements[1]))
    end
    
    -- Thêm thông tin coin của player
    bagData.playerCoin = getPlayerCoin(source)
    
    -- Thêm thông tin tiền cash của player
    local Player = QBCore.Functions.GetPlayer(source)
    bagData.playerMoney = Player and Player.Functions.GetMoney('cash') or 0
    
    -- Upgrade options sẽ được load khi chọn balo
    
    cb(bagData)
end)

-- Callback để refresh requirements với số lượng mới nhất
QBCore.Functions.CreateCallback('xn_thamdinhbalo:refreshRequirements', function(source, cb)
    --print("Debug: refreshRequirements called")
    local requirements = createRequirements(source)
    
    cb({
        requirements = requirements,
        success = true
    })
end)

-- Callback để lấy upgrade options dựa theo balo được chọn
QBCore.Functions.CreateCallback('xn_thamdinhbalo:getUpgradeOptions', function(source, cb, bagSlot, clientGender, isCustom)
    --print("Debug: getUpgradeOptions called with parameters:")
    --print("  - source:", source)
    --print("  - cb:", type(cb))  
    --print("  - bagSlot:", bagSlot, "(type:", type(bagSlot), ")")
    --print("  - clientGender:", clientGender, "(type:", type(clientGender), ")")
    --print("  - isCustom:", isCustom)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        --print("Debug: Player not found")
        cb(false)
        return
    end
    
    -- Sử dụng gender từ client, fallback về "male" nếu không có
    local gender = clientGender or "male"
    --print("Debug: Player gender from client:", gender)
    
    -- Lấy thông tin balo từ slot
    local inventory = exports.ox_inventory:GetInventory(source, false)
    if not inventory or not inventory.items then
        --print("Debug: No inventory or items")
        cb(false)
        return
    end
    
    -- Tìm item theo slot
    local bagItem = nil
    for slot, item in pairs(inventory.items) do
        if tostring(slot) == tostring(bagSlot) then
            bagItem = item
            break
        end
    end
    
    if not bagItem then
        --print("Debug: Item not found in slot:", bagSlot)
        cb(false)
        return
    end
    
    if bagItem.name ~= Config.BagItem or not bagItem.metadata then
        --print("Debug: Item not cloth_bags or no metadata, item name:", bagItem.name)
        cb(false)
        return
    end
    
    local capdo = bagItem.metadata.Capdo or 3
    local drawable = bagItem.metadata.drawable or 89
    --print("Debug: Bag metadata level:", capdo, "drawable:", drawable)
    
    -- Xác định level thực sự dựa theo drawable, không phải metadata.Capdo
    local isUpgradeable, actualLevel = isDrawableUpgradeable(drawable, gender)
    if not isUpgradeable then
        --print("Debug: Drawable", drawable, "is not upgradeable for any level")
        cb({
            canUpgrade = false,
            message = "Balo này không thể trao đổi (drawable không hợp lệ)"
        })
        return
    end
    
    --print("Debug: Using actual level from drawable:", actualLevel, "instead of metadata level:", capdo)
    local levelToUse = actualLevel -- Dùng level thực sự từ drawable
    
    -- Lấy config level cho gender và cấp độ tương ứng
    local genderConfig = Config.UpgradeLevels[gender]
    if not genderConfig then
        --print("Debug: No gender config for:", gender)
        cb(false)
        return
    end
    
    local levelConfig = genderConfig[levelToUse]
    if not levelConfig then
        --print("Debug: ERROR - No level config found for gender:", gender, "level:", levelToUse)
        local availableLevels = {}
        for level, _ in pairs(genderConfig or {}) do
            table.insert(availableLevels, level)
        end
        --print("Debug: Available levels for gender:", gender, ":", json.encode(availableLevels))
        cb(false)
        return
    end
    
    --print("Debug: Level config found for level", levelToUse)
    --print("Debug: Upgradeable drawables:", json.encode(levelConfig.upgradeable_drawables))
    --print("Debug: Normal drawables:", json.encode(levelConfig.upgrade_normal_drawables))
    --print("Debug: Rare drawables:", json.encode(levelConfig.upgrade_rare_drawables))
    
    -- Debug cụ thể cho drawable 197
    local has197Normal = false
    local has197Rare = false
    for _, drawable in pairs(levelConfig.upgrade_normal_drawables or {}) do
        if drawable == 197 then has197Normal = true end
    end
    for _, drawable in pairs(levelConfig.upgrade_rare_drawables or {}) do
        if drawable == 197 then has197Rare = true end
    end
    --print("Debug: Drawable 197 in normal:", has197Normal, "in rare:", has197Rare, "for gender:", gender)
    
    -- Kiểm tra xem drawable hiện tại có thể trao đổi không
    local canUpgrade = true -- Đã kiểm tra ở trên với isDrawableUpgradeable
    --print("Debug: Drawable", drawable, "can be upgraded at level", levelToUse)
    
    -- Tạo danh sách các upgrade options có thể nhận được
    local upgradeOptions = {}
    
    -- Chỉ hiển thị upgrade options, không hiển thị downgrade options
    -- Bỏ qua downgrade_drawables trong upgrade options display
    
    -- Thêm upgrade normal options (loại bỏ drawable hiện tại)
    for _, normalDrawable in pairs(levelConfig.upgrade_normal_drawables) do
        if normalDrawable ~= drawable then -- Không thêm drawable hiện tại
            table.insert(upgradeOptions, {
                drawable = normalDrawable,
                chance = levelConfig.upgrade_normal_chance,
                type = 'normal',
                label = 'trao đổi thường',
                level = levelToUse
            })
            if normalDrawable == 197 then
                --print("Debug: Added drawable 197 as NORMAL for gender:", gender)
            end
        end
    end
    
    -- Thêm upgrade rare options (loại bỏ drawable hiện tại)
    for _, rareDrawable in pairs(levelConfig.upgrade_rare_drawables) do
        if rareDrawable ~= drawable then -- Không thêm drawable hiện tại
            table.insert(upgradeOptions, {
                drawable = rareDrawable,
                chance = levelConfig.upgrade_rare_chance,
                type = 'rare',
                label = 'trao đổi hiếm',
                level = levelToUse
            })
            if rareDrawable == 197 then
                --print("Debug: Added drawable 197 as RARE for gender:", gender)
            end
        end
    end
    
    --print("Debug: Total upgrade options created:", #upgradeOptions)
    
    -- Debug tổng quan về drawable 197 trong upgrade options
    local drawable197Count = 0
    local drawable197Types = {}
    for _, option in pairs(upgradeOptions) do
        if option.drawable == 197 then
            drawable197Count = drawable197Count + 1
            table.insert(drawable197Types, option.type)
        end
    end
    --print("Debug: Drawable 197 appears", drawable197Count, "times with types:", json.encode(drawable197Types))
    
    -- Tạo requirements dựa theo level thực sự
    local requirements = createRequirements(source, levelToUse, isCustom)

    --print("Debug: Created", #requirements, "requirements for level", levelToUse)
    
    local response = {
        canUpgrade = true,
        options = upgradeOptions,
        currentLevel = levelToUse, -- Dùng level thực sự từ drawable
        currentDrawable = drawable,
        coinCost = Config.CoinUpgrade.cost_per_level[levelToUse] or 0,
        playerCoin = getPlayerCoin(source),
        appraisalCost = Config.AppraisalCost[levelToUse] or 0,
        playerMoney = Player.Functions.GetMoney('cash'),
        requirements = requirements -- Thêm requirements theo level
    }
    --print("Debug: Sending callback response:", json.encode(response))
    
    cb(response)
end)

-- Callback xử lý trao đổi
QBCore.Functions.CreateCallback('xn_thamdinhbalo:startAppraisal', function(source, cb, bagSlot, clientGender)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, message = "Player not found"})
        return
    end
    
    -- Kiểm tra xem player đang xử lý request không (chống ping cao duplicate)
    local playerId = Player.PlayerData.citizenid
    if processingRequests[playerId] then
        cb({success = false, message = "Đang xử lý yêu cầu, vui lòng đợi..."})
        return
    end
    
    -- Lock request
    processingRequests[playerId] = true
    
    -- Sử dụng gender từ client, fallback về "male" nếu không có
    local gender = clientGender or "male"
    --print("Debug: Using gender from client for appraisal:", gender)
    
    -- Lấy thông tin balo từ slot
    local inventory = exports.ox_inventory:GetInventory(source, false)
    if not inventory or not inventory.items or not inventory.items[bagSlot] then
        cb({success = false, message = "Không tìm thấy balo"})
        return
    end
    
    local bagItem = inventory.items[bagSlot]
    if bagItem.name ~= Config.BagItem or not bagItem.metadata then
        processingRequests[playerId] = nil
        cb({success = false, message = "Item không hợp lệ"})
        return
    end
    
    local drawable = bagItem.metadata.drawable
    local doHiem = bagItem.metadata.DoHiem or 'Rare'
    
    -- Xác định level thực sự dựa theo drawable, không phải metadata.Capdo
    local isUpgradeable, actualLevel = isDrawableUpgradeable(drawable, gender)
    if not isUpgradeable then
        processingRequests[playerId] = nil
        cb({success = false, message = "Balo này không thể trao đổi (drawable không hợp lệ)"})
        return
    end
    
    local capdo = actualLevel -- Dùng level thực từ drawable
    
    -- Lấy config level cho gender và cấp độ tương ứng
    local genderConfig = Config.UpgradeLevels[gender]
    if not genderConfig then
        processingRequests[playerId] = nil
        cb({success = false, message = "Cấu hình gender không hợp lệ"})
        return
    end
    
    local levelConfig = genderConfig[capdo]
    if not levelConfig then
        processingRequests[playerId] = nil
        cb({success = false, message = "Cấp độ balo không hợp lệ"})
        return
    end
    
    -- Drawable đã được verify từ isDrawableUpgradeable

    -- Kiểm tra tiền appraisal theo cấp độ
    local appraisalCost = Config.AppraisalCost[capdo] or 0
    if appraisalCost > 0 then
        local playerMoney = Player.Functions.GetMoney('cash')
        if playerMoney < appraisalCost then
            processingRequests[playerId] = nil
            cb({success = false, message = string.format("Không đủ tiền! Cần $%d để trao đổi cấp độ %d (bạn có $%d)", appraisalCost, capdo, playerMoney)})
            return
        end
        
        -- Trừ tiền appraisal
        Player.Functions.RemoveMoney('cash', appraisalCost, 'bag-appraisal')
    end

    -- Kiểm tra vật phẩm cần thiết
    local requirements = Config.UpgradeRequirements[doHiem]
    if requirements then
        for _, req in pairs(requirements) do
            local playerItem = exports.ox_inventory:Search(source, 'count', req.item)
            local hasCount = 0
            
            -- Xử lý kết quả từ ox_inventory:Search
            if type(playerItem) == 'number' then
                hasCount = playerItem
            elseif type(playerItem) == 'table' and playerItem.count then
                hasCount = playerItem.count
            elseif playerItem then
                hasCount = tonumber(playerItem) or 0
            end
            
            if hasCount < req.amount then
                processingRequests[playerId] = nil
                cb({success = false, message = string.format("Không đủ %s (cần %d, có %d)", req.item, req.amount, hasCount)})
                return
            end
        end
        
        -- Trừ vật phẩm cần thiết
        for _, req in pairs(requirements) do
            exports.ox_inventory:RemoveItem(source, req.item, req.amount)
        end
    end
    
    -- Tính toán kết quả trao đổi
    local random = math.random(1, 100)
    local result = {
        success = true,
        type = 'success',
        message = '',
        newDrawable = drawable,
        newCapdo = capdo,
        newDoHiem = doHiem
    }
    
    if random <= levelConfig.downgrade_chance then
        -- Tụt cấp: Giảm DoHiem 1 bậc + đổi drawable (không đổi Capdo)
        local downgradeDrawables = {}
        for _, d in pairs(levelConfig.downgrade_drawables) do
            if d ~= drawable then -- Loại bỏ drawable hiện tại
                table.insert(downgradeDrawables, d)
            end
        end
        if #downgradeDrawables > 0 then
            result.newDrawable = downgradeDrawables[math.random(1, #downgradeDrawables)]
        else
            result.newDrawable = drawable -- Nếu không có drawable khác, giữ nguyên
        end
        result.newCapdo = capdo -- Giữ nguyên Capdo
        result.newDoHiem = DowngradeRarity(doHiem) -- Giảm DoHiem 1 bậc
        result.message = string.format("trao đổi thất bại! Balo đã tụt từ %s xuống %s.", doHiem, result.newDoHiem)
        result.type = 'error'
    elseif random <= (levelConfig.downgrade_chance + levelConfig.upgrade_normal_chance) then
        -- trao đổi thường: Giữ nguyên DoHiem + đổi drawable
        local normalDrawables = {}
        for _, d in pairs(levelConfig.upgrade_normal_drawables) do
            if d ~= drawable then -- Loại bỏ drawable hiện tại
                table.insert(normalDrawables, d)
            end
        end
        if #normalDrawables > 0 then
            result.newDrawable = normalDrawables[math.random(1, #normalDrawables)]
        else
            result.newDrawable = drawable -- Nếu không có drawable khác, giữ nguyên
        end
        result.newCapdo = capdo -- Giữ nguyên Capdo
        result.newDoHiem = doHiem -- Giữ nguyên DoHiem
        result.message = string.format("trao đổi thành công! Balo đã được trao đổi (giữ nguyên %s).", doHiem)
        result.type = 'success'
    elseif random <= (levelConfig.downgrade_chance + levelConfig.upgrade_normal_chance + levelConfig.upgrade_rare_chance) then
        -- trao đổi hiếm: Tăng DoHiem 1 bậc + đổi drawable
        local rareDrawables = {}
        for _, d in pairs(levelConfig.upgrade_rare_drawables) do
            if d ~= drawable then -- Loại bỏ drawable hiện tại
                table.insert(rareDrawables, d)
            end
        end
        if #rareDrawables > 0 then
            result.newDrawable = rareDrawables[math.random(1, #rareDrawables)]
        else
            result.newDrawable = drawable -- Nếu không có drawable khác, giữ nguyên
        end
        result.newCapdo = capdo -- Giữ nguyên Capdo
        result.newDoHiem = UpgradeRarity(doHiem) -- Tăng DoHiem 1 bậc
        result.message = string.format("trao đổi xuất sắc! Balo đã thăng từ %s lên %s!", doHiem, result.newDoHiem)
        result.type = 'success'
    else
        -- Không đổi
        result.message = "trao đổi không có thay đổi."
        result.type = 'info'
    end
    
    -- Lưu thông tin để confirm sau
    result.slot = bagSlot
    result.oldMetadata = bagItem.metadata
    result.gender = gender
    result.upgradeType = 'appraisal' -- Đánh dấu đây là loại appraisal
    result.newLevel = result.newCapdo -- Alias cho React
    result.isRare = (result.type == 'success' and result.newDoHiem ~= doHiem) -- Có thay đổi DoHiem không
    
    -- Xóa balo cũ ngay lập tức
    exports.ox_inventory:RemoveItem(source, Config.BagItem, 1, bagItem.metadata, bagSlot)
    
    -- KHÔNG add balo mới ngay - chờ người chơi nhấn OK
    
    -- Unlock sau cooldown time
    SetTimeout(COOLDOWN_TIME, function()
        processingRequests[playerId] = nil
    end)
    
    cb(result)
end)

-- Callback để confirm và thực sự update balo sau khi nhấn OK
QBCore.Functions.CreateCallback('xn_thamdinhbalo:confirmAppraisal', function(source, cb, resultData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, message = "Player not found"})
        return
    end
    
    -- Kiểm tra lock để chống duplicate khi bấm OK nhiều lần
    local playerId = Player.PlayerData.citizenid .. "_confirm"
    if processingRequests[playerId] then
        cb({success = false, message = "Đang xử lý, vui lòng đợi..."})
        return
    end
    
    -- Lock request
    processingRequests[playerId] = true
    
    -- Nhận dữ liệu từ React
    local newDrawable = resultData.newDrawable
    local gender = resultData.gender or 'male'
    local oldMetadata = resultData.oldMetadata or {}
    
    -- ✅ GIỮ NGUYÊN 100% METADATA CŨ, CHỈ THAY ĐỔI DRAWABLE VÀ IMAGE
    local newMetadata = {}
    
    -- Copy toàn bộ metadata cũ (bao gồm Capdo, DoHiem, serial, fromGacha...)
    for k, v in pairs(oldMetadata) do
        newMetadata[k] = v
    end
    
    -- ✅ ĐẢM BẢO GIỮ SERIAL NẾU CÓ
    if oldMetadata.serial then
        newMetadata.serial = oldMetadata.serial
    end
    
    -- Chỉ thay đổi drawable và image
    newMetadata.drawable = newDrawable
    newMetadata.id = newDrawable
    newMetadata.label = string.format("Túi xách %d", newDrawable)
    newMetadata.imageurl = string.format("%s/%s_5_%d.%s", 
        Config.ImageSettings.Url, 
        gender, 
        newDrawable, 
        Config.ImageSettings.Extension
    )
    newMetadata.image = newMetadata.imageurl
    
    -- Capdo và DoHiem giữ nguyên từ oldMetadata
    
    -- Debug log
    if newMetadata.serial then
        print(string.format("[xn_thamdinhbalo] Appraisal: Preserved serial %s for player %s", newMetadata.serial, Player.PlayerData.citizenid))
    end
    
    -- Thêm item mới vào inventory
    local success = exports.ox_inventory:AddItem(source, Config.BagItem, 1, newMetadata)
    
    -- Unlock sau khi hoàn thành
    SetTimeout(1000, function()
        processingRequests[playerId] = nil
    end)
    
    if success then
        cb({success = true, message = "Đã nhận balo mới"})
    else
        cb({success = false, message = "Không thể thêm balo mới"})
    end
end)

-- Callback trao đổi bằng coin
QBCore.Functions.CreateCallback('xn_thamdinhbalo:coinUpgrade', function(source, cb, bagSlot, clientGender)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, message = "Player not found"})
        return
    end
    
    -- Kiểm tra xem player đang xử lý request không (chống ping cao duplicate)
    local playerId = Player.PlayerData.citizenid
    if processingRequests[playerId] then
        cb({success = false, message = "Đang xử lý yêu cầu, vui lòng đợi..."})
        return
    end
    
    -- Lock request
    processingRequests[playerId] = true
    
    -- Sử dụng gender từ client, fallback về "male" nếu không có
    local gender = clientGender or "male"
    --print("Debug: Using gender from client for coin upgrade:", gender)
    
    -- Lấy thông tin balo từ slot
    local inventory = exports.ox_inventory:GetInventory(source, false)
    if not inventory or not inventory.items or not inventory.items[bagSlot] then
        processingRequests[playerId] = nil
        cb({success = false, message = "Không tìm thấy balo"})
        return
    end
    
    local bagItem = inventory.items[bagSlot]
    if bagItem.name ~= Config.BagItem then
        processingRequests[playerId] = nil
        cb({success = false, message = "Item không phải là balo"})
        return
    end
    
    local currentDrawable = bagItem.metadata and bagItem.metadata.drawable
    if not currentDrawable then
        processingRequests[playerId] = nil
        cb({success = false, message = "Balo không có thông tin drawable"})
        return
    end
    
    -- Kiểm tra có thể trao đổi không
    local canUpgrade, currentLevel = isDrawableUpgradeable(currentDrawable, gender)
    if not canUpgrade then
        print("Debug: Drawable", currentDrawable, "is not upgradeable for gender", gender)
        processingRequests[playerId] = nil
        cb({success = false, message = "Balo này không thể trao đổi"})
        return
    end
    
    -- Lấy chi phí coin cho level hiện tại
    local coinCost = Config.CoinUpgrade.cost_per_level[currentLevel]
    if not coinCost then
        processingRequests[playerId] = nil
        cb({success = false, message = "Không tìm thấy giá coin cho level này"})
        return
    end
    
    -- Kiểm tra coin của player
    local playerCoin = getPlayerCoin(source)
    if playerCoin < coinCost then
        processingRequests[playerId] = nil
        cb({success = false, message = string.format("Không đủ coin. Cần %d coin, bạn có %d coin", coinCost, playerCoin)})
        return
    end
    
    -- Kiểm tra và trừ requirements (vật phẩm cần thiết)
    local doHiem = bagItem.metadata and bagItem.metadata.DoHiem or "Uncommon"
    local requirements = Config.UpgradeRequirements[doHiem]
    if requirements then
        -- Kiểm tra đủ vật phẩm không
        for _, req in pairs(requirements) do
            local hasCount = exports.ox_inventory:GetItemCount(source, req.item)
            if hasCount < req.amount then
                processingRequests[playerId] = nil
                cb({success = false, message = string.format("Không đủ %s (cần %d, có %d)", req.item, req.amount, hasCount)})
                return
            end
        end
        
        -- Trừ vật phẩm cần thiết
        for _, req in pairs(requirements) do
            exports.ox_inventory:RemoveItem(source, req.item, req.amount)
            --print(string.format("Debug: Coin upgrade removed %d %s", req.amount, req.item))
        end
    end
    
    -- Trừ coin
    if not removePlayerCoin(source, coinCost) then
        processingRequests[playerId] = nil -- Unlock nếu thất bại
        cb({success = false, message = "Không thể trừ coin"})
        return
    end
    
    -- Lấy danh sách upgrade options cho level hiện tại
    local levelConfig = Config.UpgradeLevels[gender][currentLevel]
    local upgradeOptions = {}
    
    -- Thêm normal upgrade options với weight cao hơn (loại bỏ drawable hiện tại)
    if levelConfig.upgrade_normal_drawables then
        for _, drawableItem in pairs(levelConfig.upgrade_normal_drawables) do
            if drawableItem ~= currentDrawable then -- Không thêm drawable hiện tại
                table.insert(upgradeOptions, {drawable = drawableItem, type = "normal", level = currentLevel})
            end
        end
    end
    
    -- Thêm rare upgrade options với weight thấp hơn (loại bỏ drawable hiện tại)
    if levelConfig.upgrade_rare_drawables then
        for _, drawableItem in pairs(levelConfig.upgrade_rare_drawables) do
            if drawableItem ~= currentDrawable then -- Không thêm drawable hiện tại
                table.insert(upgradeOptions, {drawable = drawableItem, type = "rare", level = currentLevel})
            end
        end
    end
    
    if #upgradeOptions == 0 then
        cb({success = false, message = "Không có tùy chọn trao đổi"})
        return
    end
    
    -- Xác định loại upgrade dựa trên tỷ lệ config
    local rareChance = Config.CoinUpgrade.rare_chance or 20
    local roll = math.random(1, 100)
    local upgradeType = (roll <= rareChance) and "rare" or "normal"
    
    -- Lọc options theo loại được chọn
    local filteredOptions = {}
    for _, option in pairs(upgradeOptions) do
        if option.type == upgradeType then
            table.insert(filteredOptions, option)
        end
    end
    
    -- Nếu không có options cho loại được chọn, fallback về tất cả options
    if #filteredOptions == 0 then
        filteredOptions = upgradeOptions
    end
    
    -- Chọn ngẫu nhiên một option từ danh sách đã lọc
    local selectedOption = filteredOptions[math.random(1, #filteredOptions)]
    local newDrawable = selectedOption.drawable
    
    -- Lấy độ hiếm hiện tại từ metadata balo cũ
    local currentRarity = bagItem.metadata and bagItem.metadata.DoHiem or "Uncommon"
    
    -- Xác định cấp độ mới và độ hiếm theo yêu cầu
    local newLevel = currentLevel  -- Capdo giữ nguyên cấp độ cũ
    local newRarity = currentRarity  -- Mặc định giữ nguyên độ hiếm
    
    -- Xác định độ hiếm mới dựa vào loại upgrade
    if selectedOption.type == "rare" then
        -- upgrade_rare_drawables: tăng 1 bậc theo Config.RarityHierarchy
        newRarity = UpgradeRarity(currentRarity)
    else
        -- upgrade_normal_drawables: giữ nguyên độ hiếm
        newRarity = currentRarity
    end
    
    -- Xóa balo cũ ngay lập tức
    exports.ox_inventory:RemoveItem(source, Config.BagItem, 1, nil, bagSlot)
    
    -- KHÔNG add balo mới ngay - chờ người chơi nhấn OK
    
    -- Unlock sau cooldown time
    SetTimeout(COOLDOWN_TIME, function()
        processingRequests[playerId] = nil
    end)
    
    -- Lưu thông tin để hiển thị kết quả
    cb({
        success = true, 
        type = 'success',
        message = string.format("trao đổi thành công! Drawable: %d (%s), Cấp độ: %d, Tiêu tốn: %d coin", 
            newDrawable, selectedOption.type, newLevel, coinCost),
        newDrawable = newDrawable,
        newType = selectedOption.type,
        newRarity = newRarity,
        newCapdo = newLevel,
        newLevel = newLevel, -- Alias cho React
        newDoHiem = newRarity,
        coinSpent = coinCost,
        countdownTime = Config.CoinUpgrade.countdown_time,
        slot = bagSlot,
        oldMetadata = bagItem.metadata, -- ✅ Pass metadata CŨ từ bagItem
        gender = gender,
        upgradeType = 'coin', -- Đánh dấu đây là loại coin upgrade
        isRare = (selectedOption.type == 'rare') -- Có phải rare upgrade không
    })
end)

-- Callback để confirm và thực sự update balo coin upgrade sau khi nhấn OK
QBCore.Functions.CreateCallback('xn_thamdinhbalo:confirmCoinUpgrade', function(source, cb, resultData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, message = "Player not found"})
        return
    end
    
    -- Kiểm tra lock để chống duplicate khi bấm OK nhiều lần
    local playerId = Player.PlayerData.citizenid .. "_confirm"
    if processingRequests[playerId] then
        cb({success = false, message = "Đang xử lý, vui lòng đợi..."})
        return
    end
    
    -- Lock request
    processingRequests[playerId] = true
    
    -- Nhận dữ liệu từ React
    local newDrawable = resultData.newDrawable
    local gender = resultData.gender or 'male'
    local oldMetadata = resultData.oldMetadata or {}
    
    -- ✅ GIỮ NGUYÊN 100% METADATA CŨ, CHỈ THAY ĐỔI DRAWABLE VÀ IMAGE
    local newMetadata = {}
    
    -- Copy toàn bộ metadata cũ (bao gồm Capdo, DoHiem, serial, fromGacha...)
    for k, v in pairs(oldMetadata) do
        newMetadata[k] = v
    end
    
    -- ✅ ĐẢM BẢO GIỮ SERIAL NẾU CÓ
    if oldMetadata.serial then
        newMetadata.serial = oldMetadata.serial
    end
    
    -- Chỉ thay đổi drawable và image
    local imageUrl = string.format('%s/%s_%d_%d.%s', 
        Config.ImageSettings.Url, 
        gender, 
        Config.ImageSettings.component_id,
        newDrawable, 
        Config.ImageSettings.Extension
    )
    
    newMetadata.drawable = newDrawable
    newMetadata.id = newDrawable
    newMetadata.label = string.format("Túi xách %d", newDrawable)
    newMetadata.image = imageUrl
    newMetadata.imageurl = imageUrl
    
    -- Capdo và DoHiem giữ nguyên từ oldMetadata
    
    -- Thêm balo mới vào inventory
    local success = exports.ox_inventory:AddItem(source, Config.BagItem, 1, newMetadata)
    
    -- Unlock sau khi hoàn thành
    SetTimeout(1000, function()
        processingRequests[playerId] = nil
    end)
    
    if success then
        cb({success = true, message = "Đã nhận balo mới"})
    else
        cb({success = false, message = "Không thể thêm balo mới"})
    end
end)

-- Callback xử lý đổi mẫu theo yêu cầu trực tiếp
QBCore.Functions.CreateCallback('xn_thamdinhbalo:claimCustomBag', function(source, cb, bagSlot, targetDrawable, clientGender)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, message = "Player not found"})
        return
    end
    
    local playerId = Player.PlayerData.citizenid
    if processingRequests[playerId] then
        cb({success = false, message = "Đang xử lý yêu cầu, vui lòng đợi..."})
        return
    end
    
    processingRequests[playerId] = true
    
    local gender = clientGender or "male"
    
    -- Lấy thông tin balo từ slot
    local inventory = exports.ox_inventory:GetInventory(source, false)
    if not inventory or not inventory.items or not inventory.items[bagSlot] then
        processingRequests[playerId] = nil
        cb({success = false, message = "Không tìm thấy balo"})
        return
    end
    
    local bagItem = inventory.items[bagSlot]
    if bagItem.name ~= Config.BagItem or not bagItem.metadata then
        processingRequests[playerId] = nil
        cb({success = false, message = "Item không hợp lệ"})
        return
    end
    
    local drawable = bagItem.metadata.drawable
    local doHiem = bagItem.metadata.DoHiem or 'Rare'
    
    -- Xác định level thực sự dựa theo drawable, không phải metadata.Capdo
    local isUpgradeable, actualLevel = isDrawableUpgradeable(drawable, gender)
    if not isUpgradeable then
        processingRequests[playerId] = nil
        cb({success = false, message = "Balo này không thể trao đổi (drawable không hợp lệ)"})
        return
    end
    
    local capdo = actualLevel
    
    -- Lấy config level cho gender và cấp độ tương ứng
    local genderConfig = Config.UpgradeLevels[gender]
    if not genderConfig then
        processingRequests[playerId] = nil
        cb({success = false, message = "Cấu hình gender không hợp lệ"})
        return
    end
    
    local levelConfig = genderConfig[capdo]
    if not levelConfig then
        processingRequests[playerId] = nil
        cb({success = false, message = "Cấp độ balo không hợp lệ"})
        return
    end
    
    -- Kiểm tra xem targetDrawable có nằm trong danh sách upgrade_normal_drawables hoặc upgrade_rare_drawables hay không
    local isValidTarget = false
    if levelConfig.upgrade_normal_drawables then
        for _, d in pairs(levelConfig.upgrade_normal_drawables) do
            if d == targetDrawable then
                isValidTarget = true
                break
            end
        end
    end
    if not isValidTarget and levelConfig.upgrade_rare_drawables then
        for _, d in pairs(levelConfig.upgrade_rare_drawables) do
            if d == targetDrawable then
                isValidTarget = true
                break
            end
        end
    end
    
    if not isValidTarget then
        processingRequests[playerId] = nil
        cb({success = false, message = "Mẫu balo được chọn không nằm trong danh sách có thể nhận"})
        return
    end
    
    -- Sử dụng Custom Upgrade Requirements
    local requirementsConfig = Config.CustomUpgradeRequirementsByLevel[capdo] or Config.CustomUpgradeRequirements[doHiem]
    if not requirementsConfig then
        processingRequests[playerId] = nil
        cb({success = false, message = "Không tìm thấy cấu hình vật phẩm yêu cầu cho cấp độ này"})
        return
    end
    
    -- Kiểm tra vật phẩm cần thiết
    for _, req in pairs(requirementsConfig) do
        local playerItem = exports.ox_inventory:Search(source, 'count', req.item)
        local hasCount = 0
        if type(playerItem) == 'number' then
            hasCount = playerItem
        elseif type(playerItem) == 'table' and playerItem.count then
            hasCount = playerItem.count
        elseif playerItem then
            hasCount = tonumber(playerItem) or 0
        end
        
        if hasCount < req.amount then
            processingRequests[playerId] = nil
            cb({success = false, message = string.format("Không đủ %s (cần %d, có %d)", req.item, req.amount, hasCount)})
            return
        end
    end
    
    -- Trừ vật phẩm cần thiết
    for _, req in pairs(requirementsConfig) do
        exports.ox_inventory:RemoveItem(source, req.item, req.amount)
    end
    
    -- Giữ nguyên 100% metadata cũ, chỉ thay đổi drawable và image
    local newMetadata = {}
    for k, v in pairs(bagItem.metadata) do
        newMetadata[k] = v
    end
    
    newMetadata.drawable = targetDrawable
    newMetadata.id = targetDrawable
    newMetadata.label = string.format("Túi xách %d", targetDrawable)
    newMetadata.imageurl = string.format("%s/%s_5_%d.%s", 
        Config.ImageSettings.Url, 
        gender, 
        targetDrawable, 
        Config.ImageSettings.Extension
    )
    newMetadata.image = newMetadata.imageurl
    
    -- Xóa balo cũ
    exports.ox_inventory:RemoveItem(source, Config.BagItem, 1, bagItem.metadata, bagSlot)
    
    -- Thêm balo mới
    local success = exports.ox_inventory:AddItem(source, Config.BagItem, 1, newMetadata)
    
    processingRequests[playerId] = nil
    
    if success then
        cb({success = true, message = "Đã đổi mẫu balo theo yêu cầu thành công"})
    else
        cb({success = false, message = "Lỗi khi thêm balo mới"})
    end
end)

-- Test command để kiểm tra config

-- RegisterCommand('testconfig', function(source, args, rawCommand)
--     --print("=== CONFIG TEST ===")
--     --print("Config.UpgradeLevels exists:", Config.UpgradeLevels ~= nil)
    
--     if Config.UpgradeLevels then
--         --print("Available genders:")
--         for gender, levels in pairs(Config.UpgradeLevels) do
--             --print("  Gender:", gender)
--             for level, config in pairs(levels) do
--                 --print("    Level:", level, "has", #(config.upgradeable_drawables or {}), "upgradeable drawables")
--             end
--         end
--     end
    
--     -- Test gender detection
--     local Player = QBCore.Functions.GetPlayer(source)
--     if Player then
--         --print("Player found, testing gender detection from client...")
--         TriggerClientEvent('xn_thamdinhbalo:testGender', source)
--     end
-- end, false)

-- Event để nhận kết quả test gender từ client
RegisterNetEvent('xn_thamdinhbalo:testGenderResult')
AddEventHandler('xn_thamdinhbalo:testGenderResult', function(gender)
    local source = source
    --print("=== GENDER TEST RESULT FROM CLIENT ===")
    --print("Player:", source, "Gender:", gender)
    
    -- Test config access
    if Config.UpgradeLevels and Config.UpgradeLevels[gender] then
        --print("Config found for gender:", gender)
        local levels = {}
        for level, config in pairs(Config.UpgradeLevels[gender]) do
            table.insert(levels, level)
        end
        --print("Available levels:", json.encode(levels))
    else
        --print("ERROR: No config found for gender:", gender)
    end
    
    TriggerClientEvent('QBCore:Notify', source, 'Gender test complete - check server console', 'success')
end)

-- Test command để kiểm tra drawable vs gender
-- RegisterCommand('testdrawable', function(source, args, rawCommand)
--     local drawable = tonumber(args[1]) or 89
--     local testGender = args[2] or "male"
    
--     --print("=== DRAWABLE TEST ===")
--     --print("Testing drawable:", drawable, "for gender:", testGender)
    
--     local isUpgradeable, level = isDrawableUpgradeable(drawable, testGender)
--     --print("Result - Upgradeable:", isUpgradeable, "Level:", level)
    
--     TriggerClientEvent('QBCore:Notify', source, string.format('Drawable %d for %s: %s (Level: %s)', drawable, testGender, tostring(isUpgradeable), tostring(level)), 'info')
-- end, false)
    
-- -- Comprehensive debug command để kiểm tra drawable 197
-- RegisterCommand('check197', function(source, args, rawCommand)
--     --print("=== CHECKING DRAWABLE 197 ===")
    
--     -- 1. Kiểm tra config
--     --print("1. Config check:")
--     local femaleConfig = Config.UpgradeLevels['female']
--     local maleConfig = Config.UpgradeLevels['male']
    
--     if femaleConfig and femaleConfig[3] then
--         local normalDrawables = femaleConfig[3].upgrade_normal_drawables or {}
--         local rareDrawables = femaleConfig[3].upgrade_rare_drawables or {}
        
--         local in_normal = false
--         local in_rare = false
        
--         for _, d in pairs(normalDrawables) do
--             if d == 197 then in_normal = true end
--         end
        
--         for _, d in pairs(rareDrawables) do
--             if d == 197 then in_rare = true end
--         end
        
--         --print("  Female level 3 - 197 in normal:", in_normal, "in rare:", in_rare)
--         --print("  Female normal drawables:", json.encode(normalDrawables))
--         --print("  Female rare drawables:", json.encode(rareDrawables))
--     end
    
--     if maleConfig and maleConfig[3] then
--         local normalDrawables = maleConfig[3].upgrade_normal_drawables or {}
--         local rareDrawables = maleConfig[3].upgrade_rare_drawables or {}
        
--         local in_normal = false
--         local in_rare = false
        
--         for _, d in pairs(normalDrawables) do
--             if d == 197 then in_normal = true end
--         end
        
--         for _, d in pairs(rareDrawables) do
--             if d == 197 then in_rare = true end
--         end
        
--         --print("  Male level 3 - 197 in normal:", in_normal, "in rare:", in_rare)
--         --print("  Male normal drawables:", json.encode(normalDrawables))
--         --print("  Male rare drawables:", json.encode(rareDrawables))
--     end
    
--     TriggerClientEvent('QBCore:Notify', source, 'Check drawable 197 complete - see console', 'info')
-- end, false)

-- -- Command để set metadata.sex cho tất cả balo dựa trên drawable
-- RegisterCommand('fixbagsex', function(source, args, rawCommand)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end
    
--     local inventory = exports.ox_inventory:GetInventory(source, false)
--     if not inventory or not inventory.items then
--         TriggerClientEvent('QBCore:Notify', source, 'Không thể lấy inventory', 'error')
--         return
--     end
    
--     local fixedCount = 0
    
--     -- Duyệt qua tất cả items
--     for slot, item in pairs(inventory.items) do
--         if item.name == Config.BagItem and item.metadata then
--             local drawable = item.metadata.drawable
--             if drawable and not item.metadata.sex then
                
--                 -- Kiểm tra drawable thuộc gender nào
--                 local isFemaleDrawable = false
--                 local isMaleDrawable = false
                
--                 for genderKey, genderConfig in pairs(Config.UpgradeLevels) do
--                     for levelKey, levelConfig in pairs(genderConfig) do
--                         if levelConfig.upgradeable_drawables then
--                             for _, configDrawable in pairs(levelConfig.upgradeable_drawables) do
--                                 if configDrawable == drawable then
--                                     if genderKey == "female" then
--                                         isFemaleDrawable = true
--                                     else
--                                         isMaleDrawable = true
--                                     end
--                                 end
--                             end
--                         end
--                     end
--                 end
                
--                 -- Set metadata.sex
--                 if isFemaleDrawable and not isMaleDrawable then
--                     item.metadata.sex = 1 -- female
--                     fixedCount = fixedCount + 1
--                     --print("Fixed bag drawable", drawable, "set sex = 1 (female)")
--                 elseif isMaleDrawable and not isFemaleDrawable then
--                     item.metadata.sex = 0 -- male
--                     fixedCount = fixedCount + 1
--                     --print("Fixed bag drawable", drawable, "set sex = 0 (male)")
--                 end
--             end
--         end
--     end
    
--     TriggerClientEvent('QBCore:Notify', source, string.format('Đã fix %d balo metadata.sex', fixedCount), 'success')
-- end, false)

-- -- Test command để kiểm tra config và gender
-- RegisterCommand('debugbag', function(source, args, rawCommand)
--     --print("=== DEBUG BAG SYSTEM ===")
    
--     -- Test config
--     --print("1. Testing config...")
--     --print("Config.UpgradeLevels exists:", Config.UpgradeLevels ~= nil)
    
--     if Config.UpgradeLevels then
--         for gender, levels in pairs(Config.UpgradeLevels) do
--             --print("  Gender:", gender)
--             for level, config in pairs(levels) do
--                 --print("    Level:", level, "- upgradeable_drawables count:", #(config.upgradeable_drawables or {}))
--             end
--         end
--     end
    
--     -- Test với client gender
--     --print("2. Testing client gender...")
--     TriggerClientEvent('xn_thamdinhbalo:debugGender', source)
    
--     TriggerClientEvent('QBCore:Notify', source, 'Debug test started - check server console', 'info')
-- end, false)

-- Event để nhận debug gender từ client
RegisterNetEvent('xn_thamdinhbalo:debugGenderResult')
AddEventHandler('xn_thamdinhbalo:debugGenderResult', function(gender, pedModel)
    local source = source
    --print("=== CLIENT GENDER DEBUG RESULT ===")
    --print("Player:", source)
    --print("Gender detected:", gender)
    --print("Ped model:", pedModel)
    
    -- Test config access với gender này
    local testDrawable = 89
    --print("Testing drawable", testDrawable, "with gender", gender)
    
    if Config.UpgradeLevels and Config.UpgradeLevels[gender] then
        --print("✓ Config found for gender:", gender)
        local found = false
        for level, config in pairs(Config.UpgradeLevels[gender]) do
            if config.upgradeable_drawables then
                for _, drawable in pairs(config.upgradeable_drawables) do
                    if drawable == testDrawable then
                        --print("✓ Drawable", testDrawable, "found in level", level)
                        found = true
                        break
                    end
                end
            end
            if found then break end
        end
        if not found then
            --print("✗ Drawable", testDrawable, "NOT found in any level")
        end
    else
        --print("✗ NO config found for gender:", gender)
    end
end)

-- -- SIMPLE TEST COMMAND  
-- RegisterCommand('simpletest', function(source, args, rawCommand)
--     --print("=== SIMPLE TEST ===")
    
--     -- Test 1: Basic config
--     --print("Config exists:", Config ~= nil)
--     --print("UpgradeLevels exists:", Config and Config.UpgradeLevels ~= nil)
    
--     if Config and Config.UpgradeLevels then
--         -- Test 2: Gender configs
--         --print("Male config exists:", Config.UpgradeLevels['male'] ~= nil)
--         --print("Female config exists:", Config.UpgradeLevels['female'] ~= nil)
        
--         -- Test 3: Try access female
--         if Config.UpgradeLevels['female'] then
--             --print("Female level 3 exists:", Config.UpgradeLevels['female'][3] ~= nil)
--             if Config.UpgradeLevels['female'][3] then
--                 local drawables = Config.UpgradeLevels['female'][3].upgradeable_drawables or {}
--                 --print("Female level 3 drawable count:", #drawables)
--                 --print("First few drawables:", drawables[1] or "none", drawables[2] or "none", drawables[3] or "none")
--             end
--         end
--     end
    
--     TriggerClientEvent('QBCore:Notify', source, 'Simple test done - check console', 'success')
-- end, false)
