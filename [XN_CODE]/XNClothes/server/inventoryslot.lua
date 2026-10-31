PlayerSex = {}

local function IsSpecialBagAllowed(source, drawable)
    if not drawable then return true end
    local drawNum = tonumber(drawable)
    -- Nam: 395, Nữ: 413
    if drawNum == 395 or drawNum == 413 then
        local player = nil
        if Config.FrameWork == "ESX" then
            if ESX then player = ESX.GetPlayerFromId(source) end
        elseif Config.FrameWork == "QBOX" then
            if QBCore then player = QBCore.Functions.GetPlayer(source) end
        end
        
        -- Fallback check for QBCore / ESX
        if not player and QBCore then
            player = QBCore.Functions.GetPlayer(source)
        end
        if not player and ESX then
            player = ESX.GetPlayerFromId(source)
        end
        
        if not player then return false end
        
        local jobName = nil
        local onDuty = false
        
        if player.PlayerData and player.PlayerData.job then
            jobName = player.PlayerData.job.name
            onDuty = (player.PlayerData.job.onduty == true)
        elseif player.job then
            jobName = player.job.name
            if type(player.job.onduty) == "boolean" then
                onDuty = player.job.onduty
            else
                onDuty = (jobName == "police" or jobName == "ambulance")
            end
        end
        
        -- Check Player State Bag as override (handles QBox and other frameworks seamlessly)
        local state = Player(source).state
        if state then
            if state.onDuty ~= nil then
                onDuty = (state.onDuty == true)
            elseif state.onduty ~= nil then
                onDuty = (state.onduty == true)
            end
        end
        
        if (jobName == "police" or jobName == "ambulance") and onDuty then
            return true
        end
        
        return false
    end
    
    return true
end

local MALE_FREEMODE_MODEL = joaat('mp_m_freemode_01')
local FEMALE_FREEMODE_MODEL = joaat('mp_f_freemode_01')

local function isFreemodePedBySource(playerSource)
    local ped = GetPlayerPed(playerSource)
    if not ped or ped <= 0 then
        return false
    end

    local model = GetEntityModel(ped)
    return model == MALE_FREEMODE_MODEL or model == FEMALE_FREEMODE_MODEL
end

-- Get player gender from ped model (source of truth)
local function isFreemodePedBySource(playerSource)
    local ped = GetPlayerPed(playerSource)
    if not ped or ped <= 0 then
        return false
    end
    
    local model = GetEntityModel(ped)
    return model == MALE_FREEMODE_MODEL or model == FEMALE_FREEMODE_MODEL
end

-- REAL-TIME gender detection from ped model (no cache, always accurate)
-- Returns "male", "female", or nil if not freemode
local function getRealPedGender(playerSource)
    local ped = GetPlayerPed(playerSource)
    if not ped or ped <= 0 then
        return nil
    end
    local model = GetEntityModel(ped)
    if model == FEMALE_FREEMODE_MODEL then
        return "female"
    elseif model == MALE_FREEMODE_MODEL then
        return "male"
    end
    return nil  -- Custom ped, no gender check needed
end

local function triggerSavePlayerIfFreemode(playerSource)
    if not playerSource then
        return
    end

    if not Config.UseIllenium or isFreemodePedBySource(playerSource) then
        TriggerClientEvent('savePlayer', playerSource)
    end
end

RegisterServerEvent('clothes:changeslotclothes')
AddEventHandler('clothes:changeslotclothes', function(metadata, slot, name, label)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end

    -- Kiểm tra durability trước khi thay đổi quần áo
    if metadata and metadata.durability ~= nil then
        if tonumber(metadata.durability) == 0 then
            TriggerClientEvent('QBCore:Notify', source, "Quần áo đã hỏng và không thể sử dụng!", 'error')
            return
        end
    end

    -- Kiểm tra giới tính trước khi thay đổi quần áo (REAL-TIME ped check)
    local realGender = getRealPedGender(source)
    if metadata.sex and realGender and metadata.sex ~= realGender then
        TriggerClientEvent('QBCore:Notify', source, "Bạn không thể mặc quần áo của giới tính khác!", 'error')
        return
    end

    -- Kiểm tra balo đặc biệt (police & ambulance khi onduty)
    if name == 'cloth_bags' and metadata and metadata.drawable then
        if not IsSpecialBagAllowed(source, metadata.drawable) then
            if Config.FrameWork == "ESX" then
                TriggerClientEvent('esx:showNotification', source, "Balo này chỉ dành cho Police và Ambulance khi đang On Duty!")
            else
                TriggerClientEvent('QBCore:Notify', source, "Balo này chỉ dành cho Police và Ambulance khi đang On Duty!", 'error')
            end
            return
        end
    end

    local componentIndex = -1
    for i, componentName in ipairs(clothesComponentNames) do
        if componentName == name or (componentName == 'cloth_decals' and name == 'cloth_decal') then
            componentIndex = i
            break
        end
    end

    if componentIndex == -1 then
        return
    end

    local slotID = clothesSlotID[componentIndex]

    local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, slotID)

    if itemInSlot and json.encode(itemInSlot.metadata) == json.encode(metadata) then
        TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 'Vous avez déjà cet élément sur vous', 'error')
        return
    end

    -- Dùng `slot` (slot hiện tại của item) để xóa, không dùng slotID (đích)
    exports.ox_inventory:RemoveItem(player.PlayerData.source, name, 1, metadata, slot)

    if itemInSlot and itemInSlot.name then
        local oldItemName = itemInSlot.name
        local oldItemMetadata = itemInSlot.metadata or {}

        exports.ox_inventory:RemoveItem(player.PlayerData.source, oldItemName, 1, oldItemMetadata, slotID)

        Wait(200)

        -- Trả balo cũ về túi đồ thường (không chỉ định slot → vào 1-5)
        exports.ox_inventory:AddItem(player.PlayerData.source, oldItemName, 1, oldItemMetadata)
    end

    -- Đặt balo mới vào đúng ô quần áo
    exports.ox_inventory:AddItem(player.PlayerData.source, name, 1, metadata, slotID)

    GetPlayerClothesAndStock(player.PlayerData.source)
    TriggerClientEvent('RefreshArmsAndTShirt', player.PlayerData.source)
end)


local isProcessing = {} 
local isMonitoring = {} 



local UseExports = Config.UseExports
local canCC


local defaultClothingWoman = {
    [1] = { draw = 0, text = 0 },
    [2] = { draw = -1, text = -1 },
    [3] = { draw = -1, text = -1 },
    [4] = { draw = -1, text = -1 },
    [5] = { draw = 0, text = 0 },
    [6] = { draw = 15, text = 0 },
    [7] = { draw = 15, text = 0 },
    [8] = { draw = 0, text = 0 },
    [9] = { draw = -1, text = -1 },
    [10] = { draw = -1, text = -1 },
    [11] = { draw = 0, text = 0 },
    [12] = { draw = 15, text = 0 },
    [13] = { draw = 35, text = 0 },
    [14] = { draw = 15, text = 0 },
    [15] = { draw = 15, text = 0 },
    [16] = { draw = 0, text = 0 }
}

local defaultClothingMen = {
    [1] = { draw = 0, text = 0 },
    [2] = { draw = -1, text = -1 },
    [3] = { draw = -1, text = -1 },
    [4] = { draw = -1, text = -1 },
    [5] = { draw = 0, text = 0 },
    [6] = { draw = 15, text = 0 },
    [7] = { draw = 15, text = 0 },
    [8] = { draw = 0, text = 0 },
    [9] = { draw = -1, text = -1 },
    [10] = { draw = -1, text = -1 },
    [11] = { draw = 15, text = 0 },
    [12] = { draw = 61, text = 0 },
    [13] = { draw = 34, text = 0 },
    [14] = { draw = 15, text = 0 },
    [15] = { draw = 15, text = 0 },
    [16] = { draw = 0, text = 0 }
}


local clothingMonitor = {}
local monitoringInterval = Config.Durability.MonitoringInterval or 5000 -- 5 giây
local warningCooldowns = {} -- Track thời gian cảnh báo cuối cùng cho từng player

