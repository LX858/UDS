QBCore = nil
local scriptname = GetCurrentResourceName()
Pcoords = nil
local changetobomber = false
Bomb = nil
local holdbomb = false
local PreviousCoords = nil
local Prohibit = false
local appove = false
local sendbutton = false
local JoinBomber = false
local washold = false
local gameStart = false
local TimetoJoin = 0
local startB = false
local clzcitemx = nil
local playerBomb = {}
local effectscale = 0.1
local timex = 0
local zcx = nil
if QBCore == nil then
    Citizen.CreateThread(function()
        while QBCore == nil do
            QBCore = exports['qb-core']:GetCoreObject()
            Citizen.Wait(100)
        end
        while not QBCore.Functions.GetPlayerData() do Wait(0) end
        Wait(30000)
        TriggerServerEvent(scriptname .. 'Getitem')
        TriggerServerEvent('zc_BomberEvent')
    end)
end

RegisterNetEvent('zc_BomberEvent_cl')
AddEventHandler('zc_BomberEvent_cl', function(tk) 
    zcx = tk 
end)

DisplayCooldown = function(count, text)
    if count >= 0 then
        SendNUIMessage({type = 'time', time = secondsToTime(count)})
        Wait(1000)
    end
    if count > 0 then
        DisplayCooldown(count - 1, text)
    else
        SendNUIMessage({type = 'time', time = text})
    end
end

RegisterNetEvent(scriptname .. 'Returnitem')
AddEventHandler(scriptname .. 'Returnitem',
                function(itemx) clzcitemx = itemx end)

RegisterNetEvent(scriptname .. 'ZC_BOMBERREGIS')
AddEventHandler(scriptname .. 'ZC_BOMBERREGIS', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local jobNow = PlayerData.job.name
    for k, v in pairs(
                    Config['อาชีพที่ไม่ต้องเข้าร่วม']) do
        if jobNow == v then return end
    end
    SendNUIMessage({type = 'berregis'})

    SendNUIMessage({
        type = 'playsound',
        sound = Config['เพลงก่อนเข้ากิจกรรม']['เล่นเพลงอะไร'],
        volume = Config['เพลงก่อนเข้ากิจกรรม']['ระดับความดังเพลง'],
        loop = false
    })

    local Beforestart = true
    local TimetoJoin = Config['CountDown']
    SendNUIMessage({type = 'time', time = TimetoJoin})

    Citizen.CreateThread(function()
        DisplayCooldown(TimetoJoin, 'Waiting...')
        Beforestart = false
    end)

    Citizen.CreateThread(function()
        while Beforestart do
            Wait(100)
            if IsControlPressed(0, 73) then
                JoinBomber = false
                SendNUIMessage({type = 'offUI'})
                SendNUIMessage({type = 'stopsound'})
                break
            end
            if IsControlPressed(0, 47) then
                JoinBomber = true
                startB = false
                TriggerServerEvent(scriptname .. "Mejoin")
                PreviousCoords = GetEntityCoords(PlayerPedId())
                SendNUIMessage({type = 'accept'})
                StartScreenEffect("MinigameEndFranklin", 0, 0)
                SendNUIMessage({type = 'buttonoff'})
                break
            end
        end
        if not JoinBomber then
            SendNUIMessage({type = 'offUI'})
            SendNUIMessage({type = 'buttonoff'})
            SendNUIMessage({type = 'stopsound'})
        end
    end)
end)

local setskin = function(skin)
    local playerPed = PlayerPedId()
    local skin = skin
    local currentHealth = GetEntityHealth(GetPlayerPed(-1))
    local currentArmor = GetPedArmour(GetPlayerPed(-1))
    RequestModel(skin)
    Citizen.CreateThread(function()

        HasModelLoaded(skin)
        Citizen.Wait(2000)

        while not HasModelLoaded(skin) do
            RequestModel(skin)
            Citizen.Wait(0)

        end

        if IsModelInCdimage(skin) and IsModelValid(skin) then
            SetPlayerModel(PlayerId(), skin)
            SetPedDefaultComponentVariation(playerPed)

        end

        SetModelAsNoLongerNeeded(skin)

        if cb ~= nil then cb() end

        TriggerEvent('skinchanger:modelLoaded')
    end)
    --   exports['progressBars']:startUI(Config["Delay"], Config["ProgressBars"]["UseSkin"])

    -- QBCore skin system
    TriggerEvent('qb-clothing:client:loadPlayerClothing')

    Citizen.Wait(100)
    SetEntityHealth(GetPlayerPed(-1), currentHealth)
    SetPedArmour(GetPlayerPed(-1), currentArmor)
