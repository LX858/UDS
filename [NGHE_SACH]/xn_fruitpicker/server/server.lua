usedTrees = {}

-- Register useable items with QBX Core
exports.qbx_core:CreateUseableItem('fruit_basket', function(source, item)
    local Player = exports.qbx_core:GetPlayer(source)
    
    -- Kiểm tra nếu player đang on duty với job police, ambulance, hoặc cardealer
    if Player and Player.PlayerData.job and Player.PlayerData.job.name then
        local blockedJobs = {
            ['police'] = true,
            ['ambulance'] = true,
            ['cardealer'] = true
        }
        
        -- Chỉ chặn nếu player có job trong danh sách VÀ đang on-duty
        if blockedJobs[Player.PlayerData.job.name] and Player.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Hái Cam',
                description = 'Bạn đang làm việc, không thể sử dụng giỏ cam!',
                type = 'error'
            })
            return
        end
    end
    
    local itemData = {
        name = item.name,
        slot = item.slot,
        metadata = item.metadata or {},
        info = item.metadata or {}
    }
    TriggerClientEvent("xn-fruitpicker:usebasket", source, itemData)
end)

-- Callback kiểm tra xem cây có thể hái không (dựa trên server-side cooldown và cân nặng)
lib.callback.register('xn-fruitpicker:canPickTree', function(source, treeKey)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false, 'cooldown', 0 end
    
    -- Kiểm tra sức chứa (cân nặng) trước khi hái
    local canCarryWeight = exports.ox_inventory:CanCarryWeight(source, 1000)
    if not canCarryWeight then
        return false, 'weight', 0
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- Nếu chưa từng hái cây này
    if not usedTrees[citizenId] or not usedTrees[citizenId][treeKey] then
        return true, 'ok', 0
    end
    
    -- Kiểm tra thời gian đã trải qua kể từ lần hái cuối
    local lastPickTime = usedTrees[citizenId][treeKey]
    local currentTime = os.time()
    local timePassed = currentTime - lastPickTime
    local cooldownSeconds = math.floor(Config.Timeout / 1000)
    
    if timePassed >= cooldownSeconds then
        -- Đã hết cooldown, có thể hái
        return true, 'ok', 0
    else
        -- Còn cooldown, trả về thời gian còn lại
        local timeRemaining = cooldownSeconds - timePassed
        return false, 'cooldown', timeRemaining
    end
end)

lib.callback.register('xn-fruitpicker:server:getdata', function(source)
    local playerData = {}
    
    local success, Player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)
    
    if not success or not Player then 
        return playerData 
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- Trả về danh sách cây và trạng thái cooldown
    if usedTrees[citizenId] ~= nil then
        local currentTime = os.time()
        local cooldownSeconds = math.floor(Config.Timeout / 1000)
        
        for treeKey, timestamp in pairs(usedTrees[citizenId]) do
            local timePassed = currentTime - timestamp
            if timePassed >= cooldownSeconds then
                -- Hết cooldown, có thể hái
                playerData[treeKey] = false
            else
                -- Còn cooldown
                playerData[treeKey] = true
            end
        end
    end
    
    return playerData
end)

