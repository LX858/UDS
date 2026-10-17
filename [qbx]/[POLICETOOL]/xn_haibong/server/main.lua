local ox_inventory = exports.ox_inventory

local function reduceDurability(src, itemName)
    if not itemName or itemName == false then return end
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    if not inventory then return end

    local targetSlot = nil
    local targetDurability = nil

    for _, slot in pairs(inventory) do
        if slot.name == itemName then
            local dur = (slot.metadata and slot.metadata.durability) or 100
            -- Ưu tiên slot có durability thấp nhất (đang dùng dở) nhưng > 0
            if targetSlot == nil or dur < targetDurability then
                targetSlot = slot.slot
                targetDurability = dur
            end
        end
    end

    if not targetSlot then return end

    local newDurability = targetDurability - 2

    local isScissors = false
    if Config.Farms then
        for _, farm in pairs(Config.Farms) do
            if farm.Scissors == itemName then
                isScissors = true
                break
            end
        end
    elseif itemName == Config.Scissors then
        isScissors = true
    end

    local itemLabel = itemName == 'may_xay' and 'Máy xay' or (isScissors and 'Kéo' or itemName)
    local itemIcon = itemName == 'may_xay' and '⚙️' or (isScissors and '✂️' or '🔧')

    if newDurability <= 0 then
        -- Xoá đúng slot cái kéo/máy xay này
        exports.ox_inventory:RemoveItem(src, itemName, 1, nil, targetSlot)
        TriggerClientEvent('QBCore:Notify', src, itemIcon .. ' ' .. itemLabel .. ' của bạn đã hỏng!', 'error')
    else
        -- Cập nhật durability cho đúng slot đó
        exports.ox_inventory:SetMetadata(src, targetSlot, { durability = newDurability })
        if newDurability <= 20 then
            TriggerClientEvent('QBCore:Notify', src, '⚠️ ' .. itemLabel .. ' sắp hỏng! Độ bền còn ' .. math.floor(newDurability) .. '%', 'error')
        end
    end
end

local function GetFarmConfigServer(farmId, playerCoords)
    if farmId and Config.Farms and Config.Farms[farmId] then
        return Config.Farms[farmId], farmId
    end

    if Config.Farms and playerCoords then
        local closestFarm = nil
        local minDistance = 999999.0

        for id, farm in pairs(Config.Farms) do
            if farm.Locations then
                for _, loc in ipairs(farm.Locations) do
                    local dist = #(playerCoords - loc)
                    if dist < minDistance then
                        minDistance = dist
                        closestFarm = id
                    end
                end
            end
            if farm.ProcessLocation then
                local dist = #(playerCoords - vector3(farm.ProcessLocation.x, farm.ProcessLocation.y, farm.ProcessLocation.z))
                if dist < minDistance then
                    minDistance = dist
                    closestFarm = id
                end
            end
        end

        if closestFarm then
            return Config.Farms[closestFarm], closestFarm
        end
    end

    return Config, 'haibong'
end

-- Register usable items for scissors
local registeredScissors = {}
local function RegisterScissorsItems()
    local farms = Config.Farms or { ['default'] = Config }
    for _, farm in pairs(farms) do
        local sc = farm.Scissors
        if sc and sc ~= false and not registeredScissors[sc] then
            registeredScissors[sc] = true
            exports.qbx_core:CreateUseableItem(sc, function(source, item)
                local src = source
                TriggerClientEvent('1307_HaiCan:client:UseScissors', src)
            end)
        end
    end
end
RegisterScissorsItems()

local weedCooldowns = {}

AddEventHandler('playerDropped', function()
    local src = source
    weedCooldowns[src] = nil
end)

