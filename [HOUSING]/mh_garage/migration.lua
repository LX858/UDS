-- Migration script to fix style data structure
-- Run this once to fix existing garage data

local function FixGarageData()
    --print('^3[mh_garage]^7 Starting garage data migration...')
    
    local result = MySQL.query.await('SELECT * FROM `mh_garage`')
    local fixedCount = 0
    
    for i = 1, #result do
        local row = result[i]
        local data = json.decode(row.data)
        
        if data and data.style then
            local needsFix = false
            
            -- Check if style is an array instead of object with floor keys
            if type(data.style) == 'table' and data.style[1] and type(data.style[1]) == 'table' then
                -- Old format: style = [[...]] or style = [...]
                needsFix = true
                local oldStyle = data.style
                data.style = {}
                
                -- Convert to new format: style = {["1"] = [...]}
                if oldStyle[1] and type(oldStyle[1]) == 'table' and oldStyle[1][1] then
                    -- Format: [[...]]
                    data.style["1"] = oldStyle[1]
                else
                    -- Format: [...]
                    data.style["1"] = oldStyle
                end
                
                --print('^2[mh_garage]^7 Fixed garage:', row.name, 'for owner:', row.owner)
                fixedCount = fixedCount + 1
            end
            
            if needsFix then
                MySQL.execute('UPDATE `mh_garage` SET data = ? WHERE id = ?', {
                    json.encode(data), row.id
                })
            end
        end
    end
    
    --print('^2[mh_garage]^7 Migration completed! Fixed', fixedCount, 'garages.')
end

-- Run migration
CreateThread(function()
    Wait(5000) -- Wait for database to be ready
    FixGarageData()
end)