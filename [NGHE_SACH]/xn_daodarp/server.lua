local QBCore = exports['qb-core']:GetCoreObject()

-- Helper function to verify player job (fallback definition)
local function VerifyPlayerJob(source)
    -- By default return true. You can customize this check if a specific job is required.
    return true
end

local playerActions = {}

-- Helper to start an action
local function StartPlayerAction(src, action, duration, metadata)
    playerActions[src] = {
        action = action,
        startTime = GetGameTimer(),
        duration = duration,
        metadata = metadata or {},
        verified = false
    }
end

-- Helper to clear action
local function ClearPlayerAction(src)
    playerActions[src] = nil
end

RegisterNetEvent('xn_daodarp:startProcessing', function()
    local src = source
    StartPlayerAction(src, 'processing', 4200)
end)

RegisterNetEvent('xn_daodarp:cancelProcessing', function()
    local src = source
    ClearPlayerAction(src)
end)

RegisterNetEvent('xn_daoda:startSmelting', function(subAction, duration, gemItem)
    local src = source
    StartPlayerAction(src, 'smelting', duration, { subAction = subAction, gemItem = gemItem })
end)

RegisterNetEvent('xn_daoda:cancelSmelting', function()
    local src = source
    ClearPlayerAction(src)
end)

-- Server event to give reward
RegisterNetEvent('xn_daodarp:giveReward', function()
    local src = source
    local state = playerActions[src]
    
    if not state or state.action ~= 'processing' then
        return
    end
    
    local elapsed = GetGameTimer() - state.startTime
    if elapsed < (state.duration - 500) then
        return
    end
    
    -- Clear state immediately to prevent double reward
    playerActions[src] = nil
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Give reward item
    local success = exports.ox_inventory:CanCarryItem(src, Config.RewardItem, Config.RewardAmount)
    
    if success then
        exports.ox_inventory:AddItem(src, Config.RewardItem, Config.RewardAmount)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Thành công',
            description = 'Bạn đã nhận được ' .. Config.RewardAmount .. ' ' .. Config.ItemLabels[Config.RewardItem] .. '!',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Túi đồ đầy, không thể nhận thêm!',
            type = 'error'
        })
    end
end)

-- Server event to reduce drill durability
RegisterNetEvent('xn_daodarp:reduceDurability', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Get all drill items from inventory using ox_inventory Search
    local drillSlots = exports.ox_inventory:Search(src, 'slots', Config.RequiredItem)
    
    if drillSlots and #drillSlots > 0 then
        -- Get the first drill found
        local drillSlot = drillSlots[1]
        local currentDurability = drillSlot.metadata and drillSlot.metadata.durability or 100
        local newDurability = math.max(0, currentDurability - Config.DurabilityLoss)
        
        if newDurability <= 0 then
            -- Remove broken drill
            exports.ox_inventory:RemoveItem(src, Config.RequiredItem, 1, drillSlot.metadata, drillSlot.slot)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Thông báo',
                description = 'Máy khoan đã hỏng!',
                type = 'error'
            })
        else
            -- Update durability using the proper ox_inventory function
            exports.ox_inventory:SetDurability(src, drillSlot.slot, newDurability)
            
            -- Notify player about durability status
            if newDurability <= 20 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Cảnh báo',
                    description = 'Máy khoan sắp hỏng! Độ bền: ' .. math.floor(newDurability) .. '%',
                    type = 'warning'
                })
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Thông báo',
                    description = 'Độ bền máy khoan: ' .. math.floor(newDurability) .. '%',
                    type = 'inform'
                })
            end
        end
    else
        -- No drill found in inventory
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Không tìm thấy máy khoan trong túi đồ!',
            type = 'error'
        })
    end
end)

-- Command to give drill (for testing/admin)
QBCore.Commands.Add('givedrillrock', 'Give rock drill (Admin Only)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin (you can modify this based on your permission system)
    if Player.PlayerData.job.name == 'admin' or QBCore.Functions.HasPermission(src, 'admin') then
        local metadata = {
            durability = 100,
            description = 'Máy khoan đá - Độ bền: 100%',
            type = 'drill'
        }
        
        local success = exports.ox_inventory:AddItem(src, Config.RequiredItem, 1, metadata)
        
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Thành công',
                description = 'Bạn đã nhận được máy khoan đá!',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lỗi',
                description = 'Túi đồ đầy!',
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Bạn không có quyền sử dụng lệnh này!',
            type = 'error'
        })
    end
end, 'admin')

-- Command to give stones (for testing/admin)
QBCore.Commands.Add('givestones', 'Give stones (Admin Only)', {{name = 'amount', help = 'Amount of stones'}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = tonumber(args[1]) or 1
    
    if not Player then return end
    
    -- Check if player is admin
    if Player.PlayerData.job.name == 'admin' or QBCore.Functions.HasPermission(src, 'admin') then
        local success = exports.ox_inventory:AddItem(src, Config.RewardItem, amount)
        
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Thành công',
                description = 'Bạn đã nhận được ' .. amount .. ' ' .. Config.ItemLabels[Config.RewardItem] .. '!',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lỗi',
                description = 'Túi đồ đầy!',
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Bạn không có quyền sử dụng lệnh này!',
            type = 'error'
        })
    end
end, 'admin')

-- Function to check if player has required item (server-side verification)
function HasRequiredItem(src)
    -- Use ox_inventory Search function to find drill items
    local drillSlots = exports.ox_inventory:Search(src, 'slots', Config.RequiredItem)
    
    if drillSlots and #drillSlots > 0 then
        -- Check if any drill has durability > 0
        for _, drillSlot in pairs(drillSlots) do
            local durability = drillSlot.metadata and drillSlot.metadata.durability or 100
            if durability > 0 then
                return true
            end
        end
    end
    
    return false
