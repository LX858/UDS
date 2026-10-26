OldArmour = 0
counttext = 0
HoldFlag = false
NumBerx = 0
NumbertoRandom = 0
CountRevive = 0
TeamData = {}
TeamScore = {}
usedSwords = {}
Ped = nil
inteam = false
Pcoords = nil
Imjoin = false
spawnedSwords = {}
MyTeam = nil
SwordStart = false
Register = false
handobj = false
MyOldCoord = nil
itemList = nil
sudden = false
attackskill = {
    'Slow', 'Freeze', 'Onfire', 'Stunt', 'Drunk', 'SetCoord', 'MinusPoint'
}
-------------
timerun = 0
runfast = false
drunk = false
timedrunk = 0
inlooprevive = false
local swordDeadUiShown = false
local lastSwordDeadUiText = nil
local swordDeadNuiShown = false
local lastSwordDeadSeconds = nil
------------
Citizen.CreateThread(function()
    while not UIloaded do Wait(100) end
    TriggerServerEvent('zcSword_SetDimension', 0)
end)

-------------------------------------------------------------------
-------------------------------------------------------------------
function Cancle()
    SendNUIMessage({ type = 'CloseGameStartWaitRegister' })
    Imjoin = false
    sudden = true
    pcall(function()
        if LocalPlayer and LocalPlayer.state then
            LocalPlayer.state:set('inSwordFlag', false, false)
        end
    end)
    if MyTeam then TriggerServerEvent('zcSword_SetDimension', 0) end
    Register = false
    HoldFlag = false
    NumBerx = 0
    inlooprevive = false
    NumbertoRandom = 0
    CountRevive = 0
    TeamData = {}
    TeamScore = {}
    Ped = nil
    Pcoords = nil
    SwordStart = false
    playanim = false
    if handobj then DeleteObject(handobj) end
    handobj = nil
    for k, v in pairs(usedSwords) do DeleteObject(v) end
    for k, v in pairs(spawnedSwords) do DeleteObject(v.Sword) end
    spawnedSwords = {}
    timerun = 0
    runfast = false
    drunk = false
    timedrunk = 0
    MyTeam = nil
    inteam = false
    SendNUIMessage({ type = 'CloseVictory' })
    Wait(2000)
    SendNUIMessage({ type = 'CloseGameStart' })
    if swordDeadUiShown and lib and lib.hideTextUI then
        lib.hideTextUI()
        swordDeadUiShown = false
        lastSwordDeadUiText = nil
    end
    if swordDeadNuiShown then
        SendNUIMessage({ type = 'SwordDeadHide' })
        swordDeadNuiShown = false
        lastSwordDeadSeconds = nil
    end
    if SwordPlayerIsDown() then
        ReviveOnStartOrEnd()
    end
    sudden = false
    Wait(2000)
    if MyOldCoord then
        SetEntityCoords(cache.ped, MyOldCoord.x, MyOldCoord.y,
            MyOldCoord.z + 2)
        MyOldCoord = nil
    end
    if OldArmour then
        SetPedArmour(cache.ped, OldArmour)
    end
    Wait(1000)
    Changeback()
end

function CancleNojoin()
    CountRevive = 0
    Imjoin = false
    Register = false
    pcall(function()
        if LocalPlayer and LocalPlayer.state then
            LocalPlayer.state:set('inSwordFlag', false, false)
        end
    end)
    HoldFlag = false
    NumBerx = 0
    NumbertoRandom = 0
    TeamData = {}
    TeamScore = {}
    Ped = nil
    Pcoords = nil
    SwordStart = false
    MyTeam = nil
    if swordDeadUiShown and lib and lib.hideTextUI then
        lib.hideTextUI()
        swordDeadUiShown = false
        lastSwordDeadUiText = nil
    end
    if swordDeadNuiShown then
        SendNUIMessage({ type = 'SwordDeadHide' })
        swordDeadNuiShown = false
        lastSwordDeadSeconds = nil
    end
end