-- Helper xử lý tỉ lệ nhận Thẻ Hái Cam (Config.TheHaiCamDrop)
local function handleSpecialCardDrop(src, count, sourceEvent)
    if not (Config.TheHaiCamDrop and Config.TheHaiCamDrop.enabled) then return end
    
    local triggerMode = Config.TheHaiCamDrop.triggerOn or 'take_from_basket'
    if triggerMode ~= 'both' and triggerMode ~= sourceEvent then
        return
    end

    local chance = Config.TheHaiCamDrop.chance or 20
    local specialItemCount = 0
    for i = 1, count do
        local roll = math.random(1, 100)
        if roll <= chance then
            specialItemCount = specialItemCount + 1
        end
    end

    if Config.Debug then
        print(string.format("^2[DEBUG] TheHaiCamDrop - Source: %s, Count: %d, Chance: %d%%, Won: %d (Player: %s)^7", 
            tostring(sourceEvent), count, chance, specialItemCount, tostring(src)))
    end

    if specialItemCount > 0 then
        local itemName = Config.TheHaiCamDrop.itemName or "the_hai_cam"
        local itemLabel = Config.TheHaiCamDrop.itemLabel or "Thẻ Hái Cam"
        
        local added = exports.ox_inventory:AddItem(src, itemName, specialItemCount)
        if added then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Vật Phẩm Đặc Biệt',
                description = string.format('Bạn nhận được thêm x%d %s!', specialItemCount, itemLabel),
                type = 'success'
            })
            if Config.Debug then
                print(string.format("^2[DEBUG] TheHaiCamDrop: AddItem success (x%d %s to %s)^7", 
                    specialItemCount, itemName, tostring(src)))
            end
        else
            local canCarry = exports.ox_inventory:CanCarryItem(src, itemName, specialItemCount)
            if canCarry == false then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Túi Đầy',
                    description = string.format('Bạn nhận được %s nhưng túi đồ không đủ chỗ chứa!', itemLabel),
                    type = 'error'
                })
            else
                print(string.format("^1[ERROR] [xn_fruitpicker] Không thể AddItem '%s' cho player %s! Vui lòng kiểm tra xem item '%s' đã được khai báo trong ox_inventory/data/items.lua chưa!^7", itemName, tostring(src), itemName))
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Lỗi Item',
                    description = string.format('Không thể nhận %s (Item chưa được thêm vào ox_inventory/data/items.lua)!', itemLabel),
                    type = 'error'
                })
            end
        end
    end
end

