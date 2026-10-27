SVTeam = {}
NumberofTeamx = 0
TeamScoreSv = {}
GetSword = {}
GetSword2 = {}
SwordCount = {}
TimeBuff = {}
MinusBuff = {}
itemList = {}
firsttime = false
dataAccpet = {}
SW = false
sudden = false
local Holdflag = {}
local PlayerEventTeam = {}
local reviveEligibleUntil = {}
local HoldFlagScoreThreadActive = {}
local Joinx = 0
local rewardIssued = false
local rewardProcessing = false
local roundStarted = false
local currentRoundId
local currentMode
local roundSequence = 0

local function IsAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src in pairs(PlayerEventTeam) do
        SetPlayerRoutingBucket(src, 0)
    end
end)


function CancleSV()
    for src in pairs(PlayerEventTeam) do
        reviveEligibleUntil[src] = os.time() + 15
    end
    for i = 1, NumberofTeamx do
        GlobalState["Score" .. i] = 0
        GlobalState["Buff" .. i] = 1
        GlobalState["holdflag" .. i] = 0
    end

    Holdflag = {}
    SVTeam = {}
    NumberofTeamx = 0
    TeamScoreSv = {}
    SwordCount = {}
    firsttime = false
    GlobalState.SwordTime = 0
    SVTeam = {}
    NumberofTeamx = 0
    TeamScoreSv = {}
    SwordCount = {}
    TimeBuff = {}
    MinusBuff = {}
    GetSword = {}
    GetSword2 = {}
    PlayerEventTeam = {}
    Joinx = 0
    rewardIssued = false
    rewardProcessing = false
    roundStarted = false
    currentRoundId = nil
    currentMode = nil
    HoldFlagScoreThreadActive = {}
    firsttime = false
    oldSwordCoord = nil
    flagpointsword = false
    buffx = nil
    Wait(2000)
    if sudden then
        TriggerClientEvent("zcSword_Cancle", -1)
        sudden = false
    end
    Wait(5000)
    SW = false
end

local function BeginEvent(mode, teamCount, duration, loserRewards, reservedByAdmin)
    if not SwordRewards.ready or (SW and not reservedByAdmin) then return false end
    if reservedByAdmin and (not SW or roundStarted or NumberofTeamx ~= 0) then return false end
    teamCount, duration = tonumber(teamCount), tonumber(duration)
    if (mode ~= 'Random' and mode ~= 'Select') or not teamCount or teamCount % 1 ~= 0
        or teamCount < 2 or teamCount > #Config.TeamData
        or not duration or duration <= 0 or type(loserRewards) ~= 'table' then
        return false
    end
    for _, reward in ipairs(loserRewards) do
        local count = tonumber(reward.count)
        if type(reward.name) ~= 'string' or not count or count < 1 or count % 1 ~= 0
            or not exports.ox_inventory:Items(reward.name) then return false end
    end

    SW = true
    sudden = false
    NumberofTeamx = teamCount
    currentMode = mode
    dataAccpet = loserRewards
    roundSequence = roundSequence + 1
    currentRoundId = ('%d-%d-%d'):format(os.time(), GetGameTimer(), roundSequence)
    local clock = os.date('!*t', os.time() + 7 * 3600)
    local hour = clock.hour % 12
    if hour == 0 then hour = 12 end
    local formattedTime = ('%d:%02d %s'):format(hour, clock.min, clock.hour >= 12 and 'PM' or 'AM')
    TriggerClientEvent('zcSword_Register', -1, mode, teamCount, formattedTime)
    StartCountDownSV(Config.JoinWaitSeconds, duration)
    return true
end

RegisterCommand(Config.Commands.startUI, function(src)
    if not IsAdmin(src) or SW then return end
    if not SwordRewards.ready then
        if src > 0 then AlertServer(src, 'SwordFlag chưa kết nối cơ sở dữ liệu.', 'error') end
        return
    end
    SW = true
    TriggerClientEvent('yip:cl:openmenuadmin', src, itemList)
end)

RegisterNetEvent('yip:sv:clear', function()
    if IsAdmin(source) and SW and NumberofTeamx == 0 and not roundStarted then SW = false end
end)

RegisterCommand(Config.Commands.stop, function(src)
    if not IsAdmin(src) or not SW or rewardProcessing then return end
    sudden = true
    CancleSV()
end)

