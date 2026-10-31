

Oxlyn = Oxlyn or {}

local RemoveDecalsInRange   = RemoveDecalsInRange
local ClearAllBrokenGlass   = ClearAllBrokenGlass
local ClearAreaOfProjectiles = ClearAreaOfProjectiles

-- Running totals and last-run info
Oxlyn.Cleanup = {
    lastRun    = 0,
    totalPeds  = 0,
    totalVehs  = 0,
    totalObjs  = 0,
    totalProj  = 0,
    lastResult = nil,
}
local Cleanup = Oxlyn.Cleanup

---------------------------------------------------------------------
-- Protected models (never deleted)
---------------------------------------------------------------------

local protectedModels = {}   -- set of model hashes

CreateThread(function()
    for _, model in ipairs(Config.CleanupSafety.protectedModels or {}) do
        local hash = type(model) == "string" and GetHashKey(model) or model
        protectedModels[hash] = true
    end
end)

local function isProtectedModel(entity)
    return protectedModels[GetEntityModel(entity)] == true
end

---------------------------------------------------------------------
-- Safety checks
---------------------------------------------------------------------

-- Whether an entity is safe to delete.
local function canDelete(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false
    end
    if IsEntityAttached(entity) then return false end
    if IsEntityAMissionEntity(entity) then return false end
    if isProtectedModel(entity) then return false end

    -- Networked entities we don't control belong to someone else
    if NetworkGetEntityIsNetworked(entity) and not NetworkHasControlOfEntity(entity) then
        return false
    end

    return true
end

-- True if the entity is farther than minDist and closer than maxDist from center.
local function isInRange(entity, center, minDist, maxDist)
    local dist = #(GetEntityCoords(entity) - center)
    return minDist < dist and maxDist > dist
end

local function deleteEntity(entity)
    if not DoesEntityExist(entity) then return false end

    SetEntityAsMissionEntity(entity, true, true)
    if IsEntityAVehicle(entity) then
        DeleteVehicle(entity)
    else
        DeleteEntity(entity)
    end

    return not DoesEntityExist(entity)
end

local function isVehicleEmpty(vehicle)
    if not IsVehicleSeatFree(vehicle, -1) then
        return false
    end

    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle) or 0
    for seat = 0, maxPassengers - 1 do
        if not IsVehicleSeatFree(vehicle, seat) then
            return false
        end
    end

    return true
end

---------------------------------------------------------------------
-- Cleanup passes (each returns the number of entities deleted)
---------------------------------------------------------------------

local function cleanDeadPeds(center, minDist, maxDist, limit)
    local count = 0

    for _, ped in ipairs(GetGamePool("CPed")) do
        if count >= limit then break end

        if not IsPedAPlayer(ped)
            and IsPedDeadOrDying(ped, true)
            and canDelete(ped)
            and isInRange(ped, center, minDist, maxDist)
            and not IsPedInAnyVehicle(ped, true)
            and deleteEntity(ped) then
            count = count + 1
        end
    end

    return count
end

local function cleanEmptyVehicles(center, minDist, maxDist, limit)
    local count = 0
    local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), true)

    for _, vehicle in ipairs(GetGamePool("CVehicle")) do
        if count >= limit then break end

        if vehicle ~= playerVehicle
            and isVehicleEmpty(vehicle)
            and canDelete(vehicle)
            and isInRange(vehicle, center, minDist, maxDist) then

            local ownedByPlayer = false
            if IsVehiclePreviouslyOwnedByPlayer then
                ownedByPlayer = IsVehiclePreviouslyOwnedByPlayer(vehicle)
            end

            if not ownedByPlayer and deleteEntity(vehicle) then
                count = count + 1
            end
        end
    end

    return count
end

