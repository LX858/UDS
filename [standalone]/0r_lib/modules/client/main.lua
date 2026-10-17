

-- Global reference to the detected framework export object (ESX or QBCore).
-- Populated during framework detection below.
ResmonFramework = nil

-- Initialise sub-tables on Resmon.Lib so every module can safely read/write
-- without nil-index errors, regardless of initialisation order.
Resmon.Lib.PlayerData       = {}   -- Cached local player data (job, money, id …)
Resmon.Lib.CurrentRequestId = 0   -- Auto-incrementing ID for server callbacks
Resmon.Lib.ServerCallbacks  = {}   -- Pending server-callback functions [id] = fn
Resmon.Lib.UI               = {}   -- UI state storage
Resmon.Lib.Callback         = {}   -- Callback helpers namespace
Resmon.Lib.PropertiesVehicle= {}   -- Vehicle property get/set helpers
Resmon.Lib.Craft            = {}   -- Crafting table helpers (v1)
Resmon.Lib.Apartment        = {}   -- Apartment / property helpers
Resmon.Lib.Craft_V2         = {}   -- Crafting table helpers (v2)


-- =============================================================================
-- SECTION 2 – FRAMEWORK DETECTION
-- Checks whether ESX or QBCore is present and grabs the shared object.
-- Last framework found wins (QBCore check runs after ESX).
-- =============================================================================

-- ── ESX ──────────────────────────────────────────────────────────────────────
local esxResourceState = GetResourceState(Config.CoreName.ESX)
if esxResourceState ~= "missing" then
    Config.Framework = "ESX"
    -- Fetch the ESX shared object via its export
    ResmonFramework = exports[Config.CoreName.ESX]:getSharedObject()
end

-- ── QBCore ───────────────────────────────────────────────────────────────────
local qbResourceState = GetResourceState(Config.CoreName.QBCore)
if qbResourceState ~= "missing" then
    Config.Framework = "QBCore"
    -- Fetch the QBCore shared object via its export
    ResmonFramework = exports[Config.CoreName.QBCore]:GetCoreObject()
end


-- =============================================================================
-- SECTION 3 – FRAMEWORK HELPERS
-- =============================================================================

-- Resmon.Lib.GetFramework()
-- Returns the currently active framework name ("ESX" or "QBCore").
function Resmon.Lib.GetFramework()
    return Config.Framework
end

-- Also expose as a resource export so other scripts can query the framework.
exports("GetFramework", function()
    return Config.Framework
end)

-- Cache the framework-specific event names into Resmon.Lib for convenience.
Resmon.Lib.PlayerLoadedEvent = Config.PlayerLoadedEvents[Config.Framework]
Resmon.Lib.PlayerJobEvent    = Config.PlayerJobEvents[Config.Framework]


-- =============================================================================
-- SECTION 4 – UTILITY FUNCTIONS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GenerateHash(inputString, patternToRemove)
-- Strips 'patternToRemove' from 'inputString' then replaces every remaining
-- character with a random printable ASCII character (32–126).
-- Used to produce random-looking strings the same length as the stripped input.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GenerateHash(inputString, patternToRemove)
    -- Remove the unwanted pattern from the input
    local stripped = string.gsub(inputString, patternToRemove, "")

    local result = ""
    -- Replace each character with a random printable ASCII character
    for i = 1, string.len(stripped), 1 do
        local randomChar = string.char(math.random(32, 126))
        result = result .. randomChar
    end
    return result
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.DumpTable(value, indentLevel)
-- Recursively serialises a Lua value (table or scalar) to a human-readable
-- string with indentation, similar to a pretty-printer / inspect function.
-- 'indentLevel' defaults to 0 and increases for nested tables.
-- ----------------------------------------------------------------------------
function Resmon.Lib.DumpTable(value, indentLevel)
    if indentLevel == nil then indentLevel = 0 end

    if type(value) == "table" then
        -- Build the leading indentation string for this level
        local indent = ""
        for _ = 1, indentLevel + 1, 1 do
            indent = indent .. "    "
        end

        local output = "{\n"

        -- Iterate every key/value pair in the table
        for k, v in pairs(value) do
            -- Wrap string keys in quotes; leave numeric keys bare
            local keyStr = k
            if type(k) ~= "number" then
                keyStr = "\"" .. k .. "\""
            end

            -- Build inner indentation
            local innerIndent = ""
            for _ = 1, indentLevel, 1 do
                innerIndent = innerIndent .. "    "
            end

            -- Recursively dump the value, increasing indent depth by 1
            output = output .. "[" .. keyStr .. "] = "
                           .. Resmon.Lib.DumpTable(v, indentLevel + 1)
                           .. ",\n"
        end

        -- Closing brace with correct indentation
        local closingIndent = ""
        for _ = 1, indentLevel, 1 do
            closingIndent = closingIndent .. "    "
        end
        return output .. closingIndent .. "}"
    else
        -- Scalar value: just convert to string
        return tostring(value)
    end
end


-- ----------------------------------------------------------------------------
-- Net event: 0R:Lib:Notify  (server → client)
-- Sends a notification to the NUI layer.
-- The data table is forwarded as-is so the front-end can style it.
-- ----------------------------------------------------------------------------
RegisterNetEvent("0R:Lib:Notify")
AddEventHandler("0R:Lib:Notify", function(notifyData)
    SendNUIMessage({
        type = "showNotify",
        data = notifyData,
    })
end)


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Notify(notifyData)
-- Client-side wrapper: sends a notification directly via NUI without going
-- through the server event.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Notify(notifyData)
    SendNUIMessage({
        type = "showNotify",
        data = notifyData,
    })
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.ShowTextUI(text, icon)
-- Displays a text-UI prompt (the small contextual hint shown on screen).
-- If Config.CustomTextUI is set, defers to the configured custom function
-- instead of the built-in NUI message.
-- ----------------------------------------------------------------------------
function Resmon.Lib.ShowTextUI(text, icon)
    if not Config.CustomTextUI then
        -- Built-in NUI text-UI
        SendNUIMessage({
            type   = "showUI",
            icon   = icon,
            string = text,
        })
    else
        -- User-supplied custom text-UI function
        Config.CustomTextUIFunc(text)
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.ShowNotify(message, notifyType, duration)
-- Displays a framework notification (ESX or QBCore flavour).
-- Falls back to nothing if Config.CustomNotify is truthy (caller handles it).
-- ----------------------------------------------------------------------------
function Resmon.Lib.ShowNotify(message, notifyType, duration)
    if not Config.CustomNotify then
        if Config.Framework == "ESX" then
            ResmonFramework.ShowNotification(message, notifyType, duration)
        else
            ResmonFramework.Functions.Notify(message, notifyType, duration)
        end
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.HideTextUI()
-- Hides the text-UI prompt shown by ShowTextUI.
-- Calls the custom hide function when configured.
-- ----------------------------------------------------------------------------
function Resmon.Lib.HideTextUI()
    if not Config.CustomTextUI then
        SendNUIMessage({ type = "hideUI" })
    else
        Config.CustomTextUIHide()
    end