RegisterCommand(Config.Commands.startNoUI, function(src, args)
    if not IsAdmin(src) then return end
    local teamCount = tonumber(args[2]) or 2
    teamCount = math.max(2, math.min(#Config.TeamData, math.floor(teamCount)))
    local duration = tonumber(args[3]) or Config.GameDurationMinutes
    if duration <= 0 then duration = Config.GameDurationMinutes end
    BeginEvent(args[1] == 'Select' and 'Select' or 'Random', teamCount,
        duration, Config.Rewards.Consolation, false)
end)

AddEventHandler('zcSword_Auto', function(mode, team, duration)
    BeginEvent(mode, team, duration, {}, false)
end)

RegisterNetEvent('yip:sv:startevent', function(mode, teamCount, duration, loserRewards)
    if not IsAdmin(source) then return end
    if not BeginEvent(mode, teamCount, duration, loserRewards or {}, true) then
        if SW and NumberofTeamx == 0 then SW = false end
        AlertServer(source, 'Thông số sự kiện không hợp lệ hoặc cơ sở dữ liệu chưa sẵn sàng.', 'error')
    end
end)

Citizen.CreateThread(function()
    local checkedMinute
    while true do
        local bangkok = os.date('!*t', os.time() + 7 * 3600)
        local minuteKey = ('%04d-%02d-%02d %02d:%02d'):format(
            bangkok.year, bangkok.month, bangkok.day, bangkok.hour, bangkok.min)
        if SwordRewards.ready and minuteKey ~= checkedMinute then
            checkedMinute = minuteKey
            local clockTime = ('%02d:%02d'):format(bangkok.hour, bangkok.min)
            for _, scheduledTime in ipairs(Config.Schedule) do
                if clockTime == scheduledTime then
                    local reserved, reason = SwordRewards.ReserveSlot(minuteKey)
                    if reason then
                        print(('[Zc_SwordFlag] Scheduled slot %s skipped: %s'):format(minuteKey, reason))
                    elseif reserved then
                        if BeginEvent(Config.ScheduledMode, Config.ScheduledTeamCount,
                            Config.GameDurationMinutes, {}, false) then
                            print(('[Zc_SwordFlag] Scheduled registration opened at %s Bangkok'):format(minuteKey))
                        else
                            print(('[Zc_SwordFlag] Scheduled slot %s skipped: another event is active'):format(minuteKey))
                        end
                    end
                end
            end
        end
        Wait(1000)
    end
end)

function StartCountDownSV(time, TimeEvent)
    local roundId = currentRoundId
    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            if not SW or currentRoundId ~= roundId or sudden then break end
            time = time - 1
            if time <= 0 then
                Wait(100)
                if not SW or currentRoundId ~= roundId or sudden then break end

                roundStarted = true
                TriggerClientEvent('zcSword_Start', -1)
                TriggerEvent('zcSword_CreateFlagProp')
                TriggerEvent('zcSword_CreateFirstProp')
                Wait(
                    Config.Server.startDelayBeforeTimerSeconds * 1000)
                if SW and currentRoundId == roundId and not sudden then
                    TriggerEvent('zcSword_StartSV', TimeEvent)
                end

                break
            end
            if sudden then break end
        end
    end)
end

RegisterNetEvent('zcSword_SelectTeam')
AddEventHandler('zcSword_SelectTeam', function(meSelectTeam)
    local _source = source
    if not SW or currentMode ~= 'Select' or roundStarted or PlayerEventTeam[_source] or type(meSelectTeam) ~= 'number'
        or meSelectTeam % 1 ~= 0 or meSelectTeam < 1 or meSelectTeam > NumberofTeamx then return end
    if SVTeam[meSelectTeam] == nil then
        SVTeam[meSelectTeam] = {}
        SVTeam[meSelectTeam] = 1
    elseif SVTeam[meSelectTeam] >=
        Config.MaxPlayersPerTeam then
        AlertServer(_source, 'Đội đã đủ người', 'error')
        return
    else
        SVTeam[meSelectTeam] = SVTeam[meSelectTeam] + 1
    end
    -- SetPlayerRoutingBucket(source, Config.Dimension)
    PlayerEventTeam[_source] = meSelectTeam
    reviveEligibleUntil[_source] = nil
    Joinx = Joinx + 1
    TriggerClientEvent('zcSword_AddTeamMember', _source, meSelectTeam)
    Wait(50)
    TriggerClientEvent('zcSword_AddTeamtoUI', -1, meSelectTeam)
end)

RegisterNetEvent('zcSword_SvRandomTeam')
AddEventHandler('zcSword_SvRandomTeam', function()
    local src = source
    if not SW or currentMode ~= 'Random' or roundStarted or PlayerEventTeam[src] or NumberofTeamx < 2 then return end
    local minimum = Config.MaxPlayersPerTeam
    local available = {}
    for team = 1, NumberofTeamx do
        local count = SVTeam[team] or 0
        if count < minimum then
            minimum = count
            available = { team }
        elseif count == minimum and count < Config.MaxPlayersPerTeam then
            available[#available + 1] = team
        end
    end
    if #available == 0 then
        AlertServer(src, 'Các đội đã đủ người.', 'error')
        return
    end
    local team = available[math.random(#available)]
    SVTeam[team] = (SVTeam[team] or 0) + 1
    PlayerEventTeam[src] = team
    reviveEligibleUntil[src] = nil
    Joinx = Joinx + 1
    TriggerClientEvent('zcSword_AddTeamMember', src, team)
    Wait(50)
    TriggerClientEvent('zcSword_AddTeamtoUI', -1, team)
end)

RegisterNetEvent('zcSword_SetDimension')
AddEventHandler('zcSword_SetDimension', function(miti)
    local _source = source
    if miti ~= 0 and (miti ~= Config.Dimension or not PlayerEventTeam[_source]) then return end
    SetPlayerRoutingBucket(_source, miti)
end)

RegisterNetEvent('zcSword_RequestRevive', function()
    local src = source
    local recentlyJoined = reviveEligibleUntil[src] and reviveEligibleUntil[src] >= os.time()
    if not ((SW and roundStarted and PlayerEventTeam[src]) or recentlyJoined) then return end
    if not exports.qbx_core:GetPlayer(src) then return end
    exports.qbx_medical:Revive(src)
end)

function StartActivityTimeSV(time)
    local roundId = currentRoundId
    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            if not SW or currentRoundId ~= roundId or sudden then break end
            time = time - 1
            GlobalState.SwordTime = time
            if time <= 0 then
                TriggerEvent('zcSword_EndSV')
                while rewardProcessing do Wait(100) end
                Wait(2000)
                TriggerClientEvent('zcSword_End', -1)
                CancleSV()
                break
            end
            if Joinx <=
                Config.CancelIfPlayersLessOrEqual then
                print('Not Enough Player')
                TriggerClientEvent('zcSword_End', -1)
                CancleSV()
                break
            end

        end
    end)
end

RegisterNetEvent('zcSword_CreateFlagProp')
AddEventHandler('zcSword_CreateFlagProp', function()
    Wait(5000)
    local FlagInBox = 0
    local FlagCoord = {}
    while FlagInBox < NumberofTeamx - Config.MinusFlagSword do
        Wait(1000)

        local rnd = math.random(1, 100)
        FlagInBox = FlagInBox + 1
        local randomCoord = Config.StartPoint -- v.Coord[math.random(#v.Coord)]
        local truecoord = vector3(randomCoord.x +
                                      (math.random(
                                          -1 * (Config.Distance -
                                              Config.SwordOutOfBoundsPadding),
                                          (Config.Distance -
                                              Config.SwordOutOfBoundsPadding))),
                                  randomCoord.y +
                                      (math.random(
                                          -1 * (Config.Distance -
                                              Config.SwordOutOfBoundsPadding),
                                          (Config.Distance -
                                              Config.SwordOutOfBoundsPadding))),
                                  randomCoord.z)
        if FlagCoord[truecoord] == nil then
            FlagCoord[truecoord] = true
        else
            FlagInBox = FlagInBox - 1
            return
        end

        TriggerClientEvent('zcSword_SpawnFlagSword', -1, Config.FlagSword,
                           truecoord)
    end
    FlagCoord = {}
end)

RegisterNetEvent('zcSword_CreateFirstProp')
AddEventHandler('zcSword_CreateFirstProp', function()
    Wait(5000)
    local SwordInBox = 0
    local selectedSwords = {}
    local AvailableSwords = {}
    local SwordCoord = {}

    while SwordInBox < Config.MaxSword do
        Wait(1000)

        for k, v in pairs(Config.Sword) do
            Wait(Config.SwordSpawnIntervalMs)
            local rnd = math.random(1, 100)
            if rnd <= v.Percent then
                local spawnpercent = math.random(1, 100)
                if spawnpercent > 50 then
                    SwordInBox = SwordInBox + 1
                    local randomCoord = Config.StartPoint -- v.Coord[math.random(#v.Coord)]

                    local truecoord = vector3(randomCoord.x +
                                                  (math.random(
                                                      -1 * (Config.Distance -
                                                          Config.SwordOutOfBoundsPadding),
                                                      (Config.Distance -
                                                          Config.SwordOutOfBoundsPadding))),
                                              randomCoord.y +
                                                  (math.random(
                                                      -1 * (Config.Distance -
                                                          Config.SwordOutOfBoundsPadding),
                                                      (Config.Distance -
                                                          Config.SwordOutOfBoundsPadding))),
                                              randomCoord.z)
                    if SwordCoord[truecoord] == nil then
                        SwordCoord[truecoord] = true
                    else
                        SwordInBox = SwordInBox - 1
                        return
                    end
                    if SwordInBox <= Config.MaxSword then
                        TriggerClientEvent('zcSword_SpawnSword', -1, k,
                                           truecoord)
                    end
                end
            end
        end
    end
    SwordCoord = {}
end)

AddEventHandler('playerDropped', function()
    local _source = source
    local team = PlayerEventTeam[_source]
    if team then
        SVTeam[team] = math.max(0, (SVTeam[team] or 0) - 1)
        Joinx = math.max(0, Joinx - 1)
    end
    PlayerEventTeam[_source] = nil
    reviveEligibleUntil[_source] = nil
    if Holdflag[_source] ~= nil then
        if Holdflag[_source].Hold == true then

            TriggerClientEvent('zcSword_SpawnFlagSword', -1, nil, nil)
            local t = Holdflag[_source].Team
            if t then
                GlobalState["holdflag" .. t] =
                    math.max(0, (GlobalState["holdflag" .. t] or 0) - 1)
            end
        end
        Holdflag[_source] = nil
    end
end)

RegisterNetEvent('zcSword_HoldflagAddscore')
AddEventHandler('zcSword_HoldflagAddscore', function(MyTeam, Drop, Coords)
    local _source = source
    if not SW or not roundStarted or PlayerEventTeam[_source] ~= MyTeam then return end
    if type(MyTeam) ~= 'number' or MyTeam < 1 then return end

    -- Drop / death: second arg is not nil (e.g. false from client)
    if Drop ~= nil then
        local hf = Holdflag[_source]
        if not hf then return end
        local team = hf.Team or MyTeam
        GlobalState['holdflag' .. team] =
            math.max(0, (GlobalState['holdflag' .. team] or 0) - 1)
        Holdflag[_source] = nil
        TriggerClientEvent('zcSword_SpawnFlagSword', -1, nil, Coords)
        return
    end

    -- Start holding flag: only one Holdflag entry per player; only bump counter once
    if Holdflag[_source] ~= nil then return end

    Holdflag[_source] = {Hold = true, Team = MyTeam}
    GlobalState['holdflag' .. MyTeam] =
        (GlobalState['holdflag' .. MyTeam] or 0) + 1

    if HoldFlagScoreThreadActive[MyTeam] then return end
    HoldFlagScoreThreadActive[MyTeam] = true
    Citizen.CreateThread(function()
        local team = MyTeam
        while (GlobalState['holdflag' .. team] or 0) > 0 do
            Wait(1000)
            if not GlobalState['holdflag' .. team] or
                GlobalState['holdflag' .. team] <= 0 then break end
            GlobalState['Score' .. team] =
                (GlobalState['Score' .. team] or 0) +
                    (Config.ScorePerSecondHoldingFlag *
                        (GlobalState['Buff' .. team] or 1) *
                        GlobalState['holdflag' .. team])
            if GlobalState['holdflag' .. team] <= 0 then break end
        end
        HoldFlagScoreThreadActive[team] = false
    end)
end)

RegisterNetEvent('zc_sword_removeswordpickp')
AddEventHandler('zc_sword_removeswordpickp',
                function(ks, SwordCoord, flagpointsword)
    local _source = source
    if SwordCoord == nil then
        print(('[Zc_SwordFlag] zc_sword_removeswordpickp: SwordCoord nil (src=%s, ks=%s, flag=%s)'):format(
            tostring(_source), tostring(ks), tostring(flagpointsword)))
        return
    end
    if flagpointsword then
        if not GetSword[SwordCoord] then
            GetSword[SwordCoord] = true
            TriggerClientEvent('zc_sword_removeswordpickpCL', -1, _source, ks,
                               PlayerEventTeam[_source])
            Wait(
                Config.Server.debugClearSwordFromCoordMs)
            GetSword[SwordCoord] = nil
            return
        end
    end

    if not flagpointsword then
        if not GetSword2[SwordCoord] then
            GetSword2[SwordCoord] = true
            Citizen.CreateThread(function()
                Wait(
                    Config.Server.debugClearSwordFromCoordMs)
                GetSword2[SwordCoord] = nil
            end)

            TriggerClientEvent('zc_sword_removeswordpickpCL', -1, _source, ks,
                               PlayerEventTeam[_source])
            Wait(
                Config.NewSwordRespawnSeconds * 1000)
            spwanone = math.random(1, #Config.Sword)
            local randomCoord = Config.StartPoint
            local truecoord = vector3(randomCoord.x +
                                          (math.random(
                                              -1 * (Config.Distance -
                                                  Config.SwordOutOfBoundsPadding),
                                              (Config.Distance -
                                                  Config.SwordOutOfBoundsPadding))),
                                      randomCoord.y +
                                          (math.random(
                                              -1 * (Config.Distance -
                                                  Config.SwordOutOfBoundsPadding),
                                              (Config.Distance -
                                                  Config.SwordOutOfBoundsPadding))),
                                      randomCoord.z)

            TriggerClientEvent('zcSword_SpawnSword', -1, spwanone, truecoord)

        end
    end
end)

RegisterNetEvent('zcSword_DropFlag')
AddEventHandler('zcSword_DropFlag', function(MyTeam, Coords) end)

AddEventHandler('zcSword_StartSV', function(TimeEvent)
    rewardIssued = false
    local TimeInGame = 0
    if TimeEvent ~= nil then
        TimeInGame = TimeEvent * 60
    else
        TimeInGame = Config.GameDurationMinutes * 60
    end

    for i = 1, NumberofTeamx do
        GlobalState["Score" .. i] = 0
        GlobalState["Buff" .. i] = 1
        GlobalState["holdflag" .. i] = 0
        GlobalState["Minus" .. i] = 1
    end
    GlobalState.SwordTime = TimeInGame

    StartActivityTimeSV(TimeInGame)
end)

RegisterNetEvent('zcSword_useSkill')
AddEventHandler('zcSword_useSkill', function(MyTeam, xteam, buffx, timex)
    if buffx == 'Freeze' or buffx == 'Onfire' or buffx == 'Stunt' or buffx ==
        'Drunk' or buffx == 'SetCoord' then
        TriggerClientEvent('Sendattacktoenemy', -1, xteam, buffx, timex)
    elseif buffx == 'Fast' or buffx == 'Revive' or buffx == 'Heal' or buffx ==
        'Armour' then
        TriggerClientEvent('SendextratmyteamL', -1, MyTeam, buffx, timex)
    elseif buffx == 'X3' or buffx == 'X2' then
        Xbuff(MyTeam, xteam, buffx, timex)
    elseif buffx == 'MinusPoint' then
        xMinus(MyTeam, xteam, buffx, timex)
    end
end)

function xMinus(MyTeam, xteam, buffx, timex)

    if MinusBuff[xteam] == nil then MinusBuff[xteam] = {} end
    if MinusBuff[xteam].xtime == nil then MinusBuff[xteam].xtime = 0 end
    if not MinusBuff[xteam].loop then
        MinusBuff[xteam].xtime = timex
    else
        MinusBuff[xteam].xtime = MinusBuff[xteam].xtime + timex
    end
    if not MinusBuff[xteam].loop then
        MinusBuff[xteam].loop = true
        GlobalState["Minus" .. xteam] = 2
        Citizen.CreateThread(function()
            local minusTeam = xteam
            while MinusBuff[minusTeam] and MinusBuff[minusTeam].xtime > 0 do
                Wait(1000)
                if not MinusBuff[minusTeam] then break end

                if GlobalState["Score" .. minusTeam] > 0 then
                    GlobalState["Score" .. minusTeam] =
                        GlobalState["Score" .. minusTeam] - Config.MinusPoint
                end
                MinusBuff[minusTeam].xtime = MinusBuff[minusTeam].xtime - 1
                if MinusBuff[minusTeam].xtime <= 0 then
                    MinusBuff[minusTeam].loop = nil
                    MinusBuff[minusTeam].xtime = 0
                    GlobalState["Minus" .. minusTeam] = 1
                    break
                end
                if sudden then break end
            end
        end)
    end

end

function Xbuff(MyTeam, xteam, buffx, timex)
    if TimeBuff[MyTeam] == nil then TimeBuff[MyTeam] = {} end
    if TimeBuff[MyTeam].xtime == nil then TimeBuff[MyTeam].xtime = 0 end
    if GlobalState["Buff" .. MyTeam] == 1 then
        if buffx == 'X2' then
            TimeBuff[MyTeam].xtime = TimeBuff[MyTeam].xtime + timex
            GlobalState["Buff" .. MyTeam] = 2
        elseif buffx == 'X3' then
            TimeBuff[MyTeam].xtime = TimeBuff[MyTeam].xtime + timex
            GlobalState["Buff" .. MyTeam] = 3
        end
    elseif GlobalState["Buff" .. MyTeam] == 2 then
        if buffx == 'X2' then
            TimeBuff[MyTeam].xtime = TimeBuff[MyTeam].xtime + timex
        elseif buffx == 'X3' then
            TimeBuff[MyTeam].xtime = timex
            GlobalState["Buff" .. MyTeam] = 3
        end
    elseif GlobalState["Buff" .. MyTeam] == 3 then
        if buffx == 'X2' then
            return
        elseif buffx == 'X3' then
            TimeBuff[MyTeam].xtime = TimeBuff[MyTeam].xtime + timex
        end
    end
    if not TimeBuff[MyTeam].loop then
        TimeBuff[MyTeam].loop = true
        Citizen.CreateThread(function()
            local teamId = MyTeam
            -- CancleSV() replaces TimeBuff = {}; guard so async loop never indexes nil.
            while TimeBuff[teamId] and TimeBuff[teamId].xtime > 0 do
                Wait(1000)
                if not TimeBuff[teamId] then break end
                TimeBuff[teamId].xtime = TimeBuff[teamId].xtime - 1
                if TimeBuff[teamId].xtime <= 0 then
                    TimeBuff[teamId].loop = nil
                    TimeBuff[teamId].xtime = 0
                    GlobalState["Buff" .. teamId] = 1
                    break
                end
                if sudden then break end
            end
        end)
    end
end

AddEventHandler('zcSword_EndSV', function()
    if not SW or not roundStarted or rewardIssued or not currentRoundId then return end
    rewardIssued = true
    rewardProcessing = true
    local roundId = currentRoundId
    local winningTeam, winningScore = BestScore()
    for src, team in pairs(PlayerEventTeam) do
        if team == winningTeam and winningTeam ~= 0 then
            local ok, err = pcall(SwordRewards.Grant, src, roundId, Config.Rewards.WinnerDefault)
            if not ok then print(('[Zc_SwordFlag] Winner payout failed: %s'):format(tostring(err))) end
        elseif #dataAccpet > 0 then
            local ok, err = pcall(SwordRewards.Grant, src, roundId, dataAccpet)
            if not ok then print(('[Zc_SwordFlag] Loser payout failed: %s'):format(tostring(err))) end
        end
    end
    TriggerClientEvent('zcSword_Reward', -1, winningTeam, winningScore,
        Config.Rewards.WinnerDefault, dataAccpet)
    rewardProcessing = false
end)

function BestScore()
    local BestScore = 0
    local TeamBestScore = 0

    for i = 1, NumberofTeamx do
        local score = GlobalState["Score" .. i]
        if score > BestScore then
            BestScore = score
            TeamBestScore = i
        end
    end

    return TeamBestScore, BestScore
end

