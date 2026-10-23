local config = require 'config.client'
local sharedConfig = require 'config.shared'

---@type table<number, boolean> weapon hashes as a set
WeaponsThatDamagedPlayer = {}

NumInjuries = 0

local playerState = LocalPlayer.state

---@type table<BodyPartKey, Injury>
Injuries = {}

for bodyPartKey in pairs(sharedConfig.bodyParts) do
    local bodyPartStateBag = BODY_PART_STATE_BAG_PREFIX .. bodyPartKey
    Injuries[bodyPartKey] = playerState[bodyPartStateBag]
    AddStateBagChangeHandler(bodyPartStateBag, ('player:%s'):format(cache.serverId), function(_, _, value)
        Injuries[bodyPartKey] = value
    end)
end

function SetInjury(bodyPartKey, severity)
    playerState:set(BODY_PART_STATE_BAG_PREFIX .. bodyPartKey, severity, true)
end

BleedLevel = playerState[BLEED_LEVEL_STATE_BAG] or 0

AddStateBagChangeHandler(BLEED_LEVEL_STATE_BAG, ('player:%s'):format(cache.serverId), function(_, _, value)
    BleedLevel = value
end)

function SetBleedLevel(level)
    playerState:set(BLEED_LEVEL_STATE_BAG, level, true)
end

DeathState = playerState[DEATH_STATE_STATE_BAG] or sharedConfig.deathState.ALIVE

AddStateBagChangeHandler(DEATH_STATE_STATE_BAG, ('player:%s'):format(cache.serverId), function(_, _, value)
    DeathState = value
end)

function SetDeathState(deathState)
    playerState:set(DEATH_STATE_STATE_BAG, deathState, true)
    DeathState = deathState
end

BleedTickTimer, AdvanceBleedTimer = 0, 0
FadeOutTimer, BlackoutTimer = 0, 0

---@type number
Hp = nil

DeathTime = 0
LaststandTime = 0
RespawnHoldTime = 5
LastStandDict = 'combat@damage@writhe'
LastStandAnim = 'writhe_loop'

exports('IsDead', function()
    return DeathState == sharedConfig.deathState.DEAD
end)

exports('IsLaststand', function()
    return DeathState == sharedConfig.deathState.LAST_STAND
end)

exports('GetDeathTime', function()
    return DeathTime
end)

exports('GetLaststandTime', function()
    return LaststandTime
end)

exports('IncrementDeathTime', function(seconds)
    DeathTime += seconds
end)

exports('IncrementLaststandTime', function(seconds)
    LaststandTime += seconds
end)

exports('GetRespawnHoldTimeDeprecated', function()
    return RespawnHoldTime
end)

lib.callback.register('qbx_medical:client:killPlayer', function()
    SetEntityHealth(cache.ped, 0)
end)

-- Event để đồng bộ dữ liệu y tế từ server khi cần
RegisterNetEvent('qbx_medical:client:syncMedicalData', function()
    --print("^2[qbx_medical:client] Requesting medical data sync from server^7")
    -- Request server sync dữ liệu từ metadata vào StateBags
    TriggerServerEvent('qbx_medical:server:requestDataSync')
end)

-- Tự động sync khi spawn
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    --print("^2[qbx_medical:client] Player loaded, waiting 3 seconds before sync^7")
    Wait(3000) -- Đợi lâu hơn để đảm bảo server đã load xong
    TriggerEvent('qbx_medical:client:syncMedicalData')
end)

-- Thêm handler khi spawn
AddEventHandler('QBCore:Client:OnPlayerSpawn', function()
    --print("^2[qbx_medical:client] Player spawned, requesting medical data sync^7")
    Wait(2000)
    TriggerEvent('qbx_medical:client:syncMedicalData')
end)

---@return boolean isInjuryCausingLimp if injury causes a limp and is damaged.
local function isInjuryCausingLimp()
    for bodyPartKey in pairs(Injuries) do
        if sharedConfig.bodyParts[bodyPartKey].causeLimp then
            return true
        end
    end
    return false
