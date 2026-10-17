ItemsMenuLoaded = false

local function findCacheEntryByIdentifier(identifier)
    local identifierNum = tonumber(identifier)
    for tvId, tvData in pairs(TelevisionCache) do
        if identifierNum == tvData.identifierNumber or identifierNum == tvId then
            return tvId, tvData
        end
    end
    return nil, nil
end

RegisterNUICallback("duiHasLoaded", function(data, cb)
    MegaDebug("duiHasLoaded start")

    local tvId, tvData = findCacheEntryByIdentifier(data.identifier)
    if tvData then
        tvData.duiLoaded = true
        Debug("dui_events.lua | SetDUILink | 7", data.url)
        SetDUILink(tvData.duiObj, data.url)
        Debug("DUI Identifier", data.identifier, "has loaded with key", tvId, data.url)

        local playerPos = GetEntityCoords(PlayerPedId())
        DuiMessage(tvData.duiObj, {
            type = "rcore_tv_update_pos",
            x    = playerPos.x,
            y    = playerPos.y,
            z    = playerPos.z,
        })
    end

    MegaDebug("duiHasLoaded stop")
    if cb then cb("ok") end
end)

RegisterNUICallback("updatePos", function(data, cb)
    MegaDebug("updatePos start")

    local identifierNum = tonumber(data.identifier)
    for tvId, tvData in pairs(TelevisionCache) do
        local matchesId    = identifierNum == tvData.identifierNumber or identifierNum == tvId
        local isLoaded     = tvData.duiLoaded == true
        if matchesId or isLoaded then
            local playerPos = GetEntityCoords(PlayerPedId())
            DuiMessage(tvData.duiObj, {
                type = "rcore_tv_update_pos",
                x    = playerPos.x,
                y    = playerPos.y,
                z    = playerPos.z,
            })
            break
        end
    end

    MegaDebug("updatePos stop")
    if cb then cb("ok") end
end)

RegisterNUICallback("loaded", function(data, cb)
    MegaDebug("loaded start")

    -- Mark matching entry as loaded; also mark menu entries
    for tvId, tvData in pairs(TelevisionCache) do
        local identifierNum  = tonumber(data.identifier)
        local matchesId      = identifierNum == tvData.identifierNumber or identifierNum == tvId
        if matchesId and tvData.duiLoaded then
            tvData.duiLoaded = tvData.isMenu and true or tvData.duiLoaded
        elseif not matchesId and tvData.isMenu then
            tvData.duiLoaded = true
        end
    end

    if data.isMenu then
        local tvCacheKey, tvCacheData = GetTelevisionAtCoords(televisionMenuPosition)

        for index, videoEntry in pairs(Config.listVideos) do
            Wait(100)
            local targetDuiObj = tvCacheData and tvCacheData.duiObj
                or (TelevisionCache.menu and TelevisionCache.menu.duiObj)

            if targetDuiObj then
                DuiMessage(targetDuiObj, {
                    type  = "rcore_tv_add_tv",
                    title = videoEntry.name,
                    icon  = videoEntry.icon,
                    index = index,
                })
            end
        end

        local activateDuiObj = tvCacheData and tvCacheData.duiObj
            or (TelevisionCache.menu and TelevisionCache.menu.duiObj)

        if activateDuiObj then
            DuiMessage(activateDuiObj, { type = "active_first" })
        end

        ItemsMenuLoaded = true
    else
        for tvId, tvData in pairs(TelevisionCache) do
            if tvData.duiObj and tvData.duiLoaded then
                Debug("IsDuiAvailable, 49")
                if IsDuiAvailable(tvData.duiObj) then
                    DuiMessage(tvData.duiObj, {
                        type       = "rcore_tv_update_tv_volume",
                        max_volume = PlayerTelevisionVolume,
                    })
                    DuiMessage(tvData.duiObj, {
                        type        = "rcore_tv_update_tv_pos",
                        x           = tvData.tvPos.x,
                        y           = tvData.tvPos.y,
                        z           = tvData.tvPos.z,
                        MaxDistance = tvData.distance,
                        max_volume  = PlayerTelevisionVolume,
                    })
                end
            end
        end
    end

    MegaDebug("loaded stop")
    if cb then cb("ok") end
end)
