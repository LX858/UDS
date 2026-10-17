local QBCore = exports['qb-core']:GetCoreObject()
local Cocounts = {} -- Cocounts[playerID][tree]
local Time = {} -- Time[playerID][tree]

local function ensureTreeState(src, tree)
    if not Cocounts[src] then Cocounts[src] = {} end
    if not Time[src] then Time[src] = {} end
    if not Cocounts[src][tree] then Cocounts[src][tree] = 0 end
    if not Time[src][tree] then Time[src][tree] = 0 end
end

local function canPickTreeNow(src, tree)
    ensureTreeState(src, tree)

    if Cocounts[src][tree] == Config.MaxLimit and Time[src][tree] ~= 0 and (os.time() >= Time[src][tree]) then
        Cocounts[src][tree] = 0
        Time[src][tree] = 0
    end

    if Cocounts[src][tree] < Config.MaxLimit then
        return true, 0
    end

    return false, math.max(0, Time[src][tree] - os.time())
end

-- Trừ 5% độ bền cái kéo đang dùng (theo slot), xoá đúng slot khi hết bền
local function reduceDurability(src)
    if not Config.ItemRequire then return end
    -- Lấy toàn bộ inventory, tìm slot kéo có durability cao nhất (cái đang "dùng")
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    if not inventory then return end

    local targetSlot = nil
    local targetDurability = nil

    for _, slot in pairs(inventory) do
        if slot.name == Config.ItemRequireName then
            local dur = (slot.metadata and slot.metadata.durability) or 100
            -- Ưu tiên slot có durability thấp nhất (đang dùng dở) nhưng > 0
            if targetSlot == nil or dur < targetDurability then
                targetSlot = slot.slot
                targetDurability = dur
            end
        end
    end

    if not targetSlot then return end

    local newDurability = targetDurability - 5

    if newDurability <= 0 then
        -- Xoá đúng slot cái kéo này
        exports.ox_inventory:RemoveItem(src, Config.ItemRequireName, 1, nil, targetSlot)
        TriggerClientEvent('QBCore:Notify', src, '✂️ Kéo của bạn đã hỏng!', 'error')
    else
        -- Cập nhật durability cho đúng slot đó
        exports.ox_inventory:SetMetadata(src, targetSlot, { durability = newDurability })
        if newDurability <= 20 then
            TriggerClientEvent('QBCore:Notify', src, '⚠️ Kéo sắp hỏng! Độ bền còn ' .. math.floor(newDurability) .. '%', 'error')
        end
    end
end

exports['monitors']:RegisterProtectedEvent('xx_coco:server:addCoconut', function(src, tree, amount, shouldRemoveItem)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not tree or not Config.SpawnTrees[tree] then return end
    
    local canPick, remaining = canPickTreeNow(src, tree)
    if not canPick then
        TriggerClientEvent('QBCore:Notify', src, Languages.Wait .. remaining .. Languages.Second, 'error')
        return
    end
    
    -- Kiểm tra trúng Rare Drop
    local isRare = false
    if Config.RareDrops and Config.RareDrops.enabled then
        local randomChance = math.random(1, 100)
        if randomChance <= Config.RareDrops.rareChance then
            isRare = true
        end
    end
    
    -- Kiểm tra sức chứa cho vật phẩm thường (luôn nhận) và vật phẩm hiếm (nếu trúng)
    local canCarry = exports.ox_inventory:CanCarryItem(src, Config.RewardItemName, amount)
    if isRare then
        canCarry = canCarry and exports.ox_inventory:CanCarryItem(src, Config.RareDrops.rareItemName, Config.RareDrops.rareAmount)
    end
    
    if canCarry then
        if Cocounts[src][tree] + 1 <= Config.MaxLimit then
            Cocounts[src][tree] = Cocounts[src][tree] + 1
            if Cocounts[src][tree] == Config.MaxLimit then
                Time[src][tree] = os.time() + Config.TimeCanPick
            end
            
            -- Thêm dừa thường vào inventory
            exports.ox_inventory:AddItem(src, Config.RewardItemName, amount)
            TriggerClientEvent('QBCore:Notify', src, 'Bạn đã hái được ' .. amount .. ' trái dừa', 'success')
            
            -- Thêm vật phẩm hiếm vào inventory nếu trúng
            if isRare then
                exports.ox_inventory:AddItem(src, Config.RareDrops.rareItemName, Config.RareDrops.rareAmount)
                TriggerClientEvent('QBCore:Notify', src, 'Bạn may mắn hái được ' .. Config.RareDrops.rareItemLabel .. '!', 'success')
            end
            
            -- Trừ độ bền kéo
            reduceDurability(src)
            
            -- Hệ thống phần thưởng đặc biệt
            if Config.Event and Config.Event.enabled then
                if math.random(1, 100) <= Config.Event.chance then
                    local roll = math.random(1, 100)
                    local cumulativeChance = 0
                    for _, reward in ipairs(Config.Event.rewards) do
                        cumulativeChance = cumulativeChance + reward.chance
                        if roll <= cumulativeChance then
                            exports.ox_inventory:AddItem(src, reward.item, 1)
                            break
                        end
                    end
                end
            end
        else
            return
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'kho của bạn quá đầy để hái dừa!', 'error')
    end
end)

QBCore.Functions.CreateCallback('xx_coco:checkCanPick', function(source, cb, tree)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false) 
        return 
    end
    
    -- Kiểm tra nếu player đang on duty với job police, ambulance, hoặc cardealer
    if Player.PlayerData.job and Player.PlayerData.job.name then
        local blockedJobs = {
            ['police'] = true,
            ['ambulance'] = true,
            ['cardealer'] = true
        }
        
        -- Chỉ chặn nếu player có job trong danh sách VÀ đang on-duty
        if blockedJobs[Player.PlayerData.job.name] and Player.PlayerData.job.onduty then
            TriggerClientEvent('QBCore:Notify', source, 'Bạn đang làm việc, không thể hái dừa!', 'error')
            cb(false)
            return
        end
    end
    
    -- Check if player has required item
    if Config.ItemRequire then
        local hasItem = exports.ox_inventory:GetItem(source, Config.ItemRequireName, nil, true)
        if not hasItem or hasItem < 1 then
            TriggerClientEvent('QBCore:Notify', source, 'Bạn cần có ' .. Config.ItemRequireName .. ' để hái dừa!', 'error')
            cb(false)
            return
        end
    end
    
    local canPick, remaining = canPickTreeNow(source, tree)

    if canPick then
        cb(true)
    else
        TriggerClientEvent('QBCore:Notify', source, Languages.Wait .. remaining .. Languages.Second, 'error')
        cb(false)
    end
end)

-- NPC Shop Server Events
RegisterServerEvent('xx_coco:server:buyItem')
AddEventHandler('xx_coco:server:buyItem', function(itemName, quantity, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local totalPrice = price * quantity
    local playerMoney = Player.PlayerData.money.cash
    
    -- Check if player has enough money
    if playerMoney >= totalPrice then
        -- Remove money
        Player.Functions.RemoveMoney('cash', totalPrice, 'npc-shop-purchase')
        
        -- Add item to inventory with metadata
        exports.ox_inventory:AddItem(src, itemName, quantity, {durability = 100})
        
        TriggerClientEvent('QBCore:Notify', src, 'Bạn đã mua ' .. quantity .. 'x ' .. itemName .. ' với giá $' .. totalPrice, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Languages.NotEnoughMoney, 'error')
    end
end)