-- Function kiểm tra và reload quần áo
function CheckAndReloadClothing(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end

    local needsReload = false
    local missingItems = {}

    -- Kiểm tra từng slot quần áo
    for _, item in pairs(componentMapping) do
        if item.clothesSlotID ~= componentMapping.clothes.clothesSlotID then
            local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, item.clothesSlotID)
            
            -- Nếu slot trống nhưng trước đó có quần áo
            local isItemValid = (itemInSlot and (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal')))
            if item.clothesSlotID == (componentMapping and componentMapping.earrings and componentMapping.earrings.clothesSlotID or 16) and itemInSlot then
                if itemInSlot.name == 'cloth_ears' or itemInSlot.name == 'cloth_decals' or itemInSlot.name == 'cloth_decal' then
                    isItemValid = true
                end
            end
            if (not isItemValid) and clothingMonitor[source] and clothingMonitor[source][item.clothesSlotID] then
                needsReload = true
                table.insert(missingItems, {
                    component = item.component,
                    prop = item.prop,
                    itemname = item.itemname,
                    slotID = item.clothesSlotID
                })
            end
        end
    end

    if needsReload then
        --print(("Player %s missing clothing items, reloading..."):format(source))
        
        -- Reset các component/prop bị mất về mặc định
        local isFreemodePlayer = isFreemodePedBySource(source)
        for _, missing in pairs(missingItems) do
            local ped = GetPlayerPed(source)
            local hash = GetEntityModel(ped)
            local isMale = (hash == 1885233650)
            
            if missing.prop then
                TriggerClientEvent('setPedProp', source, {
                    texture = 0,
                    drawable = -1,
                    prop_id = missing.component
                })
            elseif not isFreemodePlayer then
                -- Custom ped: drawable 0, texture 0
                TriggerClientEvent('setPedComponent', source, {
                    texture = 0,
                    drawable = 0,
                    component_id = missing.component
                })
            else
                -- Freemode ped: dùng defaultClothing array
                local defaultClothing = isMale and defaultClothingMen or defaultClothingWoman
                local defaultIndex = -1
                for index, componentName in ipairs(clothesComponentNames) do
                    if componentName == missing.itemname then
                        defaultIndex = index
                        break
                    end
                end
                if defaultIndex > 0 and defaultClothing[defaultIndex] then
                    TriggerClientEvent('setPedComponent', source, {
                        texture = defaultClothing[defaultIndex].text,
                        drawable = defaultClothing[defaultIndex].draw,
                        component_id = missing.component
                    })
                end
            end
        end
        
        triggerSavePlayerIfFreemode(source)
        
        -- Cập nhật clothing data
        Citizen.CreateThread(function()
            Wait(200)
            GetPlayerClothesAndStock(source)
        end)
    end
end

-- Function cập nhật monitor data
function UpdateClothingMonitor(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end

    if not clothingMonitor[source] then
        clothingMonitor[source] = {}
    end

    -- Lưu trạng thái hiện tại của các slot quần áo
    for _, item in pairs(componentMapping) do
        if item.clothesSlotID and item.clothesSlotID ~= componentMapping.clothes.clothesSlotID then
            local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, item.clothesSlotID)
            clothingMonitor[source][item.clothesSlotID] = itemInSlot and true or false
        end
    end
end

-- Function kiểm tra durability của quần áo đang mặc
function CheckClothingDurability(source)
    -- Kiểm tra xem có bật monitoring không
    if not Config.Durability.MonitoringEnabled then
        return
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end

    local currentTime = GetGameTimer()
    
    -- Kiểm tra từng slot quần áo đang mặc
    for _, item in pairs(componentMapping) do
        if item.clothesSlotID and item.clothesSlotID ~= componentMapping.clothes.clothesSlotID then
            local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, item.clothesSlotID)
            
            if itemInSlot and itemInSlot.metadata and itemInSlot.metadata.durability ~= nil and (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal')) then
                local durability = tonumber(itemInSlot.metadata.durability)
                
                -- Kiểm tra xem item có trong danh sách loại trừ không
                local isExcluded = false
                if Config.Durability.ExcludeItems then
                    for _, excludeItem in ipairs(Config.Durability.ExcludeItems) do
                        if itemInSlot.name == excludeItem then
                            isExcluded = true
                            break
                        end
                    end
                end
                
                -- Nếu durability = 0 và bật auto remove và không bị loại trừ
                if durability == 0 and Config.Durability.AutoRemoveBroken and not isExcluded then
                    RemoveBrokenClothing(source, item, itemInSlot)
                    
                -- Cảnh báo khi durability thấp (cho tất cả item kể cả bị loại trừ)
                elseif Config.Durability.LowDurabilityWarning and 
                       durability <= Config.Durability.LowDurabilityThreshold and 
                       durability > 0 then
                    
                    -- Kiểm tra cooldown để không spam cảnh báo
                    local warningKey = source .. "_" .. item.clothesSlotID
                    if not warningCooldowns[warningKey] or 
                       (currentTime - warningCooldowns[warningKey]) >= Config.Durability.WarningCooldown then
                        
                        local warningMsg = isExcluded and 
                            string.format("%s sắp hỏng (độ bền: %d%%) - Cần sửa chữa thủ công!", item.label or itemInSlot.label, durability) or
                            string.format("%s sắp hỏng (độ bền: %d%%)", item.label or itemInSlot.label, durability)
                        
                        TriggerClientEvent('QBCore:Notify', source, warningMsg, 'warning')
                        
                        warningCooldowns[warningKey] = currentTime
                    end
                end
            end
        end
    end
end

-- Function tháo quần áo bị hỏng
function RemoveBrokenClothing(source, componentInfo, itemData)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end

    -- Thông báo cho người chơi
    TriggerClientEvent('QBCore:Notify', source, 
        string.format("%s đã hỏng và được tháo ra!", componentInfo.label or itemData.label), 
        'error')

    -- Di chuyển item từ slot mặc về inventory thường
    local success = exports.ox_inventory:RemoveItem(
        player.PlayerData.source, 
        itemData.name, 
        1, 
        itemData.metadata, 
        componentInfo.clothesSlotID
    )
    
    if success then
        -- Thử thêm vào inventory thường trước
        local addSuccess = exports.ox_inventory:AddItem(
            player.PlayerData.source, 
            itemData.name, 
            1, 
            itemData.metadata
        )

        -- Nếu inventory đầy và có sử dụng personal storage
        if not addSuccess and Config.Durability.UsePersonalStorage then
            -- Gửi về kho cá nhân
            local citizenid = player.PlayerData.citizenid
            local success_storage = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, itemData.name, 1, itemData.metadata)
            
            if success_storage then
                TriggerClientEvent('QBCore:Notify', source, 
                    string.format("Inventory đầy! %s đã được gửi về kho cá nhân.", componentInfo.label or itemData.label), 
                    'info')
            else
                -- Nếu không thể gửi về kho, thêm lại vào slot cũ (rollback)
                exports.ox_inventory:AddItem(
                    player.PlayerData.source, 
                    itemData.name, 
                    1, 
                    itemData.metadata, 
                    componentInfo.clothesSlotID
                )
                TriggerClientEvent('QBCore:Notify', source, 
                    "Không thể tháo quần áo: inventory và kho đều đầy!", 
                    'error')
                return
            end
        elseif not addSuccess then
            -- Nếu không dùng personal storage và inventory đầy, rollback
            exports.ox_inventory:AddItem(
                player.PlayerData.source, 
                itemData.name, 
                1, 
                itemData.metadata, 
                componentInfo.clothesSlotID
            )
            TriggerClientEvent('QBCore:Notify', source, 
                "Không thể tháo quần áo: inventory đầy! Hãy dọn dẹp inventory.", 
                'error')
            return
        end

        -- Reset component về mặc định chỉ khi thành công
        ResetComponentToDefault(source, componentInfo)
        
        -- Cập nhật dữ liệu quần áo
        Citizen.CreateThread(function()
            Wait(200)
            GetPlayerClothesAndStock(source)
        end)
    end
end

-- Function reset component về mặc định
function ResetComponentToDefault(source, componentInfo)
    local ped = GetPlayerPed(source)
    local hash = GetEntityModel(ped)
    local isMale = (hash == 1885233650)
    local isFreemode_ = isFreemodePedBySource(source)
    
    if componentInfo.prop then
        TriggerClientEvent('setPedProp', source, {
            texture = 0,
            drawable = -1,
            prop_id = componentInfo.component
        })
    elseif not isFreemode_ then
        -- Custom ped: drawable 0
        TriggerClientEvent('setPedComponent', source, {
            texture = 0,
            drawable = 0,
            component_id = componentInfo.component
        })
    else
        -- Freemode ped: dùng default array
        local defaultClothing = isMale and defaultClothingMen or defaultClothingWoman
        local defaultIndex = -1
        for index, componentName in ipairs(clothesComponentNames) do
            if componentName == componentInfo.itemname then
                defaultIndex = index
                break
            end
        end
        if defaultIndex > 0 and defaultClothing[defaultIndex] then
            TriggerClientEvent('setPedComponent', source, {
                texture = defaultClothing[defaultIndex].text,
                drawable = defaultClothing[defaultIndex].draw,
                component_id = componentInfo.component
            })
        end
    end
    
    triggerSavePlayerIfFreemode(source)
end

-- Function tiện ích để kiểm tra xem có thể thêm item vào inventory không
function CanAddToInventory(source, itemName, count, metadata)
    -- Thử thêm item tạm thời để kiểm tra
    local testSuccess = exports.ox_inventory:AddItem(source, itemName, count, metadata)
    if testSuccess then
        -- Nếu thành công, xóa item đó đi
        exports.ox_inventory:RemoveItem(source, itemName, count, metadata)
        return true
    end
    return false
end

-- Thread monitoring quần áo - OPTIMIZED: Chỉ chạy khi Durability.MonitoringEnabled = true
-- Default: DISABLED (đã tắt trong config)
Citizen.CreateThread(function()
    -- Đợi 10 giây trước khi bắt đầu monitoring
    Wait(10000)
    
    while true do
        -- Chỉ chạy nếu monitoring được bật (mặc định: tắt)
        if Config.Durability and Config.Durability.MonitoringEnabled then
            -- Sử dụng interval lớn hơn để giảm tải server
            local interval = Config.Durability.MonitoringInterval or 30000 -- Default 30 giây
            
            for source, _ in pairs(clothingMonitor) do
                -- Kiểm tra player còn online không
                local ped = GetPlayerPed(source)
                if ped and ped ~= 0 then
                    -- Chỉ check durability, không check reload (giảm tải)
                    CheckClothingDurability(source)
                else
                    -- Cleanup offline players
                    clothingMonitor[source] = nil
                    warningCooldowns[source] = nil
                end
            end
            
            Wait(interval)
        else
            -- Nếu không bật monitoring, chờ lâu hơn trước khi check lại config
            Wait(60000) -- Check lại config mỗi 60 giây
        end
    end
end)

-- Cleanup khi player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    if clothingMonitor[source] then
        clothingMonitor[source] = nil
    end
    if warningCooldowns[source] then
        warningCooldowns[source] = nil
    end
    -- PERF FIX: Reset routing bucket khi disconnect (tránh bucket rác tích tụ)
    -- Player có thể disconnect khi đang trong shop (routing bucket ≠ 0)
    SetPlayerRoutingBucket(source, 0)
end)

-- Khởi tạo monitoring cho player mới
RegisterNetEvent('clothes:initMonitoring')
AddEventHandler('clothes:initMonitoring', function()
    local source = source
    UpdateClothingMonitor(source)
end)

-- Sync ped gender from client (client ped model is source of truth)
-- Called when player spawns, changes ped, or opens inventory
RegisterNetEvent('clothes:updatePedGender', function(clientGender)
    local src = source
    if clientGender == "male" or clientGender == "female" then
        PlayerSex[src] = clientGender
    end
end)

-- Event mới để load lại quần áo trong slot
-- IMPORTANT: This event ONLY handles clothing components and props
-- It does NOT touch skin-related data (face, hair, headBlend, etc.)
-- Those are managed by illenium-appearance
RegisterNetEvent('clothes:reloadPlayerClothes')
AddEventHandler('clothes:reloadPlayerClothes', function(clientGender)
    local source = source
    
    -- If client provided gender, update PlayerSex (client ped is source of truth)
    if clientGender == "male" or clientGender == "female" then
        PlayerSex[source] = clientGender
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end
    
    -- Components that are SKIN-related and should NEVER be modified by clothes system
    -- Component 0 = Face shape (NOT modified)
    -- Component 2 = Hair style (NOT modified)
    local protectedComponents = {
        [0] = true,  -- Face - NEVER touch
        [2] = true,  -- Hair - NEVER touch
    }
    
    Citizen.CreateThread(function()
        Wait(100)

        -- Xác định giới tính từ PlayerSex table (được set từ client khi load)
        local playerGender = PlayerSex[source] or "male"

        -- Xác định model để load default clothes
        local ped = GetPlayerPed(source)
        local hash = GetEntityModel(ped)
        local isFreemode = isFreemodePedBySource(source)
        local isMale = (hash == 1885233650)
        local defaultClothing = isMale and defaultClothingMen or defaultClothingWoman

        -- Load lại từng item quần áo từ componentMapping lên nhân vật
        for categoryName, item in pairs(componentMapping) do
            -- Safety check: Skip any protected skin components
            if item.component and protectedComponents[item.component] and not item.prop then
                --print('[XNClothes] SKIPPING protected component:', item.component, '(skin data)')
                goto continue
            end
            if item.clothesSlotID and item.clothesSlotID ~= componentMapping.clothes.clothesSlotID and item.component then
                local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, item.clothesSlotID)

                -- Validate gender: item must match player's current gender
                local isValidGender = false
                local isMatchingItem = false
                if itemInSlot and itemInSlot.metadata then
                    local itemGender = itemInSlot.metadata.sex or "male"
                    isValidGender = (itemGender == playerGender)
                    isMatchingItem = (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal'))
                end

                if itemInSlot and itemInSlot.metadata and isValidGender and isMatchingItem then
                    -- Có quần áo trong slot VÀ giới tính khớp - load lên người
                    if item.prop then
                        local props = {
                            texture = itemInSlot.metadata.texture or 0,
                            drawable = itemInSlot.metadata.drawable or -1,
                            prop_id = item.component,
                            sex = itemInSlot.metadata.sex or playerGender  -- Include sex for client validation
                        }
                        TriggerClientEvent('setPedProp', source, props)
                    else
                        local components = {
                            texture = itemInSlot.metadata.texture or 0,
                            drawable = itemInSlot.metadata.drawable or 0,
                            component_id = item.component,
                            sex = itemInSlot.metadata.sex or playerGender  -- Include sex for client validation
                        }
                        TriggerClientEvent('setPedComponent', source, components)
                    end
                else
                    -- Slot trống HOẶC giới tính không khớp - reset về default
                    if item.prop then
                        -- Props luôn reset về -1 (ẩn)
                        TriggerClientEvent('setPedProp', source, {
                            texture = 0,
                            drawable = -1,
                            prop_id = item.component
                        })
                    elseif not isFreemode then
                        -- Custom ped: drawable 0, texture 0
                        TriggerClientEvent('setPedComponent', source, {
                            texture = 0,
                            drawable = 0,
                            component_id = item.component
                        })
                    else
                        -- Freemode ped: dùng Config.DefaultClothes trước, fallback array cũ
                        if Config.DefaultClothes[categoryName] and Config.DefaultClothes[categoryName].components then
                            local defaultComp = Config.DefaultClothes[categoryName].components[1]
                            if defaultComp then
                                local drawable = isMale and defaultComp.default_male or defaultComp.default_female
                                -- Validate drawable before sending
                                if drawable and drawable >= 0 then
                                    TriggerClientEvent('setPedComponent', source, {
                                        texture = 0,
                                        drawable = drawable,
                                        component_id = item.component
                                    })
                                else
                                    -- Fallback to 0 if invalid
                                    TriggerClientEvent('setPedComponent', source, {
                                        texture = 0,
                                        drawable = 0,
                                        component_id = item.component
                                    })
                                end
                            end
                        else
                            local defaultIndex = -1
                            for index, componentName in ipairs(clothesComponentNames) do
                                if componentName == item.itemname then
                                    defaultIndex = index
                                    break
                                end
                            end
                            if defaultIndex > 0 and defaultClothing[defaultIndex] then
                                local drawable = defaultClothing[defaultIndex].draw
                                local texture = defaultClothing[defaultIndex].text
                                -- Validate before sending
                                if drawable and drawable >= 0 then
                                    TriggerClientEvent('setPedComponent', source, {
                                        texture = texture or 0,
                                        drawable = drawable,
                                        component_id = item.component
                                    })
                                else
                                    -- Fallback to 0 if invalid
                                    TriggerClientEvent('setPedComponent', source, {
                                        texture = 0,
                                        drawable = 0,
                                        component_id = item.component
                                    })
                                end
                            else
                                -- No default found, use safe fallback
                                TriggerClientEvent('setPedComponent', source, {
                                    texture = 0,
                                    drawable = 0,
                                    component_id = item.component
                                })
                            end
                        end
                    end
                end
            end
            -- PERF FIX: Bỏ Wait(50) trong vòng lặp (15 items × 50ms = 750ms block đã được loại bỏ)

            ::continue::
        end
        
        -- Trigger save và cập nhật
        Wait(100)
        triggerSavePlayerIfFreemode(source)
        
        -- Cập nhật clothes bundle và monitoring
        GetPlayerClothesAndStock(source)
        UpdateClothingMonitor(source)
        
        --print('[XNClothes] Clothes reloaded successfully for player:', source)
        TriggerClientEvent('QBCore:Notify', source, 'Đã tải lại quần áo!', 'success')
    end)
end)

