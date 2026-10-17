-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Initialize stream namespace
WSB.stream = {}

-- Load an animation dictionary
-- @param animDict string - Name of the animation dictionary to load
-- @param timeoutMs number|nil - Timeout in milliseconds (defaults to 5000)
-- @return boolean - True if loaded successfully, false if timeout
function WSB.stream.animDict(animDict, timeoutMs)
    -- Default timeout to 5 seconds
    if not timeoutMs then
        timeoutMs = 5000
    end
    
    -- Request the animation dictionary
    RequestAnimDict(animDict)
    
    local startTime = GetGameTimer()
    
    -- Wait for animation dictionary to load
    while true do
        if HasAnimDictLoaded(animDict) then
            break
        end
        
        Wait(0)
        
        local elapsedTime = GetGameTimer() - startTime
        
        -- Check for timeout
        if timeoutMs < elapsedTime then
            print(
                "^0[^3WARNING^0] failed to load animation dictionary ^1" .. animDict ..
                "^0 after ^1" .. string.format("%.2f", elapsedTime) .. " MS^0"
            )
            return false
        end
    end
    
    return true
end

-- Load an animation set
-- @param animSet string - Name of the animation set to load
-- @param timeoutMs number|nil - Timeout in milliseconds (defaults to 5000)
-- @return boolean - True if loaded successfully, false if timeout
function WSB.stream.animSet(animSet, timeoutMs)
    -- Default timeout to 5 seconds
    if not timeoutMs then
        timeoutMs = 5000
    end
    
    -- Request the animation set
    RequestAnimSet(animSet)
    
    local startTime = GetGameTimer()
    
    -- Wait for animation set to load
    while true do
        if HasAnimSetLoaded(animSet) then
            break
        end
        
        Wait(0)
        
        local elapsedTime = GetGameTimer() - startTime
        
        -- Check for timeout
        if timeoutMs < elapsedTime then
            print(
                "^0[^3WARNING^0] failed to load animation set ^1" .. animSet ..
                "^0 after ^1" .. string.format("%.2f", elapsedTime) .. " MS^0"
            )
            return false
        end
    end
    
    return true
end

-- Load a model
-- @param modelHash string|number - Model name or hash to load
-- @param timeoutMs number|nil - Timeout in milliseconds (defaults to 5000)
-- @return boolean - True if loaded successfully, false if timeout
function WSB.stream.model(modelHash, timeoutMs)
    -- Default timeout to 5 seconds
    if not timeoutMs then
        timeoutMs = 5000
    end
    
    -- Request the model
    RequestModel(modelHash)
    
    local startTime = GetGameTimer()
    
    -- Wait for model to load
    while true do
        if HasModelLoaded(modelHash) then
            break
        end
        
        Wait(0)
        
        local elapsedTime = GetGameTimer() - startTime
        
        -- Check for timeout
        if timeoutMs < elapsedTime then
            print(
                "^0[^3WARNING^0] failed to load model ^1" .. modelHash ..
                "^0 after ^1" .. string.format("%.2f", elapsedTime) .. " MS^0"
            )
            return false
        end
    end
    
    return true
end

-- Load a weapon asset
-- @param weaponHash string|number - Weapon name or hash to load
-- @param timeoutMs number|nil - Timeout in milliseconds (defaults to 5000)
-- @return boolean - True if loaded successfully, false if timeout
function WSB.stream.weapon(weaponHash, timeoutMs)
    -- Default timeout to 5 seconds
    if not timeoutMs then
        timeoutMs = 5000
    end
    
    -- Request the weapon asset
    RequestWeaponAsset(weaponHash)
    
    local startTime = GetGameTimer()
    
    -- Wait for weapon asset to load
    while true do
        if HasWeaponAssetLoaded(weaponHash) then
            break
        end
        
        Wait(0)
        
        local elapsedTime = GetGameTimer() - startTime
        
        -- Check for timeout
        if timeoutMs < elapsedTime then
            print(
                "^0[^3WARNING^0] failed to load weaponType ^1" .. weaponHash ..
                "^0 after ^1" .. string.format("%.2f", elapsedTime) .. " MS^0"
            )
            return false
        end
    end
    
    return true
end

-- Load a particle effect (PTFX) asset
-- @param ptfxAsset string - Name of the PTFX asset to load
-- @param timeoutMs number|nil - Timeout in milliseconds (defaults to 5000)
-- @return boolean - True if loaded successfully, false if timeout
function WSB.stream.ptfx(ptfxAsset, timeoutMs)
    -- Default timeout to 5 seconds
    if not timeoutMs then
        timeoutMs = 5000
    end
    
    -- Request the PTFX asset
    RequestNamedPtfxAsset(ptfxAsset)
    
    local startTime = GetGameTimer()
    
    -- Wait for PTFX asset to load
    while true do
        if HasNamedPtfxAssetLoaded(ptfxAsset) then
            break
        end
        
        Wait(0)
        
        local elapsedTime = GetGameTimer() - startTime
        
        -- Check for timeout
        if timeoutMs < elapsedTime then
            print(
                "^0[^3WARNING^0] failed to load PtfxAsset ^1" .. ptfxAsset ..
                "^0 after ^1" .. string.format("%.2f", elapsedTime) .. " MS^0"
            )
            return false
        end
    end
    
    return true
end

-- Load a scaleform movie
-- @param scaleformName string - Name of the scaleform to load
-- @param timeoutMs number|nil - Timeout in milliseconds (defaults to 5000)
-- @return number|boolean - Scaleform handle if loaded successfully, false if timeout
function WSB.stream.scaleform(scaleformName, timeoutMs)
    -- Default timeout to 5 seconds
    if not timeoutMs then
        timeoutMs = 5000
    end
    
    -- Request the scaleform movie (returns handle immediately)
    local scaleformHandle = RequestScaleformMovie(scaleformName)
    
    local startTime = GetGameTimer()
    
    -- Wait for scaleform to load
    while true do
        if HasScaleformMovieLoaded(scaleformHandle) then
            break
        end
        
        Wait(0)
        
        local elapsedTime = GetGameTimer() - startTime
        
        -- Check for timeout
        if timeoutMs < elapsedTime then
            print(
                "^0[^3WARNING^0] failed to load ScaleForm ^1" .. scaleformName ..
                "^0 after ^1" .. string.format("%.2f", elapsedTime) .. " MS^0"
            )
            return false
        end
    end
    
    return scaleformHandle
end