end

resetskin = function()
    local playerPed = PlayerPedId()
    local skin = skin
    local currentHealth = GetEntityHealth(GetPlayerPed(-1))
    local currentArmor = GetPedArmour(GetPlayerPed(-1))
    changetobomber = true
    RequestModel(skin)
    TriggerEvent('skinchanger:getSkin', function(skin) sex = skin["sex"] end)
    if sex == 0 then
        skin = "mp_m_freemode_01"
    elseif sex == 1 then
        skin = "mp_f_freemode_01"
    end

    Citizen.CreateThread(function()
        HasModelLoaded(skin)
        Citizen.Wait(2000)

        while not HasModelLoaded(skin) do
            RequestModel(skin)
            Citizen.Wait(0)
        end

        if IsModelInCdimage(skin) and IsModelValid(skin) then
            SetPlayerModel(PlayerId(), skin)
            SetPedDefaultComponentVariation(playerPed)

        end

        SetModelAsNoLongerNeeded(skin)

        if cb ~= nil then cb() end

        TriggerEvent('skinchanger:modelLoaded')
    end)
    --  exports['progressBars']:startUI(Config["Delay"], Config["ProgressBars"]["UseDefaultSkin"])
    Citizen.Wait(3000)
    -- QBCore skin system
    TriggerEvent('qb-clothing:client:loadPlayerClothing')
    SetPedMaxHealth(playerPed, 200)

end

RegisterNetEvent(scriptname .. 'CreatZone')
AddEventHandler(scriptname .. 'CreatZone', function()

    Citizen.CreateThread(function()
        while JoinBomber do
            local Ped = PlayerPedId()
            local PedCoords = GetEntityCoords(Ped)
            Wait(1000)
            inzone = false
            if GetDistanceBetweenCoords(PedCoords,
                                        Config['จุดเล่นกิจกรรม'],
                                        true) <= Config['ระยะวง'] then
                inzone = true
            end

            if not inzone then

                SetEntityCoords(PlayerPedId(),
                                Config['จุดเล่นกิจกรรม']
                                    .x + math.random(0,
                                                     Config['การกระจายจุดสุ่มเข้าร่วม']),
                                Config['จุดเล่นกิจกรรม']
                                    .y + math.random(0,
                                                     Config['การกระจายจุดสุ่มเข้าร่วม']),
                                Config['จุดเล่นกิจกรรม']
                                    .z + 2)
            end
        end
    end)
    if Config['แสดงวง'] then
        Citizen.CreateThread(function()
            while JoinBomber do
                Wait(2)
                if inzone then
                    DrawMarker(1,
                               Config['จุดเล่นกิจกรรม']
                                   .x,
                               Config['จุดเล่นกิจกรรม']
                                   .y,
                               Config['จุดเล่นกิจกรรม']
                                   .z - 5.2, 0.0, 0.0, 0.0, 0, 0.0, 0.0,
                               Config['ระยะวง'] * 2,
                               Config['ระยะวง'] * 2, 30.0, 255, 0,
                               0, 100, false, true, 2, false, false, false,
                               false)

                end
            end
        end)
    end
end)

