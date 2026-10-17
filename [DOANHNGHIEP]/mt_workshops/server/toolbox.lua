RegisterNetEvent('mt_workshops:server:fixVehicleBody', function(vehicle, player)
    TriggerClientEvent('mt_workshops:client:fixVehicleBody', -1, vehicle, player)
end)

RegisterNetEvent('mt_workshops:server:damageVehicleBody', function(vehicle, player)
    TriggerClientEvent('mt_workshops:client:damageVehicleBody', -1, vehicle, player)
end)

RegisterNetEvent('mt_workshops:server:fixVehicleEngine', function(vehicle, player)
    TriggerClientEvent('mt_workshops:client:fixVehicleEngine', -1, vehicle, player)
end)

RegisterNetEvent('mt_workshops:server:damageVehicleEngine', function(vehicle, player)
    TriggerClientEvent('mt_workshops:client:damageVehicleEngine', -1, vehicle, player)
end)

RegisterNetEvent('mt_workshops:server:fixVehicleTank', function(vehicle, player)
    TriggerClientEvent('mt_workshops:client:fixVehicleTank', -1, vehicle, player)
end)

RegisterNetEvent('mt_workshops:server:washVehicle', function(vehicle, player)
    TriggerClientEvent('mt_workshops:client:washVehicle', -1, vehicle, player)
end)

RegisterNetEvent('mt_workshops:server:changeVehicleOil', function(vehicle, player)
    TriggerClientEvent('mt_workshops:client:changeVehicleOil', -1, vehicle, player)
end)

RegisterNetEvent('mt_workshops:server:setVehicleRepairFreeze', function(netId, state)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        Entity(vehicle).state:set('isRepairFrozen', state, true)
        TriggerClientEvent('mt_workshops:client:syncVehicleFreeze', -1, netId, state)
    end
end)

-- Bảng lưu thời gian log cuối cùng của mỗi biển số
local lastLogTime = {}
local LOG_COOLDOWN = 15 * 60 -- 15 phút tính bằng giây

