

Oxlyn = Oxlyn or {}

local resourceName = GetCurrentResourceName()
local floor = math.floor

----------------------------------------------------------------------
-- Startup
----------------------------------------------------------------------
CreateThread(function()
    Oxlyn.WaitForBridge(30000)
    Oxlyn.LoadLocal()

    Oxlyn.ActiveLocale = Oxlyn.State.overrides.uiLocale or Config.Locale
    Oxlyn.Resolve()

    TriggerServerEvent("oxlyn_fps:clientReady")
    Wait(500)

    Oxlyn.ApplyBoost()
    Oxlyn.RefreshHud()
    Oxlyn.State.ready = true

    Oxlyn.Debug("cliente pronto | preset =", Oxlyn.State.activePreset)
end)

----------------------------------------------------------------------
-- Change hooks
----------------------------------------------------------------------
function Oxlyn.OnSettingsChanged(key)
    local setting = Oxlyn.SettingIndex[key]
    if not setting then return end

    local group = setting.group
    local isUiGroup = (group == "hud" or group == "interface")

    if isUiGroup then
        Oxlyn.ActiveLocale = Oxlyn.Get("uiLocale") or Config.Locale
        Oxlyn.RefreshHud()
        Oxlyn.PushUiConfig()
    end

    if key == "uiBlur" and Oxlyn.State.open then
        if Oxlyn.Get("uiBlur") ~= false then
            if TriggerScreenblurFadeIn then TriggerScreenblurFadeIn(300.0) end
        else
            if TriggerScreenblurFadeOut then TriggerScreenblurFadeOut(200.0) end
        end
    end

    if key == "uiLocale" and Oxlyn.State.open then
        SendNUIMessage({
            action = "schema",
            schema = Oxlyn.BuildSchemaPayload(),
            values = Oxlyn.BuildValuesPayload(),
        })
        SendNUIMessage({
            action = "static",
            static = Oxlyn.BuildStaticPayload(),
        })
    end

    if not isUiGroup then
        Oxlyn.ApplyBoost()
    end
end

function Oxlyn.OnPresetChanged(presetId)
    Oxlyn.ApplyBoost()
    Oxlyn.RefreshHud()
    Oxlyn.PushUiConfig()

    local preset = Oxlyn.PresetIndex[presetId]
    local label = preset and Oxlyn.T(preset.label) or presetId
    Oxlyn.Notify(Oxlyn.L("notify_preset", label), "success")

    if Oxlyn.State.open then
        SendNUIMessage({ action = "values", payload = Oxlyn.BuildValuesPayload() })
    end
end

----------------------------------------------------------------------
-- Sounds
----------------------------------------------------------------------
function Oxlyn.PlaySound(name)
    if Oxlyn.Get("uiSounds") == false then return end

    local sound = Config.Sounds and Config.Sounds[name]
    if not sound then return end

    PlaySoundFrontend(-1, sound[1], sound[2], true)
end

RegisterNUICallback("sound", function(data, cb)
    Oxlyn.PlaySound(data and data.name)
    cb({ ok = true })
end)

----------------------------------------------------------------------
-- UI config / payload builders
----------------------------------------------------------------------
function Oxlyn.PushUiConfig()
    SendNUIMessage({
        action = "uiConfig",
        config = {
            accent    = Oxlyn.Get("uiAccent") or "#FF2E43",
            autoScale = Oxlyn.Get("uiAutoScale") ~= false,
            scale     = Oxlyn.Get("uiScale") or 1.0,
            blur      = Oxlyn.Get("uiBlur") ~= false,
            backdrop  = Oxlyn.Get("uiBackdrop") or 0.32,
            threeD    = Oxlyn.Get("ui3d") ~= false,
            animations = Oxlyn.Get("uiAnimations") ~= false,
            float     = Oxlyn.Eff("uiFloat") ~= false,
            sounds    = Oxlyn.Get("uiSounds") ~= false,
            chartRange = Oxlyn.Get("uiChartRange") or "1m",
            chartGlow  = Oxlyn.Get("uiChartGlow") or 0.55,
            showEstimates     = Oxlyn.Get("uiShowEstimates") ~= false,
            showEstimateBadge = Config.Metrics.showEstimateBadge ~= false,
            lang      = Oxlyn.ActiveLocale,
        },
    })
