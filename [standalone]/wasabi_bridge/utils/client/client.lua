-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Generate a unique identifier for a target
-- @param targetType string - Type of target (e.g., "entity", "model", "zone")
-- @param targetName string - Name/identifier of the target
-- @param customIdentifier string|nil - Optional custom identifier to use
-- @return string - Unique identifier for the target
function GenerateTargetIdentifier(targetType, targetName, customIdentifier)
    -- Initialize targetType table if it doesn't exist
    if not ActiveTargets[targetType] then
        ActiveTargets[targetType] = {}
    end
    
    -- Initialize targetName table if it doesn't exist
    if not ActiveTargets[targetType][targetName] then
        ActiveTargets[targetType][targetName] = {}
    end
    
    -- If custom identifier provided, return it
    if customIdentifier then
        return customIdentifier
    end
    
    -- Check if this is the first target with this name
    local hasExistingTargets = next(ActiveTargets[targetType][targetName])
    
    if not hasExistingTargets then
        -- First target with this name, use simple identifier
        return targetName .. "_1"
    end
    
    -- Generate numbered identifier based on existing count
    local existingCount = #ActiveTargets[targetType][targetName]
    return targetName .. "_" .. (existingCount + 1)
end

-- Save target options to the ActiveTargets registry
-- @param targetType string - Type of target (e.g., "entity", "model", "zone")
-- @param targetName string - Name/identifier of the target
-- @param identifier string - Unique identifier for this specific target
-- @param options table - Target options/configuration
-- @param additionalData table|nil - Additional data (e.g., model information)
function SaveTargetOptions(targetType, targetName, identifier, options, additionalData)
    -- Initialize targetType table if it doesn't exist
    if not ActiveTargets[targetType] then
        ActiveTargets[targetType] = {}
    end
    
    -- Initialize targetName table if it doesn't exist
    if not ActiveTargets[targetType][targetName] then
        ActiveTargets[targetType][targetName] = {}
    end
    
    -- Get the next index for this target
    local targetList = ActiveTargets[targetType][targetName]
    local nextIndex = #targetList + 1
    
    -- Save target data
    targetList[nextIndex] = {
        identifier = identifier,
        options = options
    }
    
    -- Handle model-specific data
    if targetType == "model" and additionalData then
        if additionalData.models then
            ActiveTargets[targetType][targetName][nextIndex].model = additionalData.models
        end
    end
end

-- Remove an active target by its identifier
-- @param targetType string - Type of target (e.g., "entity", "model", "zone")
-- @param targetName string - Name/identifier of the target
-- @param identifier string - Unique identifier of the target to remove
function RemoveActiveTarget(targetType, targetName, identifier)
    -- Check if target type exists
    if not ActiveTargets[targetType] then
        return
    end
    
    -- Check if target name exists
    if not ActiveTargets[targetType][targetName] then
        return
    end
    
    -- Find and remove the target with matching identifier
    local targetList = ActiveTargets[targetType][targetName]
    
    for index = 1, #targetList, 1 do
        if targetList[index].identifier == identifier then
            table.remove(targetList, index)
            break
        end
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
    
    -- Handle codem-inventory format
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
    
    -- Handle standard/ox_inventory format
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

-- Format target option data for ox_lib menu system
-- @param targetData table - Target data containing options array
-- @return table - Formatted menu options for ox_lib
function FormatDataForOxLibMenu(targetData)
    local formattedOptions = {}
    
    for optionIndex = 1, #targetData.options, 1 do
        local newIndex = #formattedOptions + 1
        local option = targetData.options[optionIndex]
        
        formattedOptions[newIndex] = {
            icon = option.icon or false,
            label = option.title,
            description = option.description or false,
            args = {
                event = option.event,
                args = option.args or false
            }
        }
    end
    
    return formattedOptions
end