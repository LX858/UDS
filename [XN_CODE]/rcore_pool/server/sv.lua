
Citizen.CreateThread(function()
    while true do
        Wait(5000)

        for playerId, cuePos in pairs(PoolCueTable) do
            DeleteCueIfPlayerTooFar(playerId, cuePos)
            Wait(250)
        end
    end
end)

function DeleteCueIfPlayerTooFar(playerId, cuePos)
    Citizen.CreateThread(function()
        local ped      = GetPlayerPed(playerId)
        local pedCoords = GetEntityCoords(ped)

        if #(pedCoords - cuePos) > 30.0 then
            DeletePoolCueIfExists(playerId)
        end
    end)
end

function DeletePoolCueIfExists(playerId)
    if not PoolCueTable[playerId] then return end

    Player(playerId).state.hasPoolCue = nil
    TriggerEvent('rcore_pool:onReturnCue', playerId)
    PoolCueTable[playerId] = nil
end

function tprint(data, indent)
    indent = indent or 0

    if type(data) == "table" then
        for key, value in pairs(data) do
            local prefix = string.rep("  ", indent) .. key .. ": "

            if type(value) == "table" then
                print(prefix)
                tprint(value, indent + 1)
            elseif type(value) == "boolean" then
                print(prefix .. tostring(value))
            else
                print(prefix .. value)
            end
        end
    else
        print(data)
    end
end

function positionToTableAddress(playerId, pos)
    local xRounded = math.floor(pos.x * 10) / 10
    local yRounded = math.floor(pos.y * 10) / 10

    local bucketPrefix = ""
    if Config.UseBuckets then
        bucketPrefix = GetPlayerRoutingBucket(playerId) .. "/"
    end

    return bucketPrefix .. xRounded .. "/" .. yRounded
end

function SyncTableState(clientId, tableAddress, isCueBallHit, hitStrength)
    TriggerClientEvent('rcore_pool:syncTableState', clientId, tableAddress, Tables[tableAddress], isCueBallHit, hitStrength)
end

RegisterNetEvent('rcore_pool:requestTurn')
AddEventHandler('rcore_pool:requestTurn', function(tableAddress, serverIds)
    local playerId = source

    if not Tables[tableAddress] then return end
    if Tables[tableAddress].player then return end

    Tables[tableAddress].player     = playerId
    Tables[tableAddress].lastPlayer = playerId

    if not Tables[tableAddress].pastPlayers then
        Tables[tableAddress].pastPlayers = {}
    end

    if not Tables[tableAddress].pastPlayers[playerId] then
        Tables[tableAddress].pastPlayers[playerId] = true

        local ballCount = #Tables[tableAddress].balls
        if ballCount == 10 then
            TriggerClientEvent('rcore_stats:api:increaseStatValue', playerId, "pool_9_played", 1)
        elseif ballCount == 16 then
            TriggerClientEvent('rcore_stats:api:increaseStatValue', playerId, "pool_8_played", 1)
        end
    end

    for _, serverId in pairs(serverIds) do
        SyncTableState(serverId, tableAddress)
    end

    TriggerClientEvent('rcore_pool:turnGranted', playerId, tableAddress)
end)

RegisterNetEvent('rcore_pool:registerTable')
AddEventHandler('rcore_pool:registerTable', function(coords)
    local tablePos     = vector3(coords.x, coords.y, coords.z)
    local playerId     = source
    local tableAddress = positionToTableAddress(playerId, tablePos)

    if not Tables[tableAddress] then
        Tables[tableAddress] = {
            tablePos   = tablePos,
            cueBallIdx = nil,
            balls      = {},
        }
    end

    SyncTableState(playerId, tableAddress)
end)