function RegisUIRandom()
    SendNUIMessage({
        type = 'open',
        CountDown = SecondsToClock(Config.JoinWaitSeconds),
        Header = 'Chế độ chia đội ngẫu nhiên',
        Team = TeamData
    })
    SetNuiFocus(true, true)
end

function RegisUISelect()
    SendNUIMessage({ type = 'OpenMenuSelectTeam', DataTeam = TeamData })
    SetNuiFocus(true, true)
end

function UpdateUITeam(TeamData)
    SendNUIMessage({ type = 'UpdateTeam', DataTeam = TeamData })
end

function UpdateUITime(time)
    SendNUIMessage({ type = 'UpdateTime', CountDown = SecondsToClock(time) })
end

function closeUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeOpen' })
end

RegisterNetEvent('zcSword_Register')
AddEventHandler('zcSword_Register', function(Mode, NumBer, TimeNow)
    Register = true
    CreateTeamData(NumBer)
    NumBerx = NumBer
    StartCountDown(Config.JoinWaitSeconds)
    SendNUIMessage({
        type = 'GameStartWaitRegister',
        TimeEventStart = TimeNow,
        Sounds = Config.Sounds,
        Volume = Config.Volume
    })
    Citizen.CreateThread(function()
        while Register do
            Wait(0)
            if IsControlJustPressed(0, Keys[Config.UISETTING.ButtonAcceptEvent]) then
                Imjoin = true
                if Mode == 'Random' then
                    if not MyTeam then
                        NumbertoRandom = NumBer

                        TriggerServerEvent('zcSword_SvRandomTeam',
                            NumbertoRandom)
                    end
                else
                    RegisUISelect()
                end
            end
            if IsControlJustPressed(0, Keys[Config.UISETTING.ButtonDeniedEvent]) then
                if not Imjoin then Cancle() end
            end
        end
    end)
end)

function StartCountDown(time)
    Citizen.CreateThread(function()
        while Register do
            Wait(1000)
            time = time - 1
            UpdateUITime(time)
            if time <= 0 then Register = false end
        end
    end)
end

function Inteam(MyCloth)
    inteam = true
    Citizen.CreateThread(function()
        while inteam do
            Wait(math.random(
                (Config.OutfitCheckIntervalSeconds *
                    1000 / 2),
                (Config.OutfitCheckIntervalSeconds *
                    1000)))
            if not inteam then break end
            ApplyTeamOutfit(MyCloth)
        end
    end)
end

function WarptoJoin()
    SwitchOutPlayer(cache.ped, 0, 1)
    Citizen.Wait(2000)
    FreezeEntityPosition(cache.ped, true)
    SetCloth()
    pcall(function()
        if LocalPlayer and LocalPlayer.state then
            LocalPlayer.state:set('inSwordFlag', true, false)
        end
    end)
    TriggerServerEvent('zcSword_SetDimension', Config.Dimension)
    Citizen.Wait(3000)
    SetEntityCoords(cache.ped, Config.TeamData[MyTeam].SpawnPoint.x +
        math.random(-15, 15),
        Config.TeamData[MyTeam].SpawnPoint.y + math.random(-15, 15),
        Config.TeamData[MyTeam].SpawnPoint.z + 2)
    SendNUIMessage({ type = 'close' })
    SwitchInPlayer(cache.ped)
    SetLocalPlayerAsGhost(true)
    Citizen.CreateThread(function()
        Wait(Config.PassiveSeconds * 1000)
        SetLocalPlayerAsGhost(false)
    end)
    Citizen.Wait(Config.FreezeOnWarpSeconds * 1000)
    StartScreenEffect("MinigameEndFranklin", 0, 0)
    FreezeEntityPosition(cache.ped, false)
end