end


-- =============================================================================
-- SECTION 5 – SERVER CALLBACK SYSTEM
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Callback.Client(callbackName, callbackFn, ...)
-- Triggers a named server-side callback and registers a local function to
-- handle the response when the server fires "0R:Core:ServerCallback".
--
-- Parameters:
--   callbackName  – string key identifying the server callback
--   callbackFn    – function(result, ...) called when the server responds
--   ...           – extra arguments forwarded to the server handler
--
-- Request IDs cycle 0 → 65534 → 0 to avoid collisions.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Callback.Client(callbackName, callbackFn, ...)
    -- Store the callback under the current request ID
    Resmon.Lib.ServerCallbacks[Resmon.Lib.CurrentRequestId] = callbackFn

    -- Ask the server to execute the named callback and return results
    TriggerServerEvent(
        "0R:Core:TriggerCallback",
        callbackName,
        Resmon.Lib.CurrentRequestId,
        ...
    )

    -- Advance the request ID, wrapping at 65535
    if Resmon.Lib.CurrentRequestId < 65535 then
        Resmon.Lib.CurrentRequestId = Resmon.Lib.CurrentRequestId + 1
    else
        Resmon.Lib.CurrentRequestId = 0
    end
end


-- =============================================================================
-- SECTION 6 – PLAYER HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.IsPlayerLoaded()
-- Returns true when the local player is fully loaded into the session.
-- Uses the framework-appropriate API.
-- ----------------------------------------------------------------------------
function Resmon.Lib.IsPlayerLoaded()
    if Config.Framework == "ESX" then
        return ResmonFramework.IsPlayerLoaded()
    else
        -- QBCore exposes login state via a statebag
        return LocalPlayer.state.isLoggedIn
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerData()
-- Returns a normalised player-data table regardless of the active framework.
-- Fields always present in the returned table:
--   .identifier  – citizen / license identifier string
--   .cash        – current cash amount
--   .bank        – current bank balance
--   .job         – job table (with .grade_level normalised to a number)
-- Returns an empty table when the framework object is not yet available.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerData()
    local playerData = {}

    -- Guard: framework not initialised yet
    if not ResmonFramework then
        return playerData
    end

    if Config.Framework == "ESX" then
        -- ── ESX path ──────────────────────────────────────────────────────
        playerData = ResmonFramework.GetPlayerData()

        -- ESX stores money inside an 'accounts' array; flatten it for convenience
        for _, account in pairs(playerData.accounts or {}) do
            if account.name == "bank" then
                playerData.bank = account.money
            elseif account.name == "money" then
                playerData.cash = account.money
            end
        end

        -- Normalise grade to a flat .grade_level number
        if playerData.job then
            playerData.job.grade_level = playerData.job.grade
        end

    else
        -- ── QBCore path ───────────────────────────────────────────────────
        local rawData = ResmonFramework.Functions.GetPlayerData()
        playerData = rawData or playerData

        if not rawData then
            playerData = {}
        end

        -- Normalise identifier (QBCore uses citizenid, ESX uses identifier)
        local identifier = playerData.citizenid or playerData.identifier
        playerData.identifier = identifier

        -- Flatten money sub-table
        local moneyTable = playerData.money or {}

        local cash = moneyTable.cash or playerData.cash or 0
        playerData.cash = cash

        local bank = moneyTable.bank or playerData.bank or 0
        playerData.bank = bank

        -- Normalise job grade to a flat number
        if playerData.job then
            local grade = playerData.job.grade
            if type(grade) == "table" then
                -- QBCore grade is sometimes a sub-table {level, name, …}
                playerData.job.grade_level = grade.level or grade.grade or 0
            else
                -- Grade is already a number (or nil)
                playerData.job.grade_level = grade or 0
            end
        end
    end

    return playerData
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetClosestPlayer(coords)
-- Finds the player (excluding self) closest to 'coords'.
-- If 'coords' is nil, uses the local player's current position.
--
-- Returns: playerId (integer), distance (float)
--          Returns -1, -1 when no other players are present.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetClosestPlayer(coords)
    local allPlayers   = Resmon.Lib.GetPlayers()
    local closestDist  = -1
    local closestId    = -1
    local searchCoords = coords
    local excludeSelf  = false

    local localPed      = PlayerPedId()
    local localPlayerId = PlayerId()

    -- When no coords given, search from own position and exclude self
    if searchCoords == nil then
        excludeSelf  = true
        searchCoords = GetEntityCoords(localPed)
    end

    for i = 1, #allPlayers, 1 do
        local ped = GetPlayerPed(allPlayers[i])

        -- Skip the local player when searching from own position
        if excludeSelf then
            if allPlayers[i] == localPlayerId then
                goto continueClosestPlayer
            end
        end

        local pedCoords = GetEntityCoords(ped)
        local dist = GetDistanceBetweenCoords(
            pedCoords, searchCoords.x, searchCoords.y, searchCoords.z, true
        )

        if closestDist == -1 or closestDist > dist then
            closestId   = allPlayers[i]
            closestDist = dist
        end

        ::continueClosestPlayer::
    end

    return closestId, closestDist
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayers(excludeSelf, returnPedMap, returnPeds)
-- Returns a list of active players on the server.
--
-- Parameters:
--   excludeSelf  – when true, the local player is omitted
--   returnPedMap – when true, returns a table keyed by player ID → ped handle
--   returnPeds   – when true (and returnPedMap false), stores ped handles
--                  instead of player IDs in the result array
-- Returns: table of player IDs, ped handles, or a map depending on flags.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayers(excludeSelf, returnPedMap, returnPeds)
    local result      = {}
    local localId     = PlayerId()

    for _, playerId in ipairs(GetActivePlayers()) do
        local ped      = GetPlayerPed(playerId)
        local pedExists = DoesEntityExist(ped)

        -- Include this player if their ped exists and the exclude flag is met
        if pedExists and (excludeSelf and playerId ~= localId or not excludeSelf) then
            if returnPedMap then
                -- Map: result[playerId] = pedHandle
                result[playerId] = ped
            else
                local insertValue = (returnPeds and ped) or playerId
                result[#result + 1] = insertValue
            end
        end
    end

    return result
end


-- =============================================================================
-- SECTION 7 – VEHICLE PROPERTIES
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlate(vehicleHandle)
-- Returns the trimmed licence plate text for the given vehicle entity.
-- Returns nil if the handle is 0 (no vehicle).
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlate(vehicleHandle)
    if vehicleHandle == 0 then return end
    return Resmon.Lib.Trim(GetVehicleNumberPlateText(vehicleHandle))
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.PropertiesVehicle.Get(vehicleHandle)
-- Reads and returns a comprehensive properties table for a vehicle entity.
-- Returns nil (implicit) if the entity does not exist.
--
-- The returned table contains every cosmetic and mechanical property:
--   colours, mods (0-49), livery, neons, tyres, damage state, etc.
-- ----------------------------------------------------------------------------
function Resmon.Lib.PropertiesVehicle.Get(vehicleHandle)
    if not DoesEntityExist(vehicleHandle) then return end

    -- ── Colours ───────────────────────────────────────────────────────────
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicleHandle)
    local color1, color2               = GetVehicleColours(vehicleHandle)

    -- Custom primary colour (RGB table) overrides the palette index
    if GetIsVehiclePrimaryColourCustom(vehicleHandle) then
        local r, g, b = GetVehicleCustomPrimaryColour(vehicleHandle)
        color1 = { r, g, b }
    end

    -- Custom secondary colour (RGB table) overrides the palette index
    if GetIsVehicleSecondaryColourCustom(vehicleHandle) then
        local r, g, b = GetVehicleCustomSecondaryColour(vehicleHandle)
        color2 = { r, g, b }
    end

    -- ── Extras ────────────────────────────────────────────────────────────
    local extras = {}
    for extraId = 0, 12, 1 do
        if DoesExtraExist(vehicleHandle, extraId) then
            local isOn = IsVehicleExtraTurnedOn(vehicleHandle, extraId)
            extras[tostring(extraId)] = (isOn == 1)
        end
    end

    -- ── Livery ────────────────────────────────────────────────────────────
    -- Mod slot 48 stores the livery; fall back to GetVehicleLivery when -1
    local modLivery = GetVehicleMod(vehicleHandle, 48)
    if modLivery == -1 then
        local liveryId = GetVehicleLivery(vehicleHandle)
        if liveryId ~= 0 then
            modLivery = liveryId
        end
    end

    -- ── Tyre health ───────────────────────────────────────────────────────
    local tireHealth = {}
    for wheelIdx = 0, 3, 1 do
        tireHealth[wheelIdx] = GetVehicleWheelHealth(vehicleHandle, wheelIdx)
    end

    -- ── Tyre burst state (partial / fully burst) ──────────────────────────
    local tireBurstState = {}
    for tireIdx = 0, 5, 1 do
        tireBurstState[tireIdx] = IsVehicleTyreBurst(vehicleHandle, tireIdx, false)
    end

    local tireBurstCompletely = {}
    for tireIdx = 0, 5, 1 do
        tireBurstCompletely[tireIdx] = IsVehicleTyreBurst(vehicleHandle, tireIdx, true)
    end

    -- ── Window integrity ──────────────────────────────────────────────────
    local windowStatus = {}
    for winIdx = 0, 7, 1 do
        windowStatus[winIdx] = (IsVehicleWindowIntact(vehicleHandle, winIdx) == 1)
    end

    -- ── Door damage ───────────────────────────────────────────────────────
    local doorStatus = {}
    for doorIdx = 0, 5, 1 do
        doorStatus[doorIdx] = (IsVehicleDoorDamaged(vehicleHandle, doorIdx) == 1)
    end

    -- ── Neon lights ───────────────────────────────────────────────────────
    local neonEnabled = {
        IsVehicleNeonLightEnabled(vehicleHandle, 0),  -- left
        IsVehicleNeonLightEnabled(vehicleHandle, 1),  -- right
        IsVehicleNeonLightEnabled(vehicleHandle, 2),  -- front
        IsVehicleNeonLightEnabled(vehicleHandle, 3),  -- back
    }
    local neonColor = table.pack(GetVehicleNeonLightsColour(vehicleHandle))

    -- ── Assemble properties table ─────────────────────────────────────────
    local props = {}

    props.model          = GetEntityModel(vehicleHandle)
    props.plate          = Resmon.Lib.GetPlate(vehicleHandle)
    props.plateIndex     = GetVehicleNumberPlateTextIndex(vehicleHandle)
    props.bodyHealth     = Resmon.Lib.Round(GetVehicleBodyHealth(vehicleHandle),    0.1)
    props.engineHealth   = Resmon.Lib.Round(GetVehicleEngineHealth(vehicleHandle),  0.1)
    props.tankHealth     = Resmon.Lib.Round(GetVehiclePetrolTankHealth(vehicleHandle), 0.1)
    props.fuelLevel      = Resmon.Lib.Round(GetVehicleFuelLevel(vehicleHandle),     0.1)
    props.dirtLevel      = Resmon.Lib.Round(GetVehicleDirtLevel(vehicleHandle),     0.1)
    props.oilLevel       = Resmon.Lib.Round(GetVehicleOilLevel(vehicleHandle),      0.1)
    props.color1         = color1
    props.color2         = color2
    props.pearlescentColor = pearlescentColor
    props.dashboardColor = GetVehicleDashboardColour(vehicleHandle)
    props.wheelColor     = wheelColor
    props.wheels         = GetVehicleWheelType(vehicleHandle)
    props.wheelSize      = GetVehicleWheelSize(vehicleHandle)
    props.wheelWidth     = GetVehicleWheelWidth(vehicleHandle)
    props.tireHealth         = tireHealth
    props.tireBurstState     = tireBurstState
    props.tireBurstCompletely = tireBurstCompletely
    props.windowTint     = GetVehicleWindowTint(vehicleHandle)
    props.windowStatus   = windowStatus
    props.doorStatus     = doorStatus
    props.xenonColor     = GetVehicleXenonLightsColour(vehicleHandle)
    props.neonEnabled    = neonEnabled
    props.neonColor      = neonColor
    props.headlightColor = GetVehicleHeadlightsColour(vehicleHandle)
    props.interiorColor  = GetVehicleInteriorColour(vehicleHandle)
    props.extras         = extras
    props.tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicleHandle))

    -- ── Vehicle mods (slots 0–49) ─────────────────────────────────────────
    props.modSpoilers      = GetVehicleMod(vehicleHandle, 0)
    props.modFrontBumper   = GetVehicleMod(vehicleHandle, 1)
    props.modRearBumper    = GetVehicleMod(vehicleHandle, 2)
    props.modSideSkirt     = GetVehicleMod(vehicleHandle, 3)
    props.modExhaust       = GetVehicleMod(vehicleHandle, 4)
    props.modFrame         = GetVehicleMod(vehicleHandle, 5)
    props.modGrille        = GetVehicleMod(vehicleHandle, 6)
    props.modHood          = GetVehicleMod(vehicleHandle, 7)
    props.modFender        = GetVehicleMod(vehicleHandle, 8)
    props.modRightFender   = GetVehicleMod(vehicleHandle, 9)
    props.modRoof          = GetVehicleMod(vehicleHandle, 10)
    props.modEngine        = GetVehicleMod(vehicleHandle, 11)
    props.modBrakes        = GetVehicleMod(vehicleHandle, 12)
    props.modTransmission  = GetVehicleMod(vehicleHandle, 13)
    props.modHorns         = GetVehicleMod(vehicleHandle, 14)
    props.modSuspension    = GetVehicleMod(vehicleHandle, 15)
    props.modArmor         = GetVehicleMod(vehicleHandle, 16)
    props.modKit17         = GetVehicleMod(vehicleHandle, 17)
    props.modTurbo         = IsToggleModOn(vehicleHandle, 18)   -- toggle mod
    props.modKit19         = GetVehicleMod(vehicleHandle, 19)
    props.modSmokeEnabled  = IsToggleModOn(vehicleHandle, 20)   -- toggle mod
    props.modKit21         = GetVehicleMod(vehicleHandle, 21)
    props.modXenon         = IsToggleModOn(vehicleHandle, 22)   -- toggle mod
    props.modFrontWheels   = GetVehicleMod(vehicleHandle, 23)
    props.modBackWheels    = GetVehicleMod(vehicleHandle, 24)
    props.modCustomTiresF  = GetVehicleModVariation(vehicleHandle, 23)
    props.modCustomTiresR  = GetVehicleModVariation(vehicleHandle, 24)
    props.modPlateHolder   = GetVehicleMod(vehicleHandle, 25)
    props.modVanityPlate   = GetVehicleMod(vehicleHandle, 26)
    props.modTrimA         = GetVehicleMod(vehicleHandle, 27)
    props.modOrnaments     = GetVehicleMod(vehicleHandle, 28)
    props.modDashboard     = GetVehicleMod(vehicleHandle, 29)
    props.modDial          = GetVehicleMod(vehicleHandle, 30)
    props.modDoorSpeaker   = GetVehicleMod(vehicleHandle, 31)
    props.modSeats         = GetVehicleMod(vehicleHandle, 32)
    props.modSteeringWheel = GetVehicleMod(vehicleHandle, 33)
    props.modShifterLeavers= GetVehicleMod(vehicleHandle, 34)
    props.modAPlate        = GetVehicleMod(vehicleHandle, 35)
    props.modSpeakers      = GetVehicleMod(vehicleHandle, 36)
    props.modTrunk         = GetVehicleMod(vehicleHandle, 37)
    props.modHydrolic      = GetVehicleMod(vehicleHandle, 38)
    props.modEngineBlock   = GetVehicleMod(vehicleHandle, 39)
    props.modAirFilter     = GetVehicleMod(vehicleHandle, 40)
    props.modStruts        = GetVehicleMod(vehicleHandle, 41)
    props.modArchCover     = GetVehicleMod(vehicleHandle, 42)
    props.modAerials       = GetVehicleMod(vehicleHandle, 43)
    props.modTrimB         = GetVehicleMod(vehicleHandle, 44)
    props.modTank          = GetVehicleMod(vehicleHandle, 45)
    props.modWindows       = GetVehicleMod(vehicleHandle, 46)
    props.modKit47         = GetVehicleMod(vehicleHandle, 47)
    props.modLivery        = modLivery
    props.modKit49         = GetVehicleMod(vehicleHandle, 49)
    props.liveryRoof       = GetVehicleRoofLivery(vehicleHandle)

    return props
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.PropertiesVehicle.Set(vehicleHandle, props)
-- Applies a properties table (produced by .Get) back onto a vehicle entity.
-- Only fields present (non-nil / truthy) in 'props' are applied, so partial
-- updates are safe.
-- ----------------------------------------------------------------------------
function Resmon.Lib.PropertiesVehicle.Set(vehicleHandle, props)
    if not DoesEntityExist(vehicleHandle) then return end

    -- ── Extras ────────────────────────────────────────────────────────────
    if props.extras then
        for extraIdStr, isEnabled in pairs(props.extras) do
            local extraId = tonumber(extraIdStr)
            if isEnabled then
                SetVehicleExtra(vehicleHandle, extraId, 0) -- 0 = enabled
            else
                SetVehicleExtra(vehicleHandle, extraId, 1) -- 1 = disabled
            end
        end
    end

    -- Cache current colours so we can use them as fallbacks below
    local currentColor1, currentColor2         = GetVehicleColours(vehicleHandle)
    local currentPearlescent, currentWheelColor = GetVehicleExtraColours(vehicleHandle)

    -- Ensure the mod kit is reset so mods apply correctly
    SetVehicleModKit(vehicleHandle, 0)

    -- ── Plate ─────────────────────────────────────────────────────────────
    if props.plate then
        SetVehicleNumberPlateText(vehicleHandle, props.plate)
    end
    if props.plateIndex then
        SetVehicleNumberPlateTextIndex(vehicleHandle, props.plateIndex)
    end

    -- ── Health / condition ────────────────────────────────────────────────
    if props.bodyHealth   then SetVehicleBodyHealth(vehicleHandle,       props.bodyHealth   + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicleHandle,     props.engineHealth + 0.0) end
    if props.tankHealth   then SetVehiclePetrolTankHealth(vehicleHandle, props.tankHealth) end
    if props.fuelLevel    then SetVehicleFuelLevel(vehicleHandle,        props.fuelLevel    + 0.0) end
    if props.dirtLevel    then SetVehicleDirtLevel(vehicleHandle,        props.dirtLevel    + 0.0) end
    if props.oilLevel     then SetVehicleOilLevel(vehicleHandle,         props.oilLevel) end

    -- ── Primary colour ────────────────────────────────────────────────────
    if props.color1 then
        if type(props.color1) == "number" then
            -- Palette index
            ClearVehicleCustomPrimaryColour(vehicleHandle)
            SetVehicleColours(vehicleHandle, props.color1, currentColor2)
        else
            -- RGB table {r, g, b}
            SetVehicleCustomPrimaryColour(
                vehicleHandle,
                props.color1[1], props.color1[2], props.color1[3]
            )
        end
    end

    -- ── Secondary colour ──────────────────────────────────────────────────
    if props.color2 then
        if type(props.color2) == "number" then
            ClearVehicleCustomSecondaryColour(vehicleHandle)
            SetVehicleColours(
                vehicleHandle,
                props.color1 or currentColor1,
                props.color2
            )
        else
            SetVehicleCustomSecondaryColour(
                vehicleHandle,
                props.color2[1], props.color2[2], props.color2[3]
            )
        end
    end

    -- ── Pearlescent / wheel colours ───────────────────────────────────────
    if props.pearlescentColor then
        SetVehicleExtraColours(vehicleHandle, props.pearlescentColor, currentWheelColor)
    end
    if props.interiorColor   then SetVehicleInteriorColor(vehicleHandle, props.interiorColor) end
    if props.dashboardColor  then SetVehicleDashboardColour(vehicleHandle, props.dashboardColor) end
    if props.wheelColor then
        SetVehicleExtraColours(
            vehicleHandle,
            props.pearlescentColor or currentPearlescent,
            props.wheelColor
        )
    end

    -- ── Wheel type and size ───────────────────────────────────────────────
    if props.wheels    then SetVehicleWheelType(vehicleHandle, props.wheels) end
    if props.wheelSize then SetVehicleWheelSize(vehicleHandle, props.wheelSize) end
    if props.wheelWidth then SetVehicleWheelWidth(vehicleHandle, props.wheelWidth) end

    -- ── Tyre health ───────────────────────────────────────────────────────
    if props.tireHealth then
        for wheelIdx, health in pairs(props.tireHealth) do
            SetVehicleWheelHealth(vehicleHandle, wheelIdx, health)
        end
    end

    -- ── Tyre burst (partial) ──────────────────────────────────────────────
    if props.tireBurstState then
        for tireIdxStr, isBurst in pairs(props.tireBurstState) do
            if isBurst then
                SetVehicleTyreBurst(vehicleHandle, tonumber(tireIdxStr), false, 1000.0)
            end
        end
    end

    -- ── Tyre burst (completely flat) ──────────────────────────────────────
    if props.tireBurstCompletely then
        for tireIdxStr, isBurst in pairs(props.tireBurstCompletely) do
            if isBurst then
                SetVehicleTyreBurst(vehicleHandle, tonumber(tireIdxStr), true, 1000.0)
            end
        end
    end

    -- ── Window tint ───────────────────────────────────────────────────────
    if props.windowTint then SetVehicleWindowTint(vehicleHandle, props.windowTint) end

    -- ── Window damage ─────────────────────────────────────────────────────
    if props.windowStatus then
        for winIdx, isIntact in pairs(props.windowStatus) do
            if not isIntact then
                SmashVehicleWindow(vehicleHandle, winIdx)
            end
        end
    end

    -- ── Door damage ───────────────────────────────────────────────────────
    if props.doorStatus then
        for doorIdxStr, isDamaged in pairs(props.doorStatus) do
            if isDamaged then
                SetVehicleDoorBroken(vehicleHandle, tonumber(doorIdxStr), true)
            end
        end
    end

    -- ── Neon lights ───────────────────────────────────────────────────────
    if props.neonEnabled then
        SetVehicleNeonLightEnabled(vehicleHandle, 0, props.neonEnabled[1])
        SetVehicleNeonLightEnabled(vehicleHandle, 1, props.neonEnabled[2])
        SetVehicleNeonLightEnabled(vehicleHandle, 2, props.neonEnabled[3])
        SetVehicleNeonLightEnabled(vehicleHandle, 3, props.neonEnabled[4])
    end
    if props.neonColor then
        SetVehicleNeonLightsColour(
            vehicleHandle,
            props.neonColor[1], props.neonColor[2], props.neonColor[3]
        )
    end

    -- ── Headlight / interior colours ──────────────────────────────────────
    if props.headlightColor then SetVehicleHeadlightsColour(vehicleHandle, props.headlightColor) end
    if props.interiorColor  then SetVehicleInteriorColour(vehicleHandle,   props.interiorColor) end

    -- ── Tyre smoke colour ─────────────────────────────────────────────────
    if props.tyreSmokeColor then
        SetVehicleTyreSmokeColor(
            vehicleHandle,
            props.tyreSmokeColor[1],
            props.tyreSmokeColor[2],
            props.tyreSmokeColor[3]
        )
    end

    -- ── Xenon colour ──────────────────────────────────────────────────────
    if props.xenonColor then SetVehicleXenonLightsColor(vehicleHandle, props.xenonColor) end

    -- ── Mods (SetVehicleMod for most; ToggleVehicleMod for toggles) ───────
    if props.modSpoilers      then SetVehicleMod(vehicleHandle, 0,  props.modSpoilers,     false) end
    if props.modFrontBumper   then SetVehicleMod(vehicleHandle, 1,  props.modFrontBumper,  false) end
    if props.modRearBumper    then SetVehicleMod(vehicleHandle, 2,  props.modRearBumper,   false) end
    if props.modSideSkirt     then SetVehicleMod(vehicleHandle, 3,  props.modSideSkirt,    false) end
    if props.modExhaust       then SetVehicleMod(vehicleHandle, 4,  props.modExhaust,      false) end
    if props.modFrame         then SetVehicleMod(vehicleHandle, 5,  props.modFrame,        false) end
    if props.modGrille        then SetVehicleMod(vehicleHandle, 6,  props.modGrille,       false) end
    if props.modHood          then SetVehicleMod(vehicleHandle, 7,  props.modHood,         false) end
    if props.modFender        then SetVehicleMod(vehicleHandle, 8,  props.modFender,       false) end
    if props.modRightFender   then SetVehicleMod(vehicleHandle, 9,  props.modRightFender,  false) end
    if props.modRoof          then SetVehicleMod(vehicleHandle, 10, props.modRoof,         false) end
    if props.modEngine        then SetVehicleMod(vehicleHandle, 11, props.modEngine,       false) end
    if props.modBrakes        then SetVehicleMod(vehicleHandle, 12, props.modBrakes,       false) end
    if props.modTransmission  then SetVehicleMod(vehicleHandle, 13, props.modTransmission, false) end
    if props.modHorns         then SetVehicleMod(vehicleHandle, 14, props.modHorns,        false) end
    if props.modSuspension    then SetVehicleMod(vehicleHandle, 15, props.modSuspension,   false) end
    if props.modArmor         then SetVehicleMod(vehicleHandle, 16, props.modArmor,        false) end
    if props.modKit17         then SetVehicleMod(vehicleHandle, 17, props.modKit17,        false) end
    if props.modTurbo         then ToggleVehicleMod(vehicleHandle, 18, props.modTurbo) end
    if props.modKit19         then SetVehicleMod(vehicleHandle, 19, props.modKit19,        false) end
    if props.modSmokeEnabled  then ToggleVehicleMod(vehicleHandle, 20, props.modSmokeEnabled) end
    if props.modKit21         then SetVehicleMod(vehicleHandle, 21, props.modKit21,        false) end
    if props.modXenon         then ToggleVehicleMod(vehicleHandle, 22, props.modXenon) end
    if props.modFrontWheels   then SetVehicleMod(vehicleHandle, 23, props.modFrontWheels,  false) end
    if props.modBackWheels    then SetVehicleMod(vehicleHandle, 24, props.modBackWheels,   false) end

    -- Custom tyre variants (uses the wheel mod slot but passes the variation flag)
    if props.modCustomTiresF then
        SetVehicleMod(vehicleHandle, 23, props.modFrontWheels, props.modCustomTiresF)
    end
    if props.modCustomTiresR then
        SetVehicleMod(vehicleHandle, 24, props.modBackWheels,  props.modCustomTiresR)
    end

    if props.modPlateHolder   then SetVehicleMod(vehicleHandle, 25, props.modPlateHolder,   false) end
    if props.modVanityPlate   then SetVehicleMod(vehicleHandle, 26, props.modVanityPlate,   false) end
    if props.modTrimA         then SetVehicleMod(vehicleHandle, 27, props.modTrimA,         false) end
    if props.modOrnaments     then SetVehicleMod(vehicleHandle, 28, props.modOrnaments,     false) end
    if props.modDashboard     then SetVehicleMod(vehicleHandle, 29, props.modDashboard,     false) end
    if props.modDial          then SetVehicleMod(vehicleHandle, 30, props.modDial,          false) end
    if props.modDoorSpeaker   then SetVehicleMod(vehicleHandle, 31, props.modDoorSpeaker,   false) end
    if props.modSeats         then SetVehicleMod(vehicleHandle, 32, props.modSeats,         false) end
    if props.modSteeringWheel then SetVehicleMod(vehicleHandle, 33, props.modSteeringWheel, false) end
    if props.modShifterLeavers then SetVehicleMod(vehicleHandle, 34, props.modShifterLeavers, false) end
    if props.modAPlate        then SetVehicleMod(vehicleHandle, 35, props.modAPlate,        false) end
    if props.modSpeakers      then SetVehicleMod(vehicleHandle, 36, props.modSpeakers,      false) end
    if props.modTrunk         then SetVehicleMod(vehicleHandle, 37, props.modTrunk,         false) end
    if props.modHydrolic      then SetVehicleMod(vehicleHandle, 38, props.modHydrolic,      false) end
    if props.modEngineBlock   then SetVehicleMod(vehicleHandle, 39, props.modEngineBlock,   false) end
    if props.modAirFilter     then SetVehicleMod(vehicleHandle, 40, props.modAirFilter,     false) end
    if props.modStruts        then SetVehicleMod(vehicleHandle, 41, props.modStruts,        false) end
    if props.modArchCover     then SetVehicleMod(vehicleHandle, 42, props.modArchCover,     false) end
    if props.modAerials       then SetVehicleMod(vehicleHandle, 43, props.modAerials,       false) end
    if props.modTrimB         then SetVehicleMod(vehicleHandle, 44, props.modTrimB,         false) end
    if props.modTank          then SetVehicleMod(vehicleHandle, 45, props.modTank,          false) end
    if props.modWindows       then SetVehicleMod(vehicleHandle, 46, props.modWindows,       false) end
    if props.modKit47         then SetVehicleMod(vehicleHandle, 47, props.modKit47,         false) end

    -- Livery uses both SetVehicleMod slot 48 AND SetVehicleLivery
    if props.modLivery then
        SetVehicleMod(vehicleHandle, 48, props.modLivery, false)
        SetVehicleLivery(vehicleHandle, props.modLivery)
    end

    if props.modKit49  then SetVehicleMod(vehicleHandle, 49, props.modKit49, false) end
    if props.liveryRoof then SetVehicleRoofLivery(vehicleHandle, props.liveryRoof) end
