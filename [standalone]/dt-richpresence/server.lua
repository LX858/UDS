local function UpdatePlayerCount()
    GlobalState.totalPlayers = GetNumPlayerIndices()
end

AddEventHandler('playerJoining', function()
    SetTimeout(1000, UpdatePlayerCount)
end)

AddEventHandler('playerDropped', function()
    SetTimeout(1000, UpdatePlayerCount)
end)

CreateThread(function()
    while true do
        UpdatePlayerCount()
        Wait(Config.UpdateInterval or 30000)
    end
end)