local QBCore = exports['qb-core']:GetCoreObject()

-- Bảng cấu hình phần thưởng cho 3 gói quà xã đoàn
local GANG_BOXES = {
    ['qua_gang_1'] = {
        label = 'Gói Quà Xã Đoàn I',
        wrenches = 3,
        bandage = 100,
        armor = 50,
        vehicle = 'xe_gang_1',
    },
    ['qua_gang_2'] = {
        label = 'Gói Quà Xã Đoàn II',
        wrenches = 6,
        bandage = 200,
        armor = 100,
        vehicle = 'xe_gang_2',
    },
    ['qua_gang_3'] = {
        label = 'Gói Quà Xã Đoàn III',
        wrenches = 10,
        bandage = 500,
        armor = 200,
        vehicle = 'xe_gang_3',
    },
}

--- Hàm tạo mã Serial dạng HTXXXXXXX (HT + 7 ký tự ngẫu nhiên gồm số & chữ in hoa)
local function GenerateHTSerial()
    local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local serial = "HT"
    for _ = 1, 7 do
        local rand = math.random(1, #charset)
        serial = serial .. charset:sub(rand, rand)
    end
    return serial
end

-- Đăng ký Usable Item cho cả qbx_core và qb-core
for itemName, boxData in pairs(GANG_BOXES) do
    if exports.qbx_core and exports.qbx_core.CreateUseableItem then
        exports.qbx_core:CreateUseableItem(itemName, function(source, item)
            TriggerClientEvent('xn_gangbox:client:useBox', source, itemName)
        end)
    end

    if QBCore and QBCore.Functions and QBCore.Functions.CreateUseableItem then
        QBCore.Functions.CreateUseableItem(itemName, function(source, item)
            TriggerClientEvent('xn_gangbox:client:useBox', source, itemName)
        end)
    end
end

-- Xử lý mở gói quà sau khi hoàn thành progress bar
RegisterNetEvent('xn_gangbox:server:openBox', function(itemName)
    local src = source
    local boxData = GANG_BOXES[itemName]
    if not boxData then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Kiểm tra người chơi có sở hữu vật phẩm gói quà không
    local itemCount = exports.ox_inventory:GetItem(src, itemName, nil, true)
    if not itemCount or itemCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Bạn không có ' .. boxData.label .. ' trong túi đồ!'
        })
        return
    end

    local citizenid = Player.PlayerData and Player.PlayerData.citizenid
    if not citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không tìm thấy thông tin CitizenID của bạn!'
        })
        return
    end

    -- Xóa 1 gói quà khỏi túi đồ người chơi
    local removed = exports.ox_inventory:RemoveItem(src, itemName, 1)
    if not removed then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không thể xóa ' .. boxData.label .. '!'
        })
        return
    end

    -- 1. Chuyển weapon_wrench vào Bưu Cục (mỗi cây 1 serial độc nhất HTXXXXXXX và DoHiem: "Common")
    for i = 1, boxData.wrenches do
        local wrenchSerial = GenerateHTSerial()
        local wrenchMetadata = {
            serial = wrenchSerial,
            DoHiem = "Common",
            durability = 100,
        }
        exports.xn_buucuc:AddItemToPersonalStorage(citizenid, 'weapon_wrench', 1, wrenchMetadata)
    end

    -- 2. Chuyển bandage_lv2 vào Bưu Cục
    if boxData.bandage and boxData.bandage > 0 then
        exports.xn_buucuc:AddItemToPersonalStorage(citizenid, 'bandage_lv2', boxData.bandage, {})
    end

    -- 3. Chuyển ao_giap_gang_lv1 vào Bưu Cục
    if boxData.armor and boxData.armor > 0 then
        exports.xn_buucuc:AddItemToPersonalStorage(citizenid, 'ao_giap_gang_lv1', boxData.armor, {})
    end

    -- 4. Chuyển vé xe gang vào Bưu Cục
    if boxData.vehicle then
        exports.xn_buucuc:AddItemToPersonalStorage(citizenid, boxData.vehicle, 1, {})
    end

    -- Thông báo thành công
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = ('Đã mở %s! Phần thưởng (%dx Cờ Lê, %dx Băng Gạc LV2, %dx Giáp Gang LV1, 1x %s) đã được gửi vào Bưu Cục!'):format(
            boxData.label,
            boxData.wrenches,
            boxData.bandage,
            boxData.armor,
            boxData.vehicle
        )
    })

    -- Log console
    print(('[xn_gangbox] Player %s (CID: %s, ID: %d) đã mở %s và nhận thưởng vào Bưu Cục'):format(
        GetPlayerName(src),
        citizenid,
        src,
        boxData.label
    ))
end)

