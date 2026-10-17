local anyTvInRange = false
local tvDebugMode = false
PlayerBucketID = 0
TelevisionCache = {}
skipRender = false

local scaleFormList = Config.ScaleFormLists

local checkerThreadAlive = false
local renderThreadAlive = false

RegisterCommand("streamertelevision", function()
    skipRender = not skipRender
    if not skipRender then
        TriggerEvent("chat:addMessage", { args = { "^1[Television]", Config.Messages.streamer_off } })
    else
        TriggerEvent("chat:addMessage", { args = { "^1[Television]", Config.Messages.streamer_on } })
    end
end, false)

RegisterNetEvent(TriggerName("UpdatePlayerBucketID"))
AddEventHandler(TriggerName("UpdatePlayerBucketID"), function(bucketId)
    MegaDebug("UpdatePlayerBucketID start")
    PlayerBucketID = bucketId
    MegaDebug("UpdatePlayerBucketID stop")
    DestroyDuiAndScaleform()
    TelevisionCache = {}
    TriggerServerEvent("rcore_television:fetchCache")
end)

AddEventHandler("xsound:streamerMode", function(enabled)
    skipRender = enabled
    if not skipRender then
        TriggerEvent("chat:addMessage", { args = { "^1[Television]", Config.Messages.streamer_off } })
    else
        TriggerEvent("chat:addMessage", { args = { "^1[Television]", Config.Messages.streamer_on } })
    end
end)

RegisterCommand("dumpme", function()
    Dump(TelevisionCache, true)
end)

function GetUnoccupiedScaleform()
    for name, occupied in pairs(scaleFormList) do
        if occupied == false then
            return true, name
        end
    end
    return false, "none"
end

function SetScaleformOccupied(name)
    if scaleFormList[name] ~= nil then
        scaleFormList[name] = true
    end
end

function UnreleaseOccupiedScaleform(name)
    if scaleFormList[name] ~= nil then
        scaleFormList[name] = false
    end
end

function GetTotalActiveTelevisionNearPlayer()
    local count = 0
    for _, entry in pairs(TelevisionCache) do
        if entry.Rendering == true then
            count = count + 1
        end
    end
    return count
end

function CreateVirtualTelevision(key, tvData)
    local tvPos, tvSize, tvRot, tvDistance = GetTelevisionMetaData(tvData.ModelHash, tvData.entity)
    TelevisionCache[key] = {
        redirect          = GetRedirectFromURL(tvData.URL),
        time              = 0,
        URL               = tvData.URL,
        tvPos             = tvPos,
        tvSize            = tvSize,
        rot               = tvRot,
        distance          = tvDistance,
        scaleformLoaded   = false,
        scaleformName     = "television_scaleform_1",
        scaleformId       = nil,
        entityHit         = tvData.entity,
        hash              = tvData.ModelHash,
        Job               = tvData.Job,
        DisableCountTime  = tvData.DisableCountTime,
        DisableInteraction = tvData.DisableInteraction,
    }
end

CreateThread(function()
    while true do
        Wait(1000)
        if not checkerThreadAlive then
            Debug("The checker thread ended something is nil there.")
        end
        if not renderThreadAlive then
            Debug("Thread render ended")
        end
    end
end)

RegisterCommand("tvdebug", function()
    tvDebugMode = not tvDebugMode
    local msg = string.format("The TV debug state: %s", tvDebugMode)
    print(msg)
    TriggerEvent("chat:addMessage", { args = { msg } })
end)

