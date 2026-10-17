if not lib then return end

local Edit = {}

function Edit.SetFuel(vehicle, fuel)
    -- Support for cdn-fuel system
    local success = false
    
    if GetResourceState('cdn-fuel') == 'started' then
        local ok, result = pcall(function()
            exports['cdn-fuel']:SetFuel(vehicle, fuel)
        end)
        if ok then
            success = true
            --print('^2[FUEL]^7 Set fuel using cdn-fuel:', fuel)
        else
            --print('^1[FUEL ERROR]^7 cdn-fuel failed:', result)
        end
    end
    
    if not success then
        -- Fallback to native
        SetVehicleFuelLevel(vehicle, fuel)
        --print('^3[FUEL]^7 Set fuel using native:', fuel)
    end
end

function Edit.GetFuel(vehicle)
    -- Support for cdn-fuel system
    if GetResourceState('cdn-fuel') == 'started' then
        local ok, result = pcall(function()
            return exports["cdn-fuel"]:GetFuel(vehicle)
        end)
        if ok and result then
            --print('^2[FUEL]^7 Got fuel using cdn-fuel:', result)
            return result
        else
            --print('^1[FUEL ERROR]^7 cdn-fuel get failed, using native')
        end
    end
    
    -- Fallback to native
    local fuel = GetVehicleFuelLevel(vehicle)
    --print('^3[FUEL]^7 Got fuel using native:', fuel)
    return fuel
end


function Edit.GiveCarKey(vehicle, plate)
    if Shared.qb then
        -- TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end
end


function Edit.Notify(description, type)
    lib.notify({
        description = description,
        duration = 4500,
        type = type,
        position = 'bottom'
    })
end


function Edit.RemoveKeys(vehicle, plate)
    
end


function Edit.OnExitGarage()
    -- myb weather?
end


RegisterNetEvent('mh_garage:Notify', Edit.Notify)

return Edit