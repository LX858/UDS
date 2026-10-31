local QBCore = exports["qb-core"]:GetCoreObject()

-- Lấy danh sách ruộng đã thuê của người chơi (100% RAM Lookup)
lib.callback.register('xx_farming:getPlayerRentals', function(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return {} end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local currentTime = os.time()
    local result = {}
    
    for _, rental in pairs(FarmRentals) do
        if rental.owner == pid and rental.is_active == 1 and rental.end_time > currentTime then
            local zoneName = (FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[rental.zone_id] and FarmRental.FarmZones[rental.zone_id].name) or ("Ruộng #" .. rental.zone_id)
            result[#result + 1] = {
                id = rental.id,
                zone_id = rental.zone_id,
                owner = rental.owner,
                start_time = rental.start_time,
                end_time = rental.end_time,
                hours_rented = rental.hours_rented,
                price_paid = rental.price_paid,
                is_active = rental.is_active,
                zone_name = zoneName
            }
        end
    end
    
    return result
end)

-- Kiểm tra xem người chơi có quyền trồng cây ở zone này không (100% RAM Lookup)
lib.callback.register('xx_farming:canPlantInZone', function(source, coords)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return false end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local zoneId = GetZoneIdFromCoords(coords)
    
    if not zoneId then return true end -- Nếu không trong zone nào thì cho phép
    
    local hasPermission = CheckFarmPermission(pid, zoneId)
    return hasPermission
end)

-- Lấy trạng thái tất cả ruộng (ai thuê, còn bao lâu, etc.) (100% RAM Lookup)
lib.callback.register('xx_farming:getAllFarmStatus', function(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return {} end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    local currentTime = os.time()
    local farmStatus = {}
    
    -- Đánh dấu ruộng nào đã được thuê
    for zoneId, rental in pairs(FarmRentals) do
        if rental.is_active == 1 and rental.end_time > currentTime then
            farmStatus[zoneId] = {
                isRented = true,
                owner = rental.owner,
                isOwnedByPlayer = (rental.owner == pid),
                endTime = rental.end_time,
                timeLeft = rental.end_time - currentTime
            }
        end
    end
    
    -- Đánh dấu ruộng no_rent để client biết không hiển thị option thuê
    if FarmRental and FarmRental.FarmZones then
        for zoneId, zone in pairs(FarmRental.FarmZones) do
            if zone.no_rent or zone.capture then
                if not farmStatus[zoneId] then farmStatus[zoneId] = {} end
                farmStatus[zoneId].no_rent = true
            end
        end
    end
    
    return farmStatus
end)

-- Thuê ruộng
RegisterNetEvent('xx_farming:rentFarm')
AddEventHandler('xx_farming:rentFarm', function(zoneId, hours)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    zoneId = tonumber(zoneId) or zoneId
    hours = tonumber(hours) or 1
    
    -- Lấy giá thuê của zone này
    local zone = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId]
    if not zone then
        TriggerClientEvent('QBCore:Notify', src, 'Zone không hợp lệ', 'error')
        return
    end
    
    -- Kiểm tra xem ruộng có cho thuê không
    if zone.no_rent or zone.capture then
        TriggerClientEvent('QBCore:Notify', src, 'Ruộng này không cho thuê!', 'error')
        return
    end
    
    local totalPrice = hours * zone.rentalPrice
    local currentTime = os.time()
    
    -- Kiểm tra xem zone đã được thuê bởi người khác chưa
    local existing = FarmRentals[zoneId]
    if existing and existing.is_active == 1 and existing.end_time > currentTime and existing.owner ~= pid then
        TriggerClientEvent('QBCore:Notify', src, 'Ruộng này đã được thuê bởi người khác!', 'error')
        return
    end
    
    -- Kiểm tra xem người chơi hiện tại đã thuê zone này chưa
    if existing and existing.is_active == 1 and existing.owner == pid and existing.end_time > currentTime then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn đã thuê ruộng này rồi! Sử dụng chức năng gia hạn nếu muốn thuê thêm.', 'error')
        return
    end
    
    -- Kiểm tra tiền
    local cash = xPlayer.PlayerData.money and xPlayer.PlayerData.money.cash or 0
    if cash < totalPrice then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ tiền để thuê ruộng! Cần: $' .. totalPrice, 'error')
        return
    end
    
    -- Trừ tiền
    xPlayer.Functions.RemoveMoney('cash', totalPrice)
    
    local startTime = currentTime
    local endTime = startTime + (hours * 3600)
    
    -- Xóa các bản ghi cũ của zone trong DB async
    MySQL.update('DELETE FROM farm_permissions WHERE zone_id = ?', { zoneId })
    MySQL.update('DELETE FROM farm_rentals WHERE zone_id = ?', { zoneId })
    
    -- Thêm vào database async
    MySQL.insert([[
        INSERT INTO farm_rentals (zone_id, owner, start_time, end_time, hours_rented, price_paid, is_active) 
        VALUES (?, ?, ?, ?, ?, ?, 1)
    ]], { zoneId, pid, startTime, endTime, hours, totalPrice }, function(insertId)
        if insertId then
            FarmRentals[zoneId] = {
                id = insertId,
                zone_id = zoneId,
                owner = pid,
                start_time = startTime,
                end_time = endTime,
                hours_rented = hours,
                price_paid = totalPrice,
                is_active = 1
            }
            FarmPermissions[zoneId] = {}
            
            local zoneName = zone.name or ("Ruộng #" .. zoneId)
            TriggerClientEvent('QBCore:Notify', src, 'Đã thuê ' .. zoneName .. ' trong ' .. hours .. ' giờ với giá $' .. totalPrice, 'success')
        else
            -- Hoàn tiền nếu insert thất bại
            xPlayer.Functions.AddMoney('cash', totalPrice)
            TriggerClientEvent('QBCore:Notify', src, 'Có lỗi xảy ra khi thuê ruộng. Tiền đã được hoàn lại.', 'error')
        end
    end)
end)

-- Gia hạn thuê ruộng
RegisterNetEvent('xx_farming:extendRental')
AddEventHandler('xx_farming:extendRental', function(zoneId, hours)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    zoneId = tonumber(zoneId) or zoneId
    hours = tonumber(hours) or 1
    
    -- Lấy giá thuê của zone này
    local zone = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId]
    if not zone then
        TriggerClientEvent('QBCore:Notify', src, 'Zone không hợp lệ', 'error')
        return
    end
    
    local rental = FarmRentals[zoneId]
    if not rental or rental.owner ~= pid or rental.is_active ~= 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không thuê ruộng này!', 'error')
        return
    end
    
    local totalPrice = hours * zone.rentalPrice
    local cash = xPlayer.PlayerData.money and xPlayer.PlayerData.money.cash or 0
    if cash < totalPrice then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ tiền để gia hạn! Cần: $' .. totalPrice, 'error')
        return
    end
    
    -- Trừ tiền
    xPlayer.Functions.RemoveMoney('cash', totalPrice)
    
    local currentEndTime = rental.end_time
    local newEndTime = math.max(currentEndTime, os.time()) + (hours * 3600)
    
    -- Cập nhật RAM
    rental.end_time = newEndTime
    rental.hours_rented = (rental.hours_rented or 0) + hours
    rental.price_paid = (rental.price_paid or 0) + totalPrice
    
    -- Ghi async xuống DB
    MySQL.update('UPDATE farm_rentals SET end_time = ?, hours_rented = hours_rented + ?, price_paid = price_paid + ? WHERE id = ?', {
        newEndTime, hours, totalPrice, rental.id
    })
    
    local zoneName = zone.name or ("Ruộng #" .. zoneId)
    TriggerClientEvent('QBCore:Notify', src, 'Đã gia hạn ' .. zoneName .. ' thêm ' .. hours .. ' giờ với giá $' .. totalPrice, 'success')
end)