RegisterNetEvent('1307_HaiCan:server:RewardWeed', function(clientFarmId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local farmConfig, farmId = GetFarmConfigServer(clientFarmId, playerCoords)

    -- Check Job
    if farmConfig.Job and Player.PlayerData.job.name ~= farmConfig.Job then
        return exports.qbx_core:Notify(src, "Bạn không có quyền thực hiện công việc này!", "error")
    end

    local pickTime = farmConfig.PickTime or 5
    local currentTime = GetGameTimer()
    if weedCooldowns[src] and (currentTime - weedCooldowns[src]) < ((pickTime - 2) * 1000) then
        return exports.qbx_core:Notify(src, "Thao tác quá nhanh, vui lòng đợi!", "error")
    end

    -- Distance check
    local locations = farmConfig.Locations or farmConfig.WeedLocations or {}
    local nearLocation = false
    for _, loc in ipairs(locations) do
        if #(playerCoords - loc) < 10.0 then
            nearLocation = true
            break
        end
    end

    if not nearLocation then
        return exports.qbx_core:Notify(src, "Bạn ở quá xa khu vực thu hoạch!", "error")
    end

    -- Check Scissors if farm requires it
    local scissorsItem = farmConfig.Scissors
    if scissorsItem and scissorsItem ~= false then
        local hasScissors = ox_inventory:GetItemCount(src, scissorsItem)
        if hasScissors <= 0 then
            return exports.qbx_core:Notify(src, "Bạn không có kéo để thu hoạch!", "error")
        end
        reduceDurability(src, scissorsItem)
    end

    local weedItem = farmConfig.Weed or 'bonggon'
    local amount = farmConfig.RewardWeed or 1
    if not exports.ox_inventory:CanCarryItem(src, weedItem, amount) then
        return exports.qbx_core:Notify(src, "Kho đồ đang quá kg rồi 😔", "error")
    end

    weedCooldowns[src] = currentTime
    exports.ox_inventory:AddItem(src, weedItem, amount)
end)

RegisterNetEvent('1307_HaiCan:server:RewardJoint', function(clientFarmId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local farmConfig, farmId = GetFarmConfigServer(clientFarmId, playerCoords)

    -- Check Job
    if farmConfig.Job and Player.PlayerData.job.name ~= farmConfig.Job then
        return exports.qbx_core:Notify(src, "Bạn không có quyền thực hiện công việc này!", "error")
    end

    local weedItem = farmConfig.Weed or 'bonggon'
    local amountToProcess = farmConfig.AmountToProcess or 2
    local rewardJoint = farmConfig.RewardJoint or 1
    local jointItem = farmConfig.Joint or 'bonggon'

    -- Check distance to ProcessLocation if defined
    if farmConfig.ProcessLocation then
        local procCoords = vector3(farmConfig.ProcessLocation.x, farmConfig.ProcessLocation.y, farmConfig.ProcessLocation.z)
        if #(playerCoords - procCoords) > 10.0 then
            return exports.qbx_core:Notify(src, "Bạn ở quá xa khu vực chế biến!", "error")
        end
    end

    local count = ox_inventory:GetItemCount(src, weedItem)
    if count < amountToProcess then
        return TriggerClientEvent('QBCore:Notify', src, 'Bạn không đủ nguyên liệu thô để chế biến!', 'error')
    end

    local hasMayXay = ox_inventory:GetItemCount(src, 'may_xay')
    if hasMayXay <= 0 then
        return TriggerClientEvent('QBCore:Notify', src, 'Bạn không có máy xay!', 'error')
    end

    ox_inventory:RemoveItem(src, weedItem, amountToProcess)
    reduceDurability(src, 'may_xay')
    ox_inventory:AddItem(src, jointItem, rewardJoint)
    TriggerClientEvent('QBCore:Notify', src, 'Bạn đã chế biến thành công!', 'success')
end)

RegisterNetEvent('1307_HaiCan:sv:NhanDieuCan', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local jointItem = Config.Joint or 'bonggon'
    local count = ox_inventory:GetItemCount(src, jointItem)
    if count > 0 then
        ox_inventory:RemoveItem(src, jointItem, 1)
        ox_inventory:AddItem(src, 'joint', 1)
        TriggerClientEvent('QBCore:Notify', src, 'Bạn đã trao đổi thành công', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không đủ nguyên liệu để trao đổi', 'error')
    end
end)