local minimapScaleform = nil
local uiReady = false
local minimapFixRunning = false
local minimapFixQueued = false

local mapPlacer = {}
local moveHudActive = false
local minimapMaskDisabled = false
local measuredClusterLeftPx = nil
local measuredClusterWidthPx = nil
local measuredMinimapHeightPx = nil

local HUD_LAYOUT_REF_W = 1920
local HUD_LAYOUT_REF_H = 1080
local HUD_SAFE_LEFT_PX = 12
local HUD_SAFE_BOTTOM_PX = 14
local HUD_CLUSTER_GAP_PX = 0
local HUD_VITALS_STATUS_GAP_PX = 6
local HUD_ENV_HEIGHT_PX = 52
local HUD_ENV_MAP_GAP_PX = 26
local HUD_MINIMAP_VITALS_GAP_PX = 4
local HUD_MAP_PLACER_PAD_PX = 10
local HUD_VITALS_HEIGHT_PX = 27
local HUD_STATUS_HEIGHT_PX = 54
local HUD_BAND_FALLBACK_W_PX = 366
local HUD_MINIMAP_FALLBACK_H_PX = 255

local screenResolution = { x = 1920, y = 1080 }

local function scaleHudPx(value, ref, screen)
    if ref <= 0 or screen <= 0 then return math.floor(value + 0.5) end
    return math.floor((value * screen / ref) + 0.5)
end

local function getScreenResolution()
    local w, h = GetActiveScreenResolution()
    screenResolution.x = w
    screenResolution.y = h
    return screenResolution
end

local function getClusterBottomPx(screenH)
    return scaleHudPx(HUD_SAFE_BOTTOM_PX, HUD_LAYOUT_REF_H, screenH)
end

local function getClusterLeftPx(screenW)
    if measuredClusterLeftPx and measuredClusterLeftPx > 0 then
        return measuredClusterLeftPx
    end
    return scaleHudPx(HUD_SAFE_LEFT_PX, HUD_LAYOUT_REF_W, screenW)
end

local function getClusterWidthPx(screenW)
    if measuredClusterWidthPx and measuredClusterWidthPx > 0 then
        return measuredClusterWidthPx
    end
    return scaleHudPx(HUD_BAND_FALLBACK_W_PX, HUD_LAYOUT_REF_W, screenW)
end

local function getStatusHeightPx(screenH)
    return scaleHudPx(HUD_STATUS_HEIGHT_PX, HUD_LAYOUT_REF_H, screenH)
end

local function getVitalsHeightPx(screenH)
    return scaleHudPx(HUD_VITALS_HEIGHT_PX, HUD_LAYOUT_REF_H, screenH)
end

local function getMinimapHeightPx(screenH, bandWidthPx)

    if measuredMinimapHeightPx and measuredMinimapHeightPx > 0 then
        return measuredMinimapHeightPx
    end
    if bandWidthPx and bandWidthPx > 0 then
        return math.floor((bandWidthPx * HUD_MINIMAP_FALLBACK_H_PX / HUD_BAND_FALLBACK_W_PX) + 0.5)
    end
    return scaleHudPx(HUD_MINIMAP_FALLBACK_H_PX, HUD_LAYOUT_REF_H, screenH)
end

