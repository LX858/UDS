table.insert(Cfg.voiceModes, {35.0, 'Megaphone'})

exports('setMegaphone', function(...)
    local args = {...}
    local previousVoiceRange = args[1]
    local restoreMode = args[2]

    -- Handle export table being passed as first argument
    if type(previousVoiceRange) == "table" then
        previousVoiceRange = args[2]
        restoreMode = args[3]
    end

    -- Support boolean toggle (r_megaphone compatibility)
    if previousVoiceRange == true then
        previousVoiceRange = nil
    elseif previousVoiceRange == false and type(restoreMode) == "number" then
        previousVoiceRange = restoreMode
    end

    if not previousVoiceRange then
        mode = #Cfg.voiceModes
        setProximityState(Cfg.voiceModes[#Cfg.voiceModes][1], true)
    else
        mode = previousVoiceRange
        if Cfg.voiceModes[previousVoiceRange] then
            setProximityState(Cfg.voiceModes[previousVoiceRange][1], false)
        else
            -- Fallback to default if mode doesn't exist
            mode = 1
            setProximityState(Cfg.voiceModes[1][1], false)
        end
    end
end)

exports('getMegaphone', function()
    return mode
end)

RegisterCommand('cycleproximity', function()
    if GetConvarInt('voice_enableProximityCycle', 1) ~= 1 or disableProximityCycle then return end
    
    local newMode = mode + 1
    if newMode <= #Cfg.voiceModes and newMode ~= #Cfg.voiceModes - 1 then
    	mode = newMode
    else
    	mode = 1
    end
    
    setProximityState(Cfg.voiceModes[mode][1], false)
    TriggerEvent('pma-voice:setTalkingMode', mode)
end, false)

if gameVersion == 'fivem' then
    RegisterKeyMapping('cycleproximity', 'Cycle Proximity', 'keyboard', GetConvar('voice_defaultCycle', 'F11'))
end