RegisterNetEvent(scriptname .. 'ZC_BOMBERSTART')
AddEventHandler(scriptname .. 'ZC_BOMBERSTART', function()

    if JoinBomber then
        gameStart = true
        TriggerEvent(scriptname .. 'CreatZone')
        SwitchOutPlayer(PlayerPedId(), 0, 1)
        Citizen.Wait(2000)
        Citizen.CreateThread(function()
            Citizen.Wait(math.random(100, 2000))
            TriggerServerEvent(scriptname .. "BOMBER_SwitchDimension",
                               Config['Dimension'])
        end)

        FreezeEntityPosition(PlayerPedId(), true)

        Citizen.Wait(3000)
        if Config['เปลี่ยนสกิน'] then
            setskin(Config['เลือกสกิน'])
        end
        SetEntityCoords(PlayerPedId(),
                        Config['จุดเล่นกิจกรรม'].x +
                            math.random(0,
                                        Config['การกระจายจุดสุ่มเข้าร่วม']),
                        Config['จุดเล่นกิจกรรม'].y +
                            math.random(0,
                                        Config['การกระจายจุดสุ่มเข้าร่วม']),
                        Config['จุดเล่นกิจกรรม'].z +
                            2)
        SwitchInPlayer(PlayerPedId())

        Citizen.Wait(4500)
        SendNUIMessage({type = 'stopsound'})
        Citizen.Wait(500)
        SendNUIMessage({
            type = 'playsound',
            sound = Config['เพลงในกิจกรรม']['เล่นเพลงอะไร'],
            volume = Config['เพลงในกิจกรรม']['ระดับความดังเพลง'],
            loop = true
        })

        Citizen.Wait(4500)
        Citizen.CreateThread(function() DisplayCooldown(-1, 'Start!!') end)
        Citizen.Wait(500)
        StartScreenEffect("MinigameEndFranklin", 0, 0)
        FreezeEntityPosition(PlayerPedId(), false)
        Citizen.CreateThread(function()
            DisplayCooldown(Config['เวลากิจกรรม'],
                            'BOMB!!')
        end)
    end
end)

RegisterNetEvent(scriptname .. 'ZC_SELECTBOMBERCL')
AddEventHandler(scriptname .. 'ZC_SELECTBOMBERCL', function()

    if IsPedDeadOrDying(PlayerPedId()) and gameStart then revive() end
    ClearPedTasksImmediately(PlayerPedId())
    SendNUIMessage({
        type = 'eff',
        sound = Config['เสียงเอฟเฟคส่งบอมบ์']['เล่นเพลงอะไร'],
        volume = Config['เสียงเอฟเฟคส่งบอมบ์']['ระดับความดังเพลง']

    })
    holdbombx()
end)

RegisterNetEvent(scriptname .. 'Zc_ClearBomb')
AddEventHandler(scriptname .. 'Zc_ClearBomb', function()
    playbombsong = false
    holdbomb = false
    DetachEntity(PlayerPedId(), true, true)
    DeleteEntity(Bomb)
    ClearPedSecondaryTask(PlayerPedId())
    SendNUIMessage({
        type = 'eff',
        sound = Config['เสียงเอฟเฟคส่งบอมบ์']['เล่นเพลงอะไร'],
        volume = Config['เสียงเอฟเฟคส่งบอมบ์']['ระดับความดังเพลง']

    })
end)

RegisterNetEvent(scriptname .. 'KickLegCL')
AddEventHandler(scriptname .. 'KickLegCL', function()
    if not holdbomb then
        SetPedToRagdoll(PlayerPedId(), Config['เวลาล้ม'] * 1000,
                        Config['เวลาล้ม'] * 1000, 0, 0, 0, 0)
    end
end)

