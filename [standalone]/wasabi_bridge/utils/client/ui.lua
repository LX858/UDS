-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Callback storage for async UI operations
local InputDialogCallback = false
local AlertDialogCallback = false
local ProgressUICallback = false
local SkillCheckCallback = false

-- Flag to prevent overlapping progress bars
local isProgressBarActive = false

-- Convert icon string to proper Font Awesome format
-- Handles various FA icon format conversions (fas, far, fab, fal, fad)
-- @param iconString string - Icon string to format
-- @return string - Properly formatted Font Awesome icon string
local function formatFontAwesomeIcon(iconString)
    -- FA prefix mapping
    local fontAwesomePrefixes = {
        fas = "fa-solid",
        far = "fa-regular",
        fab = "fa-brands",
        fal = "fa-light",
        fad = "fa-duotone"
    }
    
    -- Check for and replace short prefixes with full prefixes
    for shortPrefix, fullPrefix in pairs(fontAwesomePrefixes) do
        if iconString:match("^" .. shortPrefix .. " fa%-.+$") then
            return iconString:gsub("^" .. shortPrefix .. " fa%-", fullPrefix .. " fa-")
        end
    end
    
    -- Already properly formatted (e.g., "fa-solid fa-icon")
    if iconString:match("^fa%-.+ fa%-.+$") then
        return iconString
    end
    
    -- Simple icon name without prefix - add default fa-solid prefix
    if not iconString:match("%s") then
        return "fa-solid fa-" .. iconString
    end
    
    return iconString
end

-- Normalize table to ensure numeric keys are properly indexed
-- Converts string-indexed numeric keys to proper numeric keys
-- @param tbl any - Table to normalize (or any value)
-- @return table|any - Normalized table or original value
function NormalizeTable(tbl)
    if type(tbl) == "table" then
        local normalized = {}
        
        for key, value in pairs(tbl) do
            local numericKey = tonumber(key)
            if numericKey then
                normalized[numericKey] = value
            end
        end
        
        return normalized
    end
    
    return tbl
end

-- NUI Callback: Handle exit event from UI
RegisterNUICallback("onExit", function(data, cb)
    if not data.onExit then
        cb("ok")
        return
    end
    
    data.onExit()
    cb("ok")
end)

