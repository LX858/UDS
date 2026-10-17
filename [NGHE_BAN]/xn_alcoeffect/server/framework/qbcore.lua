if Config.Framework ~= 'QBcore' then return end

QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    Wait(4000)
    for itemName, itemData in pairs(Config.AlcocholItems) do
        Wait(100)
        QBCore.Functions.CreateUseableItem(itemName, function(source)
            if not DrinkInProggres then
                DrinkInProggres = true
                local Player = QBCore.Functions.GetPlayer(source)
                local Thirst = Player.PlayerData.metadata.thirst or 0
                local Stress = Player.PlayerData.metadata.stress or 0
                
                if QBCore.Shared.Items[itemName] then
                    Player.Functions.RemoveItem(itemName, 1)
               else
                    print("❌ Item not found in QBCore.Shared.Items:", itemName)
                end
                if itemData.thirst then
                    if itemData.thirst[1] == "add" then
                        Thirst = Thirst + itemData.thirst[2]
                    elseif itemData.thirst[1] == "remove" then
                        Thirst = Thirst - itemData.thirst[2]
                    end
                end
                if itemData.stress then
                    if itemData.stress[1] == "add" then
                        Stress = Stress + itemData.stress[2]
                    elseif itemData.stress[1] == "remove" then
                        Stress = Stress - itemData.stress[2]
                    end
                end
                
                Player.Functions.SetMetaData("thirst", Thirst)
                Player.Functions.SetMetaData("stress", Stress)
                TriggerClientEvent('NRG_AlcoEffect:onDrink', source, itemData.drunk, itemData.prop, itemData.propoffset, itemData.notify)
                Wait(6000)
                DrinkInProggres = false
            end

        end)
    end

    QBCore.Functions.CreateUseableItem(Config.BreathalyzerItemName, function(source)

        TriggerClientEvent('NRG_AlcoEffect:UseAlcomat', source)

    end)
    print('Items ready to use')
end)

function SavePlayerDrunk(playerId, drunkLevel)
    if not Config.SaveDrunkStatusInMetadata then return end
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end
    
    local level = math.min(100, math.max(0, math.floor(tonumber(drunkLevel) or 0)))
    if level <= 0 then
        Player.Functions.SetMetaData('drunk', { level = 0, time = os.time() })
    else
        Player.Functions.SetMetaData('drunk', {
            level = level,
            time = os.time()
        })
    end
end

function GetPlayerDrunk(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return 0, nil end
    
    local drunkMeta = Player.PlayerData.metadata.drunk
    if not drunkMeta then return 0, nil end
    
    local currentDrunk = 0
    local savedTime = os.time()
    
    if type(drunkMeta) == 'table' then
        currentDrunk = tonumber(drunkMeta.level) or 0
        savedTime = tonumber(drunkMeta.time) or os.time()
    elseif type(drunkMeta) == 'number' then
        currentDrunk = tonumber(drunkMeta) or 0
    end
    
    local timePass = os.time() - savedTime
    local intervals = math.floor(timePass / Config.DropDrunkLevelTime)
    local decay = intervals * Config.DropDrunkLevelCount
    local realDrunk = math.min(100, math.max(0, math.floor(currentDrunk - decay)))
    
    return realDrunk, drunkMeta
end

function IdToPlayerIdentifier(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if Player then
        return Player.PlayerData.citizenid
    else
        return nil
    end
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
    local src = player.PlayerData.source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if Config.SaveDrunkStatusInMetadata then
        local drunkMeta = Player.PlayerData.metadata.drunk
        if drunkMeta then
            local currentDrunk = 0
            local savedTime = os.time()
            
            if type(drunkMeta) == 'table' then
                currentDrunk = tonumber(drunkMeta.level) or 0
                savedTime = tonumber(drunkMeta.time) or os.time()
            elseif type(drunkMeta) == 'number' then
                currentDrunk = tonumber(drunkMeta) or 0
            end
            
            if currentDrunk > 0 then
                local timePass = os.time() - savedTime
                local intervals = math.floor(timePass / Config.DropDrunkLevelTime)
                local decay = intervals * Config.DropDrunkLevelCount
                local newDrunk = math.min(100, math.max(0, math.floor(currentDrunk - decay)))
                
                Player.Functions.SetMetaData('drunk', {
                    level = newDrunk,
                    time = os.time()
                })
                PlayersDrunkLevel[src] = newDrunk
                
                if newDrunk > 0 then
                    Wait(5000)
                    TriggerClientEvent('NRG_AlcoEffect:PlayerLoader', src, newDrunk)
                end
            else
                PlayersDrunkLevel[src] = 0
            end
        end
    elseif Config.SavaDrunkStatusInSQL and PlayerDataDrunk and PlayerDataDrunk[player.PlayerData.citizenid] then
        local timenow = os.time()
        local timepass = timenow - PlayerDataDrunk[player.PlayerData.citizenid].time

        local x = timepass / Config.DropDrunkLevelTime
        x = math.floor(x)
        local take = x * Config.DropDrunkLevelCount
        
        if take < PlayerDataDrunk[player.PlayerData.citizenid].drunk then
            Wait(10000)
            local SqlDrunkLevel = PlayerDataDrunk[player.PlayerData.citizenid].drunk - take
            TriggerClientEvent('NRG_AlcoEffect:PlayerLoader', player.PlayerData.source, SqlDrunkLevel)
        end
    end
end)


