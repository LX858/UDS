local QBX = exports.qbx_core
local listedVehicles = {} -- {[plate] = {price, owner, model}}
local pendingTransactions = {} -- {[plate] = {seller, buyer, price}}

-- Function: Gửi Discord Webhook
local function SendDiscordLog(data)
    if not Config.DiscordWebhook or Config.DiscordWebhook == "" then return end
    
    local fields = {
        {
            ["name"] = "👤 Người Bán",
            ["value"] = string.format("**Tên:** %s\n**PID:** %s", data.sellerName, data.sellerPID),
            ["inline"] = true
        },
        {
            ["name"] = "👤 Người Mua",
            ["value"] = string.format("**Tên:** %s\n**PID:** %s", data.buyerName, data.buyerPID),
            ["inline"] = true
        },
        {
            ["name"] = "🚙 Thông Tin Xe",
            ["value"] = string.format("**Loại xe:** %s\n**Biển số:** %s", data.vehicleName, data.plate),
            ["inline"] = false
        },
        {
            ["name"] = "💰 Giá Bán",
            ["value"] = string.format("$%s", data.price),
            ["inline"] = true
        },
        {
            ["name"] = "💸 Thuế (%.0f%%)",
            ["value"] = string.format("$%s", data.tax),
            ["inline"] = true
        },
        {
            ["name"] = "💵 Người Bán Nhận",
            ["value"] = string.format("$%s", data.sellerReceive),
            ["inline"] = true
        }
    }

    if data.isVIP then
        table.insert(fields, {
            ["name"] = "🎟️ Vé VIP Sử Dụng",
            ["value"] = string.format("Đã trừ %dx %s", Config.VIPItem.count, Config.VIPItem.label or Config.VIPItem.item),
            ["inline"] = false
        })
    end

    local embed = {
        {
            ["title"] = "🚗 GIAO DỊCH BÁN XE THÀNH CÔNG",
            ["color"] = 3066993, -- Màu xanh lá
            ["fields"] = fields,
            ["footer"] = {
                ["text"] = "XN Vehicle Sale System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest("https://discord.com/api/webhooks/1467136019865534582/zz5z2RzK72pLcH_4VQBsPMkJWRUvfHqFVieG4AjuxYFxGEgNM97gFGJXwbyjwpdpnA7d", function(err, text, headers) end, 'POST', json.encode({
        username = "XN Vehicle Sale",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Event: Cleanup khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^3[xn_banxecu] Cleaning up State Bags...')
    
    -- Clear tất cả State Bag của xe đang bán
    for plate, data in pairs(listedVehicles) do
        local vehicles = GetAllVehicles()
        for _, vehicle in ipairs(vehicles) do
            local vehPlate = GetVehicleNumberPlateText(vehicle)
            if vehPlate and vehPlate:gsub("^%s*(.-)%s*$", "%1") == plate then
                Entity(vehicle).state:set('listedVehicle', nil, true)
                print('^2[xn_banxecu] Cleared State Bag for plate:', plate)
                break
            end
        end
    end
    
    print('^2[xn_banxecu] Cleanup complete!')
end)

-- Callback: Lấy tên người chơi (firstname + lastname + citizenid)
lib.callback.register('xn_banxecu:getPlayerName', function(source, targetId)
    local player = QBX:GetPlayer(targetId)
    if not player then return nil end
    
    local firstname = player.PlayerData.charinfo.firstname or ''
    local lastname = player.PlayerData.charinfo.lastname or ''
    local citizenid = player.PlayerData.pid or ''
    
    return {
        name = firstname .. ' ' .. lastname,
        citizenid = citizenid
    }
end)

-- Callback: Lấy thông tin owner của xe (dùng cho NUI)
lib.callback.register('xn_banxecu:getOwnerInfo', function(source, plate)
    local vehicleData = listedVehicles[plate]
    if not vehicleData then return nil end
    
    local ownerSource = vehicleData.owner
    local player = QBX:GetPlayer(ownerSource)
    if not player then return nil end
    
    -- Lấy số điện thoại từ lb-phone
    local phoneNumber = exports['lb-phone']:GetEquippedPhoneNumber(ownerSource) or 'N/A'
    
    return {
        firstname = player.PlayerData.charinfo.firstname or '',
        lastname = player.PlayerData.charinfo.lastname or '',
        citizenid = player.PlayerData.pid or '',
        phone = phoneNumber
    }
end)

-- Callback: Lấy thông tin xe listed theo plate
lib.callback.register('xn_banxecu:getListedVehicle', function(source, plate)
    return listedVehicles[plate]
end)
-- Callback: Lấy thông tin xe và giá từ cardealer
lib.callback.register('xn_banxecu:getVehicleInfo', function(source, plate)
    local player = QBX:GetPlayer(source)
    if not player then return nil end
    
    -- Kiểm tra xe có thuộc sở hữu của player không
    local result = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate, player.PlayerData.citizenid
    })
    
    if not result then return nil end
    
    -- Lấy giá xe từ cardealer_stock
    local dealerPrice = MySQL.scalar.await('SELECT priceToCustomers FROM cardealer_stock WHERE vehicle = ? LIMIT 1', {
        result.vehicle
    })
    
    if not dealerPrice then
        -- Nếu không tìm thấy trong cardealer_stock, dùng giá mặc định
        dealerPrice = 50000
    end
    
    return {
        vehicleName = result.vehicle,
        plate = plate,
        dealerPrice = dealerPrice
    }
end)

