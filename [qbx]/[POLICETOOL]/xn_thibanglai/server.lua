
local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('ricky-dmv:getData', function(source, cb)
    local licenses = Config.License
    local Player = QBCore.Functions.GetPlayer(source)
    local result = MySQL.Sync.fetchAll("SELECT * FROM player_licenses WHERE citizenid = @citizenid", {
        ['@citizenid'] = Player.PlayerData.citizenid,
    })
    
    -- Mapping ID cũ sang ID mới để tương thích ngược
    local oldToNewId = {
        ['drive_bike'] = 'license_bike',
        ['drive_bikedmv'] = 'license_bikedmv',
        ['drive'] = 'license_car',
        ['drivedmv'] = 'license_cardmv',
        ['drive_truck'] = 'license_truck',
        ['drive_truckdmv'] = 'license_truckdmv'
    }
    
    for k,v in pairs(licenses) do 
        v.theory = false
        v.practice = false
        for i=1, #result, 1 do
            local coso = result[i]
            local licenseType = coso.type
            
            -- Convert ID cũ sang ID mới nếu cần
            if oldToNewId[licenseType] then
                licenseType = oldToNewId[licenseType]
            end

            if licenseType == v.id then
                v.theory = true
                v.practice = true
            elseif licenseType == v.id.."dmv" then
                v.theory = true
                v.practice = false
            end
        end
    end
    cb(licenses, Player.PlayerData.money['cash'], Player.PlayerData.money['bank'])
end)

-- Callback kiểm tra license nhanh (chỉ 1 license cụ thể)
QBCore.Functions.CreateCallback('ricky-dmv:checkLicense', function(source, cb, licenseId)
    local Player = QBCore.Functions.GetPlayer(source)
    local result = MySQL.Sync.fetchAll("SELECT * FROM player_licenses WHERE citizenid = @citizenid AND type IN (@type, @typedmv)", {
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@type'] = licenseId,
        ['@typedmv'] = licenseId.."dmv"
    })
    
    local hasTheory = false
    local hasPractice = false
    
    for i=1, #result, 1 do
        if result[i].type == licenseId then
            hasTheory = true
            hasPractice = true
        elseif result[i].type == licenseId.."dmv" then
            hasTheory = true
        end
    end
    
    cb(hasTheory, hasPractice)
end)

-- QBCore doesn't need licenses table, using player_licenses directly
-- AddEventHandler('onResourceStart', function(resource)
--     if resource == GetCurrentResourceName() then
--         for k,v in pairs(Config.License) do
--             local result =  MySQL.Sync.fetchAll("SELECT * FROM licenses WHERE type = @type", {
--                   ['@type'] = v.id,
--             }) 
--             if result == nil or result[1] == nil then
--                 MySQL.Async.execute("INSERT INTO licenses (type, label) VALUES (@type, @label)", {
--                     ['@type'] = v.id,
--                     ['@label'] = v.label,
--                 }) 
--             end
--         end

--         for k,v in pairs(Config.License) do
--             local result =  MySQL.Sync.fetchAll("SELECT * FROM licenses WHERE type = @type", {
--                   ['@type'] = v.id.."dmv",
--             }) 
--             if result == nil or result[1] == nil then
--                 MySQL.Async.execute("INSERT INTO licenses (type, label) VALUES (@type, @label)", {
--                     ['@type'] = v.id.."dmv",
--                     ['@label'] = v.label.." DMV",
--                 }) 
--             end
--         end
--     end
-- end)


RegisterNetEvent('ricky-dmv:givelicense', function(license)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.Async.execute('INSERT INTO player_licenses (citizenid, type, status) VALUES (@citizenid, @type, @status) ON DUPLICATE KEY UPDATE status = @status', {
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@type'] = license,
        ['@status'] = 1
    })
    TriggerClientEvent('ricky-dmv:updateLicense', src)
end)


RegisterNetEvent('ricky-dmv:removeMoney', function(account, money)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  
  -- Kiểm tra và convert money sang số
  local amount = tonumber(money)
  if not amount or amount <= 0 then
    print("[Ricky-DMV] Invalid money amount:", money)
    return
  end
  
  if account == 'money' then
    Player.Functions.RemoveMoney('cash', amount)
  elseif account == 'bank' then
    Player.Functions.RemoveMoney('bank', amount)
  end
end)

