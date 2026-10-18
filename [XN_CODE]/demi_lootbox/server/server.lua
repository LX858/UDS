local POOL_SIZE = 100

local function tableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

Config = Config or {}

-- Tỷ lệ phần trăm chính xác theo từng phẩm (Tổng = 100.0%)
-- Hỗ trợ chính xác số thập phân như 0.5% (tương đương 5/1000 hoặc 50/10000)
Config.RarityChances = {
    legendary = 0.5,   -- 0.5% (Đặc biệt - Đỏ)
    epic      = 3.5,   -- 3.5% (Sử thi - Cam)
    rare      = 12.0,  -- 12.0% (Hiếm - Tím)
    uncommon  = 24.0,  -- 24.0% (Không phổ biến - Xanh dương)
    common    = 60.0,  -- 60.0% (Thường - Xanh lá)
}

local function rollWinningRarity(case)
    -- Random chính xác đến 0.01% (thang đo 10.000)
    local roll = math.random(1, 10000) / 100 -- Giá trị từ 0.01 đến 100.00

    local chances = Config.RarityChances or {
        legendary = 0.5,
        epic = 3.5,
        rare = 12.0,
        uncommon = 24.0,
        common = 60.0,
    }

    -- Thứ tự từ quý hiếm nhất → thường nhất
    local order = { 'legendary', 'epic', 'rare', 'uncommon', 'common' }

    -- Tính cumulative và tìm rarity được roll trúng
    local cumulative = 0
    local rolledRarity = nil
    for _, rarity in ipairs(order) do
        local chance = chances[rarity] or 0
        cumulative = cumulative + chance
        if roll <= cumulative then
            rolledRarity = rarity
            break
        end
    end

    -- Nếu roll trúng rarity có item trong hòm → trả về luôn
    if rolledRarity and case[rolledRarity] and #case[rolledRarity] > 0 then
        return rolledRarity
    end

    -- Fallback: nếu hòm không có item của rarity đã roll,
    -- tìm xuống rarity thấp hơn (common, uncommon, rare...) thay vì leo lên legendary
    local fallbackOrder = { 'common', 'uncommon', 'rare', 'epic', 'legendary' }
    for _, rarity in ipairs(fallbackOrder) do
        if case[rarity] and #case[rarity] > 0 then
            return rarity
        end
    end

    return 'common'
end

