local QBCore = exports['qb-core']:GetCoreObject()
local vehicleDocsCache = {}
local quaysoLocked = false -- Biến lock để ngăn spam quay số
local currentPlayer = nil -- Người chơi đang quay số

local function randomLetters()
    local letters = {}
    for i = 1, 2 do
        letters[i] = string.char(math.random(65, 90))
    end
    return table.concat(letters)
end

RegisterNetEvent('LuaNest_BamBienSo:server:GetNumber', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not vehicleDocsCache then return end

    -- Kiểm tra lock
    if quaysoLocked then
        local currentPlayerName = "Không rõ"
        if currentPlayer then
            local currentPlayerData = QBCore.Functions.GetPlayer(currentPlayer)
            if currentPlayerData then
                currentPlayerName = GetPlayerName(currentPlayer)
            end
        end
        QBCore.Functions.Notify(src, '⏳ Hệ thống quay số đang được sử dụng bởi: ' .. currentPlayerName, 'error', 5000)
        return
    end

    local oldPlate, Model = nil, nil
    local hasProfileButSpun = false
    for plate, data in pairs(vehicleDocsCache) do
        if data.CCCD == Player.PlayerData.citizenid then
            if not data.hasSpun then
                oldPlate = plate
                Model = data.model
                break
            else
                hasProfileButSpun = true
            end
        end
    end

    if not oldPlate then
        if hasProfileButSpun then
            QBCore.Functions.Notify(src, '❌ Hồ sơ này đã được quay số rồi!', 'error')
        else
            QBCore.Functions.Notify(src, '❌ Không tìm thấy hồ sơ xe của bạn!', 'error')
        end
        return
    end

    -- Khóa hệ thống quay số
    quaysoLocked = true
    currentPlayer = src
    TriggerClientEvent('LuaNest_BamBienSo:client:setSpinState', -1, true)
    print(('[LuaNest] 🔒 Hệ thống quay số bị khóa bởi: %s'):format(GetPlayerName(src)))
    
    -- Thông báo cho tất cả người chơi
    -- TriggerClientEvent('chat:addMessage', -1, {
    --     color = {0, 255, 255},
    --     multiline = true,
    --     args = {"[QUAY SỐ]", "🎲 " .. GetPlayerName(src) .. " đang thực hiện quay số biển xe..."}
    -- })

    local digits = string.format("%05d", math.random(0, 99999))
    local newPlate = "UDS" .. digits

    -- Thông báo quá trình quay số cho tất cả người chơi
    TriggerClientEvent('LuaNest_BamBienSo:client:ReceiveNumber', -1, {
        old = oldPlate,
        new = newPlate,
        Model = Model
    })

    vehicleDocsCache[oldPlate].plate = newPlate
    vehicleDocsCache[oldPlate].hasSpun = true
    
    -- Tạo timer để mở khóa sau 10 giây (thời gian quay số)
    SetTimeout(10000, function()
        quaysoLocked = false
        currentPlayer = nil
        TriggerClientEvent('LuaNest_BamBienSo:client:setSpinState', -1, false)
        print('[LuaNest] 🔓 Hệ thống quay số đã được mở khóa')
    end)
    
    print(('[LuaNest] 🎲 Quay số hoàn tất: %s → %s'):format(oldPlate, newPlate))
end)

-- Event xử lý khi người chơi disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    if quaysoLocked and currentPlayer == src then
        quaysoLocked = false
        currentPlayer = nil
        TriggerClientEvent('LuaNest_BamBienSo:client:setSpinState', -1, false)
        print(('[LuaNest] 🔓 Hệ thống quay số đã được mở khóa do người chơi %s disconnect'):format(GetPlayerName(src)))
        
        -- Thông báo cho tất cả người chơi
        -- TriggerClientEvent('chat:addMessage', -1, {
        --     color = {255, 165, 0},
        --     multiline = true,
        --     args = {"[QUAY SỐ]", "⚠️ Hệ thống quay số đã được mở khóa do người chơi disconnect"}
        -- })
    end
end)

