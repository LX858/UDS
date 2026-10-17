-- Initialize debug system
if not dbg then
    dbg = RDebug()
    dbg.setupPrefix(GetCurrentResourceName())
end

-- Get current game type
local gameName = GetGameName()

-- Storage for markers, texts and blips
local activeTexts = {}
local activeMarkers = {}
local activeBlips = {}

-- Try to delete marker and associated elements
function tryDeleteMarker(pointKey)
    -- Try to destroy active text
    local textObject = activeTexts[pointKey]
    if textObject ~= nil then
        local success, error = pcall(textObject.destroy)
        if not success then
            dbg.critical("Error occurs on calling destroy on point %s - %s", point.key, error)
        end
    end
    
    -- Try to destroy active marker
    local markerObject = activeMarkers[pointKey]
    if markerObject ~= nil then
        local success, error = pcall(markerObject.destroy)
        if not success then
            dbg.critical("Error occurs on calling destroy on point %s - %s", point.key, error)
        end
    end
    
    -- Try to remove active blip
    local blipObject = activeBlips[pointKey]
    if blipObject ~= nil then
        removeBlip(blipObject)
    end
end

-- Check if point should be rendered based on permissions and job
function shouldRenderPoint(point, playerData)
    if point.is_enabled == false then
        return false
    end
    
    local playerJob = {
        name = GetPlayersJobName(),
        grade = GetPlayersJobGrade()
    }
    
    return HasPermission(point.attributes, playerJob, playerData)
end

-- Initialize markers and points for all available points
function initMarkers(playerData)
    for _, point in pairs(getPoints()) do
        local pointKey = point.key
        
        -- Clean up existing elements
        local existingText = activeTexts[pointKey]
        if existingText ~= nil then
            local success, error = pcall(existingText.destroy)
            if not success then
                dbg.critical("Error occurs on calling destroy on point %s - %s", pointKey, error)
            end
        end
        
        local existingMarker = activeMarkers[pointKey]
        if existingMarker ~= nil then
            local success, error = pcall(existingMarker.destroy)
            if not success then
                dbg.critical("Error occurs on calling destroy on marker %s - %s", pointKey, error)
            end
            dbg.debug("Remove marker %s", pointKey)
        end
        
        local existingBlip = activeBlips[pointKey]
        if existingBlip ~= nil then
            removeBlip(existingBlip)
        end
        
        -- Check if point should be rendered
        if shouldRenderPoint(point, playerData) then
            local position = vector3(point.position.x, point.position.y, point.position.z)
            
            -- Create 3D text
            local textObject = create3DText(point.label, GetCurrentResourceName())
            
            -- Set font if specified
            if point.font then
                textObject.setFont(tonumber(point.font))
            end
            
            -- Configure text properties
            textObject.setPosition(position)
            textObject.setRenderDistance(point.draw_distance or 5.0)
            textObject.setKeys({Config.Keys.HelpPointOpen})
            textObject.setColor({
                r = point.color.r,
                g = point.color.g,
                b = point.color.b,
                a = 255
            })
            textObject.setSize((point.size * 1.0) or 0.8)
            
            -- Set key event handler
            textObject.on("key", function(keyPressed)
                if keyPressed == Config.Keys.HelpPointOpen then
                    TriggerServerEvent(triggerName("openPointHelp"), point.key)
                end
            end)
            
            -- Set enter event handler
            textObject.on("enter", function()
                ShowHelpText(_U("help_text"))
            end)
            
            textObject.render()
            
            -- Create blip if enabled
            local blipObject = nil
            if point.blip_enabled then
                if gameName == GameType.REDM then
                    blipObject = createBlip(
                        point.label,
                        GetHashKey(point.blip_sprite),
                        position,
                        {
                            scale = point.blip_size or 0.8
                        }
                    )
                elseif gameName == GameType.FIVEM then
                    blipObject = createBlip(
                        point.label,
                        point.blip_sprite,
                        position,
                        {
                            type = point.blip_display_type or 2,
                            color = point.blip_color or 1,
                            scale = point.blip_size or 0.8
                        }
                    )
                end
                
                activeBlips[pointKey] = blipObject
                dbg.debug("Creating blip for %s %s", pointKey, blipObject)
            end
            
            -- Create marker if enabled
            if point.marker_enabled then
                local markerObject = createMarker(pointKey, GetCurrentResourceName())
                
                -- Get marker offset
                local markerOffset = Config.MarkerOffset[pointKey] or Config.MarkerOffset.default or vector3(0.0, 0.0, 0.0)
                
                -- Configure marker properties
                markerObject.setPosition(position + markerOffset)
                markerObject.setColor({
                    r = point.marker_color.r,
                    g = point.marker_color.g,
                    b = point.marker_color.b,
                    a = 255
                })
                markerObject.setScale({
                    x = point.marker_size.x * 1.0,
                    y = point.marker_size.y * 1.0,
                    z = point.marker_size.z * 1.0
                })
                
                -- Set rotation if enabled
                if point.is_rotation_enabled then
                    markerObject.setFaceCamera(false)
                    markerObject.setRotation({
                        x = point.marker_rotation.x * 1.0,
                        y = point.marker_rotation.y * 1.0,
                        z = point.marker_rotation.z * 1.0
                    })
                end
                
                markerObject.setType(point.marker_type)
                markerObject.setRenderDistance(point.marker_draw_distance)
                markerObject.render()
                
                activeMarkers[pointKey] = markerObject
                dbg.debug("Created marker %s", pointKey)
            end
            
            dbg.debug("Create text on %s", json.encode(point.position))
            activeTexts[pointKey] = textObject
        end
    end
end

-- Event handler for opening root help menu
RegisterNetEvent(triggerName("openRootHelp"), function(initData, serverData)
    if initData then
        setInitData(initData, serverData.isDataFinishedLoading)
    end
    
    if isOpened() then
        dbg.critical("NUI is already opened!")
        return
    end
    
    dbg.debug("Opening root help menu")
    openRootHelp(serverData.isAdmin, serverData)
end)

-- Event handler for opening help admin menu
RegisterNetEvent(triggerName("openHelpAdmin"), function(initData, serverData)
    if initData then
        setInitData(initData, serverData.isDataFinishedLoading)
    end
    
    if isOpened() then
        dbg.critical("NUI is already opened!")
        return
    end
    
    dbg.debug("Opening root help menu")
    openRootHelp(true, serverData)
end)

-- Event handler for opening specific help
RegisterNetEvent(triggerName("openSpecificHelp"), function(initData, serverData)
    if initData then
        setInitData(initData, serverData.isDataFinishedLoading)
    end
    
    if isOpened() then
        dbg.critical("NUI is already opened!")
        return
    end
    
    openSpecificHelp(serverData)
end)

-- Event handler for navigation
RegisterNetEvent(triggerName("navigate"), function(coordinates)
    if coordinates.x ~= nil and coordinates.y ~= nil then
        SetNewWaypoint(coordinates.x, coordinates.y)
    end
    
    NativeNotify(_U("navigate_set"))
end)

-- Resource stop cleanup
AddEventHandler("onResourceStop", function(resourceName)
    local currentResource = GetCurrentResourceName()
    if resourceName ~= currentResource then
        return
    end
    
    removeAllBlips()
end)