RegisterNetEvent('zcSword_Start')
AddEventHandler('zcSword_Start', function()
    SendNUIMessage({ type = 'CloseGameStartWaitRegister' })
    if not MyTeam then return end
    Register = false
    SwordStart = true
    MyOldCoord = GetEntityCoords(cache.ped)
    OldArmour = GetPedArmour(cache.ped)
    WarptoJoin()
    Genmycoord()
    Wait(2000)
    do
        if SwordPlayerIsDown() then
            ReviveOnStartOrEnd()
        end
    end
    StartActivity()
    Citizen.CreateThread(function()
        while SwordStart do
            Wait(1000)
            local dead = SwordPlayerIsDown()
            if dead then
                CountRevive = CountRevive + 1
                local left = math.max(0, (Config.ReviveDelaySeconds or 0) - CountRevive)
                if not swordDeadNuiShown then
                    SendNUIMessage({ type = 'SwordDead', Seconds = left })
                    swordDeadNuiShown = true
                    lastSwordDeadSeconds = left
                else
                    if lastSwordDeadSeconds ~= left then
                        SendNUIMessage({ type = 'SwordDeadUpdate', Seconds = left })
                        lastSwordDeadSeconds = left
                    end
                end
                if CountRevive >=
                    Config.ReviveDelaySeconds then
                    CountRevive = 0
                    Revive()
                end
            else
                if CountRevive ~= 0 then CountRevive = 0 end
                if swordDeadUiShown and lib and lib.hideTextUI then
                    lib.hideTextUI()
                    swordDeadUiShown = false
                    lastSwordDeadUiText = nil
                end
                if swordDeadNuiShown then
                    SendNUIMessage({ type = 'SwordDeadHide' })
                    swordDeadNuiShown = false
                    lastSwordDeadSeconds = nil
                end
            end
        end
    end)

    Citizen.CreateThread(function()
        while SwordStart do
            Citizen.Wait(1000)
            local dead = SwordPlayerIsDown()
            if dead then
                HoldSkill = false
                if handobj then DeleteEntity(handobj) end
                handobj = nil
                TriggerEvent('zcSword_Holdskillstop')
            end
        end
    end)

    Citizen.CreateThread(function()
        while SwordStart do
            Wait(1000)
            local Pcoords = GetEntityCoords(cache.ped)
            if GetDistanceBetweenCoords(Pcoords, Config.StartPoint, true) >=
                Config.Distance then
                if Config.TeleportBackOnOutOfBounds then
                    SetEntityCoords(cache.ped, Config.StartPoint)
                end
                Wait(50)
                if Config.KillOnOutOfBounds then
                    ApplyDamageToPed(cache.ped, 999, false)
                end
            end
        end
    end)
    Citizen.CreateThread(function()
        while SwordStart do
            Wait(2)
            DrawMarker(1, Config.StartPoint.x, Config.StartPoint.y,
                Config.StartPoint.z - 1, 0, 0, 0, 0, 0, 0,
                Config.Distance * 2.0, Config.Distance * 2.0, 10.0, 255,
                0, 0, 100, 0, 0, 0, 0)
        end
    end)
end)

function CreateTeamScore()
    for i = 1, NumBerx do
        TeamScore[i] = {
            TeamName = Config.TeamData[i].TeamName,
            ScoreTeam = GlobalState["Score" .. i],
            ColorTeam = Config.TeamData[i].ColorTeam,
            Buff = GlobalState["Buff" .. i],
            Minus = GlobalState["Minus" .. i]
        }
    end
end

function UpdateActivityUI()
    SendNUIMessage({ type = 'GameStart', DataTeam = TeamScore })
end

RegisterNetEvent('zcSword_Holdskillstop')
AddEventHandler('zcSword_Holdskillstop', function()
    HoldSkill = false
    if handobj then DeleteEntity(handobj) end
    handobj = nil
end)

RegisterNetEvent('zcSword_SpawnSword')
AddEventHandler('zcSword_SpawnSword', function(kdata, coord)
    if not SwordStart then return end
    Wait(1000)
    for k, v in pairs(Config.Sword) do if k == kdata then datasword = v end end
    Wait(50)
    local sword = CreateObject(GetHashKey(datasword.Sword), coord.x, coord.y,
        coord.z + 3, false, false, true)
    PlaceObjectOnGroundProperly(sword)
    Wait(50)
    Cox = GetEntityCoords(sword)
    SetEntityCoords(sword, Cox.x, Cox.y, Cox.z - Config.SwordFloatOffset)
    local Cox2 = GetEntityCoords(sword)

    SetEntityAsMissionEntity(sword, true, true)
    FreezeEntityPosition(sword, true)
    SetModelAsNoLongerNeeded(sword)
    Sword = {
        Sword = sword,
        kIndex = kdata,
        SwordCoord = Cox2,
        Model = datasword.Sword,
        Buff = datasword.Buff,
        Time = datasword.BuffTime,
        Text = datasword.TextBuff

    }
    table.insert(spawnedSwords, Sword)
end)