-- Command để test durability (chỉ admin)
RegisterCommand('testdurability', function(source, args)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    
    -- Kiểm tra quyền admin (có thể thay đổi theo hệ thống của bạn)
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này!', 'error')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('QBCore:Notify', source, 'Sử dụng: /testdurability [check|break|info] [slot]', 'info')
        return
    end
    
    local action = args[1]
    
    if action == 'check' then
        CheckClothingDurability(source)
        TriggerClientEvent('QBCore:Notify', source, 'Đã kiểm tra durability quần áo!', 'success')
        
    elseif action == 'break' then
        local slotId = tonumber(args[2])
        if not slotId then
            TriggerClientEvent('QBCore:Notify', source, 'Vui lòng nhập slot ID (45-60)', 'error')
            return
        end
        
        local itemInSlot = exports.ox_inventory:GetSlot(source, slotId)
        if itemInSlot and itemInSlot.metadata then
            -- Set durability = 0 để test
            itemInSlot.metadata.durability = 0
            exports.ox_inventory:SetMetadata(source, slotId, itemInSlot.metadata)
            
            -- Kiểm tra xem có phải cloth_bags không
            local isExcluded = false
            if Config.Durability.ExcludeItems then
                for _, excludeItem in ipairs(Config.Durability.ExcludeItems) do
                    if itemInSlot.name == excludeItem then
                        isExcluded = true
                        break
                    end
                end
            end
            
            local msg = isExcluded and 
                string.format("Đã set durability = 0 cho %s (slot %d) - Item này KHÔNG tự động tháo", itemInSlot.name, slotId) or
                string.format("Đã set durability = 0 cho %s (slot %d) - Item này SẼ tự động tháo", itemInSlot.name, slotId)
            
            TriggerClientEvent('QBCore:Notify', source, msg, 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, 'Không tìm thấy item trong slot ' .. slotId, 'error')
        end
        
    elseif action == 'info' then
        local excludeList = table.concat(Config.Durability.ExcludeItems or {}, ', ')
        TriggerClientEvent('QBCore:Notify', source, 
            string.format("Monitoring: %s | Auto Remove: %s | Excluded: %s", 
                Config.Durability.MonitoringEnabled and 'ON' or 'OFF',
                Config.Durability.AutoRemoveBroken and 'ON' or 'OFF',
                excludeList ~= '' and excludeList or 'None'
            ), 'info')
    end
end, false)

-- NOTE: createItem hook không hiệu quả vì slot=nil khi hook được gọi.
-- Giải pháp: Kiểm soát slot assignment trong AddItem wrapper ở server.lua
-- Slots 6-21 được dành riêng cho quần áo, items khác sẽ tự động vào slots 1-5 hoặc 22+