-- Command admin để mở khóa khẩn cấp hệ thống quay số
lib.addCommand('unlockquayso', {
    help = 'Mở khóa khẩn cấp hệ thống quay số',
    restricted = 'group.admin'
}, function(source, args)
    local src = source
    
    if not quaysoLocked then
        QBCore.Functions.Notify(src, '✅ Hệ thống quay số hiện đang mở', 'success')
        return
    end
    
    local previousPlayer = "Không rõ"
    if currentPlayer then
        previousPlayer = GetPlayerName(currentPlayer) or "Không rõ"
    end
    
    quaysoLocked = false
    currentPlayer = nil
    TriggerClientEvent('LuaNest_BamBienSo:client:setSpinState', -1, false)
    
    QBCore.Functions.Notify(src, '🔓 Đã mở khóa hệ thống quay số (trước đó bị khóa bởi: ' .. previousPlayer .. ')', 'success')
    print(('[LuaNest] 🔓 Admin %s đã mở khóa hệ thống quay số'):format(GetPlayerName(src)))
    
    -- Thông báo cho tất cả người chơi
    -- TriggerClientEvent('chat:addMessage', -1, {
    --     color = {0, 255, 0},
    --     multiline = true,
    --     args = {"[ADMIN]", "🔓 Hệ thống quay số đã được mở khóa bởi Admin"}
    -- })
end)

