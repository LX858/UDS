local utils = {}
local vehicleKeys = {}

local Config = require 'data'

function utils.formatPlate(plate)
    local plateType = type(plate)

    if plateType == 'string' then
        return plate:gsub('%s', ''):upper()
    elseif plateType == 'number' then
        if DoesEntityExist(plate) then
            return utils.formatPlate(GetVehicleNumberPlateText(plate))
        else
            lib.print.error(('Recived entity %s but does not exsist'):format(plate))
        end
    end
end


local keyRing = GetConvarInt('vehiclekeys_keyring', 0) == 1

--- Returns the entity from a netId
---@param plate string
---@return boolean
function utils.hasKey(plate)
    plate = utils.formatPlate(plate)


    if Config.useKeyItem then
        if keyRing then
            return lib.callback.await('Renewed-Vehiclekeys:server:hasKey', false, plate)
        else
            return exports.ox_inventory:GetItemCount('vehiclekey', { plate = plate }, true) > 0
        end
    end

    return vehicleKeys[plate]
end exports('hasKey', utils.hasKey)

function utils.setKeys(Keys)
    if not Config.useKeyItem and Keys and next(Keys) then
        vehicleKeys = Keys
    end
end

--- Sets the engine status of a vehicle and returns the new status
---@param vehicle number
---@return boolean
function utils.setEngineStatus(vehicle)
    if not vehicle then return false end

    local engineStatus = GetIsVehicleEngineRunning(vehicle)

    SetVehicleUndriveable(vehicle, not engineStatus)
    SetVehicleNeedsToBeHotwired(vehicle, false)

    if GetPedInVehicleSeat(vehicle, -1) > 0 then
        SetVehicleEngineOn(vehicle, engineStatus, false, true)
    else
        SetVehicleEngineOn(vehicle, engineStatus, true, true)
    end

    return engineStatus
end

--- Returns weather or not the player is allowed to lockpick this vehicle
---@param vehicle number
---@return boolean
function utils.canLockpick(vehicle)
    return true
end

--- Get the amount of peds inside of a vehicle
---@param vehicle number
---@return table
function utils.getPedsInCar(vehicle)
    local Peds = {}
    local pedAmt = 0

    if vehicle then
        for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
            local pedInSeat = GetPedInVehicleSeat(vehicle, seat)

            if pedInSeat > 0 and not IsPedAPlayer(pedInSeat) then
                pedAmt += 1
                Peds[pedAmt] = pedInSeat
            end
        end
    end

    return Peds
end

function utils.getClosestKeyCar()
    local vehicles = GetGamePool('CVehicle')
    local closestKeyCar
    local closestKeyCoords = 10.0
    local playerCoords = GetEntityCoords(cache.ped)

    if not cache.vehicle then
        for i = 1, #vehicles do
            local vehicle = vehicles[i]
            if DoesEntityExist(vehicle) then
                local dist = #(playerCoords - GetEntityCoords(vehicle))
                if dist <= closestKeyCoords then
                    local class = GetVehicleClass(vehicle)
                    if Config.vehicles[class] and not Config.vehicles[class].noLocks then
                        local plate = GetVehicleNumberPlateText(vehicle)
                        if utils.hasKey(plate) then
                            closestKeyCar = vehicle
                            closestKeyCoords = dist
                        end
                    end
                end
            end
        end
    end

    return closestKeyCar
end

--- Makes allt he ped flee within that vehicle
---@param vehicle number
function utils.pedFlee(vehicle)
    local peds, amount = utils.getPedsInCar(vehicle)

    if amount == 0 then return end

    for i = 1, #peds do
        local pedInSeat = peds[i]
        TaskLeaveVehicle(pedInSeat, vehicle, 0)
        PlayPain(pedInSeat, 6, 0)
        Wait(1000)
        ClearPedTasksImmediately(pedInSeat)
        PlayPain(pedInSeat, math.random(7, 8), 0)
        SetPedFleeAttributes(pedInSeat, 0, 0)
        TaskReactAndFleePed(pedInSeat, cache.ped)
    end
end

---Displays TextUI on the players screen
---@param text string
function utils.textUi(text)
    lib.showTextUI(text, {
        position = 'left-center',
    })
end

function utils.hideTextUi()
    lib.hideTextUI()
