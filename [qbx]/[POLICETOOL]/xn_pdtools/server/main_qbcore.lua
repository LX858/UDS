-- VERSION sử dụng exports QBCore thay vì MySQL trực tiếp

-- Kiểm tra framework được sử dụng (ESX hoặc QBCore)
local Framework = nil
local QBCore = nil
local ESX = nil

-- Table để lưu thông tin xe đã spawn (đơn giản)
local SpawnedVehicles = {}

CreateThread(function()
    -- Thử load QBCore
    pcall(function()
        QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then
            Framework = 'QBCore'
            print('[xn_pdtools] QBCore detected')
        end
    end)
    
    -- Nếu không có QBCore, thử ESX
    if not Framework then
        pcall(function()
            ESX = exports['es_extended']:getSharedObject()
            if ESX then
                Framework = 'ESX'
                print('[xn_pdtools] ESX detected')
            end
        end)
    end
    
    print('[xn_pdtools] Framework: ' .. (Framework or 'None'))
end)

-- Event để track xe khi player spawn
RegisterServerEvent('xn_pdtools:registerVehicle')
AddEventHandler('xn_pdtools:registerVehicle', function(plate, vehicleData)
    local src = source
    
    if Framework == 'QBCore' and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            SpawnedVehicles[plate:gsub("%s+", ""):upper()] = {
                owner = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                citizenid = Player.PlayerData.citizenid,
                plate = plate:gsub("%s+", ""):upper(),
                status = 'Đã spawn',
                model = vehicleData.model or 'Không rõ',
                color = 'Không rõ',
                registration_date = os.date('%Y-%m-%d'),
                spawn_time = os.time()
            }
            print('[xn_pdtools] Registered vehicle ' .. plate .. ' to ' .. SpawnedVehicles[plate:gsub("%s+", ""):upper()].owner)
        end
    end
end)

-- Lấy thông tin job của player
RegisterServerEvent('xn_pdtools:getPlayerJob')
AddEventHandler('xn_pdtools:getPlayerJob', function()
    local src = source
    local playerData = nil
    
    if Framework == 'QBCore' and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            playerData = {
                job = Player.PlayerData.job.name,
                onduty = Player.PlayerData.job.onduty or false -- Thêm trạng thái onduty
            }
        end
    elseif Framework == 'ESX' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            playerData = {
                job = xPlayer.job.name,
                onduty = true -- ESX không có onduty system, mặc định là true
            }
        end
    end
    
    TriggerClientEvent('xn_pdtools:receivePlayerJob', src, playerData)
end)