-- ============================================================
-- SERVER-AUTHORITATIVE: Thêm cam vào sọt (chống bug đảo slot)
-- Client gửi basketSlot hiện tại; server tự đọc metadata từ
-- ox_inventory để đảm bảo số liệu chính xác.
-- ============================================================
lib.callback.register('xn-fruitpicker:server:addOrangeToBasket', function(source, basketSlot, treeKey)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then
        return false, 'player_not_found'
    end

    -- Lấy inventory của player từ ox_inventory (authoritative)
    local inv = exports.ox_inventory:GetInventory(src, false)
    if not inv or not inv.items then
        return false, 'inventory_error'
    end

    -- Tìm fruit_basket tại đúng slot mà client khai báo
    local basketItem = nil
    for slotNum, item in pairs(inv.items) do
        if item and item.name == 'fruit_basket' and item.slot == basketSlot then
            basketItem = item
            break
        end
    end

    if not basketItem then
        -- Thử tìm bất kỳ fruit_basket nào nếu slot không match
        -- (phòng trường hợp client gửi slot cũ)
        if Config.Debug then
            print(string.format("^3[DEBUG] addOrangeToBasket: basket not found at slot %s, searching all slots^7", tostring(basketSlot)))
        end
        for slotNum, item in pairs(inv.items) do
            if item and item.name == 'fruit_basket' then
                basketItem = item
                if Config.Debug then
                    print(string.format("^3[DEBUG] addOrangeToBasket: found basket at slot %d^7", item.slot))
                end
                break
            end
        end
    end

    if not basketItem then
        return false, 'basket_not_found'
    end

    -- Đọc qty hiện tại từ metadata thực tế trong inventory
    local currentMeta = basketItem.metadata or {}
    local currentQty = currentMeta.qty or 0
    local maxOranges = Config.BasketMaxOranges or 20

    -- Kiểm tra giới hạn 20 quả
    if currentQty >= maxOranges then
        return false, 'basket_full', currentQty, basketItem.slot
    end

    -- Kiểm tra sức chứa (cân nặng) trước khi hái
    local canCarryWeight = exports.ox_inventory:CanCarryWeight(src, 1000)
    if not canCarryWeight then
        return false, 'cannot_carry_weight', currentQty, basketItem.slot
    end

    -- Tính qty mới
    local newQty = currentQty + 1

    -- Cập nhật metadata
    local newMetadata = {}
    for k, v in pairs(currentMeta) do
        newMetadata[k] = v
    end
    newMetadata.qty = newQty
    newMetadata.weight = newQty * 1000

    -- Ghi metadata vào đúng slot xác thực
    local setOk = exports.ox_inventory:SetMetadata(src, basketItem.slot, newMetadata)

    if Config.Debug then
        print(string.format("^2[DEBUG] addOrangeToBasket: slot=%d, qty %d->%d, SetMetadata=%s^7",
            basketItem.slot, currentQty, newQty, tostring(setOk)))
    end

    -- Cập nhật cooldown cây
    if treeKey then
        local citizenId = Player.PlayerData.citizenid
        if not usedTrees[citizenId] then
            usedTrees[citizenId] = {}
        end
        usedTrees[citizenId][treeKey] = os.time()

        -- Sync cooldown về client
        local playerData = {}
        local currentTime = os.time()
        local cooldownSeconds = math.floor(Config.Timeout / 1000)
        for key, timestamp in pairs(usedTrees[citizenId]) do
            local timePassed = currentTime - timestamp
            playerData[key] = (timePassed < cooldownSeconds)
        end
        TriggerClientEvent("xn-fruitpicker:updatedata", src, playerData)
    end

    -- Update player reputation
    local jobRep = Player.PlayerData.metadata.jobrep or {}
    if jobRep.fruitpeeker ~= nil then
        if jobRep.fruitpeeker > 40 then
            jobRep.fruitpeeker = jobRep.fruitpeeker + 0.05
        elseif jobRep.fruitpeeker > 30 then
            jobRep.fruitpeeker = jobRep.fruitpeeker + 0.1
        elseif jobRep.fruitpeeker > 20 then
            jobRep.fruitpeeker = jobRep.fruitpeeker + 0.15
        elseif jobRep.fruitpeeker > 10 then
            jobRep.fruitpeeker = jobRep.fruitpeeker + 0.2
        else
            jobRep.fruitpeeker = jobRep.fruitpeeker + 0.25
        end
    else
        jobRep.fruitpeeker = 0.25
    end
    Player.Functions.SetMetaData("jobrep", jobRep)

    -- Rare item drop chance when picking orange
    if Config.RareItemDrop.enabled and treeKey then
        local randomChance = math.random(1, 100)
        if randomChance <= Config.RareItemDrop.chance then
            local rareMetadata = { weight = Config.RareItemDrop.weight or 1000 }
            local canCarry = exports.ox_inventory:CanCarryItem(src, Config.RareItemDrop.itemName, 1, rareMetadata)
            
            if not canCarry then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Hái Cam',
                    description = 'Tìm thấy cam đặc biệt nhưng không đủ chỗ để nhặt!',
                    type = 'error'
                })
            else
                local rareSuccess = exports.ox_inventory:AddItem(src, Config.RareItemDrop.itemName, 1, rareMetadata)
                if rareSuccess then
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Hái Cam',
                        description = 'Bạn đã tìm thấy một quả cam đặc biệt!',
                        type = 'success'
                    })
                end
            end
        end
    end

    -- Special card drop (nếu triggerOn = 'tree' hoặc 'both')
    handleSpecialCardDrop(src, 1, 'tree')

    return true, 'ok', newQty, basketItem.slot
end)

RegisterServerEvent("xn-fruitpicker:savebasket")
AddEventHandler("xn-fruitpicker:savebasket", function(basketData, treeKey)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    -- Update basket metadata in ox_inventory
    local newMetadata = basketData.metadata or basketData.info or {}
    local qty = basketData.info and basketData.info.qty or basketData.metadata and basketData.metadata.qty or 0
    newMetadata.qty = qty
    
    -- Set weight as only the additional weight from oranges (ox_inventory adds this to base item weight)
    -- Each orange adds 1kg (1000g)
    newMetadata.weight = qty * 1000
    
    if Config.Debug then
        print(string.format("^2[DEBUG] Basket weight updated: qty=%d, additional_weight=%dg, total_weight=%dg^7", qty, newMetadata.weight, 2000 + newMetadata.weight))
    end
    
    exports.ox_inventory:SetMetadata(src, basketData.slot, newMetadata)
end)