function holdbombx()
    playbombsong = false
    CountBomb =
        Config['เวลาก่อนระเบิดจะระเบิด']

    holdbomb = true
    Wait(100)
    local animdict2 = "anim@heists@box_carry@"
    local animname2 = "idle"
    RequestAnimDict(animdict2)
    while not HasAnimDictLoaded(animdict2) do Citizen.Wait(1) end
    TaskPlayAnim(PlayerPedId(), animdict2, animname2, 5.0, -1.0, -1, 50, 0,
                 false, false, false)
    Bomb = CreateObject(Config['ชื่อพร้อบระเบิด'],
                        GetEntityCoords(PlayerPedId()), true, true, true)
    AttachEntityToEntity(Bomb, PlayerPedId(),
                         GetPedBoneIndex(PlayerPedId(), 28252), 0.5, 0.6, 0.00,
                         30.0, 270.0, 180.0, true, true, false, true, 1, true)

    Citizen.CreateThread(function()
        while holdbomb do
            if not IsEntityPlayingAnim(PlayerPedId(), animdict2, animname2, 3) then
                TaskPlayAnim(PlayerPedId(), animdict2, animname2, 5.0, -1.0, -1,
                             50, 0, false, false, false)
            end
            Citizen.Wait(3000)
        end
    end)

    Citizen.CreateThread(function()
        while holdbomb do
            SetPedCanRagdoll(PlayerPedId(), false)
            Citizen.Wait(5)
        end
    end)

    Citizen.CreateThread(function()
        while holdbomb do
            Wait(1000)
            if holdbomb then Starteffect(effectscale) end
        end
    end)
    if Config.NewMode then
        Citizen.CreateThread(function()
            while holdbomb do
                Wait(1000)
                CountBomb = CountBomb - 1
                if CountBomb < 20 and CountBomb > 10 then
                    effectscale = 0.3
                elseif CountBomb < 10 and CountBomb > 5 then
                    effectscale = 0.5
                elseif CountBomb < 5 and CountBomb > 1 then
                    SendNUIMessage({
                        type = 'eff',
                        sound = Config['เพลงตอนถือบอมบ์']['เล่นเพลงอะไร'],
                        volume = Config['เพลงตอนถือบอมบ์']['ระดับความดังเพลง']
                    })
                    effectscale = 3.0
                elseif CountBomb < 1 then
                    effectscale = 5.0
                end
                if CountBomb == 0 then
                    CountBomb = -10
                    DetachEntity(PlayerPedId(), true, true)
                    DeleteEntity(Bomb)
                    ClearPedSecondaryTask(PlayerPedId())
                    local Pcoordsx = GetEntityCoords(PlayerPedId())
                    AddExplosion(Pcoordsx.x, Pcoordsx.y, Pcoordsx.z, 19, 0.05,
                                 true, false, false)
                    AddExplosion(Pcoordsx.x, Pcoordsx.y, Pcoordsx.z, 2,
                                 Config['ความแรงระเบิด'],
                                 true, false, false)
                    SetEntityHealth(PlayerPedId(), 0)
                    TriggerServerEvent('zc_Bomberdie')
                end
            end
        end)
        Citizen.CreateThread(function()
            while holdbomb do
                Wait(30)
                local Pcoordsx = GetEntityCoords(PlayerPedId())
                if CountBomb > 0 then
                    ShowToolTip(CountBomb, Pcoordsx.x, Pcoordsx.y,
                                Pcoordsx.z + 0.5)
                end
            end
        end)
    end
end

function Starteffect(effectscale)
    UseParticleFxAssetNextCall('core')
    local pfx = StartNetworkedParticleFxNonLoopedOnEntity(
                    'ent_dst_elec_fire_sp', Bomb, 0.0, 0.0, 0.80, 0.0, 0.0, 0.0,
                    effectscale, false, false, false)
end