-- Lấy thông tin xe theo biển số
RegisterServerEvent('xn_pdtools:getVehicleInfo')
AddEventHandler('xn_pdtools:getVehicleInfo', function(plate, isNPC)
    local src = source
    
    print('[xn_pdtools] Server received request for plate: ' .. tostring(plate))
    
    -- Làm sạch biển số
    plate = plate:gsub("%s+", ""):upper()
    
    print('[xn_pdtools] Cleaned plate: ' .. plate .. ' | Client suggests isNPC: ' .. tostring(isNPC))
    
    -- Lấy thông tin xe player như bình thường - LUÔN LUÔN thử trước
    local vehicleData = nil
    
    if Framework == 'QBCore' and QBCore then
        print('[xn_pdtools] Checking QBCore database...')
        
        -- Query database để tìm chủ xe thực sự
        exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
            if result[1] then
                -- Tìm thấy xe trong database
                local vehicleInfo = result[1]
                
                -- Lấy thông tin player từ citizenid
                exports.oxmysql:execute('SELECT * FROM players WHERE citizenid = ?', {vehicleInfo.citizenid}, function(players)
                    local ownerName = 'Không xác định'
                    if players[1] then
                        local charinfo = json.decode(players[1].charinfo)
                        ownerName = charinfo.firstname .. ' ' .. charinfo.lastname
                    end
                    
                    -- Kiểm tra xe có đang được sử dụng không
                    local status = 'Đã đăng ký'
                    local Players = QBCore.Functions.GetPlayers()
                    for _, playerId in pairs(Players) do
                        local ped = GetPlayerPed(playerId)
                        local currentVehicle = GetVehiclePedIsIn(ped, false)
                        if currentVehicle ~= 0 then
                            local currentPlate = GetVehicleNumberPlateText(currentVehicle):gsub("%s+", ""):upper()
                            if currentPlate == plate then
                                status = 'Đang sử dụng'
                                break
                            end
                        end
                    end
                    
                    local vehicleData = {
                        owner = ownerName,
                        plate = plate,
                        status = status,
                        model = vehicleInfo.vehicle or 'Không rõ',
                        color = 'Không rõ',
                        registration_date = 'Không rõ',
                        garage = vehicleInfo.garage or 'Không rõ'
                    }
                    
                    TriggerClientEvent('xn_pdtools:receiveVehicleInfo', src, vehicleData)
                    print('[xn_pdtools] Found vehicle in database: ' .. ownerName)
                    
                    -- Log việc kiểm tra
                    local playerName = GetPlayerName(src)
                    print(string.format('[xn_pdtools] Player %s checked vehicle %s (Owner: %s)', playerName, plate, ownerName))
                end)
            else
                -- Không tìm thấy trong database, kiểm tra các nguồn khác
                print('[xn_pdtools] Vehicle not found in database, checking other sources...')
                
                CheckOtherSources(src, plate, isNPC)
            end
        end)
    elseif Framework == 'ESX' and ESX then
        print('[xn_pdtools] ESX framework - checking database...')
        
        exports.oxmysql:execute('SELECT * FROM owned_vehicles WHERE plate = ?', {plate}, function(result)
            if result[1] then
                local vehicleInfo = result[1]
                
                exports.oxmysql:execute('SELECT * FROM users WHERE identifier = ?', {vehicleInfo.owner}, function(users)
                    local ownerName = 'Không xác định'
                    if users[1] then
                        ownerName = users[1].firstname .. ' ' .. users[1].lastname
                    end
                    
                    local vehicleData = {
                        owner = ownerName,
                        plate = plate,
                        status = 'Đã đăng ký',
                        model = json.decode(vehicleInfo.vehicle).model or 'Không rõ',
                        color = 'Không rõ',
                        registration_date = 'Không rõ',
                        garage = vehicleInfo.stored or 'Không rõ'
                    }
                    
                    TriggerClientEvent('xn_pdtools:receiveVehicleInfo', src, vehicleData)
                    
                    local playerName = GetPlayerName(src)
                    print(string.format('[xn_pdtools] Player %s checked vehicle %s (Owner: %s)', playerName, plate, ownerName))
                end)
            else
                CheckOtherSources(src, plate, isNPC)
            end
        end)
    else
        print('[xn_pdtools] No framework detected, checking other sources...')
        CheckOtherSources(src, plate, isNPC)
    end
end)

-- Function để kiểm tra các nguồn khác khi không tìm thấy trong database
function CheckOtherSources(src, plate, isNPC)
    local vehicleData = nil
    
    -- Kiểm tra trong SpawnedVehicles
    if SpawnedVehicles[plate] then
        vehicleData = SpawnedVehicles[plate]
        vehicleData.status = 'Xe đã spawn (chưa đăng ký)'
        print('[xn_pdtools] Found vehicle in SpawnedVehicles: ' .. vehicleData.owner)
    -- Kiểm tra trong config
    elseif Config.VehicleInfo[plate] then
        vehicleData = Config.VehicleInfo[plate]
        print('[xn_pdtools] Found vehicle in config: ' .. vehicleData.owner)
    else
        -- Kiểm tra xe có phải NPC không
        if isNPC then
            vehicleData = {
                owner = 'Xe NPC',
                plate = plate,
                status = 'Xe của NPC (AI Traffic)',
                model = 'Không rõ',
                color = 'Không rõ',
                registration_date = 'N/A',
                isNPC = true
            }
            print('[xn_pdtools] Confirmed as NPC vehicle')
        else
            -- Không xác định được
            vehicleData = {
                owner = 'Không xác định',
                plate = plate,
                status = 'Không tìm thấy trong hệ thống',
                model = 'Không rõ',
                color = 'Không rõ',
                registration_date = 'Không rõ'
            }
            print('[xn_pdtools] Vehicle not found anywhere, using default data')
        end
    end
    
    TriggerClientEvent('xn_pdtools:receiveVehicleInfo', src, vehicleData)
    
    -- Log việc kiểm tra
    local playerName = GetPlayerName(src)
    if vehicleData.isNPC then
        print(string.format('[xn_pdtools] Player %s checked NPC vehicle %s', playerName, plate))
    else
        print(string.format('[xn_pdtools] Player %s checked vehicle %s (Owner: %s)', playerName, plate, vehicleData.owner))
    end
