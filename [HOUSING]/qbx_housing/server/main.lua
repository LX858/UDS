local QBX = exports.qbx_core
local playerHouses = {} -- Cache player ownership {[houseId] = {citizenid, owner_name, keys}}
local allHouses = {} -- Cache tất cả houses từ database {[houseId] = {id, type, door, interior, ...}}
local houseBuckets = {} -- Bucket cho mỗi nhà {[houseId] = bucketId}
local playersInHouse = {} -- Track players trong nhà {[source] = houseId}
local houseOccupants = {} -- Track ai đang ở nhà nào {[houseId] = {source1, source2, ...}}

-- Function tạo bucket ID từ houseId (deterministic - luôn giống nhau cho cùng 1 nhà)
local function GetHouseBucket(houseId)
    if not houseId then return 0 end
    local strHouseId = tostring(houseId)
    if not houseBuckets[strHouseId] then
        -- Tạo bucket ID từ hash của houseId (range: 1000-99999 để tránh conflict)
        local hash = 0
        for i = 1, #strHouseId do
            hash = hash + string.byte(strHouseId, i)
        end
        houseBuckets[strHouseId] = 1000 + (hash % 98999) -- Bucket range: 1000-99999
        
        -- CRITICAL: Set bucket entity lockdown mode ngay khi tạo bucket
        SetRoutingBucketEntityLockdownMode(houseBuckets[strHouseId], 'relaxed')
    end
    return houseBuckets[strHouseId]
end

