local QBCore = exports["qb-core"]:GetCoreObject()
local ox = exports.ox_inventory

-- ==================== HỆ THỐNG LẤY NƯỚC ====================
QBCore.Functions.CreateUseableItem('xo_rong', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    TriggerClientEvent('xn_farming:useEmptyBucket', source)
end)

QBCore.Functions.CreateCallback('xn_farming:checkEmptyBucket', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false)
        return 
    end
    
    local emptyBucket = Player.Functions.GetItemByName('xo_rong')
    cb(emptyBucket and emptyBucket.amount > 0)
end)

QBCore.Functions.CreateCallback('xn_farming:getWater', function(source, cb)
    local ped = GetPlayerPed(source)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        cb(false)
        return
    end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false)
        return 
    end
    
    local emptyBucket = Player.Functions.GetItemByName('xo_rong')
    if not emptyBucket or emptyBucket.amount <= 0 then
        cb(false)
        return
    end
    
    if Player.Functions.RemoveItem('xo_rong', 1) then
        if Player.Functions.AddItem('xo_co_nuoc', 1) then
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['xo_co_nuoc'], "add")
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['xo_rong'], "remove")
            cb(true)
        else
            Player.Functions.AddItem('xo_rong', 1)
            cb(false)
        end
    else
        cb(false)
    end
end)

-- ==================== CỬA HÀNG NÔNG NGHIỆP ====================
QBCore.Functions.CreateCallback('xn_farming:buyItem', function(source, cb, item, quantity, totalPrice)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false, 'Không tìm thấy thông tin người chơi')
        return 
    end
    
    quantity = tonumber(quantity) or 1
    if quantity < 1 or quantity > 99 then
        cb(false, 'Số lượng không hợp lệ (1 - 99)!')
        return
    end

    local validItem = false
    local itemLabel = ''
    local unitPrice = 0

    if FarmShop and FarmShop.Items then
        for _, shopItem in ipairs(FarmShop.Items) do
            if shopItem.item == item then
                validItem = true
                itemLabel = shopItem.label
                unitPrice = shopItem.price
                break
            end
        end
    end

    if not validItem and PoppyShop and PoppyShop.Enabled ~= false and PoppyShop.Items then
        for _, shopItem in ipairs(PoppyShop.Items) do
            if shopItem.item == item then
                validItem = true
                itemLabel = shopItem.label
                unitPrice = shopItem.price
                break
            end
        end
    end
    
    if not validItem then
        cb(false, 'Vật phẩm không hợp lệ')
        return
    end
    
    local calcTotalPrice = unitPrice * quantity
    local playerMoney = Player.PlayerData.money and Player.PlayerData.money.cash or 0
    if playerMoney < calcTotalPrice then
        cb(false, string.format('Bạn không đủ tiền! Cần $%d, bạn có $%d', calcTotalPrice, playerMoney))
        return
    end
    
    if Player.Functions.RemoveMoney('cash', calcTotalPrice) then
        local added = false
        if ox and ox.AddItem then
            added = ox:AddItem(source, item, quantity)
        else
            added = Player.Functions.AddItem(item, quantity)
        end

        if added then
            if QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[item] then
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "add")
            end
            
            if Config.Debug then
                print(string.format("Player %s bought %dx %s for $%d", Player.PlayerData.name, quantity, itemLabel, calcTotalPrice))
            end
            
            cb(true, string.format('Đã mua %dx %s với giá $%d', quantity, itemLabel, calcTotalPrice))
        else
            Player.Functions.AddMoney('cash', calcTotalPrice)
            cb(false, 'Không thể thêm vật phẩm vào túi đồ')
        end
    else
        cb(false, 'Giao dịch thất bại')
    end
end)

-- Event handler cập nhật số lượng cây trồng
RegisterNetEvent('xx_farming:updatePlantCount')
AddEventHandler('xx_farming:updatePlantCount', function(playerId)
    if playerId then
        getPlayerPlantCount(playerId)
    end
end)

-- ==================== HỆ THỐNG TRỘM CÂY & CHÓ BẢO VỆ ====================
function CanStealPlant(thiefPid, plantId)
    plantId = tonumber(plantId)
    local plant = Plants[plantId]
    if not plant then
        return false
    end
    
    local plantOwner = plant.owner
    if thiefPid == plantOwner then
        return false
    end
    
    local plantCoords = type(plant.coords) == "string" and json.decode(plant.coords) or plant.coords
    local zoneId = GetZoneIdFromCoords(plantCoords)
    
    if zoneId then
        local hasPermission = CheckFarmPermission(thiefPid, zoneId)
        if hasPermission then
            return false
        end
    end
    
    local growth = GetServerPlantGrowth(plant)
    if growth < 99 then
        return false
    end

    return true
end

