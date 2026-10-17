local DEBUG = false
local function debugLog() end
if DEBUG then debugLog = function(...)
    print(...)
end end

function EnsureAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end
function EnsureModel(model)
    if not IsModelInCdimage(model) then
        debugLog("model", model, "not in cd image")
    else
        if not HasModelLoaded(model) then
            debugLog("loading", model)
            RequestModel(model)
        	while not HasModelLoaded(model) do
        		Wait(0)
        	end
            debugLog("successfully loaded", model)
    	end
	end
end

local previousAnim = nil
function StopAnim(ped)
    if previousAnim then
        StopEntityAnim(ped, previousAnim[2], previousAnim[1], true)
        previousAnim = nil
    end
end
function PlayAnimFlags(ped, dict, anim, flags)
    StopAnim(ped)
    EnsureAnimDict(dict)
    local len = GetAnimDuration(dict, anim)
    TaskPlayAnim(ped, dict, anim, 1.0, -1.0, len, flags, 1, 0, 0, 0)
    previousAnim = {dict, anim}
end

function PlayAnimUpper(ped, dict, anim)
    PlayAnimFlags(ped, dict, anim, 49)
end
function PlayAnim(ped, dict, anim)
    PlayAnimFlags(ped, dict, anim, 0)
end

local targetPool = {
    {vector3(1600.185, 6622.714, 15.85106), 1.0},
}

-- Use Config.AreaSize as max range to match the prospecting zone
local maxTargetRange = 150.0  -- Slightly larger than AreaSize for edge cases
local targets = {}
local dugTargets = {} -- Track dug target indices to prevent re-add


RegisterNetEvent("prospecting:setTargetPool")
AddEventHandler("prospecting:setTargetPool", function(pool)
    if Config.debug then print("^5[DEBUG] Received new target pool, size:", #pool) end
    targetPool = {}
    dugTargets = {} -- Clear dug targets when getting new pool
    debugLog("new targets", json.encode(pool))
    for n, pos in next, pool do
        targetPool[n] = {vector3(pos[1], pos[2], pos[3]), pos[4], n}
    end
    if Config.debug then print("^5[DEBUG] targetPool updated, size:", #targetPool) end
end)

local isProspecting = false
local pauseProspecting = false
local didCancelProspecting = false
local scannerState = "none"
local scannerFrametime = 0.0
local scannerScale = 0.0
local scannerAudio = true

local CONTROLS = {
    ["dig"] = {
        label = "PROSP_DIG",
        control = 24,
        input = "INPUT_ATTACK"
    },
    ["dig_hint"] = {
        label = "PROSP_DIG_HINT",
        control = 24,
        input = "INPUT_ATTACK"
    },
    ["stop"] = {
        label = "PROSP_STOP",
        control = 75,
        input = "INPUT_VEH_EXIT"
    },
    ["audio_on"] = {
        label = "PROSP_AUDIOON",
        control = 140,
        input = "INPUT_MELEE_ATTACK_LIGHT"
    },
    ["audio_off"] = {
        label = "PROSP_AUDIOOFF",
        control = 140,
        input = "INPUT_MELEE_ATTACK_LIGHT"
    },
}

local textUIShown = false
local currentTextUI = ""

local entityOffsets = {
    ["w_am_metaldetector"] = {
		bone = 18905,
        offset = vector3(0.360000, 0.060000, 0.140000),
        rotation = vector3(194.000000, -358.000000, -20.299999),
	},
}

local attachedEntities = {}
local scannerEntity = nil
function AttachEntity(ped, model)
    if entityOffsets[model] then
        EnsureModel(model)
        local pos = GetEntityCoords(PlayerPedId())
    	local ent = CreateObjectNoOffset(model, pos, 1, 1, 0)
    	AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, entityOffsets[model].bone), entityOffsets[model].offset, entityOffsets[model].rotation, 1, 1, 0, 0, 2, 1)
        scannerEntity = ent
        table.insert(attachedEntities, ent)
    end
end

function CleanupModels()
    for _, ent in next, attachedEntities do
        DetachEntity(ent, 0, 0)
        DeleteEntity(ent)
    end
    attachedEntities = {}
    scannerEntity = nil
end

function DisableAllInstructions()
    if textUIShown then
        lib.hideTextUI()
        textUIShown = false
        currentTextUI = ""
    end
end