RegisterNetEvent('zcSword_SpawnFlagSword')
AddEventHandler('zcSword_SpawnFlagSword', function(kdata, coord)
    if not MyTeam then return end
    Wait(50)
    if coord == nil or coord == vector(0.0, 0.0, 0.0) then
        coord = Config.StartPoint
    end
    local sword = CreateObject(GetHashKey(Config.FlagSword), coord.x, coord.y,
        coord.z + 3, false, false, true)
    PlaceObjectOnGroundProperly(sword)
    Wait(50)
    Cox = GetEntityCoords(sword)
    SetEntityCoords(sword, Cox.x, Cox.y, Cox.z - Config.FlagSwordFloatOffset)
    local Cox2 = GetEntityCoords(sword)
    SetEntityAsMissionEntity(sword, true, true)
    FreezeEntityPosition(sword, true)
    SetModelAsNoLongerNeeded(sword)
    Sword = {
        Sword = sword,
        SwordCoord = Cox2,
        Model = Config.FlagSword,
        Point = true,
        Text = Config.FlagText
    }
    table.insert(spawnedSwords, Sword)
end)

function Genmycoord()
    Citizen.CreateThread(function()
        while SwordStart do
            Wait(500)
            Pcoords = GetEntityCoords(cache.ped)
        end
    end)
end

