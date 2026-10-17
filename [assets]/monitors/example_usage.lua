-- ============================================
-- VÍ DỤ SỬ DỤNG ANTI-TRIGGER SYSTEM
-- ============================================

-- ============================================
-- CÁCH 1: BẢO VỆ EVENT ĐƠN GIẢN
-- ============================================

-- SERVER SIDE (trong resource của bạn)
exports['anti-trigger']:RegisterProtectedEvent('example:giveWeapon', function(source, weaponName)
    local xPlayer = ESX.GetPlayerFromId(source) -- ESX example
    
    if xPlayer then
        xPlayer.addWeapon(weaponName, 100)
        print(string.format("Đã trao %s cho %s", weaponName, GetPlayerName(source)))
    end
end)

-- CLIENT SIDE (trong resource của bạn)
RegisterCommand('getgun', function(source, args)
    local weapon = args[1] or 'WEAPON_PISTOL'
    
    -- Cách 1: Dùng export
    exports['anti-trigger']:TriggerProtectedServerEvent('example:giveWeapon', weapon)
    
    -- Cách 2: Dùng global function (đơn giản hơn)
    -- _TriggerProtectedServerEvent('example:giveWeapon', weapon)
end, false)

-- ============================================
-- CÁCH 2: BẢO VỆ NHIỀU EVENT CÙNG LÚC
-- ============================================

-- SERVER SIDE
local protectedEvents = {
    -- Bảo vệ event trao item
    ['shop:buyItem'] = function(source, itemName, quantity, price)
        local xPlayer = ESX.GetPlayerFromId(source)
        
        if xPlayer.getMoney() >= price then
            xPlayer.removeMoney(price)
            xPlayer.addInventoryItem(itemName, quantity)
            TriggerClientEvent('esx:showNotification', source, 'Đã mua ' .. itemName)
        else
            TriggerClientEvent('esx:showNotification', source, 'Không đủ tiền!')
        end
    end,
    
    -- Bảo vệ event trao tiền
    ['admin:giveMoney'] = function(source, targetId, amount)
        -- Kiểm tra quyền admin (ví dụ)
        if IsPlayerAceAllowed(source, 'admin') then
            local xTarget = ESX.GetPlayerFromId(targetId)
            if xTarget then
                xTarget.addMoney(amount)
                TriggerClientEvent('esx:showNotification', source, 'Đã trao tiền')
            end
        end
    end,
    
    -- Bảo vệ event đổi nghề
    ['admin:setJob'] = function(source, targetId, job, grade)
        if IsPlayerAceAllowed(source, 'admin') then
            local xTarget = ESX.GetPlayerFromId(targetId)
            if xTarget then
                xTarget.setJob(job, grade)
                TriggerClientEvent('esx:showNotification', source, 'Đã đổi nghề')
            end
        end
    end,
    
    -- Bảo vệ event teleport
    ['admin:teleport'] = function(source, x, y, z)
        if IsPlayerAceAllowed(source, 'admin') then
            local ped = GetPlayerPed(source)
            SetEntityCoords(ped, x, y, z)
        end
    end
}

-- Đăng ký tất cả events được bảo vệ
exports['anti-trigger']:RegisterProtectedEvents(protectedEvents)

-- ============================================
-- CÁCH 3: BẢO VỆ EVENT TRONG ESX
-- ============================================

