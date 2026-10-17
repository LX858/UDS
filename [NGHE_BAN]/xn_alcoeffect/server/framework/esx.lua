if Config.Framework ~= 'ESX' then return end
ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    Wait(4000)

        for itemName, itemData in pairs(Config.AlcocholItems) do
            Wait(100)
            ESX.RegisterUsableItem(itemName, function(playerId)
                if not DrinkInProggres then
                    DrinkInProggres = true
                    local xPlayer = ESX.GetPlayerFromId(playerId) 
                    if itemData.thirst then
                        if itemData.thirst[1] == "add" then
                            TriggerClientEvent("esx_status:add", playerId, 'thirst', itemData.thirst[2])
                        elseif itemData.thirst[1] == "remove" then
                            TriggerClientEvent("esx_status:remove", playerId, 'thirst', itemData.thirst[2])
                        end
                    end
                    xPlayer.removeInventoryItem(itemName, 1)
                    TriggerClientEvent('NRG_AlcoEffect:onDrink', playerId, itemData.drunk, itemData.prop, itemData.propoffset, itemData.notify)
                    Wait(6000)
                    DrinkInProggres = false
                end
                
            end)
        end

        ESX.RegisterUsableItem(Config.BreathalyzerItemName, function(playerId)

            TriggerClientEvent('NRG_AlcoEffect:UseAlcomat', playerId)

        end)
        print('Items ready to use')
end)

function IdToPlayerIdentifier(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        return xPlayer.identifier
    else
        return nil
    end
end

RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)

    if PlayerDataDrunk[xPlayer.identifier] then
        local timenow = os.time()
        local timepass = timenow - PlayerDataDrunk[xPlayer.identifier].time
    
        local x = timepass/Config.DropDrunkLevelTime
        x = math.floor(x)
        take = x*Config.DropDrunkLevelCount
        SqlDrunkLevel = PlayerDataDrunk[xPlayer.identifier].drunk - take
        if take < PlayerDataDrunk[xPlayer.identifier].drunk then
            Wait(5000)
            TriggerClientEvent('NRG_AlcoEffect:PlayerLoader', xPlayer.source, SqlDrunkLevel)
        end
        

    end
end)