-- Callback: Đăng bán xe
lib.callback.register('xn_banxecu:listVehicle', function(source, plate, price, parkingSpot)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    -- Kiểm tra xe đã được đăng bán chưa
    if listedVehicles[plate] then
        return false
    end
    
    -- Lấy thông tin xe
    local result = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate, player.PlayerData.citizenid
    })
    
    if not result then return false end

    -- Kiểm tra xe có thuộc danh sách blacklist không
    local isBlacklisted = Config.IsVehicleBlacklisted(result.vehicle)
    if isBlacklisted then
        if not Config.VIPItem or not Config.VIPItem.enabled then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi',
                description = 'Xe này không được phép bán',
                type = 'error'
            })
            return false
        end

        local vipCount = exports.ox_inventory:GetItemCount(source, Config.VIPItem.item) or 0
        if vipCount < Config.VIPItem.count then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi',
                description = string.format('Bạn cần có %dx %s để đăng bán xe này!', Config.VIPItem.count, Config.VIPItem.label or Config.VIPItem.item),
                type = 'error'
            })
            return false
        end
    end

    -- Kiểm tra giá tối thiểu hợp lệ
    local minPrice = 0
    if isBlacklisted then
        minPrice = (Config.VIPItem and Config.VIPItem.minPrice) or 1000000
    else
        local dealerPrice = MySQL.scalar.await('SELECT priceToCustomers FROM cardealer_stock WHERE vehicle = ? LIMIT 1', {
            result.vehicle
        }) or 50000
        minPrice = math.floor(dealerPrice * Config.PricePercentage)
    end

    if not price or price < minPrice then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = string.format('Giá bán tối thiểu là $%s', lib.math.groupdigits(minPrice)),
            type = 'error'
        })
        return false
    end
    
    -- Lưu vào danh sách xe đang bán
    listedVehicles[plate] = {
        price = price,
        owner = source,
        model = result.vehicle,
        citizenid = player.PlayerData.citizenid,
        parkingSpot = parkingSpot,
        isVIP = isBlacklisted
    }
    
    -- Không cần TriggerClientEvent, dùng State Bag để tự động sync
    -- Client sẽ lắng nghe thay đổi qua AddStateBagChangeHandler
    
    return true
end)

-- Callback: Gỡ đăng bán xe
lib.callback.register('xn_banxecu:unlistVehicle', function(source, plate)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    local data = listedVehicles[plate]
    
    -- Kiểm tra quyền sở hữu
    if data and data.owner ~= source then
        return false
    end
    
    -- Nếu không có trong listedVehicles (do restart), kiểm tra State Bag
    if not data then
        -- Tìm xe theo plate và kiểm tra State Bag
        local vehicles = GetAllVehicles()
        local found = false
        
        for _, vehicle in ipairs(vehicles) do
            local vehPlate = GetVehicleNumberPlateText(vehicle)
            if vehPlate and vehPlate:gsub("^%s*(.-)%s*$", "%1") == plate then
                local stateBag = Entity(vehicle).state.listedVehicle
                
                -- Kiểm tra State Bag có tồn tại và player có phải owner không
                if stateBag then
                    -- Kiểm tra citizenid thay vì source (vì source thay đổi sau restart)
                    local result = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
                        plate, player.PlayerData.citizenid
                    })
                    
                    if result then
                        -- Clear State Bag
                        Entity(vehicle).state:set('listedVehicle', nil, true)
                        found = true
                        print('^2[xn_banxecu] Removed orphaned State Bag for plate:', plate)
                        break
                    else
                        -- Không phải chủ xe
                        return false
                    end
                end
            end
        end
        
        return found
    end
    
    -- Xóa khỏi danh sách
    listedVehicles[plate] = nil
    
    -- Không cần TriggerClientEvent, State Bag sẽ tự động sync
    
    return true