end

-- Event để log việc xóa xe
RegisterServerEvent('xn_pdtools:logVehicleDelete')
AddEventHandler('xn_pdtools:logVehicleDelete', function(plate)
    local src = source
    local playerName = GetPlayerName(src)
    
    -- Kiểm tra quyền và onduty status
    local hasPermission = false
    if Framework == 'QBCore' and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            for _, job in ipairs(Config.AllowedJobs) do
                if Player.PlayerData.job.name == job and Player.PlayerData.job.onduty then
                    hasPermission = true
                    break
                end
            end
        end
    elseif Framework == 'ESX' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            for _, job in ipairs(Config.AllowedJobs) do
                if xPlayer.job.name == job then
                    hasPermission = true
                    break
                end
            end
        end
    end
    
    if hasPermission then
        print(string.format('[xn_pdtools] Player %s deleted vehicle %s', playerName, plate))
        -- Có thể thêm log vào database ở đây nếu cần
    else
        print(string.format('[xn_pdtools] WARNING: Player %s attempted to delete vehicle %s without permission or not onduty!', playerName, plate))
    end
end)

-- Event để log việc mở khóa xe
RegisterServerEvent('xn_pdtools:logVehicleUnlock')
AddEventHandler('xn_pdtools:logVehicleUnlock', function(plate)
    local src = source
    local playerName = GetPlayerName(src)
    
    -- Kiểm tra quyền và onduty status
    local hasPermission = false
    if Framework == 'QBCore' and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            for _, job in ipairs(Config.AllowedJobs) do
                if Player.PlayerData.job.name == job and Player.PlayerData.job.onduty then
                    hasPermission = true
                    break
                end
            end
        end
    elseif Framework == 'ESX' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            for _, job in ipairs(Config.AllowedJobs) do
                if xPlayer.job.name == job then
                    hasPermission = true
                    break
                end
            end
        end
    end
    
    if hasPermission then
        print(string.format('[xn_pdtools] Player %s unlocked vehicle %s', playerName, plate))
        -- Có thể thêm log vào database ở đây nếu cần
    else
        print(string.format('[xn_pdtools] WARNING: Player %s attempted to unlock vehicle %s without permission or not onduty!', playerName, plate))
    end
end)

-- Debug command để xem danh sách xe đã đăng ký
RegisterCommand('listvehicles', function(source, args, rawCommand)
    if source == 0 then -- Server console only
        print('[xn_pdtools] === Registered Vehicles (Memory) ===')
        local count = 0
        for plate, data in pairs(SpawnedVehicles) do
            count = count + 1
            print(string.format('%d. Plate: %s | Owner: %s | Model: %s | Status: %s', 
                count, plate, data.owner, data.model, data.status))
        end
        if count == 0 then
            print('No vehicles registered in memory.')
        else
            print('Total in memory: ' .. count .. ' vehicles')
        end
        print('[xn_pdtools] ========================')
    end
end, true)

-- Debug command để test database query
RegisterCommand('testdb', function(source, args, rawCommand)
    if source == 0 then -- Server console only
        local testPlate = args[1] or 'TEST123'
        print('[xn_pdtools] Testing database query for plate: ' .. testPlate)
        
        if Framework == 'QBCore' then
            exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ?', {testPlate}, function(result)
                if result[1] then
                    print('[xn_pdtools] Found vehicle: ' .. json.encode(result[1]))
                else
                    print('[xn_pdtools] Vehicle not found in player_vehicles')
                end
            end)
        elseif Framework == 'ESX' then
            exports.oxmysql:execute('SELECT * FROM owned_vehicles WHERE plate = ?', {testPlate}, function(result)
                if result[1] then
                    print('[xn_pdtools] Found vehicle: ' .. json.encode(result[1]))
                else
                    print('[xn_pdtools] Vehicle not found in owned_vehicles')
                end
            end)
        else
            print('[xn_pdtools] No framework detected')
        end
    end
