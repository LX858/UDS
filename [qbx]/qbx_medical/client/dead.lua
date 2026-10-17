local config = require 'config.client'
local sharedConfig = require 'config.shared'
local WEAPONS = exports.qbx_core:GetWeapons()
local allowRespawn = true
local lastResurrectTime = 0 -- Cooldown để tránh spam resurrect
local isProcessingDeath = false -- Flag để tránh trigger nhiều lần

local function logPlayerKiller()
    local killer_2, killerWeapon = NetworkGetEntityKillerOfPlayer(cache.playerId)
    local killer = GetPedSourceOfDeath(cache.ped)

    if killer_2 ~= 0 and killer_2 ~= -1 then
        killer = killer_2
    end

    local killerId = NetworkGetPlayerIndexFromPed(killer)
    local killerName = killerId ~= -1 and (' %s (%d)'):format(GetPlayerName(killerId), GetPlayerServerId(killerId)) or locale('info.self_death')
    local weaponItem = WEAPONS[killerWeapon]
    local weaponLabel = locale('info.wep_unknown') or (weaponItem and weaponItem.label)
    local weaponName = locale('info.wep_unknown') or (weaponItem and weaponItem.name)
    local message = locale('logs.death_log_message', killerName, GetPlayerName(cache.playerId), weaponLabel, weaponName)

    lib.callback.await('qbx_medical:server:log', false, 'LOG KILL', message)
end

local function playDeadAnimation()
    if IsEntityAttached(cache.ped) then return end

    local deadAnimDict = 'dead'
    local deadAnim = not QBX.PlayerData.metadata.ishandcuffed and 'dead_a' or 'dead_f'
    local deadVehAnimDict = 'veh@low@front_ps@idle_duck'
    local deadVehAnim = 'sit'

    if cache.vehicle then
        if not IsEntityPlayingAnim(cache.ped, deadVehAnimDict, deadVehAnim, 3) then
            lib.playAnim(cache.ped, deadVehAnimDict, deadVehAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    elseif not IsEntityPlayingAnim(cache.ped, deadAnimDict, deadAnim, 3) then
        lib.playAnim(cache.ped, deadAnimDict, deadAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
    end
end

exports('PlayDeadAnimation', playDeadAnimation)

---put player in death animation and make invincible
function OnDeath(attacker, weapon)
    SetDeathState(sharedConfig.deathState.DEAD)
    TriggerEvent('qbx_medical:client:onPlayerDied', attacker, weapon)

    -- Convert attacker ped to source server ID
    local attackerSource = nil
    if attacker and attacker ~= 0 and attacker ~= cache.ped then
        local attackerPlayerId = NetworkGetPlayerIndexFromPed(attacker)
        if attackerPlayerId and attackerPlayerId ~= -1 then
            attackerSource = GetPlayerServerId(attackerPlayerId)
        end
    end

    TriggerServerEvent('qbx_medical:server:onPlayerDied', attackerSource, weapon)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'demo', 0.1)
    TriggerEvent('ox_inventory:disarm', cache.playerId, true) 
    WaitForPlayerToStopMoving()

    CreateThread(function()
        while DeathState == sharedConfig.deathState.DEAD do
            DisableControls()
            playDeadAnimation()
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            LocalPlayer.state.invBusy = true
            Wait(0)
        end
    end)
    LocalPlayer.state.invBusy = true

    ResurrectPlayer()
    playDeadAnimation()
    SetEntityInvincible(cache.ped, true)
    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    if not exports.qbx_medical:IsInRedZone() then
        SendNUIMessage({ action = 'res' })
    end
    CheckForRespawn()
end

exports('KillPlayer', OnDeath)

local function respawn()
    local success = lib.callback.await('qbx_medical:server:respawn')
    if not success then return end
    if QBX.PlayerData.metadata.ishandcuffed then
        TriggerEvent('police:client:GetCuffed', -1)
    end
    TriggerEvent('police:client:DeEscort')
    LocalPlayer.state.invBusy = false
end

---Allow player to respawn
function CheckForRespawn()
    while DeathState == sharedConfig.deathState.DEAD do
        Wait(1000)
        local inRedZone = exports.qbx_medical:IsInRedZone()
        if not inRedZone then
            if DeathTime > 0 then
                DeathTime -= 1
                if DeathTime <= 0 and allowRespawn then
                    respawn()
                    return
                end
            end
        end
    end
end

function AllowRespawn()
    allowRespawn = true
end

exports('AllowRespawn', AllowRespawn)

exports('DisableRespawn', function()
    allowRespawn = false
end)

---when player is killed by another player, set last stand mode, or if already in last stand mode, set player to dead mode.
---@param event string
---@param data table
AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
    if not IsEntityAPed(victim) or not victimDied or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId or not IsEntityDead(cache.ped) then return end

    -- Nếu đang xử lý death thì bỏ qua
    if isProcessingDeath then
        return
    end

    isProcessingDeath = true

    if DeathState == sharedConfig.deathState.ALIVE then
        -- Lần ngất đầu tiên: chuyển sang LAST_STAND
        SetDeathState(sharedConfig.deathState.LAST_STAND)
        Wait(1000)
        StartLastStand(attacker, weapon)
    elseif DeathState == sharedConfig.deathState.LAST_STAND then
        -- Bị tấn công khi đang ngất: chuyển sang DEAD
        exports.qbx_core:Notify(locale('error.bled_out'), 'error')
        EndLastStand()
        logPlayerKiller()
        DeathTime = config.deathTime
        OnDeath(attacker, weapon)
    end

    isProcessingDeath = false
end)

function DisableControls()
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 38, true)
    EnableControlAction(0, 0, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 288, true)
    EnableControlAction(0, 213, true)
    EnableControlAction(0, 74, true) -- Enable Key H for Red Zone hospital respawn
    -- EnableControlAction(0, 249, true) -- Disable Push-to-Talk (N) while dead/laststand
    -- EnableControlAction(0, 46, true) -- Disable Talk (E) while dead/laststand
    EnableControlAction(0, 47, true)
end