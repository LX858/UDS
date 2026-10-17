CreateThread(function()
    while true do
        Wait(1000)
        local playerPos = GetEntityCoords(PlayerPedId())

        for tvId, tvData in pairs(Config.PlayingTelevisionOnLocation) do
            local resolution     = Config.resolution[tvData.ModelHash]
            local distanceToTV   = #(playerPos - tvData.Position)
            local spawnDistance  = resolution.distance + 15

            if distanceToTV < spawnDistance then
                if not tvData.entity then
                    local entity = CreateLocalObject(tvData.ModelHash, tvData.Position)
                    SetEntityHeading(entity, tvData.Heading)
                    tvData.entity = entity
                end

                if not TelevisionCache[tvId] then
                    if tvData.AddIdentifierToURL then
                        tvData.URL = tvData.URL .. "?identifier=" .. tvId
                    end
                    CreateVirtualTelevision(tvId, tvData)
                end
            else
                if tvData.entity then
                    DeleteEntity(tvData.entity)
                    tvData.entity = nil
                end
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for tvId, tvData in pairs(Config.PlayingTelevisionOnLocation) do
        if tvData.entity then
            DeleteEntity(tvData.entity)
        end
    end
end)
