-- Cooldown tracking
local playerCooldowns = {}

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

--- Kiểm tra cooldown cho player
---@param source number
---@return boolean
local function checkCooldown(source)
    local now = GetGameTimer()
    local lastTime = playerCooldowns[source]
    
    if lastTime and (now - lastTime) < Config.ExchangeCooldown then
        return false
    end
    
    return true
end

--- Set cooldown cho player
---@param source number
local function setCooldown(source)
    playerCooldowns[source] = GetGameTimer()
end

--- Build imageurl cho clothing item
---@param sex string
---@param uiCategory string
---@param drawable number
---@return string
local function buildImageUrl(sex, uiCategory, drawable)
    local compData = Config.ComponentMapping[uiCategory]
    if not compData then return "" end
    
    local url = ""
    if compData.isProp then
        -- Format: female_prop_0_1.webp
        url = Config.Url .. "/" .. sex .. "_prop_" .. compData.id .. "_" .. drawable .. "." .. Config.Extension
    else
        -- Format: female_11_0.webp
        url = Config.Url .. "/" .. sex .. "_" .. compData.id .. "_" .. drawable .. "." .. Config.Extension
    end
    
    if Config.Debug then
        print(string.format('[DEBUG] Built imageurl: %s (sex=%s, uiCategory=%s, drawable=%d, isProp=%s)', url, sex, uiCategory, drawable, tostring(compData.isProp)))
    end
    return url
end

--- Tìm uiCategory từ itemName
---@param itemName string
---@return string|nil
local function findUiCategoryByItemName(itemName)
    for uiCat, itemN in pairs(Config.UIToItemMapping) do
        if itemN == itemName then
            return uiCat
        end
    end
    return nil
end

-- =====================================================
-- CALLBACK: LẤY DANH SÁCH ITEM QUẦN ÁO CỦA PLAYER
-- =====================================================

lib.callback.register('clothes_exchange:getPlayerClothingItems', function(source, sex)
    -- Validate sex
    if sex ~= 'male' and sex ~= 'female' then
        return {}
    end
    
    -- Lấy inventory items
    local inventory = exports.ox_inventory:GetInventoryItems(source)
    if not inventory then
        return {}
    end
    
    local clothingItems = {}
    
    -- Lọc items là quần áo và có metadata hợp lệ
    for _, item in pairs(inventory) do
        if item and item.name and item.metadata then
            local uiCategory = findUiCategoryByItemName(item.name)
            
            if uiCategory then
                local rarity = item.metadata.DoHiem or item.metadata.dohiem
                local drawable = item.metadata.drawable
                local isNew = item.metadata.isnew or item.metadata.isNew
                
                -- LOẠI BỎ items có metadata.isnew = 'yes' nếu không cho phép đổi đồ mới
                if not Config.AllowNewItems and (isNew == 'yes' or isNew == 'Yes' or isNew == 'YES' or isNew == true) then
                    if Config.Debug then
                        print(string.format('[DEBUG] Item %s bị loại vì isnew=%s (Config.AllowNewItems is false)', item.name, tostring(isNew)))
                    end
                    goto continue
                end
                
                -- Lấy giới tính của ITEM
                local itemSex = item.metadata.sex or item.metadata.gender
                if itemSex ~= 'male' and itemSex ~= 'female' then
                    goto continue
                end
                
                -- Chỉ cho phép đổi nếu đồ ngược giới tính với nhân vật (Nam có đồ Nữ, Nữ có đồ Nam)
                if sex == 'male' and itemSex ~= 'female' then
                    goto continue
                elseif sex == 'female' and itemSex ~= 'male' then
                    goto continue
                end
                
                if drawable and rarity then
                    -- ƯU TIÊN dùng imageurl từ metadata (đồ cũ của player)
                    local imageurl = item.metadata.imageurl
                    
                    -- Chỉ build lại nếu metadata không có imageurl
                    if not imageurl or imageurl == "" or imageurl == " " then
                        imageurl = buildImageUrl(itemSex, uiCategory, drawable)
                        if Config.Debug then
                            print(string.format('[DEBUG] No metadata imageurl, built: %s (itemSex=%s)', imageurl, itemSex))
                        end
                    else
                        if Config.Debug then
                            print(string.format('[DEBUG] Using metadata imageurl: %s', imageurl))
                        end
                    end
                    
                    table.insert(clothingItems, {
                        slot = item.slot,
                        name = item.name,
                        label = item.label or item.name,
                        count = item.count or 1,
                        metadata = item.metadata,
                        uiCategory = uiCategory,
                        rarity = rarity,
                        drawable = drawable,
                        imageurl = imageurl
                    })
                end
            end
            
            ::continue::
        end
    end
    
    return clothingItems
end)

