-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Export the bridge object for other resources to access
exports("GetBridgeObject", function()
    return WSB
end)

-- Get the Wasabi Bridge version
-- @return string - Version string with dots removed (e.g., "123" for version 1.2.3)
function WSB.getVersion()
    -- Get version from resource metadata
    local version = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
    
    -- Remove dots from version string
    version = version:gsub("%.", "")
    
    return version
end

-- Trim whitespace from a string
-- @param str string|nil - String to trim
-- @return string|nil - Trimmed string, or nil if input is nil
function WSB.trim(str)
    if str then
        return string.gsub(str, "^%s*(.-)%s*$", "%1")
    else
        return nil
    end
end

-- Convert shop data between different inventory system formats
-- @param shopData table - Original shop data with inventory array
-- @param inventorySystem string|nil - Target inventory system (defaults to WSB.inventorySystem)
-- @return table - Converted shop data in the appropriate format
function ConvertShopData(shopData, inventorySystem)
    -- Use default inventory system if not specified
    if not inventorySystem then
        inventorySystem = WSB.inventorySystem
    end
    
    -- Handle codem-inventory format (simple array)
    if inventorySystem == "codem-inventory" then
        local convertedItems = {}
        
        for index, item in ipairs(shopData.inventory) do
            local itemIndex = #convertedItems + 1
            convertedItems[itemIndex] = {
                name = item.name,
                price = item.price
            }
        end
        
        return convertedItems
    end
    
    -- Handle standard/ox_inventory format (structured with slots)
    local slotCounter = 0
    local convertedShop = {
        label = shopData.name,
        items = {}
    }
    
    for index, item in ipairs(shopData.inventory) do
        local itemIndex = #convertedShop.items + 1
        
        convertedShop.items[itemIndex] = {
            name = item.name,
            price = item.price,
            slot = slotCounter + 1,
            amount = 500,  -- Default amount
            info = {}
        }
        
        slotCounter = slotCounter + 1
    end
    
    return convertedShop
end

-- Register network event for debug printing
RegisterNetEvent("wasabi_bridge:debugPrint", print)