-- SERVER SIDE - Bảo vệ ESX events
exports['anti-trigger']:RegisterProtectedEvent('esx_shop:buyItem', function(source, itemName, quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    local item = ESX.GetItem(itemName)
    
    if item then
        local totalPrice = item.price * quantity
        
        if xPlayer.getMoney() >= totalPrice then
            xPlayer.removeMoney(totalPrice)
            xPlayer.addInventoryItem(itemName, quantity)
            TriggerClientEvent('esx:showNotification', source, 'Đã mua thành công')
        else
            TriggerClientEvent('esx:showNotification', source, 'Không đủ tiền')
        end
    end
end)

-- CLIENT SIDE
function BuyItem(itemName, quantity)
    _TriggerProtectedServerEvent('esx_shop:buyItem', itemName, quantity)
end

-- ============================================
-- CÁCH 4: BẢO VỆ EVENT TRONG QBCORE
-- ============================================

-- SERVER SIDE
exports['anti-trigger']:RegisterProtectedEvent('qb-shop:server:buyItem', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    local totalPrice = data.price * data.amount
    
    if Player.PlayerData.money.cash >= totalPrice then
        Player.Functions.RemoveMoney('cash', totalPrice)
        Player.Functions.AddItem(data.item, data.amount)
        TriggerClientEvent('QBCore:Notify', source, 'Đã mua thành công', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Không đủ tiền', 'error')
    end
end)

-- CLIENT SIDE
RegisterNetEvent('qb-shop:client:buyItem', function(item, amount, price)
    _TriggerProtectedServerEvent('qb-shop:server:buyItem', {
        item = item,
        amount = amount,
        price = price
    })
end)

-- ============================================
-- CÁCH 5: BẢO VỆ EVENT NGÂN HÀNG
-- ============================================

-- SERVER SIDE
exports['anti-trigger']:RegisterProtectedEvent('bank:deposit', function(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        xPlayer.addAccountMoney('bank', amount)
        TriggerClientEvent('esx:showNotification', source, 'Đã gửi $' .. amount)
    else
        TriggerClientEvent('esx:showNotification', source, 'Không đủ tiền mặt')
    end
end)

exports['anti-trigger']:RegisterProtectedEvent('bank:withdraw', function(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer.getAccount('bank').money >= amount then
        xPlayer.removeAccountMoney('bank', amount)
        xPlayer.addMoney(amount)
        TriggerClientEvent('esx:showNotification', source, 'Đã rút $' .. amount)
    else
        TriggerClientEvent('esx:showNotification', source, 'Không đủ tiền trong bank')
    end
end)

-- CLIENT SIDE
function DepositMoney(amount)
    if amount > 0 then
        _TriggerProtectedServerEvent('bank:deposit', amount)
    end
end

function WithdrawMoney(amount)
    if amount > 0 then
        _TriggerProtectedServerEvent('bank:withdraw', amount)
    end
end

-- ============================================
-- CÁCH 6: BẢO VỆ EVENT ADMIN MENU
-- ============================================

-- SERVER SIDE
local adminEvents = {
    ['admin:giveItem'] = function(source, targetId, itemName, quantity)
        if IsPlayerAceAllowed(source, 'admin.items') then
            local xTarget = ESX.GetPlayerFromId(targetId)
            if xTarget then
                xTarget.addInventoryItem(itemName, quantity)
                TriggerClientEvent('esx:showNotification', source, 'Đã trao item')
            end
        else
            DropPlayer(source, 'Unauthorized admin action')
        end
    end,
    
    ['admin:revivePlayer'] = function(source, targetId)
        if IsPlayerAceAllowed(source, 'admin.revive') then
            TriggerClientEvent('esx_ambulancejob:revive', targetId)
            TriggerClientEvent('esx:showNotification', source, 'Đã hồi sinh người chơi')
        else
            DropPlayer(source, 'Unauthorized admin action')
        end
    end,
    
    ['admin:kickPlayer'] = function(source, targetId, reason)
        if IsPlayerAceAllowed(source, 'admin.kick') then
            DropPlayer(targetId, reason)
            TriggerClientEvent('esx:showNotification', source, 'Đã kick người chơi')
        else
            DropPlayer(source, 'Unauthorized admin action')
        end
    end
}

exports['anti-trigger']:RegisterProtectedEvents(adminEvents)

-- CLIENT SIDE
function AdminGiveItem(targetId, itemName, quantity)
    _TriggerProtectedServerEvent('admin:giveItem', targetId, itemName, quantity)
end

-- ============================================
-- CÁCH 7: BẢO VỆ EVENT VEHICLE SHOP
-- ============================================

-- SERVER SIDE
exports['anti-trigger']:RegisterProtectedEvent('vehicleshop:buyVehicle', function(source, vehicleModel, vehiclePlate, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer.getAccount('bank').money >= price then
        xPlayer.removeAccountMoney('bank', price)
        
        -- Lưu xe vào database
        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
            ['@owner'] = xPlayer.identifier,
            ['@plate'] = vehiclePlate,
            ['@vehicle'] = json.encode({model = GetHashKey(vehicleModel), plate = vehiclePlate})
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('esx:showNotification', source, 'Đã mua xe thành công')
            end
        end)
    else
        TriggerClientEvent('esx:showNotification', source, 'Không đủ tiền')
    end
end)

-- CLIENT SIDE
function BuyVehicle(model, plate, price)
    _TriggerProtectedServerEvent('vehicleshop:buyVehicle', model, plate, price)
end

-- ============================================
-- CÁCH 8: KIỂM TRA TOKEN TRONG CODE HIỆN CÓ
-- ============================================

-- SERVER SIDE - Nếu bạn muốn tự kiểm tra token
RegisterNetEvent('myResource:customEvent', function(token, data)
    local source = source
    
    -- Kiểm tra token thủ công
    local isValid = exports['anti-trigger']:ValidateToken(source, token)
    
    if isValid then
        -- Token hợp lệ, xử lý code của bạn
        print("Token hợp lệ, xử lý event...")
        -- Your code here
    else
        print(string.format("Token không hợp lệ từ player %s", GetPlayerName(source)))
    end
end)

-- CLIENT SIDE
function TriggerCustomEvent(data)
    local token = exports['anti-trigger']:GetCurrentToken()
    
    if token then
        TriggerServerEvent('myResource:customEvent', token, data)
    else
        print("Token chưa sẵn sàng!")
    end
end

-- ============================================
-- CÁCH 9: SỬ DỤNG VỚI NUI CALLBACK
-- ============================================

-- CLIENT SIDE
RegisterNUICallback('buyItem', function(data, cb)
    -- Kiểm tra token trước khi trigger
    if exports['anti-trigger']:IsTokenReady() then
        _TriggerProtectedServerEvent('shop:buyItem', data.item, data.quantity, data.price)
        cb({success = true})
    else
        cb({success = false, error = 'Token not ready'})
    end
end)

-- ============================================
-- CÁCH 10: DEBUG VÀ TESTING
-- ============================================

-- CLIENT SIDE - Commands để test
RegisterCommand('testtoken', function()
    if exports['anti-trigger']:IsTokenReady() then
        print("^2Token sẵn sàng!^7")
        print("Token: " .. exports['anti-trigger']:GetCurrentToken())
    else
        print("^1Token chưa sẵn sàng!^7")
    end
end, false)

RegisterCommand('testprotected', function()
    -- Test trigger event được bảo vệ
    _TriggerProtectedServerEvent('example:testEvent', 'test_data')
    print("^3Đã trigger event được bảo vệ^7")
end, false)

-- ============================================
-- LƯU Ý QUAN TRỌNG
-- ============================================

--[[
    1. Luôn dùng _TriggerProtectedServerEvent() thay vì TriggerServerEvent() 
       cho các event được bảo vệ
    
    2. Token tự động refresh, bạn không cần lo lắng về việc quản lý
    
    3. Nếu token hết hạn, hệ thống sẽ tự động request token mới
    
    4. Mọi vi phạm đều được ghi log và theo dõi
    
    5. Sau Config.MaxViolations lần vi phạm, người chơi sẽ bị ban tự động
    
    6. Có thể bật Discord webhook để nhận thông báo về vi phạm
    
    7. Sử dụng RegisterProtectedEvent() thay vì RegisterNetEvent() 
       cho các event cần bảo vệ
    
    8. Handler function của protected event sẽ nhận source là tham số đầu tiên,
       theo sau là các tham số khác (token đã được xử lý tự động)
]]

-- ============================================
-- BEST PRACTICES
-- ============================================

--[[
    ✅ NÊN:
    - Bảo vệ tất cả events liên quan đến tiền, item, xe
    - Bảo vệ events admin/moderator
    - Bảo vệ events có thể bị lợi dụng
    - Kiểm tra quyền admin trong handler function
    - Log các hành động quan trọng
    
    ❌ KHÔNG NÊN:
    - Bảo vệ events được trigger rất thường xuyên (vd: updatePosition)
    - Bảo vệ events không quan trọng
    - Quên validate dữ liệu trong handler
    - Tin tưởng hoàn toàn client-side data
]]