-- =====================================================
-- CALLBACK: LẤY DANH SÁCH DRAWABLE CÓ THỂ ĐỔI
-- =====================================================

lib.callback.register('clothes_exchange:getExchangeOptions', function(source, data)
    -- Validate input
    if not data or not data.slot or not data.itemName or not data.uiCategory or not data.sex then
        return {}
    end
    
    local slot = tonumber(data.slot)
    local itemName = data.itemName
    local uiCategory = data.uiCategory
    local sex = data.sex
    
    -- Validate sex
    if sex ~= 'male' and sex ~= 'female' then
        return {}
    end
    
    -- Validate item mapping
    if Config.UIToItemMapping[uiCategory] ~= itemName then
        return {}
    end
    
    -- Lấy item từ slot trong inventory
    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item or item.name ~= itemName then
        return {}
    end
    
    -- Kiểm tra metadata
    if not item.metadata or not item.metadata.drawable then
        return {}
    end
    
    -- BLOCK items có isnew = 'yes' nếu không cho phép đổi đồ mới
    local isNew = item.metadata.isnew or item.metadata.isNew
    if not Config.AllowNewItems and (isNew == 'yes' or isNew == 'Yes' or isNew == 'YES' or isNew == true) then
        return {}
    end
    
    local rarity = item.metadata.DoHiem or item.metadata.dohiem
    if not rarity then
        return {}
    end
    
    -- Lấy giới tính của ITEM (không phải ped)
    local itemSex = item.metadata.sex or item.metadata.gender
    if not itemSex or (itemSex ~= 'male' and itemSex ~= 'female') then
        return {}
    end
    
    -- Kiểm tra giới tính của item (phải ngược với giới tính nhân vật)
    if sex == 'male' and itemSex ~= 'female' then
        return {}
    elseif sex == 'female' and itemSex ~= 'male' then
        return {}
    end
    
    -- Lấy danh sách drawable của giới tính NHÂN VẬT (để đổi sang giới tính của mình)
    local drawableList = Config.Dohiem[sex] and Config.Dohiem[sex][itemName] and Config.Dohiem[sex][itemName][rarity]
    if Config.Debug then
        print(string.format('[DEBUG] getExchangeOptions: itemName=%s, itemSex=%s, targetSex=%s, rarity=%s', itemName, itemSex, sex, rarity))
    end
    if not drawableList or #drawableList == 0 then
        return {}
    end
    
    -- Build danh sách options (các drawable CÓ THỂ ĐỔI - không dùng metadata)
    local options = {}
    
    for _, drawable in ipairs(drawableList) do
        -- Build imageurl cho từng option mới theo giới tính NHÂN VẬT (sex)
        local imageurl = buildImageUrl(sex, uiCategory, drawable)
        table.insert(options, {
            drawable = drawable,
            imageurl = imageurl,
            isOwned = false
        })
    end
    
    return options
end)

-- =====================================================
-- CALLBACK: THỰC HIỆN TRAO ĐỔI ITEM
-- =====================================================

