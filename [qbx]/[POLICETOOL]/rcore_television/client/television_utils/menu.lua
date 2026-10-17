SelectedMenuItemIndex = 1
local menuUrl = "nui://rcore_television/html/menu/menu.html"
local tvCamera = nil
local needsCacheRefresh = false
TempBlockMenu = false
TempBlockEnter = false
IsLookingAtTV = false
ViewingTvMenu = false
televisionMenuPosition = nil
entityTagged = nil
distance = nil
rotation = nil
size = nil

RegisterKey(function()
    if not ViewingTvMenu then return end
    local videoEntry = Config.listVideos[SelectedMenuItemIndex]
    if videoEntry then
        if videoEntry.url then
            ExecuteCommand(Config.playUrl .. " " .. videoEntry.url)
        else
            Debug("List Video index does exists but URL doesnt exists", SelectedMenuItemIndex)
        end
    else
        Debug("List Video index doesnt exists", SelectedMenuItemIndex)
    end
end, "changeTvProgram", "Will change TV program", Config.keyToSelectProgram or "RETURN")

function openNearTelevision()
    if IsLookingAtTV or TempBlockMenu or TempBlockEnter then return end
    if Config.Editor then return end

    local hit, _, _, entity = CastRayCast(PlayerPedId(), 4294967295, 5.0)
    local detectorType = Config.DetectorType

    if detectorType == 2 then
        hit = 1
        entity = 1
        local playerPos = GetEntityCoords(PlayerPedId())
        for modelHash, modelData in pairs(Config.resolution) do
            local found = GetClosestObjectOfType(playerPos, modelData.distanceToOpen + 0.001, modelHash, false, false, false)
            local foundDist = #(GetEntityCoords(found) - playerPos)
            if foundDist <= modelData.distanceToOpen and GetEntityModel(found) == modelHash then
                entity = found
                break
            end
        end
    end

    if hit == 0 then return end

    if detectorType == 1 and GetEntityType(entity) == 0 then return end

    local modelHash = GetEntityModel(entity)
    if not IsModelTelevision(modelHash) then return end

    local tvCoords = GetEntityCoords(entity)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local tvDist = #(tvCoords - playerCoords)
    local openDist = (Config.resolution[modelHash] and Config.resolution[modelHash].distanceToOpen) or Config.DefaultOpenDistance

    if tvDist >= openDist then return end

    if not YourSpecialPermission() then
        showNotification(_U("not_vip"))
        return
    end

    local camPos, camRot = GetTelevisionCameraData(modelHash, entity)
    local tvPos, tvSize, tvRot, tvDistance, tvMeta = GetTelevisionMetaData(modelHash, entity)

    metaData = tvMeta
    distance = tvDistance
    rotation = tvRot
    size = tvSize
    televisionMenuPosition = tvPos

    local camCoords = GetGameplayCamCoord()
    local camCurrentRot = GetGameplayCamRot()
    local canOpen = true
    local hasDuiTV = false
    local rotationOffset = vector3(0, 0, 0)

    if tvMeta then
        if tvMeta.ItemToOpen then
            local p = promise.new()
            callCallback(TriggerName("DoesPlayerHaveCertain"), function(result)
                p:resolve(result)
            end, tvMeta.ItemToOpen)
            local hasItem = Citizen.Await(p)
            if not hasItem then
                local itemList = ""
                for _, itemName in pairs(tvMeta.ItemToOpen) do
                    itemList = itemName .. " / " .. itemList
                end
                itemList = itemList:sub(1, -4)
                showNotification(_U("doesnt_have_remote", itemList))
                return
            end
        end
    end

    entityTagged = entity

    local _, modelDataByHash = GetModelDataByHash(modelHash)
    if modelDataByHash then
        if modelDataByHash.CameraOffSet and modelDataByHash.CameraOffSet.rotationOffset then
            rotationOffset = modelDataByHash.CameraOffSet.rotationOffset
        end
        canOpen = false
        if IsTelevisionSuitableForJob(modelDataByHash) then canOpen = true end
    end

    local cacheIndex, cacheEntry = GetTelevisionAtCoords(televisionMenuPosition)
    if cacheEntry then
        canOpen = false
        hasDuiTV = false
        if IsTelevisionSuitableForJob(cacheEntry) then canOpen = true end
        if cacheEntry.DisableInteraction then return end
        if cacheEntry.DisableInteraction == nil then
            if type(cacheIndex) == "string" and cacheIndex ~= "menu" then
                hasDuiTV = true
            end
        end
    end

    local _, customTvEntry = GetCustomTelevision(televisionMenuPosition)
    if customTvEntry then
        canOpen = false
        if IsTelevisionSuitableForJob(customTvEntry) then canOpen = true end
    end

    if not canOpen then return end

    if not hasDuiTV then
        ShowHelpNotification(_U("switch_to_menu"), false, false, 10000)
    end

    TempBlockEnter = true
    tvCamera = CreateCamera("tv_cam", camCoords, camCurrentRot, 50.0)
    IsLookingAtTV = true

    if canOpen then
        OpenTVMenu()
        needsCacheRefresh = false
    end

    CreateThread(function()
        while tvCamera ~= nil do
            Wait(0)
            Config.SetPlayerInvisible()
        end
    end)

    FreezeEntityPosition(PlayerPedId(), true)
    tvCamera.Render()
    Wait(16)
    tvCamera.ChangePosition(camPos, camPos, camRot - rotationOffset, 1000)
    TempBlockEnter = false

    -- Disable player controls while interacting with TV so keys like
    -- SPACE (jump), WASD (move), crouch, attack etc. don't fire on the ped
    CreateThread(function()
        while IsLookingAtTV do
            Wait(0)
            -- Movement
            DisableControlAction(0, 30, true)  -- INPUT_MOVE_LR  (A / D)
            DisableControlAction(0, 31, true)  -- INPUT_MOVE_UD  (W / S)
            DisableControlAction(0, 21, true)  -- INPUT_SPRINT
            DisableControlAction(0, 22, true)  -- INPUT_JUMP      (SPACE)
            DisableControlAction(0, 36, true)  -- INPUT_DUCK      (CTRL)
            DisableControlAction(0, 58, true)  -- INPUT_SNEAK
            -- Combat / weapons
            DisableControlAction(0, 24, true)  -- INPUT_ATTACK    (LMB)
            DisableControlAction(0, 25, true)  -- INPUT_AIM       (RMB)
            DisableControlAction(0, 47, true)  -- INPUT_MELEE_ATTACK_LIGHT
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_HEAVY
            DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_ALTERNATE
            DisableControlAction(0, 257, true) -- INPUT_ATTACK2
            -- Weapon wheel / switching
            DisableControlAction(0, 37, true)  -- INPUT_SELECT_WEAPON
            DisableControlAction(0, 157, true) -- INPUT_SELECT_PREV_WEAPON
            DisableControlAction(0, 158, true) -- INPUT_SELECT_NEXT_WEAPON
            -- Misc actions
            DisableControlAction(0, 23, true)  -- INPUT_ENTER
            DisableControlAction(0, 75, true)  -- INPUT_VEH_EXIT (F)
            DisableControlAction(0, 44, true)  -- INPUT_COVER
        end
    end)