function DigSequence(cb)
    DisableAllInstructions()
    CleanupModels()
    local ped = PlayerPedId()
    StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
    
    if lib.progressBar({
        duration = 5000,
        label = GetLabelText("PROSP_DIG") or 'Đang đào...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'random@burial',
            clip = 'a_burial',
        },
        prop = {
            model = 'prop_tool_shovel',
            bone = 28422,
            pos = vec3(0.0, 0.0, 0.24),
            rot = vec3(0.0, 0.0, 0.0),
        },
    }) then
        -- Success - just run callback, no need to re-attach
        if Config.debug then print("^2[DEBUG] ProgressBar SUCCESS") end
        CreateThread(function()
            Wait(100)
            if cb then cb() end
            if Config.debug then print("^2[DEBUG] Dig completed, use detector again to continue") end
        end)
    else
        -- Cancelled - no action needed
        if Config.debug then print("^1[DEBUG] ProgressBar CANCELLED") end
    end
end

function ShowHelp(text, n)
    BeginTextCommandDisplayHelp(text)
    EndTextCommandDisplayHelp(n or 0, false, true, -1)
end
function ShowFloatingHelp(text, pos)
    SetFloatingHelpTextWorldPosition(1, pos)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    ShowHelp(text, 2)
end

function getClosestTarget(pos)
    local closest, index, closestdist, difficulty
    local targetCount = 0
    for n, target in next, targets do
        targetCount = targetCount + 1
        -- Use 3D distance, not 2D
        local dist = #(pos - target[1])
        if (not closest) or closestdist > dist then
            closestdist = dist
            index = n
            closest = target
            difficulty = target[2]
        end
    end
    if targetCount > 0 and not index then
        if Config.debug then print("^1[DEBUG] getClosestTarget: Had", targetCount, "targets but found no valid index!") end
    end
    return closest or vector3(0.0, 0.0, 0.0), closestdist, index, difficulty
end

function DigTarget(index)
    if Config.debug then print("^3[DEBUG] DigTarget called, index:", index) end
    
    -- Pause prospecting during dig
    pauseProspecting = true
    
    local target = table.remove(targets, index)
    local pos = target[1]
    local targetPoolIndex = target[3] -- Get the original targetPool index
    
    -- Mark as dug immediately to prevent re-detection
    dugTargets[targetPoolIndex] = true
    
    DigSequence(function()
        -- Send event to server AFTER digging completes
        if Config.debug then print("^2[DEBUG] Dig completed, sending collect event to server") end
        TriggerServerEvent("prospecting:userCollectedNode", targetPoolIndex, pos.x, pos.y, pos.z)
        
        -- Reset ped animations immediately after dig
        local ped = PlayerPedId()
        StopEntityAnim(ped, "wood_idle_a", "mini@golfai", 1.0)
        ClearPedTasks(ped)
        ClearPedSecondaryTask(ped)
        ResetPedMovementClipset(ped, 0.0)
        
        -- Wait a moment for server to process, then stop detector
        Wait(500)
        if Config.debug then print("^2[DEBUG] Item received, stopping detector") end
        StopProspecting()
    end)
end

function StopProspecting()
    if not didCancelProspecting then
        didCancelProspecting = true
        CleanupModels()
        local ped = PlayerPedId()
        -- Stop the animation with proper blend out
        StopEntityAnim(ped, "wood_idle_a", "mini@golfai", 1.0)
        -- Clear tasks to reset stance
        ClearPedTasks(ped)
        ClearPedSecondaryTask(ped)
        -- Reset ped movement to normal
        ResetPedMovementClipset(ped, 0.0)
        circleScale = 0.0
        scannerScale = 0.0
        scannerState = "none"
        isProspecting = false
        pauseProspecting = false -- Reset pause state for next time
        TriggerServerEvent("prospecting:userStoppedProspecting")
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        CleanupModels()
        StopProspecting()
    end
end)

function StartProspecting()
    debugLog("trying to start")
    if not isProspecting then
        debugLog("starting")
        ProspectingThreads()
    end
end

RegisterNetEvent("prospecting:forceStart")
AddEventHandler("prospecting:forceStart", function()
    StartProspecting()
end)
RegisterNetEvent("prospecting:forceStop")
AddEventHandler("prospecting:forceStop", function()
    StopProspecting()
end)

-- Không cần auto-request locations khi resource start
-- Targets sẽ được assign khi player sử dụng máy dò