CreateThread(function()
    while true do
        Wait(0)
        if not tvDebugMode then
            Wait(1000)
        else
            local playerPos = GetEntityCoords(PlayerPedId())
            for _, entry in pairs(TelevisionCache) do
                local dist = #(entry.tvPos - playerPos)
                if dist < entry.distance then
                    local line1 = string.format("\nScaleformID: %s \nEntity Model: %s\nRedirect Type: %s\nTelevision Bucket ID: %s",
                        entry.scaleformId, entry.hash, entry.redirect, entry.bucketID)
                    draw3DText(entry.tvPos, line1)
                    draw3DText(entry.tvPos - vector3(0, 0, 0.35),
                        string.format("\nPlayer Bucket ID: %s\nCurrent Time: %s", PlayerBucketID, entry.time))
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        checkerThreadAlive = false
        local playerPos = GetEntityCoords(PlayerPedId())
        anyTvInRange = false

        for key, entry in pairs(TelevisionCache) do
            local isJobAllowed = true

            if type(key) == "string" and key ~= "menu" then
                if entry.Job then
                    isJobAllowed = false
                    for jobName, grades in pairs(entry.Job) do
                        for _, grade in pairs(grades) do
                            if IsAtJob(jobName, grade) then
                                isJobAllowed = true
                                break
                            end
                        end
                    end
                end
            end

            local checkPos = entry.tvPos
            local inRange = #(checkPos - playerPos) < (entry.distance + 5)

            if Config.AllowNetworkedObjects and entry.NetID then
                if NetworkDoesEntityExistWithNetworkId(entry.NetID) then
                    checkPos = GetEntityCoords(NetToObj(entry.NetID))
                    inRange = #(checkPos - playerPos) < (entry.distance + 5)
                end
            end

            if inRange and isJobAllowed then
                if not skipRender then
                    local bucketMatch = entry.bucketID == PlayerBucketID or entry.bucketID == nil
                    if bucketMatch then
                        anyTvInRange = true
                        local hasSlot, slotName = GetUnoccupiedScaleform()
                        if hasSlot and not entry.scaleformLoaded then
                            entry.scaleformName = slotName
                            SetScaleformOccupied(slotName)
                            entry.scaleformLoaded = true
                            entry.scaleformId = RequestScaleformMovie(entry.scaleformName)

                            if entry.scaleformId == 0 then
                                print("The scaleform ID is 0! Some other resource from your server is using too much ◌RequestScaleformMovie◌ and doesnt release them!")
                                if Config.UsePreloaded then
                                    print("Using preloaded scaleform the preloaded scaleform ID is: " .. GlobalScaleformID)
                                    entry.scaleformId = GlobalScaleformID
                                end
                            end

                            Debug("trying to load: ", entry.scaleformName)
                            while not HasScaleformMovieLoaded(entry.scaleformId) do Wait(0) end
                            Debug("Loaded scaleform: ", entry.scaleformName)
                            Debug("Scaleform ID: ", entry.scaleformId)

                            entry.identifierNumber = math.random(9999999999)
                            entry.URL = entry.URL:gsub(" ", "")

                            local duiUrl = GetLoadingDUILink(entry.identifierNumber,
                                getSupportedLink(entry.redirect, entry.URL, PlayerTelevisionVolume, entry.time, entry.identifierNumber))

                            entry.txd = CreateRuntimeTxd("video" .. entry.scaleformId)
                            entry.duiObj = CreateDui(duiUrl, 1920, 1080)
                            entry.dui = GetDuiHandle(entry.duiObj)
                            CreateRuntimeTextureFromDuiHandle(entry.txd, "test" .. entry.scaleformId, entry.dui)

                            Debug("IsDuiAvailable, 108")
                            while not IsDuiAvailable(entry.duiObj) do Wait(0) end

                            BeginScaleformMovieMethod(entry.scaleformId, "SET_TEXTURE")
                            PushScaleformMovieFunction(entry.scaleformId, "SET_TEXTURE")
                            PushScaleformMovieMethodParameterString("video" .. entry.scaleformId)
                            PushScaleformMovieMethodParameterString("test" .. entry.scaleformId)
                            PushScaleformMovieFunctionParameterInt(0)
                            PushScaleformMovieFunctionParameterInt(0)
                            PushScaleformMovieFunctionParameterInt(1920)
                            PushScaleformMovieFunctionParameterInt(1080)
                            PopScaleformMovieFunctionVoid()

                            entry.Rendering = true
                        end
                    end
                end
            else
                if entry.scaleformLoaded and entry.duiLoaded then
                    entry.scaleformLoaded = false
                    entry.duiLoaded = false
                    entry.Rendering = false
                    Debug("DestroyDui | render_scaleform.lua | 155")
                    DestroyDui(entry.duiObj)
                    UnreleaseOccupiedScaleform(entry.scaleformName)
                    if GlobalScaleformID ~= entry.scaleformId then
                        SetScaleformMovieAsNoLongerNeeded(entry.scaleformId)
                    end
                    entry.scaleformName = nil
                    entry.scaleformId = nil
                end
            end
        end
        checkerThreadAlive = true
    end
end)

