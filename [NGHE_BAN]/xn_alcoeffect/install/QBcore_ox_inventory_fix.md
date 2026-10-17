Go to ox_inventory/modules/bridge/qb/server.lua

replace

function server.UseItem(source, itemName, data)
    local cb = QBCore.Functions.CanUseItem(itemName)
    return cb and cb(source, data)
end 

use this one 

function server.UseItem(source, itemName, data)
    local itemData = QBCore.Functions.CanUseItem(itemName)
    if type(itemData) == "table" and itemData.func then
        itemData.func(source, data)
    end
end