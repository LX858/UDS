-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Get the inventory slot number for a specific item
-- Works with both QBCore (Functions.GetItemByName) and ESX (getInventoryItem) style inventories
-- @param source number - Player server ID
-- @param itemName string - Name of the item to find
-- @return number|boolean - Slot number if found, false otherwise
function GetItemSlot(source, itemName)
    -- Get player object
    local player = WSB.getPlayer(source)
    if not player then
        return false
    end
    
    local itemData = nil
    
    -- Try QBCore inventory method
    if player.Functions then
        if player.Functions.GetItemByName then
            itemData = player.Functions.GetItemByName(itemName)
        end
    else
        -- Try ESX inventory method
        if player.getInventoryItem then
            itemData = player.getInventoryItem(itemName)
        end
    end
    
    -- Return slot number if item exists
    if itemData then
        if itemData.slot then
            return itemData.slot
        end
    end
    
    return false
end

-- Get all inventory slots that contain a specific item
-- Useful for items that can be stacked in multiple slots
-- @param inventory table - Player inventory data
-- @param itemName string - Name of the item to find
-- @return table - Array of slot numbers containing the item
function GetSlotsByItem(inventory, itemName)
    local slots = {}
    
    if not inventory then
        return slots
    end
    
    -- Convert item name to lowercase for case-insensitive comparison
    local searchName = itemName:lower()
    
    -- Iterate through inventory
    for slotKey, itemData in pairs(inventory) do
        local currentItemName = itemData.name:lower()
        
        if currentItemName == searchName then
            local slotIndex = #slots + 1
            
            -- Try to get slot number from item data, otherwise use the key
            local slotNumber = tonumber(itemData.slot) or tonumber(slotKey)
            
            slots[slotIndex] = slotNumber
        end
    end
    
    return slots
end