CreateThread(function()
    local lastPos = GetEntityCoords(PlayerPedId())
    while true do
        Wait(100)
        local playerPos = GetEntityCoords(PlayerPedId())
        local moved = #(lastPos - playerPos)
        if moved >= 0.2 then
            lastPos = playerPos
            if not anyTvInRange then Wait(1000) end
            for _, entry in pairs(TelevisionCache) do
                local redirectType = GetRedirectFromURL(entry.URL)
                if not Config.IgnorePositionUpdateCustomSupport[redirectType] then
                    if entry.duiObj and entry.duiLoaded then
                        DuiMessage(entry.duiObj, {
                            type = "rcore_tv_update_pos",
                            x = playerPos.x,
                            y = playerPos.y,
                            z = playerPos.z,
                        })
                        if Config.AllowNetworkedObjects and NetworkDoesEntityExistWithNetworkId(entry.NetID) then
                            local tvPos = GetEntityCoords(NetToObj(entry.NetID))
                            DuiMessage(entry.duiObj, {
                                type       = "rcore_tv_update_tv_pos",
                                x          = tvPos.x,
                                y          = tvPos.y,
                                z          = tvPos.z,
                                MaxDistance = entry.distance,
                                max_volume  = PlayerTelevisionVolume,
                            })
                        end
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        renderThreadAlive = false
        if not anyTvInRange then
            renderThreadAlive = true
            Wait(1000)
        end

        for _, entry in pairs(TelevisionCache) do
            if HasScaleformMovieLoaded(entry.scaleformId) then
                if Config.Editor then
                    local tvPos, tvSize, tvRot = GetTelevisionMetaData(entry.hash, entry.entityHit)
                    local adjustedSize = tvSize - vector3(xScale, yScale, zScale)
                    local drawPos = GetOffsetFromEntityInWorldCoords(entry.entityHit, xPosEdit, yPosEdit, zPosEdit)

                    if not Config.ScaleformPop then
                        BeginScaleformMovieMethod(entry.scaleformId, "SET_TEXTURE")
                        PushScaleformMovieMethodParameterString("video" .. entry.scaleformId)
                        PushScaleformMovieMethodParameterString("test" .. entry.scaleformId)
                        PopScaleformMovieFunctionVoid()
                    end

                    DrawScaleformMovie_3dNonAdditive(entry.scaleformId,
                        drawPos.x, drawPos.y, drawPos.z,
                        0, 0, entry.rot.z * -1,
                        2.0, 2.0, 2.0,
                        adjustedSize.x, adjustedSize.y, adjustedSize.z)
                else
                    if not Config.ScaleformPop then
                        BeginScaleformMovieMethod(entry.scaleformId, "SET_TEXTURE")
                        PushScaleformMovieMethodParameterString("video" .. entry.scaleformId)
                        PushScaleformMovieMethodParameterString("test" .. entry.scaleformId)
                        PopScaleformMovieFunctionVoid()
                    end

                    if entry.NetID then
                        if Config.AllowNetworkedObjects and NetworkDoesEntityExistWithNetworkId(entry.NetID) then
                            local netObj = NetToObj(entry.NetID)
                            local netPos, netSize, netRot = GetTelevisionMetaData(entry.hash, netObj)
                            DrawScaleformMovie_3dNonAdditive(entry.scaleformId,
                                netPos.x, netPos.y, netPos.z,
                                0, 0, netRot.z * -1,
                                2.0, 2.0, 2.0,
                                netSize.x, netSize.y, netSize.z)
                        end
                    else
                        DrawScaleformMovie_3dNonAdditive(entry.scaleformId,
                            entry.tvPos.x, entry.tvPos.y, entry.tvPos.z,
                            0, 0, entry.rot.z * -1,
                            2.0, 2.0, 2.0,
                            entry.tvSize.x, entry.tvSize.y, entry.tvSize.z)
                    end
                end
            end
        end
        renderThreadAlive = true
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        for _, entry in pairs(TelevisionCache) do
            if entry.duiLoaded and HasScaleformMovieLoaded(entry.scaleformId) then
                for pattern, handler in pairs(Config.ClickOnScreen) do
                    if string.match(entry.URL, pattern) ~= nil then
                        handler(entry.duiObj)
                    end
                end
            end
        end
        renderThreadAlive = true
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        for _, entry in pairs(TelevisionCache) do
            if entry.time and not entry.DisableCountTime then
                entry.time = entry.time + 1
            end
        end
    end
end)