end, true)

-- ===================================
-- POLICE BOX ITEM HANDLER
-- ===================================

-- Callback để xử lý việc sử dụng box_police
lib.callback.register('xn_pdtools:usePoliceBox', function(source)
    local src = source
    
    if Framework == 'QBCore' and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            print('[xn_pdtools] Player not found')
            return { success = false, message = 'Không tìm thấy thông tin người chơi' }
        end
        
        -- Kiểm tra xem player có vật phẩm box_police không
        local hasItem = exports.ox_inventory:GetItem(src, Config.PoliceBox.itemName, nil, true)
        if not hasItem or hasItem < 1 then
            return { success = false, message = 'Bạn không có hộp cảnh sát' }
        end
        
        -- Xóa box_police khỏi inventory
        local removed = exports.ox_inventory:RemoveItem(src, Config.PoliceBox.itemName, 1)
        if not removed then
            return { success = false, message = 'Không thể mở hộp cảnh sát' }
        end
        
        -- Thêm các vật phẩm vào inventory
        local itemsReceived = {}
        local allSuccess = true
        
        for _, item in ipairs(Config.PoliceBox.items) do
            local added = exports.ox_inventory:AddItem(src, item.name, item.amount)
            if added then
                table.insert(itemsReceived, { name = item.name, amount = item.amount })
            else
                allSuccess = false
                print('[xn_pdtools] Failed to add item: ' .. item.name)
            end
        end
        
        if #itemsReceived > 0 then
            -- Tạo chuỗi thông báo
            local itemList = {}
            for _, item in ipairs(itemsReceived) do
                table.insert(itemList, item.amount .. 'x ' .. item.name)
            end
            
            return { 
                success = true, 
                message = 'Bạn đã nhận: ' .. table.concat(itemList, ', '),
                items = itemsReceived
            }
        else
            -- Hoàn lại box nếu không thêm được vật phẩm nào
            exports.ox_inventory:AddItem(src, Config.PoliceBox.itemName, 1)
            return { success = false, message = 'Không thể thêm vật phẩm vào túi' }
        end
        
    elseif Framework == 'ESX' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then
            return { success = false, message = 'Không tìm thấy thông tin người chơi' }
        end
        
        -- Kiểm tra và xóa box_police
        local hasItem = exports.ox_inventory:GetItem(src, Config.PoliceBox.itemName, nil, true)
        if not hasItem or hasItem < 1 then
            return { success = false, message = 'Bạn không có hộp cảnh sát' }
        end
        
        local removed = exports.ox_inventory:RemoveItem(src, Config.PoliceBox.itemName, 1)
        if not removed then
            return { success = false, message = 'Không thể mở hộp cảnh sát' }
        end
        
        -- Thêm các vật phẩm
        local itemsReceived = {}
        for _, item in ipairs(Config.PoliceBox.items) do
            local added = exports.ox_inventory:AddItem(src, item.name, item.amount)
            if added then
                table.insert(itemsReceived, { name = item.name, amount = item.amount })
            end
        end
        
        if #itemsReceived > 0 then
            local itemList = {}
            for _, item in ipairs(itemsReceived) do
                table.insert(itemList, item.amount .. 'x ' .. item.name)
            end
            
            return { 
                success = true, 
                message = 'Bạn đã nhận: ' .. table.concat(itemList, ', '),
                items = itemsReceived
            }
        else
            exports.ox_inventory:AddItem(src, Config.PoliceBox.itemName, 1)
            return { success = false, message = 'Không thể thêm vật phẩm vào túi' }
        end
    else
        return { success = false, message = 'Framework không được hỗ trợ' }
    end
end)