end

if Config.TargetZoneType == TargetType.NO_TARGET then
    RegisterKey(openNearTelevision, "opentelevision", "Key E", Config.keyOpenTV or "E")
end

RegisterNetEvent("rcore_television:openNearTelevision")
AddEventHandler("rcore_television:openNearTelevision", openNearTelevision)

function OpenTVMenu()
    if not tvCamera then return end

    local cacheIndex, cacheEntry = GetTelevisionAtCoords(televisionMenuPosition)
    if cacheEntry then
        if cacheEntry.DisableInteraction then return end
        if cacheEntry.DisableInteraction == nil then
            if type(cacheIndex) == "string" and cacheIndex ~= "menu" then return end
        end
    end

    ViewingTvMenu = true
    ItemsMenuLoaded = false

    if cacheEntry then
        if cacheEntry.duiObj then
            Debug("menu.lua | SetDUILink | 140", menuUrl)
            if GetDuiUrl(cacheEntry.duiObj) ~= menuUrl then
                SetDUILink(cacheEntry.duiObj, GetLoadingDUILink(cacheEntry.identifierNumber, menuUrl))
            end
            needsCacheRefresh = true
        end
    else
        if not TelevisionCache.menu then
            needsCacheRefresh = true
            DestroyDuiAndScaleform()
            TelevisionCache.menu = {
                redirect      = RedirectType.MENU,
                time          = 0,
                bucketID      = PlayerBucketID,
                URL           = menuUrl,
                tvPos         = televisionMenuPosition,
                tvSize        = size,
                rot           = rotation,
                distance      = distance,
                scaleformLoaded = false,
                scaleformName = "...",
                scaleformId   = nil,
                entityHit     = entityTagged,
                hash          = GetEntityModel(entityTagged),
            }
        end
    end

    SelectedMenuItemIndex = 1
    displayHelp(10000)
    FreezeEntityPosition(PlayerPedId(), true)
    SetPlayerCanUseCover(PlayerId(), false)
end

RegisterKey(OpenTVMenu, "opentvmenu", "Key Q", "Q")

function IsTelevisionSuitableForJob(tvData)
    if not tvData.Job then return true end
    for jobName, grades in pairs(tvData.Job) do
        for _, grade in pairs(grades) do
            if IsAtJob(jobName, grade) then return true end
        end
    end
    return false
end