RegisterServerEvent("xn-fruitpicker:addorg")
AddEventHandler("xn-fruitpicker:addorg", function(treeKey)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    local citizenId = Player.PlayerData.citizenid
    
    -- Lưu timestamp thay vì boolean
    if usedTrees[citizenId] ~= nil then
        usedTrees[citizenId][treeKey] = os.time()
    else
        usedTrees[citizenId] = {}
        usedTrees[citizenId][treeKey] = os.time()
    end
    
    if Config.Debug then
        print(string.format("^2[DEBUG] Tree picked - CitizenId: %s, TreeKey: %s, Timestamp: %d^7", 
            citizenId, tostring(treeKey), os.time()))
    end
    
    -- Sync data về client
    local playerData = {}
    local currentTime = os.time()
    local cooldownSeconds = math.floor(Config.Timeout / 1000)
    
    for key, timestamp in pairs(usedTrees[citizenId]) do
        local timePassed = currentTime - timestamp
        playerData[key] = (timePassed < cooldownSeconds)
    end
    
    TriggerClientEvent("xn-fruitpicker:updatedata", src, playerData)
end)

-- Event này không còn cần thiết vì cooldown check theo timestamp
-- Giữ lại để tương thích ngược, nhưng không làm gì
RegisterServerEvent("xn-fruitpicker:removeorg")
AddEventHandler("xn-fruitpicker:removeorg", function(treeKey)
    -- Deprecated: Cooldown giờ check theo timestamp ở server
    if Config.Debug then
        print("^3[DEBUG] removeorg event called but deprecated^7")
    end
end)

RegisterServerEvent("xn-fruitpicker:removebasket")
AddEventHandler("xn-fruitpicker:removebasket", function(playerId)
    TriggerClientEvent("xn-fruitpicker:removebasket", playerId)
end)

-- Callback kiểm tra sức chứa (slot và weight) trước khi lấy cam
lib.callback.register('xn-fruitpicker:canCarryOranges', function(source, amount)
    -- Kiểm tra cả slot và weight
    -- Mỗi quả cam: 1kg (1000g)
    local canCarryWeight = exports.ox_inventory:CanCarryWeight(source, amount * 1000)
    local canCarryItem = exports.ox_inventory:CanCarryItem(source, "orange", amount)
    
    local canCarry = canCarryWeight and canCarryItem
    
    if Config.Debug then
        print(string.format("^2[DEBUG] Can carry oranges - Amount: %d, Weight: %s, Slot: %s, Result: %s^7", 
            amount, tostring(canCarryWeight), tostring(canCarryItem), tostring(canCarry)))
    end
    
    return canCarry
end)

-- Callback kiểm tra sức chứa (slot và weight) trước khi thêm cam vào sọt
lib.callback.register('xn-fruitpicker:canAddFruitToBasket', function(source)
    -- Kiểm tra cả slot và weight
    -- Mỗi quả cam: 1 slot và 1kg (1000g)
    local canCarryWeight = exports.ox_inventory:CanCarryWeight(source, 1000)
    local canCarryItem = exports.ox_inventory:CanCarryItem(source, "orange", 1)
    
    local canCarry = canCarryWeight and canCarryItem
    
    if Config.Debug then
        print(string.format("^2[DEBUG] Can add fruit to basket - Weight: %s, Slot: %s, Result: %s^7", 
            tostring(canCarryWeight), tostring(canCarryItem), tostring(canCarry)))
    end
    
    return canCarry
end)