function StartActivity()
    Citizen.CreateThread(function()
        while SwordStart do
            Wait(900)
            CreateTeamScore()
            Wait(100)
            UpdateUITime(GlobalState.SwordTime)
            UpdateActivityUI()
        end
    end)

    Citizen.CreateThread(function()
        while SwordStart do
            Wait(0)
            for k, v in pairs(spawnedSwords) do
                if v.SwordCoord then
                    if v.Point then
                        DrawMarker(1, v.SwordCoord.x, v.SwordCoord.y,
                            v.SwordCoord.z + 2.0, 0, 0, 0, 0, 0, 0, 1.0,
                            1.0, 10.0, 255, 255, 0, 255, 1, 1, 0, 0)
                    end
                    local pedcoords = GetEntityCoords(cache.ped)
                    if pedcoords then
                        if #(pedcoords - v.SwordCoord) < 2.5 then
                            if handobj then
                                DrawText3D(
                                    v.SwordCoord.x, v.SwordCoord.y,
                                    v.SwordCoord.z + 1.2,
                                    Config.Text.alreadyHasSword .. v.Text)
                            else
                                DrawText3D(
                                    v.SwordCoord.x, v.SwordCoord.y,
                                    v.SwordCoord.z + 1.2,
                                    Config.Text.pickupPrompt .. v.Text)
                            end

                            if IsControlJustPressed(0,
                                    Config.Keys.pickupSword) and
                                not IsPedDeadOrDying(cache.ped) then
                                if not handobj then
                                    if not isPickup then
                                        isPickup = true
                                        Citizen.CreateThread(function()
                                            Wait(1000)
                                            isPickup = false
                                        end)
                                        ksword = k
                                        -- Snapshot coords before progress bar: another player picking up
                                        -- clears spawnedSwords[k].SwordCoord for everyone via
                                        -- zc_sword_removeswordpickpCL, which would nil this at completion.
                                        local sc = v.SwordCoord
                                        local pickSwordCoord = sc and
                                            vector3(sc.x, sc.y, sc.z) or nil
                                        local pickPoint = v.Point
                                        Wait(100)
                                        playanimation()
                                        local pickSec = v.Point and
                                            (Config.FlagPickupProgressSeconds or Config.PickupProgressSeconds) or
                                            Config.PickupProgressSeconds
                                        local pickLabel = v.Point and 'Đang nhặt cờ' or 'Đang nhặt kiếm'
                                        local success = lib.progressBar({
                                            duration = pickSec * 1000,
                                            label = pickLabel,
                                            useWhileDead = false,
                                            canCancel = true,
                                            disable = {
                                                car = true,
                                            },
                                        })
                                        if success then
                                            playanim = false
                                            ClearPedTasksImmediately(
                                                cache.ped)
                                            FreezeEntityPosition(
                                                cache.ped, false)
                                            if not IsPedDeadOrDying(
                                                    cache.ped) then
                                                if ksword ~= nil then
                                                    if spawnedSwords[ksword] ~=
                                                        nil then
                                                        if not IsPedDeadOrDying(
                                                                cache.ped) then
                                                            isPickup =
                                                                false

                                                            if pickSwordCoord then
                                                                TriggerServerEvent(
                                                                    'zc_sword_removeswordpickp',
                                                                    ksword,
                                                                    pickSwordCoord,
                                                                    pickPoint)
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        else
                                            playanim = false
                                            ClearPedTasksImmediately(
                                                cache.ped)
                                            FreezeEntityPosition(
                                                cache.ped, false)
                                        end

                                        -- TriggerEvent(
                                        --     "mythic_progbar:client:progress", {
                                        --         name = "pickup_sword",
                                        --         duration = Config.PickupProgressSeconds *
                                        --             1000,
                                        --         label = "Nhặt kiếm",
                                        --         useWhileDead = false,
                                        --         canCancel = true,
                                        --         controlDisables = {
                                        --             disableMovement = true,
                                        --             disableCarMovement = true,
                                        --             disableMouse = false,
                                        --             disableCombat = true
                                        --         }
                                        --     }, function(cancelled)
                                        --         playanim = false
                                        --         ClearPedTasksImmediately(
                                        --             cache.ped)
                                        --         FreezeEntityPosition(
                                        --             cache.ped, false)
                                        --         if not cancelled then
                                        --             if not IsPedDeadOrDying(
                                        --                     cache.ped) then
                                        --                 if ksword ~= nil then
                                        --                     if spawnedSwords[ksword] ~=
                                        --                         nil then
                                        --                         if not IsPedDeadOrDying(
                                        --                                 cache.ped) then
                                        --                             isPickup =
                                        --                                 false

                                        --                             TriggerServerEvent(
                                        --                                 'zc_sword_removeswordpickp',
                                        --                                 ksword,
                                        --                                 spawnedSwords[ksword]
                                        --                                 .SwordCoord,
                                        --                                 spawnedSwords[ksword]
                                        --                                 .Point)
                                        --                         end
                                        --                     end
                                        --                 end
                                        --             end
                                        --         else
                                        --             isPickup = false
                                        --         end
                                        --         Wait(500)
                                        --         isPickup = false
                                        --     end)
                                    end
                                else

                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

function HoldflagSkill(id, buffx, timex)
    if GetPlayerServerId(PlayerId()) == id then
        local attacktype = false
        for k, v in pairs(attackskill) do
            if buffx == v then attacktype = true end
        end
        Notify('Nhấn E để sử dụng kỹ năng', 'success')
        HoldSkill = true

        if attacktype then
            Citizen.CreateThread(function()
                local Num = NumBerx
                local xteam = MyTeam % Num + 1
                while HoldSkill do
                    local zc = 4
                    if IsControlJustPressed(0, 20) then
                        Wait(100)
                        xteam = xteam % Num + 1
                        if xteam == MyTeam then
                            xteam = xteam % Num + 1
                        end
                    end
                    local TeamName = Config.TeamData[xteam].TeamName
                    DrawText2D2(0.95, 1.35, 0.4, 1.0, 1.0,
                        Config.Textx1 .. TeamName)
                    DrawText2D(0.95, 1.35, 0.4, 1.0, 1.05, Config.Textx2)
                    if IsControlJustPressed(0,
                            Config.Keys.useSkill) then
                        TriggerServerEvent('zcSword_useSkill', MyTeam, xteam,
                            buffx, timex)
                        HoldSkill = false
                        if handobj then
                            DeleteEntity(handobj)
                        end
                        handobj = nil
                        break
                    end
                    if sudden then break end
                    Citizen.Wait(zc)
                end
            end)
        else
            Citizen.CreateThread(function()
                local Num = NumBerx
                local xteam = MyTeam % Num + 1
                while HoldSkill do
                    local zc = 4
                    if IsControlJustPressed(0,
                            Config.Keys.useSkill) then
                        TriggerServerEvent('zcSword_useSkill', MyTeam, xteam,
                            buffx, timex)
                        HoldSkill = false
                        if handobj then
                            DeleteEntity(handobj)
                        end
                        handobj = nil
                        TriggerEvent('zcSword_Holdskillstop')
                        break
                    end
                    DrawText2D2(0.95, 1.35, 0.4, 1.0, 1.0, Config.Textx1)
                    Citizen.Wait(zc)
                end
            end)
        end
    end
end

function MarkerHoldFlag(id)
    local HoldFlagID = GetPlayerFromServerId(id)
    local PedFlag = GetPlayerPed(HoldFlagID)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            PedFlagCO = GetEntityCoords(PedFlag)
            if IsPedDeadOrDying(PedFlag, 1) then break end
            if sudden then break end
            if PedFlag ~= cache.ped and PedFlag ~= 0 then
                DrawMarker(1, PedFlagCO.x, PedFlagCO.y, PedFlagCO.z + 2.0, 0, 0,
                    0, 0, 0, 0, 0.6, 0.6, 10.0, 255, 255, 0, 255, 1, 1,
                    0, 0)
            end
        end
    end)