-- Command admin để kiểm tra và đồng bộ biển số
lib.addCommand('syncplates', {
    help = 'Kiểm tra và đồng bộ biển số giữa cột plate và mods',
    restricted = 'group.admin'
}, function(source, args)
    local src = source
    
    QBCore.Functions.Notify(src, '🔄 Bắt đầu kiểm tra và đồng bộ biển số...', 'primary', 5000)
    print(('[LuaNest] 🔍 Admin %s bắt đầu kiểm tra đồng bộ biển số'):format(GetPlayerName(src)))
    
    -- Lấy tất cả xe trong database
    MySQL.Async.fetchAll('SELECT plate, mods FROM player_vehicles', {}, function(vehicles)
        if not vehicles or #vehicles == 0 then
            QBCore.Functions.Notify(src, '❌ Không tìm thấy xe nào trong database!', 'error')
            return
        end
        
        local totalVehicles = #vehicles
        local mismatchedVehicles = {}
        local fixedVehicles = {}
        local errorVehicles = {}
        
        print(('[LuaNest] 📊 Tìm thấy %d xe để kiểm tra'):format(totalVehicles))
        
        for i, vehicle in ipairs(vehicles) do
            local plateFromDB = vehicle.plate
            local modsData = vehicle.mods
            
            if modsData and modsData ~= '' then
                -- Decode JSON mods
                local success, decodedMods = pcall(json.decode, modsData)
                if success and decodedMods then
                    local plateFromMods = decodedMods.plate
                    
                    -- Kiểm tra xem có khác biệt không
                    if plateFromMods and plateFromMods ~= plateFromDB then
                        table.insert(mismatchedVehicles, {
                            dbPlate = plateFromDB,
                            modsPlate = plateFromMods
                        })
                        
                        -- Cập nhật plate trong mods để khớp với database
                        decodedMods.plate = plateFromDB
                        local encodeSuccess, newModsData = pcall(json.encode, decodedMods)
                        
                        if encodeSuccess then
                            -- Update database
                            MySQL.Async.execute('UPDATE player_vehicles SET mods = @newMods WHERE plate = @plate', {
                                ['@newMods'] = newModsData,
                                ['@plate'] = plateFromDB
                            }, function(rowsChanged)
                                if rowsChanged > 0 then
                                    table.insert(fixedVehicles, {
                                        plate = plateFromDB,
                                        oldModsPlate = plateFromMods
                                    })
                                    print(('[LuaNest] ✅ Đã sửa biển số: %s (mods: %s → %s)'):format(plateFromDB, plateFromMods, plateFromDB))
                                else
                                    table.insert(errorVehicles, plateFromDB)
                                    print(('[LuaNest] ❌ Không thể cập nhật mods cho xe: %s'):format(plateFromDB))
                                end
                                
                                -- Kiểm tra xem đã xử lý xong tất cả chưa
                                if #fixedVehicles + #errorVehicles == #mismatchedVehicles then
                                    -- Gửi báo cáo cuối cùng
                                    local reportMessage = string.format(
                                        '📋 BÁO CÁO ĐỒNG BỘ BIỂN SỐ:\n' ..
                                        '• Tổng xe kiểm tra: %d\n' ..
                                        '• Xe có lỗi biển số: %d\n' ..
                                        '• Xe đã sửa thành công: %d\n' ..
                                        '• Xe sửa lỗi: %d',
                                        totalVehicles, #mismatchedVehicles, #fixedVehicles, #errorVehicles
                                    )
                                    
                                    QBCore.Functions.Notify(src, reportMessage, 'success', 10000)
                                    print(('[LuaNest] 📊 Báo cáo hoàn thành - Admin: %s'):format(GetPlayerName(src)))
                                    
                                    -- Gửi chi tiết qua chat nếu có lỗi
                                    if #fixedVehicles > 0 then
                                        -- TriggerClientEvent('chat:addMessage', src, {
                                        --     color = {0, 255, 0},
                                        --     multiline = true,
                                        --     args = {"[SYNC-PLATES]", string.format("✅ Đã sửa %d xe có biển số không khớp", #fixedVehicles)}
                                        -- })
                                    end
                                    
                                    if #errorVehicles > 0 then
                                        -- TriggerClientEvent('chat:addMessage', src, {
                                        --     color = {255, 165, 0},
                                        --     multiline = true,
                                        --     args = {"[SYNC-PLATES]", string.format("⚠️ Có %d xe không thể sửa được", #errorVehicles)}
                                        -- })
                                    end
                                end
                            end)
                        else
                            table.insert(errorVehicles, plateFromDB)
                            print(('[LuaNest] ❌ Lỗi encode JSON cho xe: %s'):format(plateFromDB))
                        end
                    end
                else
                    print(('[LuaNest] ⚠️ Lỗi decode JSON mods cho xe: %s'):format(plateFromDB))
                end
            end
        end
        
        -- Nếu không có xe nào cần sửa
        if #mismatchedVehicles == 0 then
            QBCore.Functions.Notify(src, '✅ Tất cả biển số đã đồng bộ! Không cần sửa gì.', 'success', 5000)
            print(('[LuaNest] ✅ Tất cả %d xe đều có biển số đồng bộ'):format(totalVehicles))
        end
    end)
end)

RegisterNetEvent('LuaNest_BamBienSo:server:nopHoSo', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    -- Kiểm tra tiền của người chơi
    local playerMoney = Player.PlayerData.money.cash or 0
    local requiredMoney = 100

    if playerMoney < requiredMoney then
        QBCore.Functions.Notify(src, '❌ Bạn cần có ít nhất 💵' .. requiredMoney .. ' để nộp hồ sơ xe! (Hiện có: 💵' .. playerMoney .. ')', 'error')
        return
    end

    local items = exports.ox_inventory:Search(src, 'slots', 'giaytoxe')
    local count = exports.ox_inventory:GetItem(src, 'giaytoxe', nil, true)

    if count == 0 or not items or #items == 0 then
        return QBCore.Functions.Notify(src, '❌ Bạn làm gì có giấy tờ xe?', 'error')
    end

    local validMetadata, slotId = nil, nil
    for _, slot in pairs(items) do
        if slot.metadata and slot.metadata.tenchu and slot.metadata.plate and slot.metadata.model then
            validMetadata = slot.metadata
            slotId = slot.slot
            break
        end
    end

    if not validMetadata then
        return QBCore.Functions.Notify(src, '❌ Giấy tờ thiếu thông tin hợp lệ!', 'error')
    end

    -- Trừ tiền từ người chơi
    Player.Functions.RemoveMoney('cash', requiredMoney, 'nop-ho-so-xe')
    
    vehicleDocsCache[validMetadata.plate] = {
        tenchu = validMetadata.tenchu,
        model = validMetadata.model,
        CCCD = validMetadata.CCCD,
        plate = validMetadata.plate,
        source = src,
        hasSpun = false
    }

    Plate = validMetadata.plate
    exports['Renewed-Vehiclekeys']:removeKey(source, Plate)
    Wait(100)
    exports.ox_inventory:RemoveItem(src, 'giaytoxe', 1, nil, slotId)
    
    QBCore.Functions.Notify(src, '✅ Hồ sơ xe đã được nộp thành công! (-💵' .. requiredMoney .. ')', 'success')
    print(('[LuaNest] 💰 Người chơi %s đã nộp hồ sơ xe %s và trả phí 💵%s'):format(Player.PlayerData.citizenid, validMetadata.plate, requiredMoney))
end)

lib.addCommand('capgiaytoxe', {
    help = 'Thêm giấy tờ xe cho người chơi (lấy biển số từ xe đang ngồi)',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'PID người nhận giấy tờ xe',
        }
    }
}, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    --print(('[LuaNest] Thêm giấy tờ xe cho PID: %s'):format(args.target))

    -- Kiểm tra job và grade
    if Player.PlayerData.job.name ~= 'police' or Player.PlayerData.job.grade.level < 8 then
        QBCore.Functions.Notify(src, '❌ Bạn cần là công an từ cấp 8 trở lên để sử dụng lệnh này!', 'error')
        return
    end

    -- Lấy thông tin người nhận từ PID
    local targetPlayer = QBCore.Functions.GetPlayer(args.target)
    if not targetPlayer then
        QBCore.Functions.Notify(src, '❌ Không tìm thấy người chơi với PID: ' .. args.target, 'error')
        return
    end

    --print(('[LuaNest] Tìm thấy người chơi: %s (Source: %s)'):format(targetPlayer.PlayerData.name, targetPlayer.PlayerData.source))

    -- Kiểm tra xem người chơi có đang ngồi trên xe không
    local targetSrc = targetPlayer.PlayerData.source
    --print(('[LuaNest] Gửi trigger đến source: %s'):format(targetSrc))
    
    -- Thông báo cho admin về quá trình
    QBCore.Functions.Notify(src, '🔄 Đang kiểm tra xe của người chơi...', 'primary', 3000)
    
    -- Không cần gửi plate vì sẽ lấy từ xe thực tế
    TriggerClientEvent('LuaNest_BamBienSo:client:checkVehicle', targetSrc, src, nil, args.target)
end)

-- Event mới xử lý từ client dialog
RegisterNetEvent('LuaNest_BamBienSo:server:capGiayToXeFromClient', function(targetPid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Kiểm tra job và grade
    if Player.PlayerData.job.name ~= 'police' or Player.PlayerData.job.grade.level < 11 then
        QBCore.Functions.Notify(src, '❌ Bạn cần là công an từ cấp 11 trở lên để sử dụng lệnh này!', 'error')
        return
    end

    -- Tìm player theo PID (duyệt qua tất cả players online)
    local targetPlayer = nil
    local targetSrc = nil
    
    local allPlayers = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(allPlayers) do
        local tempPlayer = QBCore.Functions.GetPlayer(playerId)
        if tempPlayer and tempPlayer.PlayerData.pid == targetPid then
            targetPlayer = tempPlayer
            targetSrc = playerId
            break
        end
    end
    
    if not targetPlayer or not targetSrc then
        QBCore.Functions.Notify(src, '❌ Không tìm thấy người chơi với PID: ' .. targetPid .. ' (Người chơi có thể đã offline)', 'error')
        return
    end

    -- Thông báo cho admin về quá trình
    QBCore.Functions.Notify(src, '🔄 Đang kiểm tra xe của người chơi ' .. GetPlayerName(targetSrc) .. '...', 'primary', 3000)
    
    -- Không cần gửi plate vì sẽ lấy từ xe thực tế
    TriggerClientEvent('LuaNest_BamBienSo:client:checkVehicle', targetSrc, src, nil, targetPid)
end)

RegisterNetEvent('LuaNest_BamBienSo:server:createGiayToXe', function(adminSrc, plate, targetPid, vehicleModel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local metadata = {
        plate = plate,
        tenchu = GetPlayerName(src),
        CCCD = Player.PlayerData.citizenid,
        model = vehicleModel
    }

    exports.ox_inventory:AddItem(src, 'giaytoxe', 1, metadata)
    print(metadata)
    QBCore.Functions.Notify(src, '✅ Đã nhận giấy tờ xe vào túi đồ!', 'success')
    QBCore.Functions.Notify(adminSrc, '✅ Đã thêm giấy tờ xe cho người chơi PID: ' .. targetPid, 'success')
end)

-- Event xử lý khi người chơi không ngồi trên xe
RegisterNetEvent('LuaNest_BamBienSo:server:playerNotInVehicle', function(adminSrc, targetPid)
    local src = source
    
    -- Thông báo chi tiết cho admin
    QBCore.Functions.Notify(adminSrc, '❌ Người chơi (PID: ' .. targetPid .. ') không đang ngồi trên xe!', 'error', 5000)
    
    -- Log server
    print(('[LuaNest] ❌ Người chơi PID %s không ngồi trên xe khi admin %s yêu cầu cấp giấy tờ'):format(targetPid, adminSrc))
    
    -- Thông báo cho admin qua chat (nếu cần)
    -- TriggerClientEvent('chat:addMessage', adminSrc, {
    --     color = {255, 165, 0},
    --     multiline = true,
    --     args = {"[HỆ THỐNG]", "⚠️ Yêu cầu cấp giấy tờ xe thất bại - Người chơi không ngồi trên xe"}
    -- })
end)

RegisterCommand('addgiaytoxe', function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local plate = args[1] or 'XYZ123'
    local tenchu = args[2] or GetPlayerName(src)
    local model = args[3] or 'Adder'

    local metadata = {
        plate = plate,
        tenchu = tenchu,
        CCCD = Player.PlayerData.citizenid,
        model = model
    }

    exports.ox_inventory:AddItem(src, 'giaytoxe', 1, metadata)
    print(metadata)
    QBCore.Functions.Notify(src, '✅ Đã thêm giấy tờ xe vào túi đồ!', 'success')
end, false)



QBCore.Functions.CreateCallback('LuaNest_BamBienSo:server:GetSpinningState', function(source, cb)
    cb(quaysoLocked)
end)

QBCore.Functions.CreateCallback("LuaNest_BamBienSo:server:GetCache", function(src, cb)
    cb(vehicleDocsCache or {})
end)

RegisterNetEvent('LuaNest_BamBienSo:server:TraHoSo', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not vehicleDocsCache or not vehicleDocsCache[plate] then
        QBCore.Functions.Notify(src, '❌ Không tìm thấy hồ sơ!', 'error')
        return
    end

    local data = vehicleDocsCache[plate]
    
    -- Kiểm tra hồ sơ có phải của người chơi này không
    if data.CCCD ~= Player.PlayerData.citizenid then
        QBCore.Functions.Notify(src, '❌ Bạn không thể lấy hồ sơ xe của người khác!', 'error')
        print(('[LuaNest] ⚠️ Người chơi %s cố gắng lấy hồ sơ xe không phải của mình (Plate: %s, Owner: %s)'):format(Player.PlayerData.citizenid, plate, data.CCCD))
        return
    end

    exports.ox_inventory:AddItem(src, 'biensoxe', 1, {
        tenchu = data.tenchu,
        plate = data.plate,
        CCCD = data.CCCD,
        model = data.model
    })
    
    exports['Renewed-Vehiclekeys']:addKey(source, data.plate)

    vehicleDocsCache[plate] = nil
    QBCore.Functions.Notify(src, '✅ Bạn đã nhận lại hồ sơ xe: ' .. data.plate, 'success')
    print(('[LuaNest] ✅ Người chơi %s đã nhận lại hồ sơ xe: %s'):format(Player.PlayerData.citizenid, data.plate))
end)

QBCore.Functions.CreateUseableItem('biensoxe', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    local items = exports.ox_inventory:Search(source, 'slots', 'biensoxe')

    for _, slot in pairs(items) do
        if slot.metadata.CCCD == Player.PlayerData.citizenid then
            if slot.metadata.tenchu and slot.metadata.plate and slot.metadata.model then
                TriggerClientEvent('LuaNest_BamBienSo:client:ganbien', source, slot)
                return
            end
        else
            QBCore.Functions.Notify(source, '❌ Biển số này không thuộc về bạn!', 'error')
        end
    end
end)

QBCore.Functions.CreateCallback('LuaNest_BamBienSo:server:KiemTraXeChinhChu', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    local cleanedPlate = string.gsub(plate, "%s+", "")

    print(('[LuaNest] Kiểm tra xe chính chủ - Plate: %s, Cleaned: %s, CitizenID: %s'):format(plate, cleanedPlate, citizenid))

    MySQL.Async.fetchScalar('SELECT citizenid FROM player_vehicles WHERE plate = @plate', {
        ['@plate'] = cleanedPlate
    }, function(citizenid2)
        local isOwner = citizenid2 == citizenid
        print(('[LuaNest] Kết quả kiểm tra xe - Owner: %s, Is Owner: %s'):format(citizenid2 or 'null', tostring(isOwner)))
        cb(isOwner)
    end)
end)

RegisterNetEvent('LuaNest_BamBienSo:server:CapNhatBienSo', function(oldPlate, newPlate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local cleanedOldPlate = string.gsub(oldPlate, "%s+", "")
    local cleanedNewPlate = string.gsub(newPlate, "%s+", "")
    
    -- Kiểm tra xe cũ có thuộc về người chơi không và lấy dữ liệu mods
    MySQL.Async.fetchAll('SELECT citizenid, mods FROM player_vehicles WHERE plate = @oldPlate', {
        ['@oldPlate'] = cleanedOldPlate
    }, function(result)
        if not result or #result == 0 or result[1].citizenid ~= citizenid then
            print(('[LuaNest] ⚠️ Người chơi %s cố gắng đổi biển số không hợp lệ! Old: %s'):format(citizenid, cleanedOldPlate))
            return
        end

        -- Kiểm tra biển số mới đã tồn tại chưa
        MySQL.Async.fetchScalar('SELECT citizenid FROM player_vehicles WHERE plate = @newPlate', {
            ['@newPlate'] = cleanedNewPlate
        }, function(existingOwner)
            if existingOwner then
                print(('[LuaNest] ⚠️ Biển số %s đã tồn tại thuộc về %s'):format(cleanedNewPlate, existingOwner))
                QBCore.Functions.Notify(src, '❌ Biển số mới đã tồn tại trong hệ thống!', 'error')
                return
            end

            -- Cập nhật mods JSON để thay đổi plate bên trong
            local modsData = result[1].mods
            local updatedMods = modsData
            
            if modsData and modsData ~= '' then
                -- Decode JSON và thay đổi plate
                local success, decodedMods = pcall(json.decode, modsData)
                if success and decodedMods and decodedMods.plate then
                    decodedMods.plate = cleanedNewPlate
                    local encodeSuccess, newModsData = pcall(json.encode, decodedMods)
                    if encodeSuccess then
                        updatedMods = newModsData
                        print(('[LuaNest] 🔧 Đã cập nhật plate trong mods: %s → %s'):format(cleanedOldPlate, cleanedNewPlate))
                    else
                        print(('[LuaNest] ⚠️ Lỗi encode JSON mods cho xe %s'):format(cleanedOldPlate))
                    end
                else
                    print(('[LuaNest] ⚠️ Lỗi decode JSON mods cho xe %s'):format(cleanedOldPlate))
                end
            end

            -- ox_inventory: trunk = 'trunk{plate}', glovebox = 'glove{plate}'
            local trunkId = 'trunk' .. cleanedOldPlate
            local gloveboxId = 'glove' .. cleanedOldPlate
            
            print(('[LuaNest] 🔄 Xóa trunk/glovebox cho plate: %s'):format(cleanedOldPlate))
            print(('[LuaNest] 🔄 Trunk ID: %s, Glovebox ID: %s'):format(trunkId, gloveboxId))
            
            -- Bước 1: ClearInventory - xóa items trong memory và database
            pcall(function()
                exports.ox_inventory:ClearInventory(trunkId)
                print(('[LuaNest] 🗑️ ClearInventory trunk: %s'):format(trunkId))
            end)
            
            pcall(function()
                exports.ox_inventory:ClearInventory(gloveboxId)
                print(('[LuaNest] 🗑️ ClearInventory glovebox: %s'):format(gloveboxId))
            end)
            
            -- Bước 2: RemoveInventory - xóa khỏi runtime cache (save rồi remove)
            -- Điều này đảm bảo ox_inventory không còn giữ reference đến inventory cũ
            pcall(function()
                exports.ox_inventory:RemoveInventory(trunkId)
                print(('[LuaNest] 🗑️ RemoveInventory trunk: %s'):format(trunkId))
            end)
            
            pcall(function()
                exports.ox_inventory:RemoveInventory(gloveboxId)
                print(('[LuaNest] 🗑️ RemoveInventory glovebox: %s'):format(gloveboxId))
            end)

            -- Bước 3: Đợi để đảm bảo ox_inventory đã xử lý xong
            Wait(500)
            
            -- Bước 4: Update plate và force set trunk/glovebox = NULL trong database
            MySQL.Async.execute('UPDATE player_vehicles SET plate = @newPlate, mods = @newMods, trunk = NULL, glovebox = NULL WHERE plate = @oldPlate AND citizenid = @citizenid', {
                ['@newPlate'] = cleanedNewPlate,
                ['@newMods'] = updatedMods,
                ['@oldPlate'] = cleanedOldPlate,
                ['@citizenid'] = citizenid
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    print(('[LuaNest] ✅ Đã cập nhật biển số: %s → %s cho %s'):format(cleanedOldPlate, cleanedNewPlate, citizenid))
                    QBCore.Functions.Notify(src, '✅ Biển số xe đã được cập nhật thành công!', 'success')
                else
                    print(('[LuaNest] ❌ Không thể cập nhật biển số cho %s (Old: %s, New: %s)'):format(citizenid, cleanedOldPlate, cleanedNewPlate))
                    QBCore.Functions.Notify(src, '❌ Lỗi khi cập nhật biển số!', 'error')
                end
            end)
        end)
    end)
end)