end

-- Builds the list of performance tips shown in the panel
local function buildTips()
    local fps  = Oxlyn.FPS
    local real = Oxlyn.Metrics.real
    local tips = {}

    local function add(key, kind, ...)
        tips[#tips + 1] = {
            text = Oxlyn.L(key, ...),
            kind = kind or "info",
        }
    end

    if fps.average >= Config.Metrics.fpsExcellent then
        add("tip_great", "good")
    elseif fps.average > 0 and fps.average < Config.Metrics.fpsPoor then
        add("tip_low", "bad")
    end

    if fps.average > 0 and fps.low1 > 0 and fps.low1 < fps.average * 0.55 then
        add("tip_stutter", "warn")
    end

    if real.totalEntities > 700 then
        add("tip_entities", "warn", real.totalEntities)
    end

    if real.ping > Config.Metrics.pingWarn then
        add("tip_ping", "warn", real.ping)
    end

    if Oxlyn.State.activePreset == "off" and fps.average > 0 and fps.average < Config.Metrics.fpsGood then
        add("tip_nopreset", "info")
    end

    if Oxlyn.Get("uiBlur") and fps.average < Config.Metrics.fpsGood then
        add("tip_blur", "info")
    end

    if #tips == 0 then
        add("tip_stable", "good")
    end

    return tips
end