end

function Holdflagpoint(id)
    local HoldFlagID = GetPlayerFromServerId(id)
    local PedFlag = GetPlayerPed(HoldFlagID)
    if GetPlayerServerId(PlayerId()) == id then
        HoldFlag = true
        TriggerServerEvent('zcSword_HoldflagAddscore', MyTeam)
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(1000)
                if IsPedDeadOrDying(cache.ped) then
                    local Coords = GetEntityCoords(cache.ped)
                    HoldFlag = false
                    if handobj then DeleteEntity(handobj) end
                    handobj = nil
                    TriggerServerEvent('zcSword_HoldflagAddscore', MyTeam,
                        HoldFlag, Coords)
                    break
                end
                if sudden then break end
            end
        end)
    end
end

function ShowParticleFx()
    -- ShowParticle
end

function SwordonBack(Sword, id)
    local HoldFlagID = GetPlayerFromServerId(id)
    local PedFlag = GetPlayerPed(HoldFlagID)
    local model = GetHashKey(Sword.Model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end
    handobj = CreateObject(model, GetEntityCoords(PedFlag), true, true, false)
    AttachEntityToEntity(handobj, PedFlag, GetPedBoneIndex(PedFlag, 24818),
        -1.20, -0.195, -0.217, -0.300, -80.700, 180.6, false,
        false, false, false, 2, true)
    SetModelAsNoLongerNeeded(model)
end

RegisterNetEvent('zc_sword_removeswordpickpCL')
AddEventHandler('zc_sword_removeswordpickpCL', function(id, ksword, pickerTeam)
    if GetPlayerServerId(PlayerId()) == id and pickerTeam and pickerTeam > 0 then
        MyTeam = pickerTeam
    end
    local sw = spawnedSwords[ksword]
    if not sw then return end
    DeleteEntity(sw.Sword)
    if sw.Point then MarkerHoldFlag(id) end
    if GetPlayerServerId(PlayerId()) == id then
        SwordonBack(sw, id)
        if sw.Point then
            Holdflagpoint(id)
        else
            if IsPedDeadOrDying(cache.ped) then
                HoldSkill = false
                if handobj then DeleteEntity(handobj) end
                handobj = nil
                return
            end
            local buffx = sw.Buff
            local timex = sw.Time
            local success = lib.progressBar({
                duration = 5000,
                label = 'Đang chờ hồi chiêu',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                },
            })
            if success then
                if not IsPedDeadOrDying(cache.ped) then
                    HoldflagSkill(id, buffx, timex)
                else
                    HoldSkill = false
                    if handobj then DeleteEntity(handobj) end
                    handobj = nil
                end
            end
        end
    end
    Wait(0)
    if sw.SwordCoord then sw.SwordCoord = nil end
    if sw.Point then sw.Point = nil end
end)