local checkMovingItems = exports.ox_inventory:registerHook('swapItems', function(payload)
    local source_ = payload.source
    local action = payload.action
    local czSlotsfrom = payload.fromSlot.slot
    local czSlots = payload.toSlot
    local metadata = payload.fromSlot.metadata
    local itemName = payload.fromSlot.name
    
    -- Kiểm tra balo đặc biệt (police & ambulance khi onduty) khi kéo vào ô balo
    local toSlotNumber = type(czSlots) == "table" and czSlots.slot or czSlots
    if toSlotNumber == Config.SlotBalo and itemName == 'cloth_bags' then
        if metadata and metadata.drawable then
            if not IsSpecialBagAllowed(source_, metadata.drawable) then
                if Config.FrameWork == "ESX" then
                    TriggerClientEvent('esx:showNotification', source_, "Balo này chỉ dành cho Police và Ambulance khi đang On Duty!")
                else
                    TriggerClientEvent('QBCore:Notify', source_, "Balo này chỉ dành cho Police và Ambulance khi đang On Duty!", 'error')
                end
                return false
            end
        end
    end
    
    -- Handle player to player transfers
    if payload.toType == "player" and payload.fromType == "player" and payload.source == payload.toInventory then
        local toSlotNumber = type(czSlots) == "table" and czSlots.slot or czSlots
        
        -- Check if trying to remove bag when items exist in extended slots
        if czSlotsfrom == Config.SlotBalo then
            -- Check if player has any items in slots above MaxClothesSlot
            local hasItemsInExtendedSlots = false
            
            -- Check each slot from TinhKhoDo+1 (slot 34) to a reasonable max (e.g., 60)
            for slot = Config.TinhKhoDo + 1, 60 do
                local item = exports.ox_inventory:GetSlot(source_, slot)
                if item and item.count and item.count > 0 then
                    hasItemsInExtendedSlots = true
                    break
                end
            end
            
            if hasItemsInExtendedSlots then
                TriggerClientEvent('QBCore:Notify', source_, "Không thể tháo balo khi còn đồ trong túi! Hãy lấy hết đồ ra trước.", "error")
                return false
            end
            
            -- Only allow moving bag to slots 1-33, not to extended slots (34+)
            if toSlotNumber > Config.TinhKhoDo then
                TriggerClientEvent('QBCore:Notify', source_, "Balo chỉ có thể chuyển vào ô 1-33!", "error")
                return false
            end
        end
    end
    
    -- Block moving bag to stash/trunk/shop when items exist in extended slots (>=22)
    if payload.fromType == "player" and payload.toType ~= "player" then
        if czSlotsfrom == Config.SlotBalo then
            -- Check if player has any items in extended slots
            local hasItemsInExtendedSlots = false
            for slot = Config.TinhKhoDo + 1, 60 do
                local item = exports.ox_inventory:GetSlot(source_, slot)
                if item and item.count and item.count > 0 then
                    hasItemsInExtendedSlots = true
                    break
                end
            end
            
            if hasItemsInExtendedSlots then
                TriggerClientEvent('QBCore:Notify', source_, "Không thể chuyển balo khi còn đồ trong túi! Hãy lấy hết đồ ra trước.", "error")
                return false
            end
        end
    end
    
    if payload.toType == "player" and payload.fromType == "player" and payload.source == payload.toInventory then
        
        if action == 'swap' then
            if czSlotsfrom ~= nil then 
                local toSlotNumber = type(czSlots) == "table" and czSlots.slot or czSlots
                if (toSlotNumber >= Config.MinClothesSlot and toSlotNumber <= Config.MaxClothesSlot and toSlotNumber == componentMapping.clothes.clothesSlotID) or
                (czSlotsfrom >= Config.MinClothesSlot and czSlotsfrom <= Config.MaxClothesSlot and czSlotsfrom == componentMapping.clothes.clothesSlotID )  then
                    TriggerClientEvent('QBCore:Notify', source_, Config.Notification.cannotechange)
                    return false
                end 
            end 
        end

        local toSlotNumber = type(czSlots) == "table" and czSlots.slot or czSlots

        if toSlotNumber == Config.CamSlotUpdate then 
            return false
        end

        local realGender_ = getRealPedGender(source_)
        if metadata.sex and realGender_ and metadata.sex ~= realGender_ then
            for index, searchingClothingName in pairs(componentMapping) do
                if toSlotNumber == searchingClothingName.clothesSlotID then
                    TriggerClientEvent('QBCore:Notify', source_, Config.Notification.cannotcarry)
                    return false
                end
            end
        end

        -- Kiểm tra xem toSlotNumber có phải là slot quần áo không
        local isClothingSlot = false
        local allowedForSlot = false
        local slotLabels = {}

        for _, mapping in pairs(componentMapping) do
            if toSlotNumber == mapping.clothesSlotID then
                isClothingSlot = true
                table.insert(slotLabels, mapping.label)
                if itemName == mapping.itemname or (mapping.itemname == 'cloth_decals' and itemName == 'cloth_decal') then
                    allowedForSlot = true
                    break
                end
            end
        end

        if isClothingSlot and not allowedForSlot then
            local labelStr = table.concat(slotLabels, " / ")
            TriggerClientEvent('QBCore:Notify', source_, Config.Notification.reservedto .. labelStr)
            return false
        end

        if czSlotsfrom == componentMapping.clothes.clothesSlotID then 
            ClothesMoved(source_, toSlotNumber)
        end 

        if toSlotNumber == componentMapping.clothes.clothesSlotID then 
            if metadata.sex == PlayerSex[source_] then 
                ClothesMovedToGood(source_)
            else 
                return false
            end
        end

        if action == 'move' then
            Citizen.CreateThread(function()
                -- PERF FIX: Chỉ gọi GetPlayerClothesAndStock 1 lần (trước gọi 2 lần duplicate)
                local needsUpdate =
                    (toSlotNumber >= Config.MinClothesSlot and toSlotNumber <= Config.MaxClothesSlot and toSlotNumber ~= componentMapping.clothes.clothesSlotID)
                    or (czSlotsfrom >= Config.MinClothesSlot and czSlotsfrom <= Config.MaxClothesSlot and czSlotsfrom ~= componentMapping.clothes.clothesSlotID)

                if needsUpdate then
                    GetPlayerClothesAndStock(source_)
                end
            end)
        end

        if (action == 'swap') then
            local fromSlotMoved = payload.fromSlot.slot
            local toSlotMoved = type(payload.toSlot) == "table" and payload.toSlot.slot or payload.toSlot

            local CurrentItemNames = { payload.fromSlot.name, payload.toSlot.name }
            local CurrentItemMetadata = { payload.fromSlot.metadata, payload.toSlot.metadata }

            local cItemMoved = false
            local cItemMovedIndex = -1

            local cSlotToDetect = false
            local cSlotToIndex = -1

            local cSlotFromDetect = false
            local cSlotFromIndex = -1

            for index, searchingClothingName in ipairs(clothesComponentNames) do
                if CurrentItemNames[1] == searchingClothingName or CurrentItemNames[2] == searchingClothingName
                   or ((searchingClothingName == 'cloth_decals') and (CurrentItemNames[1] == 'cloth_decal' or CurrentItemNames[2] == 'cloth_decal')) then
                    cItemMoved = true
                    cItemMovedIndex = index
                    break
                end
            end

            for index, searchingClothingSlot in ipairs(clothesSlotID) do
                if toSlotMoved == searchingClothingSlot then
                    cSlotToDetect = true
                    cSlotToIndex = index
                    break
                end
            end

            for index, searchingClothingSlot in ipairs(clothesSlotID) do
                if fromSlotMoved == searchingClothingSlot then
                    cSlotFromDetect = true
                    cSlotFromIndex = index
                    break
                end
            end

            local isComponent
            if cItemMovedIndex == 2 or cItemMovedIndex == 4 or cItemMovedIndex == 3 or cItemMovedIndex == 10 or cItemMovedIndex == 9 then
                isComponent = false
            else
                isComponent = true
            end

            if (cItemMoved) then
                if (UseExports) then
                    canCC = Player(source_).state.canChangeClothes
                else
                    canCC = true
                end

                local isItem1Ears = (CurrentItemNames[1] == 'cloth_ears')
                local isItem2Ears = (CurrentItemNames[2] == 'cloth_ears')
                local isItem1Decal = (CurrentItemNames[1] == 'cloth_decals' or CurrentItemNames[1] == 'cloth_decal')
                local isItem2Decal = (CurrentItemNames[2] == 'cloth_decals' or CurrentItemNames[2] == 'cloth_decal')
                local sharedSlot = (componentMapping and componentMapping.earrings and componentMapping.earrings.clothesSlotID) or (calculateSlot and calculateSlot(16)) or 16
                local isSharedSlotSwap = ((isItem1Ears and isItem2Decal) or (isItem1Decal and isItem2Ears)) and (toSlotMoved == sharedSlot or fromSlotMoved == sharedSlot)

                if isSharedSlotSwap then
                    if (canCC) then
                        local incomingName, incomingMetadata
                        if toSlotMoved == sharedSlot then
                            incomingName = CurrentItemNames[1]
                            incomingMetadata = CurrentItemMetadata[1]
                        else
                            incomingName = CurrentItemNames[2]
                            incomingMetadata = CurrentItemMetadata[2]
                        end

                        incomingMetadata = incomingMetadata or {}

                        if incomingMetadata.durability ~= nil then
                            if tonumber(incomingMetadata.durability) == 0 then
                                TriggerClientEvent('QBCore:Notify', source_, "Quần áo đã hỏng và không thể sử dụng!", 'error')
                                return false
                            end
                        end

                        local realGender = getRealPedGender(source_)
                        if incomingMetadata.sex and realGender and incomingMetadata.sex ~= realGender then
                            TriggerClientEvent('QBCore:Notify', source_, "Bạn không thể mặc quần áo của giới tính khác!", 'error')
                            return false
                        end

                        if incomingName == 'cloth_ears' then
                            -- Mặc khuyên tai, gỡ decal
                            TriggerClientEvent('setPedProp', source_, {
                                texture = incomingMetadata.texture or 0,
                                drawable = incomingMetadata.drawable or -1,
                                prop_id = 2,
                                sex = incomingMetadata.sex
                            })
                            TriggerClientEvent('setPedComponent', source_, {
                                texture = 0,
                                drawable = 0,
                                component_id = 10
                            })
                        else
                            -- Mặc decal, gỡ khuyên tai
                            TriggerClientEvent('setPedComponent', source_, {
                                texture = incomingMetadata.texture or 0,
                                drawable = incomingMetadata.drawable or 0,
                                component_id = 10,
                                sex = incomingMetadata.sex
                            })
                            TriggerClientEvent('setPedProp', source_, {
                                texture = 0,
                                drawable = -1,
                                prop_id = 2
                            })
                        end

                        triggerSavePlayerIfFreemode(source_)
                        GetPlayerClothesAndStock(source_)
                    else
                        return false
                    end
                elseif (CurrentItemNames[1] == CurrentItemNames[2] or (isItem1Decal and isItem2Decal)) then
                    if (fromSlotMoved == clothesSlotID[cItemMovedIndex]) then
                        if (canCC) then
                            -- Kiểm tra durability cho item thứ 2 (đang swap vào)
                            if CurrentItemMetadata[2] and CurrentItemMetadata[2].durability ~= nil then
                                if tonumber(CurrentItemMetadata[2].durability) == 0 then
                                    TriggerClientEvent('QBCore:Notify', source_, "Quần áo đã hỏng và không thể sử dụng!", 'error')
                                    return false
                                end
                            end

                            -- Kiểm tra giới tính cho item thứ 2 (REAL-TIME ped check)
                            local realGender2 = getRealPedGender(source_)
                            if CurrentItemMetadata[2] and CurrentItemMetadata[2].sex and realGender2 and CurrentItemMetadata[2].sex ~= realGender2 then
                                TriggerClientEvent('QBCore:Notify', source_, "Bạn không thể mặc quần áo của giới tính khác!", 'error')
                                return false
                            end
                            
                            if (isComponent) then
                                if clothesComponentNames[cItemMovedIndex] == 'cloth_bags' then
                                    local suc = BagAdd(source_, CurrentItemMetadata[1], false)
                                    if suc then
                                        local suc2 = BagAdd(source_, CurrentItemMetadata[2], true)
                                        if suc2 == false then
                                            return false
                                        end
                                    else
                                        return false
                                    end
                                end
                                local components = {
                                    texture = CurrentItemMetadata[2].texture,
                                    drawable = CurrentItemMetadata[2].drawable,
                                    component_id = clothesComponentID[cItemMovedIndex],
                                    sex = CurrentItemMetadata[2].sex
                                }
                                TriggerClientEvent('setPedComponent', source_, components)

                                -- Mặc decal -> gỡ khuyên tai
                                if clothesComponentNames[cItemMovedIndex] == 'cloth_decals' then
                                    TriggerClientEvent('setPedProp', source_, {
                                        texture = 0,
                                        drawable = -1,
                                        prop_id = 2
                                    })
                                end
                            else
                                local props = {
                                    texture = CurrentItemMetadata[2].texture,
                                    drawable = CurrentItemMetadata[2].drawable,
                                    prop_id = clothesComponentID[cItemMovedIndex],
                                    sex = CurrentItemMetadata[2].sex
                                }
                                TriggerClientEvent('setPedProp', source_, props)

                                -- Mặc khuyên tai -> gỡ decal
                                if clothesComponentNames[cItemMovedIndex] == 'cloth_ears' then
                                    TriggerClientEvent('setPedComponent', source_, {
                                        texture = 0,
                                        drawable = 0,
                                        component_id = 10
                                    })
                                end
                            end
                            triggerSavePlayerIfFreemode(source_)
                            GetPlayerClothesAndStock(source_)
                        else
                            return false
                        end
                    elseif (toSlotMoved == clothesSlotID[cItemMovedIndex]) then
                        if (canCC) then
                            -- Kiểm tra durability cho item thứ 1 (đang swap vào)
                            if CurrentItemMetadata[1] and CurrentItemMetadata[1].durability ~= nil then
                                if tonumber(CurrentItemMetadata[1].durability) == 0 then
                                    TriggerClientEvent('QBCore:Notify', source_, "Quần áo đã hỏng và không thể sử dụng!", 'error')
                                    return false
                                end
                            end

                            -- Kiểm tra giới tính cho item thứ 1 (REAL-TIME ped check)
                            local realGender1 = getRealPedGender(source_)
                            if CurrentItemMetadata[1] and CurrentItemMetadata[1].sex and realGender1 and CurrentItemMetadata[1].sex ~= realGender1 then
                                TriggerClientEvent('QBCore:Notify', source_, "Bạn không thể mặc quần áo của giới tính khác!", 'error')
                                return false
                            end
                            
                            if (isComponent) then
                                if clothesComponentNames[cItemMovedIndex] == 'cloth_bags' then
                                    local suc = BagAdd(source_, CurrentItemMetadata[2], false)
                                    if suc then
                                        local suc2 = BagAdd(source_, CurrentItemMetadata[1], true)
                                        if suc2 == false then
                                            return false
                                        end
                                    else
                                        return false
                                    end
                                end
                                local components = {
                                    texture = CurrentItemMetadata[1].texture,
                                    drawable = CurrentItemMetadata[1].drawable,
                                    component_id = clothesComponentID[cItemMovedIndex],
                                    sex = CurrentItemMetadata[1].sex
                                }
                                TriggerClientEvent('setPedComponent', source_, components)

                                -- Mặc decal -> gỡ khuyên tai
                                if clothesComponentNames[cItemMovedIndex] == 'cloth_decals' then
                                    TriggerClientEvent('setPedProp', source_, {
                                        texture = 0,
                                        drawable = -1,
                                        prop_id = 2
                                    })
                                end
                            else
                                local props = {
                                    texture = CurrentItemMetadata[1].texture,
                                    drawable = CurrentItemMetadata[1].drawable,
                                    prop_id = clothesComponentID[cItemMovedIndex],
                                    sex = CurrentItemMetadata[1].sex
                                }
                                TriggerClientEvent('setPedProp', source_, props)

                                -- Mặc khuyên tai -> gỡ decal
                                if clothesComponentNames[cItemMovedIndex] == 'cloth_ears' then
                                    TriggerClientEvent('setPedComponent', source_, {
                                        texture = 0,
                                        drawable = 0,
                                        component_id = 10
                                    })
                                end
                            end

                            triggerSavePlayerIfFreemode(source_)
                            GetPlayerClothesAndStock(source_)
                        else
                            return false
                        end
                    end
                else
                    return false
                end
            else
                if (cSlotFromDetect or cSlotToDetect) then
                    return false
                end
            end
        elseif (action == 'move') then
            local fromSlotMoved = payload.fromSlot.slot
            local toSlotMoved = type(payload.toSlot) == "table" and payload.toSlot.slot or payload.toSlot

            local CurrentItemName = payload.fromSlot.name
            local CurrentItemMetadata = payload.fromSlot.metadata

            local MovedCitem = false
            local MovedCitemIndex = -1


            local MovedToCslot = false
            local MovedToCslotIndex = -1

            local MovedFromCslot = false

            for index, searchingClothingName in ipairs(clothesComponentNames) do
                if CurrentItemName == searchingClothingName or (searchingClothingName == 'cloth_decals' and CurrentItemName == 'cloth_decal') then
                    MovedCitem = true
                    MovedCitemIndex = index
                    break
                end
            end

            local isComponent
            if MovedCitemIndex == 2 or MovedCitemIndex == 4 or MovedCitemIndex == 3 or MovedCitemIndex == 10 or MovedCitemIndex == 9 then
                isComponent = false
            else
                isComponent = true
            end

            for index, searchingClothingSlot in ipairs(clothesSlotID) do
                if toSlotMoved == searchingClothingSlot then
                    MovedToCslot = true
                    MovedToCslotIndex = index
                    break
                end
            end

            for _, searchingClothingSlot in ipairs(clothesSlotID) do
                if fromSlotMoved == searchingClothingSlot then
                    MovedFromCslot = true
                    break
                end
            end

            if (MovedCitem) then
                if (UseExports) then
                    canCC = Player(source_).state.canChangeClothes
                else
                    canCC = true
                end
                if (MovedToCslot) then
                    local isMatchingSlot = (clothesSlotID[MovedCitemIndex] == toSlotMoved)
                    if (isMatchingSlot) then
                        if (canCC) then
                            -- Kiểm tra durability trước khi mặc quần áo
                            if CurrentItemMetadata and CurrentItemMetadata.durability ~= nil then
                                if tonumber(CurrentItemMetadata.durability) == 0 then
                                    TriggerClientEvent('QBCore:Notify', source_, "Quần áo đã hỏng và không thể sử dụng!", 'error')
                                    return false
                                end
                            end

                            -- Kiểm tra giới tính (REAL-TIME ped check, ngăn mặc đồ khác giới)
                            local realGenderM = getRealPedGender(source_)
                            if CurrentItemMetadata and CurrentItemMetadata.sex and realGenderM and CurrentItemMetadata.sex ~= realGenderM then
                                TriggerClientEvent('QBCore:Notify', source_, "Bạn không thể mặc quần áo của giới tính khác!", 'error')
                                return false
                            end
                            
                            if (isComponent) then
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                                    local suc = BagAdd(source_, CurrentItemMetadata, true)
                                    if suc == false then
                                        return false
                                    end
                                end
                                local components = {
                                    texture = CurrentItemMetadata.texture,
                                    drawable = CurrentItemMetadata.drawable,
                                    component_id = clothesComponentID[MovedCitemIndex],
                                    sex = CurrentItemMetadata.sex
                                }
                                TriggerClientEvent('setPedComponent', source_, components)

                                -- Mặc decal (component 10) chia sẻ slot 16 với khuyên tai -> gỡ khuyên tai
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_decals' then
                                    TriggerClientEvent('setPedProp', source_, {
                                        texture = 0,
                                        drawable = -1,
                                        prop_id = 2
                                    })
                                end
                            else
                                local props = {
                                    texture = CurrentItemMetadata.texture,
                                    drawable = CurrentItemMetadata.drawable,
                                    prop_id = clothesComponentID[MovedCitemIndex],
                                    sex = CurrentItemMetadata.sex
                                }
                                TriggerClientEvent('setPedProp', source_, props)

                                -- Mặc khuyên tai (prop 2) chia sẻ slot 16 với decal -> gỡ decal
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_ears' then
                                    TriggerClientEvent('setPedComponent', source_, {
                                        texture = 0,
                                        drawable = 0,
                                        component_id = 10
                                    })
                                end
                            end
                            triggerSavePlayerIfFreemode(source_)
                        else
                            return false
                        end
                    else
                        if payload.toType ~= 'player' then

    
                            return true
                        else
                            return false
                        end
                    end
                elseif (MovedFromCslot and fromSlotMoved == clothesSlotID[MovedCitemIndex]) then
                    if (payload.fromInventory ~= payload.toInventory and payload.fromType == 'player' and payload.toType == 'player') then
                        local fromSource = payload.fromInventory
                        local ped = GetPlayerPed(fromSource)
                        local hash = GetEntityModel(ped)
                        local isFreemode_ = isFreemodePedBySource(fromSource)
                        if not isFreemode_ then
                            -- Custom ped: drawable 0
                            if (isComponent) then
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                                    local suc = BagAdd(fromSource, CurrentItemMetadata, false)
                                    if suc == false then return false end
                                end
                                TriggerClientEvent('setPedComponent', fromSource, {
                                    texture = 0,
                                    drawable = 0,
                                    component_id = clothesComponentID[MovedCitemIndex]
                                })
                            else
                                TriggerClientEvent('setPedProp', fromSource, {
                                    texture = 0,
                                    drawable = -1,
                                    prop_id = clothesComponentID[MovedCitemIndex]
                                })
                            end
                        elseif (hash == 1885233650) then
                            if (isComponent) then
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                                    local suc = BagAdd(fromSource, CurrentItemMetadata, false)
                                    if suc == false then
                                        return false
                                    end
                                end

                                local components = Config.DefaultClothes[clothesComponentNames[MovedCitemIndex]].components
                                TriggerClientEvent('setPedComponent', fromSource, components)
                            else
                                local props = {
                                    texture = defaultClothingMen[MovedCitemIndex].text,
                                    drawable = defaultClothingMen[MovedCitemIndex].draw,
                                    prop_id = clothesComponentID[MovedCitemIndex]
                                }
                                TriggerClientEvent('setPedProp', fromSource, props)
                            end
                        else
                            if (isComponent) then
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                                    local suc = BagAdd(fromSource, CurrentItemMetadata, false)
                                    if suc == false then
                                        return false
                                    end
                                end
                                local components = {
                                    texture = defaultClothingWoman[MovedCitemIndex].text,
                                    drawable = defaultClothingWoman[MovedCitemIndex].draw,
                                    component_id = clothesComponentID[MovedCitemIndex]
                                }
                                TriggerClientEvent('setPedComponent', fromSource, components)
                            else
                                local props = {
                                    texture = defaultClothingWoman[MovedCitemIndex].text,
                                    drawable = defaultClothingWoman[MovedCitemIndex].draw,
                                    prop_id = clothesComponentID[MovedCitemIndex]
                                }
                                TriggerClientEvent('setPedProp', fromSource, props)
                            end
                        end
                        triggerSavePlayerIfFreemode(fromSource)

                        

                        return true
                    end
                    if (canCC) then
                        local ped = GetPlayerPed(source_)
                        local hash = GetEntityModel(ped)
                        local isFreemode_ = isFreemodePedBySource(source_)
                        if not isFreemode_ then
                            -- Custom ped: drawable 0
                            if (isComponent) then
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                                    local suc = BagAdd(source_, CurrentItemMetadata, false)
                                    if suc == false then return false end
                                end
                                TriggerClientEvent('setPedComponent', source_, {
                                    texture = 0,
                                    drawable = 0,
                                    component_id = clothesComponentID[MovedCitemIndex]
                                })
                            else
                                TriggerClientEvent('setPedProp', source_, {
                                    texture = 0,
                                    drawable = -1,
                                    prop_id = clothesComponentID[MovedCitemIndex]
                                })
                            end
                        elseif (hash == 1885233650) then
                            if (isComponent) then
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                                    local suc = BagAdd(source_, CurrentItemMetadata, false)
                                    if suc == false then
                                        return false
                                    end
                                end
                                local components = {
                                    texture = defaultClothingMen[MovedCitemIndex].text,
                                    drawable = defaultClothingMen[MovedCitemIndex].draw,
                                    component_id = clothesComponentID[MovedCitemIndex]
                                }
                                TriggerClientEvent('setPedComponent', source_, components)
                            else
                                local props = {
                                    texture = defaultClothingMen[MovedCitemIndex].text,
                                    drawable = defaultClothingMen[MovedCitemIndex].draw,
                                    prop_id = clothesComponentID[MovedCitemIndex]
                                }
                                
                                TriggerClientEvent('setPedProp', source_, props)
                            end
                        else
                            if (isComponent) then
                                if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                                    local suc = BagAdd(source_, CurrentItemMetadata, false)
                                    if suc == false then
                                        return false
                                    end
                                end
                                local components = {
                                    texture = defaultClothingWoman[MovedCitemIndex].text,
                                    drawable = defaultClothingWoman[MovedCitemIndex].draw,
                                    component_id = clothesComponentID[MovedCitemIndex]
                                }
                                TriggerClientEvent('setPedComponent', source_, components)
                            else
                                local props = {
                                    texture = defaultClothingWoman[MovedCitemIndex].text,
                                    drawable = defaultClothingWoman[MovedCitemIndex].draw,
                                    prop_id = clothesComponentID[MovedCitemIndex]
                                }
                                TriggerClientEvent('setPedProp', source_, props)
                            end
                        end
                        triggerSavePlayerIfFreemode(source_)
                    else
                        return false
                    end
                end
            else
                if (MovedToCslot) then
                    return false
                end
            end
        
        end
    end
    
    -- Handle drops to ground or other inventory types
    if payload.fromType == "player" and payload.toType ~= "player" then
        local fromSlotMoved = payload.fromSlot.slot
        local CurrentItemName = payload.fromSlot.name
        local CurrentItemMetadata = payload.fromSlot.metadata

        local MovedCitem = false
        local MovedCitemIndex = -1
        local MovedFromCslot = false

        -- Check if it's a clothing item
        for index, searchingClothingName in ipairs(clothesComponentNames) do
            if CurrentItemName == searchingClothingName or (searchingClothingName == 'cloth_decals' and CurrentItemName == 'cloth_decal') then
                MovedCitem = true
                MovedCitemIndex = index
                break
            end
        end

        -- Check if moved from clothing slot
        for _, searchingClothingSlot in ipairs(clothesSlotID) do
            if fromSlotMoved == searchingClothingSlot and fromSlotMoved == clothesSlotID[MovedCitemIndex] then
                MovedFromCslot = true
                break
            end
        end

        -- If clothing item moved from clothing slot to ground/other inventory
        if MovedCitem and MovedFromCslot then
            local isComponent = not (MovedCitemIndex == 2 or MovedCitemIndex == 4 or MovedCitemIndex == 3 or MovedCitemIndex == 10 or MovedCitemIndex == 9)
            
            if (UseExports) then
                canCC = Player(source_).state.canChangeClothes
            else
                canCC = true
            end

            if canCC then
                local ped = GetPlayerPed(source_)
                local hash = GetEntityModel(ped)
                local isFreemode_ = isFreemodePedBySource(source_)
                
                if not isFreemode_ then
                    -- Custom ped: drawable 0
                    if (isComponent) then
                        if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                            local suc = BagAdd(source_, CurrentItemMetadata, false)
                            if suc == false then return false end
                        end
                        TriggerClientEvent('setPedComponent', source_, {
                            texture = 0,
                            drawable = 0,
                            component_id = clothesComponentID[MovedCitemIndex]
                        })
                    else
                        TriggerClientEvent('setPedProp', source_, {
                            texture = 0,
                            drawable = -1,
                            prop_id = clothesComponentID[MovedCitemIndex]
                        })
                    end
                elseif (hash == 1885233650) then -- Male
                    if (isComponent) then
                        if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                            local suc = BagAdd(source_, CurrentItemMetadata, false)
                            if suc == false then
                                return false
                            end
                        end
                        local components = {
                            texture = defaultClothingMen[MovedCitemIndex].text,
                            drawable = defaultClothingMen[MovedCitemIndex].draw,
                            component_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedComponent', source_, components)
                    else
                        local props = {
                            texture = defaultClothingMen[MovedCitemIndex].text,
                            drawable = defaultClothingMen[MovedCitemIndex].draw,
                            prop_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedProp', source_, props)
                    end
                else -- Female
                    if (isComponent) then
                        if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                            local suc = BagAdd(source_, CurrentItemMetadata, false)
                            if suc == false then
                                return false
                            end
                        end
                        local components = {
                            texture = defaultClothingWoman[MovedCitemIndex].text,
                            drawable = defaultClothingWoman[MovedCitemIndex].draw,
                            component_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedComponent', source_, components)
                    else
                        local props = {
                            texture = defaultClothingWoman[MovedCitemIndex].text,
                            drawable = defaultClothingWoman[MovedCitemIndex].draw,
                            prop_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedProp', source_, props)
                    end
                end
                triggerSavePlayerIfFreemode(source_)
                
                -- Cập nhật monitoring cho cả hai player
                Citizen.CreateThread(function()
                    Wait(200)
                    GetPlayerClothesAndStock(fromSource)
                    UpdateClothingMonitor(fromSource)
                    UpdateClothingMonitor(toSource)
                end)
            else
                return false
            end
        end

        -- Handle clothes bundle slot being dropped
        if fromSlotMoved == componentMapping.clothes.clothesSlotID then 
            Citizen.CreateThread(function()
                Wait(200)
                -- Reset player to default clothes when outfit bundle is dropped
                TriggerClientEvent('clothes:resetPed', source_)
                
                -- Clear all clothing slots when outfit bundle is dropped
                for _, item in pairs(componentMapping) do
                    if item.clothesSlotID ~= componentMapping.clothes.clothesSlotID then
                        local itemInSlot = exports.ox_inventory:GetSlot(source_, item.clothesSlotID)
                        if itemInSlot and (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal')) then 
                            exports.ox_inventory:RemoveItem(source_, itemInSlot.name, 1, itemInSlot.metadata, item.clothesSlotID)
                        end 
                    end
                end
                UpdateClothingMonitor(source_)
            end)
        end
    end

    -- Handle items being moved TO player from other inventories
    if payload.fromType ~= "player" and payload.toType == "player" then
        local toSlotMoved = type(payload.toSlot) == "table" and payload.toSlot.slot or payload.toSlot
        local CurrentItemName = payload.fromSlot.name
        
        -- Kiểm tra nếu là item quần áo
        local isClothingItem = false
        local clothingItemIndex = -1
        for index, searchingClothingName in ipairs(clothesComponentNames) do
            if CurrentItemName == searchingClothingName or (searchingClothingName == 'cloth_decals' and CurrentItemName == 'cloth_decal') then
                isClothingItem = true
                clothingItemIndex = index
                break
            end
        end
        
        -- Nếu là quần áo, kiểm tra xem có kéo vào đúng slot không
        if isClothingItem and toSlotMoved >= Config.MinClothesSlot and toSlotMoved <= Config.MaxClothesSlot then
            -- Kiểm tra xem slot đích có phải là slot dành cho loại quần áo này không
            local isCorrectSlot = false
            for _, mapping in pairs(componentMapping) do
                if toSlotMoved == mapping.clothesSlotID and (CurrentItemName == mapping.itemname or (mapping.itemname == 'cloth_decals' and CurrentItemName == 'cloth_decal')) then
                    isCorrectSlot = true
                    break
                end
            end
            
            if not isCorrectSlot then
                TriggerClientEvent('QBCore:Notify', source_, Config.Notification.reservedto .. "loại quần áo khác", "error")
                return false
            end
        end
        
        -- If item moved to clothing slot, update clothes
        if toSlotMoved >= Config.MinClothesSlot and toSlotMoved <= Config.MaxClothesSlot then
            Citizen.CreateThread(function()
                Wait(200)
                GetPlayerClothesAndStock(source_)
                UpdateClothingMonitor(source_)
            end)
        end
        
        -- Handle clothes bundle being moved to player
        if toSlotMoved == componentMapping.clothes.clothesSlotID then 
            if metadata.sex == PlayerSex[source_] then 
                ClothesMovedToGood(source_)
            else 
                return false
            end
        end
    end

    -- Handle transfers between different players (THÊM SECTION NÀY)
    if payload.fromType == "player" and payload.toType == "player" and payload.fromInventory ~= payload.toInventory then
        local fromSource = payload.fromInventory
        local toSource = payload.toInventory
        local fromSlotMoved = payload.fromSlot.slot
        local CurrentItemName = payload.fromSlot.name
        local CurrentItemMetadata = payload.fromSlot.metadata

        local MovedCitem = false
        local MovedCitemIndex = -1
        local MovedFromCslot = false

        -- Check if it's a clothing item
        for index, searchingClothingName in ipairs(clothesComponentNames) do
            if CurrentItemName == searchingClothingName or (searchingClothingName == 'cloth_decals' and CurrentItemName == 'cloth_decal') then
                MovedCitem = true
                MovedCitemIndex = index
                break
            end
        end

        -- Check if moved from clothing slot
        for _, searchingClothingSlot in ipairs(clothesSlotID) do
            if fromSlotMoved == searchingClothingSlot and fromSlotMoved == clothesSlotID[MovedCitemIndex] then
                MovedFromCslot = true
                break
            end
        end

        -- If clothing item moved from clothing slot to another player
        if MovedCitem and MovedFromCslot then
            local isComponent = not (MovedCitemIndex == 2 or MovedCitemIndex == 4 or MovedCitemIndex == 3 or MovedCitemIndex == 10 or MovedCitemIndex == 9)
            
            if (UseExports) then
                canCC = Player(fromSource).state.canChangeClothes
            else
                canCC = true
            end

            if canCC then
                local ped = GetPlayerPed(fromSource)
                local hash = GetEntityModel(ped)
                
                if (hash == 1885233650) then -- Male
                    if (isComponent) then
                        if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                            local suc = BagAdd(fromSource, CurrentItemMetadata, false)
                            if suc == false then
                                return false
                            end
                        end
                        local components = {
                            texture = defaultClothingMen[MovedCitemIndex].text,
                            drawable = defaultClothingMen[MovedCitemIndex].draw,
                            component_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedComponent', fromSource, components)
                    else
                        local props = {
                            texture = defaultClothingMen[MovedCitemIndex].text,
                            drawable = defaultClothingMen[MovedCitemIndex].draw,
                            prop_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedProp', fromSource, props)
                    end
                else -- Female
                    if (isComponent) then
                        if clothesComponentNames[MovedCitemIndex] == 'cloth_bags' then
                            local suc = BagAdd(fromSource, CurrentItemMetadata, false)
                            if suc == false then
                                return false
                            end
                        end
                        local components = {
                            texture = defaultClothingWoman[MovedCitemIndex].text,
                            drawable = defaultClothingWoman[MovedCitemIndex].draw,
                            component_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedComponent', fromSource, components)
                    else
                        local props = {
                            texture = defaultClothingWoman[MovedCitemIndex].text,
                            drawable = defaultClothingWoman[MovedCitemIndex].draw,
                            prop_id = clothesComponentID[MovedCitemIndex]
                        }
                        TriggerClientEvent('setPedProp', fromSource, props)
                    end
                end
                triggerSavePlayerIfFreemode(fromSource)
                
                -- Cập nhật monitoring cho cả hai player
                Citizen.CreateThread(function()
                    Wait(200)
                    GetPlayerClothesAndStock(fromSource)
                    UpdateClothingMonitor(fromSource)
                    UpdateClothingMonitor(toSource)
                end)
            else
                return false
            end
        end

        -- Handle clothes bundle being transferred to another player
        if fromSlotMoved == componentMapping.clothes.clothesSlotID then 
            Citizen.CreateThread(function()
                Wait(200)
                -- Reset sender to default clothes when outfit bundle is given away
                TriggerClientEvent('clothes:resetPed', fromSource)
                
                -- Clear all clothing slots for sender
                for _, item in pairs(componentMapping) do
                    if item.clothesSlotID ~= componentMapping.clothes.clothesSlotID then
                        local itemInSlot = exports.ox_inventory:GetSlot(fromSource, item.clothesSlotID)
                        if itemInSlot and (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal')) then 
                            exports.ox_inventory:RemoveItem(fromSource, itemInSlot.name, 1, itemInSlot.metadata, item.clothesSlotID)
                        end 
                    end
                end
                UpdateClothingMonitor(fromSource)
                UpdateClothingMonitor(toSource)
            end)
        end
    end
end, {
    print = false,
})


function BagAdd(source, itemMetadata, isEquip)

    Citizen.SetTimeout(100, function()
        local slotData = exports.ox_inventory:GetSlot(source, Config.SlotBalo) -- Lấy dữ liệu slot balo
        local playerSex = PlayerSex[source] or "male" -- Lấy giới tính của player, mặc định là male
        
        if slotData and slotData.name and slotData.metadata then
            local drawable = slotData.metadata.drawable
            
            -- Kiểm tra nếu là balo đặc biệt mà không được phép sử dụng
            if drawable and not IsSpecialBagAllowed(source, drawable) then
                -- Tìm slot trống trong khoảng từ 22 đến 33
                local targetSlot = nil
                for slot = 22, 33 do
                    local slotInfo = exports.ox_inventory:GetSlot(source, slot)
                    if not slotInfo or not slotInfo.name then
                        targetSlot = slot
                        break
                    end
                end
                
                -- Tháo balo: di chuyển balo từ SlotBalo về túi đồ thường hoặc bưu cục
                exports.ox_inventory:RemoveItem(source, slotData.name, 1, slotData.metadata, Config.SlotBalo)
                if targetSlot then
                    exports.ox_inventory:AddItem(source, slotData.name, 1, slotData.metadata, targetSlot)
                else
                    local player = GetPlayer(source)
                    local citizenid = player and (player.PlayerData and player.PlayerData.citizenid or player.identifier)
                    local success_storage = false
                    if citizenid then
                        success_storage = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, slotData.name, 1, slotData.metadata)
                    end
                    
                    if success_storage then
                        if Config.FrameWork == "ESX" then
                            TriggerClientEvent('esx:showNotification', source, "Túi đồ đầy! Balo đặc biệt đã được gửi về bưu cục.")
                        else
                            TriggerClientEvent('QBCore:Notify', source, "Túi đồ đầy! Balo đặc biệt đã được gửi về bưu cục.", 'info')
                        end
                    else
                        exports.ox_inventory:AddItem(source, slotData.name, 1, slotData.metadata)
                    end
                end
                
                -- Set slot và weight mặc định
                exports.ox_inventory:SetSlotCount(source, Config.MaxTuiDo)
                exports.ox_inventory:SetMaxWeight(source, Config.MaxCanNang)
                
                -- Đặt lại component ngoại hình về không mặc balo
                TriggerClientEvent('setPedComponent', source, {
                    texture = 0,
                    drawable = 0,
                    component_id = 5
                })
                
                if Config.FrameWork == "ESX" then
                    TriggerClientEvent('esx:showNotification', source, "Balo này chỉ dành cho Police và Ambulance khi đang On Duty! Balo đã tự động tháo.")
                else
                    TriggerClientEvent('QBCore:Notify', source, "Balo này chỉ dành cho Police và Ambulance khi đang On Duty! Balo đã tự động tháo.", 'error')
                end
                
                TriggerClientEvent('gin:dong:inven', source)
                return
            end
        end
        
        -- Debug logging
       --print(("BagAdd called for player %s, sex: %s"):format(source, playerSex))
        
        if slotData and slotData.name and slotData.metadata then
            local drawable = slotData.metadata.drawable -- Lấy giá trị drawable từ metadata
           -- print(("Bag found with drawable: %s"):format(drawable))
            
            -- Tìm level tương ứng với drawable
            local foundLevel = nil
            if Config.TuiDo[playerSex] then
                for level, levelData in pairs(Config.TuiDo[playerSex]) do
                    if levelData.Drawable then
                        for _, draw in ipairs(levelData.Drawable) do
                            if draw == drawable then
                                foundLevel = level
                                break
                            end
                        end
                    end
                    if foundLevel then break end
                end
            end
            
            if foundLevel and Config.TuiDo[playerSex][foundLevel] then -- Kiểm tra level có trong Config.TuiDo theo giới tính
                local so_Slot = Config.TuiDo[playerSex][foundLevel]["so_Slot"] -- Lấy giá trị so_Slot theo level
                local so_Ky = Config.TuiDo[playerSex][foundLevel]["so_Ky"]
                exports.ox_inventory:SetSlotCount(source, so_Slot) -- Đặt tổng số slot
                exports.ox_inventory:SetMaxWeight(source, so_Ky)
                --print(("Bag configured - Level: %s, Drawable: %s, Slots: %s, Weight: %s"):format(foundLevel, drawable, so_Slot, so_Ky))
            else
                exports.ox_inventory:SetSlotCount(source, Config.MaxTuiDo) -- Đặt giá trị mặc định
                exports.ox_inventory:SetMaxWeight(source, Config.MaxCanNang)
                --print(("Using default bag config - Drawable %s not found in Config.TuiDo"):format(drawable or "nil"))
            end
        else
            exports.ox_inventory:SetSlotCount(source, Config.MaxTuiDo) -- Đặt giá trị mặc định
            exports.ox_inventory:SetMaxWeight(source, Config.MaxCanNang)
            --print("No bag found or bag has no metadata, using default config")
        end
        
        TriggerClientEvent('gin:dong:inven', source)
    end)
end




RegisterNetEvent('gin:server:HienBalo', function(isBagVisible)
    local source_ = source
    if not source_ then return end
    local components2 = {}
    Citizen.SetTimeout(100, function()
        local slotData = exports.ox_inventory:GetSlot(source_, Config.SlotBalo) -- Lấy dữ liệu slot 19
        -- print(isBagVisible)
        if slotData then
            local drawable = slotData.metadata
            if isBagVisible then 
                components2 = {
                    texture = drawable.texture,
                    drawable = drawable.drawable,
                    component_id = 5
                }
            else 
                components2 = {
                    texture = 0,
                    drawable = 0,
                    component_id = 5
                }
            end 
        end
        TriggerClientEvent('setPedComponent', source_, components2)
    end)
end)

local function onPlayerLoaded(source)
    SetTimeout(2000, function()
        -- Check if player still online
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if not xPlayer then
            return
        end

        -- Check and load bag data when player joins
        local bagSlot = exports.ox_inventory:GetSlot(source, Config.SlotBalo)
        if bagSlot and bagSlot.metadata and bagSlot.metadata.drawable then
            -- Player has bag equipped, load its capacity and weight
            BagAdd(source, bagSlot.metadata, true)
        else 
            -- No bag equipped, reset to default
            BagAdd(source, nil, true)
        end
    end)
end


RegisterNetEvent('QBCore:PlayerLoaded', function(playerId)
    if not playerId then 
        return 
    end

    onPlayerLoaded(playerId)
end)

RegisterServerEvent('RefreshArmsAndTShirt')
AddEventHandler('RefreshArmsAndTShirt', function()
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end

    local playerGender = PlayerSex[source] or "male"
    local armsSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, componentMapping.gloves.clothesSlotID)
    local tShirtSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, componentMapping.shirt.clothesSlotID)
    
    -- Validate gender for arms
    local armsData = nil
    if armsSlot and armsSlot.metadata then
        local itemGender = armsSlot.metadata.sex or "male"
        if itemGender == playerGender then
            armsData = armsSlot.metadata
        end
    end
    
    -- Validate gender for tshirt
    local tShirtData = nil
    if tShirtSlot and tShirtSlot.metadata then
        local itemGender = tShirtSlot.metadata.sex or "male"
        if itemGender == playerGender then
            tShirtData = tShirtSlot.metadata
        end
    end

    TriggerClientEvent('refreshaandtshirt', player.PlayerData.source, armsData, tShirtData)
end)



RegisterServerEvent('sex:loadPlayer')
AddEventHandler('sex:loadPlayer',function(sex)
    PlayerSex[source] = sex 
end)


function GetPlayerClothes(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData then
        return
    end

    local ClothesData = {}
    ClothesData.sex = PlayerSex[source]

    for _, item in pairs(componentMapping) do
        if item.clothesSlotID ~= componentMapping.clothes.clothesSlotID then
            local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, item.clothesSlotID)
            if itemInSlot and itemInSlot.metadata and (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal')) then
                local metadata = itemInSlot.metadata
                local itemData = {
                    name = item.itemname,
                    sex = PlayerSex[source],
                    drawable = metadata.drawable,
                    texture = metadata.texture,
                    component_id = item.component,
                    prop_id = item.prop,
                    camera = item.camera
                }
                if metadata.token then
                    itemData.token = metadata.token
                end
                table.insert(ClothesData, itemData)
            end
        end
    end

    if #ClothesData == 0 then
        local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, componentMapping.clothes.clothesSlotID)
        if itemInSlot and itemInSlot.name == 'clothes' then
            exports.ox_inventory:RemoveItem(player.PlayerData.source, 'clothes', 1, itemInSlot.metadata, componentMapping.clothes.clothesSlotID)
        end
    end

    return ClothesData
end



function ClothesMoved(source, toSlot)
    Citizen.CreateThread(function()
        Wait(200)
        local player = QBCore.Functions.GetPlayer(source)
        if not player or not player.PlayerData then
            return
        end
        TriggerClientEvent('animation:clothes', source)

        local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, toSlot)
        if itemInSlot and itemInSlot.metadata then
            local clothesdata = GetPlayerClothes(source)

            if clothesdata and #clothesdata > 0 then
                clothesdata.label = itemInSlot.metadata.label
                exports.ox_inventory:SetMetadata(player.PlayerData.source, toSlot, clothesdata)
            end
        end

        for _, item in pairs(componentMapping) do
            local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, item.clothesSlotID)
            if itemInSlot and (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal')) then 
                exports.ox_inventory:RemoveItem(player.PlayerData.source, itemInSlot.name, 1, itemInSlot.metadata, item.clothesSlotID)
            end 
        end

        TriggerClientEvent('clothes:resetPed', player.PlayerData.source)
    end)
end


function ClothesMovedToGood(source)
    Citizen.CreateThread(function()
        Wait(200)
        local player = QBCore.Functions.GetPlayer(source)
        if not player then 
            return 
        end

        local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, componentMapping.clothes.clothesSlotID)
        if itemInSlot and itemInSlot.name == 'clothes' and itemInSlot.metadata then
            local clothesList = itemInSlot.metadata
            TriggerClientEvent('clothes:refreshClothes', player.PlayerData.source, clothesList)
            TriggerClientEvent('animation:clothes', source)
            
            if not clothesList.sex then
                clothesList.sex = PlayerSex[player.PlayerData.source]
            end

            for _, clothing in pairs(clothesList) do
                if type(clothing) == "table" then  
                    for _, mapping in pairs(componentMapping) do
                        local isMatchingComponent = mapping.component == clothing.component_id
                        local isMatchingProp = isPropToBool(mapping.prop) == isPropToBool(clothing.prop_id)
                        local sameSex = PlayerSex[player.PlayerData.source] == (clothing.sex or clothesList.sex)
                        
                        if not sameSex then
                            return 
                        end 

                        if isMatchingComponent and isMatchingProp and mapping.itemname == clothing.name then
                            if Config.NoImage then
                                local itemData = {
                                    name = clothing.name,
                                    label = clothing.label,
                                    drawable = clothing.drawable,
                                    texture = clothing.texture,
                                    component_id = clothing.component_id,
                                    prop_id = clothing.prop_id,
                                    sex = PlayerSex[player.PlayerData.source],
                                    camera = clothing.camera
                                }

                                if clothing.name == 'cloth_bags' then
                                    itemData.metadata = clothing.metadata
                                    itemData.token = clothing.token
                                end
    
                                exports.ox_inventory:AddItem(
                                    player.PlayerData.source,
                                    clothing.name,
                                    1,
                                    itemData,
                                    mapping.clothesSlotID
                                )
                            else
                                local imagename
                                if clothing.prop_id then
                                    imagename = Config.Url .. "/".. PlayerSex[player.PlayerData.source].."_prop_"..clothing.component_id..'_'..clothing.drawable..'.'..Config.Extension
                                else
                                    imagename = Config.Url .. "/".. PlayerSex[player.PlayerData.source].."_" ..clothing.component_id..'_'..clothing.drawable..'.'..Config.Extension
                                end
                                local itemData = {
                                    name = clothing.name,
                                    label = clothing.label,
                                    drawable = clothing.drawable,
                                    texture = clothing.texture,
                                    component_id = clothing.component_id,
                                    prop_id = clothing.prop_id,
                                    sex = PlayerSex[player.PlayerData.source],
                                    imageurl = imagename,
                                    camera = clothing.camera
                                }

                                if clothing.name == 'cloth_bags' then
                                    itemData.metadata = clothing.metadata
                                    itemData.token = clothing.token
                                end
    
                                exports.ox_inventory:AddItem(
                                    player.PlayerData.source,
                                    clothing.name,
                                    1,
                                    itemData,
                                    mapping.clothesSlotID
                                )
                            end
                        end
                    end
                end
            end
        end
    end)
end



function GetPlayerClothesAndStock(source)
    
    Citizen.CreateThread(function()
        Wait(200)
        local player = QBCore.Functions.GetPlayer(source)
        if not player then
            return
        end

        local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, componentMapping.clothes.clothesSlotID)
        local clothesdata = GetPlayerClothes(source)
        
        if clothesdata and itemInSlot then  
            clothesdata.label = itemInSlot.metadata.label
        end 

        if itemInSlot == nil then
            if clothesdata then  
                exports.ox_inventory:AddItem(
                    player.PlayerData.source,
                    'clothes',
                    1,
                    clothesdata,
                    componentMapping.clothes.clothesSlotID
                )
            end
            
        elseif itemInSlot and itemInSlot.name == 'clothes' then
            exports.ox_inventory:SetMetadata(player.PlayerData.source, componentMapping.clothes.clothesSlotID, clothesdata)
            Wait(200)
        end
    end)
end

function GetPlayerSource(player)
    if not player then return nil end

    if Config.FrameWork == "ESX" then
        return player.source or nil

    elseif Config.FrameWork == "QBOX" then
        return player.PlayerData and player.PlayerData.source or player.source or nil
    else
        --print("Framework non pris en charge pour GetPlayerSource")
        return nil
    end
end

function isClothingRestrictedByJob(playerJob, componentId, drawable, sex, isProp)
    if not Config.JobOutifsBlackList then
        return false
    end
    
    local gender = sex == "female" and "women" or "men"
    local hasRestriction = false
    local propBool = isPropToBool(isProp)
    
    for _, jobRestriction in pairs(Config.JobOutifsBlackList) do
        local restrictions = jobRestriction.clothes[gender]
        
        if restrictions then
            for _, restriction in pairs(restrictions) do
                if restriction.component_id == componentId and isPropToBool(restriction.props) == propBool then
               
                    for _, restrictedDrawable in pairs(restriction.drawable) do
                        if restrictedDrawable == drawable then
                            hasRestriction = true
                         
                            if jobRestriction.job == playerJob then
                                return false 
                            end
                        end
                    end
                end
            end
        end
    end
    
    return hasRestriction
end

RegisterServerEvent('clothes:defaultoutfit')
AddEventHandler('clothes:defaultoutfit', function()
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local isoutfit = exports.ox_inventory:GetSlot(xPlayer.PlayerData.source, componentMapping.clothes.clothesSlotID)
    
    if isoutfit and isoutfit.name == 'clothes' then
        exports.ox_inventory:RemoveItem(xPlayer.PlayerData.source, 'clothes', 1, isoutfit.metadata, componentMapping.clothes.clothesSlotID) 
        exports.ox_inventory:AddItem(xPlayer.PlayerData.source, 'clothes', 1, isoutfit.metadata)
    end

    for _, item in pairs(componentMapping) do
        if item.clothesSlotID ~= componentMapping.clothes.clothesSlotID then
            local itemInSlot = exports.ox_inventory:GetSlot(xPlayer.PlayerData.source, item.clothesSlotID)
            if itemInSlot and (itemInSlot.name == item.itemname or (item.itemname == 'cloth_decals' and itemInSlot.name == 'cloth_decal')) then 
                exports.ox_inventory:RemoveItem(xPlayer.PlayerData.source, itemInSlot.name, 1, itemInSlot.metadata, item.clothesSlotID)
            end 
        end
    end
end)

RegisterServerEvent('clothes:purchaseClothesoutfit')
AddEventHandler('clothes:purchaseClothesoutfit', function(data)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then
        return
    end

    local playerSex = PlayerSex[xPlayer.PlayerData.source] or "male"

    -- Kiểm tra nếu có món đồ TradeShop trong gói mua outfit bằng tiền mặt
    for _, item in pairs(data.items) do
        local cat = item.category
        local idx = tonumber(item.index)
        if Config.TradeShop and idx then
            local isTrade = false
            if Config.TradeShop.AllowedDrawables then
                local list = (Config.TradeShop.AllowedDrawables[cat] and Config.TradeShop.AllowedDrawables[cat][playerSex])
                    or (Config.TradeShop.AllowedDrawables[playerSex] and Config.TradeShop.AllowedDrawables[playerSex][cat])
                    or (cat == "gloves" and Config.TradeShop.AllowedDrawables[playerSex])
                if list then
                    for _, d in ipairs(list) do
                        if tonumber(d) == idx then
                            isTrade = true
                            break
                        end
                    end
                end
            end
            if not isTrade and Config.TradeShop.Items then
                if (Config.TradeShop.Items[cat] and Config.TradeShop.Items[cat][playerSex] and Config.TradeShop.Items[cat][playerSex][idx])
                    or (Config.TradeShop.Items[playerSex] and Config.TradeShop.Items[playerSex][cat] and Config.TradeShop.Items[playerSex][cat][idx])
                    or (cat == "gloves" and Config.TradeShop.Items[playerSex] and Config.TradeShop.Items[playerSex][idx]) then
                    isTrade = true
                end
            end
            if isTrade then
                TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "Không thể mua vật phẩm Tattoo bằng tiền mặt trong gói outfit!", "error")
                return
            end
        end
    end

    if xPlayer.Functions.GetMoney('cash') < data.totalPrice then
        TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, Config.Notification.notenoughmoney, "error")
        return
    end

    xPlayer.Functions.RemoveMoney('cash', data.totalPrice)

    local ClothesData = {}
    ClothesData.sex = PlayerSex[xPlayer.PlayerData.source]

    for _, item in pairs(data.items) do
        local category = item.category
        if componentMapping[category] then

            if isClothingRestrictedByJob(GetJobName(GetPlayerSource(xPlayer)), componentMapping[category].component, item.index, PlayerSex[GetPlayerSource(xPlayer)], componentMapping[category].prop) then
                TriggerClientEvent('QBCore:Notify', GetPlayerSource(xPlayer), Config.Notification.restrictedClothing)
                AddPlayerMoney(GetPlayerSource(xPlayer), data.totalPrice)
                setPlayerProcessing(GetPlayerSource(xPlayer), false)
                return
            end

            local itemData = {
                name = componentMapping[category].itemname,
                sex = PlayerSex[xPlayer.PlayerData.source],
                drawable = item.index,
                texture = item.texture,
                component_id = componentMapping[category].component,
                prop_id = componentMapping[category].prop,
                camera = componentMapping[category].camera
            }
            table.insert(ClothesData, itemData)
        end
    end

    if #ClothesData > 0 then
        local success = exports.ox_inventory:AddItem(xPlayer.PlayerData.source, 'clothes', 1, ClothesData)
        if success then
            TriggerClientEvent('clothes:refreshClothes', xPlayer.PlayerData.source, ClothesData)
            TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, Config.Notification.outfitexported, "success")
        else
            xPlayer.Functions.AddMoney('cash', data.totalPrice)
            TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "Erreur lors de l'achat", "error")
        end
    end