exports['monitors']:RegisterProtectedEvent("xn-fruitpicker:getoranges", function(src, amount)
    
    -- Kiểm tra slot và cân nặng TRƯỚC KHI thêm cam vào inventory
    local canCarryWeight = exports.ox_inventory:CanCarryWeight(src, amount * 1000) -- Mỗi cam 1kg
    local canCarryItem = exports.ox_inventory:CanCarryItem(src, "orange", amount)
    
    if not canCarryWeight or not canCarryItem then
        local reason = ""
        if not canCarryWeight and not canCarryItem then
            reason = "không đủ slot và cân nặng"
        elseif not canCarryWeight then
            reason = "không đủ cân nặng"
        else
            reason = "không đủ slot"
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Không thể lấy ' .. amount .. ' quả cam - ' .. reason .. '!',
            type = 'error'
        })
        
        if Config.Debug then
            print(string.format("^3[DEBUG] Cannot add oranges - Amount: %d, Weight: %s, Slot: %s^7", 
                amount, tostring(canCarryWeight), tostring(canCarryItem)))
        end
        
        return
    end
    
    local success = exports.ox_inventory:AddItem(src, "orange", amount)
    
    if success then
        -- Find basket and reduce durability
        local inv = exports.ox_inventory:GetInventory(src, false)
        if inv and inv.items then
            for slotNum, basketItem in pairs(inv.items) do
                if basketItem and basketItem.name == 'fruit_basket' then
                    local currentDurability = basketItem.metadata and basketItem.metadata.durability or Config.BasketDurability
                    local durabilityLoss = Config.DurabilityPerOrange * amount
                    local newDurability = math.max(0, currentDurability - durabilityLoss)
                    
                    if Config.Debug then
                        print(string.format("^2[DEBUG] Pickup Orange - Basket Durability: %d -> %d (Amount: %d, Slot: %s)^7", currentDurability, newDurability, amount, tostring(slotNum)))
                    end
                    
                    if newDurability <= 0 then
                        -- Remove basket when durability reaches 0
                        exports.ox_inventory:RemoveItem(src, 'fruit_basket', 1, basketItem.metadata, slotNum)
                        TriggerClientEvent('ox_lib:notify', src, {
                            description = 'Sọt cam đã hỏng do sử dụng quá nhiều!',
                            type = 'error'
                        })
                        TriggerClientEvent("xn-fruitpicker:removebasket", src)
                    else
                        -- Update durability
                        local durOk = exports.ox_inventory:SetDurability(src, slotNum, newDurability)
                        
                        if Config.Debug then
                            print(string.format("^2[DEBUG] SetDurability result: %s^7", tostring(durOk)))
                        end
                    end
                    
                    break
                end
            end
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Đã nhận ' .. amount .. ' quả cam',
            type = 'success'
        })

        -- Xử lý nhận thêm vật phẩm đặc biệt the_hai_cam (nếu triggerOn = 'take_from_basket' hoặc 'both')
        handleSpecialCardDrop(src, amount, 'take_from_basket')
    end
end)

RegisterServerEvent("xn-fruitpicker:selloranges")
AddEventHandler("xn-fruitpicker:selloranges", function(amount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local paymentPerFruit = math.random(Config.MinPay, Config.MaxPay)
    
    if amount > 0 then
        -- Player.Functions.AddMoney("cash", paymentPerFruit * amount)
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Sold ' .. amount .. ' oranges for $' .. (paymentPerFruit * amount),
            type = 'success'
        })
    end
end)

AddEventHandler('ox_inventory:itemRemoved', function(playerId, itemName, itemCount, itemMetadata, slot)
    if itemName == 'fruit_basket' then
        TriggerClientEvent("xn-fruitpicker:removebasket", playerId)
    end
end)

-- Hook to detect basket transfer between inventories or players
exports.ox_inventory:registerHook('swapItems', function(payload)
    if Config.Debug then
        print("^2[DEBUG] swapItems hook triggered^7")
        print("^2[DEBUG] Payload:^7", json.encode(payload, {indent = true}))
    end
    
    local fromInventory = payload.fromInventory
    local toInventory = payload.toInventory
    local item = payload.fromSlot -- fromSlot is the item object itself
    local fromType = payload.fromType
    local toType = payload.toType
    local source = payload.source
    
    -- Check if moving fruit_basket FROM player inventory to anywhere else
    if item and item.name == 'fruit_basket' and fromType == 'player' and fromInventory ~= toInventory then
        local playerId = tonumber(source) or tonumber(fromInventory)
        
        if playerId then
            if Config.Debug then
                print(string.format("^3[DEBUG] Basket being transferred from player %s to %s (type: %s) - Cancelling job^7", tostring(playerId), tostring(toInventory), tostring(toType)))
            end
            
            -- Cancel the fruit picking job immediately
            TriggerClientEvent("xn-fruitpicker:removebasket", playerId)
        end
    end
    
    return true -- Allow the swap to continue
end, {
    print = Config.Debug,
    itemFilter = {
        fruit_basket = true
    }
})