function SecondsToClock(seconds)
    local seconds = tonumber(seconds)
    if seconds <= 0 then
        return "00:00";
    else
        hours = string.format("%02.f", math.floor(seconds / 3600));
        mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)));
        secs = string.format("%02.f",
            math.floor(seconds - hours * 3600 - mins * 60));
        return mins .. ":" .. secs
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        pcall(function()
            if LocalPlayer and LocalPlayer.state then
                LocalPlayer.state:set('inSwordFlag', false, false)
            end
        end)
        if swordDeadUiShown and lib and lib.hideTextUI then
            lib.hideTextUI()
            swordDeadUiShown = false
            lastSwordDeadUiText = nil
        end
        if swordDeadNuiShown then
            SendNUIMessage({ type = 'SwordDeadHide' })
            swordDeadNuiShown = false
            lastSwordDeadSeconds = nil
        end
        if MyTeam then TriggerServerEvent('zcSword_SetDimension', 0) end
        inteam = false
        Changeback()
        if handobj then DeleteObject(handobj) end
        for k, v in pairs(spawnedSwords) do DeleteObject(v.Sword) end
        for k, v in pairs(usedSwords) do DeleteObject(v) end
    end
end)

function SendReactMessage(action, data, data2)
    SendNUIMessage({ type = action, data = data, data2 = data2 })
end

RegisterNetEvent('SendextratmyteamL')
AddEventHandler('SendextratmyteamL', function(MyTeamx, buffx, timex)
    if MyTeam == nil then return end
    if MyTeamx == MyTeam then
        if counttext > 0 then
            counttext = 0
            Wait(500)
        end

        if counttext == 0 then counttext = 400 end

        Text = '~w~ Đội của bạn ~g~ đã nhận được buff.'

        Citizen.CreateThread(function()
            while true do
                Wait(0)
                DrawText2D3(0.95, 1.38, 0.3, 1.0, 1.0, Text)
                counttext = counttext - 1
                if counttext <= 0 then
                    counttext = 0
                    break
                end
            end
        end)

        if buffx == 'Revive' then
            if SwordPlayerIsDown() then ReviveBuff() end
        elseif buffx == 'Heal' then
            if not IsPedDeadOrDying(cache.ped, 1) then
                SetEntityHealth(cache.ped, 200)
            end
        elseif buffx == 'Fast' then
            if not IsPedDeadOrDying(cache.ped, 1) then
                Runfast(timex)
            end
        elseif buffx == 'Armour' then
            if not IsPedDeadOrDying(cache.ped, 1) then
                SetPedArmour(cache.ped, 200)
            end
        end
    end
end)

function Runfast(timex)
    timerun = timerun + timex
    if not runfast then
        runfast = true
        SetPedMovementClipset(cache.ped, "MOVE_M@QUICK", true)
        SetPedMoveRateOverride(PlayerId(), 10.0)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
        while timerun > 0 do
            timerun = timerun - 1
            Wait(1000)
            if timerun <= 0 then
                timerun = 0
                runfast = false
                SetPedMoveRateOverride(PlayerId(), 1.0)
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                ResetPedMovementClipset(cache.ped)
            end
        end
    end
end