local function clampNorm(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function getNativeMapCalibration()
    return {
        widthExtra = tonumber(Config.MinimapNativeWidthExtra) or 0.013,
        heightExtra = tonumber(Config.MinimapNativeHeightExtra) or 0.018,
        offsetX = tonumber(Config.MinimapNativeOffsetX) or 0.0,
        offsetY = tonumber(Config.MinimapNativeOffsetY) or 0.0,
    }
end

local function getFixedMinimapNorm(screenW, screenH)
    if screenW <= 0 then return 0.175, 0.20 end
    screenH = screenH or math.floor(screenW * HUD_LAYOUT_REF_H / HUD_LAYOUT_REF_W)
    local mapWidthPx = getClusterWidthPx(screenW)
    local mapHeightPx = getMinimapHeightPx(screenH, mapWidthPx)
    local nativeScale = tonumber(Config.MinimapNativeScale) or 1.0
    if nativeScale <= 0 then nativeScale = 1.0 end
    return (mapWidthPx / screenW) * nativeScale, (mapHeightPx / screenH) * nativeScale
end

--- Native radar thường nhỏ hơn khung UI (neo L/B) — bù kích thước để blip không tràn cạnh trên/phải.
local function applyNativeMapCalibration(positions)
    local mm = positions.minimap
    if type(mm) ~= 'table' then return end

    local calibration = getNativeMapCalibration()
    mm.width = clampNorm((mm.width or 0) + calibration.widthExtra, 0.001, 1.0)
    mm.height = clampNorm((mm.height or 0) + calibration.heightExtra, 0.001, 1.0)
    mm.x = (mm.x or 0) + calibration.offsetX
    mm.y = (mm.y or 0) + calibration.offsetY
end

local function getMinimapPositions(screenRes)
    local positions = { minimap = {}, minimap_blur = {}, minimap_mask = {} }
    local resolutionX, resolutionY = screenRes.x, screenRes.y
    local defaultAspectRatio = 1920 / 1080
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6)
    end

    local mapW, mapH = getFixedMinimapNorm(resolutionX, resolutionY)
    local placerRect = mapPlacer.rectangle

    if resolutionX >= 3440 then
        positions.minimap = { x = -0.007, y = -0.075, width = mapW, height = mapH }
        positions.minimap_blur = { x = -0.0085, y = -0.045, width = 0.27, height = 0.3 }
        positions.minimap_mask = { x = 0.0, y = 0.0, width = mapW, height = mapH }
    elseif resolutionX >= 2560 then
        positions.minimap = { x = -0.007, y = -0.075, width = mapW, height = mapH }
        positions.minimap_blur = { x = -0.0085, y = -0.045, width = 0.27, height = 0.3 }
        positions.minimap_mask = { x = 0.0, y = 0.0, width = mapW, height = mapH }
    else
        positions.minimap = { x = -0.015, y = -0.085, width = mapW, height = mapH }
        positions.minimap_blur = { x = -0.015, y = -0.055, width = 0.27, height = 0.30 }
        positions.minimap_mask = { x = 0.0, y = 0.0, width = mapW, height = mapH }
    end

    positions.minimap.x = positions.minimap.x + minimapOffset
    positions.minimap_blur.x = positions.minimap_blur.x + minimapOffset
    positions.minimap_mask.x = positions.minimap_mask.x + minimapOffset

    if type(placerRect) == 'table' then
        local offsetX = tonumber(placerRect.offsetX) or 0.0
        local offsetY = tonumber(placerRect.offsetY) or 0.0
        local scale = tonumber(placerRect.scale) or 0.0
        positions.minimap.x = positions.minimap.x + offsetX
        positions.minimap.y = positions.minimap.y + offsetY
        positions.minimap.width = positions.minimap.width + scale
        positions.minimap.height = positions.minimap.height + scale
        positions.minimap_blur.x = positions.minimap_blur.x + offsetX
        positions.minimap_blur.y = positions.minimap_blur.y + offsetY
        positions.minimap_blur.width = positions.minimap_blur.width + scale
        positions.minimap_blur.height = positions.minimap_blur.height + scale
    end

    return positions
end

local function getMinimapPositionsWithoutPlacer(screenRes)
    local saved = mapPlacer
    mapPlacer = {}
    local positions = getMinimapPositions(screenRes)
    mapPlacer = saved
    return positions
end