RegisterNetEvent('ricky-dmv:giveItemLicense', function(license)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- VALIDATION: Kiểm tra license ID có hợp lệ không
    local validLicenses = {
        'license_bike',
        'license_car',
        'license_truck'
    }
    
    local isValid = false
    for _, validLicense in ipairs(validLicenses) do
        if license == validLicense then
            isValid = true
            break
        end
    end
    
    if not isValid then
        print(string.format('[SECURITY] Player %s (%s) tried to give invalid license: %s', Player.PlayerData.name, src, license))
        return
    end
    
    -- VALIDATION: Kiểm tra người chơi đã có license trong database chưa
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_licenses WHERE citizenid = @citizenid AND type = @type', {
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@type'] = license
    })
    
    if not result or #result == 0 then
        print(string.format('[SECURITY] Player %s (%s) tried to get item for license %s but doesnt have it in database', Player.PlayerData.name, src, license))
        return
    end
    
    -- Mapping từ license ID sang hạng bằng
    local licenseToHang = {
        ['license_bike']  = 'A',
        ['license_car']   = 'B',
        ['license_truck'] = 'C'
    }
    
    local loaiBang = licenseToHang[license]
    
    if loaiBang then
        -- Kiểm tra xem đã có item driver_license cùng hạng chưa để tránh spam
        local hasItem = exports.ox_inventory:Search(src, 1, 'driver_license', { Loaibang = loaiBang })
        if hasItem and next(hasItem) then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn đã có bằng lái hạng ' .. loaiBang .. ' rồi!', 'error')
            return
        end
        
        -- Thêm item vào inventory với metadata hạng bằng
        local success = exports.ox_inventory:AddItem(src, 'driver_license', 1, {
            Loaibang = loaiBang,
            issued = os.date('%d/%m/%Y'),
            citizenid = Player.PlayerData.citizenid
        })
        
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn đã nhận được Bằng lái hạng ' .. loaiBang .. '!', 'success')
            print(string.format('[DMV] Player %s (%s) received driver_license hang %s', Player.PlayerData.name, src, loaiBang))
        else
            TriggerClientEvent('QBCore:Notify', src, 'Không thể cấp bằng lái, kiểm tra inventory', 'error')
        end
    end
end)

RegisterNetEvent('ricky-dmv:reissueLicense', function(license)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- VALIDATION: Kiểm tra license ID có hợp lệ không
    local validLicenses = {
        'license_bike',
        'license_car',
        'license_truck'
    }
    
    local isValid = false
    for _, validLicense in ipairs(validLicenses) do
        if license == validLicense then
            isValid = true
            break
        end
    end
    
    if not isValid then
        print(string.format('[SECURITY] Player %s (%s) tried to reissue invalid license: %s', Player.PlayerData.name, src, license))
        return
    end
    
    -- VALIDATION: Kiểm tra người chơi đã có license trong database chưa
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_licenses WHERE citizenid = @citizenid AND type = @type', {
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@type'] = license
    })
    
    if not result or #result == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn chưa có bằng lái này để cấp lại!', 'error')
        return
    end
    
    -- Mapping từ license ID sang hạng bằng
    local licenseToHang = {
        ['license_bike']  = 'A',
        ['license_car']   = 'B',
        ['license_truck'] = 'C'
    }
    
    local loaiBang = licenseToHang[license]
    
    if loaiBang then
        -- Thêm item vào inventory với metadata hạng bằng (cấp lại cho phép nhiều lần)
        local success = exports.ox_inventory:AddItem(src, 'driver_license', 1, {
            Loaibang = loaiBang,
            issued = os.date('%d/%m/%Y'),
            citizenid = Player.PlayerData.citizenid,
            reissued = true
        })
        
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Đã cấp lại Bằng lái hạng ' .. loaiBang .. ' thành công!', 'success')
            print(string.format('[DMV] Player %s (%s) reissued driver_license hang %s', Player.PlayerData.name, src, loaiBang))
        else
            TriggerClientEvent('QBCore:Notify', src, 'Không thể cấp lại bằng lái, kiểm tra inventory đầy', 'error')
        end
    end
end)