-- NUI Callback: Close menu and remove focus
RegisterNUICallback("closeMenu", function(data, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    cb("ok")
end)

-- NUI Callback: Trigger menu event
RegisterNUICallback("menuEvent", function(data, cb)
    -- Trigger the event if specified
    if data.event and data.event ~= "" then
        TriggerEvent(data.event, data.args)
    end
    
    -- Remove focus
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    -- Call onExit callback if provided
    if data.onExit then
        data.onExit()
    end
    
    cb("ok")
end)

-- NUI Callback: Set focus state
RegisterNUICallback("setFocus", function(data, cb)
    SetNuiFocus(data.isFocused, data.isFocused)
    
    -- Keep input enabled for menus while focused
    if data.isMenu then
        if data.isFocused then
            SetNuiFocusKeepInput(true)
        end
    end
    
    cb("ok")
end)

-- Show a custom notification
-- @param heading string - Notification title
-- @param content string - Notification message
-- @param notifType string - Notification type (maps to Config.Notifications.styles)
-- @param icon string - Icon to display
-- @param notificationId any - Optional unique ID for the notification
function ShowNotification(heading, content, notifType, icon, notificationId)
    -- Get style configuration or default to 'info'
    local styleConfig = Config.Notifications.styles[notifType]
    if not styleConfig then
        styleConfig = Config.Notifications.styles.info
    end
    
    -- Use style default icon if none provided
    if not icon then
        icon = styleConfig.icon
    end
    
    -- Format icon
    icon = formatFontAwesomeIcon(icon)
    
    -- Send notification to NUI
    SendNUIMessage({
        component = "notify",
        type = "custom",
        customType = {
            color = styleConfig.color
        },
        heading = heading or "",
        content = content or "",
        icon = icon,
        iconEffect = false,
        iconSize = Config.Notifications.defaults.iconSize,
        position = Config.Notifications.defaults.position,
        time = Config.Notifications.defaults.time,
        color = Config.Notifications.defaults.fontColor,
        sound = Config.Notifications.defaults.sound,
        backgroundColor = Config.Notifications.defaults.backgroundColor,
        id = notificationId
    })
end

-- Show a menu with options
-- @param menuData table - Menu configuration {title, color, position, options, onExit}
function ShowMenu(menuData)
    Wait(300)
    
    -- Format icons for all menu options
    for index, option in ipairs(menuData.options) do
        if option.icon then
            option.icon = formatFontAwesomeIcon(option.icon)
        end
    end
    
    -- Send menu to NUI
    SendNUIMessage({
        component = "menu",
        title = menuData.title,
        color = menuData.color or false,
        position = menuData.position or false,
        options = menuData.options,
        onExit = menuData.onExit or false
    })
    
    -- Set focus but keep input enabled
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
end

-- Show a context menu (right-click style menu)
-- @param menuData table - Menu configuration {title, color, options, onExit}
function ShowContextMenu(menuData)
    Wait(300)
    
    -- Format icons for all menu options
    for index, option in ipairs(menuData.options) do
        if option.icon then
            option.icon = formatFontAwesomeIcon(option.icon)
        end
    end
    
    -- Send context menu to NUI
    SendNUIMessage({
        component = "contextMenu",
        title = menuData.title,
        color = menuData.color or false,
        options = menuData.options,
        onExit = menuData.onExit or false
    })
    
    -- Set full focus
    SetNuiFocus(true, true)
end

-- NUI Callback: Receive input dialog data
RegisterNUICallback("inputDialogData", function(data, cb)
    -- Check if data is empty
    if data then
        if not next(data) then
            data = nil
        end
    end
    
    InputDialogCallback = data or "nil"
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Show an input dialog with multiple fields
-- @param label string - Dialog title
-- @param fields table - Array of input field configurations
-- @param color string|nil - Optional color theme
-- @return table|nil - Table of input values or nil if cancelled
function InputDialog(label, fields, color)
    Wait(300)
    
    -- Send input dialog to NUI
    SendNUIMessage({
        component = "inputDialog",
        label = label,
        data = fields,
        color = color or false
    })
    
    SetNuiFocus(true, true)
    
    -- Wait for callback
    local result = nil
    while result == nil do
        Wait(5)
        
        if InputDialogCallback then
            result = InputDialogCallback
            InputDialogCallback = nil
        end
    end
    
    -- Process result
    if result and result ~= "nil" then
        result = NormalizeTable(result)
        
        -- Convert empty strings to false
        for index = 1, #result, 1 do
            if result[index] == "" then
                result[index] = false
            end
        end
        
        InputDialogCallback = nil
        return result
    else
        InputDialogCallback = nil
        return nil
    end
end

-- NUI Callback: Receive alert dialog response
RegisterNUICallback("alertDialogData", function(data, cb)
    AlertDialogCallback = data or "nil"
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Show an alert dialog (confirm/cancel)
-- @param dialogData table - Dialog configuration {header, content, centered, cancel, color}
-- @return any - User response (true/false or custom value)
function AlertDialog(dialogData)
    Wait(300)
    
    -- Send alert dialog to NUI
    SendNUIMessage({
        component = "alertDialog",
        header = dialogData.header,
        content = dialogData.content,
        centered = dialogData.centered or false,
        cancel = dialogData.cancel or false,
        color = dialogData.color or false
    })
    
    SetNuiFocus(true, true)
    
    -- Wait for callback
    local result = nil
    while result == nil do
        Wait(5)
        
        if AlertDialogCallback then
            result = AlertDialogCallback
            AlertDialogCallback = nil
        end
    end
    
    if result and result ~= "nil" then
        AlertDialogCallback = nil
        return result
    else
        AlertDialogCallback = nil
        return nil
    end
end

-- Show text UI (persistent on-screen text)
-- @param message string - Message to display
-- @param options table|nil - Display options {position, iconColor, textColor, backgroundColor}
function ShowTextUI(message, options)
    if not options then
        options = {}
    end
    
    -- Apply defaults from config
    options.position = options.position or Config.TextUISettings.position or "right-center"
    options.iconColor = options.iconColor or Config.TextUISettings.iconColor or "#ffffff"
    options.textColor = options.textColor or Config.TextUISettings.textColor or "#ffffff"
    options.backgroundColor = options.backgroundColor or Config.TextUISettings.backgroundColor or "#25262B"
    
    Wait(300)
    
    SendNUIMessage({
        component = "textUI",
        message = message,
        options = options
    })
end

-- Hide text UI
function HideTextUI()
    Wait(300)
    
    SendNUIMessage({
        component = "textUI",
        message = false
    })
end

-- NUI Callback: Receive progress UI response
RegisterNUICallback("progressUIResponse", function(data, cb)
    local passed = false
    if data then
        if data.passed then
            passed = data.passed
        end
    end
    
    ProgressUICallback = passed or "nil"
    cb("ok")
end)

-- Show progress bar/circle with optional animation and props
-- @param progressData table - Progress configuration {label, duration, color, useWhileDead, canCancel, disable, anim, prop}
-- @param uiComponent string|nil - UI component type ("progressBar" or "progressCircle", defaults to "progressBar")
-- @return boolean|nil - True if completed, false if cancelled, nil on error
function ProgressUI(progressData, uiComponent)
    -- Prevent overlapping progress bars
    if isProgressBarActive then
        return false
    end
    
    Wait(300)
    
    if not uiComponent then
        uiComponent = "progressBar"
    end
    
    isProgressBarActive = true
    
    -- Send progress UI to NUI
    SendNUIMessage({
        component = uiComponent,
        label = progressData.label or false,
        duration = progressData.duration,
        color = progressData.color
    })
    
    -- Configuration flags
    local flagOptions = {}
    local disableKeys = {}
    local defaultFlags = {
        useWhileDead = true,
        canCancel = true,
        allowRagdoll = true,
        allowSwimming = true,
        allowCuffed = true,
        allowFalling = true
    }
    
    local animationPlayed = nil
    local propsCreated = nil
    local createdProps = {}
    
    -- Extract user-provided flags
    for key, value in pairs(progressData) do
        if defaultFlags[key] then
            flagOptions[key] = value
        end
    end
    
    local callbackResult = nil
    
    -- Main progress loop
    while callbackResult == nil do
        -- Check flag conditions
        if flagOptions then
            if next(flagOptions) and not callbackResult then
                for flagName, flagValue in pairs(flagOptions) do
                    if not flagValue then
                        local playerPed = WSB.cache.ped or PlayerPedId()
                        local shouldCancel = false
                        
                        -- Check each flag condition
                        if flagName == "useWhileDead" then
                            shouldCancel = WSB.isPlayerDead()
                        elseif flagName == "canCancel" then
                            -- Check for cancel inputs (ESC, Backspace, X)
                            shouldCancel = IsControlJustReleased(0, 177) or
                                          IsDisabledControlJustReleased(0, 177) or
                                          IsControlJustReleased(0, 73) or
                                          IsDisabledControlJustReleased(0, 73)
                        elseif flagName == "allowRagdoll" then
                            shouldCancel = IsPedRagdoll(playerPed)
                        elseif flagName == "allowSwimming" then
                            shouldCancel = IsPedSwimming(playerPed)
                        elseif flagName == "allowCuffed" then
                            shouldCancel = WSB.isPlayerHandcuffed()
                        elseif flagName == "allowFalling" then
                            shouldCancel = IsPedFalling(playerPed)
                        end
                        
                        -- Cancel progress if condition met
                        if shouldCancel and (flagName ~= "canCancel" or flagValue) then
                            SendNUIMessage({
                                component = uiComponent,
                                cancelled = true
                            })
                        end
                    end
                end
            end
        end
        
        -- Handle control disabling
        if progressData.disable then
            if next(progressData.disable) and not callbackResult then
                for disableType, isDisabled in pairs(progressData.disable) do
                    if isDisabled then
                        if disableType == "movement" or disableType == "move" or disableType == "all" then
                            WSB.disableKeys()
                        elseif disableType == "car" then
                            -- Cancel if player enters vehicle
                            if WSB.cache.vehicle then
                                if progressData.anim then
                                    ClearPedTasks(WSB.cache.ped or PlayerPedId())
                                end
                                SendNUIMessage({
                                    component = uiComponent,
                                    cancelled = true
                                })
                            end
                        elseif disableType == "combat" then
                            disableKeys[#disableKeys + 1] = 76
                            WSB.disableKeys(76)
                            DisablePlayerFiring(WSB.cache.playerId, true)
                        elseif disableType == "mouse" then
                            WSB.disableKeys({24, 25})  -- Left/right click
                        elseif disableType == "sprint" then
                            WSB.disableKeys(21)  -- Sprint key
                        end
                    end
                end
            end
        end
        
        -- Handle animation
        if progressData.anim and not animationPlayed and not callbackResult then
            if progressData.anim.scenario then
                -- Play scenario animation
                TaskStartScenarioInPlace(
                    WSB.cache.ped or PlayerPedId(),
                    progressData.anim.scenario,
                    0,
                    progressData.anim.playEnter ~= false
                )
                animationPlayed = true
            elseif progressData.anim.dict and progressData.anim.clip and not animationPlayed then
                -- Load and play animation dictionary
                if WSB.stream.animDict(progressData.anim.dict, 5000) then
                    animationPlayed = true
                    
                    TaskPlayAnim(
                        WSB.cache.ped or PlayerPedId(),
                        progressData.anim.dict,
                        progressData.anim.clip,
                        progressData.anim.blendIn or 3.0,
                        progressData.anim.blendOut or 3.0,
                        progressData.anim.duration or -1,
                        progressData.anim.flag or 49,
                        progressData.anim.playbackRate or 0,
                        progressData.anim.lockX or false,
                        progressData.anim.lockY or false,
                        progressData.anim.lockZ or false
                    )
                end
            end
        end
        
        -- Handle prop creation
        if progressData.prop and not callbackResult then
            if progressData.prop.model and not propsCreated then
                -- Single prop
                if WSB.stream.model(progressData.prop.model, 7500) then
                    local playerPed = WSB.cache.ped or PlayerPedId()
                    local propCoords = {table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.0, 0.55))}
                    
                    local propObject = CreateObjectNoOffset(
                        progressData.prop.model,
                        propCoords[1], propCoords[2], propCoords[3],
                        true, false, false
                    )
                    
                    AttachEntityToEntity(
                        propObject,
                        playerPed,
                        GetPedBoneIndex(playerPed, progressData.prop.bone or 60309),
                        progressData.prop.pos.x,
                        progressData.prop.pos.y,
                        progressData.prop.pos.z,
                        progressData.prop.rot.x,
                        progressData.prop.rot.y,
                        progressData.prop.rot.z,
                        true, true, false, true,
                        progressData.prop.rotOrder or 0,
                        true
                    )
                    
                    SetModelAsNoLongerNeeded(progressData.prop.model)
                    
                    if DoesEntityExist(propObject) then
                        createdProps[#createdProps + 1] = propObject
                    end
                    
                    propsCreated = true
                end
            elseif progressData.prop[1] and progressData.prop[1].model and not propsCreated then
                -- Multiple props
                for propIndex = 1, #progressData.prop, 1 do
                    local propConfig = progressData.prop[propIndex]
                    
                    if WSB.stream.model(propConfig.model, 7500) then
                        local playerPed = WSB.cache.ped or PlayerPedId()
                        local propCoords = {table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.0, 0.55))}
                        
                        local propObject = CreateObjectNoOffset(
                            propConfig.model,
                            propCoords[1], propCoords[2], propCoords[3],
                            true, false, false
                        )
                        
                        AttachEntityToEntity(
                            propObject,
                            playerPed,
                            GetPedBoneIndex(playerPed, propConfig.bone or 60309),
                            propConfig.pos.x,
                            propConfig.pos.y,
                            propConfig.pos.z,
                            propConfig.rot.x,
                            propConfig.rot.y,
                            propConfig.rot.z,
                            true, true, false, true,
                            propConfig.rotOrder or 0,
                            true
                        )
                        
                        SetModelAsNoLongerNeeded(propConfig.model)
                        
                        if DoesEntityExist(propObject) then
                            createdProps[#createdProps + 1] = propObject
                        end
                        
                        propsCreated = true
                    end
                end
            end
        end
        
        -- Check for callback result
        if ProgressUICallback then
            callbackResult = ProgressUICallback
            ProgressUICallback = nil
        end
        
        Wait(0)
    end
    
    -- Cleanup: Clear animation
    if progressData.anim then
        ClearPedTasks(WSB.cache.ped or PlayerPedId())
    end
    
    -- Cleanup: Delete props
    if progressData.prop and createdProps then
        if next(createdProps) then
            for propIndex = 1, #createdProps, 1 do
                if DoesEntityExist(createdProps[propIndex]) then
                    DeleteEntity(createdProps[propIndex])
                end
            end
        end
    end
    
    isProgressBarActive = false
    
    if callbackResult and callbackResult ~= "nil" then
        return callbackResult
    else
        return nil
    end
end

-- NUI Callback: Receive skill check result
RegisterNUICallback("skillCheckResult", function(data, cb)
    local passed = false
    if data then
        if data.passed then
            passed = data.passed
        end
    end
    
    SkillCheckCallback = passed or "nil"
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Show a skill check mini-game
-- @param difficulty string - Difficulty level
-- @param key string - Key to press
-- @param color string - Color theme
-- @return boolean|nil - True if passed, false if failed, nil on error
function SkillCheck(difficulty, key, color)
    Wait(300)
    
    -- Send skill check to NUI
    SendNUIMessage({
        component = "skillCheck",
        difficulty = difficulty,
        key = key,
        color = color
    })
    
    SetNuiFocus(true, true)
    
    -- Wait for result
    local result = nil
    while result == nil do
        Wait(5)
        
        if SkillCheckCallback then
            result = SkillCheckCallback
            SkillCheckCallback = nil
        end
    end
    
    SkillCheckCallback = nil
    
    if result and result ~= "nil" then
        return result
    end
    
    return nil
end