-- Function set player bucket
local function SetPlayerBucket(source, bucketId)
    local src = tonumber(source)
    if not src then return end
    bucketId = tonumber(bucketId) or 0
    
    local oldBucket = GetPlayerRoutingBucket(src)
    if oldBucket ~= bucketId then
        SetPlayerRoutingBucket(src, bucketId)
        if QBX and QBX.SetPlayerBucket then
            pcall(function() QBX.SetPlayerBucket(QBX, src, bucketId) end)
        end
        
        -- CRITICAL: Ensure bucket mode is set (in case it wasn't set before)
        if bucketId > 0 then
            SetRoutingBucketEntityLockdownMode(bucketId, 'relaxed')
        end
    end
end

CreateThread(function()
    -- Load tất cả houses từ database VÀO CACHE
    LoadAllHousesFromDB()
    
    -- Load ownership data
    LoadAllHouses()
end)

-- Load TẤT CẢ houses từ database (thay thế Config.Houses)

function GetGangHouseInterior(level)
    local lvl = tonumber(level) or 1
    if Config.GangHouseLevels and Config.GangHouseLevels[lvl] and Config.GangHouseLevels[lvl].interior then
        return Config.GangHouseLevels[lvl].interior
    end
    if lvl == 2 then
        return vector4(-31.4107, -595.1233, 80.0309, 244.8473)
    elseif lvl >= 3 then
        return vector4(342.2681, 437.8397, 149.3809, 105.3746)
    else
        return vector4(346.60, -1012.87, -99.20, 0.0)
    end
end

function GetGangHouseStashCoords(level)
    local lvl = tonumber(level) or 1
    if Config.GangHouseLevels and Config.GangHouseLevels[lvl] and Config.GangHouseLevels[lvl].stashCoords then
        return Config.GangHouseLevels[lvl].stashCoords
    end
    if lvl == 2 then
        return vector3(-12.889921188354, -596.69024658203, 79.556922912598)
    elseif lvl >= 3 then
        return vector3(338.62582397461, 437.19735717773, 142.03758239746)
    else
        return vector3(352.56, -998.95, -99.64)
    end
end

function LoadAllHousesFromDB()
    pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `player_juicer_purchased` (
                `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
                `purchased` TINYINT(1) NOT NULL DEFAULT 0,
                `purchased_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
                KEY `idx_citizenid` (`citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]])
        MySQL.query.await('ALTER TABLE `houses` ADD COLUMN IF NOT EXISTS `gang` VARCHAR(50) DEFAULT NULL COMMENT "Mã Xã Đoàn sở hữu nhà"')
        MySQL.query.await('ALTER TABLE `houses` ADD COLUMN IF NOT EXISTS `blip_color` INT DEFAULT 1 COMMENT "Màu blip GTA ID"')
        MySQL.query.await('ALTER TABLE `houses` ADD COLUMN IF NOT EXISTS `level` INT DEFAULT 1 COMMENT "Cấp độ nhà gang (1, 2, 3)"')
        MySQL.query.await('UPDATE `houses` SET `interior_x` = 346.60, `interior_y` = -1012.87, `interior_z` = -99.20 WHERE `gang` IS NOT NULL AND `gang` != "" AND `gang` != "none"')
    end)
    local result = MySQL.query.await('SELECT * FROM houses WHERE enabled = 1')
    if result then
        for _, house in ipairs(result) do
            local extraData = house.extra_data and json.decode(house.extra_data) or {}
            
            local houseLevel = tonumber(house.level) or 1
            local isGang = (house.gang and house.gang ~= '' and house.gang ~= 'none') or (house.type == 'gang')
            local interiorCoords = isGang and GetGangHouseInterior(houseLevel) or vector3(house.interior_x, house.interior_y, house.interior_z)
            local storageCoords = isGang and GetGangHouseStashCoords(houseLevel) or vector3(house.storage_x, house.storage_y, house.storage_z)

            allHouses[house.id] = {
                id = house.id,
                type = house.type,
                label = house.label,
                price = house.price,
                gang = (house.gang and house.gang ~= '' and house.gang ~= 'none') and house.gang or nil,
                level = houseLevel,
                blipColor = tonumber(house.blip_color) or 1,
                door = vector3(house.door_x, house.door_y, house.door_z),
                interior = interiorCoords,
                storagePoint = storageCoords,
                juicerPoint = (house.juicer_x and house.juicer_y and house.juicer_z) and vector3(house.juicer_x, house.juicer_y, house.juicer_z) or nil,
                packagingPoint = (house.packaging_x and house.packaging_y and house.packaging_z) and vector3(house.packaging_x, house.packaging_y, house.packaging_z) or nil,
                exitPoint = vector3(house.exit_x, house.exit_y, house.exit_z),
                garagePoint = vector3(house.garage_x, house.garage_y, house.garage_z),
                garageSpawn = vector4(house.spawn_x, house.spawn_y, house.spawn_z, house.spawn_h),
                bedPoint = (house.bed_x and house.bed_y and house.bed_z) and vector4(house.bed_x, house.bed_y, house.bed_z, house.bed_w or 0.0) or nil,
                juicerPurchased = house.juicer_purchased == 1 or house.juicer_purchased == true,
                apartmentNumber = extraData.apartmentNumber,
                homestayNumber = extraData.homestayNumber
            }
            allHouses[tostring(house.id)] = allHouses[house.id]
        end
        --print('[QBX Housing] Loaded ' .. #result .. ' houses from database')
    end
end

-- Load ownership data
function LoadAllHouses()
    local result = MySQL.query.await('SELECT * FROM player_houses')
    if result then
        for _, house in ipairs(result) do
            playerHouses[tostring(house.house_id)] = {
                citizenid = house.citizenid,
                owner_name = house.owner_name,
                price = house.price,
                keys = json.decode(house.keys) or {}
            }
            playerHouses[house.house_id] = playerHouses[tostring(house.house_id)]
        end
        --print('[QBX Housing] Loaded ' .. #result .. ' owned houses')
    end
end

-- Lấy thông tin ownership
function GetHouseData(houseId)
    if not houseId then return nil end
    local strId = tostring(houseId)
    return playerHouses[strId] or playerHouses[tonumber(houseId)] or playerHouses[houseId]
end

-- Lấy config của house TỪ DATABASE CACHE (thay thế Config.Houses)
function GetHouseConfig(houseId)
    if not houseId then return nil end
    local strId = tostring(houseId)
    return allHouses[strId] or allHouses[tonumber(houseId)] or allHouses[houseId]
end

-- Kiểm tra xem player có sở hữu house không
function IsOwner(citizenid, houseId)
    local houseConfig = GetHouseConfig(houseId)
    if houseConfig and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none' then
        local player = QBX:GetPlayerByCitizenId(citizenid)
        if player and player.PlayerData.gang and player.PlayerData.gang.name == houseConfig.gang then
            return true
        end
        return false
    end
    
    local house = GetHouseData(houseId)
    if not house then return false end
    return house.citizenid == citizenid
end

-- Kiểm tra xem player có keys không
function HasKeys(citizenid, houseId)
    local houseConfig = GetHouseConfig(houseId)
    if houseConfig and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none' then
        local player = QBX:GetPlayerByCitizenId(citizenid)
        if player and player.PlayerData.gang and player.PlayerData.gang.name == houseConfig.gang then
            return true
        end
        return false
    end
    
    local house = GetHouseData(houseId)
    if not house then return false end
    
    if house.citizenid == citizenid then return true end
    
    for _, key in ipairs(house.keys or {}) do
        if key == citizenid then return true end
    end
    
    return false
end

-- Lấy house data (cho blips)
lib.callback.register('qbx_housing:server:getHouseData', function(source, houseId)
    return GetHouseData(houseId)
end)

-- Lấy TẤT CẢ house data (tối ưu cho blips - 1 call thay vì N calls)
lib.callback.register('qbx_housing:server:getAllHousesData', function(source)
    return playerHouses -- Return toàn bộ table {[houseId] = {citizenid, owner_name, keys}}
end)

-- Lấy TẤT CẢ houses config (cho client tạo blips + interactions)
lib.callback.register('qbx_housing:server:getAllHouses', function(source)
    local housesList = {}
    for _, house in pairs(allHouses) do
        table.insert(housesList, house)
    end
    return housesList
end)

-- Lấy thông tin nhà cho NUI
lib.callback.register('qbx_housing:server:getHouseInfo', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return nil end
    
    -- Lấy house config (luôn có, từ cache hoặc DB)
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then 
        --print('[QBX Housing] House config not found: ' .. houseId)
        return nil 
    end
    
    -- Lấy ownership data (có thể null nếu chưa mua)
    local houseData = GetHouseData(houseId)
    
    -- Get price: use custom price from houses table OR fallback to Config.HouseTypes price
    local houseType = Config.HouseTypes[houseConfig.type]
    local price = houseConfig.price or (houseType and houseType.price) or 0
    
    -- Xử lý nếu là nhà Xã Đoàn
    if houseConfig.gang then
        local playerGang = player.PlayerData.gang and player.PlayerData.gang.name
        local playerGangGrade = player.PlayerData.gang and player.PlayerData.gang.grade
        local gradeLevel = 0
        if type(playerGangGrade) == 'table' then
            gradeLevel = playerGangGrade.level or 0
        elseif type(playerGangGrade) == 'number' then
            gradeLevel = playerGangGrade
        end
        
        local isMember = (playerGang == houseConfig.gang)
        local isBoss = isMember and (gradeLevel >= 3 or (player.PlayerData.gang and player.PlayerData.gang.isboss == true))
        
        -- Lấy gang label từ qbx_core
        local gangLabel = houseConfig.gang
        local success, gangData = pcall(function()
            return exports.qbx_core:GetGang(houseConfig.gang)
        end)
        if success and gangData and gangData.label and gangData.label ~= '' then
            gangLabel = gangData.label
        elseif isMember and player.PlayerData.gang and player.PlayerData.gang.label then
            gangLabel = player.PlayerData.gang.label
        end
        
        local robberyInfo = nil
        pcall(function()
            if GetResourceState('xn_ganghouserob') == 'started' then
                robberyInfo = exports.xn_ganghouserob:GetHouseRobberyInfo(houseId, source)
            end
        end)

        return {
            isGangHouse = true,
            gang = houseConfig.gang,
            gangLabel = gangLabel,
            isGangMember = isMember,
            isBoss = isBoss,
            gangGrade = gradeLevel,
            isOwner = isBoss, -- Chỉ boss cấp >= 3 mới có quyền quản lý
            hasKeys = isMember,
            isOwned = true,
            owner_name = 'Xã Đoàn: ' .. gangLabel,
            price = price,
            robbery = robberyInfo
        }
    end
    
    if houseData then
        -- Nhà đã có chủ
        return {
            isGangHouse = false,
            owner_name = houseData.owner_name,
            isOwner = houseData.citizenid == player.PlayerData.citizenid,
            hasKeys = HasKeys(player.PlayerData.citizenid, houseId),
            price = price
        }
    else
        -- Nhà trống, chưa có chủ
        return {
            isGangHouse = false,
            owner_name = nil,
            isOwner = false,
            hasKeys = false,
            price = price
        }
    end
end)

-- Mua nhà
lib.callback.register('qbx_housing:server:buyHouse', function(source, houseId, paymentType)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Không tìm thấy player' end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then return false, 'Không tìm thấy nhà' end
    
    if houseConfig.gang then
        return false, 'Căn nhà này thuộc sở hữu của Xã Đoàn, không thể mua bán!'
    end
    
    local houseData = GetHouseData(houseId)
    if houseData then return false, 'Nhà này đã có người sở hữu' end
    
    local houseType = Config.HouseTypes[houseConfig.type]
    if not houseType then return false, 'Loại nhà không hợp lệ' end
    
    -- Get price: use custom price from houses table OR fallback to Config.HouseTypes price
    local price = tonumber(houseConfig.price) or tonumber(houseType.price)
    if not price or price <= 0 then
        return false, 'Giá nhà không hợp lệ'
    end
    
    local bankMoney = player.Functions.GetMoney('bank') or (player.PlayerData.money and player.PlayerData.money.bank) or 0
    local cashMoney = player.Functions.GetMoney('cash') or (player.PlayerData.money and player.PlayerData.money.cash) or 0
    local deductedMethod = nil
    
    if paymentType == 'cash' then
        if cashMoney >= price then
            if player.Functions.RemoveMoney('cash', price, 'house-purchase') then
                deductedMethod = 'tiền mặt'
            else
                return false, 'Không thể trừ tiền mặt từ bạn'
            end
        else
            return false, ('Bạn không đủ tiền mặt! Cần $%s nhưng bạn chỉ có $%s tiền mặt'):format(price, cashMoney)
        end
    elseif paymentType == 'bank' then
        if bankMoney >= price then
            if player.Functions.RemoveMoney('bank', price, 'house-purchase') then
                deductedMethod = 'chuyển khoản ngân hàng'
            else
                return false, 'Không thể trừ tiền trong tài khoản ngân hàng'
            end
        else
            return false, ('Bạn không đủ tiền trong ngân hàng! Cần $%s nhưng bạn chỉ có $%s trong tài khoản'):format(price, bankMoney)
        end
    else
        -- Tự động kiểm tra nếu paymentType không xác định: ưu tiên bank, sau đó đến cash
        if bankMoney >= price then
            if player.Functions.RemoveMoney('bank', price, 'house-purchase') then
                deductedMethod = 'chuyển khoản ngân hàng'
            end
        elseif cashMoney >= price then
            if player.Functions.RemoveMoney('cash', price, 'house-purchase') then
                deductedMethod = 'tiền mặt'
            end
        end
        
        if not deductedMethod then
            return false, ('Bạn không có đủ tiền để mua nhà! Cần: $%s (Ngân hàng: $%s, Tiền mặt: $%s)'):format(price, bankMoney, cashMoney)
        end
    end
    
    MySQL.insert('INSERT INTO player_houses (house_id, citizenid, owner_name, price) VALUES (?, ?, ?, ?)',
        {houseId, player.PlayerData.citizenid, player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname, price})
    
    playerHouses[houseId] = {
        citizenid = player.PlayerData.citizenid,
        owner_name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        price = price,
        keys = {}
    }
    
    -- Tạo stash cho nhà
    CreateHouseStash(houseId, houseConfig.type)
    
    -- Tạo garage với MLO interior từ mh_garage (ĐỒNG BỘ - đợi hoàn thành trước khi return)
    if GetResourceState('mh_garage') == 'started' then
        local garageCreated = CreateHouseGarage(source, houseId, houseConfig, houseType)
        if not garageCreated then
            print('^1[QBX Housing]^7 WARNING: Failed to create garage for house ' .. houseId)
        end
    end
    
    -- Update blip color cho tất cả players
    TriggerClientEvent('qbx_housing:client:updateBlipColor', -1, houseId, player.PlayerData.citizenid)
    
    -- Real-time sync to all clients & open NUIs
    TriggerClientEvent('qbx_housing:client:syncHouseData', -1, houseId, {
        owner = player.PlayerData.citizenid,
        owner_name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        price = price
    })
    
    return true, ('Bạn đã mua nhà thành công bằng %s với giá $%s'):format(deductedMethod, price)
end)

-- Bán nhà cho người chơi khác
-- Kiểm tra và xóa hợp đồng bán nhà
lib.callback.register('qbx_housing:server:checkSellContract', function(source, houseId)
    local seller = QBX:GetPlayer(source)
    if not seller then return false, 'Không tìm thấy người bán' end
    
    -- Check if seller is owner
    if not IsOwner(seller.PlayerData.citizenid, houseId) then
        return false, 'Bạn không phải chủ nhà'
    end
    
    -- Check if garage has any vehicles (TRƯỚC KHI kiểm tra hợp đồng)
    local garageName = 'house_' .. houseId
    local vehiclesInGarage = MySQL.query.await('SELECT COUNT(*) as count FROM player_vehicles WHERE citizenid = ? AND garage = ? AND state = 1', {
        seller.PlayerData.citizenid,
        garageName
    })
    
    if vehiclesInGarage and vehiclesInGarage[1] and vehiclesInGarage[1].count > 0 then
        return false, 'Bạn cần lấy hết xe ra khỏi garage trước khi bán nhà (Còn ' .. vehiclesInGarage[1].count .. ' xe trong garage)'
    end
    
    -- Check if seller has hopdongbannha item
    local hasItem = exports.ox_inventory:Search(source, 'count', 'hopdongbannha')
    
    if not hasItem or hasItem < 1 then
        return false, 'Bạn thiếu hợp đồng để bán căn nhà này'
    end
    
    return true, 'Hợp đồng hợp lệ'
end)

-- Gửi đề nghị bán nhà đến người mua
lib.callback.register('qbx_housing:server:sellHouseToPlayer', function(source, houseId, buyerId, sellPrice)
    local seller = QBX:GetPlayer(source)
    if not seller then return false, 'Không tìm thấy người bán' end
    
    local buyer = QBX:GetPlayer(buyerId)
    if not buyer then return false, 'Không tìm thấy người mua' end
    
    -- Check if seller is owner
    if not IsOwner(seller.PlayerData.citizenid, houseId) then
        return false, 'Bạn không phải chủ nhà'
    end
    
    -- Validate price range
    if sellPrice < 500000 or sellPrice > 10000000 then
        return false, 'Giá bán không hợp lệ'
    end
    
    -- Check if buyer has enough cash
    local buyerMoney = buyer.Functions.GetMoney('cash')
    if buyerMoney < sellPrice then
        return false, 'Người mua không đủ tiền mặt (Cần: $' .. sellPrice .. ', Có: $' .. buyerMoney .. ')'
    end
    
    -- Get house config for label
    local houseConfig = GetHouseConfig(houseId)
    local houseLabel = houseConfig and Config.HouseTypes[houseConfig.type].label or 'Nhà'
    
    -- Send offer to buyer
    TriggerClientEvent('qbx_housing:client:receiveHousePurchaseOffer', buyerId, {
        houseId = houseId,
        sellerId = source,
        sellerName = seller.PlayerData.charinfo.firstname .. ' ' .. seller.PlayerData.charinfo.lastname,
        houseLabel = houseLabel,
        price = sellPrice
    })
    
    return true, 'Đã gửi đề nghị bán nhà đến ' .. buyer.PlayerData.charinfo.firstname .. '. Đang chờ xác nhận...'
end)

-- Xác nhận mua nhà (sau khi người mua đồng ý)
lib.callback.register('qbx_housing:server:confirmHousePurchase', function(source, houseId, sellerId, sellPrice)
    local buyer = QBX:GetPlayer(source)
    if not buyer then return false, 'Không tìm thấy người mua' end
    
    local seller = QBX:GetPlayer(sellerId)
    if not seller then return false, 'Người bán đã offline' end
    
    -- Verify seller is still owner
    if not IsOwner(seller.PlayerData.citizenid, houseId) then
        return false, 'Người bán không còn là chủ nhà'
    end
    
    -- Check buyer still has enough cash
    local buyerMoney = buyer.Functions.GetMoney('cash')
    if buyerMoney < sellPrice then
        return false, 'Bạn không đủ tiền mặt (Cần: $' .. sellPrice .. ', Có: $' .. buyerMoney .. ')'
    end
    
    -- Remove money from buyer
    if not buyer.Functions.RemoveMoney('cash', sellPrice, 'house-purchase-from-player') then
        return false, 'Không thể trừ tiền từ bạn'
    end
    
    -- Add money to seller
    seller.Functions.AddMoney('cash', sellPrice, 'house-sale-to-player')
    
    -- Update house ownership
    MySQL.query('UPDATE player_houses SET citizenid = ?, owner_name = ?, price = ?, `keys` = ? WHERE house_id = ?', {
        buyer.PlayerData.citizenid,
        buyer.PlayerData.charinfo.firstname .. ' ' .. buyer.PlayerData.charinfo.lastname,
        sellPrice,
        '[]', -- Reset shared keys to empty array
        houseId
    })
    
    -- Update cache
    playerHouses[houseId] = {
        citizenid = buyer.PlayerData.citizenid,
        owner_name = buyer.PlayerData.charinfo.firstname .. ' ' .. buyer.PlayerData.charinfo.lastname,
        price = sellPrice,
        keys = {} -- Reset shared keys
    }
    
    -- Update garage owner nếu mh_garage đang chạy
    if GetResourceState('mh_garage') == 'started' then
        TriggerEvent('qbx_housing:server:TransferHouseGarage', houseId, buyer.PlayerData.citizenid)
    end
    
    -- Update blip color cho tất cả players
    TriggerClientEvent('qbx_housing:client:updateBlipColor', -1, houseId, buyer.PlayerData.citizenid)
    
    -- Remove hopdongbannha item from seller after transaction completes
    exports.ox_inventory:RemoveItem(sellerId, 'hopdongbannha', 1)
    
    -- Notify seller
    TriggerClientEvent('ox_lib:notify', sellerId, {
        title = 'Bán nhà',
        description = 'Đã bán nhà cho ' .. buyer.PlayerData.charinfo.firstname .. ' với giá $' .. sellPrice,
        type = 'success'
    })
    
    return true, 'Bạn đã mua nhà với giá $' .. sellPrice .. ' từ ' .. seller.PlayerData.charinfo.firstname
end)

-- Bán nhà (callback cũ - giữ lại để tương thích)
lib.callback.register('qbx_housing:server:sellHouse', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Không tìm thấy player' end
    
    local houseConfig = GetHouseConfig(houseId)
    if houseConfig and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none' then
        return false, 'Căn nhà này thuộc sở hữu của Xã Đoàn, không thể bán!'
    end
    
    if not IsOwner(player.PlayerData.citizenid, houseId) then
        return false, 'Bạn không phải chủ nhà'
    end
    
    local houseData = GetHouseData(houseId)
    if not houseData or not houseData.price then
        return false, 'Không tìm thấy thông tin nhà'
    end
    
    local sellPrice = math.floor(houseData.price * 0.75) -- Bán lại 75% giá
    
    player.Functions.AddMoney('bank', sellPrice, 'house-sale')
    
    MySQL.query('DELETE FROM player_houses WHERE house_id = ?', {houseId})
    
    playerHouses[houseId] = nil
    
    -- Xóa garage nếu mh_garage đang chạy
    if GetResourceState('mh_garage') == 'started' then
        TriggerEvent('qbx_housing:server:DeleteHouseGarage', houseId)
    end
    
    -- Update blip color cho tất cả players (về màu tím - nhà trống)
    TriggerClientEvent('qbx_housing:client:updateBlipColor', -1, houseId, nil)
    
    return true, 'Bạn đã bán nhà thành công với giá $' .. sellPrice
end)

-- Tạo stash cho house sử dụng ox_inventory
function CreateHouseStash(houseId, houseType)
    local houseConfig = GetHouseConfig(houseId)
    local isGang = houseConfig and ((houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang')
    
    local slots = 25
    local weight = 100000
    local label = 'Kho nhà'
    
    if isGang then
        local gLevel = (houseConfig and tonumber(houseConfig.level)) or 1
        local gCfg = Config.GangHouseLevels and Config.GangHouseLevels[gLevel]
        if gCfg and gCfg.storage then
            slots = gCfg.storage.slots or 25
            weight = gCfg.storage.weight or 100000
            label = gCfg.storage.label or ('Kho Trụ Sở Cấp ' .. gLevel)
        else
            if gLevel == 2 then
                slots = 100
                weight = 1000000
                label = 'Kho Trụ Sở Cấp 2 (100 Ô - 1000KG)'
            elseif gLevel >= 3 then
                slots = 150
                weight = 1500000
                label = 'Kho Trụ Sở Cấp 3 (150 Ô - 1500KG)'
            else
                slots = 50
                weight = 500000
                label = 'Kho Trụ Sở Cấp 1 (50 Ô - 500KG)'
            end
        end
    else
        local typeConfig = Config.HouseTypes[houseType]
        local stashConfig = typeConfig and typeConfig.storage or { slots = 25, weight = 100000 }
        slots = stashConfig.slots
        weight = stashConfig.weight
        label = 'Kho nhà'
    end
    
    exports.ox_inventory:RegisterStash('house_' .. houseId, label, slots, weight, false)
end

-- Mở stash
lib.callback.register('qbx_housing:server:openStash', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    if not HasKeys(player.PlayerData.citizenid, houseId) then
        return false
    end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then return false end
    
    -- Đảm bảo stash đã được tạo
    CreateHouseStash(houseId, houseConfig.type)
    
    return true
end)

-- Lấy danh sách nhà của player
lib.callback.register('qbx_housing:server:getPlayerHouses', function(source)
    local player = QBX:GetPlayer(source)
    if not player then return {} end
    
    local houses = {}
    for houseId, data in pairs(playerHouses) do
        if data.citizenid == player.PlayerData.citizenid then
            local config = GetHouseConfig(houseId)
            if config then
                table.insert(houses, {
                    id = houseId,
                    type = config.type,
                    label = Config.HouseTypes[config.type].label,
                    door = config.door
                })
            end
        end
    end
    
    return houses
end)

-- Cho keys
lib.callback.register('qbx_housing:server:giveKeys', function(source, houseId, targetId)
    local player = QBX:GetPlayer(source)
    local target = QBX:GetPlayer(targetId)
    
    if not player or not target then return false, 'Không tìm thấy player' end
    
    local houseConfig = GetHouseConfig(houseId)
    if houseConfig and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none' then
        return false, 'Căn nhà này thuộc sở hữu của Xã Đoàn, không thể chia sẻ chìa khóa!'
    end
    
    if not IsOwner(player.PlayerData.citizenid, houseId) then
        return false, 'Bạn không phải chủ nhà'
    end
    
    local house = playerHouses[houseId]
    if not house.keys then house.keys = {} end
    
    for _, key in ipairs(house.keys) do
        if key == target.PlayerData.citizenid then
            return false, 'Người này đã có chìa khóa'
        end
    end
    
    -- Kiểm tra giới hạn số người chia sẻ chìa khóa
    local houseConfig = GetHouseConfig(houseId)
    if houseConfig then
        local houseType = Config.HouseTypes[houseConfig.type]
        if houseType and houseType.maxSharedKeys then
            if #house.keys >= houseType.maxSharedKeys then
                return false, 'Bạn đã chia sẻ chìa khóa tối đa (' .. houseType.maxSharedKeys .. ' người)'
            end
        end
    end
    
    table.insert(house.keys, target.PlayerData.citizenid)
    
    -- Lưu vào database với .await để đảm bảo dữ liệu được lưu trước khi return
    local success = MySQL.update.await('UPDATE player_houses SET `keys` = ? WHERE house_id = ?',
        {json.encode(house.keys), houseId})
    
    if success then
        return true, 'Đã cho chìa khóa thành công'
    else
        -- Rollback cache nếu lưu thất bại
        table.remove(house.keys, #house.keys)
        return false, 'Lỗi khi lưu chìa khóa vào database'
    end
end)

-- Thu hồi keys
lib.callback.register('qbx_housing:server:removeKeys', function(source, houseId, citizenid)
    local player = QBX:GetPlayer(source)
    
    if not player then return false, 'Không tìm thấy player' end
    
    local houseConfig = GetHouseConfig(houseId)
    if houseConfig and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none' then
        return false, 'Căn nhà này thuộc sở hữu của Xã Đoàn, không thể thao tác chìa khóa!'
    end
    
    if not IsOwner(player.PlayerData.citizenid, houseId) then
        return false, 'Bạn không phải chủ nhà'
    end
    
    local house = playerHouses[houseId]
    if not house.keys then return false, 'Không có keys nào' end
    
    for i, key in ipairs(house.keys) do
        if key == citizenid then
            table.remove(house.keys, i)
            
            -- Lưu vào database với .await
            local success = MySQL.update.await('UPDATE player_houses SET `keys` = ? WHERE house_id = ?',
                {json.encode(house.keys), houseId})
            
            if success then
                return true, 'Đã thu hồi chìa khóa'
            else
                -- Rollback cache nếu lưu thất bại
                table.insert(house.keys, i, citizenid)
                return false, 'Lỗi khi lưu dữ liệu vào database'
            end
        end
    end
    
    return false, 'Không tìm thấy chìa khóa'
end)

-- Lấy danh sách người có chìa khóa
lib.callback.register('qbx_housing:server:getSharedKeys', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return {} end
    
    if not IsOwner(player.PlayerData.citizenid, houseId) then
        return {}
    end
    
    local house = playerHouses[houseId]
    if not house or not house.keys or #house.keys == 0 then return {} end
    
    -- Batch query player info from database (1 query thay vì N queries)
    local placeholders = {}
    for i = 1, #house.keys do
        placeholders[i] = '?'
    end
    
    local query = string.format('SELECT citizenid, charinfo FROM players WHERE citizenid IN (%s)', table.concat(placeholders, ','))
    local playerData = MySQL.query.await(query, house.keys)
    
    local namesMap = {}
    if playerData then
        for _, row in ipairs(playerData) do
            local charinfo = row.charinfo and json.decode(row.charinfo)
            if charinfo and charinfo.firstname and charinfo.lastname then
                namesMap[row.citizenid] = charinfo.firstname .. ' ' .. charinfo.lastname
            end
        end
    end
    
    local keyList = {}
    for _, citizenid in ipairs(house.keys) do
        table.insert(keyList, {
            citizenid = citizenid,
            player_name = namesMap[citizenid] or 'Unknown Player'
        })
    end
    
    return keyList
end)

-- Kiểm tra quyền truy cập
lib.callback.register('qbx_housing:server:hasAccess', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    return HasKeys(player.PlayerData.citizenid, houseId)
end)

-- Kiểm tra có phải chủ nhà không
lib.callback.register('qbx_housing:server:isOwner', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    return IsOwner(player.PlayerData.citizenid, houseId)
end)

-- Lấy thông tin garage
lib.callback.register('qbx_housing:server:getGarageInfo', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return nil end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then return nil end
    
    local isGangMember = houseConfig.gang and player.PlayerData.gang and player.PlayerData.gang.name == houseConfig.gang
    
    -- CHỈ CHỦ NHÀ hoặc THÀNH VIÊN XÃ ĐOÀN mới được truy cập garage
    if not IsOwner(player.PlayerData.citizenid, houseId) and not isGangMember then
        return nil
    end
    if not houseConfig then return nil end
    
    local houseType = Config.HouseTypes[houseConfig.type]
    
    return {
        maxVehicles = houseType.garage.maxVehicles,
        garagePoint = houseConfig.garagePoint,
        garageSpawn = houseConfig.garageSpawn
    }
end)

-- ========== BED SYSTEM (READ-ONLY FOR PLAYERS, ADMIN SETUP ONLY) ==========

-- Lấy bed coordinates từ houses table (chỉ đọc, không cho phép chỉnh sửa)
lib.callback.register('qbx_housing:server:getBedCoords', function(source, houseId)
    local houseConfig = GetHouseConfig(houseId)
    
    if not houseConfig then return nil end
    
    -- Chỉ return bed từ houses table (admin setup)
    -- Không có custom bed cho owner
    return houseConfig.bedPoint or nil
end)

-- ========== JUICER PURCHASE SYSTEM (PLAYER-BASED) ==========


-- Safe helper kiểm tra trạng thái máy xay
local function IsJuicerPurchasedByCitizenId(citizenid)
    if not citizenid then return false end
    local success, res = pcall(function()
        return MySQL.scalar.await('SELECT purchased FROM player_juicer_purchased WHERE citizenid = ?', {citizenid})
    end)
    if success and (res == 1 or res == true) then
        return true
    end
    return false
end

-- Kiểm tra player đã mua máy xay sinh tố chưa (theo player, không theo nhà)
lib.callback.register('qbx_housing:server:checkJuicerPurchased', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    local citizenid = player.PlayerData.citizenid
    return IsJuicerPurchasedByCitizenId(citizenid)
end)

-- Function lấy coin từ database (await version)
local function GetPlayerCoinAwait(citizenid)
    local coin = MySQL.scalar.await('SELECT coin FROM players WHERE citizenid = ?', {citizenid})
    return tonumber(coin) or 0
end

-- Function trừ coin từ database (await version)
local function RemovePlayerCoinAwait(citizenid, amount)
    local currentCoin = GetPlayerCoinAwait(citizenid)
    if currentCoin < amount then
        return false
    end
    
    local newCoin = currentCoin - amount
    local affectedRows = MySQL.update.await('UPDATE players SET coin = ? WHERE citizenid = ?', {newCoin, citizenid})
    return affectedRows > 0
end

-- Mua máy xay sinh tố (500 coin) - Lưu theo player (dùng được ở mọi nhà)
lib.callback.register('qbx_housing:server:purchaseJuicer', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Không tìm thấy player' end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Kiểm tra có phải chủ nhà không
    if not IsOwner(citizenid, houseId) then
        return false, 'Chỉ chủ nhà mới có thể mua máy xay sinh tố'
    end
    
    -- Kiểm tra player đã mua chưa (query từ bảng player_juicer_purchased)
    if IsJuicerPurchasedByCitizenId(citizenid) then
        return false, 'Bạn đã mua máy xay sinh tố rồi! (Dùng được ở mọi nhà bạn sở hữu)'
    end
    
    -- Kiểm tra có đủ coin không (query trực tiếp database)
    local currentCoins = GetPlayerCoinAwait(citizenid)
    if currentCoins < 500 then
        return false, 'Không đủ coin (cần 500 coin, bạn có ' .. currentCoins .. ' coin)'
    end
    
    -- Trừ coin
    local coinRemoved = RemovePlayerCoinAwait(citizenid, 500)
    if not coinRemoved then
        return false, 'Không thể trừ coin'
    end
    
    -- Lưu vào bảng player_juicer_purchased (INSERT hoặc UPDATE)
    local success = MySQL.insert.await([[
        INSERT INTO player_juicer_purchased (citizenid, purchased, purchased_at) 
        VALUES (?, TRUE, NOW()) 
        ON DUPLICATE KEY UPDATE purchased = TRUE, purchased_at = NOW()
    ]], {citizenid})
    
    if not success then
        -- Rollback: Hoàn lại coin nếu database insert thất bại
        MySQL.update.await('UPDATE players SET coin = coin + 500 WHERE citizenid = ?', {citizenid})
        return false, 'Lỗi khi lưu dữ liệu vào database'
    end
    
    return true, 'Đã mua máy xay sinh tố thành công! (Dùng được ở mọi nhà bạn sở hữu, trừ 500 coin)'
end)

-- ========== EXPORTS ==========

-- Export functions
exports('GetHouseData', GetHouseData)
exports('GetHouseConfig', GetHouseConfig)
exports('IsOwner', IsOwner)
exports('HasKeys', HasKeys)

-- Export: Kiểm tra player đã mua máy xay sinh tố chưa (dùng cho F7_ladudu)
exports('CheckJuicerPurchased', function(source)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    local citizenid = player.PlayerData.citizenid
    return IsJuicerPurchasedByCitizenId(citizenid)
end)

-- ========== BUCKET SYSTEM ==========

-- Event: Player vào nhà
RegisterNetEvent('qbx_housing:server:enterHouse', function(houseId)
    local source = source
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then return end
    
    -- Kiểm tra quyền truy cập nếu là nhà Xã Đoàn
    if houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none' then
        if not (player.PlayerData.gang and player.PlayerData.gang.name == houseConfig.gang) then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Nhà Xã Đoàn',
                description = 'Bạn không thuộc Xã Đoàn này để vào nhà!',
                type = 'error'
            })
            return
        end
    else
        -- Kiểm tra quyền truy cập cho nhà thường
        if not HasKeys(player.PlayerData.citizenid, houseId) then
            --print('^1[QBX Housing]^7 Player ' .. source .. ' tried to enter house without keys: ' .. houseId)
            return
        end
    end
    
    -- Kiểm tra xem nhà có chủ không hoặc là nhà Xã Đoàn
    local houseData = GetHouseData(houseId)
    local bucketId
    
    if houseData or (houseConfig and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') then
        -- Nhà có chủ hoặc nhà Xã Đoàn - dùng bucket riêng của nhà
        bucketId = GetHouseBucket(houseId)
    else
        -- Nhà không chủ (realestate tour) - dùng bucket riêng của nhà để đồng bộ
        bucketId = GetHouseBucket(houseId)
    end
    
    -- Set player vào bucket
    SetPlayerBucket(source, bucketId)
    
    -- Track player trong nhà
    local strHouseId = tostring(houseId)
    playersInHouse[source] = strHouseId
    
    -- Thêm vào danh sách người trong nhà
    if not houseOccupants[strHouseId] then
        houseOccupants[strHouseId] = {}
    end
    table.insert(houseOccupants[strHouseId], source)
    
    --print('^2[QBX Housing]^7 Player ' .. source .. ' entered house ' .. houseId .. ' (bucket: ' .. bucketId .. ')')
end)

-- Event: Player ra khỏi nhà
RegisterNetEvent('qbx_housing:server:exitHouse', function(houseId)
    local source = source
    
    -- Set player về bucket mặc định (0)
    SetPlayerBucket(source, 0)
    
    -- Xóa khỏi tracking
    playersInHouse[source] = nil
    
    local strHouseId = tostring(houseId)
    -- Xóa khỏi danh sách người trong nhà
    if houseOccupants[strHouseId] then
        for i, src in ipairs(houseOccupants[strHouseId]) do
            if src == source then
                table.remove(houseOccupants[strHouseId], i)
                break
            end
        end
        
        -- Nếu không còn ai trong nhà, xóa entry
        if #houseOccupants[strHouseId] == 0 then
            houseOccupants[strHouseId] = nil
        end
    end
    
    --print('^2[QBX Housing]^7 Player ' .. source .. ' exited house ' .. houseId .. ' (bucket: 0)')
end)

-- Cleanup khi player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    local houseId = playersInHouse[source]
    
    if houseId then
        -- Xóa khỏi tracking
        playersInHouse[source] = nil
        
        local strHouseId = tostring(houseId)
        -- Xóa khỏi danh sách người trong nhà
        if houseOccupants[strHouseId] then
            for i, src in ipairs(houseOccupants[strHouseId]) do
                if src == source then
                    table.remove(houseOccupants[strHouseId], i)
                    break
                end
            end
            
            if #houseOccupants[strHouseId] == 0 then
                houseOccupants[strHouseId] = nil
            end
        end
        
        --print('^3[QBX Housing]^7 Player ' .. source .. ' disconnected from house ' .. houseId)
    end
end)

-- Callback: Lấy danh sách players trong nhà (debug)
lib.callback.register('qbx_housing:server:getHouseOccupants', function(source, houseId)
    local strHouseId = tostring(houseId)
    return houseOccupants[strHouseId] or houseOccupants[houseId] or {}
end)

-- ========== EXPORTS CHO ADMIN ==========

-- Export: Lấy array của tất cả houses
exports('GetAllHousesArray', function()
    local housesArray = {}
    for _, house in pairs(allHouses) do
        table.insert(housesArray, house)
    end
    return housesArray
end)

-- Export: Add house vào cache (khi tạo mới)
exports('AddHouseToCache', function(house)
    allHouses[house.id] = house
    --print('[Server] Added house to cache: ' .. house.id)
end)

-- Export: Update house trong cache (khi sửa)
exports('UpdateHouseInCache', function(house)
    allHouses[house.id] = house
    --print('[Server] Updated house in cache: ' .. house.id)
end)

-- Export: Remove house khỏi cache (khi xóa)
exports('RemoveHouseFromCache', function(houseId)
    allHouses[houseId] = nil
    playerHouses[houseId] = nil
    --print('[Server] Removed house from cache: ' .. houseId)
end)

-- Export: Get routing bucket for a house
exports('GetHouseBucket', function(houseId)
    return GetHouseBucket(houseId)
end)

-- Event internal: Reload từ DB
RegisterNetEvent('qbx_housing:internal:reloadFromDB', function()
    -- Clear cache
    for k in pairs(allHouses) do
        allHouses[k] = nil
    end
    
    -- Reload từ database
    LoadAllHousesFromDB()
end)
-- ========== REALESTATE CALLBACKS ==========

-- Get nearby players
lib.callback.register('qbx_housing:server:getNearbyPlayers', function(source, coords, radius)
    local nearbyPlayers = {}
    local sourcePed = GetPlayerPed(source)
    local sourceCoords = coords or GetEntityCoords(sourcePed)
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        if targetId ~= source then
            local targetPed = GetPlayerPed(targetId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(sourceCoords - targetCoords)
            
            if distance <= (radius or 5.0) then
                local player = QBX:GetPlayer(targetId)
                if player then
                    table.insert(nearbyPlayers, {
                        id = targetId, -- Server ID
                        citizenid = player.PlayerData.citizenid,
                        pid = player.PlayerData.pid,
                        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                        distance = math.floor(distance * 10) / 10
                    })
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(nearbyPlayers, function(a, b) return a.distance < b.distance end)
    
    return nearbyPlayers
end)

-- Transfer house (realestate chuyển nhượng)
lib.callback.register('qbx_housing:server:transferHouse', function(source, houseId, targetId)
    local realestate = QBX:GetPlayer(source)
    local target = QBX:GetPlayer(targetId)
    
    if not realestate or not target then 
        return false, 'Không tìm thấy player'
    end
    
    -- Check realestate job
    if realestate.PlayerData.job.name ~= 'realestate' or not realestate.PlayerData.job.onduty then
        return false, 'Bạn không phải realestate hoặc chưa onduty'
    end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then 
        return false, 'Không tìm thấy nhà'
    end
    
    local houseData = GetHouseData(houseId)
    if houseData then 
        return false, 'Nhà này đã có người sở hữu'
    end
    
    local houseType = Config.HouseTypes[houseConfig.type]
    if not houseType then 
        return false, 'Loại nhà không hợp lệ'
    end
    
    -- Use custom price from database OR fallback to Config price
    local price = houseConfig.price or houseType.price or 0
    
    -- Check target has enough cash
    if target.Functions.GetMoney('cash') < price then
        return false, 'Người mua không đủ tiền mặt'
    end
    
    -- Send transfer offer to target (they can accept/decline)
    TriggerClientEvent('qbx_housing:client:receiveTransferOffer', targetId, houseId, source, realestate.PlayerData.charinfo.firstname .. ' ' .. realestate.PlayerData.charinfo.lastname, houseConfig.label or houseId, price)
    
    return true, 'Đã gửi đề nghị chuyển nhượng'
end)

-- Accept house transfer (called from client after player confirms)
lib.callback.register('qbx_housing:server:acceptTransfer', function(source, houseId, realestateSource, price)
    local target = QBX:GetPlayer(source)
    local realestate = QBX:GetPlayer(realestateSource)
    
    if not target then 
        return false, 'Lỗi hệ thống'
    end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then 
        return false, 'Không tìm thấy nhà'
    end
    
    local houseData = GetHouseData(houseId)
    if houseData then 
        return false, 'Nhà này đã có người sở hữu'
    end
    
    local houseType = Config.HouseTypes[houseConfig.type]
    if not houseType then 
        return false, 'Loại nhà không hợp lệ'
    end
    
    -- Check target has enough cash
    if target.Functions.GetMoney('cash') < price then
        return false, 'Bạn không đủ tiền mặt'
    end
    
    -- Remove money from target (CASH not bank)
    target.Functions.RemoveMoney('cash', price, 'house-purchase')
    
    -- Give commission to realestate (10%)
    local commission = math.floor(price * 0.1)
    if realestate then
        realestate.Functions.AddMoney('cash', commission, 'realestate-commission')
    end
    
    -- Create ownership
    local success = MySQL.insert.await('INSERT INTO player_houses (citizenid, house_id, owner_name) VALUES (?, ?, ?)', {
        target.PlayerData.citizenid,
        houseId,
        target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
    })
    
    if success then
        -- Update cache
        playerHouses[houseId] = {
            citizenid = target.PlayerData.citizenid,
            owner_name = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
            keys = {}
        }
        
        -- Create garage for new owner
        if GetResourceState('mh_garage') == 'started' then
            local garageName = 'house_' .. houseId
            local garageConfig = {
                type = 'car',
                enter = houseConfig.garagePoint,
                parkVehicle = houseConfig.garagePoint,
                vehicleSpawnPoint = houseConfig.garageSpawn,
                price = nil,
                pricetakeout = 0,
                blip = { id = 0, scale = 0, colour = 0 },
                blackListClass = { 14, 15, 16, 19, 21 },
                GarageInfo = 'Garage nhà ' .. houseId,
                interior = houseType.garage.interior
            }
            exports['mh_garage']:InjectServerGarage(garageName, garageConfig)
            
            -- ONLY sync to players near the house (within 500m) or inside it
            local houseBucket = exports.qbx_housing:GetHouseBucket(houseId)
            local houseCoords = vector3(houseConfig.garagePoint.x, houseConfig.garagePoint.y, houseConfig.garagePoint.z)
            
            for _, playerId in ipairs(GetPlayers()) do
                local targetId = tonumber(playerId)
                local targetPed = GetPlayerPed(targetId)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(houseCoords - targetCoords)
                
                if distance < 500.0 or GetPlayerRoutingBucket(targetId) == houseBucket then
                    TriggerClientEvent('qbx_housing:client:SyncHouseGarage', targetId, garageName, garageConfig)
                end
            end
        end
        
        -- Update blip color & real-time sync to all clients
        TriggerClientEvent('qbx_housing:client:updateBlipColor', -1, houseId, target.PlayerData.citizenid)
        TriggerClientEvent('qbx_housing:client:syncHouseData', -1, houseId, {
            owner = target.PlayerData.citizenid,
            owner_name = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
            price = price
        })
        
        -- Notify buyer
        lib.notify(source, {
            title = 'Mua Nhà',
            description = 'Bạn đã mua ' .. (houseConfig.label or houseId) .. ' với giá $' .. price,
            type = 'success'
        })
        
        -- Notify realestate if still online
        if realestate then
            lib.notify(realestateSource, {
                title = 'Chuyển Nhượng',
                description = target.PlayerData.charinfo.firstname .. ' đã mua nhà - Hoa hồng: $' .. commission,
                type = 'success'
            })
        end
        
        return true, 'Mua nhà thành công'
    else
        -- Refund
        target.Functions.AddMoney('cash', price, 'house-purchase-refund')
        return false, 'Lỗi khi tạo ownership'
    end
end)

-- Invite player to house as OWNER (no job check)
lib.callback.register('qbx_housing:server:inviteToHouseOwner', function(source, houseId, targetId)
    local owner = QBX:GetPlayer(source)
    local target = QBX:GetPlayer(targetId)
    
    if not owner or not target then 
        return false, 'Không tìm thấy player'
    end
    
    -- Check if source is owner
    if not IsOwner(owner.PlayerData.citizenid, houseId) then
        return false, 'Bạn không phải chủ nhà'
    end
    
    -- Check if owner is inside the house
    if not playersInHouse[source] or tostring(playersInHouse[source]) ~= tostring(houseId) then
        return false, 'Bạn cần ở trong nhà để mời người khác vào nhà'
    end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then 
        return false, 'Không tìm thấy nhà'
    end
    
    -- Send invite request to target player (they can accept/decline)
    TriggerClientEvent('qbx_housing:client:receiveInvite', targetId, houseId, source, owner.PlayerData.charinfo.firstname .. ' ' .. owner.PlayerData.charinfo.lastname, houseConfig.label or tostring(houseId))
    
    return true, 'Đã gửi lời mời thăm quan'
end)

-- Invite player to house as REALESTATE (với job check)
lib.callback.register('qbx_housing:server:inviteToHouse', function(source, houseId, targetId)
    local realestate = QBX:GetPlayer(source)
    local target = QBX:GetPlayer(targetId)
    
    if not realestate or not target then 
        return false, 'Không tìm thấy player'
    end
    
    -- Check realestate job
    if realestate.PlayerData.job.name ~= 'realestate' or not realestate.PlayerData.job.onduty then
        return false, 'Bạn không phải realestate hoặc chưa onduty'
    end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then 
        return false, 'Không tìm thấy nhà'
    end
    
    -- Send invite request to target player (they can accept/decline)
    TriggerClientEvent('qbx_housing:client:receiveInvite', targetId, houseId, source, realestate.PlayerData.charinfo.firstname .. ' ' .. realestate.PlayerData.charinfo.lastname, houseConfig.label or tostring(houseId))
    
    return true, 'Đã gửi lời mời thăm quan'
end)

-- Accept invite (called from client after player confirms)
lib.callback.register('qbx_housing:server:acceptInvite', function(source, houseId, realestateSource)
    local target = QBX:GetPlayer(source)
    local inviter = realestateSource and QBX:GetPlayer(realestateSource)
    
    if not target then 
        return false, 'Lỗi hệ thống'
    end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then 
        return false, 'Không tìm thấy nhà'
    end
    
    local bucketId = 0
    
    -- 1. Ưu tiên: Lấy bucket của người mời nếu người mời đang ở trong bucket
    if realestateSource and tonumber(realestateSource) and tonumber(realestateSource) > 0 then
        local inviterBucket = GetPlayerRoutingBucket(tonumber(realestateSource))
        if inviterBucket and inviterBucket > 0 then
            bucketId = inviterBucket
        end
    end
    
    -- 2. Nếu người mời không ở trong bucket riêng hoặc không lấy được, dùng bucket của nhà
    if bucketId == 0 then
        bucketId = GetHouseBucket(houseId)
    end
    
    -- Set guest to same bucket
    SetPlayerBucket(source, bucketId)
    
    -- Track player in house
    local strHouseId = tostring(houseId)
    playersInHouse[source] = strHouseId
    if not houseOccupants[strHouseId] then
        houseOccupants[strHouseId] = {}
    end
    table.insert(houseOccupants[strHouseId], source)
    
    -- Teleport target to house interior
    TriggerClientEvent('qbx_housing:client:enterAsGuest', source, houseId)
    
    -- Notify target
    lib.notify(source, {
        title = 'Thăm Quan Nhà',
        description = 'Bạn đang ở trong ' .. (houseConfig.label or houseId),
        type = 'info'
    })
    
    -- Notify inviter if they're still online
    if inviter then
        lib.notify(realestateSource, {
            title = 'Mời Vào Nhà',
            description = target.PlayerData.charinfo.firstname .. ' đã chấp nhận lời mời',
            type = 'success'
        })
    end
    
    return true, 'Đã vào nhà'
end)

-- Handle when player declines invite
RegisterNetEvent('qbx_housing:server:declineInvite', function(houseId, realestateSource)
    local target = QBX:GetPlayer(source)
    local realestate = QBX:GetPlayer(realestateSource)
    
    if not target then return end
    
    -- Notify realestate if they're still online
    if realestate then
        lib.notify(realestateSource, {
            title = 'Mời Thăm Quan',
            description = target.PlayerData.charinfo.firstname .. ' đã từ chối lời mời',
            type = 'error'
        })
    end
end)

-- Handle when player declines house transfer
RegisterNetEvent('qbx_housing:server:declineTransfer', function(houseId, realestateSource)
    local target = QBX:GetPlayer(source)
    local realestate = QBX:GetPlayer(realestateSource)
    
    if not target then return end
    
    -- Notify realestate if they're still online
    if realestate then
        lib.notify(realestateSource, {
            title = 'Chuyển Nhượng',
            description = target.PlayerData.charinfo.firstname .. ' đã từ chối mua nhà',
            type = 'error'
        })
    end
end)

-- Decline house purchase (player-to-player sale)
RegisterNetEvent('qbx_housing:server:declineHousePurchase', function(houseId, sellerId)
    local buyer = QBX:GetPlayer(source)
    local seller = QBX:GetPlayer(sellerId)
    
    if not buyer then return end
    
    -- Notify seller if they're still online
    if seller then
        lib.notify(sellerId, {
            title = 'Bán Nhà',
            description = buyer.PlayerData.charinfo.firstname .. ' đã từ chối mua nhà',
            type = 'error'
        })
    end
end)

-- ========== PED CHANGE SYSTEM ==========

-- Database helper functions cho ped system
local db = {}

db.getPed = function(citizenid)
    local result = MySQL.query.await('SELECT * FROM `motel_ped` WHERE `citizenid` = ?', {citizenid})
    return result and result[1] or nil
end

db.savePed = function(citizenid, pedModel, comps, texs)
    return MySQL.query.await([[
        INSERT INTO `motel_ped`
            (`citizenid`, `ped_model`,
             `comp0`,`comp1`,`comp2`,`comp3`,`comp4`,`comp5`,
             `comp6`,`comp7`,`comp8`,`comp9`,`comp10`,`comp11`,
             `tex0`,`tex1`,`tex2`,`tex3`,`tex4`,`tex5`,
             `tex6`,`tex7`,`tex8`,`tex9`,`tex10`,`tex11`,
             `updated_at`)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
            `ped_model`  = VALUES(`ped_model`),
            `comp0`=VALUES(`comp0`),`comp1`=VALUES(`comp1`),`comp2`=VALUES(`comp2`),
            `comp3`=VALUES(`comp3`),`comp4`=VALUES(`comp4`),`comp5`=VALUES(`comp5`),
            `comp6`=VALUES(`comp6`),`comp7`=VALUES(`comp7`),`comp8`=VALUES(`comp8`),
            `comp9`=VALUES(`comp9`),`comp10`=VALUES(`comp10`),`comp11`=VALUES(`comp11`),
            `tex0`=VALUES(`tex0`),`tex1`=VALUES(`tex1`),`tex2`=VALUES(`tex2`),
            `tex3`=VALUES(`tex3`),`tex4`=VALUES(`tex4`),`tex5`=VALUES(`tex5`),
            `tex6`=VALUES(`tex6`),`tex7`=VALUES(`tex7`),`tex8`=VALUES(`tex8`),
            `tex9`=VALUES(`tex9`),`tex10`=VALUES(`tex10`),`tex11`=VALUES(`tex11`),
            `updated_at`=VALUES(`updated_at`)
    ]], {
        citizenid, pedModel,
        comps[0] or 0, comps[1] or 0, comps[2] or 0, comps[3] or 0,
        comps[4] or 0, comps[5] or 0, comps[6] or 0, comps[7] or 0,
        comps[8] or 0, comps[9] or 0, comps[10] or 0, comps[11] or 0,
        texs[0] or 0, texs[1] or 0, texs[2] or 0, texs[3] or 0,
        texs[4] or 0, texs[5] or 0, texs[6] or 0, texs[7] or 0,
        texs[8] or 0, texs[9] or 0, texs[10] or 0, texs[11] or 0,
        os.time()
    })
end

db.deletePed = function(citizenid)
    return MySQL.query.await('DELETE FROM `motel_ped` WHERE `citizenid` = ?', {citizenid})
end

-- Callback: Lấy ped data của player
lib.callback.register('qbx_housing:server:getPed', function(src)
    local player = QBX:GetPlayer(src)
    if not player then return nil end
    return db.getPed(player.PlayerData.citizenid)
end)

-- Callback: Lấy appearance mặc định từ playerskins (freemode model đúng giới tính)
lib.callback.register('qbx_housing:server:getDefaultAppearance', function(src)
    local player = QBX:GetPlayer(src)
    if not player then return nil end
    local citizenid = player.PlayerData.citizenid

    -- Xác định giới tính từ charinfo (0 = nam, 1 = nữ)
    local gender = player.PlayerData and player.PlayerData.charinfo and player.PlayerData.charinfo.gender
    local freemodeModel = (gender == 1) and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    -- Ưu tiên row active đúng giới tính
    local row = MySQL.single.await(
        "SELECT model, skin FROM playerskins WHERE citizenid = ? AND model = ? AND active = 1 LIMIT 1",
        { citizenid, freemodeModel }
    )
    if row then return row end

    -- Fallback: bất kỳ row nào đúng giới tính
    row = MySQL.single.await(
        "SELECT model, skin FROM playerskins WHERE citizenid = ? AND model = ? ORDER BY id DESC LIMIT 1",
        { citizenid, freemodeModel }
    )
    if row then return row end

    -- Fallback cuối: trả model không có skin
    return { model = freemodeModel, skin = nil }
end)

-- Event: Admin gán ped cho player
RegisterNetEvent('qbx_housing:server:adminSetPed', function(targetCitizenid, pedModel, comps, texs)
    local src = source
    
    -- Check admin permission
    if not IsPlayerAceAllowed(src, 'command.setped') then
        TriggerClientEvent('qbx_housing:client:notify', src, 'Bạn không có quyền sử dụng lệnh này', 'error')
        return
    end
    
    -- Save ped to database
    db.savePed(targetCitizenid, pedModel, comps, texs)
    
    -- Find target player (if online) and apply ped
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local targetPlayer = QBX:GetPlayer(targetId)
        if targetPlayer and targetPlayer.PlayerData.citizenid == targetCitizenid then
            TriggerClientEvent('qbx_housing:client:applyPed', targetId, pedModel, comps, texs)
            break
        end
    end
    
    TriggerClientEvent('qbx_housing:client:notify', src, 'Đã gán ped "' .. pedModel .. '" cho player', 'success')
end)

-- Event: Reset ped (xóa khỏi database)
RegisterNetEvent('qbx_housing:server:resetPed', function()
    local src = source
    local player = QBX:GetPlayer(src)
    if not player then return end
    db.deletePed(player.PlayerData.citizenid)
end)

-- Event: Nhận ped data từ client sau khi capture
RegisterNetEvent('qbx_housing:server:receivePedData', function(adminSource, citizenid, pedModel, comps, texs)
    local src = source
    
    -- Save to database
    db.savePed(citizenid, pedModel, comps, texs)
    
    -- Apply ped to target
    TriggerClientEvent('qbx_housing:client:applyPed', src, pedModel, comps, texs)
    
    -- Notify admin
    if adminSource then
        TriggerClientEvent('qbx_housing:client:notify', adminSource, 'Đã gán ped "' .. pedModel .. '" thành công', 'success')
    end
end)
-- ================= HOUSE MANAGEMENT SERVER CALLBACKS =================

-- Lấy toàn bộ dữ liệu quản lý nhà cho React NUI
lib.callback.register('qbx_housing:server:getManagementData', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return nil end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then return nil end
    
    local citizenid = player.PlayerData.citizenid
    local isGangHouse = (houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang'
    
    local isBoss = false
    local gangGradeLevel = 0
    local gangName = houseConfig.gang or ''
    if isGangHouse and player.PlayerData.gang and player.PlayerData.gang.name == houseConfig.gang then
        local gangGrade = player.PlayerData.gang.grade
        gangGradeLevel = (type(gangGrade) == 'table' and gangGrade.level) or (type(gangGrade) == 'number' and gangGrade) or 0
        isBoss = gangGradeLevel >= 3 or player.PlayerData.gang.isboss == true
    end
    
    local isOwner = IsOwner(citizenid, houseId)
    if not isOwner and not isBoss then
        return nil
    end
    
    -- Player coin
    local playerCoin = GetPlayerCoinAwait(citizenid)
    
    -- Juicer purchased status
    local juicerPurchased = IsJuicerPurchasedByCitizenId(citizenid)
    
    -- Shared keys
    local sharedKeys = {}
    local houseOwnership = playerHouses[houseId]
    if houseOwnership and houseOwnership.keys and #houseOwnership.keys > 0 then
        local placeholders = {}
        for i = 1, #houseOwnership.keys do placeholders[i] = '?' end
        local query = string.format('SELECT citizenid, charinfo FROM players WHERE citizenid IN (%s)', table.concat(placeholders, ','))
        local pData = MySQL.query.await(query, houseOwnership.keys)
        local namesMap = {}
        if pData then
            for _, row in ipairs(pData) do
                local charinfo = row.charinfo and json.decode(row.charinfo)
                if charinfo and charinfo.firstname and charinfo.lastname then
                    namesMap[row.citizenid] = charinfo.firstname .. ' ' .. charinfo.lastname
                end
            end
        end
        for _, kCit in ipairs(houseOwnership.keys) do
            table.insert(sharedKeys, {
                citizenid = kCit,
                playerName = namesMap[kCit] or 'Unknown',
            })
        end
    end
    
    -- Max shared keys
    local maxKeys = 2
    local houseTypeCfg = Config.HouseTypes[houseConfig.type]
    if houseTypeCfg and houseTypeCfg.maxSharedKeys then
        maxKeys = houseTypeCfg.maxSharedKeys
    end
    
    -- Sell contract check
    local hasSellContract = false
    local itemCount = exports.ox_inventory:Search(source, 'count', 'hopdongbannha')
    if itemCount and itemCount >= 1 then
        hasSellContract = true
    end
    
    local gangLabel = 'Xã Đoàn'
    if isGangHouse and gangName ~= '' then
        local success, gData = pcall(function() return exports.qbx_core:GetGang(gangName) end)
        if success and gData and gData.label and gData.label ~= '' then
            gangLabel = gData.label
        else
            gangLabel = gangName
        end
    end
    
    local gangLevel = tonumber(houseConfig.level) or 1
    local playerCash = player.Functions.GetMoney('cash') or (player.PlayerData.money and player.PlayerData.money.cash) or 0
    local gangMoney = 0
    local warehouseStock = {}

    if isGangHouse and gangName ~= '' then
        -- Lấy tiền quỹ xã đoàn từ Renewed-Banking
        local successBank, bankRes = pcall(function()
            return exports['Renewed-Banking']:getAccountMoney(gangName)
        end)
        if successBank and bankRes then
            gangMoney = tonumber(bankRes) or 0
        end

        -- Lấy vật phẩm từ kho lưu trữ xn_gang_inventory
        local rows = MySQL.query.await("SELECT `item`, `amount` FROM `xn_gang_inventory` WHERE `gang_name` = ?", { gangName })
        if rows then
            for _, r in ipairs(rows) do
                warehouseStock[r.item] = tonumber(r.amount) or 0
            end
        end
    end

    local levelsData = {}
    if isGangHouse and Config.GangHouseLevels then
        for lvl = 1, 3 do
            local lCfg = Config.GangHouseLevels[lvl]
            if lCfg then
                local reqData = nil
                if lCfg.requirements then
                    local reqItems = {}
                    for _, it in ipairs(lCfg.requirements.items or {}) do
                        local itName = it.vatpham
                        local itCount = warehouseStock[itName] or 0
                        local itemDef = exports.ox_inventory:Items(itName)
                        local itLabel = (itemDef and itemDef.label) or itName
                        table.insert(reqItems, {
                            vatpham = itName,
                            label = itLabel,
                            soluong = it.soluong,
                            sodiem = it.sodiem or '1',
                            owned = itCount,
                            hasEnough = itCount >= it.soluong
                        })
                    end
                    reqData = {
                        cash = lCfg.requirements.cash or 0,
                        hasEnoughCash = gangMoney >= (lCfg.requirements.cash or 0),
                        items = reqItems
                    }
                end
                levelsData[lvl] = {
                    level = lvl,
                    label = lCfg.label,
                    storage = lCfg.storage,
                    garage = lCfg.garage,
                    requirements = reqData
                }
            end
        end
    end

    return {
        houseId = houseId,
        isGangHouse = isGangHouse,
        gang = houseConfig.gang,
        gangLabel = gangLabel,
        gangGrade = gangGradeLevel,
        gangLevel = gangLevel,
        levelsData = levelsData,
        playerCash = isGangHouse and gangMoney or playerCash,
        gangMoney = gangMoney,
        isBoss = isBoss,
        isOwner = isOwner,
        houseType = houseConfig.type,
        typeLabel = houseTypeCfg and houseTypeCfg.label or houseConfig.label or houseId,
        ownerName = isGangHouse and gangLabel or (houseOwnership and houseOwnership.owner_name or 'Chủ sở hữu'),
        blipColor = houseConfig.blipColor or 1,
        juicerPurchased = juicerPurchased,
        playerCoin = playerCoin,
        sharedKeys = sharedKeys,
        maxSharedKeys = maxKeys,
        hasSellContract = hasSellContract,
        housePrice = houseConfig.price or (houseTypeCfg and houseTypeCfg.price) or 0
    }
end)

-- Callback Nâng Cấp Trụ Sở Xã Đoàn (Boss >= 3)
lib.callback.register('qbx_housing:server:upgradeGangHouse', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Không tìm thấy người chơi!' end
    
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then return false, 'Không tìm thấy dữ liệu nhà!' end
    
    local isGangHouse = (houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang'
    if not isGangHouse then
        return false, 'Chỉ Trụ Sở Xã Đoàn mới có thể nâng cấp!'
    end
    
    local gangName = houseConfig.gang
    local gangGrade = player.PlayerData.gang and player.PlayerData.gang.grade
    local gradeLevel = (type(gangGrade) == 'table' and gangGrade.level) or (type(gangGrade) == 'number' and gangGrade) or 0
    local isBoss = (player.PlayerData.gang and player.PlayerData.gang.name == gangName) and (gradeLevel >= 3 or player.PlayerData.gang.isboss == true)
    if not isBoss then
        return false, 'Chỉ Boss Xã Đoàn (Cấp 3 trở lên) mới có quyền nâng cấp trụ sở!'
    end
    
    local currentLevel = tonumber(houseConfig.level) or 1
    if currentLevel >= 3 then
        return false, 'Trụ sở đã đạt cấp độ tối đa (Cấp 3)!'
    end
    
    local targetLevel = currentLevel + 1
    local nextLevelCfg = Config.GangHouseLevels and Config.GangHouseLevels[targetLevel]
    if not nextLevelCfg or not nextLevelCfg.requirements then
        return false, 'Không tìm thấy cấu hình nâng cấp cho cấp ' .. targetLevel
    end
    
    local req = nextLevelCfg.requirements
    
    -- 1. Kiểm tra tiền quỹ Xã Đoàn (Renewed-Banking)
    local gangMoney = 0
    local successBank, bankRes = pcall(function()
        return exports['Renewed-Banking']:getAccountMoney(gangName)
    end)
    if successBank and bankRes then
        gangMoney = tonumber(bankRes) or 0
    end
    
    if req.cash and req.cash > 0 then
        if gangMoney < req.cash then
            return false, string.format('Quỹ Xã Đoàn không đủ tiền! Cần: $%s (Hiện có: $%s)', req.cash, gangMoney)
        end
    end
    
    -- 2. Kiểm tra tất cả vật phẩm từ kho lưu trữ gangmenu (xn_gang_inventory)
    local rows = MySQL.query.await("SELECT `item`, `amount` FROM `xn_gang_inventory` WHERE `gang_name` = ?", { gangName })
    local currentStock = {}
    if rows then
        for _, r in ipairs(rows) do
            currentStock[r.item] = tonumber(r.amount) or 0
        end
    end
    
    if req.items and #req.items > 0 then
        for _, it in ipairs(req.items) do
            local count = currentStock[it.vatpham] or 0
            if count < it.soluong then
                local itemDef = exports.ox_inventory:Items(it.vatpham)
                local itLabel = (itemDef and itemDef.label) or it.vatpham
                return false, string.format('Kho lưu trữ Xã Đoàn thiếu vật phẩm: %s (Cần %s/%s)', itLabel, count, it.soluong)
            end
        end
    end
    
    -- 3. Trừ tiền quỹ Xã Đoàn qua Renewed-Banking
    if req.cash and req.cash > 0 then
        local removed = false
        local successRemove, removeRes = pcall(function()
            return exports['Renewed-Banking']:removeAccountMoney(gangName, req.cash)
        end)
        if successRemove and removeRes then
            removed = true
        end
        if not removed then
            return false, 'Không thể trừ tiền từ quỹ Xã Đoàn!'
        end
    end
    
    -- 4. Trừ vật phẩm từ kho lưu trữ gangmenu (xn_gang_inventory)
    if req.items and #req.items > 0 then
        for _, it in ipairs(req.items) do
            MySQL.update.await("UPDATE `xn_gang_inventory` SET `amount` = `amount` - ? WHERE `gang_name` = ? AND `item` = ?", { it.soluong, gangName, it.vatpham })
        end
    end
    
    -- 5. Cập nhật Database
    MySQL.update.await('UPDATE houses SET level = ? WHERE id = ?', { targetLevel, houseId })
    
    -- 6. Cập nhật Server Cache
    local strHouseId = tostring(houseId)
    local newInterior = GetGangHouseInterior(targetLevel)
    local newStorage = GetGangHouseStashCoords(targetLevel)
    
    if allHouses[strHouseId] then
        allHouses[strHouseId].level = targetLevel
        allHouses[strHouseId].interior = newInterior
        allHouses[strHouseId].storagePoint = newStorage
    end
    if allHouses[houseId] and houseId ~= strHouseId then
        allHouses[houseId].level = targetLevel
        allHouses[houseId].interior = newInterior
        allHouses[houseId].storagePoint = newStorage
    end
    
    -- 7. Cập nhật Kho Ox_Inventory
    CreateHouseStash(houseId, houseConfig.type)
    
    -- 8. Cập nhật Garage MH_GARAGE tức thì
    if GetResourceState('mh_garage') == 'started' then
        local houseType = Config.HouseTypes[houseConfig.type]
        CreateHouseGarage(-1, houseId, houseConfig, houseType)
    end
    
    -- 9. Đồng bộ tất cả Clients
    TriggerClientEvent('qbx_housing:client:syncGangHouseLevel', -1, houseId, targetLevel, newInterior, newStorage)
    
    return true, string.format('Chúc mừng! Trụ sở %s đã nâng cấp thành công lên Cấp %s!', houseConfig.label or 'Xã Đoàn', targetLevel), targetLevel
end)
