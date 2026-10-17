-- IBONOJA IPL Manager - Configuration Setup Module
-- Processes Maps config, validates custom YMAPs, and initializes GlobalState

local mapsConfig = Maps

function BuildDefaultConfigs()
    local processedConfigs = {}
    
    for _, mapConfig in ipairs(mapsConfig) do
        local resourceNames = type(mapConfig.ResourceMapName) == "table" 
            and mapConfig.ResourceMapName 
            or {mapConfig.ResourceMapName}
        
        local foundResourceName = nil
        
        for _, resourceName in ipairs(resourceNames) do
            if GetResourceState(resourceName) ~= "missing" then
                foundResourceName = resourceName
                break
            end
        end
        
        if foundResourceName then
            processedConfigs[mapConfig.ConfigName] = mapConfig
            
            for _, option in ipairs(mapConfig.Menu.options) do
                local statebagKey = string.format("%s:%s", mapConfig.Menu.id, option.statebag)
                AllowedStateBags[statebagKey] = true
            end
        end
    end
    
    for configName, mapConfig in pairs(processedConfigs) do
        local editableMapConfig = EditableConfig[configName]
        
        if editableMapConfig then
            for _, option in ipairs(mapConfig.Menu.options) do
                ProcessMapOption(configName, mapConfig, option)
            end
        else
            lib.print.error("No editable config found for %s, using defaults", configName)
            ApplyDefaultOptionsToMap(mapConfig)
        end
    end
    
    return processedConfigs
end

function ProcessMapOption(configName, mapConfig, option)
    if option.ymap then
        ProcessCustomYmaps(configName, mapConfig, option)
    end
    
    local editableValue = EditableConfig[configName][option.configName]
    local valueType = type(editableValue)
    
    if (valueType == "number" or valueType == "boolean") and 
       (option.type == "checkbox" or option.type == "scroll") then
        
        if option.type == "checkbox" then
            ApplyCheckboxConfig(mapConfig, option, editableValue)
        elseif option.type == "scroll" and option.values then
            ApplyScrollConfig(configName, mapConfig, option, editableValue)
        end
    else
        lib.print.error("No valid editable config found for %s:%s, using default", configName, option.configName)
        ApplyDefaultOption(mapConfig, option)
    end
end

function ProcessCustomYmaps(configName, mapConfig, option)
    local customYmapsKey = option.configName .. "Ymaps"
    local customYmaps = EditableConfig[configName][customYmapsKey]
    
    if not customYmaps then
        return
    end
    
    if type(customYmaps) ~= "table" or #customYmaps == 0 then
        return
    end
    
    local isValidFormat = true
    
    for _, ymapEntry in ipairs(customYmaps) do
        if type(ymapEntry) ~= "table" or not ymapEntry.label or not ymapEntry.ymap then
            isValidFormat = false
            lib.print.error(
                "Invalid customYmaps format for %s:%s - must be array of {label = '...', ymap = '...'}",
                configName,
                option.configName
            )
            break
        end
    end
    
    if not isValidFormat then
        return
    end
    
    option.ymap.customYmaps = customYmaps
    
    local originalValuesCount = (option.values and #option.values) or 0
    
    if not option.values then
        option.values = {{label = "Off"}}
        originalValuesCount = 1
    end
    
    local maxValueId = 0
    for _, value in ipairs(option.values) do
        if value.value and value.value.id and type(value.value.id) == "number" then
            maxValueId = math.max(maxValueId, value.value.id)
        end
    end
    
    for _, ymapEntry in ipairs(customYmaps) do
        maxValueId = maxValueId + 1
        table.insert(option.values, {
            label = ymapEntry.label,
            value = {id = maxValueId},
            description = string.format("Custom Ymap: %s", ymapEntry.ymap)
        })
    end
    
    lib.print.info(
        "SERVER: Added %d custom ymaps to %s:%s (total options: %d → %d)",
        #customYmaps,
        configName,
        option.configName,
        originalValuesCount,
        #option.values
    )
end

function ApplyCheckboxConfig(mapConfig, option, configValue)
    local checkedValue = (configValue > 0 or configValue == true) and 1 or 0
    option.checked = checkedValue
    
    local statebagKey = string.format("%s:%s", mapConfig.Menu.id, option.statebag)
    GlobalState:set(statebagKey, option.checked, true)
end

function ApplyScrollConfig(configName, mapConfig, option, configValue)
    local foundMatch = false
    local isStringIdReference = false
    
    if option.idReference then
        for _, value in ipairs(option.values) do
            if value.value and value.value.id then
                isStringIdReference = type(value.value.id) == "string"
                break
            end
        end
    end
    
    if isStringIdReference then
        if configValue >= 1 and configValue <= #option.values then
            option.defaultIndex = configValue
            local statebagKey = string.format("%s:%s", mapConfig.Menu.id, option.statebag)
            GlobalState:set(statebagKey, option.defaultIndex, true)
            foundMatch = true
        end
    else
        for index, value in ipairs(option.values) do
            if value.value and value.value.id == configValue then
                option.defaultIndex = index
                local statebagKey = string.format("%s:%s", mapConfig.Menu.id, option.statebag)
                GlobalState:set(statebagKey, option.defaultIndex, true)
                foundMatch = true
                break
            end
        end
    end
    
    if not foundMatch then
        lib.print.warn(
            "No matching value found for %s:%s (config value: %s), using default",
            configName,
            option.configName,
            tostring(configValue)
        )
    end
end

function ApplyDefaultOption(mapConfig, option)
    if option.type == "checkbox" then
        option.checked = 0
        local statebagKey = string.format("%s:%s", mapConfig.Menu.id, option.statebag)
        GlobalState:set(statebagKey, option.checked, true)
    elseif option.type == "scroll" then
        option.defaultIndex = 1
        local statebagKey = string.format("%s:%s", mapConfig.Menu.id, option.statebag)
        GlobalState:set(statebagKey, option.defaultIndex, true)
    end
end

function ApplyDefaultOptionsToMap(mapConfig)
    for _, option in ipairs(mapConfig.Menu.options) do
        ApplyDefaultOption(mapConfig, option)
    end
end

Setup = {
    defaultConfigs = BuildDefaultConfigs
}