local function syncMinimapComponentsToMap(positions, alignMaskToMap)
    local mm = positions.minimap
    if type(mm) ~= 'table' or not mm.width or not mm.height then return end

    local baseW, baseH = mm.width, mm.height

    if alignMaskToMap then
        positions.minimap_mask = {
            x = mm.x or 0,
            y = mm.y or 0,
            width = baseW,
            height = baseH,
        }
    else
        positions.minimap_mask = {
            x = 0.0,
            y = 0.0,
            width = baseW,
            height = baseH,
        }
    end

    positions.minimap.width = baseW
    positions.minimap.height = baseH
    positions.minimap.x = positions.minimap_mask.x
    positions.minimap.y = positions.minimap_mask.y

    positions.minimap_blur = {
        x = positions.minimap_mask.x - 0.0015,
        y = positions.minimap_mask.y + 0.03,
        width = baseW + 0.095,
        height = baseH + 0.10,
    }
end

local function getMapSizePx(mm, screenW, screenH)
    return (mm.width or 0.1685) * screenW, (mm.height or 0.19) * screenH
end

local function buildDefaultStackLayout(screenW, screenH, bandWidthPx, mapHeightPx)
    local clusterLeft = getClusterLeftPx(screenW)
    local statusHeight = getStatusHeightPx(screenH)
    local vitalsHeight = getVitalsHeightPx(screenH)
    local gap = HUD_CLUSTER_GAP_PX

    local statusTop = screenH - getClusterBottomPx(screenH) - statusHeight
    local vitalsTop = statusTop - gap - HUD_VITALS_STATUS_GAP_PX - vitalsHeight
    local minimapTop = vitalsTop - gap - HUD_MINIMAP_VITALS_GAP_PX - mapHeightPx
    local envTop = minimapTop - gap - HUD_ENV_MAP_GAP_PX - HUD_ENV_HEIGHT_PX

    return {
        clusterLeft = clusterLeft,
        bandWidth = bandWidthPx,
        env = { left = clusterLeft, top = math.floor(envTop + 0.5), width = bandWidthPx },
        minimap = { left = clusterLeft, top = math.floor(minimapTop + 0.5), width = bandWidthPx, height = mapHeightPx },
        vitals = { left = clusterLeft, top = math.floor(vitalsTop + 0.5), width = bandWidthPx },
        statusBars = { left = clusterLeft, top = math.floor(statusTop + 0.5), width = bandWidthPx },
    }
end

local function getMinimapStackBottomPx(screenH)
    return getClusterBottomPx(screenH) + getStatusHeightPx(screenH) + HUD_CLUSTER_GAP_PX + HUD_VITALS_STATUS_GAP_PX
        + getVitalsHeightPx(screenH) + HUD_CLUSTER_GAP_PX + HUD_MINIMAP_VITALS_GAP_PX
end

local function getBaselineMinimapNativePos(screenW, screenH)
    local clusterLeftPx = getClusterLeftPx(screenW)
    local minimapStackBottomPx = getMinimapStackBottomPx(screenH)
    local safezone = GetSafeZoneSize()
    local safezoneOffset = (1.0 - safezone) / 2.0
    return {
        x = (clusterLeftPx / screenW) - safezoneOffset,
        y = -((minimapStackBottomPx / screenH) - safezoneOffset),
    }
end

