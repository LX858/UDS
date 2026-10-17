PlayerDataDrunk = {}

if Config.SavaDrunkStatusInSQL then
    MySQL.ready(function()
        local createTableQuery = [[
            CREATE TABLE IF NOT EXISTS `nrg_drunkeffect` (
                `identifier` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
                `drunk` VARCHAR(15) NOT NULL COLLATE 'utf8mb4_unicode_ci',
                `time` int(11) NOT NULL COLLATE 'utf8mb4_unicode_ci',
                PRIMARY KEY (`identifier`) USING BTREE
            )
            COLLATE='utf8mb4_general_ci'
            ENGINE=InnoDB;
        ]]
        
        MySQL.Async.execute(createTableQuery, {}, function(result)
        end)
        
        Wait(3000)
        
        exports.oxmysql:query("SELECT * FROM nrg_drunkeffect", {}, function(results)
            for _, row in ipairs(results) do
                local currentTime = os.time()
                local timeDifference = currentTime - row.time
                local timeIntervals = timeDifference / Config.DropDrunkLevelTime
                local drunkLevel = tonumber(row.drunk)
                
                local decayIntervals = math.floor(timeIntervals)
                local decayAmount = decayIntervals * Config.DropDrunkLevelCount
                
                if decayAmount < drunkLevel then
                    PlayerDataDrunk[row.identifier] = {
                        drunk = drunkLevel,
                        time = row.time
                    }
                else
                    exports.oxmysql:query("DELETE FROM nrg_drunkeffect WHERE identifier = ?", 
                        {row.identifier}, 
                        function(deleteResult)
                        end
                    )
                end
            end
        end)
    end)
    
    function SaveToSQL(playerId, drunkLevel)
        local playerIdentifier = IdToPlayerIdentifier(playerId)
        
        if drunkLevel <= 0 then
            if PlayerDataDrunk[playerIdentifier] then
                DelateFromSQL(playerIdentifier)
                PlayerDataDrunk[playerIdentifier] = nil
            end
            return
        end
        
        local formattedDrunkLevel = string.format("%.2f", drunkLevel)
        local currentTime = os.time()
        
        if PlayerDataDrunk[playerIdentifier] then
            exports.oxmysql:update(
                "UPDATE nrg_drunkeffect SET drunk = ?, time = ?  WHERE identifier = ?",
                {formattedDrunkLevel, currentTime, playerIdentifier}
            )
        else
            exports.oxmysql:insert(
                "INSERT INTO nrg_drunkeffect (identifier, drunk, time) VALUES (?, ?, ?)",
                {playerIdentifier, formattedDrunkLevel, currentTime}
            )
        end
        
        PlayerDataDrunk[playerIdentifier] = {
            drunk = drunkLevel,
            time = currentTime
        }
    end
    
    function DelateFromSQL(playerIdentifier)
        exports.oxmysql:query("DELETE FROM nrg_drunkeffect WHERE identifier = ?", 
            {playerIdentifier}, 
            function(result)
            end
        )
    end
else
    function SaveToSQL(playerId, drunkLevel)
        return
    end
    
    function DelateFromSQL(playerIdentifier)
        return
    end
end
