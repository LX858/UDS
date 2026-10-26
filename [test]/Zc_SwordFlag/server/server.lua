SVTeam = {}
currentTeam = 0
NumberofTeamx = 0
TeamScoreSv = {}
GetSword = {}
GetSword2 = {}
SwordCount = {}
TimeBuff = {}
MinusBuff = {}
itemList = {}
firsttime = false
dataReward = {}
dataAccpet = {}
SW = false
sudden = false
local Holdflag = {}
local PlayerEventTeam = {}
local reviveEligibleUntil = {}
local HoldFlagScoreThreadActive = {}
local Joinx = 0
autoeventxReward = false
autoeventxAccpets = false
local rewardIssued = false
local roundStarted = false

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
    currentTeam = 0
    NumberofTeamx = 0
    TeamScoreSv = {}
    SwordCount = {}
    firsttime = false
    GlobalState.SwordTime = 0
    SW = false
    SVTeam = {}
    currentTeam = 0
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
    roundStarted = false
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
    autoeventxReward = false
    autoeventxAccpets = false
end

RegisterCommand(
    Config.Commands.startUI,
    function(src, args)
        local _source = src
        if IsAdmin(_source) then
            if SW then return end
            if not SW then
                SW = true
                TriggerClientEvent("yip:cl:openmenuadmin", _source, itemList)
            end
        end
    end)

RegisterNetEvent('yip:sv:clear')
AddEventHandler('yip:sv:clear', function()
    if IsAdmin(source) then SW = false end
end)

RegisterCommand(Config.Commands.stop, function(src, args)
    local _source = src
    if IsAdmin(_source) then

        if SW then
            sudden = true

            CancleSV()
        end
    end
end)

RegisterCommand(
    Config.Commands.startNoUI,
    function(src, args)
        local _source = src
        if IsAdmin(_source) then
            if not SW then
                SW = true
                args[2] = tonumber(args[2])
                if args[2] == nil or args[2] <= 1 then
                    NumberofTeamx = 2
                elseif args[2] > #Config.TeamData then
                    NumberofTeamx = #Config.TeamData
                else
                    NumberofTeamx = args[2]

                end
                local current_time = os.date('%H:%M')
                local hour, minute = current_time:match("(%d+):(%d+)")
                hour = tonumber(hour)

                local period = "AM"
                if hour >= 12 then period = "PM" end

                if hour > 12 then hour = hour - 12 end

                local formatted_time = string.format("%d:%s %s", hour, minute,
                                                     period)
                if args[1] == nil then
                    TriggerClientEvent("zcSword_Register", -1, 'Random',
                                       NumberofTeamx, formatted_time)
                elseif args[1] == 'Random' then
                    TriggerClientEvent("zcSword_Register", -1, 'Random',
                                       NumberofTeamx, formatted_time)

                elseif args[1] == 'Select' then
                    TriggerClientEvent("zcSword_Register", -1, 'Select',
                                       NumberofTeamx, formatted_time)
                else
                    TriggerClientEvent("zcSword_Register", -1, 'Random',
                                       NumberofTeamx, formatted_time)
                end
                dataReward = Config.Rewards.WinnerDefault
                dataAccpet = Config.Rewards.Consolation
                autoeventxReward = true
                autoeventxAccpets = true
                TimeEvent = tonumber(args[3]) or Config.GameDurationMinutes
                if TimeEvent <= 0 then TimeEvent = Config.GameDurationMinutes end
                StartCountDownSV(Config.JoinWaitSeconds, TimeEvent)
            end
        end
    end)

AddEventHandler('zcSword_Auto', function(mode, team, Time)
    team = tonumber(team)
    Time = tonumber(Time)
    if not team or team < 2 or team > #Config.TeamData or team % 1 ~= 0
        or not Time or Time <= 0 then return end
    if not SW then
        SW = true
        local current_time = os.date('%H:%M')
        local hour, minute = current_time:match("(%d+):(%d+)")
        hour = tonumber(hour)
        local period = "AM"
        if hour >= 12 then period = "PM" end
        if hour > 12 then hour = hour - 12 end
        local formatted_time = string.format("%d:%s %s", hour, minute, period)
        --------
        local TimeEvent = Time
        NumberofTeamx = team
        dataReward = Config.Rewards.WinnerDefault
        dataAccpet = Config.Rewards.Consolation
        autoeventxReward = true
        autoeventxAccpets = true
        TriggerClientEvent("zcSword_Register", -1, mode, team, formatted_time)
        StartCountDownSV(Config.JoinWaitSeconds, TimeEvent)
    end
end)

