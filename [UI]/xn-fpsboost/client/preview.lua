

Oxlyn = Oxlyn or {}

Oxlyn.Preview = {
    running = false,
    cancelled = false,
    result = nil,
}

local Preview = Oxlyn.Preview

local SAMPLE_INTERVAL_MS = 50
local DEFAULT_SETTLE_MS = 1500
local DEFAULT_MAX_CUSTOMS = 6

---------------------------------------------------------------------
-- State snapshot / restore
---------------------------------------------------------------------

local function snapshotState()
    local overrides = {}
    for key, value in pairs(Oxlyn.State.overrides) do
        overrides[key] = value
    end

    return {
        preset = Oxlyn.State.activePreset,
        overrides = overrides,
    }
end

local function restoreState(snapshot)
    Oxlyn.State.activePreset = snapshot.preset
    Oxlyn.State.overrides = snapshot.overrides

    Oxlyn.Resolve()
    Oxlyn.SaveLocal()
    Oxlyn.ApplyBoost()
    Oxlyn.RefreshHud()
end

---------------------------------------------------------------------
-- FPS measurement window
-- Returns { avg, low1, frametime } or nil if cancelled
---------------------------------------------------------------------

local function measure(seconds, phase, presetLabel)
    Oxlyn.ResetWindow()

    local low1 = 0
    local totalMs = seconds * 1000
    local endTime = GetGameTimer() + totalMs

    while endTime > GetGameTimer() do
        if Preview.cancelled then
            return nil
        end

        local remaining = endTime - GetGameTimer()

        SendNUIMessage({
            action = "previewProgress",
            phase = phase,
            preset = presetLabel,
            progress = 1.0 - (remaining / totalMs),
            seconds = math.ceil(remaining / 1000),
            fps = math.floor(Oxlyn.FPS.smooth + 0.5),
        })

        low1 = Oxlyn.FPS.low1
        Wait(SAMPLE_INTERVAL_MS)
    end

    local avg = Oxlyn.FPS.average
    if avg <= 0 then
        avg = Oxlyn.RecentAverage(seconds)
    end

    return {
        avg = avg,
        low1 = low1,
        frametime = Oxlyn.FPS.avgFrametime,
    }
end

local function round(value)
    return math.floor(value + 0.5)
end

---------------------------------------------------------------------
-- Run a preview: measure baseline, apply preset, measure again
---------------------------------------------------------------------

function Oxlyn.RunPreview(presetId)
    if Preview.running then
        Oxlyn.Notify(Oxlyn.L("preview_busy"), "warn")
        return
    end

    local isDraft = presetId == "custom:draft"
    local custom = Oxlyn.FindCustom(presetId)
    local preset = Oxlyn.PresetIndex[presetId]

    if not preset and not custom and not isDraft then
        return
    end

    if (isDraft or custom) and not Config.AllowCustomPreset then
        return
    end

    local label
    if isDraft then
        label = Oxlyn.L("preset_custom")
    elseif custom then
        label = custom.name
    else
        label = Oxlyn.T(preset.label)
    end

    Preview.running = true
    Preview.cancelled = false
    Preview.result = nil

    local snapshot = snapshotState()
    local panelWasOpen = Oxlyn.State.open

    -- Restores everything and tells the UI the preview was cancelled
    local function abort()
        restoreState(snapshot)
        Preview.running = false
        SendNUIMessage({ action = "previewCancelled" })

        if panelWasOpen then
            Oxlyn.SetPanelOpen(true, true)
        end
    end

    CreateThread(function()
        if Config.Preview.hidePanel and panelWasOpen then
            Oxlyn.SetPanelOpen(false, true)
        end

        SendNUIMessage({ action = "previewStart", preset = label })
        Oxlyn.Notify(Oxlyn.L("preview_start", Config.Preview.baselineSeconds), "info")

        -- For a draft, the baseline only keeps interface/HUD settings,
        -- so the performance settings of the draft aren't active yet
        if isDraft then
            local baselineOverrides = {}
            for key, value in pairs(snapshot.overrides) do
                local setting = Oxlyn.SettingIndex[key]
                if setting and (setting.group == "interface" or setting.group == "hud") then
                    baselineOverrides[key] = value
                end
            end

            Oxlyn.State.overrides = baselineOverrides
            Oxlyn.Resolve()
            Oxlyn.ApplyBoost()
            Wait(Config.Preview.settleMs or DEFAULT_SETTLE_MS)
        end

        -- Baseline measurement
        local baseline = measure(Config.Preview.baselineSeconds, "baseline", label)
        if not baseline then
            return abort()
        end

        -- Apply what's being tested
        if isDraft then
            restoreState(snapshot)
        else
            Oxlyn.ApplyPreset(presetId, { force = true, skipApply = true })
            Oxlyn.ApplyBoost()
        end

        Oxlyn.Notify(Oxlyn.L("preview_apply", label, Config.Preview.testSeconds), "info")
        Wait(Config.Preview.settleMs or DEFAULT_SETTLE_MS)

        -- Test measurement
        local test = measure(Config.Preview.testSeconds, "test", label)
        if not test then
            return abort()
        end

        local deltaFps = test.avg - baseline.avg
        local deltaPct = 0
        if baseline.avg > 0 then
            deltaPct = (deltaFps / baseline.avg) * 100
        end

        local customsFull = #Oxlyn.State.customs >= (Config.MaxCustomPresets or DEFAULT_MAX_CUSTOMS)
        local willRevert = not isDraft and Config.Preview.autoRevert

        Preview.result = {
            preset = presetId,
            presetLabel = label,
            before = {
                fps = round(baseline.avg),
                low1 = baseline.low1,
                frametime = round(baseline.frametime * 100) / 100,
            },
            after = {
                fps = round(test.avg),
                low1 = test.low1,
                frametime = round(test.frametime * 100) / 100,
            },
            deltaFps = round(deltaFps),
            deltaPct = round(deltaPct),
            reverted = willRevert and true or false,
            canSave = (isDraft and Config.AllowCustomPreset and not customsFull) and true or false,
        }

        if willRevert then
            restoreState(snapshot)
        end

        Preview.running = false

        local sign = deltaFps >= 0 and "+" or ""
        Oxlyn.Notify(
            Oxlyn.L("preview_done", sign, round(deltaFps), sign, round(deltaPct)),
            deltaFps >= 0 and "success" or "warn"
        )

        SendNUIMessage({ action = "previewResult", result = Preview.result })

        if panelWasOpen then
            Oxlyn.SetPanelOpen(true, true)
            SendNUIMessage({ action = "goto", view = "performance" })
        end
    end)
end

---------------------------------------------------------------------
-- Keep the previewed preset (re-applies it if it had been reverted)
---------------------------------------------------------------------

function Oxlyn.KeepPreviewResult()
    if not Preview.result then
        return false
    end

    -- A draft is never reverted, so there's nothing to re-apply
    if Preview.result.preset == "custom:draft" then
        return true
    end

    Oxlyn.ApplyPreset(Preview.result.preset, { force = true })
    Preview.result.reverted = false
    return true
end

---------------------------------------------------------------------
-- Cancel a running preview
---------------------------------------------------------------------

function Oxlyn.CancelPreview()
    if not Preview.running then
        return
    end

    Preview.cancelled = true
    Oxlyn.Notify(Oxlyn.L("preview_cancel"), "warn")
end