end)

-- Lệnh tải lại cài đặt túi (ai cũng có thể sử dụng)
-- RegisterCommand('tailaitui', function(source, args, rawCommand)
--     -- Check if it's run by server console
--     if source == 0 then
--         -- Server console - chỉ admin có thể reload túi của người khác
--         if args[1] then
--             local targetId = tonumber(args[1])
--             if targetId and GetPlayerPed(targetId) then
--                 BagAdd(targetId, nil, true)
--                 print(("Bag reloaded for player ID: %s"):format(targetId))
--             else
--                 print("Invalid player ID")
--             end
--         else
--             print("Usage: reloadbag [playerid]")
--         end
--     else
--         -- Player command - người chơi chỉ có thể reload túi của chính họ
--         local player = QBCore.Functions.GetPlayer(source)
--         if player then
--             -- Chỉ reload túi của chính người chơi đó
--             BagAdd(source, nil, true)
--             TriggerClientEvent('QBCore:Notify', source, 'Túi của bạn đã được tải lại', 'success')
--         end
--     end
-- end, false)

-- Lệnh thay thế cho người chơi tải lại túi của riêng họ
RegisterCommand('taibalo', function(source, args, rawCommand)
    if source ~= 0 then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            BagAdd(source, nil, true)
            TriggerClientEvent('QBCore:Notify', source, 'Túi của bạn đã được tải lại', 'success')
        end
    end
end, false)



