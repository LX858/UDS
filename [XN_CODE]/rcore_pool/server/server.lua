
Tables = {}
PoolCueTable = {}

RegisterCommand("showrcorepool", function(source)
    if source == 0 then
        print(">> Cue data")
        tprint(PoolCueTable)
        print("")
        print(">> Table data")
        tprint(Tables)
    end
end, true)

RegisterNetEvent('rcore_pool:setTableState')
AddEventHandler('rcore_pool:setTableState', function(eventData)
    eventData.tablePosition = vector3(eventData.tablePosition.x, eventData.tablePosition.y, eventData.tablePosition.z)

    local serverIds      = eventData.serverIds
    eventData.serverIds  = nil

    local senderSource   = source
    local tablePosition  = eventData.tablePosition
    local ballData       = eventData.data
    local tableAddress   = positionToTableAddress(senderSource, tablePosition)

    if Tables[tableAddress] and Tables[tableAddress].player then
        return
    end

    if Config.PayForSettingBalls then
        if PlayerHasMoney(senderSource, Config.BallSetupCost) then
            PlayerTakeMoney(senderSource, Config.BallSetupCost)
            SetBallsForFirstTime(serverIds, tableAddress, tablePosition, ballData)
            SendMoneyToSociety(tablePosition, Config.BallSetupCost)
        else
            local notEnoughText = Config.Text.NOT_ENOUGH_MONEY or "You don't have $%s to setup this table."
            SendNotification(senderSource, string.format(notEnoughText, Config.BallSetupCost))
        end
    else
        SetBallsForFirstTime(serverIds, tableAddress, tablePosition, ballData)
    end
end)

function SendMoneyToSociety(tablePosition, amount)
    if not Config.PayToSociety then return end

    for _, entry in pairs(Config.PayToSociety) do
        if #(entry.poolTableCoords - tablePosition) < 5.0 then
            AddSocietyMoney(entry.society, amount)
        end
    end
end

function SetBallsForFirstTime(serverIds, tableAddress, tablePosition, ballData)
    Tables[tableAddress] = {
        tablePos   = tablePosition,
        cueBallIdx = ballData.cueBallIdx,
        balls      = ballData.balls,
        pastPlayers = {},
    }

    for _, serverId in pairs(serverIds) do
        SyncTableState(serverId, tableAddress)
    end
end

RegisterNetEvent('rcore_pool:internalPlayerHasTakenCue')
AddEventHandler('rcore_pool:internalPlayerHasTakenCue', function(coords)
    local cuePos = vector3(coords.x, coords.y, coords.z)
    local playerId = source

    TriggerEvent('rcore_pool:playerHasTakenCue', playerId)
    PoolCueTable[playerId] = cuePos
    TriggerEvent('rcore_pool:onTakeCue', playerId)
end)

RegisterNetEvent('rcore_pool:internalDeleteCue')
AddEventHandler('rcore_pool:internalDeleteCue', function()
    DeletePoolCueIfExists(source)
end)

RegisterNetEvent('rcore_pool:releaseControl')
AddEventHandler('rcore_pool:releaseControl', function(tableAddress, serverIds)
    local playerId = source

    if not Tables[tableAddress] then return end
    if Tables[tableAddress].player ~= playerId then return end

    Tables[tableAddress].player = nil

    for _, serverId in pairs(serverIds) do
        SyncTableState(serverId, tableAddress)
    end
end)

RegisterNetEvent('rcore_pool:syncFinalTableState')
AddEventHandler('rcore_pool:syncFinalTableState', function(tableAddress, finalBalls, serverIds)
    local playerId = source

    if not Tables[tableAddress] then return end
    if Tables[tableAddress].player ~= playerId then return end

    Tables[tableAddress].player = nil
    Tables[tableAddress].balls  = finalBalls

    for _, serverId in pairs(serverIds) do
        SyncTableState(serverId, tableAddress)
    end
end)

RegisterNetEvent('rcore_pool:syncCueBallVelocity')
AddEventHandler('rcore_pool:syncCueBallVelocity', function(serverIds, tableAddress, cueBallPos, cueBallVel, hitStrength)
    cueBallPos = vector2(cueBallPos.x, cueBallPos.y)
    cueBallVel = vector2(cueBallVel.x, cueBallVel.y)

    local playerId = source

    if not Tables[tableAddress] then return end
    if Tables[tableAddress].player ~= playerId then return end

    local cueBallIdx = Tables[tableAddress].cueBallIdx
    Tables[tableAddress].balls[cueBallIdx].velocity = cueBallVel
    Tables[tableAddress].balls[cueBallIdx].position = cueBallPos

    for _, serverId in pairs(serverIds) do
        SyncTableState(serverId, tableAddress, tableAddress, hitStrength)
    end
end)

RegisterNetEvent('rcore_pool:setBallInHandData')
AddEventHandler('rcore_pool:setBallInHandData', function(serverIds, tableAddress, newPosition)
    newPosition = vector2(newPosition.x, newPosition.y)

    local playerId = source

    if not Tables[tableAddress] then return end
    if Tables[tableAddress].player ~= playerId then return end

    local cueBallIdx = Tables[tableAddress].cueBallIdx
    Tables[tableAddress].balls[cueBallIdx].disabled  = false
    Tables[tableAddress].balls[cueBallIdx].position  = newPosition

    for _, serverId in pairs(serverIds) do
        if serverId ~= playerId then
            SyncTableState(serverId, tableAddress)
        end
    end
end)

RegisterNetEvent('rcore_pool:pocketed')
AddEventHandler('rcore_pool:pocketed', function(tableAddress, ballNum, nearbyServerIds)
    local playerId = source

    if not Tables[tableAddress] then return end
    if Tables[tableAddress].lastPlayer ~= playerId then return end

    local ballLabel   = Config.Text.BALL_LABELS[ballNum]
    local notifyText  = string.format(Config.Text.BALL_POCKETED, ballLabel)

    for _, serverId in pairs(nearbyServerIds) do
        if Config.UseFrameworkNotification then
            if IsClose(Tables[tableAddress].tablePos, serverId) then
                SendNotification(serverId, notifyText)
            end
        else
            TriggerClientEvent('rcore_pool:internalNotification', serverId, playerId, tableAddress, notifyText)
        end
    end
end)

RegisterNetEvent('rcore_pool:ballInHandNotify')
AddEventHandler('rcore_pool:ballInHandNotify', function(serverIds, tableAddress)
    local playerId = source

    if not Tables[tableAddress] then return end
    if Tables[tableAddress].lastPlayer ~= playerId then return end

    local notifyText = Config.Text.BALL_IN_HAND_NOTIFY

    for _, serverId in pairs(serverIds) do
        if Config.UseFrameworkNotification then
            if IsClose(Tables[tableAddress].tablePos, serverId) then
                SendNotification(serverId, notifyText)
            end
        else
            TriggerClientEvent('rcore_pool:internalNotification', serverId, playerId, tableAddress, notifyText)
        end
    end
end)

function IsClose(tablePos, serverId)
    local ped = GetPlayerPed(serverId)
    local dist = #(tablePos - GetEntityCoords(ped))
    return dist < Config.NotificationDistance
end

AddEventHandler('playerDropped', function()
    local playerId = source
    DeletePoolCueIfExists(playerId)

    for tableAddress, tableData in pairs(Tables) do
        if tableData and tableData.player == playerId then
            tableData.player = nil
            SyncTableState(-1, tableAddress)
        end
    end
end)
