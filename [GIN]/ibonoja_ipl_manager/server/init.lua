-- IBONOJA IPL Manager - Server Initialization
-- Handles config loading, state bags, permissions, and variant exports

AllowedStateBags = {}

local loadedConfig = nil

AddEventHandler("onServerResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    loadedConfig = Setup.defaultConfigs()
    GlobalState:set("ibonoja_ipl_manager:loaded", true, true)
end)

AddEventHandler("onServerResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    GlobalState:set("ibonoja_ipl_manager:loaded", false, true)
    loadedConfig = nil
end)

CreateThread(function()
    if not loadedConfig then
        loadedConfig = Setup.defaultConfigs()
        GlobalState:set("ibonoja_ipl_manager:loaded", true, true)
    end
end)

RegisterNetEvent("ibonoja_ipl_manager:set")
AddEventHandler("ibonoja_ipl_manager:set", function(statebagName, value)
    if not AllowedStateBags[statebagName] then
        lib.print.error("Received statebag update for %s which is not allowed from source %s", statebagName, source)
        return
    end
    
    GlobalState:set(statebagName, value, true)
end)

function CheckPlayerRestrictions(playerId)
    local restrictionType = type(EditableConfig.Menu.Restricted)
    local restriction = EditableConfig.Menu.Restricted
    
    if restrictionType == "boolean" then
        return restriction == false
    elseif restrictionType == "string" then
        return IsPlayerAceAllowed(playerId, restriction)
    elseif restrictionType == "table" then
        for _, ace in ipairs(restriction) do
            if IsPlayerAceAllowed(playerId, ace) then
                return true
            end
        end
        return false
    elseif restrictionType == "function" then
        return restriction(playerId) == true
    end
    
    return false
end

lib.callback.register("ibonoja_ipl_manager:checkRestrictions", function(playerId)
    return CheckPlayerRestrictions(playerId)
end)

function SetVariant(mapName, configName, variantValue)
    if not loadedConfig then
        lib.print.error("Config is not loaded yet")
        return
    end
    
    local mapConfig = loadedConfig[mapName]
    if not mapConfig then
        lib.print.error("Map %s not found in config", mapName)
        return
    end
    
    local matchedOption = nil
    local statebagName = nil
    
    for _, option in ipairs(mapConfig.Menu.options) do
        if option.configName == configName then
            matchedOption = option
            statebagName = string.format("%s:%s", mapConfig.Menu.id, option.statebag)
            break
        end
    end
    
    if not matchedOption then
        lib.print.error("Option %s not found in map %s config", configName, mapName)
        return
    end
    
    if not statebagName then
        lib.print.error("Statebag name for option %s in map %s is nil", configName, mapName)
        return
    end
    
    if not AllowedStateBags[statebagName] then
        lib.print.error("Statebag %s is not allowed to be set", statebagName)
        return
    end
    
    if matchedOption.type == "checkbox" then
        local numericValue = variantValue and 1 or 0
        GlobalState:set(statebagName, numericValue, true)
    end
    
    if matchedOption.type == "scroll" then
        local matchedIndex = nil
        
        for index, scrollValue in ipairs(matchedOption.values) do
            if scrollValue.value and scrollValue.value.id == variantValue then
                matchedIndex = index
                break
            end
        end
        
        if matchedIndex then
            GlobalState:set(statebagName, matchedIndex, true)
        else
            GlobalState:set(statebagName, 1, true)
        end
    end
end

exports("SetVariant", SetVariant)

RegisterCommand("testexp", function(source, args, rawCommand)
    exports.ibonoja_ipl_manager:SetVariant(args[1], args[2], tonumber(args[3]))
end)