end


-- =============================================================================
-- SECTION 8 – DEBUG COMMAND
-- =============================================================================

-- Toggle variable stored as an upvalue (not a global) so it persists between
-- command invocations without polluting the global namespace.
local isNuiFocused = false

-- /ra – toggles NUI cursor/focus on and off (useful for debugging NUI screens)
RegisterCommand("ra", function()
    isNuiFocused = not isNuiFocused
    if isNuiFocused then
        SetNuiFocus(1, 1)  -- enable cursor + input capture
    else
        SetNuiFocus(0, 0)  -- disable cursor + input capture
    end
end)


-- =============================================================================
-- SECTION 9 – ANIMATION / ASSET LOADING HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.A11SFUNCTION(animDict, callback)
-- Ensures an animation dictionary is loaded before running an optional
-- callback. Blocks (yields via Wait) until the dict is ready.
--
-- Note: the original obfuscated name was "A11SFUNCTION"; this is preserved
-- to maintain compatibility with any callers that reference it by name.
-- ----------------------------------------------------------------------------
function Resmon.Lib.A11SFUNCTION(animDict, callback)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end
    end
    -- Run the optional callback once the dict is loaded
    if callback ~= nil then
        callback()
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.LoadModel(modelHash)
-- Requests a model and yields until it is fully loaded into memory.
-- Safe to call when the model is already loaded (no-op).
-- ----------------------------------------------------------------------------
function Resmon.Lib.LoadModel(modelHash)
    if HasModelLoaded(modelHash) then return end
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.LoadWeaponAsset(weaponName)
-- Requests a weapon asset by name and yields until it is fully loaded.
-- Safe to call when the asset is already loaded (no-op).
-- ----------------------------------------------------------------------------
function Resmon.Lib.LoadWeaponAsset(weaponName)
    local weaponHash = GetHashKey(weaponName)
    if HasWeaponAssetLoaded(weaponHash) then return end
    RequestWeaponAsset(weaponHash, 31, 0)
    while not HasWeaponAssetLoaded(weaponHash) do
        Wait(10)
    end
