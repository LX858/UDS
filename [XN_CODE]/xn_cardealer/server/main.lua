if not lib then return end
local QBCore = exports["qb-core"]:GetCoreObject()
local logger = require '@qbx_core.modules.logger'

--[[
    TÍNH NĂNG TĂNG GIÁ XE TỰ ĐỘNG:
    - Mỗi lần bán xe, giá priceToCustomers sẽ tăng 30% so với giá hiện tại (nếu nochangeprice = false)
    - Không giới hạn số lần tăng giá
--]]

local WebHook = {
    Dat_Xe = '',
    Ban_Xe = 'https://discord.com/api/webhooks/1515754248573554773/UGvFVR6qb2-GgNbFHaJu-zmQZrAwmeG5-BD1zEnpCN3K9t7-cgq1l7Us1yZjjv1Vb3Ev',
}

-- Lấy webhook theo từng dealer
local function GetDealerWebhook(dealerId, logType)
    local targetId = dealerId or 'cardealer'
    local dealerCfg = GetDealerById(targetId)
    if dealerCfg and dealerCfg.webhook then
        if type(dealerCfg.webhook) == 'table' then
            if logType == 'datXe' or logType == 'Dat_Xe' then
                return dealerCfg.webhook.datXe or ''
            else
                return dealerCfg.webhook.banXe or ''
            end
        elseif type(dealerCfg.webhook) == 'string' then
            return dealerCfg.webhook
        end
    end
    return WebHook[logType] or ''
end