end)

-- Event: Bán xe cho người chơi khác
RegisterNetEvent('xn_banxecu:sellVehicle', function(plate, buyerId, price)
    local source = source
    local seller = QBX:GetPlayer(source)
    local buyer = QBX:GetPlayer(buyerId)
    
    if not seller or not buyer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Không tìm thấy người chơi',
            type = 'error'
        })
        return
    end
    
    local data = listedVehicles[plate]
    if not data or data.owner ~= source then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Xe không tồn tại hoặc không thuộc sở hữu của bạn',
            type = 'error'
        })
        return
    end

    local isBlacklisted = data.isVIP or Config.IsVehicleBlacklisted(data.model)
    if isBlacklisted and Config.VIPItem and Config.VIPItem.enabled then
        local vipCount = exports.ox_inventory:GetItemCount(source, Config.VIPItem.item) or 0
        if vipCount < Config.VIPItem.count then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi',
                description = string.format('Bạn cần có %dx %s trong balo để bán xe VIP này!', Config.VIPItem.count, Config.VIPItem.label or Config.VIPItem.item),
                type = 'error'
            })
            return
        end
    end
    
    -- Lưu giao dịch đang chờ
    pendingTransactions[plate] = {
        seller = source,
        buyer = buyerId,
        price = price,
        sellerName = seller.PlayerData.charinfo.firstname .. ' ' .. seller.PlayerData.charinfo.lastname,
        vehicleName = data.model
    }
    
    -- Gửi yêu cầu mua đến người mua
    TriggerClientEvent('xn_banxecu:receiveBuyRequest', buyerId, 
        pendingTransactions[plate].sellerName,
        data.model,
        plate,
        price
    )
end)

