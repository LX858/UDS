-- =============================================
--  xn_quandudu | SERVER
-- =============================================

local QBX = exports.qbx_core

-- -----------------------------------------------
-- Hàm tiện ích gửi notify về client
-- -----------------------------------------------
local function notify(src, title, desc, ntype)
    TriggerClientEvent('xn_quandudu:client:notify', src, {
        title       = title,
        description = desc,
        type        = ntype or 'inform',
    })
end

-- =============================================
-- EVENT: Sấy lá đu đủ
-- Config.Say.InputAmount ladudu_tuoi → Config.Say.OutputAmount ladudu_kho
-- =============================================
RegisterNetEvent('xn_quandudu:server:sayLaDuDu', function(index)
    local src    = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end

    -- Xác thực vị trí và khoảng cách
    local loc = Config.Locations[index]
    if not loc then
        notify(src, 'Sấy lá đu đủ', 'Vị trí sấy không hợp lệ!', 'error')
        return
    end

    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - loc.TargetCoords)
    if distance > 10.0 then
        notify(src, 'Sấy lá đu đủ', 'Bạn ở quá xa vị trí sấy!', 'error')
        return
    end

    local cfg     = Config.Say
    local item    = exports.ox_inventory:GetItem(src, cfg.InputItem, nil, false)
    local count   = item and item.count or 0

    -- Phải có ít nhất Config.Say.InputAmount
    if count < cfg.InputAmount then
        notify(src, 'Sấy lá đu đủ',
            ('Bạn cần ít nhất %d %s! (Hiện có: %d)'):format(cfg.InputAmount, cfg.InputItem, count),
            'error')
        return
    end

    -- Tính số lần quy đổi (sấy 1 lần duy nhất)
    local useAmount = cfg.InputAmount
    local getAmount = cfg.OutputAmount

    if not exports.ox_inventory:RemoveItem(src, cfg.InputItem, useAmount) then
        notify(src, 'Sấy lá đu đủ', 'Lỗi khi lấy vật phẩm, thử lại sau!', 'error')
        return
    end

    exports.ox_inventory:AddItem(src, cfg.OutputItem, getAmount)

    Player.Functions.SetMetaData("stress", 1.0)

    notify(src, 'Sấy lá đu đủ',
        ('Sấy thành công! -%d %s → +%d %s'):format(useAmount, cfg.InputItem, getAmount, cfg.OutputItem),
        'success')

    print(('[xn_quandudu] %s (ID:%s) sấy %d %s → %d %s tại vị trí %d'):format(
        GetPlayerName(src), src, useAmount, cfg.InputItem, getAmount, cfg.OutputItem, index))
end)

-- =============================================
-- EVENT: Đóng gói lá đu đủ
-- Config.DongGoi.InputAmount ladudu_kho → Config.DongGoi.OutputAmount dieududu
-- =============================================
RegisterNetEvent('xn_quandudu:server:dongGoiLaDuDu', function(index)
    local src    = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end

    -- Xác thực vị trí và khoảng cách
    local loc = Config.Locations[index]
    if not loc then
        notify(src, 'Đóng gói lá đu đủ', 'Vị trí đóng gói không hợp lệ!', 'error')
        return
    end

    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - loc.TargetCoords)
    if distance > 10.0 then
        notify(src, 'Đóng gói lá đu đủ', 'Bạn ở quá xa vị trí đóng gói!', 'error')
        return
    end

    local cfg   = Config.DongGoi
    local item  = exports.ox_inventory:GetItem(src, cfg.InputItem, nil, false)
    local count = item and item.count or 0

    -- Phải có ít nhất Config.DongGoi.InputAmount
    if count < cfg.InputAmount then
        notify(src, 'Đóng gói lá đu đủ',
            ('Bạn cần ít nhất %d %s! (Hiện có: %d)'):format(cfg.InputAmount, cfg.InputItem, count),
            'error')
        return
    end

    -- Tính số lần quy đổi (đóng gói 1 lần duy nhất)
    local useAmount = cfg.InputAmount
    local getAmount = cfg.OutputAmount

    if not exports.ox_inventory:RemoveItem(src, cfg.InputItem, useAmount) then
        notify(src, 'Đóng gói lá đu đủ', 'Lỗi khi lấy vật phẩm, thử lại sau!', 'error')
        return
    end

    exports.ox_inventory:AddItem(src, cfg.OutputItem, getAmount)

    Player.Functions.SetMetaData("stress", 1.0)

    notify(src, 'Đóng gói lá đu đủ',
        ('Đóng gói thành công! -%d %s → +%d %s'):format(useAmount, cfg.InputItem, getAmount, cfg.OutputItem),
        'success')

    print(('[xn_quandudu] %s (ID:%s) đóng gói %d %s → %d %s tại vị trí %d'):format(
        GetPlayerName(src), src, useAmount, cfg.InputItem, getAmount, cfg.OutputItem, index))
end)