end

---notify the player of damage to their body.
local function doLimbAlert()
    if DeathState ~= sharedConfig.deathState.ALIVE or NumInjuries == 0 then return end

    local limbDamageMsg = ''
    if NumInjuries <= config.alertShowInfo then
        local i = 0
        for bodyPartKey, injury in pairs(Injuries) do
            local bodyPart = sharedConfig.bodyParts[bodyPartKey]
            limbDamageMsg = limbDamageMsg .. locale('info.pain_message', bodyPart.label, sharedConfig.woundLevels[injury.severity].label)
            i += 1
            if i < NumInjuries then
                limbDamageMsg = limbDamageMsg .. ' | '
            end
        end
    else
        limbDamageMsg = locale('info.many_places')
    end
    exports.qbx_core:Notify(limbDamageMsg, 'error')
end

---sets ped animation to limping and prevents running.
function MakePedLimp()
    if not isInjuryCausingLimp() then return end
    lib.requestAnimSet('move_m@injured', 5000)
    SetPedMovementClipset(cache.ped, 'move_m@injured', 1)
    SetPlayerSprint(cache.playerId, false)
end

--- TODO: this export should not check any conditions, but force the ped to limp instead.
exports('MakePedLimp', MakePedLimp)

local function resetMinorInjuries()
    for bodyPartKey, injury in pairs(Injuries) do
        if injury.severity <= 2 then
            SetInjury(bodyPartKey, nil)
            NumInjuries -= 1
        end
    end

    if BleedLevel <= 2 then
        SetBleedLevel(0)
        BleedTickTimer = 0
        AdvanceBleedTimer = 0
        FadeOutTimer = 0
        BlackoutTimer = 0
    end

    SendBleedAlert()
    MakePedLimp()
    doLimbAlert()
end

local function resetAllInjuries(disableStatus)
    for bodyPartKey in pairs(sharedConfig.bodyParts) do
        SetInjury(bodyPartKey, nil)
    end
    NumInjuries = 0
    SetBleedLevel(0)
    BleedTickTimer = 0
    AdvanceBleedTimer = 0
    FadeOutTimer = 0
    BlackoutTimer = 0

    WeaponsThatDamagedPlayer = {}

    SendBleedAlert()
    MakePedLimp()
    doLimbAlert()
    if disableStatus then return end
    lib.callback.await('qbx_medical:server:resetHungerAndThirst')
end

---notify the player of bleeding to their body.
function SendBleedAlert()
    if DeathState == sharedConfig.deathState.DEAD or BleedLevel == 0 then return end
    exports.qbx_core:Notify(locale('info.bleed_alert', sharedConfig.bleedingStates[BleedLevel]), 'inform')
end

exports('SendBleedAlert', SendBleedAlert)

---adds a bleed to the player and alerts them. Total bleed level maxes at 4.
---@param level 1|2|3|4 speed of the bleed
function ApplyBleed(level)
    if BleedLevel == 4 then return end
    local newBleedLevel = level + BleedLevel
    if newBleedLevel > 4 then
        SetBleedLevel(4)
    else
        SetBleedLevel(newBleedLevel)
    end
    SendBleedAlert()
end

---heals player wounds.
---@param type? 'full'|any heals all wounds if full otherwise heals only major wounds.
RegisterNetEvent('qbx_medical:client:heal', function(type)
    if type == 'full' then
        resetAllInjuries()
    else
        resetMinorInjuries()
    end

    exports.qbx_core:Notify(locale('success.wounds_healed'), 'success')
end)

CreateThread(function()
    while true do
        Wait((1000 * config.messageTimer))
        doLimbAlert()
    end
end)