local function buildNuiClusterLayout(positions, screenW, screenH)
    local mm = positions.minimap or {}
    local bandWidthPx = getClusterWidthPx(screenW)
    local mapWidthPx = bandWidthPx
    local mapHeightPx = getMinimapHeightPx(screenH, bandWidthPx)
    local hasMapPlacer = type(mapPlacer.rectangle) == 'table'
    local clusterLeftPx = getClusterLeftPx(screenW)

    local nativeScale = tonumber(Config.MinimapNativeScale) or 1.0
    if nativeScale <= 0 then nativeScale = 1.0 end

    if not hasMapPlacer then
        mm.width = (mapWidthPx / screenW) * nativeScale
        mm.height = (mapHeightPx / screenH) * nativeScale
    end

    local clusterBottomPx = getClusterBottomPx(screenH)
    local statusHeightPx = getStatusHeightPx(screenH)
    local vitalsHeightPx = getVitalsHeightPx(screenH)
    local gap = HUD_CLUSTER_GAP_PX

    local vitalsStackBottomPx = clusterBottomPx + statusHeightPx + gap + HUD_VITALS_STATUS_GAP_PX
    local minimapStackBottomPx = vitalsStackBottomPx + vitalsHeightPx + gap + HUD_MINIMAP_VITALS_GAP_PX
    local envStackBottomPx = minimapStackBottomPx + mapHeightPx + gap + HUD_ENV_MAP_GAP_PX

    local stack = buildDefaultStackLayout(screenW, screenH, bandWidthPx, mapHeightPx)
    stack.env.left = clusterLeftPx
    stack.env.top = math.floor(screenH - envStackBottomPx - HUD_ENV_HEIGHT_PX + 0.5)

    local minimapLeftPx = clusterLeftPx
    local minimapBottomPx = minimapStackBottomPx

    local safezone = GetSafeZoneSize()
    local safezoneOffset = (1.0 - safezone) / 2.0

    if hasMapPlacer then
        minimapLeftPx = math.floor(math.max(((mm.x or 0) + safezoneOffset) * screenW, 0) + 0.5)
        minimapBottomPx = math.floor(math.max(-((mm.y or 0) - safezoneOffset) * screenH, 0) + 0.5)
        local minimapTopPx = math.floor(screenH - minimapBottomPx - mapHeightPx + 0.5)

        stack.minimap.left = minimapLeftPx
        stack.minimap.top = minimapTopPx
        stack.minimap.width = mapWidthPx
        stack.minimap.height = mapHeightPx
        stack.env.left = minimapLeftPx
        stack.env.top = math.floor(minimapTopPx - gap - HUD_ENV_MAP_GAP_PX - HUD_ENV_HEIGHT_PX + 0.5)
    else
        mm.x = (clusterLeftPx / screenW) - safezoneOffset
        mm.y = -((minimapStackBottomPx / screenH) - safezoneOffset)
        local minimapTopPx = math.floor(screenH - minimapStackBottomPx - mapHeightPx + 0.5)
        stack.minimap.left = minimapLeftPx
        stack.minimap.top = minimapTopPx
        stack.minimap.width = mapWidthPx
        stack.minimap.height = mapHeightPx
    end

    return {
        left = minimapLeftPx,
        clusterLeft = clusterLeftPx,
        bottom = minimapBottomPx,
        width = mapWidthPx,
        height = mapHeightPx,
        statusBottom = clusterBottomPx,
        clusterBottomPx = clusterBottomPx,
        statusStackHeightPx = statusHeightPx,
        vitalsStackBottomPx = vitalsStackBottomPx,
        minimapStackBottomPx = minimapStackBottomPx,
        envStackBottomPx = envStackBottomPx,
        needsStackBottomPx = envStackBottomPx,
        clusterGapPx = gap,
        hasCustomMinimap = hasMapPlacer,
        env = stack.env,
        minimap = stack.minimap,
        vitals = stack.vitals,
        statusBars = stack.statusBars,
        gps = stack.env,
    }
end

local function hideMinimapHealthArmor()
    if not minimapScaleform then
        minimapScaleform = RequestScaleformMovie('minimap')
    end
    if not HasScaleformMovieLoaded(minimapScaleform) then return end
    BeginScaleformMovieMethod(minimapScaleform, 'SETUP_HEALTH_ARMOUR')
    ScaleformMovieMethodAddParamInt(3)
    EndScaleformMovieMethod()
end

local function sendNuiLayout(layout)
    if not uiReady then return end
    SendNUIMessage({ action = 'setMinimapLayout', data = layout })
end

function CheckRadarDisplay()
    if hideAllActive then
        DisplayRadar(false)
        return
    end
    if Config.MinimapOnlyInVehicle then
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            DisplayRadar(true)
        else
            DisplayRadar(false)
        end
        return
    end
    DisplayRadar(true)