function LeaveTelevisionMenu()
    if not tvCamera then return end
    if TempBlockEnter ~= false then return end

    ShowHelpNotification(" ", false, false, 1)

    local _, cacheEntry = GetTelevisionAtCoords(televisionMenuPosition)
    local isDuiActive = IsAnyDuiActiveOnCoords(televisionMenuPosition)
    -- Only block exit if DUI is gone AND the player is not stuck in TV camera.
    -- After stopping the TV with SPACE the DUI is destroyed but IsLookingAtTV
    -- is still true, so we must allow leaving in that case.
    if not isDuiActive and not IsLookingAtTV then return end

    if TelevisionCache.menu then
        cacheEntry = TelevisionCache.menu
    end

    if isDuiActive and cacheEntry then
        if cacheEntry.duiObj then
            if ViewingTvMenu then
                local currentUrl = getSupportedLink(cacheEntry.redirect, cacheEntry.URL, PlayerTelevisionVolume, cacheEntry.time)
                currentUrl = currentUrl:gsub(" ", "")
                Debug("cache_event.lua | SetDUILink | 199", currentUrl)
                SetDUILink(cacheEntry.duiObj, GetLoadingDUILink(cacheEntry.identifierNumber, currentUrl))
            end
        else
            local menuEntry = TelevisionCache.menu
            if menuEntry then
                if menuEntry.duiObj and menuEntry.duiLoaded then
                    Debug("DestroyDui | menu.lua | 205")
                    DestroyDui(menuEntry.duiObj)
                    SetScaleformMovieAsNoLongerNeeded(menuEntry.scaleformId)
                end
                UnreleaseOccupiedScaleform(menuEntry.scaleformName or "none")
            end
            TelevisionCache.menu = nil
        end
    end

    IsLookingAtTV = false
    ViewingTvMenu = false
    TempBlockEnter = true

    FreezeEntityPosition(PlayerPedId(), true)
    SetPlayerControl(PlayerId(), false, 8)

    local exitCamCoords = GetGameplayCamCoord()
    local exitCamRot = GetGameplayCamRot()
    tvCamera.ChangePosition(exitCamCoords, exitCamCoords, exitCamRot, 1000)
    tvCamera.Destroy()
    tvCamera = nil
    StopRendering()
    Wait(200)

    FreezeEntityPosition(PlayerPedId(), false)
    SetPlayerCanUseCover(PlayerId(), true)
    SetPlayerControl(PlayerId(), true, 8)
    TempBlockEnter = false

    if needsCacheRefresh then
        TriggerServerEvent("rcore_television:fetchCache")
        needsCacheRefresh = false
    end
end

RegisterKey(LeaveTelevisionMenu, "leaveTVmenu_1", "Leave TV menu", Config.secondKeyToLeaveMenu or "escape")
RegisterKey(LeaveTelevisionMenu, "leaveTVmenu_2", "Leave TV menu", Config.keyToLeaveMenu or "BACK")

function ChangeItemInMenu(isUp, isRight, doSelect)
    if tvCamera == nil then return false end

    local _, cacheEntry = GetTelevisionAtCoords(televisionMenuPosition)
    local isDuiActive = IsAnyDuiActiveOnCoords(televisionMenuPosition)
    if not isDuiActive then return end

    if TelevisionCache.menu then
        cacheEntry = TelevisionCache.menu
    end

    if doSelect then
        if ItemsMenuLoaded then
            if isUp then
                if SelectedMenuItemIndex == #Config.listVideos then
                    SelectedMenuItemIndex = 0
                end
                SelectedMenuItemIndex = SelectedMenuItemIndex + 1
            else
                if SelectedMenuItemIndex == 1 then
                    SelectedMenuItemIndex = #Config.listVideos + 1
                end
                SelectedMenuItemIndex = SelectedMenuItemIndex - 1
            end
            DuiMessage(cacheEntry.duiObj, { type = "rcore_tv_change", selected = SelectedMenuItemIndex })
        end
    end

    if isUp ~= nil then
        DuiMessage(cacheEntry.duiObj, { type = isUp and "direction_top" or "direction_bottom" })
    end

    if isRight ~= nil then
        DuiMessage(cacheEntry.duiObj, { type = isRight and "direction_right" or "direction_left" })
    end
end

RegisterKey(function()
    if not tvCamera then return false end
    local _, cacheEntry = GetTelevisionAtCoords(televisionMenuPosition)
    if not IsAnyDuiActiveOnCoords(televisionMenuPosition) then return end
    if cacheEntry and cacheEntry.duiObj and cacheEntry.scaleformLoaded then
        DuiMessage(cacheEntry.duiObj, { type = "enter" })
    end
end, "enterpresstvmenu", "enter", "RETURN")

RegisterKey(function() ChangeItemInMenu(nil, true) end,  "tvnextchannelqqe",  "right",                           "RIGHT")
RegisterKey(function() ChangeItemInMenu(nil, false) end, "tvprevchannelggsxy", "left",                           "LEFT")
RegisterKey(function() ChangeItemInMenu(true, nil, true) end,  "tvnextchannel", "will select next program in tv", "UP")
RegisterKey(function() ChangeItemInMenu(false, nil, true) end, "tvprevchannel", "will select previous program in tv", "DOWN")

RegisterKey(function()
    if not IsLookingAtTV then return end
    showNotification(_U("stopped_program"))
    TriggerServerEvent("rcore_television:stopTelevisionAtCoords", televisionMenuPosition)
end, "stoptvProgram", "Will stop TV program", Config.keyToStopChannel or "SPACE")
