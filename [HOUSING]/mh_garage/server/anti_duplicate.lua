-- Anti-duplicate vehicle system
-- This script prevents and cleans up duplicate vehicles

local function CleanupDuplicateVehicles()
    local worldVehicles = GetAllVehicles()
    local plateCount = {}
    local duplicates = {}
    
    -- Count vehicles by plate
    for i = 1, #worldVehicles do
        local vehicle = worldVehicles[i]
        if DoesEntityExist(vehicle) then
            local plateText = GetVehicleNumberPlateText(vehicle)
            if plateText then
                local plate = string.strtrim(plateText)
                
                if plate and plate ~= "" then
                    if not plateCount[plate] then
                        plateCount[plate] = {}
                    end
                    
                    table.insert(plateCount[plate], vehicle)
                end
            end
            Wait(10)
        end
    end
    
    -- Find and mark duplicates
    local totalDuplicates = 0
    for plate, vehicles in pairs(plateCount) do
        if #vehicles > 1 then
            -- Keep only the first vehicle, mark others as duplicates
            for i = 2, #vehicles do
                table.insert(duplicates, vehicles[i])
                totalDuplicates = totalDuplicates + 1
            end
        end
    end
    
    -- Delete duplicates
    for i = 1, #duplicates do
        DeleteEntity(duplicates[i])
    end
    
    if totalDuplicates > 0 then
        --print("^3[mh_garage] ^7Cleanup completed: Removed", totalDuplicates, "duplicate vehicles")
    else
        --print("^2[mh_garage] ^7No duplicate vehicles found")
    end
end

-- Run cleanup on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Wait a bit for server to fully start
        Wait(5000)
        CleanupDuplicateVehicles()
    end
end)

-- Optionally run periodic cleanup (every 30 minutes)
if GetConvar('mh_garage_periodic_cleanup', 'false') == 'true' then
    SetInterval(CleanupDuplicateVehicles, 1800000) -- 30 minutes
end