GlobalScaleformID = -1

RedirectType = {
    MENU      = "menu",
    OTHER     = "other",
    SUPPORTED = "SUPPORTED",
}

if Config.TargetZoneType ~= TargetType.NO_TARGET then
    Config.DetectorType = 2
    CreateThread(function()
        for modelHash, modelData in pairs(Config.resolution) do
            CreateTargetModel(modelHash, {
                {
                    distance        = modelData.distanceToOpen,
                    num             = 1,
                    type            = "client",
                    event           = "rcore_television:openNearTelevision",
                    icon            = _U("target_icon"),
                    label           = _U("target_label"),
                    targeticon      = _U("target_targeticon"),
                    canInteract     = function(entity, distance, coords) return true end,
                    drawColor       = { 255, 255, 255, 255 },
                    successDrawColor = { 30, 144, 255, 255 },
                    eventAction     = "open_tv",
                }
            })
        end
    end)
end

CreateThread(function()
    while true do
        Wait(1000)
        local playerPos = GetEntityCoords(PlayerPedId())
        for _, swapData in pairs(Config.ReplaceObjects) do
            local distToSwap = #(swapData.pos - playerPos)
            if distToSwap < 15 then
                if not swapData.swapped then
                    local obj = GetClosestObjectOfType(swapData.pos, 3.0, swapData.originalModelHash, false, false, false)
                    if obj == 0 then
                        obj = GetClosestObjectOfType(swapData.pos, 3.0, swapData.newModelHash, false, false, false)
                    end
                    local objModel = GetEntityModel(obj)
                    if objModel == swapData.newModelHash then
                        swapData.swapped = true
                    elseif obj ~= 0 and DoesEntityExist(obj) then
                        CreateModelSwap(swapData.pos.x, swapData.pos.y, swapData.pos.z, swapData.radius, swapData.originalModelHash, swapData.newModelHash, true)
                    end
                end
            else
                swapData.swapped = nil
            end
        end
    end
end)

if Config.Debug then
    CreateThread(function()
        while true do
            Wait(0)
            DrawUIText(string.format("Debug"), 0.5, 0.68)
            DrawUIText(string.format("Player bucket: %s", PlayerBucketID or -100), 0.5, 0.715)
            DrawUIText(string.format("Playing television count: %sx (Closest to you only)", GetTotalActiveTelevisionNearPlayer()), 0.5, 0.75)
        end
    end)
end

if Config.DetectorType == 1 then
    CreateThread(function()
        while true do
            Wait(1000)
            xpcall(function()
                local hit, _, _, _, entity = CastRayCast(PlayerPedId(), 4294967295, 5.0)
                if hit == 0 then
                    SendNUIMessage({ type = "hidedot" })
                elseif entity ~= 0 then
                    if GetEntityType(entity) ~= 0 then
                        if IsModelTelevision(GetEntityModel(entity)) then
                            SendNUIMessage({ type = "showdot" })
                        else
                            SendNUIMessage({ type = "hidedot" })
                        end
                    end
                end
            end, function() end)
        end
    end)
end

if Config.UsePreloaded then
    CreateThread(function()
        GlobalScaleformID = RequestScaleformMovie("television_scaleform_8")
    end)
end

CreateThread(function()
    while true do
        Wait(1000)
        local playerPos = GetEntityCoords(PlayerPedId())
        for _, tvData in pairs(Config.CreateTelevisionModelOnCoords) do
            local modelData = Config.resolution[tvData.ModelHash]
            if modelData then
                if not modelData.fake then
                    local dist = #(playerPos - tvData.Position)
                    local spawnRange = modelData.distance + 15
                    if dist < spawnRange then
                        if not tvData.entity then
                            tvData.entity = CreateLocalObject(tvData.ModelHash, tvData.Position)
                            SetEntityHeading(tvData.entity, tvData.Heading)
                        end
                    else
                        if tvData.entity then
                            DeleteEntity(tvData.entity)
                            tvData.entity = nil
                        end
                    end
                end
            else
                Debug("Object", tvData.ModelHash, "cant be created because it aint in the Config.resolution")
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, tvData in pairs(Config.CreateTelevisionModelOnCoords) do
        if tvData.entity then
            DeleteEntity(tvData.entity)
        end
    end
end)