local function generateLootPoolFromCase(case, winningItem)
    local pool = {}
    local visualWeights = {
        common = 70,
        uncommon = 22,
        rare = 6,
        epic = 2,
        legendary = 0,
    }

    -- Nếu có đồ legendary trong hòm, thi thoảng hiển thị 1 món trên dải quay để tăng sự hấp dẫn
    if case.legendary and #case.legendary > 0 and math.random(100) <= 40 then
        visualWeights.legendary = 1
    end

    while #pool < POOL_SIZE do
        local rarity = next(visualWeights)
        if not rarity then break end

        if case[rarity] and #case[rarity] > 0 then
            local rawItem = case[rarity][math.random(#case[rarity])]
            local item = {}
            for k, v in pairs(rawItem) do
                item[k] = v
            end
            item.rarity = rarity
            pool[#pool + 1] = item
        end

        visualWeights[rarity] -= 1
        if visualWeights[rarity] <= 0 then
            visualWeights[rarity] = nil
        end
    end

    -- Nếu pool chưa đủ kích thước do hòm ít món, bổ sung ngẫu nhiên
    if #pool < POOL_SIZE then
        local availableRarities = {}
        for r, items in pairs(case) do
            if type(items) == 'table' and #items > 0 then
                availableRarities[#availableRarities + 1] = r
            end
        end
        while #pool < POOL_SIZE and #availableRarities > 0 do
            local r = availableRarities[math.random(#availableRarities)]
            local rawItem = case[r][math.random(#case[r])]
            local item = {}
            for k, v in pairs(rawItem) do item[k] = v end
            item.rarity = r
            pool[#pool + 1] = item
        end
    end

    shuffle(pool)
    pool = tableConcat(pool, pool)

    return pool
end


local playerLootQueue = {}

Config = Config or {}

Config.componentMapping = {
    hat = { component = 0, prop = true },
    mask = { component = 1, prop = false },
    glasses = { component = 1, prop = true },
    chain = { component = 7, prop = false },
    gloves = { component = 3, prop = false },
    torso = { component = 11, prop = false },
    watch = { component = 6, prop = true },
    pants = { component = 4, prop = false },
    earrings = { component = 2, prop = true },
    bag = { component = 5, prop = false },
    shirt = { component = 8, prop = false },
    vest = { component = 9, prop = false },
    bracelets = { component = 7, prop = true },
    shoes = { component = 6, prop = false },
}

local function formatClothingImageUrl(imageName)
    if not imageName then return nil end
    return "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main/" .. imageName .. ".webp"
end

local function resolveClothByGender(clothCfg, gender)
    if not clothCfg then return nil end
    gender = gender or 'male'

    local clothType = clothCfg.type or clothCfg.category or clothCfg.componentType
    local count = clothCfg.count or clothCfg.amount or 1
    local texture = clothCfg.texture or 0
    local id = clothCfg.id or clothCfg.drawable

    -- Gender specific sub-tables: male = { id = ..., texture = ... }, female = { id = ... }
    if gender == 'female' and clothCfg.female ~= nil then
        if type(clothCfg.female) == 'table' then
            id = clothCfg.female.id or clothCfg.female.drawable or id
            texture = clothCfg.female.texture or texture
            clothType = clothCfg.female.type or clothType
            count = clothCfg.female.count or clothCfg.female.amount or count
        elseif type(clothCfg.female) == 'number' or type(clothCfg.female) == 'string' then
            id = clothCfg.female
        end
    elseif gender == 'male' and clothCfg.male ~= nil then
        if type(clothCfg.male) == 'table' then
            id = clothCfg.male.id or clothCfg.male.drawable or id
            texture = clothCfg.male.texture or texture
            clothType = clothCfg.male.type or clothType
            count = clothCfg.male.count or clothCfg.male.amount or count
        elseif type(clothCfg.male) == 'number' or type(clothCfg.male) == 'string' then
            id = clothCfg.male
        end
    end

    -- If id is a table: id = { male = 222, female = 225 } or id = { [0] = 222, [1] = 225 }
    if type(id) == 'table' then
        if gender == 'female' then
            id = id.female or id.f or id[1] or id['1'] or id.male or id[0]
        else
            id = id.male or id.m or id[0] or id['0'] or id.female or id[1]
        end
    end

    -- If id_male / id_female or male_id / female_id are used
    if gender == 'female' and (clothCfg.id_female or clothCfg.female_id) then
        id = clothCfg.id_female or clothCfg.female_id
    elseif gender == 'male' and (clothCfg.id_male or clothCfg.male_id) then
        id = clothCfg.id_male or clothCfg.male_id
    end

    -- If texture is a table: texture = { male = 0, female = 1 }
    if type(texture) == 'table' then
        if gender == 'female' then
            texture = texture.female or texture.f or texture[1] or texture['1'] or texture.male or 0
        else
            texture = texture.male or texture.m or texture[0] or texture['0'] or 0
        end
    end

    if gender == 'female' and (clothCfg.texture_female or clothCfg.female_texture) then
        texture = clothCfg.texture_female or clothCfg.female_texture
    elseif gender == 'male' and (clothCfg.texture_male or clothCfg.male_texture) then
        texture = clothCfg.texture_male or clothCfg.male_texture
    end

    return {
        type = clothType,
        id = tonumber(id),
        texture = tonumber(texture) or 0,
        count = tonumber(count) or 1,
        imageName = clothCfg.imageName,
        imageUrl = clothCfg.imageUrl,
        component = clothCfg.component,
    }
end

local function getClothingImageUrl(clothCfg, gender)
    gender = gender or 'male'
    if not clothCfg then return nil end
    if clothCfg.imageUrl then return clothCfg.imageUrl end
    if clothCfg.imageName then
        return formatClothingImageUrl(clothCfg.imageName)
    end

    local resolved = resolveClothByGender(clothCfg, gender)
    if not resolved or not resolved.id then return nil end

    local baseName = resolved.type
    local mapping = Config.componentMapping and Config.componentMapping[baseName]
    local newDrawable = resolved.id

    if mapping then
        local component = mapping.component
        local imageName = string.format("%s_%d_%d", gender, component, newDrawable)
        local imageUrl = "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main/" .. imageName .. ".webp"
        return imageUrl
    elseif type(resolved.component) == "number" or type(resolved.type) == "number" then
        local component = resolved.component or resolved.type
        local imageName = string.format("%s_%d_%d", gender, component, newDrawable)
        local imageUrl = "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main/" .. imageName .. ".webp"
        return imageUrl
    end
    return nil
end

local function getPlayerGender(src)
    local gender = 'male'
    if Bridge.frameWork == "qb" and Bridge.core then
        local Player = Bridge.core.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            local g = Player.PlayerData.charinfo.gender
            if g == 1 or g == 'female' or g == 'f' or g == '1' then
                gender = 'female'
            end
        end
    elseif Bridge.frameWork == "esx" and Bridge.core then
        local Player = Bridge.core.GetPlayerFromId(src)
        if Player then
            local sex = (Player.get and Player.get('sex')) or (Player.variables and Player.variables.sex)
            if sex == 'f' or sex == 1 or sex == 'female' or sex == '1' then
                gender = 'female'
            end
        end
    end
    return gender
end

local function giveClothing(src, clothCfg, gender)
    local resolved = resolveClothByGender(clothCfg, gender)
    if not resolved or not resolved.type or not resolved.id then return end
    if GetResourceState('XNClothes') ~= 'started' then
        print(string.format('^1[demi_lootbox] ERROR: XNClothes resource is not started! Cannot give clothes type: %s, id: %s^7', tostring(resolved.type), tostring(resolved.id)))
        return
    end

    local count = resolved.count or 1
    for _ = 1, count do
        pcall(function()
            exports['XNClothes']:GiveClothingItemBySex(src, resolved.type, resolved.id, resolved.texture or 0, gender)
        end)
    end
end

function GetCaseData(source, caseIndex)
    local case = CASES[caseIndex]
    if not case then return end

    local gender = getPlayerGender(source)

    -- 1. Roll chính xác phần thưởng theo tỷ lệ phần trăm (0.5% Legendary, v.v.)
    local winningRarity = rollWinningRarity(case)
    local rawWinningItem = case[winningRarity][math.random(#case[winningRarity])]
    local winningItem = {}
    for k, v in pairs(rawWinningItem) do
        winningItem[k] = v
    end
    winningItem.rarity = winningRarity

    -- 2. Tạo dải xoay trực quan (Visual Carousel Pool)
    local lootPool = generateLootPoolFromCase(case, winningItem)

    -- 3. Chọn vị trí trúng thưởng ngẫu nhiên trong khoảng dừng của con lăn
    local winner = (math.random(#lootPool - POOL_SIZE) + POOL_SIZE)

    -- 4. Gán món đồ đã roll trúng vào đúng vị trí dừng của con lăn
    lootPool[winner] = winningItem

    -- Auto attach clothing imageUrl for clothing items based on player gender
    for i = 1, #lootPool do
        local item = lootPool[i]
        if not item.imageUrl then
            if item.imageName then
                item.imageUrl = formatClothingImageUrl(item.imageName)
            elseif item.isClothing or item.clothing or (item.type and item.id) then
                item.imageUrl = getClothingImageUrl(item.clothing or item, gender)
            elseif item.clothes and item.clothes[1] then
                item.imageUrl = getClothingImageUrl(item.clothes[1], gender)
            end
        end
    end

    playerLootQueue[source] = lootPool[winner]

    return lootPool, winner - 1
end

RegisterNetEvent('demi_lootbox:getQueuedItem', function()
    local source = source
    local loot = playerLootQueue[source]
    if not loot then
        print("^1 ==================================================================================================")
        print((' [WARNING]: POSSIBLE CHEATER. Player Source %s triggered lootbox get item event while not in queue')
            :format(source))
        print('=================================================================================================')
        print(('PLAYERS IDENTIFIERS = %s'):format(json.encode(GetPlayerIdentifiers(source), { indent = true })))
        print('=================================================================================================^7')
        return
    end

    playerLootQueue[source] = nil
    local gender = getPlayerGender(source)

    -- 1. Additional regular items
    if loot.additionalItems then
        for i = 1, #loot.additionalItems do
            local item = loot.additionalItems[i]
            Bridge.giveItem(source, item.name, item.amount or 1)
        end
    end

    -- 2. Attached clothes table (e.g. clothes = { { type = 'shirt', id = 9999, texture = 0, count = 1 } })
    if loot.clothes then
        for i = 1, #loot.clothes do
            giveClothing(source, loot.clothes[i], gender)
        end
    end

    -- 3. Standalone clothing item reward
    if loot.isClothing or loot.isCloth or (loot.type and loot.id) then
        giveClothing(source, {
            type = loot.type or (loot.clothing and loot.clothing.type),
            id = loot.id or (loot.clothing and loot.clothing.id),
            texture = loot.texture or (loot.clothing and loot.clothing.texture) or 0,
            count = loot.count or loot.amount or 1,
        }, gender)
    elseif loot.name and loot.name ~= '' then
        -- Regular item reward
        Bridge.giveItem(source, loot.name, loot.amount or 1)
    end
end)


exports('addNewLootBox', function(name, contents, cb)
    if CASES[name] then return end
    CASES[name] = contents
    Bridge.RegisterUsableItem(name, function(src)
        if cb then
            cb(src)
        end
        if Bridge.removeItem(src, name, 1) then
            local lootPool, winner = GetCaseData(src, name)
            TriggerClientEvent('demi_lootbox:RollCase', src, lootPool, winner)
        end
    end)

    for rarity, items in pairs(contents) do
        for i = 1, #items do
            local item = CASES[name][rarity][i]
            if not item.label and item.name then
                local label = Bridge.getitemLabel(item.name)
                if label and label ~= "ERROR" then
                    CASES[name][rarity][i].label = label
                end
            end
        end
    end
end)

exports('removeLootBox', function(name)
    CASES[name] = nil
end)