RegisterServerEvent('yip:sv:startevent')
AddEventHandler('yip:sv:startevent',
                function(dataType, CountTeam, TimeEvent, dataRewards,
                         dataAccpets)
    if not IsAdmin(source) or not SW or roundStarted or NumberofTeamx > 0 then return end
    CountTeam = tonumber(CountTeam)
    TimeEvent = tonumber(TimeEvent)
    if not CountTeam or CountTeam < 2 or CountTeam > #Config.TeamData or CountTeam % 1 ~= 0
        or not TimeEvent or TimeEvent <= 0
        or type(dataRewards) ~= 'table' or type(dataAccpets) ~= 'table' then
        SW = false
        AlertServer(source, 'Thông số sự kiện không hợp lệ.', 'error')
        return
    end
    if #dataRewards == 0 then
        dataRewards = Config.Rewards.WinnerDefault
        autoeventxReward = true
    end
    if #dataAccpets == 0 then
        dataAccpets = Config.Rewards.Consolation
        autoeventxAccpets = true
    end
    dataReward = dataRewards
    dataAccpet = dataAccpets
    NumberofTeamx = CountTeam
    local current_time = os.date('%H:%M')
    local hour, minute = current_time:match("(%d+):(%d+)")
    hour = tonumber(hour)

    local period = "AM"
    if hour >= 12 then period = "PM" end

    if hour > 12 then hour = hour - 12 end

    local formatted_time = string.format("%d:%s %s", hour, minute, period)
    TriggerClientEvent("zcSword_Register", -1, dataType, NumberofTeamx,
                       formatted_time)
    StartCountDownSV(Config.JoinWaitSeconds, TimeEvent)

end)

function StartCountDownSV(time, TimeEvent)

    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            time = time - 1
            if time <= 0 then
                Wait(100)

                roundStarted = true
                TriggerClientEvent('zcSword_Start', -1)
                TriggerEvent('zcSword_CreateFlagProp')
                TriggerEvent('zcSword_CreateFirstProp')
                Wait(
                    Config.Server.startDelayBeforeTimerSeconds * 1000)
                TriggerEvent('zcSword_StartSV', TimeEvent)

                break
            end
            if sudden then break end
        end
    end)
end

RegisterNetEvent('zcSword_SelectTeam')
AddEventHandler('zcSword_SelectTeam', function(meSelectTeam)
    local _source = source
    if not SW or roundStarted or PlayerEventTeam[_source] or type(meSelectTeam) ~= 'number'
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
AddEventHandler('zcSword_SvRandomTeam', function(NumberofTeam)
    local _source = source
    if not SW or roundStarted or PlayerEventTeam[_source] or NumberofTeamx < 1 then return end
    NumberofTeam = NumberofTeamx
    local allTeamsFull = true
    for teamIndex = 1, NumberofTeam do
        if SVTeam[teamIndex] == nil or SVTeam[teamIndex] <
            Config.MaxPlayersPerTeam then
            allTeamsFull = false
            break
        end
    end

    if allTeamsFull then
        -- NotifySv('Đã đủ người, không thể tham gia')
    else

        while true do
            currentTeam = currentTeam + 1
            if currentTeam > NumberofTeam then currentTeam = 1 end
            if SVTeam[currentTeam] == nil or SVTeam[currentTeam] <
                Config.MaxPlayersPerTeam then
                if SVTeam[currentTeam] == nil then
                    SVTeam[currentTeam] = 1
                else
                    SVTeam[currentTeam] = SVTeam[currentTeam] + 1
                end

                PlayerEventTeam[_source] = currentTeam
                reviveEligibleUntil[_source] = nil
                Joinx = Joinx + 1
                TriggerClientEvent('zcSword_AddTeamMember', _source, currentTeam)
                Wait(50)
                TriggerClientEvent('zcSword_AddTeamtoUI', -1, currentTeam)

                break
            end
            if sudden then break end
        end
    end
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
    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            time = time - 1
            GlobalState.SwordTime = time
            if time <= 0 then
                TriggerEvent('zcSword_EndSV')
                Wait(2000)
                TriggerClientEvent('zcSword_End', -1)
                CancleSV()
                break
            end
            if sudden then break end
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
            if sudden then break end
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

local function GrantReward(src, rewards, useRanges)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    for _, reward in pairs(rewards or {}) do
        local item = reward.name
        local count = reward.count
        if useRanges and type(count) == 'table' then
            local minimum, maximum = tonumber(count[1]), tonumber(count[2])
            if minimum and maximum and minimum >= 1 and maximum >= minimum then
                count = math.random(math.floor(minimum), math.floor(maximum))
            end
        end
        count = tonumber(count)
        if type(item) == 'string' and count and count >= 1 and count % 1 == 0
            and exports.ox_inventory:Items(item) then
            local success, response = exports.ox_inventory:AddItem(src, item, count)
            if success then
                print(('[Zc_SwordFlag] Reward %s (%s): %s x%d'):format(
                    GetPlayerName(src) or 'unknown', player.PlayerData.citizenid, item, count))
            else
                print(('[Zc_SwordFlag] Cannot give %s x%d to %s: %s'):format(
                    item, count, src, tostring(response)))
                exports.qbx_core:Notify(src, 'Không thể nhận phần thưởng ' .. item .. ' (kiểm tra túi đồ).', 'error', 5000)
            end
        else
            print(('[Zc_SwordFlag] Invalid reward item/count: %s / %s'):format(
                tostring(item), tostring(count)))
        end
    end
end

AddEventHandler('zcSword_EndSV', function()
    if rewardIssued then return end
    rewardIssued = true
    local TeamBestScore, BestScore = BestScore()
    for src, team in pairs(PlayerEventTeam) do
        if team == TeamBestScore and TeamBestScore ~= 0 then
            GrantReward(src, dataReward, autoeventxReward)
        else
            GrantReward(src, dataAccpet, autoeventxAccpets)
        end
    end
    TriggerClientEvent('zcSword_Reward', -1, TeamBestScore, BestScore,
                       dataReward, dataAccpet)
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

