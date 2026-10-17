-- =============================================
-- HỆ THỐNG NPC BÁN HÀNG OFFLINE
-- =============================================

-- Dữ liệu NPC trong bộ nhớ (global để main.lua truy cập)
npcShopData = {}

-- -----------------------------------------------
-- DB: khởi tạo bảng và load dữ liệu
-- -----------------------------------------------
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `xn_banhnuoc_npc` (
            `shop_key`        VARCHAR(50)  NOT NULL,
            `expires_at`      BIGINT       NOT NULL DEFAULT 0,
            `offline_revenue` INT          NOT NULL DEFAULT 0,
            PRIMARY KEY (`shop_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local results = MySQL.query.await("SELECT * FROM `xn_banhnuoc_npc`")
    if results then
        local now = os.time()
        for _, row in ipairs(results) do
            local remainingTime = row.expires_at or 0
            -- Backward compatibility: if row.expires_at was a future unix timestamp
            if row.expires_at > 1000000000 then
                if row.expires_at > now then
                    remainingTime = row.expires_at - now
                else
                    remainingTime = 0
                end
            end
            npcShopData[row.shop_key] = {
                remaining_time  = remainingTime,
                offline_revenue = row.offline_revenue or 0
            }
        end
    end
    print("[xn_banhnuoc] NPC system loaded. " .. #(results or {}) .. " shop(s) with NPC data.")
end)

-- -----------------------------------------------
-- Helpers
-- -----------------------------------------------
local function SaveNpcData(shopKey)
    local d = npcShopData[shopKey] or { remaining_time = 0, offline_revenue = 0 }
    MySQL.query([[
        INSERT INTO `xn_banhnuoc_npc` (shop_key, expires_at, offline_revenue)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            expires_at      = VALUES(expires_at),
            offline_revenue = VALUES(offline_revenue)
    ]], { shopKey, d.remaining_time or 0, d.offline_revenue or 0 })
end

-- Đếm số lượng item trong stash
local function GetStashCount(stashId, itemName)
    local items = exports.ox_inventory:GetInventoryItems(stashId, false)
    if not items then return 0 end
    local count = 0
    for _, item in pairs(items) do
        if item and item.name == itemName then
            count = count + item.count
        end
    end
    return count
end

-- NPC còn hiệu lực thuê?
function IsNpcActive(shopKey)
    local d = npcShopData[shopKey]
    if not d or not d.remaining_time or d.remaining_time <= 0 then return false end
    return true
end

local function AreAllEmployeesOffline(shopKey)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return true end
    local count = GlobalState[shopConfig.job .. '_count']
    return not count or count == 0
end

-- NPC đang bán? (active + tất cả nhân viên offline)
function IsNpcSelling(shopKey)
    return IsNpcActive(shopKey) and AreAllEmployeesOffline(shopKey)
end

-- Trạng thái NPC gửi về NUI
function GetNpcStatus(shopKey)
    local d = npcShopData[shopKey] or { remaining_time = 0, offline_revenue = 0 }
    local remaining = d.remaining_time or 0
    local isOffline = AreAllEmployeesOffline(shopKey)
    return {
        remaining_time  = remaining,
        expires_at      = remaining > 0 and ((os.time() + remaining) * 1000) or 0,
        offline_revenue = d.offline_revenue or 0,
        is_active       = remaining > 0,
        is_selling      = remaining > 0 and isOffline,
        is_paused       = remaining > 0 and not isOffline,
    }
end

-- -----------------------------------------------
-- Threads: Trừ thời gian NPC khi offline & Save DB
-- -----------------------------------------------

-- Thread đếm ngược thời gian NPC khi tất cả nhân viên offline
CreateThread(function()
    local interval = 10 -- 10 giây mỗi lần kiểm tra
    while true do
        Wait(interval * 1000)
        for shopKey, d in pairs(npcShopData) do
            if d.remaining_time and d.remaining_time > 0 then
                if AreAllEmployeesOffline(shopKey) then
                    -- Tất cả nhân viên offline: trừ thời gian
                    local oldTime = d.remaining_time
                    d.remaining_time = math.max(0, d.remaining_time - interval)
                    if d.remaining_time == 0 and oldTime > 0 then
                        SaveNpcData(shopKey)
                    end
                end
                -- Có nhân viên online: KHÔNG trừ thời gian (tạm dừng)
            end
        end
    end
end)

-- Định kỳ lưu DB mỗi 5 phút
CreateThread(function()
    while true do
        Wait(300000)
        for shopKey, _ in pairs(npcShopData) do
            SaveNpcData(shopKey)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for shopKey, _ in pairs(npcShopData) do
        SaveNpcData(shopKey)
    end
end)

-- Kiểm tra quyền boss (grade >= minGrade của stash_sell_config)
local function IsBoss(source, shopKey)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return false end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    if player.PlayerData.job.name ~= shopConfig.job then return false end
    local grade    = player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0
    local minGrade = shopConfig.stash_sell_config and shopConfig.stash_sell_config.minGrade or 3
    return grade >= minGrade
end

-- -----------------------------------------------
-- Callbacks
-- -----------------------------------------------

-- Lấy trạng thái NPC (chỉ nhân viên)
lib.callback.register('xn_banhnuoc:server:getNpcStatus', function(source, shopKey)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return nil end
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= shopConfig.job then return nil end
    return GetNpcStatus(shopKey)
end)

-- -----------------------------------------------
-- Events: thuê / hủy / rút tiền
-- -----------------------------------------------

-- Thuê / gia hạn NPC
RegisterNetEvent('xn_banhnuoc:server:hireNpc', function(shopKey, hours)
    local source = source
    if not IsBoss(source, shopKey) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi', description = 'Bạn không có quyền thuê NPC', type = 'error'
        })
        return
    end

    hours = math.max(1, math.min(hours, Config.NpcSettings and Config.NpcSettings.maxHours or 24))
    local pricePerHour = Config.NpcSettings and Config.NpcSettings.pricePerHour or 5000
    local totalCost    = pricePerHour * hours

    local player = exports.qbx_core:GetPlayer(source)
    if player.PlayerData.money.cash < totalCost then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = string.format('Không đủ tiền. Cần %s$', lib.math.groupdigits(totalCost)),
            type = 'error'
        })
        return
    end

    player.Functions.RemoveMoney('cash', totalCost, 'npc-hire-' .. shopKey)

    if not npcShopData[shopKey] then
        npcShopData[shopKey] = { remaining_time = 0, offline_revenue = 0 }
    end
    
    local addSeconds = hours * 3600
    npcShopData[shopKey].remaining_time = (npcShopData[shopKey].remaining_time or 0) + addSeconds
    SaveNpcData(shopKey)

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Thành công',
        description = string.format('NPC sẽ bán hàng trong %d giờ (chỉ trừ giờ khi offline). Đã trừ %s$', hours, lib.math.groupdigits(totalCost)),
        type = 'success'
    })
    TriggerClientEvent('xn_banhnuoc:client:npcStatusUpdate', source, shopKey, GetNpcStatus(shopKey))
end)

-- Hủy thuê NPC
RegisterNetEvent('xn_banhnuoc:server:cancelNpc', function(shopKey)
    local source = source
    if not IsBoss(source, shopKey) then return end

    if not npcShopData[shopKey] then
        npcShopData[shopKey] = { remaining_time = 0, offline_revenue = 0 }
    end
    npcShopData[shopKey].remaining_time = 0
    SaveNpcData(shopKey)

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Đã hủy', description = 'Đã hủy thuê NPC bán hàng', type = 'info'
    })
    TriggerClientEvent('xn_banhnuoc:client:npcStatusUpdate', source, shopKey, GetNpcStatus(shopKey))
end)

-- Rút doanh thu offline vào quỹ doanh nghiệp
RegisterNetEvent('xn_banhnuoc:server:withdrawRevenue', function(shopKey)
    local source = source
    if not IsBoss(source, shopKey) then return end

    local d = npcShopData[shopKey]
    if not d or d.offline_revenue <= 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Thông báo', description = 'Không có doanh thu để rút', type = 'info'
        })
        return
    end

    local amount        = d.offline_revenue
    d.offline_revenue   = 0
    SaveNpcData(shopKey)

    local shopConfig = Config.Shops[shopKey]
    exports['Renewed-Banking']:addAccountMoney(shopConfig.job, amount)

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Rút tiền thành công',
        description = string.format('Đã chuyển %s$ vào quỹ doanh nghiệp', lib.math.groupdigits(amount)),
        type = 'success'
    })
    TriggerClientEvent('xn_banhnuoc:client:npcStatusUpdate', source, shopKey, GetNpcStatus(shopKey))
end)

-- -----------------------------------------------
-- Event: khách mua trực tiếp từ NPC
-- -----------------------------------------------
RegisterNetEvent('xn_banhnuoc:server:buyFromNpc', function(shopKey, orderItems)
    local source     = source
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end

    if not IsNpcSelling(shopKey) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi', description = 'NPC hiện không bán hàng', type = 'error'
        })
        return
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local sellStashId = shopKey .. '_sell'
    local totalPrice  = 0
    local validItems  = {}

    for _, item in ipairs(orderItems) do
        local price = GetItemPrice and GetItemPrice(shopKey, item.name) or (shopConfig.items and shopConfig.items[item.name])
        if price then
            local stock = GetStashCount(sellStashId, item.name)
            if stock >= item.quantity then
                totalPrice = totalPrice + (price * item.quantity)
                validItems[#validItems + 1] = {
                    name     = item.name,
                    label    = item.label,
                    quantity = item.quantity,
                    price    = price
                }
            end
        end
    end

    if #validItems == 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Hết hàng', description = 'Kho hiện không có hàng', type = 'error'
        })
        return
    end

    if player.PlayerData.money.cash < totalPrice then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = string.format('Không đủ tiền. Cần %s$', lib.math.groupdigits(totalPrice)),
            type = 'error'
        })
        return
    end

    -- Thực hiện giao dịch
    player.Functions.RemoveMoney('cash', totalPrice, 'npc-buy-' .. shopKey)

    for _, item in ipairs(validItems) do
        exports.ox_inventory:RemoveItem(sellStashId, item.name, item.quantity)
        exports.ox_inventory:AddItem(source, item.name, item.quantity)
    end

    -- Cộng vào doanh thu offline
    if not npcShopData[shopKey] then
        npcShopData[shopKey] = { expires_at = 0, offline_revenue = 0 }
    end
    npcShopData[shopKey].offline_revenue = npcShopData[shopKey].offline_revenue + totalPrice
    SaveNpcData(shopKey)

    -- Refresh shop display
    TriggerEvent('rep_shop:server:lamMoiShop', shopKey)

    -- Discord log
    local customerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    print(string.format("[xn_banhnuoc] NPC sale | shop: %s | buyer: %s | total: %d$", shopKey, customerName, totalPrice))

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Mua hàng thành công',
        description = string.format('Đã mua hàng với tổng %s$', lib.math.groupdigits(totalPrice)),
        type = 'success'
    })
end)