end


-- =============================================================================
-- SECTION 10 – STRING / MATH UTILITIES
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Trim(str)
-- Removes leading and trailing whitespace from a string.
-- Returns nil if the input is nil/falsy.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Trim(str)
    if not str then return nil end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.FirstToUpper(str)
-- Capitalises the first character of a string.
-- Returns nil if the input is nil/falsy.
-- ----------------------------------------------------------------------------
function Resmon.Lib.FirstToUpper(str)
    if not str then return nil end
    return str:gsub("^%l", string.upper)
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Round(value, decimals)
-- Rounds 'value' to the given number of decimal places.
-- When 'decimals' is nil, rounds to the nearest integer.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Round(value, decimals)
    if not decimals then
        return math.floor(value + 0.5)
    end
    local multiplier = 10 ^ decimals
    return math.floor(value * multiplier + 0.5) / multiplier
end


-- =============================================================================
-- SECTION 11 – OBJECT / WORLD HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetClosestObjectsOfType(modelName, coords, radius)
-- Returns an array of all CObject entities whose model matches 'modelName'
-- within 'radius' units of 'coords'.
-- If 'coords' is nil, uses the local player ped's current position.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetClosestObjectsOfType(modelName, coords, radius)
    local localPed   = PlayerPedId()
    local allObjects = GetGamePool("CObject")
    local results    = {}

    -- Default search origin to the player's position
    if coords then
        if type(coords) == "table" then
            -- Convert plain {x,y,z} table to a vector3
            coords = vec3(coords.x, coords.y, coords.z) or coords
        end
    else
        coords = GetEntityCoords(localPed)
    end

    local targetHash = GetHashKey(modelName)

    for i = 1, #allObjects, 1 do
        local objCoords = GetEntityCoords(allObjects[i])
        local dist      = #(objCoords - coords)   -- vector length = distance
        if dist <= radius then
            local objModel = GetEntityModel(allObjects[i])
            if objModel == targetHash then
                table.insert(results, allObjects[i])
            end
        end
    end

    return results