RegisterServerEvent('XNClothes:loadbalo')
AddEventHandler('XNClothes:loadbalo', function()
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        --print('load')
        BagAdd(source, nil, true)
        TriggerClientEvent('QBCore:Notify', source, 'Túi của bạn đã được tải lại', 'success')
    end
end)

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, job)
    local src = source
    local bagSlot = exports.ox_inventory:GetSlot(src, Config.SlotBalo)
    if bagSlot and bagSlot.metadata and bagSlot.metadata.drawable then
        BagAdd(src, bagSlot.metadata, true)
    end
end)

RegisterNetEvent('qbx_core:server:onJobUpdate', function(source, job)
    local src = source
    local bagSlot = exports.ox_inventory:GetSlot(src, Config.SlotBalo)
    if bagSlot and bagSlot.metadata and bagSlot.metadata.drawable then
        BagAdd(src, bagSlot.metadata, true)
    end
end)

RegisterNetEvent('esx:setJob', function(playerId, job)
    local src = playerId
    local bagSlot = exports.ox_inventory:GetSlot(src, Config.SlotBalo)
    if bagSlot and bagSlot.metadata and bagSlot.metadata.drawable then
        BagAdd(src, bagSlot.metadata, true)
    end
end)

-- Handle state bag 'onDuty' change (CamelCase)
AddStateBagChangeHandler('onDuty', nil, function(bagName, key, value, _unused, replicated)
    if string.sub(bagName, 1, 7) == 'player:' then
        local playerId = tonumber(string.sub(bagName, 8))
        if playerId then
            SetTimeout(200, function()
                local bagSlot = exports.ox_inventory:GetSlot(playerId, Config.SlotBalo)
                if bagSlot and bagSlot.metadata and bagSlot.metadata.drawable then
                    BagAdd(playerId, bagSlot.metadata, true)
                end
            end)
        end
    end
end)