end

function utils.notify(message, type)
    lib.notify({
        description = message,
        type = type
    })
end


--- Returns true/false depending if the player completed the lockpick minigame using Untangle Game
---@param item string|number? The item name or difficulty level
---@param difficulty number? The difficulty level (0.0 - 1.0)
---@param pins number? Number of pins to pick
---@return boolean
function utils.lockpickGame(item, difficulty, pins)
    -- Untangle Game chạy async, cần đợi kết quả
    local finished = false
    local result = false
    
    -- Kiểm tra xem skillchecks (Untangle) có tồn tại không
    if GetResourceState('skillchecks') ~= 'started' then
        -- Fallback to ox_lib skillcheck
        local game = {}
        for i = 1, (pins or 3) do
            local time = math.floor((difficulty or 0.6) * 100)
            game[i] = {areaSize = math.random(time, math.ceil(time * 1.5)), speedMultiplier = 1}
        end
        return lib.skillCheck(game, Config.keys)
    end

    exports['skillchecks']:startUntangleGame(15000, 10, function(success)
        result = success
        finished = true
    end)
    
    -- Đợi cho đến khi minigame hoàn thành
    while not finished do
        Wait(100)
    end
    
    return result == true
end

--- Returns true/false depending if the player completed the hotwire minigame using Circuit Breaker
---@return boolean?
function utils.hotwireMinigame()
    -- Kiểm tra xem glitch-minigames (Circuit Breaker) có tồn tại không
    if GetResourceState('glitch-minigames') ~= 'started' then
        -- Fallback to ox_lib skillcheck (easy mode for hotwire)
        return lib.skillCheck({'easy', 'easy', 'medium'}, Config.keys)
    end

    -- Call Circuit Breaker export
    -- params: levelNumber (1-6), difficultyLevel (0-?), ...
    local result
    local callSuccess = pcall(function()
        -- levelNumber: 6 (Bản đồ phức tạp nhất), difficultyLevel: 1 (Tốc độ bình thường)
        result = exports['glitch-minigames']:StartCircuitBreaker(5, 0.5)
    end)
    
    if not callSuccess then
        -- Fallback to t3_lockpick if StartCircuitBreaker fails
        if GetResourceState('t3_lockpick') == 'started' then
            return exports["t3_lockpick"]:startLockpick(0.6, 1.5) == true
        end
        return false
    end
    
    return result == true
end

function utils.stateBagWrapper(keyFilter, cb)
    return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value, _, replicated)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)

        if not netId then return end

        local loaded
        -- pcall để tránh lỗi console "failed to resolve callback" khi entity chưa load (vd: player mới vào game)
        pcall(function()
            loaded = lib.waitFor(function()
                if NetworkDoesEntityExistWithNetworkId(netId) then return true end
            end, nil, 3500)
        end)

        if not loaded then
            -- Entity không tồn tại sau 3.5s, bỏ qua không xử lý
            return
        end

        local entity = NetToVeh(netId)

        if entity and entity > 0 then
            cb(entity, value)
        end
    end)
end