---Revives player, healing all injuries
RegisterNetEvent('qbx_medical:client:playerRevived', function(disableStatus)
    -- Set DeathState = ALIVE TRƯỚC để dừng TẤT CẢ threads check DeathState
    SetDeathState(sharedConfig.deathState.ALIVE)

    -- Wait để đảm bảo cả 2 threads (dead.lua và death-ui.lua) đều dừng
    Wait(300)

    if cache.ped then
        local pos = GetEntityCoords(cache.ped, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(cache.ped), true, false)
        SetEntityInvincible(cache.ped, false)
    end

    EndLastStand()
    TriggerEvent('qbx_medical:client:onPlayerRevived')

    -- Hide death UI sau khi đã set DeathState = ALIVE
    exports.qbx_medical:HideDeathUI()
    
    -- Force tắt blur thêm lần nữa để chắc chắn
    TriggerScreenblurFadeOut(500)
    Wait(100)
    TriggerScreenblurFadeOut(500)

    -- Wait thêm và force unlock inventory nhiều lần
    Wait(100)
    LocalPlayer.state.invBusy = false
    Wait(50)
    LocalPlayer.state.invBusy = false

    SetEntityMaxHealth(cache.ped, 200)
    SetEntityHealth(cache.ped, 200)
    ClearPedBloodDamage(cache.ped)
    SetPlayerSprint(cache.playerId, true)
    resetAllInjuries(disableStatus)
    ResetPedMovementClipset(cache.ped, 0.0)

    -- Fix collision và states sau khi revive
    -- Wait(100)

    -- SetEntityCollision(cache.ped, true, true)
    -- SetEntityInvincible(cache.ped, false)
    -- SetEntityCanBeDamaged(cache.ped, true)
    -- SetPedCanRagdoll(cache.ped, true)
    -- SetPedConfigFlag(cache.ped, 281, false)
    -- SetEntityProofs(cache.ped, false, false, false, false, false, false, false, false)
    -- ClearPedTasksImmediately(cache.ped)
    -- ResetEntityAlpha(cache.ped)
    -- SetEveryoneIgnorePlayer(cache.playerId, false)
    -- SetPoliceIgnorePlayer(cache.playerId, false)
    -- SetEntityVisible(cache.ped, true, false)
    -- NetworkSetEntityInvisibleToNetwork(cache.ped, false)

    -- FreezeEntityPosition(cache.ped, true)
    -- Wait(50)
    -- FreezeEntityPosition(cache.ped, false)

    --TriggerServerEvent('hud:server:RelieveStress', 100)
    -- player.Functions.SetMetaData('hunger', 100)
	-- player.Functions.SetMetaData('thirst', 100)
    exports.qbx_core:Notify(locale('info.healthy'), 'info')
    LocalPlayer.state.invBusy = false

    -- Thông báo server xóa đơn ping (nếu có)
    -- RegisterNetEvent('qbx_medical:server:onPlayerRevived', function(playerId)
-- 	local src = playerId or source
-- 	-- Trigger event để xn_Pingjob xóa đơn của player này
-- 	TriggerEvent('xn_pingjob:autoDeleteServiceOnRevive', src)
    TriggerServerEvent('xn_pingjob:autoDeleteServiceOnRevive', cache.serverId)
end)

RegisterNetEvent('qbx_medical:client:painkillers', function()
    if DeathState ~= sharedConfig.deathState.ALIVE then
        local pos = GetEntityCoords(cache.ped, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(cache.ped), true, false)
        SetEntityInvincible(cache.ped, false)
        EndLastStand()
    end
    ClearPedBloodDamage(cache.ped)
    SetPlayerSprint(cache.playerId, true)
    resetAllInjuries()
    ResetPedMovementClipset(cache.ped, 0.0)

    -- Fix collision và states
    SetEntityCollision(cache.ped, true, true)
    SetEntityInvincible(cache.ped, false)
    SetEntityCanBeDamaged(cache.ped, true)
    SetPedCanRagdoll(cache.ped, true)
    SetPedConfigFlag(cache.ped, 281, false)
    ResetEntityAlpha(cache.ped)
    SetEntityVisible(cache.ped, true, false)

    exports.qbx_core:Notify(locale('info.healthy'), 'info')
    LocalPlayer.state.invBusy = false
end)