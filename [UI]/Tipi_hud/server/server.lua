-- Restart flag: dùng convar thay vì file JSON, tồn tại qua resource restart.
local RESTART_CONVAR = 'tipi_hud_restarted'

lib.callback.register('tipi-hud:getInformation', function(src)
    local Player = getPlayer(src)

    if Player then
        local identifier = Player.identifier or Player.PlayerData.citizenid
        local job = getJob(Player)
        local grade = job.grade_label or job.grade.name

        return {
            online = GetNumPlayerIndices(),
            ping = GetPlayerPing(src),
            job = job.label .. " " .. grade,
            name = getName(identifier, Player) .. " (" .. src .. ")",
            cash = getMoney(Player, 'cash'),
            bank = getMoney(Player, 'bank'),
        }
    else
        return false
    end
end)

Citizen.CreateThread(function()
    Wait(10000)
    while true do
        local players = GetPlayers()
        local online = #players
        for i, id in ipairs(players) do
            local src = tonumber(id)
            WS.TriggerClientEvent('tipi-hud:refreshPing', src, {
                ping = GetPlayerPing(src), online = online
            })
            if i % 32 == 0 then Wait(0) end
        end
        Citizen.Wait(10000)
    end
end)

-- ─── Stress helpers ───────────────────────────────────────────────────────────

local function setStress(src, newVal)
    newVal = tonumber(newVal) or 0
    if newVal < 0 then newVal = 0 end
    if newVal > 100 then newVal = 100 end

    -- Đồng bộ qua StateBag server
    local playerState = Player(src).state
    if playerState and playerState.stress ~= newVal then
        playerState:set('stress', newVal, true)
    end

    -- Đồng bộ cho qbx_core
    local updated = false
    if GetResourceState('qbx_core') == 'started' then
        updated = pcall(function()
            exports.qbx_core:SetPlayerMetadata(src, 'stress', newVal)
        end)
    end

    if not updated then
        local player = getPlayer(src)
        if player and player.Functions and player.Functions.SetMetaData then
            player.Functions.SetMetaData('stress', newVal)
        end
    end

    TriggerClientEvent('tipi-hud:updateStress', src, newVal)
end

exports('setStress', setStress)

local function getCurrentStress(src, player)
    if GetResourceState('qbx_core') == 'started' then
        local success, qbxPlayer = pcall(function() return exports.qbx_core:GetPlayer(src) end)
        if success and qbxPlayer and qbxPlayer.PlayerData and qbxPlayer.PlayerData.metadata and qbxPlayer.PlayerData.metadata.stress ~= nil then
            return tonumber(qbxPlayer.PlayerData.metadata.stress) or 0
        end
    end

    local playerState = Player(src).state
    if playerState and playerState.stress ~= nil then
        return tonumber(playerState.stress) or 0
    end

    if player and player.PlayerData and player.PlayerData.metadata and player.PlayerData.metadata.stress ~= nil then
        return tonumber(player.PlayerData.metadata.stress) or 0
    end

    return 0
end

RegisterNetEvent('tipi-hud:gainStress')
AddEventHandler('tipi-hud:gainStress', function(amount)
    if Config.UseStress == false then return end
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local current = getCurrentStress(src, Player)
    local addVal = tonumber(amount) or 0
    local newStress = math.floor((current + addVal) * 100 + 0.5) / 100
    setStress(src, newStress)
end)

RegisterNetEvent('tipi-hud:relieveStress')
AddEventHandler('tipi-hud:relieveStress', function(amount)
    if Config.UseStress == false then return end
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local current = getCurrentStress(src, Player)
    local subVal = tonumber(amount) or 0
    local newStress = math.floor((current - subVal) * 100 + 0.5) / 100
    setStress(src, newStress)
end)

RegisterNetEvent('tipi-hud:setStressDirect')
AddEventHandler('tipi-hud:setStressDirect', function(val)
    if Config.UseStress == false then return end
    local src = source
    setStress(src, tonumber(val) or 0)
end)

RegisterNetEvent('tipi-hud:reset')
AddEventHandler('tipi-hud:reset', function()
    TriggerClientEvent('tipi-hud:reset', source, nil)
end)

lib.callback.register("tipi-hud:getVehicleType", function()
    return GetVehicleType(GetVehiclePedIsIn(GetPlayerPed(source), false))
end)

RegisterNetEvent('tipi-hud:setRestart')
AddEventHandler('tipi-hud:setRestart', function()
    SetConvar(RESTART_CONVAR, 'true')
    print("Script Restarting.")
end)

lib.callback.register('tipi-hud:isRestart', function()
    local flag = GetConvar(RESTART_CONVAR, 'false') == 'true'
    if flag then
        SetConvar(RESTART_CONVAR, 'false')
    end
    return flag
end)