end


-- =============================================================================
-- SECTION 12 – APARTMENT HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Apartment._0xcfpFED(modelName, coords, freeze)
-- Finds all nearby "v_ilev_garageliftdoor" objects within 3 units of 'coords'
-- and sets their freeze state to 'freeze' (true = frozen, false = dynamic).
-- The obfuscated name is preserved for backwards compatibility.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Apartment._0xcfpFED(modelName, coords, freeze)
    local nearbyDoors = Resmon.Lib.GetClosestObjectsOfType(
        "v_ilev_garageliftdoor",
        coords,
        3.0
    )
    for _, doorEntity in pairs(nearbyDoors) do
        FreezeEntityPosition(doorEntity, freeze)
    end
end


-- =============================================================================
-- SECTION 13 – CLOTHING URL HELPER (APARTMENT / PA-LIB INTEGRATION)
-- =============================================================================

-- ----------------------------------------------------------------------------
-- getUrlDataClient()
-- Asynchronously fetches the clothing URL from the "pa-lib-2" resource via
-- a server callback, waits up to 1 second, and returns the result.
-- Exposed as both a global function and a resource export.
-- ----------------------------------------------------------------------------
function getUrlDataClient()
    local p          = promise.new(promise)
    local clothingUrl = nil

    -- Fire the server callback; store the result when it arrives
    Resmon.Lib.Callback.Client("pa-lib-2:getClothingUrl", function(url)
        clothingUrl = url
    end)

    Citizen.Wait(1000)          -- give the server a moment to respond

    p:resolve(clothingUrl)
    return Citizen.Await(p)