-- Event: Người mua xác nhận mua
RegisterNetEvent('xn_banxecu:confirmBuy', function(plate)
    local source = source
    local transaction = pendingTransactions[plate]
    
    if not transaction or transaction.buyer ~= source then
        return
    end
    
    local seller = QBX:GetPlayer(transaction.seller)
    local buyer = QBX:GetPlayer(source)
    
    if not seller or not buyer then
        pendingTransactions[plate] = nil
        return
    end
    
    local data = listedVehicles[plate]
    if not data then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Xe không còn được đăng bán',
            type = 'error'
        })
        pendingTransactions[plate] = nil
        return
    end
    
    local totalPrice = transaction.price
    local tax = math.floor(totalPrice * Config.TransactionTax)
    local sellerReceive = totalPrice - tax
    
    -- Kiểm tra tiền của người mua
    if buyer.PlayerData.money.cash < totalPrice then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Bạn không đủ tiền mặt',
            type = 'error'
        })
        TriggerClientEvent('xn_banxecu:transactionCancelled', transaction.seller)
        pendingTransactions[plate] = nil
        return
    end

    -- Kiểm tra và trừ vé VIP của người bán nếu là xe VIP/Blacklist
    local isBlacklisted = data.isVIP or Config.IsVehicleBlacklisted(data.model)
    if isBlacklisted and Config.VIPItem and Config.VIPItem.enabled then
        local vipCount = exports.ox_inventory:GetItemCount(transaction.seller, Config.VIPItem.item) or 0
        if vipCount < Config.VIPItem.count then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi',
                description = 'Người bán không đủ Vé Bán Xe VIP để hoàn tất giao dịch!',
                type = 'error'
            })
            TriggerClientEvent('ox_lib:notify', transaction.seller, {
                title = 'Lỗi',
                description = string.format('Bạn không đủ %dx %s trong balo để hoàn tất bán xe VIP!', Config.VIPItem.count, Config.VIPItem.label or Config.VIPItem.item),
                type = 'error'
            })
            TriggerClientEvent('xn_banxecu:transactionCancelled', transaction.seller)
            pendingTransactions[plate] = nil
            return
        end

        local removed = exports.ox_inventory:RemoveItem(transaction.seller, Config.VIPItem.item, Config.VIPItem.count)
        if not removed then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi',
                description = 'Không thể trừ Vé Bán Xe VIP của người bán!',
                type = 'error'
            })
            TriggerClientEvent('ox_lib:notify', transaction.seller, {
                title = 'Lỗi',
                description = 'Không thể trừ Vé Bán Xe VIP trong balo của bạn!',
                type = 'error'
            })
            TriggerClientEvent('xn_banxecu:transactionCancelled', transaction.seller)
            pendingTransactions[plate] = nil
            return
        end
    end
    
    -- Trừ tiền người mua
    buyer.Functions.RemoveMoney('cash', totalPrice, 'vehicle-purchase')
    
    -- Thêm tiền cho người bán
    seller.Functions.AddMoney('cash', sellerReceive, 'vehicle-sale')
    
    -- Chuyển quyền sở hữu xe (cập nhật citizenid và license)
    MySQL.update.await('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', {
        buyer.PlayerData.citizenid,
        buyer.PlayerData.license,
        plate
    })
    
    -- Xóa xe khỏi danh sách bán
    listedVehicles[plate] = nil
    
    -- Thông báo cho cả 2 bên (chỉ gửi đến người cụ thể)
    TriggerClientEvent('xn_banxecu:transactionComplete', transaction.seller, plate, true)
    TriggerClientEvent('xn_banxecu:transactionComplete', source, plate, false)
    
    -- Xóa giao dịch
    pendingTransactions[plate] = nil
    
    -- Gửi Discord Log
    SendDiscordLog({
        sellerName = seller.PlayerData.charinfo.firstname .. ' ' .. seller.PlayerData.charinfo.lastname,
        sellerPID = seller.PlayerData.pid or seller.PlayerData.pid,
        buyerName = buyer.PlayerData.charinfo.firstname .. ' ' .. buyer.PlayerData.charinfo.lastname,
        buyerPID = buyer.PlayerData.pid or buyer.PlayerData.pid,
        vehicleName = transaction.vehicleName,
        plate = plate,
        price = lib.math.groupdigits(totalPrice),
        tax = lib.math.groupdigits(tax),
        sellerReceive = lib.math.groupdigits(sellerReceive),
        isVIP = isBlacklisted
    })
    
    -- Log giao dịch console
    -- print(string.format('^2[xn_banxecu] Transaction: %s [%s] sold %s (%s) to %s [%s] for $%s',
    --     seller.PlayerData.charinfo.firstname .. ' ' .. seller.PlayerData.charinfo.lastname,
    --     seller.PlayerData.pid or seller.PlayerData.pid,
    --     transaction.vehicleName,
    --     plate,
    --     buyer.PlayerData.charinfo.firstname .. ' ' .. buyer.PlayerData.charinfo.lastname,
    --     buyer.PlayerData.pid or buyer.PlayerData.pid,
    --     totalPrice
    -- ))
end)

-- Event: Người mua hủy giao dịch
RegisterNetEvent('xn_banxecu:cancelBuy', function(plate)
    local source = source
    local transaction = pendingTransactions[plate]
    
    if not transaction or transaction.buyer ~= source then
        return
    end
    
    -- Thông báo cho người bán
    TriggerClientEvent('xn_banxecu:transactionCancelled', transaction.seller)
    
    -- Xóa giao dịch
    pendingTransactions[plate] = nil
end)

-- Xử lý khi người chơi disconnect
AddEventHandler('playerDropped', function()
    local source = source
    
    -- Xóa tất cả xe đang bán của người chơi
    for plate, data in pairs(listedVehicles) do
        if data.owner == source then
            -- Tìm xe và clear State Bag
            local vehicles = GetAllVehicles()
            for _, vehicle in ipairs(vehicles) do
                local vehPlate = GetVehicleNumberPlateText(vehicle)
                if vehPlate and vehPlate:gsub("^%s*(.-)%s*$", "%1") == plate then
                    -- Clear State Bag để auto-sync với clients
                    Entity(vehicle).state:set('listedVehicle', nil, true)
                    print(string.format('^3[xn_banxecu] Player %s disconnected - Auto unlisted vehicle: %s', source, plate))
                    break
                end
            end
            
            -- Xóa khỏi danh sách
            listedVehicles[plate] = nil
        end
    end
    
    -- Hủy tất cả giao dịch liên quan
    for plate, transaction in pairs(pendingTransactions) do
        if transaction.seller == source then
            TriggerClientEvent('xn_banxecu:transactionCancelled', transaction.buyer)
            pendingTransactions[plate] = nil
        elseif transaction.buyer == source then
            TriggerClientEvent('xn_banxecu:transactionCancelled', transaction.seller)
            pendingTransactions[plate] = nil
        end
    end
end)
