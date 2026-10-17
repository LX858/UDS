-- VERSION with MySQL for real vehicle data

-- Kiểm tra framework được sử dụng (ESX hoặc QBCore)
local Framework = nil
local QBCore = nil
local ESX = nil

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

-- Lấy thông tin job của player
RegisterServerEvent('xn_pdtools:getPlayerJob')
AddEventHandler('xn_pdtools:getPlayerJob', function()
    local src = source
    local playerData = nil
    
    if Framework == 'QBCore' and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            playerData = {
                job = Player.PlayerData.job.name
            }
        end
    elseif Framework == 'ESX' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            playerData = {
                job = xPlayer.job.name
            }
        end
    end
    
    TriggerClientEvent('xn_pdtools:receivePlayerJob', src, playerData)
end)

-- Lấy thông tin xe theo biển số
RegisterServerEvent('xn_pdtools:getVehicleInfo')
AddEventHandler('xn_pdtools:getVehicleInfo', function(plate)
    local src = source
    
    print('[xn_pdtools] Server received request for plate: ' .. tostring(plate))
    
    -- Làm sạch biển số
    plate = plate:gsub("%s+", ""):upper()
    
    print('[xn_pdtools] Cleaned plate: ' .. plate)
    
    -- Lấy thông tin xe
    local vehicleData = nil
    
    if Framework == 'QBCore' and QBCore then
        print('[xn_pdtools] Checking QBCore database with MySQL...')
        
        -- Kiểm tra trong database trước
        exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
            if result and result[1] then
                local vehicle = result[1]
                print('[xn_pdtools] Found vehicle in database for citizenid: ' .. vehicle.citizenid)
                
                -- Lấy thông tin chủ xe
                exports.oxmysql:execute('SELECT charinfo FROM players WHERE citizenid = ?', {vehicle.citizenid}, function(playerResult)
                    local ownerName = 'Không xác định'
                    
                    if playerResult and playerResult[1] then
                        local charinfo = json.decode(playerResult[1].charinfo)
                        ownerName = charinfo.firstname .. ' ' .. charinfo.lastname
                        print('[xn_pdtools] Owner found: ' .. ownerName)
                    end
                    
                    vehicleData = {
                        owner = ownerName,
                        plate = plate,
                        status = vehicle.state == 'out' and 'Đang sử dụng' or 'Trong garage',
                        model = vehicle.vehicle,
                        color = 'Không rõ',
                        registration_date = vehicle.created or 'Không rõ',
                        garage = vehicle.garage or 'Không rõ'
                    }
                    
                    print('[xn_pdtools] Sending vehicle data to client')
                    TriggerClientEvent('xn_pdtools:receiveVehicleInfo', src, vehicleData)
                    
                    -- Log việc kiểm tra
                    local playerName = GetPlayerName(src)
                    print(string.format('[xn_pdtools] Player %s checked vehicle %s (Owner: %s)', playerName, plate, ownerName))
                end)
            else
                print('[xn_pdtools] Vehicle not found in database, checking config...')
                
                -- Không tìm thấy trong database, kiểm tra config
                if Config.VehicleInfo[plate] then
                    vehicleData = Config.VehicleInfo[plate]
                    print('[xn_pdtools] Found vehicle in config: ' .. vehicleData.owner)
                else
                    vehicleData = {
                        owner = 'Không xác định',
                        plate = plate,
                        status = 'Chưa đăng ký',
                        model = 'Không rõ',
                        color = 'Không rõ',
                        registration_date = 'Không rõ'
                    }
                    print('[xn_pdtools] Vehicle not found, using default data')
                end
                
                TriggerClientEvent('xn_pdtools:receiveVehicleInfo', src, vehicleData)
                
                -- Log việc kiểm tra
                local playerName = GetPlayerName(src)
                print(string.format('[xn_pdtools] Player %s checked vehicle %s', playerName, plate))
            end
        end)
    else
        print('[xn_pdtools] No QBCore, checking config only...')
        
        -- Fallback: kiểm tra trong config
        if Config.VehicleInfo[plate] then
            vehicleData = Config.VehicleInfo[plate]
            print('[xn_pdtools] Found vehicle in config: ' .. vehicleData.owner)
        else
            vehicleData = {
                owner = 'Không xác định',
                plate = plate,
                status = 'Chưa đăng ký',
                model = 'Không rõ',
                color = 'Không rõ',
                registration_date = 'Không rõ'
            }
            print('[xn_pdtools] Vehicle not found, using default data')
        end
        
        TriggerClientEvent('xn_pdtools:receiveVehicleInfo', src, vehicleData)
        
        -- Log việc kiểm tra
        local playerName = GetPlayerName(src)
        print(string.format('[xn_pdtools] Player %s checked vehicle %s', playerName, plate))
    end
end)