end

exports("getUrlDataClient", getUrlDataClient)


-- =============================================================================
-- SECTION 14 – CRAFTING V2 HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Craft_V2.canOpenUI()
-- Always returns true. Override this function to add permission checks
-- (e.g. job or item requirements) before opening the crafting UI.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Craft_V2.canOpenUI()
    return true
end


-- ── Internal helper: converts a rotation vector to a forward direction vector
-- Used by createPreviewObject to place objects in front of the camera.
local function rotationToDirection(rotation)
    local zRad  = math.rad(rotation.z)
    local xRad  = math.rad(rotation.x)
    local cosX  = math.cos(xRad)
    local dirX  = -math.sin(zRad) * cosX
    local dirY  =  math.cos(zRad) * cosX
    local dirZ  =  math.sin(xRad)
    return vector3(dirX, dirY, dirZ)
end


-- ── Internal helper: spawns a static prop at a world position.
-- Used by createPreviewObject for non-weapon items.
local function spawnStaticObject(modelHash, position, rotation, frozen, networked, dynamic)
    if frozen    == nil then frozen    = true  end
    if networked == nil then networked = false end
    if dynamic   == nil then dynamic   = false end

    Resmon.Lib.LoadModel(modelHash)

    local obj = CreateObject(
        modelHash,
        position.x, position.y, position.z,
        networked, networked, dynamic
    )

    SetEntityCoords(obj, position.x, position.y, position.z,
                    false, false, false, true)

    if rotation then
        -- Accept a bare heading number or a full rotation vector
        if type(rotation) == "number" then
            rotation = vector3(0.0, 0.0, rotation)
        end
        SetEntityRotation(obj, rotation.x, rotation.y, rotation.z, 2, false)
    end

    FreezeEntityPosition(obj, frozen)
    SetModelAsNoLongerNeeded(modelHash)

    return obj
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Craft_V2.createPreviewObject(modelName, attachments, camera)
-- Creates a preview entity (weapon or prop) positioned slightly in front of
-- the given camera, for display in crafting / shop UIs.
--
-- Parameters:
--   modelName   – weapon name string (e.g. "WEAPON_PISTOL") or prop hash
--   attachments – array of attachment tables (each has .name / .hash fields)
--   camera      – camera handle used to derive position and rotation
--
-- Returns: true, entityHandle
-- ----------------------------------------------------------------------------
function Resmon.Lib.Craft_V2.createPreviewObject(modelName, attachments, camera)
    -- Calculate position 1.2 units in front of the camera
    local camCoords    = GetCamCoord(camera)
    local camRot       = GetCamRot(camera, 2)
    local camDirection = rotationToDirection(camRot)
    local spawnPos     = camCoords + camDirection * 1.2

    local previewEntity = nil

    -- Determine whether this is a weapon or a regular prop
    local nameLower  = modelName:lower()
    local namePrefix = nameLower:sub(0, 7)

    if namePrefix == "weapon_" then
        -- ── Weapon preview ────────────────────────────────────────────────
        Resmon.Lib.LoadWeaponAsset(modelName)

        local weaponModelHash = GetWeapontypeModel(modelName)
        Resmon.Lib.LoadModel(weaponModelHash)

        -- Spawn the weapon object just above the target position
        local weaponObj = CreateWeaponObject(
            modelName, 0,
            spawnPos.x, spawnPos.y, spawnPos.z + 0.1,
            true, 1.3, 0
        )

        -- Wait until the entity exists before continuing
        while not DoesEntityExist(weaponObj) do
            Wait(0)
        end

        -- Hide during setup, then align to face the camera
        SetEntityAlpha(weaponObj, 0)
        SetEntityRotation(
            weaponObj,
            0.0, 0.0,
            (camRot.z + 180.0) % 360.0
        )

        previewEntity = weaponObj

        -- ── Apply attachments ─────────────────────────────────────────────
        local skinAttachment = nil

        for _, attachment in ipairs(attachments) do
            if attachment.name == "skin" then
                -- Skin tint handled separately below
                skinAttachment = attachment
            else
                -- Resolve the component hash (string → hash key if needed)
                local componentHash = attachment.hash
                if type(componentHash) == "string" then
                    local resolved = GetHashKey(componentHash)
                    if resolved then
                        componentHash = resolved
                    end
                end

                local componentModelHash = GetWeaponComponentTypeModel(componentHash)
                Resmon.Lib.LoadModel(componentModelHash)
                GiveWeaponComponentToWeaponObject(weaponObj, componentHash)
                SetModelAsNoLongerNeeded(componentModelHash)
            end
        end

        -- Apply skin tint if a skin attachment was present
        if skinAttachment then
            SetWeaponObjectTintIndex(weaponObj, 2)
        end

        -- Make the weapon visible now that setup is complete
        SetEntityAlpha(weaponObj, 255)

        -- Clean up assets
        RemoveWeaponAsset(modelName)
        SetModelAsNoLongerNeeded(weaponModelHash)
    else
        -- ── Prop / object preview ─────────────────────────────────────────
        local obj = spawnStaticObject(
            modelName, spawnPos, nil,
            true, false, false
        )
        previewEntity = obj
    end

    return true, previewEntity