function StartBomb()
    if Config.NewMode then
        Citizen.CreateThread(function()
            while JoinBomber do
                Wait(1000)
                if IsPedDeadOrDying(PlayerPedId()) then
                    -- if not holdbomb then 
                    playbombsong = false
                    TriggerEvent("pNotify:SendNotification", {
                        text = " กิจกรรมเสร็จสิ้น",
                        type = "alert",
                        timeout = 5 * 1000,
                        layout = "CenterRight",
                        queue = "global"
                    })
                    holdbomb = false
                    Wait(1000)
                    SendNUIMessage({type = 'offUI'})

                    Wait(1000)
                    SendNUIMessage({type = 'stopsound'})
                    reset()
                    SwitchOutPlayer(PlayerPedId(), 0, 1)
                    Citizen.Wait(2000)
                    FreezeEntityPosition(PlayerPedId(), true)
                    SetEntityCoords(PlayerPedId(), PreviousCoords)
                    SwitchInPlayer(PlayerPedId())
                    Citizen.Wait(10000)
                    FreezeEntityPosition(PlayerPedId(), false)
                    if IsPedDeadOrDying(PlayerPedId(), 1) then
                        revive()
                    end
                    Wait(2000)
                    if Config['เปลี่ยนสกิน'] then
                        resetskin()
                    end
                    count = 0
                    TriggerServerEvent(scriptname .. "BOMBER_SwitchDimension", 0)
                    JoinBomber = false
                    -- end
                end
            end
        end)
    end
    Citizen.CreateThread(function()
        while JoinBomber do
            Wait(150)
            if holdbomb then
                washold = true
                local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer()
                -- local closestPlayerPed = GetPlayerPed(closestPlayer)

                if closestPlayer ~= -1 and closestDistance <= 1.5 then
                    local closestPlayerPed = GetPlayerPed(closestPlayer)
                    local isPlayerNomal = true
                    local idPlayer = GetPlayerServerId(closestPlayer)
                    for k, v in pairs(playerBomb) do
                        if idPlayer == v then
                            isPlayerNomal = false
                        end
                    end
                    if isPlayerNomal then
                        if not IsPedDeadOrDying(PlayerPedId(), true) then
                            if not IsPedDeadOrDying(closestPlayerPed, true) then
                                TriggerServerEvent(scriptname .. 'BOMBERCHANGE',
                                                   idPlayer, GetPlayerServerId(
                                                       PlayerId()), clzcitemx)
                            end
                        end
                    else
                        Wait(500)
                    end

                end

                if Config['วิ่งไม่เเหนื่อย'] then
                    ResetPlayerStamina(PlayerId())
                end
                if Config['วิ่งไว'] then
                    SetPedMovementClipset(playerPed, "MOVE_M@QUICK", true)
                    SetPedMoveRateOverride(PlayerId(), 10.0)
                    SetRunSprintMultiplierForPlayer(PlayerId(),
                                                    Config['ความเร็ววิ่งไว'])
                end
            end
        end
    end)
    --- ตายแล้วยังส่งระเบิดได้ะ
    Citizen.CreateThread(function()
        while JoinBomber do
            local zc = 500
            if not holdbomb then
                if not IsPedRagdoll(PlayerPedId()) then
                    if not IsPedDeadOrDying(PlayerPedId(), 1) then
                        zc = 150
                        local vcoords = GetEntityCoords(PlayerPedId())
                        local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer()
                        local closestPlayerPed = GetPlayerPed(closestPlayer)
                        if closestDistance <= 1.5 then
                            zc = 70
                            ShowToolTip(Config['ข้อความ'],
                                        vcoords.x, vcoords.y, vcoords.z + 0.5)
                            if IsControlPressed(0,
                                                Config['ปุ่มดักขา']) then

                                TriggerServerEvent(scriptname .. 'KickLeg',
                                                   GetPlayerServerId(
                                                       closestPlayer), clzcitemx)
                                zc = 1000
                            end
                        end
                    end
                end
            end
            Wait(zc)
        end
    end)
    Citizen.CreateThread(function()
        while JoinBomber do
            Wait(1000)
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                ClearPedTasksImmediately(PlayerPedId())
            end
        end
    end)
    Citizen.CreateThread(function()
        while JoinBomber do
            Wait(500)
            if not holdbomb then
                if washold then
                    washold = false
                    SetPedMoveRateOverride(PlayerId(), 1.0)
                    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                    ResetPedMovementClipset(PlayerPedId())
                    SetPedCanRagdoll(PlayerPedId(), true)
                end
            end
        end
    end)
    if Config['ชุบในกิจกรรม'] and not Config.NewMode then
        Citizen.CreateThread(function()
            while JoinBomber do
                Wait(1000)
                if IsPedDeadOrDying(PlayerPedId(), true) and gameStart then
                    Wait(3000)
                    revive()
                end
            end
        end)
    end
end

