local config = require 'config.client'
local sharedConfig = require 'config.shared'

-- Cooldown tracking per player citizenid
local playerRedZoneCooldowns = {}
local markedPlayersInZone = {}

-- Helper to set cooldown for a player
local function setPlayerCooldown(src, zoneId, expiryTimestamp)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    if not playerRedZoneCooldowns[citizenid] then
        playerRedZoneCooldowns[citizenid] = {}
    end

    playerRedZoneCooldowns[citizenid][zoneId] = expiryTimestamp
    TriggerClientEvent('qbx_medical:client:syncRedZoneCooldowns', src, playerRedZoneCooldowns[citizenid])

    if lib and lib.logger then
        lib.logger(src, 'setRedZoneCooldown', string.format('Player %s (%s) set cooldown for %s until %s', GetPlayerName(src), citizenid, zoneId, os.date('%Y-%m-%d %H:%M:%S', expiryTimestamp)))
    end
end

-- Sync cooldowns on player load
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    if playerRedZoneCooldowns[citizenid] then
        TriggerClientEvent('qbx_medical:client:syncRedZoneCooldowns', src, playerRedZoneCooldowns[citizenid])
    end
end)

-- Mark player as downed/dead inside Red Zone
RegisterNetEvent('qbx_medical:server:markPlayerInRedZone', function(zoneId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    if not markedPlayersInZone[citizenid] then
        markedPlayersInZone[citizenid] = {}
    end
    markedPlayersInZone[citizenid][zoneId] = true
end)

-- Set Red Zone cooldown for a player from client
RegisterNetEvent('qbx_medical:server:setRedZoneCooldown', function(zoneId, expiryTimestamp)
    local src = source
    setPlayerCooldown(src, zoneId, expiryTimestamp)
end)

local function removeMedkitItem(src)
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search(src, 'count', 'medkit_che')
        if not count or count < 1 then return false end
        return exports.ox_inventory:RemoveItem(src, 'medkit_che', 1)
    else
        local player = exports.qbx_core:GetPlayer(src)
        if player and player.Functions.GetItemByName('medkit_che') then
            return player.Functions.RemoveItem('medkit_che', 1)
        end
    end
    return false
end

-- Revive Target in Red Zone (Rescuer finishes minigame & progressbar)
RegisterNetEvent('qbx_medical:server:redZoneReviveTarget', function(targetId)
    local src = source
    local rescuer = exports.qbx_core:GetPlayer(src)
    local target = exports.qbx_core:GetPlayer(targetId)

    if not rescuer or not target then return end

    local rescuerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)

    if not rescuerPed or not targetPed then return end

    -- Check distance between rescuer and target (server-side check)
    local rescuerCoords = GetEntityCoords(rescuerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local dist = #(rescuerCoords - targetCoords)

    if dist > 5.0 then
        exports.qbx_core:Notify(src, 'Khoảng cách quá xa để cứu!', 'error')
        return
    end

    -- Remove 1 medkit_che item from rescuer inventory
    local removed = removeMedkitItem(src)
    if not removed then
        exports.qbx_core:Notify(src, 'Bạn cần phải có 1 Hộp Sơ Cứu (medkit_che) trong túi đồ để cứu người!', 'error')
        return
    end

    -- Revive target
    exports.qbx_medical:Revive(targetId)

    exports.qbx_core:Notify(src, string.format('Bạn đã dùng 1 Medkit để cứu sống %s thành công!', GetPlayerName(targetId)), 'success')
    exports.qbx_core:Notify(targetId, string.format('Bạn đã được %s cứu sống!', GetPlayerName(src)), 'success')

    -- Log rescue event
    if lib and lib.logger then
        lib.logger(src, 'redZoneRevive', string.format('Rescuer %s (%s) used 1 medkit_che to revive target %s (%s) in Red Zone', GetPlayerName(src), src, GetPlayerName(targetId), targetId))
    end
end)

-- Hospital Respawn from Red Zone (Hold H for 3s when DEAD)
RegisterNetEvent('qbx_medical:server:redZoneHospitalRespawn', function(zoneId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    -- Find zone configuration
    local hospitalCoords = config.respawnLocation
    local hospitalHeading = config.respawnHeading or 0.0
    local cdMinutes = config.redZoneDefaultCooldown or 2

    if config.redZones and zoneId then
        for _, rz in ipairs(config.redZones) do
            if rz.id == zoneId then
                if rz.hospitalCoords then hospitalCoords = rz.hospitalCoords end
                if rz.hospitalHeading then hospitalHeading = rz.hospitalHeading end
                if rz.cooldownMinutes then cdMinutes = rz.cooldownMinutes end
                break
            end
        end
    end

    -- Apply cooldown for this zone
    if zoneId then
        local expiryTime = os.time() + (cdMinutes * 60)
        setPlayerCooldown(src, zoneId, expiryTime)
    end

    -- -- Revive player
    -- exports.qbx_medical:Revive(src)

    -- Teleport ped to hospital coordinates
    SetEntityCoords(ped, hospitalCoords.x, hospitalCoords.y, hospitalCoords.z, false, false, false, true)
    SetEntityHeading(ped, hospitalHeading)
    TriggerClientEvent('qbx_medical:client:teleportToHospital', src, hospitalCoords, hospitalHeading)

    exports.qbx_core:Notify(src, 'Bạn đã về bệnh viện từ vùng đỏ thành công.', 'success')

    -- Log hospital respawn event with lib.logger
    if lib and lib.logger then
        lib.logger(src, 'redZoneHospitalRespawn', string.format('Player %s (%s, CitizenId: %s) respawned to hospital from Red Zone %s', GetPlayerName(src), src, player.PlayerData.citizenid, zoneId or 'unknown'))
    else
        print(string.format('[qbx_medical] Red Zone Hospital Respawn: Player %s (%s) from zone %s', GetPlayerName(src), src, zoneId or 'unknown'))
    end
end)