-- Handle state bag 'onduty' change (lowercase)
AddStateBagChangeHandler('onduty', nil, function(bagName, key, value, _unused, replicated)
    if string.sub(bagName, 1, 7) == 'player:' then
        local playerId = tonumber(string.sub(bagName, 8))
        if playerId then
            SetTimeout(200, function()
                local bagSlot = exports.ox_inventory:GetSlot(playerId, Config.SlotBalo)
                if bagSlot and bagSlot.metadata and bagSlot.metadata.drawable then
                    BagAdd(playerId, bagSlot.metadata, true)
                end
            end)
        end
    end
end)

-- Handle state bag 'job' change
AddStateBagChangeHandler('job', nil, function(bagName, key, value, _unused, replicated)
    if string.sub(bagName, 1, 7) == 'player:' then
        local playerId = tonumber(string.sub(bagName, 8))
        if playerId then
            SetTimeout(200, function()
                local bagSlot = exports.ox_inventory:GetSlot(playerId, Config.SlotBalo)
                if bagSlot and bagSlot.metadata and bagSlot.metadata.drawable then
                    BagAdd(playerId, bagSlot.metadata, true)
                end
            end)
        end
    end
end)

local function ForceUnequipBag(targetPlayerId)
    local src = targetPlayerId
    if not src then return end
    
    local bagSlot = exports.ox_inventory:GetSlot(src, Config.SlotBalo)
    if bagSlot and bagSlot.name and bagSlot.metadata then
        local drawable = bagSlot.metadata.drawable
        if drawable and (tonumber(drawable) == 395 or tonumber(drawable) == 413) then
            -- Tìm slot trống trong khoảng từ 22 đến 33
            local targetSlot = nil
            for slot = 22, 33 do
                local slotInfo = exports.ox_inventory:GetSlot(src, slot)
                if not slotInfo or not slotInfo.name then
                    targetSlot = slot
                    break
                end
            end
            
            -- Tháo balo: di chuyển balo từ SlotBalo về túi đồ thường hoặc bưu cục
            exports.ox_inventory:RemoveItem(src, bagSlot.name, 1, bagSlot.metadata, Config.SlotBalo)
            if targetSlot then
                exports.ox_inventory:AddItem(src, bagSlot.name, 1, bagSlot.metadata, targetSlot)
            else
                local player = GetPlayer(src)
                local citizenid = player and (player.PlayerData and player.PlayerData.citizenid or player.identifier)
                local success_storage = false
                if citizenid then
                    success_storage = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, bagSlot.name, 1, bagSlot.metadata)
                end
                
                if success_storage then
                    if Config.FrameWork == "ESX" then
                        TriggerClientEvent('esx:showNotification', src, "Túi đồ đầy! Balo đặc biệt đã được gửi về bưu cục.")
                    else
                        TriggerClientEvent('QBCore:Notify', src, "Túi đồ đầy! Balo đặc biệt đã được gửi về bưu cục.", 'info')
                    end
                else
                    exports.ox_inventory:AddItem(src, bagSlot.name, 1, bagSlot.metadata)
                end
            end
            
            -- Set slot và weight mặc định
            exports.ox_inventory:SetSlotCount(src, Config.MaxTuiDo)
            exports.ox_inventory:SetMaxWeight(src, Config.MaxCanNang)
            
            -- Đặt lại component ngoại hình về không mặc balo
            TriggerClientEvent('setPedComponent', src, {
                texture = 0,
                drawable = 0,
                component_id = 5
            })
            
            if Config.FrameWork == "ESX" then
                TriggerClientEvent('esx:showNotification', src, "Balo đặc biệt đã tự động tháo khi bạn off duty.")
            else
                TriggerClientEvent('QBCore:Notify', src, "Balo đặc biệt đã tự động tháo khi bạn off duty.", 'error')
            end
            
            TriggerClientEvent('gin:dong:inven', src)
        end
    end
end

RegisterNetEvent('XNClothes:Server:ForceUnequipBag', function(targetPlayerId)
    local src = targetPlayerId or source
    ForceUnequipBag(src)
end)

-- Exports để resource khác có thể sử dụng
exports('GetPlayerClothesAndStock', GetPlayerClothesAndStock)
exports('GetPlayerClothes', GetPlayerClothes)
exports('CheckClothingDurability', CheckClothingDurability)
exports('UpdateClothingMonitor', UpdateClothingMonitor)
exports('CheckAndReloadClothing', CheckAndReloadClothing)
exports('ResetComponentToDefault', ResetComponentToDefault)
exports('ForceUnequipBag', ForceUnequipBag)
exports('GetPlayerSex', function(source)
    return PlayerSex[source]
end)