end

function FixMiniMap()
    if minimapFixRunning then
        minimapFixQueued = true
        return
    end
    minimapFixRunning = true

    CreateThread(function()
        repeat
            minimapFixQueued = false
            local ok, err = pcall(function()

                DisplayRadar(false)
                local screen = getScreenResolution()
                local positions = getMinimapPositions(screen)
                local nuiLayout = buildNuiClusterLayout(positions, screen.x, screen.y)
                sendNuiLayout(nuiLayout)

                RequestStreamedTextureDict('rectangle', false)
                local deadline = GetGameTimer() + 1200
                while not HasStreamedTextureDictLoaded('rectangle') do
                    if GetGameTimer() > deadline then break end
                    Wait(50)
                end

                if not minimapMaskDisabled and HasStreamedTextureDictLoaded('rectangle') then
                    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'rectangle', 'radarmasksm')
                    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'rectangle', 'radarmasksm')
                end

                applyNativeMapCalibration(positions)
                syncMinimapComponentsToMap(positions, true)

                SetMinimapComponentPosition('minimap', 'L', 'B',
                    positions.minimap.x, positions.minimap.y,
                    positions.minimap.width, positions.minimap.height)
                SetMinimapComponentPosition('minimap_blur', 'L', 'B',
                    positions.minimap_blur.x, positions.minimap_blur.y,
                    positions.minimap_blur.width, positions.minimap_blur.height)
                SetMinimapComponentPosition('minimap_mask', 'L', 'B',
                    positions.minimap_mask.x, positions.minimap_mask.y,
                    positions.minimap_mask.width, positions.minimap_mask.height)

                SetMinimapClipType(0)
                SetBlipAlpha(GetNorthRadarBlip(), 0)
                if not moveHudActive then
                    SetBigmapActive(true, false)
                    Wait(50)
                    SetBigmapActive(false, false)
                end
                hideMinimapHealthArmor()
            end)

            if not ok then
                print(('^1[Tipi_hud]^7 FixMiniMap lỗi: %s'):format(err))
            end
            CheckRadarDisplay()
        until not minimapFixQueued
        minimapFixRunning = false
    end)
end

function ApplyMapPlacerFromScreenPos(left, top)
    left = tonumber(left)
    top = tonumber(top)
    if not left or not top then return end

    local screen = getScreenResolution()
    local w, h = screen.x, screen.y
    left = math.floor(left + 0.5)
    top = math.floor(top + 0.5)

    local baseline = getBaselineMinimapNativePos(w, h)
    local mapWidthFloor = getClusterWidthPx(w)
    local mapHeightFloor = getMinimapHeightPx(h, mapWidthFloor)
    local pad = HUD_MAP_PLACER_PAD_PX

    left = math.max(pad, math.min(w - mapWidthFloor - pad, left))
    top = math.max(pad, math.min(h - mapHeightFloor - pad, top))
    if mapWidthFloor <= 0 or mapHeightFloor <= 0 then return end

    local bottomPx = math.max(0, h - top - mapHeightFloor)

    local safezone = GetSafeZoneSize()
    local safezoneOffset = (1.0 - safezone) / 2.0
    local targetX_safe = (left / w) - safezoneOffset
    local targetY_safe = -((bottomPx / h) - safezoneOffset)

    local offsetX = targetX_safe - (baseline.x or 0)
    local offsetY = targetY_safe - (baseline.y or 0)

    local prevScale = 0.0
    if type(mapPlacer.rectangle) == 'table' and mapPlacer.rectangle.scale then
        prevScale = tonumber(mapPlacer.rectangle.scale) or 0.0
    end

    mapPlacer = {
        rectangle = {
            offsetX = offsetX,
            offsetY = offsetY,
            scale = prevScale,
        },
    }
    SetResourceKvp('tipi_hud_map_placer', json.encode(mapPlacer))
    FixMiniMap()