function Oxlyn.BuildStaticPayload()
    local real = Oxlyn.Metrics.real

    local commands = {}
    for key, name in pairs(Config.Commands) do
        commands[#commands + 1] = { key = key, command = "/" .. name }
    end
    table.sort(commands, function(a, b) return a.command < b.command end)

    return {
        version    = GetResourceMetadata(resourceName, "version", 0) or "1.0.0",
        author     = GetResourceMetadata(resourceName, "author", 0) or "Oxlyn Software",
        framework  = Oxlyn.Framework(),
        serverName = real.serverName,
        maxPlayers = real.maxPlayers,
        gameBuild  = real.gameBuild,
        onesync    = real.onesync,
        commands   = commands,
        keys       = Config.Keys,
        sessions   = Oxlyn.GetSessions(),
        isAdmin    = Oxlyn.State.isAdmin,
        presetMarks = Oxlyn.State.presetMarks,
        lang       = Oxlyn.ActiveLocale,
        pt         = (Oxlyn.ActiveLocale == "pt"),
    }
end

----------------------------------------------------------------------
-- Live updates to the panel
----------------------------------------------------------------------
local tipsCache
local tipsCachedAt = 0
local TICK_THROTTLE_MS = 250
local lastTickAt = 0
local lastSentFps, lastSentFt = -1, -1
local chartThreadRunning = false

local function pushLiveTick()
    local now = GetGameTimer()
    local fpsData = Oxlyn.FPS

    local fps = floor(fpsData.smooth + 0.5)
    local ft  = floor(fpsData.frametime * 10 + 0.5) / 10

    -- lightweight live values, only when changed
    if fps ~= lastSentFps or ft ~= lastSentFt then
        lastSentFps, lastSentFt = fps, ft
        SendNUIMessage({ action = "live", fps = fps, ft = ft })
    end

    -- heavier full tick, throttled
    if now - lastTickAt < TICK_THROTTLE_MS then return end
    lastTickAt = now

    if not tipsCache or (now - tipsCachedAt) > 1000 then
        tipsCache = buildTips()
        tipsCachedAt = now
    end

    SendNUIMessage({
        action  = "tick",
        fps     = Oxlyn.FpsSnapshot(),
        metrics = Oxlyn.MetricsSnapshot(),
        cleanup = Oxlyn.CleanupStats(),
        preset  = Oxlyn.State.activePreset,
        uptime  = floor((now - Oxlyn.State.sessionStart) / 1000),
        clock   = { h = GetClockHours(), m = GetClockMinutes() },
        tips    = tipsCache,
    })
end

----------------------------------------------------------------------
-- Panel open / close
----------------------------------------------------------------------
function Oxlyn.SetPanelOpen(open, force)
    if open == Oxlyn.State.open then return end

    if open and not force then
        local isDown, source = Oxlyn.IsPlayerDown()
        if Config.Integration.blockWhenDead and isDown then
            Oxlyn.Debug("painel bloqueado por blockWhenDead — origem:", source or "?")
            Oxlyn.Notify(Oxlyn.L("notify_dead"), "error")
            return
        end

        if Config.Integration.blockWhileDriving and Oxlyn.IsDriving() then
            Oxlyn.Notify(Oxlyn.L("notify_driving"), "error")
            return
        end
    end

    Oxlyn.State.open = open
    SetNuiFocus(open, open)
    SetNuiFocusKeepInput(false)
    Oxlyn.PlaySound(open and "open" or "close")

    if Oxlyn.Get("uiBlur") ~= false then
        if open then
            if TriggerScreenblurFadeIn then TriggerScreenblurFadeIn(400.0) end
        else
            if TriggerScreenblurFadeOut then TriggerScreenblurFadeOut(250.0) end
        end
    end

    TriggerEvent("oxlyn_fps:panelStateChanged", open)

    if open then
        Oxlyn.ActiveLocale = Oxlyn.Get("uiLocale") or Config.Locale

        SendNUIMessage({
            action = "open",
            schema = Oxlyn.BuildSchemaPayload(),
            values = Oxlyn.BuildValuesPayload(),
            static = Oxlyn.BuildStaticPayload(),
        })
        Oxlyn.PushUiConfig()

        lastSentFps, lastSentFt = -1, -1
        pushLiveTick()

        if not chartThreadRunning then
            chartThreadRunning = true
            CreateThread(function()
                while Oxlyn.State.open do
                    pushLiveTick()
                    Wait(Config.Monitor.uiTickMs or 100)
                end
                chartThreadRunning = false
            end)
        end
    else
        SendNUIMessage({ action = "close" })
    end
end

function Oxlyn.TogglePanel()
    Oxlyn.SetPanelOpen(not Oxlyn.State.open)
end

----------------------------------------------------------------------
-- NUI callbacks
----------------------------------------------------------------------

-- Reply { ok = true, ...extra }
local function respond(cb, extra)
    local result = { ok = true }
    if extra then
        for k, v in pairs(extra) do result[k] = v end
    end
    cb(result)
end

RegisterNUICallback("close", function(_, cb)
    Oxlyn.SetPanelOpen(false)
    respond(cb)
end)

RegisterNUICallback("setSetting", function(data, cb)
    local ok, reason = Oxlyn.Set(data.id, data.value)

    if not ok then
        if reason == "locked" then
            Oxlyn.Notify(Oxlyn.L("notify_locked"), "error")
        elseif reason == "no_perm" then
            Oxlyn.Notify(Oxlyn.L("notify_no_perm"), "error")
        end
    end

    cb({ ok = ok, reason = reason, values = Oxlyn.BuildValuesPayload() })
end)

RegisterNUICallback("applyPreset", function(data, cb)
    local ok, reason = Oxlyn.ApplyPreset(data.id)

    if not ok and reason == "preset_locked" then
        Oxlyn.Notify(Oxlyn.L("notify_preset_lock"), "error")
    end

    cb({ ok = ok, reason = reason, values = Oxlyn.BuildValuesPayload() })
end)

RegisterNUICallback("previewPreset", function(data, cb)
    Oxlyn.RunPreview(data.id)
    respond(cb)
end)

RegisterNUICallback("keepPreview", function(_, cb)
    local ok = Oxlyn.KeepPreviewResult()
    cb({ ok = ok, values = Oxlyn.BuildValuesPayload() })
end)

RegisterNUICallback("cancelPreview", function(_, cb)
    Oxlyn.CancelPreview()
    respond(cb)
end)

RegisterNUICallback("resetAll", function(_, cb)
    Oxlyn.ResetAll()
    Oxlyn.Notify(Oxlyn.L("notify_reset"), "success")
    cb({
        ok     = true,
        values = Oxlyn.BuildValuesPayload(),
        schema = Oxlyn.BuildSchemaPayload(),
    })
end)

RegisterNUICallback("saveCustom", function(data, cb)
    local ok, result = Oxlyn.SaveCustomProfile(data and data.name)

    if ok then
        Oxlyn.Notify(Oxlyn.L("pf_saved", result.name), "success")
    elseif result == "full" then
        Oxlyn.Notify(Oxlyn.L("pf_full", Config.MaxCustomPresets or 6), "error")
    elseif result == "noname" then
        Oxlyn.Notify(Oxlyn.L("pf_noname"), "error")
    end

    cb({
        ok     = ok,
        reason = (not ok) and result or nil,
        values = Oxlyn.BuildValuesPayload(),
        schema = Oxlyn.BuildSchemaPayload(),
    })
end)

RegisterNUICallback("deleteCustom", function(data, cb)
    local ok = Oxlyn.DeleteCustom(data and data.id)

    if ok then
        Oxlyn.Notify(Oxlyn.L("pf_deleted"), "success")
    end

    cb({
        ok     = ok,
        values = Oxlyn.BuildValuesPayload(),
        schema = Oxlyn.BuildSchemaPayload(),
    })
end)

RegisterNUICallback("requestChart", function(data, cb)
    cb({ ok = true, chart = Oxlyn.GetChartSeries(data.series, data.range) })
end)

RegisterNUICallback("exportCsv", function(data, cb)
    cb({ ok = true, csv = Oxlyn.ExportCsv(data.range) })
end)

RegisterNUICallback("runCleanup", function(_, cb)
    local result = Oxlyn.RunCleanup(true)
    cb({ ok = true, result = result, stats = Oxlyn.CleanupStats() })
end)

RegisterNUICallback("toggleHud", function(_, cb)
    local enabled = Oxlyn.ToggleHud()
    cb({ ok = true, enabled = enabled, values = Oxlyn.BuildValuesPayload() })
end)

RegisterNUICallback("setLocale", function(data, cb)
    Oxlyn.Set("uiLocale", data.lang, true)
    Oxlyn.ActiveLocale = Oxlyn.Get("uiLocale")
    Oxlyn.PushUiConfig()

    cb({
        ok     = true,
        schema = Oxlyn.BuildSchemaPayload(),
        values = Oxlyn.BuildValuesPayload(),
        static = Oxlyn.BuildStaticPayload(),
    })
end)

----------------------------------------------------------------------
-- Net events
----------------------------------------------------------------------
RegisterNetEvent("oxlyn_fps:init", function(data)
    Oxlyn.State.isAdmin = data.isAdmin and true or false

    Oxlyn.State.locked = {}
    for _, id in ipairs(data.lockedSettings or {}) do
        Oxlyn.State.locked[id] = true
    end

    Oxlyn.State.lockedPresets = {}
    for _, id in ipairs(data.lockedPresets or {}) do
        Oxlyn.State.lockedPresets[id] = true
    end

    Oxlyn.State.maxPreset = data.maxPreset

    if data.forceDefaultOnJoin and data.defaultPreset then
        Oxlyn.State.activePreset = data.defaultPreset
        Oxlyn.State.overrides = {}
    end

    Oxlyn.Resolve()
    Oxlyn.ApplyBoost()
    Oxlyn.RefreshHud()

    if Oxlyn.State.open then
        SendNUIMessage({
            action = "schema",
            schema = Oxlyn.BuildSchemaPayload(),
            values = Oxlyn.BuildValuesPayload(),
        })
    end
end)

RegisterNetEvent("oxlyn_fps:forcePreset", function(presetId, byAdmin)
    Oxlyn.ApplyPreset(presetId, { force = true, skipApply = true })
    Oxlyn.ApplyBoost()
    Oxlyn.RefreshHud()

    local preset = Oxlyn.PresetIndex[presetId]
    local label = preset and Oxlyn.T(preset.label) or presetId

    Oxlyn.Notify(
        Oxlyn.L(byAdmin and "notify_admin_force" or "notify_preset", label),
        "warn"
    )

    if Oxlyn.State.open then
        SendNUIMessage({ action = "values", payload = Oxlyn.BuildValuesPayload() })
    end
end)

RegisterNetEvent("oxlyn_fps:notify", function(message, kind)
    Oxlyn.Notify(message, kind)
end)

----------------------------------------------------------------------
-- Commands
----------------------------------------------------------------------
RegisterCommand(Config.Commands.open, function()
    Oxlyn.TogglePanel()
end, false)

-- TriggerEvent("oxlyn_fps:togglePanel") from any client script (or TriggerClientEvent from the server)
RegisterNetEvent("oxlyn_fps:togglePanel", function()
    Oxlyn.TogglePanel()
end)

for _, alias in ipairs(Config.CommandAliases or {}) do
    RegisterCommand(alias, function()
        Oxlyn.TogglePanel()
    end, false)
end

RegisterCommand(Config.Commands.hud, function()
    Oxlyn.ToggleHud()
end, false)

RegisterCommand(Config.Commands.preset, function(_, args)
    -- no argument: list available presets
    if not args[1] then
        local names = {}
        for _, preset in ipairs(Config.Presets) do
            names[#names + 1] = preset.id
        end
        if Config.AllowCustomPreset then
            for _, custom in ipairs(Oxlyn.State.customs) do
                names[#names + 1] = custom.name
            end
        end

        Oxlyn.Notify(("/%s <%s>"):format(Config.Commands.preset, table.concat(names, " | ")), "info")
        return
    end

    local requested = table.concat(args, " "):lower()

    -- match custom presets by name
    for _, custom in ipairs(Oxlyn.State.customs) do
        if custom.name:lower() == requested then
            requested = "custom:" .. custom.id
            break
        end
    end

    local ok, reason = Oxlyn.ApplyPreset(requested)
    if not ok then
        if reason == "preset_locked" then
            Oxlyn.Notify(Oxlyn.L("notify_preset_lock"), "error")
        else
            Oxlyn.Notify(Oxlyn.L("notify_preset_unknown", requested), "error")
        end
    end
end, false)

RegisterCommand(Config.Commands.reset, function()
    Oxlyn.ResetAll()
    Oxlyn.Notify(Oxlyn.L("notify_reset"), "success")
end, false)

RegisterCommand(Config.Commands.stats, function()
    local snap = Oxlyn.FpsSnapshot()
    local preset = Oxlyn.PresetIndex[Oxlyn.State.activePreset]

    Oxlyn.Notify(
        Oxlyn.L("stats_chat",
            snap.current,
            snap.average,
            snap.low1,
            Oxlyn.Metrics.real.ping,
            preset and Oxlyn.T(preset.label) or Oxlyn.State.activePreset
        ),
        "info"
    )
end, false)

----------------------------------------------------------------------
-- Key mappings
----------------------------------------------------------------------
if Config.Keys.open and Config.Keys.open ~= "" then
    RegisterKeyMapping("oxlyn_fps_open", "Oxlyn FPS · abrir painel", "keyboard", Config.Keys.open)
    RegisterCommand("oxlyn_fps_open", function()
        Oxlyn.TogglePanel()
    end, false)
end

if Config.Keys.hud and Config.Keys.hud ~= "" then
    RegisterKeyMapping("oxlyn_fps_hud", "Oxlyn FPS · alternar HUD", "keyboard", Config.Keys.hud)
    RegisterCommand("oxlyn_fps_hud", function()
        Oxlyn.ToggleHud()
    end, false)
end

if Config.Keys.quickBoost and Config.Keys.quickBoost ~= "" then
    RegisterKeyMapping("oxlyn_fps_cycle", "Oxlyn FPS · ciclar preset", "keyboard", Config.Keys.quickBoost)
    RegisterCommand("oxlyn_fps_cycle", function()
        local ids = {}
        for _, preset in ipairs(Config.Presets) do
            ids[#ids + 1] = preset.id
        end

        local current = 1
        for i, id in ipairs(ids) do
            if id == Oxlyn.State.activePreset then
                current = i
                break
            end
        end

        Oxlyn.ApplyPreset(ids[current % #ids + 1])
    end, false)
end

----------------------------------------------------------------------
-- Auto boost: steps preset up/down based on recent average FPS
----------------------------------------------------------------------
CreateThread(function()
    Wait(20000)
    local lastSwitchAt = 0

    while true do
        Wait(5000)

        if Oxlyn.Get("autoBoost")
            and not Oxlyn.Preview.running
            and not Oxlyn.State.overlay then

            local cooldownMs = (Oxlyn.Eff("autoBoostCooldown") or 30) * 1000

            if cooldownMs <= GetGameTimer() - lastSwitchAt then
                local avg     = Oxlyn.RecentAverage(10)
                local floorFps   = Oxlyn.Eff("autoBoostFloor") or 45
                local ceilingFps = Oxlyn.Eff("autoBoostCeiling") or 90

                local ids = {}
                for _, preset in ipairs(Config.Presets) do
                    ids[#ids + 1] = preset.id
                end

                local current = 1
                for i, id in ipairs(ids) do
                    if id == Oxlyn.State.activePreset then
                        current = i
                        break
                    end
                end

                local target
                if avg > 0 and avg < floorFps then
                    if current < #ids then target = ids[current + 1] end
                elseif avg > ceilingFps and current > 1 then
                    target = ids[current - 1]
                end

                if target and target ~= Oxlyn.State.activePreset then
                    if Oxlyn.ApplyPreset(target, { skipApply = true }) then
                        Oxlyn.ApplyBoost()
                        lastSwitchAt = GetGameTimer()

                        local preset = Oxlyn.PresetIndex[target]
                        Oxlyn.Notify(
                            Oxlyn.L("notify_autoboost", preset and Oxlyn.T(preset.label) or target),
                            "info"
                        )
                    end
                end
            end
        end
    end
end)

----------------------------------------------------------------------
-- Low FPS alert (sustained for 15s, at most once per 2 min)
----------------------------------------------------------------------
CreateThread(function()
    Wait(30000)
    local lastAlertAt = 0
    local belowSince  = nil

    while true do
        Wait(3000)

        if Oxlyn.Get("alertLowFps") then
            local threshold = Oxlyn.Eff("alertThreshold") or 30
            local avg = Oxlyn.RecentAverage(8)

            if avg > 0 and threshold > avg then
                belowSince = belowSince or GetGameTimer()

                if GetGameTimer() - belowSince > 15000
                    and GetGameTimer() - lastAlertAt > 120000 then
                    lastAlertAt = GetGameTimer()
                    Oxlyn.Notify(Oxlyn.L("notify_lowfps", floor(avg)), "warn")
                end
            else
                belowSince = nil
            end
        end
    end
end)

----------------------------------------------------------------------
-- Save session summary on resource stop
----------------------------------------------------------------------
AddEventHandler("onResourceStop", function(stoppedResource)
    if stoppedResource ~= resourceName then return end
    if not Config.Monitor.saveSessions then return end

    local fps = Oxlyn.FPS
    if fps.sessionN < 60 then return end

    local year, month, day, hour, minute = GetLocalTime()

    Oxlyn.PushSession({
        date    = ("%04d-%02d-%02d %02d:%02d"):format(year, month, day, hour, minute),
        minutes = floor((GetGameTimer() - Oxlyn.State.sessionStart) / 60000),
        avg     = floor(fps.sessionSum / fps.sessionN + 0.5),
        min     = (fps.sessionMin == 9999) and 0 or fps.sessionMin,
        max     = fps.sessionMax,
        low1    = fps.low1,
        preset  = Oxlyn.State.activePreset,
    })
end)

----------------------------------------------------------------------
-- Exports
----------------------------------------------------------------------
exports("GetFps", function()
    return floor(Oxlyn.FPS.smooth + 0.5)
end)

exports("GetStats", function()
    return Oxlyn.FpsSnapshot()
end)

exports("GetMetrics", function()
    return Oxlyn.MetricsSnapshot()
end)

exports("GetPreset", function()
    return Oxlyn.State.activePreset
end)

exports("ApplyPreset", function(presetId)
    return Oxlyn.ApplyPreset(presetId)
end)

exports("SetSetting", function(id, value)
    return Oxlyn.Set(id, value)
end)

exports("GetSetting", function(id)
    return Oxlyn.Get(id)
end)

exports("OpenPanel", function()
    Oxlyn.SetPanelOpen(true)
end)

exports("ClosePanel", function()
    Oxlyn.SetPanelOpen(false)
end)

exports("ToggleHud", function()
    return Oxlyn.ToggleHud()
end)

exports("RunCleanup", function()
    return Oxlyn.RunCleanup(true)
end)

exports("IsPanelOpen", function()
    return Oxlyn.State.open
end)

----------------------------------------------------------------------
-- Close the panel on configured external events
----------------------------------------------------------------------
for _, eventName in ipairs(Config.Integration.closeOnEvents or {}) do
    AddEventHandler(eventName, function()
        if Oxlyn.State.open then
            Oxlyn.SetPanelOpen(false)
        end
    end)
end