end

-- Export function for other resources
exports('HasRequiredItem', HasRequiredItem)



-- Check if player has stones
RegisterNetEvent('xn_daoda:checkStones')
AddEventHandler('xn_daoda:checkStones', function()
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    
    -- Verify job before processing
    if not VerifyPlayerJob(source) then
        TriggerClientEvent('xn_daoda:stonesCheck', source, false, Config.SmeltingText.noJob)
        return
    end
    
    local hasStones = exports.ox_inventory:GetItemCount(source, Config.Smelting.requiredItem) >= Config.Smelting.requiredAmount
    
    if hasStones then
        TriggerClientEvent('xn_daoda:stonesCheck', source, true, nil)
    else
        TriggerClientEvent('xn_daoda:stonesCheck', source, false, Config.SmeltingText.noStones)
    end
end)

-- Check if player has gem
RegisterNetEvent('xn_daoda:checkGem')
AddEventHandler('xn_daoda:checkGem', function(gemItem)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    
    -- Verify job before processing
    if not VerifyPlayerJob(source) then
        TriggerClientEvent('xn_daoda:gemCheck', source, false, gemItem)
        return
    end
    
    local hasGem = exports.ox_inventory:GetItemCount(source, gemItem) >= 1
    
    TriggerClientEvent('xn_daoda:gemCheck', source, hasGem, gemItem)
end)

-- Remove stones from inventory
RegisterNetEvent('xn_daoda:removeStones')
AddEventHandler('xn_daoda:removeStones', function()
    local src = source
    local state = playerActions[src]
    if not state or state.action ~= 'smelting' or state.metadata.subAction ~= 'stone' then
        return
    end
    
    local elapsed = GetGameTimer() - state.startTime
    if elapsed < (state.duration - 500) then
        return
    end
    
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local hasStones = exports.ox_inventory:GetItemCount(src, Config.Smelting.requiredItem) >= Config.Smelting.requiredAmount
    if not hasStones then
        return
    end
    
    exports.ox_inventory:RemoveItem(src, Config.Smelting.requiredItem, Config.Smelting.requiredAmount)
    state.verified = true
end)

-- Remove gem from inventory
RegisterNetEvent('xn_daoda:removeGem')
AddEventHandler('xn_daoda:removeGem', function(gemItem)
    local src = source
    local state = playerActions[src]
    if not state or state.action ~= 'smelting' or state.metadata.subAction ~= 'gem' or state.metadata.gemItem ~= gemItem then
        return
    end
    
    local elapsed = GetGameTimer() - state.startTime
    if elapsed < (state.duration - 500) then
        return
    end
    
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local hasGem = exports.ox_inventory:GetItemCount(src, gemItem) >= 1
    if not hasGem then
        return
    end
    
    exports.ox_inventory:RemoveItem(src, gemItem, 1)
    state.verified = true
end)

-- Give reward to player
RegisterNetEvent('xn_daoda:giveReward')
AddEventHandler('xn_daoda:giveReward', function(item, amount)
    local src = source
    local state = playerActions[src]
    if not state or state.action ~= 'smelting' or not state.verified then
        return
    end
    
    -- Validate reward item
    local isValidReward = false
    if state.metadata.subAction == 'stone' then
        for _, reward in ipairs(Config.SmeltingRewards) do
            if reward.item == item then
                isValidReward = true
                break
            end
        end
    elseif state.metadata.subAction == 'gem' then
        for _, gem in ipairs(Config.GemSmelting.gems) do
            if gem.item == state.metadata.gemItem then
                for _, reward in ipairs(gem.rewards) do
                    if reward.item == item then
                        isValidReward = true
                        break
                    end
                end
                break
            end
        end
    end
    
    if not isValidReward then
        playerActions[src] = nil
        return
    end
    
    -- Reset state immediately to prevent double reward
    playerActions[src] = nil
    
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    if exports.ox_inventory:CanCarryItem(src, item, amount or 1) then
        exports.ox_inventory:AddItem(src, item, amount or 1)
    else
        TriggerClientEvent('QBCore:Notify', src, "kho của bạn đã đầy", 'error')
    end
end)

-- Server event to buy drill from NPC Shop
RegisterNetEvent('xn_daodarp:buyDrill', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Verify player distance to NPC shop on the server side
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local npcCoords = Config.ShopNPC.coords
    
    local distance = #(playerCoords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))
    if distance > 10.0 then
        -- Too far, possible exploit attempt
        return
    end
    
    local price = Config.ShopNPC.price
    local deductedFrom = nil
    
    -- Try deducting money: cash first, then bank
    if Player.Functions.RemoveMoney('cash', price, "buy-drill-rock") then
        deductedFrom = 'cash'
    elseif Player.Functions.RemoveMoney('bank', price, "buy-drill-rock") then
        deductedFrom = 'bank'
    end
    
    if deductedFrom then
        local metadata = {
            durability = 100,
            description = 'Máy khoan đá - Độ bền: 100%',
            type = 'drill'
        }
        
        local success = exports.ox_inventory:AddItem(src, Config.RequiredItem, 1, metadata)
        
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Thành công',
                description = 'Bạn đã mua máy khoan đá với giá $' .. price .. ' (' .. (deductedFrom == 'cash' and 'Tiền mặt' or 'Ngân hàng') .. ')!',
                type = 'success'
            })
        else
            -- Refund money if inventory is full
            Player.Functions.AddMoney(deductedFrom, price, "refund-drill-rock")
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lỗi',
                description = 'Túi đồ đầy, không thể nhận thêm! Đã hoàn trả lại tiền.',
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Bạn không đủ tiền! Cần $' .. price .. ' tiền mặt hoặc ngân hàng.',
            type = 'error'
        })
    end
end)