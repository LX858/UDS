if not lib then return end

local db = {}

MySQL.ready(function()
    local datatype = MySQL.query.await('SHOW COLUMNS FROM `player_vehicles`')
    local hasType = false
    local hasDismantleLockTime = false

    for i = 1, #datatype do
        if datatype[i].Field == 'type' then
            hasType = true
        elseif datatype[i].Field == 'dismantle_lock_time' then
            hasDismantleLockTime = true
        end
    end

    if not hasType then
        MySQL.query('ALTER TABLE `player_vehicles` ADD COLUMN type varchar(20) NOT NULL DEFAULT "car"')
    end

    if not hasDismantleLockTime then
        MySQL.query('ALTER TABLE `player_vehicles` ADD COLUMN dismantle_lock_time INT(11) DEFAULT NULL')
    end
end)

function db.GetVehicleOwner(plate)
    local cb = MySQL.query.await('SELECT `citizenid` FROM `player_vehicles` WHERE `plate` = ?', { plate })

    if not cb[1] then return false end

    return cb[1].citizenid or false
end


function db.StoreVehicle(plate, garage, properties, class)
    -- Trim plate to match database format
    plate = string.strtrim(plate)
    
    --print('^5[DB STORE]^7 Attempting to store vehicle | Plate: "' .. plate .. '" | Garage: "' .. garage .. '" | Class: ' .. class)
    
    local cb = MySQL.update.await('UPDATE `player_vehicles` SET `state` = ?, `garage` = ?, `mods` = ?, `type` = ? WHERE `plate` = ?', { 1, garage, json.encode(properties), class, plate })
    
    --print('^5[DB STORE]^7 Store result: ' .. tostring(cb) .. ' row(s) affected')
    
    -- if cb == 0 then
    --     --print('^1[DB STORE ERROR]^7 No rows updated! Vehicle with plate "' .. plate .. '" may not exist in database')
    -- end
    
    return cb
end


function db.GetPlayerVehicles(identifier, name)
    --print('^5[DB GET]^7 Querying vehicles | Identifier: ' .. identifier .. ' | Garage: ' .. name .. ' | State: 1')
    
    -- Only get vehicles that are actually IN the garage (state = 1)
    -- Include vehicle column which contains the spawn name
    local vehicles = MySQL.query.await('SELECT `mods`, `plate`, `vehicle` FROM `player_vehicles` WHERE `citizenid` = ? AND `garage` = ? AND `state` = 1', { identifier, name })
    local data = {}

    --print('^5[DB GET]^7 Query returned ' .. #vehicles .. ' vehicle(s)')

    if vehicles[1] then
        for i = 1, #vehicles do
            local mods = json.decode(vehicles[i].mods)
            mods.plate = string.strtrim(mods.plate)
            -- Store vehicle spawn name for image lookup
            mods.vehicle = vehicles[i].vehicle or mods.model

            data[mods.plate] = mods
            --print('^5[DB GET]^7 Loaded vehicle #' .. i .. ': ' .. mods.plate .. ' | Model: ' .. (mods.model or 'unknown'))
        end
    end

    return data
end


function db.UpdateStored(plate, identifier, stored)
    -- When taking vehicle out (state=0), also clear the garage field to prevent conflicts
    if stored == 0 then
        local result = MySQL.update.await('UPDATE `player_vehicles` SET `state` = ?, `garage` = NULL WHERE `plate` = ? AND `citizenid` = ?', { stored, plate, identifier })
        return result
    else
        local result = MySQL.update.await('UPDATE `player_vehicles` SET `state` = ? WHERE `plate` = ? AND `citizenid` = ?', { stored, plate, identifier })
        return result
    end
end

function db.CheckVehicleState(plate, identifier)
    local cb = MySQL.query.await('SELECT `state`, `garage` FROM `player_vehicles` WHERE `plate` = ? AND `citizenid` = ?', { plate, identifier })
    
    if cb[1] then
        return cb[1].state, cb[1].garage
    end
    
    return false, false
end

function db.DeleteWorldVehiclesByPlate(plate)
    local worldVehicles = GetAllVehicles()
    local deletedCount = 0
    
    if #worldVehicles > 0 then
        for i = 1, #worldVehicles do
            local vehicle = worldVehicles[i]
            if DoesEntityExist(vehicle) then
                local vehiclePlate = GetVehicleNumberPlateText(vehicle)
                
                if vehiclePlate and string.strtrim(vehiclePlate) == string.strtrim(plate) then
                    DeleteEntity(vehicle)
                    deletedCount = deletedCount + 1
                end
            end
        end
    end
    
    return deletedCount
end

local ImpoundList = lib.load 'config.impound'.Locations
local strtrim = string.strtrim

local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetVehiclePetrolTankHealth = GetVehiclePetrolTankHealth
local GetVehicleBodyHealth = GetVehicleBodyHealth

-- IMPROVED: Allow impound retrieval for state=0 vehicles regardless of world existence
function db.GetImpoundList(numb, identifier)
    if ImpoundList[numb] then
        local class = ImpoundList[numb].type
        local list = {}

        -- Get ALL vehicles with state=0 (out/impounded) for this player and type
        local vehicles = MySQL.query.await('SELECT `mods` FROM `player_vehicles` WHERE `citizenid` = ? and type = ? AND `state` = 0', { identifier, class })

        if vehicles[1] then
            for i = 1, #vehicles do
                local mods = json.decode(vehicles[i].mods)
                if mods and mods.plate then
                    local modPlate = strtrim(mods.plate)
                    
                    -- Always add to impound list if state=0, regardless of world existence
                    -- We'll handle world vehicle deletion during retrieval
                    list[modPlate] = mods
                    
                    ----print('^3[IMPOUND]^7 Added vehicle to impound list: ' .. modPlate .. ' (state=0)')
                end
            end

            return list
        end
    end

    return false
end

-- Get vehicles impounded by police (state=2 = police impound)
function db.GetDepotList(identifier)
    local list = {}

    local vehicles = MySQL.query.await(
        'SELECT `mods` FROM `player_vehicles` WHERE `citizenid` = ? AND `state` = 2',
        { identifier }
    )

    if vehicles and vehicles[1] then
        for i = 1, #vehicles do
            local mods = json.decode(vehicles[i].mods)
            if mods and mods.plate then
                local plate = strtrim(mods.plate)
                list[plate] = mods
            end
        end
        return list
    end

    return {}
end

-- Get ALL vehicles for recover menu (regardless of state)
function db.GetAllVehiclesForRecover(identifier)
    local list = {}

    local vehicles = MySQL.query.await(
        'SELECT `mods`, `state`, `garage` FROM `player_vehicles` WHERE `citizenid` = ?',
        { identifier }
    )

    if vehicles and vehicles[1] then
        for i = 1, #vehicles do
            local mods = json.decode(vehicles[i].mods)
            if mods and mods.plate then
                local plate = strtrim(mods.plate)
                mods.dbState = vehicles[i].state  -- Attach state info
                mods.dbGarage = vehicles[i].garage  -- Attach garage info
                list[plate] = mods
            end
        end
        return list
    end

    return {}
end


return db