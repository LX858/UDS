IsTvPopupOpen = false
ActivePopupTvPos = nil
ActivePopupTvEntity = nil

-- Helper to find nearest TV (active in cache or nearest object in world)
function FindNearestTelevision()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local closestTv = nil
    local closestDist = 999.0
    local closestEntity = nil
    local closestHash = nil
    local closestPos = nil
    local isCache = false

    -- 1. If currently in camera view / interacting
    if IsLookingAtTV and televisionMenuPosition then
        local _, cacheEntry = GetTelevisionAtCoords(televisionMenuPosition)
        return {
            pos = televisionMenuPosition,
            entity = entityTagged,
            hash = entityTagged and GetEntityModel(entityTagged) or nil,
            cache = cacheEntry or TelevisionCache.menu,
            url = cacheEntry and cacheEntry.URL or (TelevisionCache.menu and TelevisionCache.menu.URL) or nil,
            time = cacheEntry and cacheEntry.time or 0,
        }
    end

    -- 2. Search active TVs in TelevisionCache
    for key, entry in pairs(TelevisionCache) do
        if entry.tvPos and key ~= "menu" then
            local dist = #(playerPos - entry.tvPos)
            local maxDist = (entry.distance or Config.visibleDistance) + 2.0
            if dist <= maxDist and dist < closestDist then
                closestDist = dist
                closestTv = entry
                closestPos = entry.tvPos
                closestEntity = entry.entityHit
                closestHash = entry.hash
                isCache = true
            end
        end
    end

    if isCache and closestTv then
        return {
            pos = closestPos,
            entity = closestEntity,
            hash = closestHash,
            cache = closestTv,
            url = closestTv.URL,
            time = closestTv.time or 0,
        }
    end

    -- 3. Search for nearby physical TV objects
    for modelHash, modelData in pairs(Config.resolution) do
        local maxOpenDist = (modelData.distanceToOpen or Config.DefaultOpenDistance) + 5.0
        local found = GetClosestObjectOfType(playerPos, maxOpenDist, modelHash, false, false, false)
        if found ~= 0 and DoesEntityExist(found) then
            local entityPos = GetEntityCoords(found)
            local dist = #(playerPos - entityPos)
            if dist < closestDist then
                closestDist = dist
                closestEntity = found
                closestHash = modelHash
                local tvPos = GetTelevisionMetaData(modelHash, found)
                closestPos = tvPos or entityPos
            end
        end
    end

    if closestEntity then
        local _, cacheEntry = GetTelevisionAtCoords(closestPos)
        return {
            pos = closestPos,
            entity = closestEntity,
            hash = closestHash,
            cache = cacheEntry,
            url = cacheEntry and cacheEntry.URL or nil,
            time = cacheEntry and cacheEntry.time or 0,
        }
    end

    return nil
end

-- Open Interactive TV Popup UI
function OpenTvPopup()
    if IsTvPopupOpen then
        CloseTvPopup()
        return
    end

    local tvData = FindNearestTelevision()
    if not tvData then
        local noTvMsg = _U("no_tv_nearby")
        if not noTvMsg or noTvMsg:find("There isnt such") then
            noTvMsg = "Không tìm thấy màn hình TV nào gần bạn!"
        end
        showNotification(noTvMsg)
        return
    end

    ActivePopupTvPos = tvData.pos
    ActivePopupTvEntity = tvData.entity

    local currentUrl = tvData.url or ""
    local currentTime = tvData.time or 0
    local isStandby = (currentUrl == "" or currentUrl == "nil dui url" or currentUrl:find("html/menu/menu.html"))

    IsTvPopupOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        type = "open_tv_popup",
        url = currentUrl,
        time = currentTime,
        volume = PlayerTelevisionVolume,
        listVideos = Config.listVideos,
        isStandby = isStandby,
        tvPos = tvData.pos,
    })
end

-- Close Interactive TV Popup UI
function CloseTvPopup()
    if not IsTvPopupOpen then return end
    IsTvPopupOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "close_tv_popup"
    })
end

-- Command /showui
RegisterCommand("showui", function()
    OpenTvPopup()
end, false)

-- Exports
exports("OpenTvPopup", OpenTvPopup)
exports("CloseTvPopup", CloseTvPopup)

-- Chat suggestion
CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/showui", "Hiển thị màn hình TV dạng popup tương tác chuột và bàn phím")
end)

-- NUI Callbacks
RegisterNUICallback("close_tv_popup", function(data, cb)
    IsTvPopupOpen = false
    SetNuiFocus(false, false)
    if cb then cb("ok") end
end)

RegisterNUICallback("tv_popup_play_url", function(data, cb)
    local url = data.url
    if url and url ~= "" then
        url = url:gsub(" ", "")

        local isAllowed = true
        local isBlacklisted = false

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
            if cb then cb("error") end
            return
        end

        local targetEntity = ActivePopupTvEntity or entityTagged
        local targetPos = ActivePopupTvPos or televisionMenuPosition
        local modelHash = 0

        if targetEntity and DoesEntityExist(targetEntity) then
            modelHash = GetEntityModel(targetEntity)
        end

        if modelHash ~= 0 and IsModelTelevision(modelHash) then
            local videoTime = GetTimeFromUrl(url)
            PlayVideoOnTelevision(modelHash, targetEntity, url, videoTime)
            showNotification(_U("tvstation_changed", url))
        else
            -- If modelHash not available directly, broadcast cache add with targetPos
            TriggerServerEvent("rcore_television:AddTelevisionToCache", {
                redirect = GetRedirectFromURL(url),
                time = 0,
                URL = url,
                tvPos = targetPos,
                tvSize = vector3(0.7, 0.4, 0.0),
                rot = vector3(0, 0, 0),
                bucketID = PlayerBucketID,
                distance = Config.visibleDistance,
                scaleformLoaded = false,
                scaleformName = "television_scaleform_1",
                scaleformId = nil,
                entityHit = targetEntity,
                hash = modelHash ~= 0 and modelHash or 1036195894,
            })
            showNotification(_U("tvstation_changed", url))
        end
    end
    if cb then cb("ok") end
end)

RegisterNUICallback("tv_popup_stop", function(data, cb)
    local targetPos = ActivePopupTvPos or televisionMenuPosition
    if targetPos then
        TriggerServerEvent("rcore_television:stopTelevisionAtCoords", targetPos)
        showNotification(_U("stopped_program"))
    end
    if cb then cb("ok") end
end)

RegisterNUICallback("tv_popup_set_volume", function(data, cb)
    local volume = tonumber(data.volume)
    if volume and volume >= 0 and volume <= 100 then
        PlayerTelevisionVolume = volume
        DestroyDuiAndScaleform()
    end
    if cb then cb("ok") end
end)