-- Plate generation functions
local NumberCharset = {}
for i = 48, 57 do NumberCharset[#NumberCharset + 1] = string.char(i) end

function RandomInt(length)
    if length <= 0 then return '' end
    return RandomInt(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
end

local function GenerateCarDealerPlate()
    local plate = 'CDK' .. RandomInt(5)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if result then
        return GenerateCarDealerPlate()
    else
        return plate:upper()
    end
end

local function logEvent(Player, eventName, message, webhook)
    if not webhook or webhook == '' then return end
    logger.log({
        source = eventName,
        webhook = webhook,
        event = eventName,
        color = 'orange',
        message = '\n- Tên nhân vật: `'..Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname..
                  '`\n- citizenid: `'..Player.PlayerData.citizenid..
                  '`\n- ID hiện tại: `'..Player.PlayerData.source.. 
                  '`\n- `'..message..'`',
    })
end

-- Function tạo default vehicle mods
local function CreateDefaultVehicleMods(vehicle, plate)
    local defaultMods = {
        modKit47 = -1,
        modDashboard = -1,
        neonColor = {255, 0, 255},
        modSuspension = -1,
        modSideSkirt = -1,
        modHydraulics = false,
        dirtLevel = 0,
        modTrunk = -1,
        modRoof = -1,
        paintType2 = 0,
        modPlateHolder = -1,
        modExhaust = -1,
        modSmokeEnabled = false,
        modKit21 = false,
        bodyHealth = 1000,
        modBackWheels = -1,
        modXenon = false,
        modRightFender = -1,
        modArchCover = -1,
        plateIndex = 3,
        color1 = 36,
        livery = -1,
        modGrille = -1,
        modDoorR = -1,
        modSpoilers = -1,
        xenonColor = 255,
        modHood = -1,
        neonEnabled = {false, false, false, false},
        modDoorSpeaker = -1,
        modRearBumper = -1,
        modRoofLivery = -1,
        model = GetHashKey(vehicle),
        plate = plate,
        engineHealth = 1000,
        modTrimA = -1,
        modKit49 = -1,
        modSteeringWheel = -1,
        modKit19 = -1,
        tyres = {},
        wheelSize = 0.0,
        modCustomTiresF = false,
        modSpeakers = -1,
        modBrakes = -1,
        modEngine = -1,
        modWindows = -1,
        modSubwoofer = -1,
        modCustomTiresR = false,
        modSeats = -1,
        windows = {0, 1, 2, 3, 4, 5, 7},
        color2 = 0,
        modTank = -1,
        modEngineBlock = -1,
        modOrnaments = -1,
        wheels = 3,
        modDial = -1,
        modFender = -1,
        modLivery = -1,
        oilLevel = 5,
        pearlescentColor = 18,
        modAerials = -1,
        modHydrolic = -1,
        modNitrous = -1,
        modFrontBumper = -1,
        fuelLevel = 76,
        dashboardColor = 65,
        wheelWidth = 0.0,
        modVanityPlate = -1,
        modTurbo = false,
        tireHealth = {["1"] = 1000.0, ["2"] = 1000.0, ["3"] = 1000.0, ["0"] = 1000.0},
        driftTyres = false,
        paintType1 = 0,
        modShifterLeavers = -1,
        tyreSmokeColor = {255, 255, 255},
        tireBurstCompletely = {["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["6"] = false, ["7"] = false, ["0"] = false},
        windowTint = -1,
        wheelColor = 112,
        interiorColor = 93,
        windowStatus = {["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["6"] = true, ["7"] = false, ["0"] = false},
        modLightbar = -1,
        modAirFilter = -1,
        doors = {},
        doorStatus = {["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["0"] = false},
        modAPlate = -1,
        modKit17 = -1,
        liveryRoof = -1,
        headlightColor = 255,
        tireBurstState = {["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["6"] = false, ["7"] = false, ["0"] = false},
        modStruts = -1,
        modHorns = -1,
        modFrontWheels = -1,
        extras = {0},
        bulletProofTyres = true,
        tankHealth = 1000,
        modFrame = -1,
        modTransmission = -1,
        modTrimB = -1,
        modArmor = -1
    }
    return json.encode(defaultMods)
end

-- Đăng ký Stashes động cho từng Dealer
local function registerAllDealerStashes()
    for dealerId, dealerCfg in pairs(Config.Dealers) do
        if dealerCfg.locations and dealerCfg.locations.stash then
            local stashId = dealerId .. '_stash'
            local personalStashId = dealerId .. '_stash_ca_nhan'
            exports.ox_inventory:RegisterStash(stashId, 'Kho Đồ ' .. dealerCfg.label, 30, 100000, false, false, dealerCfg.locations.stash)
            exports.ox_inventory:RegisterStash(personalStashId, 'Kho Đồ Cá Nhân (' .. dealerCfg.label .. ')', 30, 50000, true, false, dealerCfg.locations.stash)
        end
    end
end

-- Tự động kiểm tra và thêm cột dealer vào DB nếu chưa có
local function EnsureDatabaseColumns()
    pcall(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `cardealer_stock` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `dealer` VARCHAR(50) NOT NULL DEFAULT 'cardealer',
                `category` VARCHAR(50) NOT NULL, 
                `vehicle` VARCHAR(50) NOT NULL,  
                `stock` INT DEFAULT 0,           
                `priceToOwners` INT NOT NULL,    
                `priceToCustomers` INT NOT NULL, 
                `danhap` INT DEFAULT 0,          
                `gioihan` INT NOT NULL,
                `nochangeprice` BOOLEAN DEFAULT FALSE,
                `isNew` TINYINT(1) NOT NULL DEFAULT 0,
                `isHot` TINYINT(1) NOT NULL DEFAULT 0,
                `originalPrice` INT NULL DEFAULT NULL,
                `discountPercent` INT NULL DEFAULT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)
    pcall(function()
        MySQL.query([[
            ALTER TABLE `cardealer_stock` 
            ADD COLUMN IF NOT EXISTS `dealer` VARCHAR(50) NOT NULL DEFAULT 'cardealer' COMMENT 'Mã đại lý quản lý xe' AFTER `category`
        ]])
    end)
    pcall(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `cardealer_sales_history` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `seller_source` INT,
                `seller_name` VARCHAR(100),
                `seller_citizenid` VARCHAR(50),
                `dealer` VARCHAR(50) NOT NULL DEFAULT 'cardealer',
                `buyer_source` INT,
                `buyer_name` VARCHAR(100),
                `buyer_citizenid` VARCHAR(50),
                `vehicle` VARCHAR(50) NOT NULL,
                `vehicle_name` VARCHAR(100),
                `price` INT DEFAULT 0,
                `plate` VARCHAR(20),
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)
    pcall(function()
        MySQL.query([[
            ALTER TABLE `cardealer_sales_history` 
            ADD COLUMN IF NOT EXISTS `dealer` VARCHAR(50) NOT NULL DEFAULT 'cardealer' COMMENT 'Mã đại lý' AFTER `seller_citizenid`
        ]])
    end)
end

local Server_Vehicle_Data = {}

-- ── VEHICLE CACHE ───────────────────────────────────────────────────────────
local _CachedOxTrunk    = nil
local _CachedQbxVehicles = nil

local function GetOxTrunkData()
    if _CachedOxTrunk ~= nil then return _CachedOxTrunk end
    local ok, data = pcall(function()
        local f = LoadResourceFile('ox_inventory', 'data/vehicles.lua')
        if f then local fn = load(f); return fn and fn() end
    end)
    _CachedOxTrunk = (ok and data) or false
    return _CachedOxTrunk
end

local function GetQbxVehicles()
    if _CachedQbxVehicles ~= nil then return _CachedQbxVehicles end
    local ok, data = pcall(function() return exports.qbx_core:GetVehiclesByName() end)
    _CachedQbxVehicles = (ok and data) or false
    return _CachedQbxVehicles
end

-- Xây dựng cache xe
function BuildVehicleCache(callback)
    local oxTrunk = GetOxTrunkData()
    local qbxVehs = GetQbxVehicles()
    exports.oxmysql:execute('SELECT * FROM cardealer_stock', {}, function(rows)
        if rows then
            for i, row in ipairs(rows) do
                local trunkSlots, trunkWeight = nil, nil
                local vi = qbxVehs and qbxVehs[row.vehicle]
                if oxTrunk and oxTrunk.trunk then
                    local vType = vi and vi.type     or 'automobile'
                    local vCat  = vi and vi.category or ''
                    local vClass = vi and vi.class   or 0
                    if vType ~= 'bike' and vType ~= 'bicycle' and vCat ~= 'motorcycles' then
                        local modelHash = GetHashKey(row.vehicle)
                        local found = false
                        if oxTrunk.trunk.models then
                            for hash, d in pairs(oxTrunk.trunk.models) do
                                if hash == modelHash and type(d) == 'table' and d[1] and d[1] > 0 then
                                    trunkSlots  = d[1]
                                    trunkWeight = d[2] and (d[2] / 1000) or nil
                                    found = true; break
                                end
                            end
                        end
                        if not found and vi and oxTrunk.trunk[vClass] and type(oxTrunk.trunk[vClass]) == 'table' then
                            local td = oxTrunk.trunk[vClass]
                            if td[1] and td[1] > 0 then
                                trunkSlots  = td[1]
                                trunkWeight = td[2] and (td[2] / 1000) or nil
                            end
                        end
                    end
                end
                rows[i].trunkSlots  = trunkSlots
                rows[i].trunkWeight = trunkWeight
                
                local displayName = nil
                if vi and vi.name then
                    displayName = vi.name
                else
                    displayName = row.vehicle:sub(1,1):upper() .. row.vehicle:sub(2)
                end
                rows[i].name = displayName
                rows[i].dealer = row.dealer or 'cardealer'
            end
            Server_Vehicle_Data = rows
        end
        if callback then callback() end
    end)
end

function RefreshVehicleCache()
    BuildVehicleCache()
end

local function GetStockRowForVehicle(vehicleModel, dealerId)
    if not vehicleModel or not Server_Vehicle_Data then return nil end
    for _, v in pairs(Server_Vehicle_Data) do
        if v.vehicle == vehicleModel then
            if not dealerId or v.dealer == dealerId then
                return v
            end
        end
    end
    -- Fallback nếu không khớp dealerId
    for _, v in pairs(Server_Vehicle_Data) do
        if v.vehicle == vehicleModel then
            return v
        end
    end
    return nil
end

local function GiveVehicleKeys(playerId, plate)
    local hasKey = exports['Renewed-Vehiclekeys']:hasKey(playerId, plate)
    if not hasKey then
        TriggerClientEvent('vehiclekeys:client:SetOwner', playerId, plate)
    end
end

local function CheckDuplicateVehicle(citizenid, vehicle, hash)
    if not Config.DuplicateCheck.enabled or not Config.DuplicateCheck.vehicles[vehicle] then
        return false
    end
    local result = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND vehicle = ? AND hash = ?', {
        citizenid,
        vehicle,
        hash
    })
    return result and result > 0
end

-- Callback lấy dữ liệu xe (hỗ trợ lọc theo dealerId)
lib.callback.register("1307_Cardealer:server:GetData", function(source, dealerId)
    if not dealerId then
        return Server_Vehicle_Data
    end
    local filtered = {}
    for _, v in ipairs(Server_Vehicle_Data) do
        if (v.dealer or 'cardealer') == dealerId then
            table.insert(filtered, v)
        end
    end
    return filtered
end)

lib.callback.register('1307_Cardealer:server:GetShowroomSaleInfoByHash', function(_, vehicleHash)
    vehicleHash = tonumber(vehicleHash)
    if not vehicleHash then return nil end
    for _, v in pairs(Server_Vehicle_Data) do
        if GetHashKey(v.vehicle) == vehicleHash then
            return {
                vehicle = v.vehicle,
                priceToCustomers = tonumber(v.priceToCustomers) or 0,
                stock = tonumber(v.stock) or 0,
                dealer = v.dealer or 'cardealer'
            }
        end
    end
    return nil
end)

lib.callback.register("1307_Cardealer:server:GetBalance", function(source, dealerId)
    local targetDealer = dealerId or 'cardealer'
    local dealerCfg = GetDealerById(targetDealer) or Config.Dealers['cardealer']
    local accountName = dealerCfg.bankAccount or targetDealer
    return exports['Renewed-Banking']:getAccountMoney(accountName) or 0
end)

lib.callback.register("1307_Cardealer:server:HasMoney", function(source, amount, dealerId)
    local src = source 
    local Player = exports.qbx_core:GetPlayer(src)
    local cash = Player.PlayerData.money["cash"]

    if cash >= amount then 
        Player.Functions.RemoveMoney("cash", amount, "THUÊ XE KÉO")
        return true 
    else 
        return false 
    end
end)

lib.callback.register("1307_Cardealer:server:IsOwned", function(source, plate)
    local retval = nil
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        retval = (result and result[1]) and true or false
    end)
    while retval == nil do Wait(0) end 
    return retval
end)

lib.callback.register("1307_Cardealer:server:NhapXe", function(source, vehicle, brand, dealerId)
    local targetDealer = dealerId or 'cardealer'
    local retval = nil
    exports.oxmysql:execute('SELECT * FROM cardealer_stock WHERE vehicle = ? and category = ? and dealer = ?', {vehicle, brand, targetDealer}, function(result)
        if result and result[1] and result[1].gioihan > result[1].danhap then
            retval = true
            exports.oxmysql:execute('UPDATE cardealer_stock SET danhap = ? WHERE vehicle = ? and category = ? and dealer = ?', {result[1].danhap + 1, vehicle, brand, targetDealer})
        else
            retval = false
        end
    end)
    while retval == nil do Wait(0) end 
    return retval
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    EnsureDatabaseColumns()
    registerAllDealerStashes()
    
    Wait(2000)
    BuildVehicleCache(function()
        print('[1307_Cardealer] Cache loaded: ' .. #Server_Vehicle_Data .. ' vehicles')
        TriggerClientEvent("1307_Cardealer:client:SyncData", -1, Server_Vehicle_Data)
    end)
end)

RegisterServerEvent('1307_Cardealer:server:OrderVehicles')
AddEventHandler('1307_Cardealer:server:OrderVehicles', function(vehicle, price, dealerId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local pData = exports.qbx_core:GetPlayer(src)
    local cid = pData.PlayerData.citizenid
    local targetDealer = dealerId or 'cardealer'
    local dealerCfg = GetDealerById(targetDealer) or Config.Dealers['cardealer']
    local accountName = dealerCfg.bankAccount or targetDealer

    local cash = exports['Renewed-Banking']:getAccountMoney(accountName) or 0
    local vehiclePrice = price
    local plate = GenerateCarDealerPlate()
    local amountPrice = tonumber(vehiclePrice)

    if tonumber(cash) >= tonumber(vehiclePrice) then
        exports.oxmysql:insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            CreateDefaultVehicleMods(vehicle, plate),
            plate,
            0
        })
        TriggerClientEvent('QBCore:Notify', src, 'Đã đặt hàng thành công, hãy tiến hành chở xe về kho để nhập hàng', 'success')
        TriggerClientEvent('1307_Cardealer:client:OrderedVehicles', src, vehicle, plate)
        exports['Renewed-Banking']:removeAccountMoney(accountName, amountPrice)
        local PlayerName = pData.PlayerData.charinfo.firstname.. " ".. pData.PlayerData.charinfo.lastname
        local vehInfo = exports.qbx_core:GetVehiclesByName()[vehicle]
        local brandName = vehInfo and vehInfo.brand:upper() or "UNKNOWN"
        local vName = vehInfo and vehInfo.name:upper() or vehicle
        local wh = GetDealerWebhook(targetDealer, 'datXe')
        logEvent(Player, '1307_Cardealer | ĐẶT XE (' .. (dealerCfg.label or targetDealer) .. ')', 'Đã đặt XE: $' .. price .. '\n Loại xe: '..vehicle..' \n Thông Tin Xe : '..brandName..' ['..vName..']', wh)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Không đủ tiền trong quỹ doanh nghiệp ' .. (dealerCfg.label or targetDealer), 'error')
    end
end)

RegisterServerEvent('1307_Cardealer:server:stockIn')
AddEventHandler('1307_Cardealer:server:stockIn', function(vehicle, plate, dealerId)
    local targetDealer = dealerId or 'cardealer'
    exports.oxmysql:execute('DELETE FROM player_vehicles WHERE plate = ?', {plate})
    exports.oxmysql:execute('UPDATE cardealer_stock SET stock = stock + 1 WHERE vehicle = ? AND dealer = ?', { vehicle, targetDealer }, function(result)
        local affected = type(result) == 'number' and result or (result and result.affectedRows or 0)
        if affected == 0 then
            exports.oxmysql:execute('UPDATE cardealer_stock SET stock = stock + 1 WHERE vehicle = ?', { vehicle })
        end
        RefreshVehicleCache()
    end)
end)

-- Event trao giấy tờ xe từ kho cho khách hàng
RegisterNetEvent('1307_Cardealer:server:GiveVehiclePapers', function(vehmodel, buyerId, dealerId)
    local src = source
    local Seller = exports.qbx_core:GetPlayer(src)
    local Buyer = exports.qbx_core:GetPlayer(buyerId)
    local targetDealer = dealerId or 'cardealer'
    
    if not Buyer then
        TriggerClientEvent('QBCore:Notify', src, "Không tìm thấy khách hàng", "error")
        return
    end

    local InStock = false
    for k, v in pairs(Server_Vehicle_Data) do 
        if v.vehicle == vehmodel and (v.dealer == targetDealer or not v.dealer) then 
            if v.stock > 0 then 
                InStock = true 
            end 
        end
    end 

    if not InStock then
        TriggerClientEvent('QBCore:Notify', src, "Xe không còn hàng.", "error")
        return
    end

    local vehicleHash = GetHashKey(vehmodel)
    if CheckDuplicateVehicle(Buyer.PlayerData.citizenid, vehmodel, vehicleHash) then
        TriggerClientEvent('QBCore:Notify', src, "Khách hàng đã sở hữu xe này rồi!", "error")
        TriggerClientEvent('QBCore:Notify', buyerId, "Bạn đã sở hữu xe này rồi!", "error")
        return
    end

    local NewPlate = GenerateCarDealerPlate()
    MySQL.Async.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        Buyer.PlayerData.license,
        Buyer.PlayerData.citizenid,
        vehmodel,
        GetHashKey(vehmodel),
        CreateDefaultVehicleMods(vehmodel, NewPlate),
        NewPlate,
        'pillboxgarage',
        0
    })

    local row = GetStockRowForVehicle(vehmodel, targetDealer)
    local price = row and (tonumber(row.priceToCustomers) or 0) or 0
    local SellerName = Seller.PlayerData.charinfo.firstname.. " ".. Seller.PlayerData.charinfo.lastname
    local buyerName = Buyer.PlayerData.charinfo.firstname.. " ".. Buyer.PlayerData.charinfo.lastname
    local vehinfo = exports.qbx_core:GetVehiclesByName()[vehmodel]
    local vehicleLabel = vehinfo and (vehinfo.brand .. " " .. vehinfo.name) or vehmodel
    
    exports.oxmysql:insert('INSERT INTO cardealer_sales_history (seller_source, seller_name, seller_citizenid, dealer, buyer_source, buyer_name, buyer_citizenid, vehicle, vehicle_name, price, plate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        Seller.PlayerData.source,
        SellerName,
        Seller.PlayerData.citizenid,
        targetDealer,
        Buyer.PlayerData.source,
        buyerName,
        Buyer.PlayerData.citizenid,
        vehmodel,
        vehicleLabel,
        price,
        NewPlate
    })
    
    TriggerClientEvent('1307_Cardealer:client:SetOwner', buyerId, NewPlate, targetDealer)

    local metadata = {
        plate = NewPlate,
        tenchu = buyerName,
        CCCD = Buyer.PlayerData.citizenid,
        model = vehmodel
    }
    exports.ox_inventory:AddItem(buyerId, 'giaytoxe', 1, metadata)
    GiveVehicleKeys(buyerId, NewPlate)

    exports.oxmysql:execute('UPDATE cardealer_stock SET stock = stock - 1 WHERE vehicle = ? AND dealer = ?', {vehmodel, targetDealer})
    RefreshVehicleCache()
    
    TriggerClientEvent('QBCore:Notify', buyerId, "Bạn đã nhận xe "..vehmodel.." và giấy tờ xe từ " .. targetDealer, "success")
    TriggerClientEvent('QBCore:Notify', src, "Đã giao xe và giấy tờ xe cho khách hàng", "success")
    
    local wh = GetDealerWebhook(targetDealer, 'banXe')
    logEvent(Buyer, '1307_Cardealer | GIAO XE TỪ KHO (' .. targetDealer .. ')', 'Tên Xe: ' .. vehmodel .. '\n NGƯỜI GIAO : '..SellerName..' (ID: '..Seller.PlayerData.source..' | '..Seller.PlayerData.citizenid..') \n NGƯỜI NHẬN : [' .. buyerName..' (ID: '..Buyer.PlayerData.source..' | '..Buyer.PlayerData.citizenid..')' .. ']', wh)
end)

RegisterNetEvent('1307_Cardealer:server:SendVehiclePurchaseRequest', function(vehmodel, _, buyerId, dealerId)
    local src = source
    local targetDealer = dealerId or 'cardealer'
    local row = GetStockRowForVehicle(vehmodel, targetDealer)
    local InStock = row and (tonumber(row.stock) or 0) > 0
    local listPrice = row and (tonumber(row.priceToCustomers) or 0) or 0

    local Seller = exports.qbx_core:GetPlayer(src)
    local SellerName = Seller.PlayerData.charinfo.firstname.." "..Seller.PlayerData.charinfo.lastname

    if InStock and listPrice > 0 then
        local Buyer = exports.qbx_core:GetPlayer(buyerId)
        if Buyer then
            TriggerClientEvent('1307_Cardealer:client:ReceivePurchaseRequest', buyerId, vehmodel, listPrice, SellerName, src, targetDealer)
        else
            TriggerClientEvent('QBCore:Notify', src, "Không tìm thấy người mua", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "Xe không còn hàng.", "error")
    end
end)

lib.callback.register('1307_Cardealer:cb:GetPlayerCoupons', function(source)
    local result = {}
    if not Config.DiscountCoupons then return result end
    for itemName, couponData in pairs(Config.DiscountCoupons) do
        local item = exports.ox_inventory:GetItem(source, itemName, nil, false)
        local count = (item and item.count) or 0
        if count > 0 then
            result[#result+1] = {
                item     = itemName,
                label    = couponData.label,
                discount = couponData.discount,
                vehicle  = couponData.vehicle or nil,
                count    = count,
            }
        end
    end
    return result
end)

RegisterNetEvent('1307_Cardealer:server:DeclinePurchase', function(sellerId)
    local src = source
    local Buyer = exports.qbx_core:GetPlayer(src)
    if Buyer and sellerId then
        local buyerName = Buyer.PlayerData.charinfo.firstname .. ' ' .. Buyer.PlayerData.charinfo.lastname
        TriggerClientEvent('QBCore:Notify', sellerId, 'Khách hàng ' .. buyerName .. ' đã từ chối mua xe', 'error')
    end
end)

RegisterNetEvent('1307_Cardealer:server:ConfirmPurchase', function(vehmodel, _, sellerId, couponItem, dealerId)
    local src = source
    local targetDealer = dealerId or 'cardealer'
    local dealerCfg = GetDealerById(targetDealer) or Config.Dealers['cardealer']
    local bankAccount = dealerCfg.bankAccount or targetDealer
    local taxAccount = dealerCfg.taxAccount or 'bcso'

    local Buyer = exports.qbx_core:GetPlayer(src)
    local Seller = exports.qbx_core:GetPlayer(sellerId)
    
    if not Seller then
        TriggerClientEvent('QBCore:Notify', src, "Không tìm thấy nhân viên bán hàng", "error")
        return
    end

    local row = GetStockRowForVehicle(vehmodel, targetDealer)
    local InStock = row and (tonumber(row.stock) or 0) > 0
    local listPrice = row and (tonumber(row.priceToCustomers) or 0) or 0

    if not InStock or listPrice <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Xe đã hết hàng!", "error")
        TriggerClientEvent('QBCore:Notify', sellerId, "Xe đã hết hàng!", "error")
        return
    end

    local vehicleHash = GetHashKey(vehmodel)
    if CheckDuplicateVehicle(Buyer.PlayerData.citizenid, vehmodel, vehicleHash) then
        TriggerClientEvent('QBCore:Notify', src, "Bạn đã sở hữu xe này rồi!", "error")
        TriggerClientEvent('QBCore:Notify', sellerId, "Khách hàng đã sở hữu xe này!", "error")
        return
    end

    local finalPrice  = listPrice
    local couponLabel = nil
    local couponDiscount = 0
    local isEventCoupon = false

    if couponItem and couponItem ~= '' then
        local couponCfg = Config.DiscountCoupons and Config.DiscountCoupons[couponItem]
        if not couponCfg then
            TriggerClientEvent('QBCore:Notify', src, "Mã giảm giá không hợp lệ!", "error")
            return
        end
        if couponCfg.vehicle and couponCfg.vehicle ~= '' and couponCfg.vehicle ~= vehmodel then
            TriggerClientEvent('QBCore:Notify', src, "Phiếu '" .. couponCfg.label .. "' chỉ dùng được cho xe: " .. couponCfg.vehicle, "error")
            return
        end
        local itemObj = exports.ox_inventory:GetItem(src, couponItem, nil, false)
        local itemCount = (itemObj and itemObj.count) or 0
        if itemCount < 1 then
            TriggerClientEvent('QBCore:Notify', src, "Bạn không có '" .. couponCfg.label .. "' trong túi đồ!", "error")
            return
        end
        couponDiscount  = couponCfg.discount
        couponLabel     = couponCfg.label
        finalPrice      = math.floor(listPrice * (1 - couponDiscount / 100))
        isEventCoupon   = couponCfg.event == true
    end

    local cash = Buyer.PlayerData.money["cash"]
    if cash < finalPrice then
        TriggerClientEvent('QBCore:Notify', src, "Bạn không đủ tiền mặt để mua xe này. Cần: $"..finalPrice, "error")
        TriggerClientEvent('QBCore:Notify', sellerId, "Khách hàng không đủ tiền để mua xe", "error")
        return
    end

    if couponItem and couponItem ~= '' then
        exports.ox_inventory:RemoveItem(src, couponItem, 1)
        exports.qbx_core:Notify(src, 'Đã sử dụng: ' .. couponLabel .. ' (-' .. couponDiscount .. '%)', 'success')
    end

    Buyer.Functions.RemoveMoney("cash", finalPrice, "Mua xe từ " .. (dealerCfg.label or targetDealer))

    local sellerAmount
    if isEventCoupon then
        sellerAmount = 100000
        -- Cả 2 doanh nghiệp cardealer và luxurycar mỗi bên nhận 100.000$
        pcall(function()
            exports['Renewed-Banking']:addAccountMoney("cardealer", 100000)
        end)
        pcall(function()
            exports['Renewed-Banking']:addAccountMoney("luxurycar", 100000)
        end)
    else
        local companyAmount = math.floor(finalPrice * 0.90)
        sellerAmount = finalPrice - companyAmount
        pcall(function()
            exports['Renewed-Banking']:addAccountMoney(taxAccount, companyAmount)
        end)
        pcall(function()
            exports['Renewed-Banking']:addAccountMoney(bankAccount, sellerAmount)
        end)
    end

    local NewPlate = GenerateCarDealerPlate()
    MySQL.Async.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        Buyer.PlayerData.license,
        Buyer.PlayerData.citizenid,
        vehmodel,
        GetHashKey(vehmodel),
        CreateDefaultVehicleMods(vehmodel, NewPlate),
        NewPlate,
        'pillboxgarage',
        0
    })

    local SellerName = Seller.PlayerData.charinfo.firstname.. " ".. Seller.PlayerData.charinfo.lastname
    local BuyerName = Buyer.PlayerData.charinfo.firstname.. " ".. Buyer.PlayerData.charinfo.lastname
    local vehinfo = exports.qbx_core:GetVehiclesByName()[vehmodel]
    local vehicleLabel = vehinfo and (vehinfo.brand .. " " .. vehinfo.name) or vehmodel
    
    exports.oxmysql:insert('INSERT INTO cardealer_sales_history (seller_source, seller_name, seller_citizenid, dealer, buyer_source, buyer_name, buyer_citizenid, vehicle, vehicle_name, price, plate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        Seller.PlayerData.source,
        SellerName,
        Seller.PlayerData.citizenid,
        targetDealer,
        Buyer.PlayerData.source,
        BuyerName,
        Buyer.PlayerData.citizenid,
        vehmodel,
        vehicleLabel,
        finalPrice,
        NewPlate
    })

    TriggerClientEvent('1307_Cardealer:client:SetOwner', src, NewPlate, targetDealer)

    local metadata = {
        plate = NewPlate,
        tenchu = BuyerName,
        CCCD = Buyer.PlayerData.citizenid,
        model = vehmodel
    }
    exports.ox_inventory:AddItem(src, 'giaytoxe', 1, metadata)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, NewPlate)

    exports.oxmysql:execute('SELECT nochangeprice FROM cardealer_stock WHERE vehicle = ? AND dealer = ?', {vehmodel, targetDealer}, function(result)
        local shouldChangePrice = true
        if result and result[1] and result[1].nochangeprice then
            shouldChangePrice = false
        end
        
        local updateQuery
        if shouldChangePrice then
            updateQuery = 'UPDATE cardealer_stock SET stock = stock - 1, priceToCustomers = FLOOR(priceToCustomers * 1.3) WHERE vehicle = ? AND dealer = ?'
        else
            updateQuery = 'UPDATE cardealer_stock SET stock = stock - 1 WHERE vehicle = ? AND dealer = ?'
        end
        
        exports.oxmysql:execute(updateQuery, {vehmodel, targetDealer}, function(res)
            local affected = type(res) == 'number' and res or (res and res.affectedRows or 0)
            if affected == 0 then
                exports.oxmysql:execute('UPDATE cardealer_stock SET stock = stock - 1 WHERE vehicle = ?', {vehmodel})
            end
            RefreshVehicleCache()
        end)
    end)
    
    if couponLabel then
        TriggerClientEvent('QBCore:Notify', src, "Mua thành công xe " .. vehmodel .. " với giá $" .. finalPrice .. " (đã giảm " .. couponDiscount .. "%)", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Bạn đã mua thành công xe " .. vehmodel .. " với giá $" .. finalPrice, "success")
    end
    TriggerClientEvent('QBCore:Notify', sellerId, "Bán thành công xe " .. vehmodel .. " | Quỹ nhận: $" .. sellerAmount, "success")
    
    local couponLog = couponLabel and (' | Mã giảm giá: ' .. couponLabel .. ' (-' .. couponDiscount .. '%)') or ''
    local wh = GetDealerWebhook(targetDealer, 'banXe')
    logEvent(Buyer, '1307_Cardealer | MUA XE (' .. (dealerCfg.label or targetDealer) .. ')', 'Tên Xe: ' .. vehmodel .. '\n Giá gốc: $' .. listPrice .. ' | Giá thanh toán: $' .. finalPrice .. couponLog .. '\n NGƯỜI MUA : '..BuyerName..' (ID: '..Buyer.PlayerData.source..' | '..Buyer.PlayerData.citizenid..') \n NGƯỜI BÁN : '..SellerName..' (ID: '..Seller.PlayerData.source..' | '..Seller.PlayerData.citizenid..') \n Quỹ nhận về: $'..sellerAmount , wh)
end)

RegisterNetEvent('1307_Cardealer:server:SendVehicle', function(vehmodel, who, dealerId)
    local src = source
    local targetDealer = dealerId or 'cardealer'
    local InStock = false
	for k, v in pairs(Server_Vehicle_Data) do 
		if v.vehicle == vehmodel and (v.dealer == targetDealer or not v.dealer) then 
			if v.stock > 0 then 
				InStock = true 
			end 
		end
	end 

    local Seller = exports.qbx_core:GetPlayer(src)
    local SellerName = Seller.PlayerData.charinfo.firstname.." "..Seller.PlayerData.charinfo.lastname
    
    if InStock then
        local Buyer = exports.qbx_core:GetPlayer(who)
        local vehicleHash = GetHashKey(vehmodel)
        if CheckDuplicateVehicle(Buyer.PlayerData.citizenid, vehmodel, vehicleHash) then
            TriggerClientEvent('QBCore:Notify', src, "Người nhận đã sở hữu xe này rồi!", "error")
            return
        end
        
        local NewPlate = GenerateCarDealerPlate()
        MySQL.Async.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            Buyer.PlayerData.license,
            Buyer.PlayerData.citizenid,
            vehmodel,
            GetHashKey(vehmodel),
            CreateDefaultVehicleMods(vehmodel, NewPlate),
            NewPlate,
            'pillboxgarage',
            0
        })

        local row = GetStockRowForVehicle(vehmodel, targetDealer)
        local price = row and (tonumber(row.priceToCustomers) or 0) or 0
        local BuyerName = Buyer.PlayerData.charinfo.firstname.. " ".. Buyer.PlayerData.charinfo.lastname
        local vehinfo = exports.qbx_core:GetVehiclesByName()[vehmodel]
        local vehicleLabel = vehinfo and (vehinfo.brand .. " " .. vehinfo.name) or vehmodel
        
        exports.oxmysql:insert('INSERT INTO cardealer_sales_history (seller_source, seller_name, seller_citizenid, dealer, buyer_source, buyer_name, buyer_citizenid, vehicle, vehicle_name, price, plate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            Seller.PlayerData.source,
            SellerName,
            Seller.PlayerData.citizenid,
            targetDealer,
            Buyer.PlayerData.source,
            BuyerName,
            Buyer.PlayerData.citizenid,
            vehmodel,
            vehicleLabel,
            price,
            NewPlate
        })
        TriggerClientEvent('1307_Cardealer:client:SetOwner', who, NewPlate, targetDealer)

        local metadata = {
            plate = NewPlate,
            tenchu = BuyerName,
            CCCD = Buyer.PlayerData.citizenid,
            model = vehmodel
        }
        exports.ox_inventory:AddItem(who, 'giaytoxe', 1, metadata)
        GiveVehicleKeys(who, NewPlate)

        exports.oxmysql:execute('SELECT nochangeprice FROM cardealer_stock WHERE vehicle = ? AND dealer = ?', {vehmodel, targetDealer}, function(result)
            local shouldChangePrice = true
            if result and result[1] and result[1].nochangeprice then
                shouldChangePrice = false
            end
            
            local updateQuery
            if shouldChangePrice then
                updateQuery = 'UPDATE cardealer_stock SET stock = stock - 1, priceToCustomers = FLOOR(priceToCustomers * 1.3) WHERE vehicle = ? AND dealer = ?'
            else
                updateQuery = 'UPDATE cardealer_stock SET stock = stock - 1 WHERE vehicle = ? AND dealer = ?'
            end
            
            exports.oxmysql:execute(updateQuery, {vehmodel, targetDealer}, function()
                RefreshVehicleCache()
            end)
        end)
        TriggerClientEvent('QBCore:Notify', who, "Bạn vừa được chuyển nhượng một chiếc xe từ đại lý.", "success")
        local wh = GetDealerWebhook(targetDealer, 'banXe')
        logEvent(Buyer, '1307_Cardealer | BÁN XE (' .. targetDealer .. ')', 'Tên Xe: ' .. vehmodel .. '\n NGƯỜI BÁN : '..SellerName..' (ID: '..Seller.PlayerData.source..' | '..Seller.PlayerData.citizenid..') \n NGƯỜI NHẬN : [' .. BuyerName..' (ID: '..Buyer.PlayerData.source..' | '..Buyer.PlayerData.citizenid..')' .. ']', wh)
    else
        TriggerClientEvent('QBCore:Notify', src, "Xe không còn hàng.", "error")
    end