-- Dọn dẹp ruộng (xóa tất cả cây trồng)
RegisterNetEvent('xx_farming:cleanupFarm')
AddEventHandler('xx_farming:cleanupFarm', function(zoneId)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local pid = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid
    zoneId = tonumber(zoneId) or zoneId
    
    -- Kiểm tra quyền sở hữu từ RAM
    local rental = FarmRentals[zoneId]
    if not rental or rental.owner ~= pid or rental.is_active ~= 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền dọn dẹp ruộng này!', 'error')
        return
    end
    
    local rentalId = rental.id
    
    -- Xóa tất cả cây trồng trong zone khỏi RAM
    for plantId, plant in pairs(Plants) do
        if plant.zone_id == zoneId then
            deletePlantFromMemory(plantId)
        end
    end
    
    -- Xóa rental và permissions khỏi RAM
    FarmRentals[zoneId] = nil
    FarmPermissions[zoneId] = nil
    
    -- Xóa DB async
    MySQL.update('DELETE FROM tomato_db WHERE zone_id = ?', { zoneId })
    MySQL.update('DELETE FROM farm_permissions WHERE rental_id = ?', { rentalId })
    MySQL.update('DELETE FROM farm_rentals WHERE id = ?', { rentalId })
    
    -- Gửi snapshot rỗng trực tiếp để client xóa cả cây và object đang hiển thị.
    BroadcastZonePlantEvent(zoneId, 1, {})
    
    local zoneName = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zoneId] and FarmRental.FarmZones[zoneId].name or ("Ruộng #" .. zoneId)
    TriggerClientEvent('QBCore:Notify', src, 'Đã dọn dẹp và trả ' .. zoneName, 'success')
end)

-- Tự động hết hạn thuê ruộng (Đọc RAM, Async DB update)
CreateThread(function()
    while true do
        Wait(60000) -- Kiểm tra mỗi phút trong RAM
        
        local currentTime = os.time()
        local expiredRentals = {}
        
        for zoneId, rental in pairs(FarmRentals) do
            if rental.is_active == 1 and rental.end_time < currentTime then
                expiredRentals[#expiredRentals + 1] = rental
            end
        end
        
        for _, rental in ipairs(expiredRentals) do
            local rId = rental.id
            local zId = rental.zone_id
            local ownerPid = rental.owner
            
            -- Xóa khỏi RAM
            FarmRentals[zId] = nil
            FarmPermissions[zId] = nil
            
            -- Xóa khỏi DB async
            MySQL.update('DELETE FROM farm_permissions WHERE rental_id = ?', { rId })
            MySQL.update('DELETE FROM farm_rentals WHERE id = ?', { rId })
            
            -- Thông báo cho người thuê nếu họ đang online qua Core cache
            local player = Framework.GetPlayerByCitizenId(ownerPid)
            if player and player.PlayerData and player.PlayerData.source then
                local zoneName = FarmRental and FarmRental.FarmZones and FarmRental.FarmZones[zId] and FarmRental.FarmZones[zId].name or ("Ruộng #" .. zId)
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 'Thời gian thuê ' .. zoneName .. ' đã hết hạn!', 'error', 10000)
            end
        end
    end
end)
