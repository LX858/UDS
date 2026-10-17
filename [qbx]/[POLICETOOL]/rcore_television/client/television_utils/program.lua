function PlayVideoOnTelevision(modelHash, entity, url, time)
    local tvPos, tvSize, tvRot, tvDistance, tvMeta = GetTelevisionMetaData(modelHash, entity)
    url = url:gsub(" ", "")

    local netId = nil
    if NetworkGetEntityIsNetworked(entity) then
        netId = ObjToNet(entity)
    end

    TriggerServerEvent("rcore_television:AddTelevisionToCache", {
        redirect        = GetRedirectFromURL(url),
        time            = time or 0,
        URL             = url,
        tvPos           = tvPos,
        tvSize          = tvSize,
        rot             = tvRot,
        bucketID        = PlayerBucketID,
        distance        = tvDistance,
        Job             = tvMeta.Job,
        scaleformLoaded = false,
        scaleformName   = "television_scaleform_1",
        scaleformId     = nil,
        entityHit       = entity,
        hash            = modelHash,
        NetID           = netId,
    })
end

RegisterCommand(Config.playUrl, function(source, args, rawCommand)
    if args[1] == nil then
        TriggerEvent("chat:addMessage", { args = { _U("playlink_info") } })
        return
    end

    if not IsPlayerLookingAtTV() then
        TriggerEvent("chat:addMessage", { args = { _U("cant_play_video") } })
        return
    end

    local commandPrefix = split(rawCommand, " ")[1]
    local url = rawCommand:gsub(commandPrefix, string.lower(commandPrefix))
    local _, endIndex = string.find(url, Config.playUrl .. " ")
    url = string.sub(url, endIndex)

    local isAllowed = true
    local isBlacklisted = false
    local _, customTv = GetCustomTelevision(televisionMenuPosition)
    if customTv then isAllowed = false end

    if Config.useWhitelist then
        isAllowed = false
        for _, pattern in pairs(Config.whitelisted) do
            if string.match(url, pattern) then
                isAllowed = true
                break
            end
        end
    end

    for _, pattern in pairs(Config.blackListed) do
        if string.match(url, pattern) then
            isAllowed = false
            isBlacklisted = true
            break
        end
    end

    if not isAllowed then
        if isBlacklisted then
            showNotification(_U("blacklisted_link"))
        else
            showNotification(_U("link_isnt_whitelisted"))
        end
    end

    if DoesEntityExist(entityTagged) and isAllowed then
        local modelHash = GetEntityModel(entityTagged)
        local _, tvEntry = GetTelevisionAtCoords(televisionMenuPosition)
        if tvEntry and tvEntry.DisableInteraction then return end

        ViewingTvMenu = false
        SelectedMenuItemIndex = 1

        local menuEntry = TelevisionCache.menu
        if menuEntry then
            if menuEntry.duiObj and menuEntry.duiLoaded then
                Debug("DestroyDui | program.lua | 90")
                DestroyDui(menuEntry.duiObj)
                SetScaleformMovieAsNoLongerNeeded(menuEntry.scaleformId)
            end
            UnreleaseOccupiedScaleform(menuEntry.scaleformName or "none")
        end
        TelevisionCache.menu = nil

        if IsModelTelevision(modelHash) then
            local videoTime = GetTimeFromUrl(url)
            PlayVideoOnTelevision(modelHash, entityTagged, url, videoTime)
            showNotification(_U("tvstation_changed", url))
        end
    end

    return true
end, false)