end


-- =============================================================================
-- SECTION 15 – CRAFTING V1: LoadPropOnTable
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Craft.LoadPropOnTable(modelHash, x, y, z, propType)
-- Spawns a preview prop on a crafting table.
-- When propType == "weapon", uses CreateWeaponObject with a slight Z offset
-- and a 1.3 scale; otherwise creates a regular static object.
--
-- Returns: entity handle of the spawned object.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Craft.LoadPropOnTable(modelHash, x, y, z, propType)
    local spawnedEntity = nil
    local offsetVec     = vector3(0.0, 0.0, 30.0)  -- unused offset vector

    if propType == "weapon" then
        Resmon.Lib.LoadWeaponAsset(modelHash)
        local entity = CreateWeaponObject(
            modelHash, 0,
            x, y, z,
            true, 1.3, 0
        )
        spawnedEntity = entity
    else
        Resmon.Lib.LoadModel(modelHash)
        local entity = CreateObject(
            modelHash, x, y, z,
            false, false, false
        )
        spawnedEntity = entity
    end

    SetModelAsNoLongerNeeded(modelHash)
    return spawnedEntity
end


-- =============================================================================
-- SECTION 16 – NUI CALLBACKS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- NUI Callback: "hasillegalpacklicense"
-- Called from the front-end to check whether the player has an illegal-pack
-- licence. Always returns true (no server-side check performed here).
-- ----------------------------------------------------------------------------
RegisterNUICallback("hasillegalpacklicense", function(data, callback)
    callback(true)
end)


-- ----------------------------------------------------------------------------
-- NUI Callback: "haslicense"
-- Called from the front-end to check whether the player holds a general
-- licence. Always returns true (no server-side check performed here).
-- ----------------------------------------------------------------------------
RegisterNUICallback("haslicense", function(data, callback)
    callback(true)
end)
