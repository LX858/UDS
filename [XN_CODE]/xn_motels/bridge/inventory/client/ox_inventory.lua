if GetResourceState('ox_inventory') ~= 'started' then return end

OpenStash = function(data,identifier)
    -- Find motel config by motel string name
    local stashConfig = config.defaultStash
    
    for motelIndex, motelData in pairs(config.motels) do
        if motelData.motel == data.motel and motelData.stash then
            stashConfig = motelData.stash
            break
        end
    end
    
    TriggerEvent('ox_inventory:openInventory', 'stash', {
        id = 'stash_'..data.motel..'_'..identifier..'_'..data.index, 
        name = 'Storage - Room #'..data.index, 
        slots = stashConfig.slots, 
        weight = stashConfig.weight, 
        coords = GetEntityCoords(cache.ped)
    })
end