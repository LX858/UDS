

Oxlyn = Oxlyn or {}

Oxlyn.Adaptive = {
    paused   = false,
    afk      = false,
    interior = false,
    key      = "",
}
local Adaptive = Oxlyn.Adaptive

-- Natives (cached locally)
local IsPauseMenuActive      = IsPauseMenuActive
local GetInteriorFromEntity  = GetInteriorFromEntity
local IsControlPressed       = IsControlPressed
local GetGameplayCamRot      = GetGameplayCamRot

-- Controls that count as "player is active" (look, move, sprint, attack, vehicle, etc.)
local ACTIVITY_CONTROLS = { 1, 2, 30, 31, 21, 22, 24, 25, 71, 72, 74, 75, 32, 33, 34, 35 }

-- Higher rank = more aggressive shadow reduction
local SHADOW_RANK = { default = 0, reduced = 1, aircraft = 2, off = 3 }

-- State
local lastBase, lastPaused, lastAfk, lastInterior   -- memoization of applyLayers inputs
local lastPos, lastRot                               -- AFK movement tracking
local afkSince                                       -- timestamp when inactivity began
local interiorChangedAt                              -- timestamp of last interior flip
local wasInInterior = false

---------------------------------------------------------------------
-- Merge helpers
---------------------------------------------------------------------

-- Combines the current value of a setting with an override, depending on setting type.
local function resolveValue(setting, current, override)
    if setting.type == "range" then
        if type(current) ~= "number" then
            return override
        end
        -- lowest value wins
        if override and override < current then
            return override
        end
        return current

    elseif setting.type == "toggle" then
        -- NOTE: literal translation of the decompiled logic
        if current == true and override then
            return override
        end
        return current

    elseif setting.type == "select" and setting.id == "shadowMode" then
        local currentRank  = SHADOW_RANK[current]  or 0
        local overrideRank = SHADOW_RANK[override] or 0
        -- more aggressive shadow mode wins
        if override and currentRank < overrideRank then
            return override
        end
        return current
    end

    return current
end