-- Only non-networked objects are touched.
local function cleanObjects(center, minDist, maxDist, limit)
    local count = 0

    for _, object in ipairs(GetGamePool("CObject")) do
        if count >= limit then break end

        if not NetworkGetEntityIsNetworked(object)
            and canDelete(object)
            and isInRange(object, center, minDist, maxDist)
            and deleteEntity(object) then
            count = count + 1
        end
    end

    return count
end

---------------------------------------------------------------------
-- Main entry point
---------------------------------------------------------------------

-- force = true runs even when cleanup is disabled and reads raw (non-effective) settings.
function Oxlyn.RunCleanup(force)
    if not Oxlyn.Get("cleanupEnabled") and not force then
        return nil
    end

    local getSetting = force and Oxlyn.Get or Oxlyn.Eff

    local center = GetEntityCoords(PlayerPedId())
    local radius = getSetting("cleanupRadius") or 400
    local minDistance = Config.CleanupSafety.minDistance or 45.0
    local maxPerPass  = Config.CleanupSafety.maxPerPass or 40

    local result = {
        peds        = 0,
        vehicles    = 0,
        objects     = 0,
        projectiles = 0,
        decals      = false,
        glass       = false,
    }

    if getSetting("clearProjectiles") and ClearAreaOfProjectiles then
        ClearAreaOfProjectiles(center.x, center.y, center.z, radius + 0.0, false)
        result.projectiles = 1
    end

    if getSetting("clearGlass") and ClearAllBrokenGlass then
        ClearAllBrokenGlass()
        result.glass = true
    end

    if getSetting("clearDecals") and RemoveDecalsInRange then
        RemoveDecalsInRange(center.x, center.y, center.z, radius + 0.0)
        result.decals = true
    end

    if getSetting("clearDeadPeds") then
        result.peds = cleanDeadPeds(center, minDistance, radius, maxPerPass)
        Wait(0)
    end

    if getSetting("clearEmptyVehicles") then
        result.vehicles = cleanEmptyVehicles(center, minDistance, radius, maxPerPass)
        Wait(0)
    end

    if getSetting("clearObjects") then
        result.objects = cleanObjects(center, minDistance, radius, maxPerPass)
    end

    Cleanup.totalPeds = Cleanup.totalPeds + result.peds
    Cleanup.totalVehs = Cleanup.totalVehs + result.vehicles
    Cleanup.totalObjs = Cleanup.totalObjs + result.objects
    Cleanup.totalProj = Cleanup.totalProj + result.projectiles
    Cleanup.lastRun    = GetGameTimer()
    Cleanup.lastResult = result

    Oxlyn.Debug(("limpeza: %d peds, %d veiculos, %d objectos"):format(
        result.peds, result.vehicles, result.objects
    ))

    return result
end

---------------------------------------------------------------------
-- Scheduler
---------------------------------------------------------------------

CreateThread(function()
    Wait(15000)
    local nextRun = GetGameTimer()

    while true do
        if Oxlyn.Get("cleanupEnabled") then
            local now = GetGameTimer()

            if nextRun <= now then
                local ped = PlayerPedId()

                -- Don't run while the player is fighting
                if not IsPedInMeleeCombat(ped) and not IsPedShooting(ped) then
                    Oxlyn.RunCleanup(false)
                    local intervalSeconds = Oxlyn.Eff("cleanupInterval") or 120
                    nextRun = GetGameTimer() + intervalSeconds * 1000
                end
            end

            Wait(2000)
        else
            nextRun = GetGameTimer()
            Wait(5000)
        end
    end
end)

---------------------------------------------------------------------
-- Stats
---------------------------------------------------------------------

function Oxlyn.CleanupStats()
    return {
        peds        = Cleanup.totalPeds,
        vehicles    = Cleanup.totalVehs,
        objects     = Cleanup.totalObjs,
        projectiles = Cleanup.totalProj,
        lastRunAgo  = Cleanup.lastRun > 0
            and math.floor((GetGameTimer() - Cleanup.lastRun) / 1000)
            or -1,
        last        = Cleanup.lastResult,
    }
end