RegisterNetEvent('mt_workshops:server:discordLog', function(actionType, vehiclePlate, vehicleHash, vehicleName, vehicleLabel)
    local src = source

    -- Chỉ gửi log khi sửa toàn bộ xe ngành
    if actionType ~= 'repairAll' then return end

    -- Kiểm tra cooldown: nếu biển số này đã được log trong vòng 15 phút thì bỏ qua
    local currentTime = os.time()
    local cleanPlate = string.gsub(vehiclePlate, "%s+", "")
    if lastLogTime[cleanPlate] and (currentTime - lastLogTime[cleanPlate]) < LOG_COOLDOWN then
        return
    end

    local webhookURL = "https://ptb.discord.com/api/webhooks/1480670323174150211/JJCJ0YDCEdlkPjfjiCWyGDCkV_cFRh-AGx8Neaigk0L2JW5xr4bF-SsCixcZIRDU9OLo"

    -- Kiểm tra xe có trong Config.specialVehicles không (dùng joaat để so sánh hash chính xác)
    local isSpecialVehicle = false
    for _, specialModel in ipairs(Config.specialVehicles) do
        if joaat(specialModel) == vehicleHash then
            isSpecialVehicle = true
            break
        end
    end
    if not isSpecialVehicle then return end

    -- Lấy thông tin người sửa (mechanic)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    local mechanicName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local mechanicPID = Player.PlayerData.pid

    -- Title mặc định (sẽ được ghi đè bởi job từ database)
    local logTitle = '🚗 SỬA XE NGÀNH ĐẶC BIỆT'
    local logColor = 10181046

    -- Lấy thông tin chủ xe (cleanPlate đã được định nghĩa ở trên)
    local ownerName = 'N/A'
    local ownerPID = 'N/A'

    -- Tìm trong job_vehicles trước, fallback sang player_vehicles
    local jobVehicle = MySQL.single.await('SELECT citizenid, job FROM job_vehicles WHERE plate = ? OR plate = ?', { vehiclePlate, cleanPlate })
    local citizenid = jobVehicle and jobVehicle.citizenid

    local vehicleJob = (jobVehicle and jobVehicle.job) or ''
    if vehicleJob == 'police' or vehicleJob == 'sheriff' then
        logTitle = '🚔 SỬA XE NGÀNH CẢNH SÁT'
        logColor = 255
    elseif vehicleJob == 'ambulance' then
        logTitle = '🚑 SỬA XE NGÀNH BÁC SĨ'
        logColor = 65280
    elseif vehicleJob == 'fire' then
        logTitle = '🚒 SỬA XE NGÀNH CỨU HỎA'
        logColor = 16744192
    end

    if not citizenid then
        local pv = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? OR plate = ?', { vehiclePlate, cleanPlate })
        citizenid = pv and pv.citizenid
    end

    if citizenid then
        local ownerInfo = MySQL.single.await('SELECT charinfo, pid FROM players WHERE citizenid = ?', { citizenid })
        if ownerInfo then
            local ok, charinfo = pcall(json.decode, ownerInfo.charinfo)
            if ok and charinfo then
                ownerName = charinfo.firstname .. ' ' .. charinfo.lastname
                ownerPID = tostring(ownerInfo.pid)
            end
        end
    end

    local formattedTime = os.date("%H:%M:%S - %d/%m/%Y")

    local embed = {
        {
            ["title"] = logTitle,
            ["color"] = logColor,
            ["fields"] = {
                {
                    ["name"] = "🔧 Thợ Sửa",
                    ["value"] = mechanicName .. " (PID: " .. mechanicPID .. ")",
                    ["inline"] = true
                },
                {
                    ["name"] = "👤 Chủ Xe",
                    ["value"] = ownerName .. " (PID: " .. ownerPID .. ")",
                    ["inline"] = true
                },
                {
                    ["name"] = "🚘 Biển Số",
                    ["value"] = vehiclePlate,
                    ["inline"] = true
                },
                {
                    ["name"] = "🚗 Tên Xe",
                    ["value"] = vehicleLabel,
                    ["inline"] = true
                },
                {
                    ["name"] = "⏰ Thời Gian",
                    ["value"] = formattedTime,
                    ["inline"] = true
                }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
        }
    }

    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({
        username = "Workshop Log",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })

    -- Cập nhật thời gian log cuối cùng cho biển số này
    lastLogTime[cleanPlate] = currentTime
end)

RegisterNetEvent('mt_workshops:server:giveRepairInvoice', function(engineRepaired, bodyRepaired, plate, washed)
    local src = source
    local washedText = washed and "\nRửa xe: Có" or ""
    local metadata = {
        description = string.format("Biển số: %s\nĐã sửa động cơ: %d%%\nĐã sửa thân vỏ: %d%%%s", plate, engineRepaired, bodyRepaired, washedText),
        plate = plate,
        engine_repaired = engineRepaired,
        body_repaired = bodyRepaired,
        washed = washed and true or false
    }
    
    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:AddItem(src, 'hoadonsuaxe', 1, metadata)
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem('hoadonsuaxe', 1, nil, metadata)
        end
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            Player.Functions.AddItem('hoadonsuaxe', 1, nil, metadata)
        end
    end
end)

local function getPlayerCharName(src)
    src = tonumber(src)
    if not src then return "N/A" end
    if Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if Player then return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname end
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname end
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if Player then return Player.getName() end
    end
    return GetPlayerName(src) or "Người chơi"
end

local function getPlayerJobName(src)
    src = tonumber(src)
    if not src then return nil end
    if Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if Player then return Player.PlayerData.job.name end
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then return Player.PlayerData.job.name end
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if Player then return Player.getJob().name end
    end
    return nil
end

local function hasItem(src, itemName)
    if Config.inventory == 'ox_inventory' then
        return exports.ox_inventory:GetItemCount(src, itemName) >= 1
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if Player then
            local item = Player.Functions.GetItemByName(itemName)
            return item and item.amount >= 1
        end
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            local item = Player.Functions.GetItemByName(itemName)
            return item and item.amount >= 1
        end
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if Player then
            local item = Player.getInventoryItem(itemName)
            return item and item.count >= 1
        end
    end
    return false
end

local function removeItem(src, item, count)
    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:RemoveItem(src, item, count)
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(item, count)
        end
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(item, count)
        end
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if Player then
            Player.removeInventoryItem(item, count)
        end
    end
end

RegisterNetEvent('mt_workshops:server:sendRepairInvoiceToPlayer', function(targetServerId, plate, body, engine, totalAmount, slot)
    local src = source
    local targetId = tonumber(targetServerId)
    local billerName = getPlayerCharName(src)
    
    local discounts = {
        ['phieu_giam_gia_10'] = hasItem(targetId, 'phieu_giam_gia_10'),
        ['phieu_giam_gia_20'] = hasItem(targetId, 'phieu_giam_gia_20'),
        ['phieu_giam_gia_30'] = hasItem(targetId, 'phieu_giam_gia_30'),
        ['phieu_giam_gia_50'] = hasItem(targetId, 'phieu_giam_gia_50'),
    }
    
    TriggerClientEvent('mt_workshops:client:receiveRepairInvoice', targetId, src, billerName, plate, body, engine, totalAmount, slot, discounts)
end)

RegisterNetEvent('mt_workshops:server:rejectRepairInvoice', function(billerSource)
    local billerSrc = tonumber(billerSource)
    if not billerSrc then return end
    TriggerClientEvent('mt_workshops:client:notify', billerSrc, "Khách hàng đã hủy yêu cầu thanh toán hóa đơn!", "error")
end)

RegisterNetEvent('mt_workshops:server:payRepairInvoice', function(billerSource, totalAmount, slot, chosenDiscount)
    local src = source -- Người thanh toán B
    local billerSrc = tonumber(billerSource)
    local originalAmount = tonumber(totalAmount)
    
    if not billerSrc or not originalAmount then return end

    local discountPercent = 0
    if chosenDiscount then
        if chosenDiscount == 'phieu_giam_gia_10' and hasItem(src, 'phieu_giam_gia_10') then
            discountPercent = 10
        elseif chosenDiscount == 'phieu_giam_gia_20' and hasItem(src, 'phieu_giam_gia_20') then
            discountPercent = 20
        elseif chosenDiscount == 'phieu_giam_gia_30' and hasItem(src, 'phieu_giam_gia_30') then
            discountPercent = 30
        elseif chosenDiscount == 'phieu_giam_gia_50' and hasItem(src, 'phieu_giam_gia_50') then
            discountPercent = 50
        end
    end
    
    local finalPayerAmount = originalAmount
    if discountPercent > 0 then
        finalPayerAmount = math.floor(originalAmount * (100 - discountPercent) / 100)
    end
    
    local hasEnoughMoney = false
    local paymentType = nil
    
    if Config.framework == 'qb' then
        local Payer = Config.core.Functions.GetPlayer(src)
        if Payer then
            if Payer.Functions.GetMoney('cash') >= finalPayerAmount then
                paymentType = 'cash'
                hasEnoughMoney = true
            elseif Payer.Functions.GetMoney('bank') >= finalPayerAmount then
                paymentType = 'bank'
                hasEnoughMoney = true
            end
        end
    elseif Config.framework == 'qbx' then
        local Payer = exports.qbx_core:GetPlayer(src)
        if Payer then
            if Payer.Functions.GetMoney('cash') >= finalPayerAmount then
                paymentType = 'cash'
                hasEnoughMoney = true
            elseif Payer.Functions.GetMoney('bank') >= finalPayerAmount then
                paymentType = 'bank'
                hasEnoughMoney = true
            end
        end
    elseif Config.framework == 'esx' then
        local Payer = Config.core.GetPlayerFromId(src)
        if Payer then
            if Payer.getMoney() >= finalPayerAmount then
                paymentType = 'money'
                hasEnoughMoney = true
            elseif Payer.getAccount('bank').money >= finalPayerAmount then
                paymentType = 'bank'
                hasEnoughMoney = true
            end
        end
    end
    
    if not hasEnoughMoney then
        TriggerClientEvent('mt_workshops:client:notify', src, "Bạn không đủ tiền để thanh toán hóa đơn này!", "error")
        TriggerClientEvent('mt_workshops:client:notify', billerSrc, "Khách hàng không đủ tiền để thanh toán!", "error")
        return
    end
    
    -- Trừ tiền của người B (Giá sau khi đã giảm)
    if Config.framework == 'qb' or Config.framework == 'qbx' then
        local Payer = (Config.framework == 'qb') and Config.core.Functions.GetPlayer(src) or exports.qbx_core:GetPlayer(src)
        Payer.Functions.RemoveMoney(paymentType, finalPayerAmount, 'repair-invoice-payment')
    elseif Config.framework == 'esx' then
        local Payer = Config.core.GetPlayerFromId(src)
        if paymentType == 'bank' then
            Payer.removeAccountMoney('bank', finalPayerAmount)
        else
            Payer.removeMoney(finalPayerAmount)
        end
    end

    -- Trừ phiếu giảm giá nếu có sử dụng
    if discountPercent > 0 and chosenDiscount then
        removeItem(src, chosenDiscount, 1)
    end
    
    -- Tính toán hoa hồng và quỹ society dựa trên GIÁ GỐC (originalAmount)
    local commission = math.floor(originalAmount * 30 / 100)
    local societyAmount = originalAmount - commission
    local jobName = getPlayerJobName(billerSrc) or 'mechanic'
    
    -- Cộng 30% cho người gửi A (cộng thẳng tiền mặt)
    if Config.framework == 'qb' or Config.framework == 'qbx' then
        local Biller = (Config.framework == 'qb') and Config.core.Functions.GetPlayer(billerSrc) or exports.qbx_core:GetPlayer(billerSrc)
        if Biller then
            Biller.Functions.AddMoney('cash', commission, 'repair-invoice-commission')
        end
    elseif Config.framework == 'esx' then
        local Biller = Config.core.GetPlayerFromId(billerSrc)
        if Biller then
            Biller.addAccountMoney('money', commission)
        end
    end
    
    -- Cộng 70% vào quỹ doanh nghiệp
    addAccountMoney(jobName, societyAmount)
    
    -- Xóa hóa đơn trong hòm đồ của người gửi A
    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:RemoveItem(billerSrc, 'hoadonsuaxe', 1, nil, slot)
    else
        if Config.framework == 'qb' or Config.framework == 'qbx' then
            local Biller = (Config.framework == 'qb') and Config.core.Functions.GetPlayer(billerSrc) or exports.qbx_core:GetPlayer(billerSrc)
            if Biller then
                Biller.Functions.RemoveItem('hoadonsuaxe', 1, slot)
            end
        end
    end
    
    TriggerClientEvent('mt_workshops:client:notify', billerSrc, string.format("Khách hàng đã thanh toán hóa đơn thành công! Bạn nhận được %d$ (30%% hoa hồng).", commission), "success")
    TriggerClientEvent('mt_workshops:client:notify', src, string.format("Bạn đã thanh toán hóa đơn thành công: %d$.", finalPayerAmount), "success")
end)
