-- DEBUG: Track entity deletion (DISABLED BY DEFAULT FOR PERFORMANCE)
-- Enable only in development when specifically debugging entity leaks.

local ENABLE_DEBUG_TRACKING = false

if ENABLE_DEBUG_TRACKING then
    local EntityDeletionLog = {}
    local MAX_LOG_SIZE = 100

    -- Hook into DeleteEntity to log all deletions
    local OriginalDeleteEntity = DeleteEntity
    function DeleteEntity(entity)
        local info = {
            entity = entity,
            entityType = GetEntityType(entity),
            timestamp = os.time(),
            stack = debug.traceback(),
        }
        
        table.insert(EntityDeletionLog, 1, info)
        if #EntityDeletionLog > MAX_LOG_SIZE then
            table.remove(EntityDeletionLog)
        end
        
        -- Log to console
        print('^1[ENTITY DELETE]^7 Entity ' .. entity .. ' deleted from:')
        print(info.stack)
        
        return OriginalDeleteEntity(entity)
    end

    -- Command to view deletion log
    RegisterCommand('entitylog', function(source, args, rawCommand)
        if source ~= 0 then return end -- Server console only
        
        print('^3[ENTITY DELETE LOG]^7 Last ' .. #EntityDeletionLog .. ' entity deletions:')
        for i, log in ipairs(EntityDeletionLog) do
            print('  [' .. i .. '] Entity ' .. log.entity .. ' at ' .. os.date('%H:%M:%S', log.timestamp))
            print('      Type: ' .. log.entityType)
            print('      Stack: ' .. log.stack:sub(1, 200))
        end
    end, false)

    -- Command to count entities
    RegisterCommand('countentities', function(source, args, rawCommand)
        if source ~= 0 then return end
        
        local vehicles = GetAllVehicles()
        local objects = GetAllObjects()
        
        print('^2[ENTITY COUNT]^7')
        print('  Vehicles: ' .. #vehicles)
        print('  Objects: ' .. #objects)
    end, false)

    print('^2[QBX Housing]^7 Entity deletion tracking enabled. Use /entitylog to view log.')
end
