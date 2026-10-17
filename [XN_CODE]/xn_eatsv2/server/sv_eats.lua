local ESX = nil
local QBCore = nil

-- Framework detection
local function InitializeFramework()
    -- Check for ESX
    if GetResourceState(Config.ESXgetSharedObject) == 'started' then
        ESX = exports[Config.ESXgetSharedObject]:getSharedObject()
        return 'esx'
    -- Check for QBCore
    elseif GetResourceState(Config.QBCoreGetCoreObject) == 'started' then
        QBCore = exports[Config.QBCoreGetCoreObject]:GetCoreObject()
        return 'qb'
    end
    return nil
end

-- Count on-duty employees for a specific job
local function GetOnDutyCount(jobName)
    local count = 0
    
    if QBCore then
        local players = QBCore.Functions.GetPlayers()
        for _, playerId in ipairs(players) do
            local Player = QBCore.Functions.GetPlayer(playerId)
            if Player and Player.PlayerData.job.name == jobName and Player.PlayerData.job.onduty then
                count = count + 1
            end
        end
    elseif ESX then
        local xPlayers = ESX.GetExtendedPlayers('job', jobName)
        for _, xPlayer in pairs(xPlayers) do
            -- ESX doesn't have onduty by default, count all with the job
            count = count + 1
        end
    end
    
    return count
end

-- Check if item can be used (job restriction check)
local function CanUseItem(itemName)
    local itemData = Config.Food[itemName] or Config.Drinks[itemName]
    if not itemData or not itemData.job then
        return true -- No job restriction
    end
    
    local minOnDuty = itemData.jobMinOnDuty or 2 -- Mặc định 2 nếu không config
    local onDutyCount = GetOnDutyCount(itemData.job)
    if onDutyCount >= minOnDuty then
        return false -- Có đủ nhân viên onduty, chặn sử dụng
    end
    
    return true
end

-- ESX item usage handler
local function RegisterESXItem(itemName, itemData)
    ESX.RegisterUsableItem(itemName, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        local item = xPlayer.getInventoryItem(itemName)
        if not item or item.count <= 0 then return end

        -- Check job restriction
        if not CanUseItem(itemName) then
            TriggerClientEvent("xn_eat:notify", source, "Xin lỗi không thể dùng vật phẩm này lúc này !", "error")
            return
        end

        -- Remove item
        xPlayer.removeInventoryItem(itemName, 1)

        -- Trigger client effects (stat update happens after animation)
        TriggerClientEvent("xn_eat:onEat", source, itemName)
    end)
end

-- QBCore item usage handler
local function RegisterQBCoreItem(itemName, itemData)
    QBCore.Functions.CreateUseableItem(itemName, function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end

        -- Check job restriction
        if not CanUseItem(itemName) then
            TriggerClientEvent("xn_eat:notify", source, "Xin lỗi không thể dùng vật phẩm này lúc này !", "error")
            return
        end

        -- Remove item
        Player.Functions.RemoveItem(itemName, 1)
        
        -- Update inventory
        TriggerClientEvent('inventory:client:ItemBox', source, 
            QBCore.Shared.Items[itemName], "remove")
        
        -- Trigger client effects (stat update happens after animation)
        TriggerClientEvent("xn_eat:onEat", source, itemName)
    end)
end

-- Apply stat effect after animation completes
RegisterNetEvent("xn_eat:applyEffect", function(itemName)
    local source = source
    local itemData = Config.Food[itemName] or Config.Drinks[itemName]
    if not itemData then return end

    if QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local effect = itemData.effect or "hunger"

        if effect == "stress" then
            -- Giảm stress
            local currentStress = Player.PlayerData.metadata.stress or 0
            local newStress = math.max(0, currentStress - itemData.amount)
            Player.Functions.SetMetaData("stress", newStress)
        else
            local currentVal = Player.PlayerData.metadata[effect] or 0
            local newVal = math.min(100, currentVal + itemData.amount)

            Player.Functions.SetMetaData(effect, newVal)

            -- Tăng metadata phụ: ăn -> poop, uống -> pee
            if effect == "hunger" and itemData.poopAmount then
                local currentPoop = Player.PlayerData.metadata.poop or 0
                local newPoop = math.min(100, currentPoop + itemData.poopAmount)
                Player.Functions.SetMetaData("poop", newPoop)
            elseif effect == "thirst" and itemData.peeAmount then
                local currentPee = Player.PlayerData.metadata.pee or 0
                local newPee = math.min(100, currentPee + itemData.peeAmount)
                Player.Functions.SetMetaData("pee", newPee)
            end

            local hunger = (effect == "hunger") and newVal or (Player.PlayerData.metadata.hunger or 0)
            local thirst = (effect == "thirst") and newVal or (Player.PlayerData.metadata.thirst or 0)
            TriggerClientEvent(Config.QBUpdateNeeds, source, hunger, thirst)
        end
    elseif ESX then
        TriggerClientEvent("esx_status:add", source, itemData.effect, itemData.amount * 10000)
    end
end)

-- Main initialization
CreateThread(function()
    local framework = InitializeFramework()
    if not framework then
        print('^1[ERROR] No supported framework (ESX/QBCore) detected!^7')
        return
    end

    -- Register all food items
    for itemName, itemData in pairs(Config.Food) do
        if framework == 'esx' then
            RegisterESXItem(itemName, itemData)
        else -- QBCore
            RegisterQBCoreItem(itemName, itemData)
        end
    end

    -- Register all drink items
    for itemName, itemData in pairs(Config.Drinks) do
        if framework == 'esx' then
            RegisterESXItem(itemName, itemData)
        else -- QBCore
            RegisterQBCoreItem(itemName, itemData)
        end
    end
end)