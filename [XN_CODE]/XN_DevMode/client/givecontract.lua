local QBCore = exports['qb-core']:GetCoreObject()

local function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())
    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
	end
	return closestPlayer, closestDistance
end

RegisterNetEvent('qb-phone:client:GiveContactDetails', function()
    print('1')
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 5.0 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent('qb-phone:server:GiveContactDetails',playerId,exports.npwd:getPhoneNumber())
    end
end)

RegisterNetEvent('qb-phone:client:ReceiveContactDetails', function(pname,pnumber)
    local defaultImage = 'https://github.com/xuannguyen995/imagechatcity/blob/main/all_stars.png?raw=true'
    print(pname, pnumber)
    exports.npwd:setPhoneVisible(true)
    exports.npwd:fillNewContact({ name = pname, number = pnumber, avatar = defaultImage })
end)