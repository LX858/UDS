local QBCore = exports['qb-core']:GetCoreObject()
local OnlinePlayers = {}

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    OnlinePlayers[Player.PlayerData.source] = {
        Name = GetPlayerName(Player.PlayerData.source),
        ICName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        CID = Player.PlayerData.citizenid,
    }
end)



function GetPlayerByPid(source)
    local Player = false
    while Core == nil do
        Citizen.Wait(0)
    end
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        Player = Core.GetPlayerFromId(source)
    else
        Player = exports.qbx_core:GetPlayerByPid(source)
        print(Player)
    end
    return Player
end

function GetIdentifier(source)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            return Player.getIdentifier()
        else
            return Player.PlayerData.citizenid
        end
    end
end

function GetIdentifierByPid(pid)
    local Player = GetPlayerByPid(pid)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            return Player.getIdentifier()
        else
            return Player.PlayerData.citizenid
        end
    end
end

AddEventHandler("playerDropped", function(reason)
    local src = source
    local Player = OnlinePlayers[src]
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end -- if this is somehow still nill
    local Playerpid = xPlayer.PlayerData.pid
    local coords = GetEntityCoords(GetPlayerPed(source))
    if not Player then return end -- if this is somehow still nill
    TriggerClientEvent("1307_logout:client:showlog", -1, src, Playerpid, coords, Player.Name, Player.ICName, Player.CID, reason)
end)

RegisterNetEvent('qb-phone:server:GiveContactDetails',function(target,number)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local name = Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname
    print(name)
    TriggerClientEvent('qb-phone:client:ReceiveContactDetails',target,name,number)
end)
