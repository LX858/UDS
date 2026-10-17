if not lib then return end

local db = {}

function db.GetVehicleOwner(plate)
    local cb = MySQL.query.await('SELECT `owner` FROM `owned_vehicles` WHERE `plate` = ?', { plate })

    if not cb[1] then return false end

    return cb[1].owner or false
end


function db.StoreVehicle(plate, garage, properties)
    local cb = MySQL.update.await('UPDATE `owned_vehicles` SET `stored` = ?, `parking` = ?, `vehicle` = ? WHERE `plate` = ?', { 1, garage, json.encode(properties), plate })

    return cb
end


function db.GetPlayerVehicles(identifier, name)
    local data = {}
    local vehicles = MySQL.query.await('SELECT `vehicle` FROM `owned_vehicles` WHERE `owner` = ? AND `parking` = ?', { identifier, name })

    if vehicles[1] then
        for i = 1, #vehicles do
            local mods = json.decode(vehicles[i].vehicle)
            mods.plate = string.strtrim(mods.plate)

            data[mods.plate] = mods
        end
    end

    return data
end


function db.UpdateStored(plate, identifier, stored)
    -- When taking vehicle out (stored=0), also clear the parking field to prevent conflicts
    if stored == 0 then
        local result = MySQL.update.await('UPDATE `owned_vehicles` SET `stored` = ?, `parking` = NULL WHERE `plate` = ? AND `owner` = ?', { stored, plate, identifier })
        return result
    else
        local result = MySQL.update.await('UPDATE `owned_vehicles` SET `stored` = ? WHERE `plate` = ? AND `owner` = ?', { stored, plate, identifier })
        return result
    end
end

function db.CheckVehicleState(plate, identifier)
    local cb = MySQL.query.await('SELECT `stored`, `parking` FROM `owned_vehicles` WHERE `plate` = ? AND `owner` = ?', { plate, identifier })
    
    if cb[1] then
        return cb[1].stored, cb[1].parking
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

-- IMPROVED: Allow impound retrieval for stored=0 vehicles regardless of world existence
function db.GetImpoundList(numb, identifier)
    if ImpoundList[numb] then
        local class = ImpoundList[numb].type
        local list = {}

        -- Get ALL vehicles with stored=0 (out/impounded) for this player and type
        local vehicles = MySQL.query.await('SELECT `vehicle` FROM `owned_vehicles` WHERE `owner` = ? and type = ? AND `stored` = 0', { identifier, class })

        if vehicles[1] then
            for i = 1, #vehicles do
                local mods = json.decode(vehicles[i].vehicle)
                if mods and mods.plate then
                    local modPlate = strtrim(mods.plate)
                    
                    -- Always add to impound list if stored=0, regardless of world existence
                    -- We'll handle world vehicle deletion during retrieval
                    list[modPlate] = mods
                    
                    --print('^3[IMPOUND]^7 Added vehicle to impound list: ' .. modPlate .. ' (stored=0)')
                end
            end

            return list
        end
    end

    return false
end

-- Get vehicles impounded by police (stored=2 = police impound)
function db.GetDepotList(identifier)
    local list = {}

    local vehicles = MySQL.query.await(
        'SELECT `vehicle` FROM `owned_vehicles` WHERE `owner` = ? AND `stored` = 2',
        { identifier }
    )

    if vehicles and vehicles[1] then
        for i = 1, #vehicles do
            local mods = json.decode(vehicles[i].vehicle)
            if mods and mods.plate then
                local plate = strtrim(mods.plate)
                list[plate] = mods
            end
        end
        return list
    end

    return {}
end

return db