-- Builds the overlay table for the active layers, or nil if nothing changes.
local function buildOverlay(paused, afk, interior)
    local cfg = Config.Adaptive
    if not cfg then return nil end

    local layers = {}
    if paused   and cfg.pause    then layers[#layers + 1] = cfg.pause    end
    if afk      and cfg.afk      then layers[#layers + 1] = cfg.afk      end
    if interior and cfg.interior then layers[#layers + 1] = cfg.interior end

    if #layers == 0 then return nil end

    local base    = Oxlyn.State.baseValues
    local overlay = {}
    local changed = false

    for _, layer in ipairs(layers) do
        for key, value in pairs(layer) do
            local setting = Oxlyn.SettingIndex[key]
            if setting then
                local current = overlay[key]
                if current == nil then
                    current = base[key]
                end

                local resolved = resolveValue(setting, current, value)
                if resolved ~= base[key] then
                    overlay[key] = resolved
                    changed = true
                end
            end
        end
    end

    return changed and overlay or nil
end

-- Deterministic "k=v;k=v" string used to detect overlay changes.
local function serialize(tbl)
    if not tbl then return "" end

    local keys = {}
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end
    table.sort(keys)

    local parts = {}
    for i, k in ipairs(keys) do
        parts[i] = k .. "=" .. tostring(tbl[k])
    end
    return table.concat(parts, ";")
end

---------------------------------------------------------------------
-- Applying the overlay
---------------------------------------------------------------------

local function applyLayers(paused, afk, interior)
    local base = Oxlyn.State.baseValues

    -- Skip if nothing changed since last call
    if base == lastBase
        and paused   == lastPaused
        and afk      == lastAfk
        and interior == lastInterior then
        return
    end

    lastPaused, lastAfk, lastInterior = paused, afk, interior
    lastBase = base

    local overlay = buildOverlay(paused, afk, interior)
    local key = serialize(overlay)

    if key == Adaptive.key then return end
    Adaptive.key = key

    Oxlyn.SetOverlay(overlay)
    lastBase = Oxlyn.State.baseValues
    Oxlyn.ApplyBoost()

    Oxlyn.Debug(("camada adaptativa: %s"):format(key == "" and "nenhuma" or key))
end

---------------------------------------------------------------------
-- AFK detection
---------------------------------------------------------------------

local function anyActivityInput()
    if not IsControlPressed then return false end

    for i = 1, #ACTIVITY_CONTROLS do
        if IsControlPressed(0, ACTIVITY_CONTROLS[i]) then
            return true
        end
    end
    return false
end

-- Returns true if the player moved, looked around, or pressed an input.
local function playerIsActive(ped)
    local cfg = Config.Adaptive or {}
    local moveThreshold = cfg.afkMoveThreshold or 0.25
    local lookThreshold = cfg.afkLookThreshold or 0.5

    local pos = GetEntityCoords(ped)
    local rot = GetGameplayCamRot and GetGameplayCamRot(2) or nil

    local active = false

    if lastPos and #(pos - lastPos) > moveThreshold then
        active = true
    end

    if rot and lastRot then
        if math.abs(rot.z - lastRot.z) > lookThreshold
            or math.abs(rot.x - lastRot.x) > lookThreshold then
            active = true
        end
    end

    lastPos, lastRot = pos, rot

    if not active and anyActivityInput() then
        active = true
    end

    return active
end

---------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------

CreateThread(function()
    Wait(6000)

    while true do
        Wait(1000)

        -- NOTE: reconstructed from garbled decompiler output
        local ready = Oxlyn.State.ready
            and not (Oxlyn.Preview and Oxlyn.Preview.running)

        local pauseEnabled    = ready and Oxlyn.Get("pauseSaver")    == true
        local afkEnabled      = ready and Oxlyn.Get("afkSaver")      == true
        local interiorEnabled = ready and Oxlyn.Get("interiorSaver") == true

        if not pauseEnabled and not afkEnabled and not interiorEnabled then
            -- Everything disabled: clear any active overlay and reset state
            if Adaptive.key ~= "" then
                applyLayers(false, false, false)
            end
            Adaptive.paused, Adaptive.afk, Adaptive.interior = false, false, false
            afkSince = nil
        else
            local now = GetGameTimer()
            local ped = PlayerPedId()

            -- Pause menu
            local paused = pauseEnabled
                and IsPauseMenuActive ~= nil
                and IsPauseMenuActive()
                or false

            -- AFK
            local afk = false
            if afkEnabled then
                if Oxlyn.State.open or paused or playerIsActive(ped) then
                    afkSince = nil
                else
                    afkSince = afkSince or now
                    local afkMs = (Oxlyn.Eff("afkMinutes") or 5) * 60000
                    afk = (now - afkSince) >= afkMs
                end
            else
                afkSince = nil
            end

            -- Interior
            local interior = false
            if interiorEnabled and GetInteriorFromEntity then
                local inInterior = GetInteriorFromEntity(ped) ~= 0

                if inInterior ~= wasInInterior then
                    interiorChangedAt = now
                    wasInInterior = inInterior
                end

                local hysteresisMs = ((Config.Adaptive and Config.Adaptive.interiorHysteresis) or 3) * 1000

                -- NOTE: literal translation. The decompiler's block nesting here is
                -- ambiguous; the intended logic may be:
                --   if interiorChangedAt and (now - interiorChangedAt) >= hysteresisMs
                --   then interior = inInterior else interior = Adaptive.interior end
                if interiorChangedAt then
                    if (now - interiorChangedAt) >= hysteresisMs then
                        interior = inInterior
                    end
                else
                    interior = Adaptive.interior
                end
            end

            -- Notify on AFK state change
            if afk ~= Adaptive.afk then
                Oxlyn.Notify(Oxlyn.L(afk and "notify_afk_on" or "notify_afk_off"), "info")
            end

            Adaptive.paused   = paused
            Adaptive.afk      = afk
            Adaptive.interior = interior

            applyLayers(paused, afk, interior)
        end
    end
end)

---------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Oxlyn.State.overlay then
        Oxlyn.SetOverlay(nil)
    end
end)