function ProspectingThreads()
    if isProspecting then 
        if Config.debug then print("^1[DEBUG] ProspectingThreads already running, returning") end
        return false 
    end
    if Config.debug then print("^3[DEBUG] ProspectingThreads starting") end
    debugLog("thread init")
    TriggerServerEvent("prospecting:userStartedProspecting")
    isProspecting = true
    didCancelProspecting = false
    pauseProspecting = false
    if Config.debug then print("^3[DEBUG] isProspecting=true, pauseProspecting=false") end

    -- Prospecting handler
    CreateThread(function()
        debugLog("thread loop")
        local ped = PlayerPedId()
        AttachEntity(ped, "w_am_metaldetector")
        local sleepTime = 0
        local loopCount = 0
        while isProspecting do
            loopCount = loopCount + 1
            if Config.debug and loopCount % 50 == 0 then -- Every ~25 seconds
                print("^4[DEBUG] Main loop still running, iteration:", loopCount, "isProspecting:", isProspecting)
            end
            Wait(sleepTime)
            sleepTime = 500 -- Default to 500ms, will be lowered if needed
            ped = PlayerPedId()
            local canProspect = true
            
            -- Disable controls
            DisableControlAction(0, 38, true)  -- E key (INPUT_PICKUP)
            DisableControlAction(0, 140, true) -- R key
            
            -- Check if F key is pressed to stop prospecting
            if IsControlJustPressed(0, 23) then -- F key (INPUT_ENTER)
                StopProspecting()
                break
            end
            
            if not IsEntityPlayingAnim(ped, "mini@golfai", "wood_idle_a", 3) then
                PlayAnimUpper(ped, "mini@golfai", "wood_idle_a")
            end

            -- Actions that halt prospecting animations and scanning
            local restrictedMovement = IsPedFalling(ped) or IsPedJumping(ped) or IsPedSprinting(ped) or 
                                       IsPedRunning(ped) or IsPedRagdoll(ped) or IsPedInAnyVehicle(ped) or 
                                       IsPedInCover(ped) or IsPedInMeleeCombat(ped)

            if restrictedMovement then canProspect = false end
            if pauseProspecting then 
                canProspect = false 
                DisableAllInstructions()
            end
            
            if canProspect then
                local pos = GetEntityCoords(ped) + vector3(GetEntityForwardX(ped) * 0.75, GetEntityForwardY(ped) * 0.75, -0.75)
                -- local pos = GetWorldPositionOfEntityBone(scannerEntity, 0)
                local target, dist, index, difficulyModifier = getClosestTarget(pos)
                
                -- Debug every iteration when canProspect is true
                if Config.debug and math.random(1, 20) == 1 then
                    print("^6[DEBUG] IN canProspect block - index:", index, "dist:", dist and string.format("%.2f", dist) or "nil", "targets:", #targets)
                end
                
                if index then
                    -- Target found, processing...
                    local dist = dist * difficulyModifier
                    -- Reduce wait time when near target
                    if dist < 30.0 then
                        sleepTime = 0 -- Need fast response when detecting
                    end
                    
                    if dist < 7.0 then
                        -- Debug: Print target coordinates
                        if Config.debug and math.random(1, 50) == 1 and target then
                            local targetVec = targets[index][1]
                            print(string.format("^2[CAN DIG] Target at: %s | Distance: %.2fm", tostring(targetVec), dist))
                        end
                        
                        local digLabel = GetLabelText("PROSP_DIG")
                        if digLabel == "NULL" or digLabel == "PROSP_DIG" then digLabel = "Dig" end
                        
                        local audioLabel = scannerAudio and GetLabelText("PROSP_AUDIOOFF") or GetLabelText("PROSP_AUDIOON")
                        if audioLabel == "NULL" then audioLabel = scannerAudio and "Audio Off" or "Audio On" end
                        
                        local textContent = string.format('[E] %s  [F] %s', digLabel, audioLabel)
                        
                        if currentTextUI ~= textContent then
                            if textUIShown then lib.hideTextUI() end
                            lib.showTextUI(textContent, {
                                position = "right-center",
                                icon = 'fa-solid fa-shovel'
                            })
                            textUIShown = true
                            currentTextUI = textContent
                        end
                        
                        -- Input check (E key is control 38)
                        if IsDisabledControlJustPressed(0, 38) then
                            if Config.debug and target then
                                local targetVec = targets[index][1]
                                print(string.format("^3[DIGGING] Target: %s | Distance: %.2fm", tostring(targetVec), dist))
                            end
                            DigTarget(index)
                        end
                    else
                        -- Hiển thị với màu sắc thay đổi theo khoảng cách
                        local audioLabel = scannerAudio and GetLabelText("PROSP_AUDIOOFF") or GetLabelText("PROSP_AUDIOON")
                        if audioLabel == "NULL" then audioLabel = scannerAudio and "Audio Off" or "Audio On" end
                        
                        -- Màu sắc theo khoảng cách: đỏ < 10m < vàng < 20m < xanh < 30m < trắng
                        local distanceText, iconColor
                        if dist < 10.0 then
                            distanceText = string.format('🔴 %.1fm', dist)
                            iconColor = 'red'
                        elseif dist < 20.0 then
                            distanceText = string.format('🟡 %.1fm', dist)
                            iconColor = 'yellow'
                        elseif dist < 30.0 then
                            distanceText = string.format('🟢 %.1fm', dist)
                            iconColor = 'green'
                        else
                            distanceText = string.format('⚪ %.1fm', dist)
                            iconColor = 'white'
                        end
                        
                        local textContent = string.format('[F] %s | %s', audioLabel, distanceText)
                        
                        if Config.debug and math.random(1, 30) == 1 then
                            print(string.format("^4[DEBUG] Showing TextUI: %s | textUIShown=%s", textContent, tostring(textUIShown)))
                        end
                        
                        if currentTextUI ~= textContent then
                            if textUIShown then lib.hideTextUI() end
                            lib.showTextUI(textContent, {
                                position = "right-center",
                                icon = 'fa-solid fa-magnifying-glass'
                            })
                            textUIShown = true
                            currentTextUI = textContent
                        end
                    end
                    if dist < 7.0 then
                        circleScale = 0.0
                        scannerScale = 0.0
                        scannerState = "ultra"
                    elseif dist < 8.0 then
                        scannerFrametime = 0.35
                        scannerScale = 4.50
                        scannerState = "fast"
                    elseif dist < 7.0 then
                        scannerFrametime = 0.4
                        scannerScale = 3.75
                        scannerState = "fast"
                    elseif dist < 8.5 then
                        scannerFrametime = 0.425
                        scannerScale = 3.00
                        scannerState = "fast"
                    elseif dist < 7.5 then
                        scannerFrametime = 0.45
                        scannerScale = 2.50
                        scannerState = "fast"
                    elseif dist < 10.0 then
                        scannerFrametime = 0.5
                        scannerScale = 1.75
                        scannerState = "fast"
                    elseif dist < 12.5 then
                        scannerFrametime = 0.75
                        scannerScale = 1.25
                        scannerState = "medium"
                    elseif dist < 15.0 then
                        scannerFrametime = 1.0
                        scannerScale = 1.00
                        scannerState = "medium"
                    elseif dist < 20.0 then
                        scannerFrametime = 1.25
                        scannerScale = 0.875
                        scannerState = "medium"
                    elseif dist < 25.0 then
                        scannerFrametime = 1.5
                        scannerScale = 0.75
                        scannerState = "slow"
                    elseif dist < 30.0 then
                        scannerFrametime = 2.0
                        scannerScale = 0.5
                        scannerState = "slow"
                    elseif dist < 50.0 then
                        scannerFrametime = 3.0
                        scannerScale = 0.4
                        scannerState = "very_slow"
                    elseif dist < 75.0 then
                        scannerFrametime = 4.0
                        scannerScale = 0.3
                        scannerState = "very_slow"
                    elseif dist < 100.0 then
                        scannerFrametime = 5.0
                        scannerScale = 0.25
                        scannerState = "very_slow"
                    else
                        scannerFrametime = 6.0
                        scannerScale = 0.2
                        scannerState = "ultra_slow"
                    end
                    scannerDistance = dist
                else
                    -- No target found - log every time to debug
                    if Config.debug then print("^1[DEBUG] No target found - targets size:", #targets, "pauseProspecting:", pauseProspecting, "canProspect:", canProspect) end
                    circleScale = 0.0
                    scannerScale = 0.0
                    scannerState = "none"
                    DisableAllInstructions()
                end
            else
                -- canProspect is FALSE - log why
                if Config.debug and math.random(1, 20) == 1 then
                    print("^1[DEBUG] canProspect=FALSE - pauseProspecting:", pauseProspecting, "restrictedMovement:", restrictedMovement or false)
                end
            end
            
            if canProspect then
                if IsDisabledControlJustPressed(0, 140) then -- R key (chỉ toggle audio)
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
                    scannerAudio = not scannerAudio
                end
            end
            if not canProspect then
                -- Ped is busy and can't prospect at this time (like falling or w/e)
                StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
                circleScale = 0.0
                scannerScale = 0.0
                scannerState = "none"
            end
            if not isProspecting then
                -- We stopped prospecting mid-frame
                CleanupModels()
                StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
                circleScale = 0.0
                scannerScale = 0.0
                scannerState = "none"
            end
        end
        DisableAllInstructions()
        StopProspecting()
    end)

    -- Marker rendering & Audio
    CreateThread(function()
        local framecount = 0
        local frametime = 0
        local localCircleScale = 0.0
        local circleR, circleG, circleB, circleA = 255, 255, 255, 255
        local _circleR, _circleG, _circleB = 255, 255, 255
        local circleScaleMultiplier = 1.5
        local renderCircle = false
        local ped = PlayerPedId()
        while isProspecting do
            if not pauseProspecting then
                Wait(0) -- Must be 0 for smooth marker rendering
            else
                Wait(100) -- Longer wait when paused
            end
            if not pauseProspecting then
                ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local fwd = GetEntityForwardVector(ped)
                local pos = coords + vector3(fwd.x * 0.75, fwd.y * 0.75, -0.75)
                -- local pos = GetWorldPositionOfEntityBone(scannerEntity, 0)
                if scannerState == "none" then
                    renderCircle = false
                    localCircleScale = 0.0
                    circleR, circleG, circleB = 150, 255, 150
                    _circleR, _circleG, _circleB = 150, 255, 150
                elseif scannerState == "slow" then
                    renderCircle = true
                    localCircleScale = localCircleScale + scannerScale
                    circleR, circleG, circleB = 150, 255, 150
                    if frametime > scannerFrametime then
                        frametime = 0.0
                    end
                    -- circleSize = (circleScale % 100) / 100
                    -- circleA = math.floor(255 - ((circleScale % 100) / 100) * 255)
                    -- DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.1, circleR, circleG, circleB, circleA)
                elseif scannerState == "medium" then
                    renderCircle = true
                    localCircleScale = localCircleScale + scannerScale
                    circleR, circleG, circleB = 255, 255, 150
                    if frametime > scannerFrametime then
                        frametime = 0.0
                    end
                    -- circleSize = (circleScale % 100) / 100
                    -- circleA = math.floor(255 - ((circleScale % 100) / 100) * 255)
                    -- DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.1, circleR, circleG, circleB, circleA)
                elseif scannerState == "fast" then
                    renderCircle = true
                    localCircleScale = localCircleScale + scannerScale
                    circleR, circleG, circleB = 255, 150, 150
                    if frametime > scannerFrametime then
                        frametime = 0.0
                    end
                elseif scannerState == "very_slow" then
                    renderCircle = true
                    localCircleScale = localCircleScale + scannerScale
                    circleR, circleG, circleB = 100, 200, 100 -- Màu xanh lá cho xa
                    if frametime > scannerFrametime then
                        frametime = 0.0
                        if Config.debug and math.random(1, 30) == 1 then
                            print(string.format("^2[DEBUG] Very slow beep - scannerAudio=%s, frametime=%.2f", tostring(scannerAudio), frametime))
                        end
                    end
                elseif scannerState == "ultra_slow" then
                    renderCircle = true
                    localCircleScale = localCircleScale + scannerScale
                    circleR, circleG, circleB = 150, 150, 150 -- Màu xám cho rất xa
                    if frametime > scannerFrametime then
                        frametime = 0.0
                        if Config.debug and math.random(1, 30) == 1 then
                            print(string.format("^7[DEBUG] Ultra slow beep - scannerAudio=%s, frametime=%.2f", tostring(scannerAudio), frametime))
                        end
                    end
                elseif scannerState == "ultra" then
                    renderCircle = false
                    localCircleScale = localCircleScale + scannerScale
                    circleR, circleG, circleB = 255, 100, 100
                    if frametime > 0.125 then
                        frametime = 0.0
                        if scannerAudio then PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0) end
                        -- PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 0)
                        if scannerAudio then PlaySoundFrontend(-1, "BOATS_PLANES_HELIS_BOOM", "MP_LOBBY_SOUNDS", 0) end
                    end
                    -- Draw the triple "found it" marker
                    circleA = 150
                    circleSize = 1.20 * circleScaleMultiplier
                    DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.2, circleR, circleG, circleB, circleA)
                    DrawMarker(6, pos, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, circleSize, 0.1, circleSize, circleR, circleG, circleB, circleA)
                    circleA = 200
                    circleSize = 0.70 * circleScaleMultiplier
                    DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.2, circleR, circleG, circleB, circleA)
                    DrawMarker(6, pos, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, circleSize, 0.1, circleSize, circleR, circleG, circleB, circleA)
                    circleA = 255
                    circleSize = 0.20 * circleScaleMultiplier
                    DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.2, circleR, circleG, circleB, circleA)
                    DrawMarker(6, pos, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, circleSize, 0.1, circleSize, circleR, circleG, circleB, circleA)
                end
                if renderCircle then
                    if localCircleScale > 100 then
                        while localCircleScale > 100 do
                            localCircleScale = localCircleScale - 100
                        end
                        _circleR, _circleG, _circleB = circleR, circleG, circleB
                        -- PlaySoundFrontend(-1, "BOATS_PLANES_HELIS_BOOM", "MP_LOBBY_SOUNDS", 0)
                        if scannerAudio then PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0) end
                    end
                    circleSize = ((localCircleScale % 100) / 100) * circleScaleMultiplier
                    circleA = math.floor(255 - ((localCircleScale % 100) / 100) * 155)
                    DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.2, _circleR, _circleG, _circleB, circleA)
                    DrawMarker(6, pos, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, circleSize, 0.1, circleSize, _circleR, _circleG, _circleB, circleA)
                end

                framecount = (framecount + 1) % 120
                frametime = frametime + Timestep()
            end
        end
    end)

    -- Location updater
    -- Adds nearby targets to the target pool
    -- Prevents client from doing frame-checks on targets across the map
    CreateThread(function()
        while isProspecting do
            local pos = GetEntityCoords(PlayerPedId())
            local newTargets = {}
            
            -- Check if player is still in prospecting zone
            local distFromCenter = #(pos - Config.BlipLocation)
            if distFromCenter > Config.AreaSize then
                -- Player left the zone, stop prospecting completely
                if Config.debug then print("^1[DEBUG] Player left prospecting zone (dist: " .. distFromCenter .. "m), stopping") end
                lib.notify({
                    description = 'Bạn đã rời khỏi khu vực dò mìn!',
                    type = 'error',
                    duration = 3000
                })
                StopProspecting()
                break -- Exit the loop
            end
            
            -- Load targets within range
            for n, target in next, targetPool do
                -- Skip if already dug
                if not dugTargets[n] and #(pos.xy - target[1].xy) < maxTargetRange then
                    newTargets[#newTargets + 1] = {target[1], target[2], n}
                end
            end
            
            targets = newTargets
            local dugCount = 0
            for _ in pairs(dugTargets) do dugCount = dugCount + 1 end
            if Config.debug then print("^5[DEBUG] Targets updated - targetPool size:", #targetPool, "nearby targets:", #targets, "dug count:", dugCount) end
            Wait(5000) -- Check every 5 seconds instead of 10
        end
    end)
    return true
end

RegisterNetEvent('client:doramin', function()
    PoliceCall()
end)

function PoliceCall() 
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    exports['ld-dispatch']:sendDispatch(
        {
            title = "Dò Bom",
            code = "12-10B",
            values = {
                {
                    text = "Dò Bom",
                    icon = "fa-solid fa-earth-americas",
                },
                {
                    text = "2 sao",
                    icon = "fa-solid fa-hashtag",
                },
            },
            valuestwo = {}, -- DON'T TOUCH
            jobs = {"police"},
            active = false,-- DON'T TOUCH
            dispatchnumber = nil,-- DON'T TOUCH
            coords = plyCoords,
            blip = {
                blipid = 486,
                blipcolor = 1,
            }
        }
    ) 
end

-- Handle trap damage from server
RegisterNetEvent('xn_domin:applyTrapDamage', function(damageAmount)
    local ped = PlayerPedId()
    local currentHealth = GetEntityHealth(ped)
    local newHealth = math.max(0, currentHealth - damageAmount)
    SetEntityHealth(ped, newHealth)
end)