RegisterNetEvent(scriptname .. 'ZC_BOMBEREND')
AddEventHandler(scriptname .. 'ZC_BOMBEREND', function()
    if JoinBomber then
        gameStart = false

        if holdbomb then
            DetachEntity(PlayerPedId(), true, true)
            DeleteEntity(Bomb)
            ClearPedSecondaryTask(PlayerPedId())
            Pcoords = GetEntityCoords(PlayerPedId())
            AddExplosion(Pcoords.x, Pcoords.y, Pcoords.z, 19, 0.05, true, false,
                         Config['ไม่ระเบิด'])
            AddExplosion(Pcoords.x, Pcoords.y, Pcoords.z, 2,
                         Config['ความแรงระเบิด'],
                         true, false, Config['ไม่ระเบิด'])
            SetEntityHealth(PlayerPedId(), 0)
        end

        if not holdbomb then
            if not IsPedDeadOrDying(PlayerPedId(), 1) then
                Citizen.CreateThread(function()
                    Citizen.Wait(math.random(100, 1000))
                    TriggerServerEvent(scriptname .. 'BOMBEREND_SURVIVE', zcx)
                end)
            end
        else
            holdbomb = false
            TriggerServerEvent(scriptname .. 'BOMBEREND_HOLDBOMB', zcx)
        end

        TriggerEvent("pNotify:SendNotification", {
            text = " กิจกรรมเสร็จสิ้น",
            type = "alert",
            timeout = 5 * 1000,
            layout = "CenterRight",
            queue = "global"
        })

        Wait(10000)
        SendNUIMessage({type = 'offUI'})

        Wait(1000)
        SendNUIMessage({type = 'stopsound'})
        reset()
        SwitchOutPlayer(PlayerPedId(), 0, 1)
        Citizen.Wait(2000)
        FreezeEntityPosition(PlayerPedId(), true)
        SetEntityCoords(PlayerPedId(), PreviousCoords)
        SwitchInPlayer(PlayerPedId())
        Citizen.Wait(10000)
        FreezeEntityPosition(PlayerPedId(), false)
        if IsPedDeadOrDying(PlayerPedId(), 1) then revive() end
        Wait(2000)
        count = 0
        if Config['เปลี่ยนสกิน'] then resetskin() end
        TriggerServerEvent(scriptname .. "BOMBER_SwitchDimension", 0)
        JoinBomber = false
    end
end)

ShowToolTip = function(msg, x, y, z)
    AddTextEntry("Test", msg)
    SetFloatingHelpTextWorldPosition(1, x, y, z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp("Test")
    EndTextCommandDisplayHelp(2, false, false, -1)
end

function reset()
    washold = false
    holdbomb = false
    Prohibit = false
    appove = false
    sendbutton = false
    JoinBomber = false
    TimetoJoin = 0
    startB = false
    gameStart = false
    DetachEntity(PlayerPedId(), true, true)
    DeleteEntity(Bomb)
    ClearPedSecondaryTask(PlayerPedId())
    SetPedMoveRateOverride(PlayerId(), 1.0)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    ResetPedMovementClipset(PlayerPedId())
    TriggerServerEvent(scriptname .. "BOMBER_SwitchDimension", 0)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DetachEntity(PlayerPedId(), true, true)
        DeleteEntity(Bomb)
        TriggerServerEvent(scriptname .. "BOMBER_SwitchDimension", 0)
        reset()
    end
end)

RegisterNetEvent(scriptname .. 'List_playerBomb')
AddEventHandler(scriptname .. 'List_playerBomb', function(data)
    playerBomb = data
    if not startB then
        startB = true
        StartBomb()
    end
end)

RegisterNetEvent(scriptname .. 'playerOutServer')
AddEventHandler(scriptname .. 'playerOutServer', function() end)

secondsToTime = function(seconds)
    local seconds, hours, mins, secs = tonumber(seconds), 0, 0, 0
    if seconds <= 0 then
        return '00:00'
    else
        local hours = string.format("%02.f", math.floor(seconds / 3600))
        local mins = string.format("%02.f",
                                   math.floor(seconds / 60 - (hours * 60)))
        local secs = string.format("%02.f", math.floor(
                                       seconds - hours * 3600 - mins * 60))
        if tonumber(hours) > 0 then
            return hours .. ':' .. mins .. ':' .. secs
        else
            return mins .. ':' .. secs
        end
    end
end

RegisterNetEvent(scriptname .. 'restskinall')
AddEventHandler(scriptname .. 'restskinall', function() resetskin() end)

RegisterNetEvent(scriptname .. 'ZC_BOMBERFULL')
AddEventHandler(scriptname .. 'ZC_BOMBERFULL', function()
    JoinBomber = false
    SendNUIMessage({type = 'offUI'})
    SendNUIMessage({type = 'stopsound'})

    TriggerEvent("pNotify:SendNotification", {
        text = "เสียใจด้วยคนเข้ากิจกรรมเต็มแล้วจ๊ะ",
        type = "alert",
        timeout = 10 * 1000,
        layout = "CenterRight",
        queue = "global"
    })
end)