function LogTheft(thiefPid, targetPid, zoneId, plantType, amount, success, wasBitten)
    MySQL.insert([[
        INSERT INTO farm_theft_logs (thief_pid, target_pid, zone_id, plant_type, amount_stolen, success, was_bitten) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { thiefPid, targetPid, zoneId, plantType, amount or 0, success and 1 or 0, wasBitten and 1 or 0 })
end

-- ==================== SỬ DỤNG HẠT GIỐNG ====================
QBCore.Functions.CreateUseableItem(Melons.FemaleSeedItem, function(source)
    TriggerClientEvent('xx_farming:client:useitem', source)
end)

if CropTypes then
    for cropType, cropConf in pairs(CropTypes) do
        if cropConf.FemaleSeedItem and cropConf.FemaleSeedItem ~= Melons.FemaleSeedItem then
            local seedItem = cropConf.FemaleSeedItem
            QBCore.Functions.CreateUseableItem(seedItem, function(source)
                TriggerClientEvent('xx_farming:client:useitem', source)
            end)
        end
    end
end

-- ==================== TRỒNG CÂY ====================
RegisterNetEvent('xx_farming:plantSeed')
AddEventHandler('xx_farming:plantSeed', function(coords, zoneId, cropType)
    local src = source
    cropType = cropType or 'rice'
    if not src then return end

    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể trồng cây khi đang ngồi trên xe!', 'error')
        return
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    local playerId = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    if not playerId then return end

    if not zoneId then
        TriggerClientEvent('QBCore:Notify', src, 'Lỗi: Không thể xác định zone!', 'error')
        return
    end
    
    local hasPermission, permissionType = CheckFarmPermission(playerId, zoneId)
    if not hasPermission then
        TriggerClientEvent('QBCore:Notify', src, string.format('Bạn cần thuê ruộng #%d hoặc được chia sẻ quyền trước khi trồng cây!', zoneId), 'error')
        return
    end

    local plantCropConfig = (CropTypes and CropTypes[cropType]) or Melons
    local canPlant, currentCount, maxLimit = canPlantMore(playerId, cropType, zoneId)
    if not canPlant then
        TriggerClientEvent('QBCore:Notify', src, string.format('Bạn đã đạt giới hạn trồng tối đa %d cây! (Đang có %d cây)', maxLimit, currentCount), 'error')
        return
    end

    local zoneConf = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId]
    if zoneConf and zoneConf.cropTypes then
        local allowed = false
        for _, ct in ipairs(zoneConf.cropTypes) do
            if ct == cropType then allowed = true; break end
        end
        if not allowed then
            TriggerClientEvent('QBCore:Notify', src, string.format('Ruộng #%d không cho phép trồng loại cây này!', zoneId), 'error')
            return
        end
    end

    local timestamp = os.time()
    if ox:RemoveItem(src, plantCropConfig.FemaleSeedItem, 1) then
        local jsonCoords = json.encode(coords)
        MySQL.insert([[
            INSERT INTO tomato_db (coords, timestamp, plantgender, water, fertilizer, owner, zone_id, crop_type, health) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], { jsonCoords, timestamp, 0, 60, 60, playerId, zoneId, cropType, 100 }, function(insertId)
            if insertId then
                local newPlant = {
                    id = insertId,
                    coords = jsonCoords,
                    timestamp = timestamp,
                    plantgender = 0,
                    water = 60,
                    fertilizer = 60,
                    owner = playerId,
                    zone_id = zoneId,
                    crop_type = cropType,
                    health = 100
                }
                Plants[insertId] = newPlant
                PlayerPlantCounts[playerId] = (PlayerPlantCounts[playerId] or 0) + 1
                BroadcastZonePlantEvent(zoneId, 2, newPlant)
            else
                FarmDebugPrint('Error: Failed to insert new plant into database for playerId: ', playerId)
            end
        end)
    else    
        TriggerClientEvent('QBCore:Notify', src, 'Không đủ hạt giống để trồng cây.', 'error')
    end
end)

-- ==================== LẤY DANH SÁCH CÂY (100% RAM Lookup) ====================
lib.callback.register('xx_farming:getPlants', function(source, zoneId)
    local plantList = {}
    zoneId = zoneId and tonumber(zoneId) or nil
    if zoneId then SubscribePlantZone(source, zoneId) end
    for _, plant in pairs(Plants) do
        if not zoneId or plant.zone_id == zoneId then
            plantList[#plantList + 1] = plant
        end
    end
    return plantList
end)

-- ==================== PHÁ CÂY ====================
lib.callback.register('xx_farming:removePlant', function(source, pId)
    local ped = GetPlayerPed(source)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return false
    end

    pId = tonumber(pId)
    local plant = Plants[pId]
    if not plant then return false end
    
    deletePlantFromMemory(pId)
    MySQL.update('DELETE FROM tomato_db WHERE id = ?', { pId })
    BroadcastZonePlantEvent(plant.zone_id, 4, pId)
    return true
end)

local function CheckHarvestEventReward(src)
    if Config.Event and Config.Event.enabled then
        local randomRoll = math.random(1, 100)
        if randomRoll <= Config.Event.chance then
            local roll = math.random(1, 100)
            local cumulativeChance = 0
            for _, reward in ipairs(Config.Event.rewards) do
                cumulativeChance = cumulativeChance + reward.chance
                if roll <= cumulativeChance then
                    if ox:AddItem(src, reward.item, 1) then
                        TriggerClientEvent('QBCore:Notify', src, 'Bạn nhận được phần thưởng đặc biệt: ' .. reward.item .. '!', 'success')
                    end
                    break
                end
            end
        end
    end
end

-- ==================== KIỂM TRA GANG KHU VỰC 13 ====================
local function GetGangName(playerData)
    local gang = playerData and playerData.gang
    local gangName = gang and gang.name
    if gangName == nil then return nil end

    gangName = string.lower(tostring(gangName)):gsub('%s+', '')
    if gangName == ''
        or gangName == 'none'
        or gangName == 'nogang'
        or gangName == 'no_gang'
        or gangName == 'unaffiliated'
        or gangName == 'civilian' then
        return nil
    end

    return gangName
end

local function HasMultipleGangsNearPlayer(src, radius)
    local sourcePed = GetPlayerPed(src)
    if sourcePed == 0 then return false end

    local sourceCoords = GetEntityCoords(sourcePed)
    local sourceBucket = GetPlayerRoutingBucket(src)
    local gangs = {}

    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        playerId = tonumber(playerId)
        if playerId then
            local playerPed = GetPlayerPed(playerId)
            if playerPed ~= 0 and GetPlayerRoutingBucket(playerId) == sourceBucket then
                local playerCoords = GetEntityCoords(playerPed)
                if #(sourceCoords - playerCoords) <= radius then
                    local player = QBCore.Functions.GetPlayer(playerId)
                    local gangName = GetGangName(player and player.PlayerData)
                    if gangName then
                        gangs[gangName] = true
                    end
                end
            end
        end
    end

    local gangCount = 0
    for _ in pairs(gangs) do
        gangCount = gangCount + 1
        if gangCount > 1 then
            return true
        end
    end

    return false
end

-- ==================== THU HOẠCH CÂY ====================
lib.callback.register('xx_farming:harvestPlant', function(source, pId)
    local src = source
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể thu hoạch khi đang ngồi trên xe!', 'error')
        return false
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end
    
    pId = tonumber(pId)
    local plant = Plants[pId]
    if not plant then return false end
    
    local playerId = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local plantCoords = type(plant.coords) == "string" and json.decode(plant.coords) or plant.coords
    local zoneId = GetZoneIdFromCoords(plantCoords)
    
    if zoneId then
        local hasPermission = CheckFarmPermission(playerId, zoneId)
        if not hasPermission then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền thu hoạch trên ruộng này hoặc thời gian thuê đã hết!', "error")
            return false
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Không thể xác định vị trí ruộng!', "error")
        return false
    end

    if zoneId == 13 and HasMultipleGangsNearPlayer(src, 100.0) then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể thu hoạch khi có nhiều gang trong khu vực!', 'error')
        return false
    end
    
    local waterPlant = tonumber(plant.water) or 0
    local ferPlant = tonumber(plant.fertilizer) or 0
    local harvestCropConfig = (CropTypes and plant.crop_type and CropTypes[plant.crop_type]) or Melons

    local plantHealth = tonumber(plant.health) or 100
    local healthMultiplier = 1.0
    if plantHealth <= 5 then
        deletePlantFromMemory(pId)
        MySQL.update('DELETE FROM tomato_db WHERE id = ?', { pId })
        BroadcastZonePlantEvent(plant.zone_id, 4, pId)
        TriggerClientEvent('QBCore:Notify', src, 'Cây đã chết vì sâu bệnh, không thể thu hoạch!', 'error')
        return true
    elseif plantHealth <= 25 then
        healthMultiplier = 0.3
    elseif plantHealth <= 50 then
        healthMultiplier = 0.6
    elseif plantHealth <= 75 then
        healthMultiplier = 0.85
    end

    local zoneConf = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId]
    local harvestMult = (zoneConf and zoneConf.harvestMultiplier) or (zoneId == 13 and 1.2) or 1.0

    if plant.plantgender == 1 then
        local seedsAmount = math.random(harvestCropConfig.SeedsFromMale[1], harvestCropConfig.SeedsFromMale[2])
        if harvestMult and harvestMult ~= 1.0 then
            seedsAmount = math.max(1, math.floor(seedsAmount * harvestMult + 0.5))
        end
        if not exports.ox_inventory:CanCarryItem(src, harvestCropConfig.FemaleSeedItem, seedsAmount) then
            TriggerClientEvent('QBCore:Notify', src, 'Túi đồ của bạn quá nặng, không thể thu hoạch!', 'error')
            return false
        end
        if ox:AddItem(src, harvestCropConfig.FemaleSeedItem, seedsAmount) then
            deletePlantFromMemory(pId)
            MySQL.update('DELETE FROM tomato_db WHERE id = ?', { pId })
            BroadcastZonePlantEvent(plant.zone_id, 4, pId)
            CheckHarvestEventReward(src)
            return true
        end
        return false
    end
    
    local lowestStat = math.min(waterPlant, ferPlant, plantHealth)
    local isPoorQuality = lowestStat < 50
    local qualityText = ""
    if isPoorQuality then
        qualityText = ""
    elseif lowestStat >= 90 then
        qualityText = "high"
    elseif lowestStat >= 70 then
        qualityText = "medium"
    else
        qualityText = "low"
    end

    local maxYield = tonumber(harvestCropConfig.PerfectHarvestTotal) or 6
    local totalYield = maxYield

    if lowestStat < 90 then
        local steps = math.ceil((90 - lowestStat) / 10)
        local deductionPercent = steps * 0.20
        totalYield = maxYield * (1.0 - deductionPercent)
    end
    totalYield = math.max(0, math.floor(totalYield + 0.5))

    local amount = totalYield
    local isDoubleYield = false
    if harvestCropConfig.DoubleYieldChance and math.random(100) <= harvestCropConfig.DoubleYieldChance then
        local multiplier = harvestCropConfig.DoubleYieldMultiplier or 2
        amount = math.floor(amount * multiplier)
        isDoubleYield = true
    end

    if harvestMult and harvestMult ~= 1.0 and amount > 0 then
        amount = math.max(1, math.floor(amount * harvestMult + 0.5))
    end

    local itemsToGive = {}
    if amount > 0 then
        local parsedItems = {}
        local ratioSum = 0
        for _, entry in ipairs(harvestCropConfig.GiveDopeItem) do
            local itemName, ratio
            if type(entry) == 'table' then
                itemName = entry.item
                ratio    = math.max(0, tonumber(entry.ratio) or 1.0)
            else
                itemName = entry
                ratio    = 1.0
            end
            parsedItems[#parsedItems + 1] = { item = itemName, ratio = ratio, qty = 0 }
            ratioSum = ratioSum + ratio
        end

        if #parsedItems == 1 then
            parsedItems[1].qty = amount
        else
            if ratioSum <= 0 then ratioSum = #parsedItems end

            local assigned = 0
            for i = 1, #parsedItems do
                local rawQty = (amount * parsedItems[i].ratio) / ratioSum
                local qty = math.floor(rawQty + 0.5)
                if qty < 0 then qty = 0 end
                parsedItems[i].qty = qty
                assigned = assigned + qty
            end

            while assigned < amount do
                local pick = 1
                for i = 2, #parsedItems do
                    if parsedItems[i].ratio > parsedItems[pick].ratio then
                        pick = i
                    end
                end
                parsedItems[pick].qty = parsedItems[pick].qty + 1
                assigned = assigned + 1
            end

            while assigned > amount do
                local pick = nil
                for i = 1, #parsedItems do
                    if parsedItems[i].qty > 0 and (not pick or parsedItems[i].ratio < parsedItems[pick].ratio) then
                        pick = i
                    end
                end
                if not pick then break end
                parsedItems[pick].qty = parsedItems[pick].qty - 1
                assigned = assigned - 1
            end
        end

        for i = 1, #parsedItems do
            if parsedItems[i].qty > 0 then
                table.insert(itemsToGive, { item = parsedItems[i].item, qty = parsedItems[i].qty })
            end
        end

        for _, info in ipairs(itemsToGive) do
            if not exports.ox_inventory:CanCarryItem(src, info.item, info.qty) then
                TriggerClientEvent('QBCore:Notify', src, 'Túi đồ của bạn quá nặng, không thể thu hoạch!', 'error')
                return false
            end
        end
    end

    if amount > 0 then
        for _, info in ipairs(itemsToGive) do
            ox:AddItem(src, info.item, info.qty)
        end
        if isDoubleYield then
            local mult = harvestCropConfig.DoubleYieldMultiplier or 2
            TriggerClientEvent('QBCore:Notify', src, 'Bạn may mắn nhận được x' .. mult .. ' sản lượng thu hoạch!', 'success')
        end
    end

    deletePlantFromMemory(pId)
    MySQL.update('DELETE FROM tomato_db WHERE id = ?', { pId })
    BroadcastZonePlantEvent(plant.zone_id, 4, pId)
    
    if isPoorQuality then
        TriggerClientEvent('QBCore:Notify', src, 'Cây này không có trái', "primary")  
    elseif qualityText == "low" then
        TriggerClientEvent('QBCore:Notify', src, 'Thu hoạch được ít, cây chưa chăm tốt!', "primary")  
        CheckHarvestEventReward(src)
    elseif qualityText == "medium" then
        TriggerClientEvent('QBCore:Notify', src, 'Thu hoạch trung bình, cần chăm chút hơn nữa!', "primary")
        CheckHarvestEventReward(src)
    elseif qualityText == "high" then
        TriggerClientEvent('QBCore:Notify', src, 'Thu hoạch bội thu, trúng mùa!', "primary")
        CheckHarvestEventReward(src)
    end
    return true
end)

-- ==================== TƯỚI NƯỚC ====================
lib.callback.register('xx_farming:addWater', function(source, key)
    local src = source
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể tưới nước khi đang ngồi trên xe!', 'error')
        return false
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end
    
    key = tonumber(key)
    local plant = Plants[key]
    if not plant then
        TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy cây!', "error")
        return false
    end
    
    local playerId = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local plantCoords = type(plant.coords) == "string" and json.decode(plant.coords) or plant.coords
    local zoneId = GetZoneIdFromCoords(plantCoords)
    
    if zoneId then
        local hasPermission = CheckFarmPermission(playerId, zoneId)
        if not hasPermission then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền chăm sóc cây trên ruộng này hoặc thời gian thuê đã hết!', "error")
            return false
        end
    end
    
    local cropConf = (CropTypes and plant.crop_type and CropTypes[plant.crop_type]) or Melons
    local waterItem = cropConf.WaterItem or Melons.WaterItem or 'xo_co_nuoc'
    local waterAdd = cropConf.WaterAdd or Melons.WaterAdd or {20, 20}
    local doAm = math.random(waterAdd[1], waterAdd[2])

    local currentWater = tonumber(plant.water) or 0
    if currentWater > 90 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể tưới thêm nước vì cây đã đạt giới hạn nước!')
        return false
    end
    
    local newWater = currentWater
    if currentWater == 90 then
        if ox:RemoveItem(src, waterItem, 1) then
            newWater = 100
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ nước để tưới cây!')
            return false
        end
    else
        if ox:RemoveItem(src, waterItem, 1) then
            newWater = math.min(100, currentWater + doAm)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ nước để tưới cây!')
            return false
        end
    end
    
    updatePlantInMemoryAndDB(key, { water = newWater })
    return true, newWater
end)

-- ==================== HẠT GIỐNG ĐỰC ====================
lib.callback.register('xx_farming:addMaleSeed', function(source, key)
    local src = source
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return false
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end
    
    key = tonumber(key)
    local plant = Plants[key]
    if not plant then
        TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy cây!', "error")
        return false
    end
    
    local playerId = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local plantCoords = type(plant.coords) == "string" and json.decode(plant.coords) or plant.coords
    local zoneId = GetZoneIdFromCoords(plantCoords)
    
    if zoneId then
        local hasPermission = CheckFarmPermission(playerId, zoneId)
        if not hasPermission then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền chăm sóc cây trên ruộng này hoặc thời gian thuê đã hết!', "error")
            return false
        end
    end
    
    if ox:RemoveItem(src, Melons.MaleSeedItem, 1) then
        updatePlantInMemoryAndDB(key, { plantgender = 1 })
        return true
    end
    return false
end)

-- ==================== BÓN PHÂN ====================
lib.callback.register('xx_farming:addFertilizer', function(source, key, fertType)
    local src = source
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể bón phân khi đang ngồi trên xe!', 'error')
        return false
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end
    
    key = tonumber(key)
    local plant = Plants[key]
    if not plant then
        TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy cây!', "error")
        return false
    end
    
    local playerId = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local plantCoords = type(plant.coords) == "string" and json.decode(plant.coords) or plant.coords
    local zoneId = GetZoneIdFromCoords(plantCoords)
    
    if zoneId then
        local hasPermission = CheckFarmPermission(playerId, zoneId)
        if not hasPermission then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền chăm sóc cây trên ruộng này hoặc thời gian thuê đã hết!', "error")
            return false
        end
    end
    
    local cropConf = (CropTypes and plant.crop_type and CropTypes[plant.crop_type]) or Melons
    local fertilizerItem = cropConf.FertilizerItem or Melons.FertilizerItem or 'fertilizer'
    
    local fert = 0
    if fertType == 'p' then
        fert = cropConf.PWeight or Melons.PWeight or -10
    elseif fertType == 'n' then
        fert = cropConf.NWeight or Melons.NWeight or 20
    elseif fertType == 'k' then
        fert = cropConf.KWeight or Melons.KWeight or 20
    end
    
    local currentFertilizer = tonumber(plant.fertilizer) or 0
    if currentFertilizer > 90 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể bón thêm phân bón vì cây đã đạt giới hạn phân bón!')
        return false
    end

    local newFertilizer = currentFertilizer
    if currentFertilizer == 90 then
        if ox:RemoveItem(src, fertilizerItem, 1) then
            newFertilizer = 100
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ phân bón để bón cho cây!')
            return false
        end
    else
        if ox:RemoveItem(src, fertilizerItem, 1) then
            newFertilizer = math.min(100, currentFertilizer + fert)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ phân bón để bón cho cây!')
            return false
        end
    end
    
    updatePlantInMemoryAndDB(key, { fertilizer = newFertilizer })
    return true, newFertilizer
end)

-- ==================== THẢ SÂU BỆNH ====================
lib.callback.register('xx_farming:addbugs', function(source, plantId, cropType)
    local src = source
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return false
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end

    local cropConf = CropTypes[cropType] or Melons
    local bugsItem = cropConf.bugs
    if not bugsItem then return false end

    plantId = tonumber(plantId)
    local plant = Plants[plantId]
    if not plant then return false end

    if not ox:RemoveItem(src, bugsItem, 1) then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có vật phẩm sâu bệnh!', 'error')
        return false
    end

    local currentHealth = tonumber(plant.health) or 100
    local damage = math.random(20, 30)
    local newHealth = math.max(0, currentHealth - damage)

    updatePlantInMemoryAndDB(plantId, { health = newHealth })

    local ownerPid = plant.owner
    if ownerPid then
        local ownerPlayer = Framework.GetPlayerByCitizenId(ownerPid)
        if ownerPlayer and ownerPlayer.PlayerData and ownerPlayer.PlayerData.source then
            TriggerClientEvent('QBCore:Notify', ownerPlayer.PlayerData.source, '⚠️ Có người vừa thả sâu vào cây của bạn! (Sức khỏe còn ' .. newHealth .. '%)', 'error')
        end
    end

    return true
end)

-- ==================== DÙNG THUỐC TRỪ SÂU ====================
lib.callback.register('xx_farming:applyPesticide', function(source, plantId, pesticideType)
    local src = source
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return false
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end

    local treatConf = BugTreatment and BugTreatment[pesticideType]
    if not treatConf then
        TriggerClientEvent('QBCore:Notify', src, 'Loại thuốc không hợp lệ!', 'error')
        return false
    end

    plantId = tonumber(plantId)
    local plant = Plants[plantId]
    if not plant then return false end

    if not ox:RemoveItem(src, pesticideType, 1) then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có ' .. treatConf.label .. '!', 'error')
        return false
    end

    local currentHealth = tonumber(plant.health) or 100
    local newHealth
    if math.random() < treatConf.cureChance then
        newHealth = 100
    else
        newHealth = math.min(100, currentHealth + treatConf.healAmount)
    end

    updatePlantInMemoryAndDB(plantId, { health = newHealth })
    local msg = newHealth >= 100 and 'Cây đã được chữa khỏi hoàn toàn!' or string.format('Sức khỏe cây: %d%%', newHealth)
    TriggerClientEvent('QBCore:Notify', src, msg, 'success')
    return true, newHealth
end)

-- ==================== CẢI THIỆN CÂY (NƯỚC + PHÂN BÓN) ====================
lib.callback.register('xx_farming:addFertilizerk', function(source, key, fertType)
    local src = source
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể bón phân khi đang ngồi trên xe!', 'error')
        return false
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false end
    
    key = tonumber(key)
    local plant = Plants[key]
    if not plant then return false end
    
    local cropConf = (CropTypes and plant.crop_type and CropTypes[plant.crop_type]) or Melons
    local waterItem = cropConf.WaterItem or Melons.WaterItem or 'xo_co_nuoc'
    local waterAdd = cropConf.WaterAdd or Melons.WaterAdd or {20, 20}
    local fertilizerItem = cropConf.FertilizerItem or Melons.FertilizerItem or 'fertilizer'
    
    local doAm = math.random(waterAdd[1], waterAdd[2])
    local updatedFields = { id = key }
    
    local currentWater = tonumber(plant.water) or 0
    if currentWater > 90 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể tưới thêm nước vì cây đã đạt giới hạn nước!')
    elseif currentWater == 90 then
        if ox:RemoveItem(src, waterItem, 1) then
            updatedFields.water = 100
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ nước để tưới cây!')
        end
    else
        if ox:RemoveItem(src, waterItem, 1) then
            updatedFields.water = math.min(100, currentWater + doAm)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ nước để tưới cây!')
        end
    end

    local fert = 0
    if fertType == 'p' then
        fert = cropConf.PWeight or Melons.PWeight or -10
    elseif fertType == 'n' then
        fert = cropConf.NWeight or Melons.NWeight or 20
    elseif fertType == 'k' then
        fert = cropConf.KWeight or Melons.KWeight or 20
    end
    
    local currentFertilizer = tonumber(plant.fertilizer) or 0
    if currentFertilizer > 90 then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể bón thêm phân bón vì cây đã đạt giới hạn phân bón!')
    elseif currentFertilizer == 90 then
        if ox:RemoveItem(src, fertilizerItem, 1) then
            updatedFields.fertilizer = 100
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ phân bón để bón cho cây!')
        end
    else
        if ox:RemoveItem(src, fertilizerItem, 1) then
            updatedFields.fertilizer = math.min(100, currentFertilizer + fert)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ phân bón để bón cho cây!')
        end
    end
    
    local toUpdate = {}
    if updatedFields.water then toUpdate.water = updatedFields.water end
    if updatedFields.fertilizer then toUpdate.fertilizer = updatedFields.fertilizer end
    
    if updatedFields.water or updatedFields.fertilizer then
        updatePlantInMemoryAndDB(key, toUpdate)
        return true, updatedFields
    end
    return false
end)

-- ==================== ADMIN COMMANDS ====================
QBCore.Commands.Add("reset_data_dua_hau", "Xóa dữ liệu trồng dưa (Admin)", {}, false, function(source, args)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    Plants = {}
    PlayerPlantCounts = {}
    ClearPendingPlantWrites()
    for zoneId in pairs(FarmRental.FarmZones) do
        BroadcastZonePlantEvent(zoneId, 1, {})
    end
    MySQL.update("DELETE FROM `tomato_db`", {}, function(affected)
        if xPlayer then
            xPlayer.Functions.Notify("Đã xóa tất cả dữ liệu cây trồng", "success", 5000)
        end
    end)
end, "admin")

QBCore.Commands.Add("check_farm_rentals", "Kiểm tra thuê ruộng (Admin)", {}, false, function(source, args)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    
    local currentTime = os.time()
    local count = 0
    for zoneId, rental in pairs(FarmRentals) do
        if rental.is_active == 1 then
            count = count + 1
            local timeLeft = rental.end_time - currentTime
            local hoursLeft = math.floor(timeLeft / 3600)
            local zoneName = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[rental.zone_id] and FarmRental.FarmZones[rental.zone_id].name or ("Zone #" .. rental.zone_id)
            local status = timeLeft > 0 and "Đang hoạt động" or "Hết hạn"
            
            local plantCount = 0
            for _, p in pairs(Plants) do
                if p.zone_id == rental.zone_id then plantCount = plantCount + 1 end
            end
            
            xPlayer.Functions.Notify(string.format("%s - Owner: %s - Plants: %d - Time left: %dh - Status: %s", zoneName, rental.owner, plantCount, hoursLeft, status), "primary", 10000)
        end
    end
    
    if count == 0 then
        xPlayer.Functions.Notify("Không có ruộng nào đang được thuê", "error", 5000)
    end
end, "admin")

-- ==================== DECAY THREAD (Tối ưu 100% RAM + Async DB Update) ====================
CreateThread(function()
    while true do
        local decreaseInterval = Melons.decreaseInterval or 180000
        Wait(decreaseInterval)

        local plantIds = {}
        local changesByZone = {}
        for plantId in pairs(Plants) do plantIds[#plantIds + 1] = plantId end
        for index, plantId in ipairs(plantIds) do
            local plant = Plants[plantId]
            if plant then
                local cropType = plant.crop_type or 'rice'
                local cropConf = (CropTypes and CropTypes[cropType]) or Melons
            
                local cropInterval = cropConf.decreaseInterval or decreaseInterval
                local decreaseRate = cropConf.decreaseRate or Melons.decreaseRate or 10
                local adjustedRate = decreaseRate * (decreaseInterval / cropInterval)

                local currentWater = tonumber(plant.water) or 0
                local currentFertilizer = tonumber(plant.fertilizer) or 0
                local currentHealth = tonumber(plant.health) or 100

                local newWater = math.max(0, currentWater - adjustedRate)
                local newFertilizer = math.max(0, currentFertilizer - adjustedRate)

                local newHealth = currentHealth
                if newHealth > 5 then
                    local diseaseChance = 0.0
                    local previousFertilizer = plant.fertilizer
                    plant.fertilizer = newFertilizer
                    local growthPct = GetServerPlantGrowth(plant)
                    plant.fertilizer = previousFertilizer

                    if growthPct > 80 and newWater < 80 then
                        diseaseChance = 0.8
                    else
                        local sensitivity = cropConf.bugSensitivity or 0.3
                        if newWater < 50 then
                            diseaseChance = diseaseChance + sensitivity * 1.2
                        end
                        if newFertilizer < 50 then
                            diseaseChance = diseaseChance + sensitivity * 0.8
                        end
                    end

                    local bugRate = cropConf.bugDecreaseRate or 12
                    if newHealth < 50 then
                        newHealth = math.max(0, newHealth - math.ceil(bugRate * 0.5))
                    elseif math.random() < diseaseChance then
                        newHealth = math.max(0, newHealth - math.ceil(bugRate * 0.4))
                    end
                end

                local _, delta = updatePlantInMemoryAndDB(plantId, {
                    water = newWater, fertilizer = newFertilizer, health = newHealth
                }, true)
                if delta then
                    local zoneId = tonumber(plant.zone_id)
                    if zoneId then
                        changesByZone[zoneId] = changesByZone[zoneId] or {}
                        changesByZone[zoneId][#changesByZone[zoneId] + 1] = delta
                    end
                end
            end
            if index % 50 == 0 then
                -- Flush before yielding so a player action in the next frame
                -- cannot be overwritten on clients by an older decay delta.
                for zoneId, changes in pairs(changesByZone) do
                    BroadcastPlantBatch(zoneId, changes)
                end
                changesByZone = {}
                Wait(0)
            end
        end
        for zoneId, changes in pairs(changesByZone) do
            BroadcastPlantBatch(zoneId, changes)
        end
    end
end)

-- ==================== QUẢN LÝ CHIA SẺ QUYỀN ====================
RegisterNetEvent('xx_farming:sharePermission')
AddEventHandler('xx_farming:sharePermission', function(zoneId, targetPid)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    zoneId = tonumber(zoneId) or zoneId
    
    local rental = FarmRentals[zoneId]
    if not rental or rental.owner ~= pid or rental.is_active ~= 1 or rental.end_time <= os.time() then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không sở hữu hoặc không có quyền trên ruộng này!', 'error')
        return
    end
    
    if not FarmPermissions[zoneId] then FarmPermissions[zoneId] = {} end
    if FarmPermissions[zoneId][targetPid] then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn đã chia sẻ quyền cho người này rồi!', 'error')
        return
    end
    
    local grantedAt = os.time()
    MySQL.insert([[
        INSERT INTO farm_permissions (rental_id, zone_id, owner, shared_with, granted_at) 
        VALUES (?, ?, ?, ?, ?)
    ]], { rental.id, zoneId, pid, targetPid, grantedAt }, function(insertId)
        if insertId then
            FarmPermissions[zoneId][targetPid] = {
                id = insertId,
                rental_id = rental.id,
                zone_id = zoneId,
                owner = pid,
                shared_with = targetPid,
                granted_at = grantedAt
            }
            TriggerClientEvent('QBCore:Notify', src, 'Đã chia sẻ quyền trồng cây cho ' .. targetPid .. '!', 'success')
            
            local targetPlayer = Framework.GetPlayerByCitizenId(targetPid)
            if targetPlayer and targetPlayer.PlayerData and targetPlayer.PlayerData.source then
                local zoneName = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId] and FarmRental.FarmZones[zoneId].name or ("Ruộng #" .. zoneId)
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Bạn đã được chia sẻ quyền trồng cây tại ' .. zoneName .. '!', 'success', 8000)
            end
        end
    end)
end)

RegisterNetEvent('xx_farming:removePermission')
AddEventHandler('xx_farming:removePermission', function(zoneId, targetPid)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    zoneId = tonumber(zoneId) or zoneId
    
    if FarmPermissions[zoneId] and FarmPermissions[zoneId][targetPid] then
        FarmPermissions[zoneId][targetPid] = nil
        MySQL.update('DELETE FROM farm_permissions WHERE zone_id = ? AND owner = ? AND shared_with = ?', { zoneId, pid, targetPid })
        
        TriggerClientEvent('QBCore:Notify', src, 'Đã xóa quyền trồng cây của ' .. targetPid .. '!', 'success')
        TriggerClientEvent('xx_farming:refreshFarmMenu', src)
        
        local targetPlayer = Framework.GetPlayerByCitizenId(targetPid)
        if targetPlayer and targetPlayer.PlayerData and targetPlayer.PlayerData.source then
            local zoneName = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId] and FarmRental.FarmZones[zoneId].name or ("Ruộng #" .. zoneId)
            TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Quyền trồng cây tại ' .. zoneName .. ' đã bị thu hồi!', 'error', 8000)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy quyền cần xóa!', 'error')
    end
end)

-- Lấy danh sách người chơi gần xung quanh
lib.callback.register('xx_farming:getNearbyPlayers', function(source, radius)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return {} end

    local myCoords = GetEntityCoords(GetPlayerPed(source))
    local dist = radius or 10.0
    local nearby = {}

    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        if playerId ~= source then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and targetPed ~= 0 then
                local targetCoords = GetEntityCoords(targetPed)
                if #(myCoords - targetCoords) <= dist then
                    local targetPlayer = QBCore.Functions.GetPlayer(playerId)
                    if targetPlayer and targetPlayer.PlayerData then
                        local charinfo = targetPlayer.PlayerData.charinfo or {}
                        nearby[#nearby + 1] = {
                            pid  = targetPlayer.PlayerData.pid or targetPlayer.PlayerData.citizenid,
                            name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                        }
                    end
                end
            end
        end
    end

    return nearby
end)

lib.callback.register('xx_farming:getSharedUsers', function(source, zoneId)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return {} end
    
    zoneId = tonumber(zoneId) or zoneId
    local result = {}
    
    if FarmPermissions[zoneId] then
        for sharedWith, perm in pairs(FarmPermissions[zoneId]) do
            result[#result + 1] = {
                shared_with = sharedWith,
                granted_at = perm.granted_at
            }
        end
    end
    
    return result
end)

-- ==================== PERMISSION CALLBACKS (100% RAM Lookups) ====================
lib.callback.register('xx_farming:checkFarmPermission', function(source, zoneId)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return false end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    return CheckFarmPermission(pid, zoneId)
end)

lib.callback.register('xx_farming:checkPlantPermission', function(source, plantCoords, plantOwner)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then 
        return { canInteract = false, canSteal = false }
    end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local zoneId = GetZoneIdFromCoords(plantCoords)
    local hasPermission = false
    if zoneId then
        hasPermission = CheckFarmPermission(pid, zoneId)
    end
    
    local isOwner = (plantOwner == pid)
    local canInteract = hasPermission or isOwner
    local canSteal = not canInteract
    
    return {
        canInteract = canInteract,
        canSteal = canSteal,
        zoneId = zoneId,
        hasPermission = hasPermission,
        isOwner = isOwner
    }
end)

lib.callback.register('xx_farming:checkPlantingPermission', function(source, coords)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then 
        return { canPlant = false, message = "Lỗi hệ thống - không tìm thấy player!" }
    end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local zoneId = GetZoneIdFromCoords(coords)
    
    if not zoneId then
        return { canPlant = false, message = "Bạn không thể trồng cây ở vị trí này!" }
    end
    
    local hasPermission, permissionType = CheckFarmPermission(pid, zoneId)
    if not hasPermission then
        return { 
            canPlant = false, 
            message = string.format("Bạn cần thuê ruộng #%d hoặc được chia sẻ quyền trước khi trồng cây!", zoneId)
        }
    end
    
    return { 
        canPlant = true, 
        zoneId = zoneId,
        permissionType = permissionType,
        message = string.format("Bạn có quyền trồng cây trong ruộng #%d (%s)", zoneId, permissionType)
    }
end)

lib.callback.register('xx_farming:checkPlantingPermissionByZone', function(source, zoneId)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then 
        return { canPlant = false, message = "Lỗi hệ thống - không tìm thấy player!" }
    end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    zoneId = tonumber(zoneId) or zoneId
    if not zoneId then
        return { canPlant = false, message = "Bạn không thể trồng cây ở vị trí này!" }
    end
    
    local hasPermission, permissionType = CheckFarmPermission(pid, zoneId)
    if not hasPermission then
        return { 
            canPlant = false, 
            message = string.format("Bạn cần thuê ruộng #%d hoặc được chia sẻ quyền trước khi trồng cây!", zoneId)
        }
    end
    
    return { 
        canPlant = true, 
        zoneId = zoneId,
        permissionType = permissionType,
        message = string.format("Bạn có quyền trồng cây trong ruộng #%d (%s)", zoneId, permissionType)
    }
end)

lib.callback.register('xx_farming:checkPlantPermissionByCoords', function(source, plantCoords, plantOwner)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then 
        return { canInteract = false, canSteal = false }
    end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local zoneId = GetZoneIdFromCoords(plantCoords)
    local hasPermission = false
    if zoneId then
        hasPermission = CheckFarmPermission(pid, zoneId)
    end
    
    local isOwner = (plantOwner == pid)
    local canInteract = hasPermission or isOwner
    local canSteal = not canInteract
    
    return {
        canInteract = canInteract,
        canSteal = canSteal,
        zoneId = zoneId,
        hasPermission = hasPermission,
        isOwner = isOwner
    }
end)

-- ==================== ĂN CẮP CÂY TRỒNG ====================
lib.callback.register('xx_farming:stealPlant', function(source, plantId)
    local ped = GetPlayerPed(source)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return false, "Không thể ăn cắp khi đang ngồi trên xe!"
    end

    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return false end
    
    local thiefPid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    plantId = tonumber(plantId)
    
    if not CanStealPlant(thiefPid, plantId) then
        return false, "Không thể ăn cắp cây này!"
    end
    
    local plant = Plants[plantId]
    if not plant then
        return false, "Cây trồng không tồn tại!"
    end
    
    local hasDogProtection = HasDogProtection(plant.zone_id)
    local success = true
    
    if hasDogProtection then
        local detectionChance = DogProtection.DogBiteChance or 50
        if math.random(100) <= detectionChance then
            local plantCoords = type(plant.coords) == "string" and json.decode(plant.coords) or plant.coords
            local dogSpawnPos = {
                x = plantCoords.x + math.random(-10, 10),
                y = plantCoords.y + math.random(-10, 10), 
                z = plantCoords.z,
                targetPlayerId = source
            }
            
            TriggerClientEvent('xx_farming:spawnGuardDog', source, dogSpawnPos)
            LogTheft(thiefPid, plant.owner, plant.zone_id, plant.crop_type or "rice", 0, false, true)
            return false, "Chó bảo vệ đã phát hiện và đang tấn công bạn!"
        else
            local stealSuccessRate = DogProtection.TheftSuccessRateWithDog or 50
            if math.random(100) > stealSuccessRate then
                LogTheft(thiefPid, plant.owner, plant.zone_id, plant.crop_type or "rice", 0, false, false)
                return false, "Ăn cắp thất bại!"
            end
        end
    end
    
    if success then
        local cropType = plant.crop_type or 'rice'
        local cropConf = (CropTypes and CropTypes[cropType]) or Melons
        local entry = cropConf.GiveDopeItem[math.random(#cropConf.GiveDopeItem)]
        local RandomItem = type(entry) == 'table' and entry.item or entry

        local waterLevel = tonumber(plant.water) or 0
        local ferLevel   = tonumber(plant.fertilizer) or 0
        local qua = waterLevel + ferLevel

        local plantHealth = tonumber(plant.health) or 100
        local healthMultiplier = 1.0
        if plantHealth <= 5 then
            healthMultiplier = 0.0
        elseif plantHealth <= 25 then
            healthMultiplier = 0.3
        elseif plantHealth <= 50 then
            healthMultiplier = 0.6
        elseif plantHealth <= 75 then
            healthMultiplier = 0.85
        end

        local harvestAmount = 0
        if waterLevel <= 25 and ferLevel < 10 then
            harvestAmount = 0
        elseif qua <= 80 then
            harvestAmount = math.max(0, math.floor((cropConf.DopeFromFemale2 or 2) * healthMultiplier))
        elseif qua <= 150 then
            harvestAmount = math.max(0, math.floor((cropConf.DopeFromFemale4 or 4) * healthMultiplier))
        else
            harvestAmount = math.max(0, math.floor((cropConf.DopeFromFemale6 or 6) * healthMultiplier))
        end
        
        if harvestAmount > 0 then
            if not exports.ox_inventory:CanCarryItem(source, RandomItem, harvestAmount) then
                return false, "Túi đồ của bạn quá nặng, không thể ăn cắp!"
            end
            ox:AddItem(source, RandomItem, harvestAmount)
        end

        deletePlantFromMemory(plantId)
        MySQL.update('DELETE FROM tomato_db WHERE id = ?', { plantId })
        BroadcastZonePlantEvent(plant.zone_id, 4, plantId)

        if harvestAmount > 0 then
            TriggerClientEvent('QBCore:Notify', source, 'Bạn đã ăn cắp thành công ' .. harvestAmount .. ' ' .. RandomItem, 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, 'Ăn cắp thành công nhưng cây không có trái (thiếu nước/phân)!', 'primary')
        end

        LogTheft(thiefPid, plant.owner, plant.zone_id, cropType, harvestAmount, true, false)
        return true, "Ăn cắp thành công!"
    end
end)

-- ==================== THUÊ CHÓ BẢO VỆ ====================
lib.callback.register('xx_farming:rentDogProtection', function(source, zoneId, hours)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return false end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    zoneId = tonumber(zoneId) or zoneId
    hours = tonumber(hours) or 1
    
    if not CheckFarmPermission(pid, zoneId) then
        return false, "Bạn không có quyền thuê bảo vệ cho khu vực này!"
    end
    
    local totalCost = (DogProtection.RentalPricePerHour or 500) * hours
    local cash = xPlayer.PlayerData.money and xPlayer.PlayerData.money.cash or 0
    if cash < totalCost then
        return false, "Bạn không đủ tiền để thuê chó bảo vệ!"
    end
    
    if HasDogProtection(zoneId) then
        return false, "Khu vực này đã có chó bảo vệ!"
    end
    
    xPlayer.Functions.RemoveMoney('cash', totalCost)
    
    local expiresAt = os.time() + (hours * 3600)
    MySQL.insert([[
        INSERT INTO farm_dog_protection (zone_id, renter_pid, expires_at) 
        VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))
    ]], { zoneId, pid, hours }, function(insertId)
        if insertId then
            DogProtections[zoneId] = {
                id = insertId,
                zone_id = zoneId,
                renter_pid = pid,
                expires_at = expiresAt
            }
        end
    end)
    
    TriggerClientEvent('QBCore:Notify', source, 'Đã thuê chó bảo vệ cho ' .. hours .. ' giờ với giá $' .. totalCost, 'success')
    return true, "Thuê bảo vệ thành công!"
end)

lib.callback.register('xx_farming:getDogProtectionInfo', function(source, zoneId)
    if not zoneId then return { hasProtection = false } end
    zoneId = tonumber(zoneId) or zoneId
    
    local hasProt, dp = HasDogProtection(zoneId)
    if hasProt and dp then
        return {
            hasProtection = true,
            expiresAt = dp.expires_at,
            renterPid = dp.renter_pid
        }
    end
    
    return { hasProtection = false }
end)

-- ==================== STRESS KHI THU HOẠCH ĐU ĐỦ ====================
RegisterNetEvent('xx_farming:addDuduHarvestStress', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentStress = Player.PlayerData.metadata and Player.PlayerData.metadata["stress"] or 0
    local addStress = math.random(1, 2)
    local newStress = math.min(100, currentStress + addStress)
    Player.Functions.SetMetaData("stress", newStress)
end)