end

function SetMeasuredHudClusterLayout(left, width, statusHeight, vitalsHeight, minimapHeight)
    left = tonumber(left)
    width = tonumber(width)
    statusHeight = tonumber(statusHeight)
    vitalsHeight = tonumber(vitalsHeight)
    minimapHeight = tonumber(minimapHeight)
    if not left or not width or width <= 0 then return end

    left = math.floor(left + 0.5)
    width = math.floor(width + 0.5)

    local prevLeft = measuredClusterLeftPx
    local prevWidth = measuredClusterWidthPx
    local prevMap = measuredMinimapHeightPx

    measuredClusterLeftPx = left
    measuredClusterWidthPx = width
    if minimapHeight and minimapHeight > 0 then
        measuredMinimapHeightPx = math.floor(minimapHeight + 0.5)
    end

    if not uiReady then return end
    if moveHudActive then return end
    if type(mapPlacer.rectangle) == 'table' then return end

    local leftDelta = prevLeft == nil and 999 or math.abs((prevLeft or 0) - left)
    local widthDelta = prevWidth == nil and 0 or math.abs((prevWidth or 0) - width)
    local mapDelta = prevMap == nil and 0 or math.abs((prevMap or 0) - (measuredMinimapHeightPx or 0))

    if leftDelta >= 2 or widthDelta >= 4 or mapDelta >= 2 or prevLeft == nil then
        FixMiniMap()
    end
end

function ResetHudClusterLayout()
    mapPlacer = {}
    DeleteResourceKvp('tipi_hud_map_placer')
    measuredClusterLeftPx = nil
    measuredClusterWidthPx = nil
    measuredMinimapHeightPx = nil
    if uiReady then
        FixMiniMap()
    end
end

function SetMinimapUiReady(state)
    uiReady = state == true
    if uiReady then
        FixMiniMap()
    end
end

local function loadSavedMapPlacer()
    local raw = GetResourceKvpString('tipi_hud_map_placer')
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            mapPlacer = decoded
        end
    end
end

RegisterNUICallback('nui:setHudClusterLayout', function(data, cb)
    cb({})
    if type(data) ~= 'table' then return end
    SetMeasuredHudClusterLayout(
        data.left,
        data.width,
        data.statusHeight,
        data.vitalsHeight,
        data.minimapHeight
    )
end)

RegisterNUICallback('nui:applyMapPlacerFromScreen', function(data, cb)
    cb({})
    if type(data) ~= 'table' then return end
    ApplyMapPlacerFromScreenPos(data.left, data.top)
end)

RegisterNUICallback('nui:fixMiniMap', function(_, cb)
    cb({})
    FixMiniMap()
end)

RegisterNUICallback('nui:resetHudClusterLayout', function(_, cb)
    cb({})
    ResetHudClusterLayout()
end)

RegisterNUICallback('nui:setMoveHudActive', function(data, cb)
    cb({})
    moveHudActive = type(data) == 'table' and data.active == true
    if moveHudActive then
        SetNuiFocus(true, true)
    end
end)

function IsMoveHudActive()
    return moveHudActive
end

RegisterNetEvent('hud:client:LoadMap', function()
    FixMiniMap()
end)

RegisterCommand('reloadmap', function()
    FixMiniMap()
end, false)


CreateThread(function()
    loadSavedMapPlacer()
    Wait(1500)
    while not IsHudComponentActive(14) do
        Wait(100)
    end
    FixMiniMap()
end)

CreateThread(function()
    while true do
        if uiReady then
            local x, y = GetActiveScreenResolution()
            if screenResolution.x ~= x or screenResolution.y ~= y then
                screenResolution.x = x
                screenResolution.y = y
                Wait(500)
                FixMiniMap()
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        hideMinimapHealthArmor()
        CheckRadarDisplay()
        Wait(500)
    end
end)