RegisterNetEvent('Sendattacktoenemy')
AddEventHandler('Sendattacktoenemy', function(xteam, buffx, timex)
    if not SwordStart then return end
    if xteam == nil then return end
    if MyTeam == xteam then
        if counttext > 0 then
            counttext = 0
            Wait(500)
        end
        if counttext == 0 then counttext = 400 end
        Text = '~w~ Đội của bạn ~r~ đã được tiếp sức.'
        Citizen.CreateThread(function()
            while true do
                Wait(0)
                DrawText2D3(0.95, 1.38, 0.3, 1.0, 1.0, Text)
                counttext = counttext - 1
                if counttext <= 0 then
                    counttext = 0
                    break
                end
            end
        end)
        if buffx == 'Freeze' then
            FreezeEntityPosition(cache.ped, true)
            AttachIce()
            Wait(timex * 1000)
            FreezeEntityPosition(cache.ped, false)
            DeleteIce()
        elseif buffx == 'Onfire' then
            StartEntityFire(cache.ped)
            Wait(timex * 1000)
            StopEntityFire(cache.ped)
        elseif buffx == 'Stunt' then
            if not IsPedDeadOrDying(cache.ped, 1) then
                PlayStunteffect()
                SetPedToRagdoll(cache.ped, timex * 1000, timex * 1000, 0, 0,
                    0, 0)
            end
        elseif buffx == 'Drunk' then
            if not IsPedDeadOrDying(cache.ped, 1) then
                SetPedDrunk(timex)
            end
        elseif buffx == 'SetCoord' then
            local xCoord = Config.TeamData[MyTeam].SpawnPoint
            local rnd = math.random(-5, 5)
            SetEntityCoords(cache.ped, xCoord.x + rnd, xCoord.y + rnd,
                xCoord.z + 2)
        end
    end
end)

function SetPedDrunk(timex)
    timedrunk = timedrunk + 10
    if not drunk then
        drunk = true
        SetTimecycleModifier("spectator5")
        SetPedMotionBlur(cache.ped, true)
        RequestAnimSet("move_m@drunk@verydrunk")

        while not HasAnimSetLoaded("move_m@drunk@verydrunk") do Wait(0) end

        SetPedMovementClipset(cache.ped, "move_m@drunk@verydrunk", true)
        Citizen.CreateThread(function()
            while timedrunk > 0 do
                Wait(4)
                DisableControlAction(0, 21, true)
            end
        end)

        while timedrunk > 0 do
            Wait(1000)
            timedrunk = timedrunk - 1
            if timedrunk <= 0 then
                ClearTimecycleModifier()
                ResetScenarioTypesEnabled()
                SetPedIsDrunk(cache.ped, false)
                SetPedMotionBlur(cache.ped, false)
                drunk = false
                timedrunk = 0
                ResetPedMovementClipset(cache.ped)
            end
        end
    end
end

RegisterNetEvent('zcSword_Reward')
AddEventHandler('zcSword_Reward',
    function(TeamBestScore, BestScore, dataReward, dataAccpet)
        if MyTeam == nil or MyTeam == 0 then return end
        if MyTeam == TeamBestScore then
            SendNUIMessage({
                type = 'Victory',
                TypeVictory = 'VICTORY',
                TypeText = 'Chiến thắng',
                VictoryTeam = Config.TeamData[TeamBestScore].TeamName,
                VictoryTeamColorBG = Config.TeamData[TeamBestScore].ColorBGSelect,
                VictoryTeamColor = Config.TeamData[TeamBestScore].ColorTeam,
                VictoryTeamScore = BestScore,
                VictoryItemReward = dataReward
            })
        else
            SendNUIMessage({
                type = 'Victory',
                TypeVictory = 'DEFEAT',
                TypeText = 'Thua cuộc',
                VictoryTeam = Config.TeamData[MyTeam].TeamName,
                VictoryTeamColorBG = Config.TeamData[MyTeam].ColorBGSelect,
                VictoryTeamColor = Config.TeamData[MyTeam].ColorTeam,
                VictoryTeamScore = BestScore,
                VictoryItemReward = dataAccpet
            })
        end
        Cancle()
    end)

function AttachIce() end

function DeleteIce() end

function PlayStunteffect() end

function DrawText2D3(x, y, scale, width, height, text)
    -- Dùng font mặc định của GTA để tránh lỗi Unicode/ô vuông
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(1.4, 1.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width / 2.3, y - height / 1 + 0.005)
end

function CheckFlag()
    if MyTeam then return true end
    return false
end
