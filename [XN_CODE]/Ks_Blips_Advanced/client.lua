local createdBlips = {}

-- Create blips with proper font support
Citizen.CreateThread(function()
    -- Wait for config to be loaded
    while not Config or not Config.Blips do
        Citizen.Wait(100)
    end
    
    -- Register text entries and create blips
    for i, blipData in ipairs(Config.Blips) do
        -- Check if the blip has already been created
        if not createdBlips[blipData.id] then
            -- Register text entry for proper font support
            local textLabel = "BLIP_" .. blipData.id
            AddTextEntry(textLabel, blipData.name)
            
            -- Wait a frame to ensure text entry is registered
            Citizen.Wait(0)
            
            local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
            SetBlipSprite(blip, blipData.sprite)
            SetBlipDisplay(blip, blipData.display)
            SetBlipScale(blip, blipData.scale)
            SetBlipColour(blip, blipData.color)
            SetBlipAlpha(blip, blipData.alpha)
            SetBlipAsShortRange(blip, blipData.shortRange)

            -- Use registered text entry with proper font support
            BeginTextCommandSetBlipName(textLabel)
            EndTextCommandSetBlipName(blip)

            -- Mark the blip as created
            createdBlips[blipData.id] = true

            -- Create the radius blip if radius is specified in config
            if blipData.radius then
                local radiusBlip = AddBlipForRadius(blipData.coords.x, blipData.coords.y, blipData.coords.z, blipData.radius)
                SetBlipColour(radiusBlip, blipData.radiusBlipColor)
                SetBlipAlpha(radiusBlip, blipData.radiusBlipAlpha)
                createdBlips[blipData.id .. "_radius"] = radiusBlip
            end
        end
    end
end)