end)

RegisterNetEvent('1307_Cardealer:server:StartTestDrive', function(who, dealerId)
    TriggerClientEvent("1307_Cardealer:client:StartTestDrive", who, dealerId)
end)

RegisterNetEvent('1307_Cardealer:server:SetTestDriveBucket', function(vehicleNetId)
    local src = source
    local bucket = src
    SetPlayerRoutingBucket(src, bucket)
    if vehicleNetId then
        local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
        if DoesEntityExist(vehicle) then
            SetEntityRoutingBucket(vehicle, bucket)
        end
    end
end)

RegisterNetEvent('1307_Cardealer:server:ResetBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

lib.callback.register('1307_Cardealer:server:spawnTestDriveVehicle', function(source, vehicleName, vehicleCoords, plate)
    local src = source
    local bucket = src
    SetPlayerRoutingBucket(src, bucket)
    
    local netId, veh = qbx.spawnVehicle({ spawnSource = vehicleCoords or src, model = vehicleName, warp = false})
    if not netId or not veh then
        SetPlayerRoutingBucket(src, 0)
        return nil, nil
    end
    
    SetEntityRoutingBucket(veh, bucket)
    SetVehicleNumberPlateText(veh, plate)
    Wait(100)
    GiveVehicleKeys(src, plate)
    return netId, veh, bucket
end)

lib.callback.register('1307_Cardealer:server:spawnVehicle', function(source, vehicleName, vehicleCoords, plate)
    local src = source
    local netId, veh = qbx.spawnVehicle({ spawnSource = vehicleCoords or src, model = vehicleName, warp = false })
    if not netId or not veh then
        return nil, nil
    end
    Wait(500)
    SetVehicleNumberPlateText(veh, plate)
    Wait(100)
    GiveVehicleKeys(src, plate)
	return netId, veh
end)

function IsPlayerMod(src)
    if not src then return false end
    return QBCore.Functions.HasPermission(src, 'mod')
        or QBCore.Functions.HasPermission(src, 'admin')
        or QBCore.Functions.HasPermission(src, 'god')
        or IsPlayerAceAllowed(tostring(src), 'command')
        or IsPlayerAceAllowed(tostring(src), 'admin')
        or IsPlayerAceAllowed(tostring(src), 'mod')
        or (exports.qbx_core and exports.qbx_core:HasPermission(src, 'mod'))
        or (exports.qbx_core and exports.qbx_core:HasPermission(src, 'admin'))
end

lib.callback.register('1307_Cardealer:server:CheckModPerm', function(source)
    return IsPlayerMod(source)
end)

RegisterNetEvent('1307_Cardealer:server:deleteVehicle', function(netId)
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)