---Alerts the police that the player is stealing or lockpicking a vehicle
---@param vehicle number EntityId
---@param itemName string|nil Name of the lockpick item used
function utils.alertLockpick(vehicle, itemName)
    -- Nếu dùng advanced lockpick, tự động báo cảnh sát
    if itemName == 'advalockpicknced' then
        local coords = GetEntityCoords(vehicle)
        local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)
        
        -- Xác định loại phương tiện
        local class = GetVehicleClass(vehicle)
        local vehicleType = "xe"
        if class == 14 then
            vehicleType = "thuyền"
        elseif class == 15 then
            vehicleType = "trực thăng"
        elseif class == 16 then
            vehicleType = "máy bay"
        end
        
        -- Gọi ld-dispatch
        if GetResourceState('ld-dispatch') == 'started' then
            exports['ld-dispatch']:sendDispatch({
                title = "Phá khóa " .. vehicleType,
                code = "10-35",
                values = {
                    {
                        text = "Địa điểm: " .. street,
                        icon = "fa-solid fa-location-dot",
                    },
                    {
                        text = "Loại: Phá khóa cửa " .. vehicleType .. " nâng cao", 
                        icon = "fa-solid fa-car",
                    },
                },
                jobs = {"police"},
                coords = coords,
                blip = {
                    blipid = 225,
                    blipcolor = 1,
                }
            })
        -- Fallback cho ps-dispatch
        elseif GetResourceState('ps-dispatch') == 'started' then
            exports['ps-dispatch']:VehicleTheft(vehicle)
        -- Fallback cho cd_dispatch
        elseif GetResourceState('cd_dispatch') == 'started' then
            local data = exports['cd_dispatch']:GetPlayerInfo()
            TriggerServerEvent('cd_dispatch:AddNotification', {
                job_table = {'police'},
                coords = coords,
                title = '10-35 - Trộm ' .. vehicleType,
                message = 'Phá khóa ' .. vehicleType .. ' tại '..street,
                flash = 0,
                unique_id = data.unique_id,
                sound = 1,
                blip = {
                    sprite = 225,
                    scale = 1.0,
                    colour = 3,
                    flashes = false,
                    text = '10-35 - Trộm ' .. vehicleType,
                    time = 5 * 60 * 1000,
                    radius = 0,
                }
            })
        -- Fallback mặc định
        else
            TriggerServerEvent('police:server:policeAlert', 'Phá khóa ' .. vehicleType .. ' nâng cao tại ' .. street)
        end
    end
    
    if cache.seat == -1 then
        -- Alert the police they are locking a vehicle engine
    else
        -- Alert the police they are lockpicking a vehicle door
    end
end

---Alerts the police that the player is hotwiring a vehicle
---@param vehicle number EntityId
---@param itemName string|nil Name of the lockpick item used
function utils.alertHotwire(vehicle, itemName)
    -- Nếu dùng advanced lockpick, tự động báo cảnh sát
    if itemName == 'advalockpicknced' then
        local coords = GetEntityCoords(vehicle)
        local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)
        
        -- Xác định loại phương tiện
        local class = GetVehicleClass(vehicle)
        local vehicleType = "xe"
        if class == 14 then
            vehicleType = "thuyền"
        elseif class == 15 then
            vehicleType = "trực thăng"
        elseif class == 16 then
            vehicleType = "máy bay"
        end
        
        -- Gọi ld-dispatch
        if GetResourceState('ld-dispatch') == 'started' then
            exports['ld-dispatch']:sendDispatch({
                title = "Đấu dây " .. vehicleType,
                code = "10-35",
                values = {
                    {
                        text = "Địa điểm: " .. street,
                        icon = "fa-solid fa-location-dot",
                    },
                    {
                        text = "Loại: Đấu dây khởi động " .. vehicleType, 
                        icon = "fa-solid fa-car-battery",
                    },
                },
                jobs = {"police"},
                coords = coords,
                blip = {
                    blipid = 225,
                    blipcolor = 1,
                }
            })
        -- Fallback cho ps-dispatch
        elseif GetResourceState('ps-dispatch') == 'started' then
            exports['ps-dispatch']:VehicleTheft(vehicle)
        -- Fallback cho cd_dispatch
        elseif GetResourceState('cd_dispatch') == 'started' then
            local data = exports['cd_dispatch']:GetPlayerInfo()
            TriggerServerEvent('cd_dispatch:AddNotification', {
                job_table = {'police'},
                coords = coords,
                title = '10-35 - Trộm ' .. vehicleType,
                message = 'Đấu dây khởi động ' .. vehicleType .. ' tại '..street,
                flash = 0,
                unique_id = data.unique_id,
                sound = 1,
                blip = {
                    sprite = 225,
                    scale = 1.0,
                    colour = 3,
                    flashes = false,
                    text = '10-35 - Trộm ' .. vehicleType,
                    time = 5 * 60 * 1000,
                    radius = 0,
                }
            })
        -- Fallback mặc định
        else
            TriggerServerEvent('police:server:policeAlert', 'Đấu dây khởi động ' .. vehicleType .. ' nâng cao tại ' .. street)
        end
    end
    -- Alert the police that im hotwiring a vehicle
end

---Alerts the police that the player is stealing a vehicle
---@param vehicle number EntityId
---@param ped number EntityId of the ped thats getting stolen from
function utils.alertVehicleTheft(vehicle, ped)
    --printt(vehicle, ped)
    -- Alert the police that im stealing a vehicle
end

return utils