lib.callback.register('clothes_exchange:exchangeItem', function(source, data)
    -- Validate input
    if not data or not data.slot or not data.itemName or not data.uiCategory or not data.targetDrawable or not data.sex then
        return {
            success = false,
            message = Config.Notify.invalid_item
        }
    end
    
    -- Validate cooldown
    if not checkCooldown(source) then
        return {
            success = false,
            message = Config.Notify.cooldown
        }
    end
    
    local slot = tonumber(data.slot)
    local itemName = data.itemName
    local uiCategory = data.uiCategory
    local targetDrawable = tonumber(data.targetDrawable)
    local sex = data.sex
    
    -- Validate sex
    if sex ~= 'male' and sex ~= 'female' then
        return {
            success = false,
            message = Config.Notify.invalid_sex
        }
    end
    
    -- Validate item mapping
    if Config.UIToItemMapping[uiCategory] ~= itemName then
        return {
            success = false,
            message = Config.Notify.invalid_item
        }
    end
    
    -- Validate targetDrawable
    if not targetDrawable or targetDrawable < 0 then
        return {
            success = false,
            message = Config.Notify.invalid_drawable
        }
    end
    
    -- Lấy item từ slot trong inventory
    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item or item.name ~= itemName then
        return {
            success = false,
            message = Config.Notify.invalid_item
        }
    end
    
    -- Kiểm tra metadata
    if not item.metadata or not item.metadata.drawable then
        return {
            success = false,
            message = Config.Notify.invalid_item
        }
    end
    
    -- BLOCK items có isnew = 'yes' nếu không cho phép đổi đồ mới
    local isNew = item.metadata.isnew or item.metadata.isNew
    if not Config.AllowNewItems and (isNew == 'yes' or isNew == 'Yes' or isNew == 'YES' or isNew == true) then
        return {
            success = false,
            message = Config.Notify.invalid_new_item
        }
    end
    
    local rarity = item.metadata.DoHiem or item.metadata.dohiem
    if not rarity then
        return {
            success = false,
            message = Config.Notify.invalid_rarity
        }
    end
    
    -- Kiểm tra giới tính của item (phải ngược với giới tính nhân vật)
    local itemSex = item.metadata.sex or item.metadata.gender
    if sex == 'male' and itemSex ~= 'female' then
        return {
            success = false,
            message = Config.Notify.invalid_item_sex
        }
    elseif sex == 'female' and itemSex ~= 'male' then
        return {
            success = false,
            message = Config.Notify.invalid_item_sex
        }
    end
    
    -- Validate targetDrawable nằm trong config theo giới tính NHÂN VẬT (sex)
    local drawableList = Config.Dohiem[sex] and Config.Dohiem[sex][itemName] and Config.Dohiem[sex][itemName][rarity]
    if not drawableList then
        return {
            success = false,
            message = Config.Notify.invalid_rarity
        }
    end
    
    local isValidDrawable = false
    for _, drawable in ipairs(drawableList) do
        if drawable == targetDrawable then
            isValidDrawable = true
            break
        end
    end
    
    if not isValidDrawable then
        return {
            success = false,
            message = Config.Notify.invalid_drawable
        }
    end
    
    -- Set cooldown
    setCooldown(source)
    
    -- Remove item cũ từ inventory
    local removed = exports.ox_inventory:RemoveItem(source, itemName, 1, item.metadata, slot)
    if not removed then
        return {
            success = false,
            message = Config.Notify.failed
        }
    end
    
    -- Add item mới qua XNClothes export
    -- Export format: GiveClothingItem(src, slot, drawable, texture, palette, sex)
    -- slot ở đây là uiCategory như 'torso', 'shirt', 'pants'
    -- sex ở đây truyền giới tính nhân vật (sex) để nhận được đồ đúng giới tính của mình
    local success = pcall(function()
        exports['XNClothes']:GiveClothingItem(source, uiCategory, targetDrawable, 0, nil, sex)
    end)
    
    if Config.Debug then
        print(string.format('[DEBUG] GiveClothingItem called: src=%d, category=%s, drawable=%d, sex=%s', source, uiCategory, targetDrawable, itemSex))
    end
    
    if not success then
        -- Rollback: add lại item cũ nếu export fail
        exports.ox_inventory:AddItem(source, itemName, 1, item.metadata)
        return {
            success = false,
            message = Config.Notify.failed
        }
    end
    
    return {
        success = true,
        message = Config.Notify.success
    }
end)

-- =====================================================
-- CLEANUP COOLDOWN KHI PLAYER DISCONNECT
-- =====================================================

AddEventHandler('playerDropped', function()
    local source = source
    if playerCooldowns[source] then
        playerCooldowns[source] = nil
    end
end)
