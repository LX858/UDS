-- Kiểm tra framework được sử dụng (ESX hoặc QBCore)
local Framework = nil
local frameworkObject = nil

CreateThread(function()
    -- Thử load ESX
    pcall(function()
        ESX = exports['es_extended']:getSharedObject()
        if ESX then
            Framework = 'ESX'
            frameworkObject = ESX
        end
    end)
    
    -- Nếu không có ESX, thử QBCore
    if not Framework then
        pcall(function()
            QBCore = exports['qb-core']:GetCoreObject()
            if QBCore then
                Framework = 'QBCore'
                frameworkObject = QBCore
            end
        end)
    end
    
    print('[xn_pdtools] Framework detected: ' .. (Framework or 'None'))
end)

-- Lấy thông tin job của player
lib.callback.register('xn_pdtools:getPlayerJob', function(source)
    local src = source
    local playerData = nil
    
    if Framework == 'ESX' and frameworkObject then
        local xPlayer = frameworkObject.GetPlayerFromId(src)
        if xPlayer then
            playerData = {
                job = xPlayer.job.name
            }
        end
    elseif Framework == 'QBCore' and frameworkObject then
        local Player = frameworkObject.Functions.GetPlayer(src)
        if Player then
            playerData = {
                job = Player.PlayerData.job.name
            }
        end
    end
    
    return playerData
end)

-- Lấy thông tin xe theo biển số
lib.callback.register('xn_pdtools:getVehicleInfo', function(source, plate)
    local src = source
    
    -- Kiểm tra quyền trước
    local playerJob = lib.callback.await('xn_pdtools:getPlayerJob', src)
    if not playerJob then return nil end
    
    local hasPermission = false
    for _, job in ipairs(Config.AllowedJobs) do
        if playerJob.job == job then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then return nil end
    
    -- Làm sạch biển số (loại bỏ khoảng trắng)
    plate = plate:gsub("%s+", ""):upper()
    
    print('[xn_pdtools] Checking vehicle with plate: ' .. plate)
    
    -- Lấy thông tin xe
    local vehicleData = nil
    
    -- Kiểm tra trong config trước
    if Config.VehicleInfo[plate] then
        vehicleData = Config.VehicleInfo[plate]
        print('[xn_pdtools] Found vehicle in config')
    else
        -- Tạo dữ liệu mặc định
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
    
    -- Log việc kiểm tra
    TriggerEvent('xn_pdtools:logVehicleCheck', plate, vehicleData)
    
    return vehicleData
end)

-- Log khi có người kiểm tra xe
RegisterServerEvent('xn_pdtools:logVehicleCheck')
AddEventHandler('xn_pdtools:logVehicleCheck', function(plate, vehicleData)
    local src = source
    local playerName = GetPlayerName(src)
    local identifier = nil
    
    if Framework == 'ESX' and frameworkObject then
        local xPlayer = frameworkObject.GetPlayerFromId(src)
        if xPlayer then
            identifier = xPlayer.identifier
        end
    elseif Framework == 'QBCore' and frameworkObject then
        local Player = frameworkObject.Functions.GetPlayer(src)
        if Player then
            identifier = Player.PlayerData.citizenid
        end
    end
    
    print(string.format('[xn_pdtools] Player %s (%s) checked vehicle %s', 
        playerName, identifier or 'unknown', plate))
end)
