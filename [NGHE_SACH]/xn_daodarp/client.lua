-- lib is provided by ox_lib via fxmanifest.lua
---@diagnostic disable-next-line: undefined-global
local lib = lib

local QBCore = exports['qb-core']:GetCoreObject()

-- Persistent system - rocks never disappear, only created once
local rockObjects = {} -- Permanent rock objects (created once on resource start)
local currentCarriedRock = nil
local isCarryingRock = false
local processingZones = {}
local processingProps = {} -- Permanent processing props

-- Busy state management for progressbar
local isBusy = false

-- Shop NPC variables
local npcPoint = nil
local shopPed = nil

-- Animation protection threads
local animationProtectionThread = nil
local controlProtectionThread = nil

-- Optimized: Ultra-minimal system - no prop creation/deletion during gameplay
-- All props are permanent and persist throughout the entire resource lifecycle

-- Function to start animation protection
local function StartAnimationProtection()
    if animationProtectionThread then return end
    
    animationProtectionThread = CreateThread(function()
        while isCarryingRock do
            if not isCarryingRock then break end -- Double check
            
            local ped = PlayerPedId()
            
            if not IsEntityPlayingAnim(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 3) then
                TaskPlayAnim(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 8.0, -8.0, -1, Config.CarryingAnimation.flag, 0, false, false, false)
            end
            
            Wait(2000) -- Increased to reduce CPU usage even more
        end
        
        animationProtectionThread = nil
    end)
end

-- Function to stop animation protection
local function StopAnimationProtection()
    if animationProtectionThread then
        animationProtectionThread = nil
    end
end

-- Function to stop control protection thread  
local function StopControlProtection()
    if controlProtectionThread then
        controlProtectionThread = nil
    end
end

-- Function to cleanup all threads
local function CleanupAllThreads()
    --print('Debug: CleanupAllThreads - Force stopping all threads and animations')
    
    -- Stop all protection threads
    StopAnimationProtection()
    StopControlProtection()
    
    -- Force cleanup threads
    animationProtectionThread = nil
    controlProtectionThread = nil
    
    -- Reset carrying state
    isCarryingRock = false
    
    -- Force cleanup all animation dicts to prevent memory leaks
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    
    -- Force remove all potential animation dicts
    RemoveAnimDict(Config.Animation.dict)
    RemoveAnimDict(Config.CarryingAnimation.dict)
    RemoveAnimDict(Config.ProcessingAnimation.dict)
    RemoveAnimSet(Config.CarryingAnimation.movementClipset)
    
    --print('Debug: CleanupAllThreads - Complete')
end

-- Function to create blips
local function CreateJobBlips()
    for _, blipData in pairs(Config.Blips) do
        if blipData.enabled then
            local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
            SetBlipSprite(blip, blipData.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, blipData.scale)
            SetBlipColour(blip, blipData.color)
            SetBlipAsShortRange(blip, true)
            
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(blipData.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end

-- Initialize system on resource start - create all permanent objects
CreateThread(function()
    CreateAllPermanentRocks()
    CreateProcessingZones() 
    CreateAllPermanentProcessingProps()
    CreateJobBlips()
end)

-- Create all rocks permanently (never delete during gameplay)
function CreateAllPermanentRocks()
    --print('Debug: Creating all permanent rock objects...')
    local created = 0
    
    for i, location in pairs(Config.RockLocations) do
        if CreatePermanentRock(i, location) then
            created = created + 1
        end
    end
    
    --print('Debug: Created ' .. created .. ' permanent rock objects')
end

-- Create a single permanent rock (exists for entire resource lifetime)
function CreatePermanentRock(index, location)
    --print('Debug: Creating permanent rock ' .. index)
    
    local rockHash = GetHashKey(Config.RockModel)
    RequestModel(rockHash)
    
    local attempts = 0
    while not HasModelLoaded(rockHash) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end
    
    if not HasModelLoaded(rockHash) then
        --print('Debug: Failed to load rock model')
        return false
    end
    
    local rock = CreateObject(rockHash, location.x, location.y, location.z - 1.0, false, false, false)
    
    if not DoesEntityExist(rock) then
        --print('Debug: Failed to create permanent rock')
        return false
    end
    
    PlaceObjectOnGroundProperly(rock)
    FreezeEntityPosition(rock, true)
    SetEntityVisible(rock, true, false) -- Always visible, never hidden
    
    rockObjects[index] = rock
    --print('Debug: Permanent rock ' .. index .. ' created with ID: ' .. rock)
    
    -- Add permanent interaction (rock never changes state)
    exports.ox_target:addLocalEntity(rock, {
        {
            name = 'mine_permanent_rock_' .. index,
            label = 'Đào đá',
            icon = 'fas fa-hammer',
            distance = Config.InteractionDistance,
            onSelect = function()
                MinePermanentRock(index, location)
            end,
            canInteract = function()
                return not isCarryingRock and HasRequiredItem()
            end
        }
    })
    
    SetModelAsNoLongerNeeded(rockHash)
    return true
end

-- Check if player has required item
function HasRequiredItem()
    local drillSlots = exports.ox_inventory:Search('slots', Config.RequiredItem)
    
    if drillSlots and #drillSlots > 0 then
        for _, drillSlot in pairs(drillSlots) do
            local durability = drillSlot.metadata and drillSlot.metadata.durability or 100
            if durability > 0 then
                return true
            end
        end
    end
    
    return false
end

-- Mine permanent rock (rock never disappears)
function MinePermanentRock(index, location)
    -- Check if player is in vehicle
    if Config.IsPlayerInVehicle() then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn không thể đào đá khi đang ngồi trên xe!',
            type = Config.Notifications.error
        })
        return
    end
    
    -- Check if player is busy with progressbar
    local busy = exports["progressbar"]:isDoingSomething()
    if busy or isBusy then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn đang thực hiện hành động khác!',
            type = Config.Notifications.error
        })
        return
    end
    
    if isCarryingRock then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn đang mang một viên đá!',
            type = Config.Notifications.error
        })
        return
    end
    
    if not HasRequiredItem() then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn cần ' .. Config.GetItemLabel(Config.RequiredItem) .. ' để đào!',
            type = Config.Notifications.error
        })
        return
    end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Check distance
    if #(coords - location) > Config.InteractionDistance then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn quá xa vị trí đào!',
            type = Config.Notifications.error
        })
        return
    end
    
    -- Set busy state
    isBusy = true
    
    -- Start mining
    exports['progressbar']:Progress({
        name = "mining_rock",
        duration = Config.MiningTime,
        label = "Đang đào đá...",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = Config.Animation.dict,
            anim = Config.Animation.anim,
            flags = Config.Animation.flag,
        },
        prop = {
            model = Config.Prop.model,
            bone = Config.Prop.bone,
            coords = vec3(0.0, 0.15, 0.0),
            rotation = vec3(90.0, 0.0, 0.0),
        }
    }, function(cancelled)
        -- Reset busy state
        isBusy = false
        
        if not cancelled then
            -- Mining successful - rock stays exactly as it is (no changes)
            --print('Debug: Successfully mined from permanent rock ' .. index .. ' (rock remains)')
            
            -- Give player the carried rock
            GiveCarriedRock()
            
            -- Reduce drill durability
            TriggerServerEvent('xn_daodarp:reduceDurability')
            
            lib.notify({
                title = 'Thông báo',
                description = 'Bạn đã đào được một viên đá! Đá vẫn ở đây để đào tiếp.',
                type = Config.Notifications.success
            })
            
            -- Clean up animation
            RemoveAnimDict(Config.Animation.dict)
        else
            -- Mining cancelled
            RemoveAnimDict(Config.Animation.dict)
            lib.notify({
                title = 'Thông báo',
                description = 'Đào đá bị hủy!',
                type = Config.Notifications.error
            })
        end
    end)
end

-- Give carried rock (reuse prop system)
function GiveCarriedRock()
    local ped = PlayerPedId()
    isCarryingRock = true
    
    -- Load carrying animation
    RequestAnimDict(Config.CarryingAnimation.dict)
    local timeout = 0
    while not HasAnimDictLoaded(Config.CarryingAnimation.dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasAnimDictLoaded(Config.CarryingAnimation.dict) then
        --print('Debug: Failed to load carrying animation dict')
        isCarryingRock = false
        return
    end
    
    TaskPlayAnim(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 8.0, -8.0, -1, Config.CarryingAnimation.flag, 0, false, false, false)
    
    -- Create or reuse carried rock prop
    if not currentCarriedRock or not DoesEntityExist(currentCarriedRock) then
        local propHash = GetHashKey(Config.CarryingRockPlacement.model)
        RequestModel(propHash)
        
        local timeout2 = 0
        while not HasModelLoaded(propHash) and timeout2 < 5000 do
            Wait(10)
            timeout2 = timeout2 + 10
        end
        
        if HasModelLoaded(propHash) then
            currentCarriedRock = CreateObject(propHash, 0, 0, 0, true, true, true)
            SetModelAsNoLongerNeeded(propHash)
        end
    end
    
    -- Attach prop to player if it exists
    if currentCarriedRock and DoesEntityExist(currentCarriedRock) then
        AttachEntityToEntity(
            currentCarriedRock, 
            ped, 
            GetPedBoneIndex(ped, Config.CarryingRockPlacement.bone), 
            Config.CarryingRockPlacement.pos.x, 
            Config.CarryingRockPlacement.pos.y, 
            Config.CarryingRockPlacement.pos.z, 
            Config.CarryingRockPlacement.rot.x, 
            Config.CarryingRockPlacement.rot.y, 
            Config.CarryingRockPlacement.rot.z, 
            true, true, false, true, 1, true
        )
        
        SetEntityVisible(currentCarriedRock, true, false)
    end
    
    -- Set movement clipset
    RequestAnimSet(Config.CarryingAnimation.movementClipset)
    local timeout3 = 0
    while not HasAnimSetLoaded(Config.CarryingAnimation.movementClipset) and timeout3 < 5000 do
        Wait(10)
        timeout3 = timeout3 + 10
    end
    
    if HasAnimSetLoaded(Config.CarryingAnimation.movementClipset) then
        SetPedMovementClipset(ped, Config.CarryingAnimation.movementClipset, 0.2)
    end
    
    -- Start protection threads
    StartAnimationProtection()
    
    if Config.DisableControlsWhileCarrying then
        controlProtectionThread = CreateThread(function()
            local lastNotification = 0
            local ped = PlayerPedId()
            
            SetPedCanRagdoll(ped, false)
            SetPedCanBeDraggedOut(ped, false)
            
            while isCarryingRock do
                if not isCarryingRock then break end -- Double check
                
                local ped = PlayerPedId()
                local currentTime = GetGameTimer()
                
                local essentialControls = {20, 21, 22, 73, 177, 322}
                for _, control in pairs(essentialControls) do
                    DisableControlAction(0, control, true)
                    
                    if IsDisabledControlJustPressed(0, control) then
                        if currentTime - lastNotification > 3000 then
                            lib.notify({
                                title = 'Thông báo',
                                description = 'Không thể thực hiện khi đang mang đá!',
                                type = Config.Notifications.error
                            })
                            lastNotification = currentTime
                        end
                    end
                end
                
                -- Less frequent animation check
                if not IsEntityPlayingAnim(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 3) then
                    TaskPlayAnim(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 8.0, -8.0, -1, Config.CarryingAnimation.flag, 0, false, false, false)
                end
                
                if IsPedInAnyVehicle(ped, false) then
                    TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
                end
                
                Wait(1000) -- Increased wait time
            end
            
            -- Cleanup when thread ends
            local ped = PlayerPedId()
            SetPedCanRagdoll(ped, true)
            SetPedCanBeDraggedOut(ped, true)
            controlProtectionThread = nil
        end)
    end
end

-- Remove carried rock (complete cleanup)
function RemoveCarriedRock()
    --print('Debug: RemoveCarriedRock - Starting COMPLETE cleanup')
    local ped = PlayerPedId()
    
    -- STEP 1: Stop all threads immediately
    isCarryingRock = false
    StopAnimationProtection()
    StopControlProtection()
    
    -- STEP 2: Wait for threads to completely stop
    Wait(500) -- Increased wait time
    
    -- STEP 3: Force stop ALL player tasks
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    StopAnimTask(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 3.0)
    
    -- STEP 4: Detach and hide carried rock prop
    if currentCarriedRock and DoesEntityExist(currentCarriedRock) then
        DetachEntity(currentCarriedRock, true, true) -- Force detach with collision
        SetEntityVisible(currentCarriedRock, false, false)
        SetEntityCoords(currentCarriedRock, 0, 0, -200, false, false, false, false) -- Move far underground
        FreezeEntityPosition(currentCarriedRock, true) -- Freeze to prevent physics
    end
    
    -- STEP 5: Reset player movement completely
    ResetPedMovementClipset(ped, 0.2)
    Wait(100) -- Let it apply
    ResetPedMovementClipset(ped, 0.0) -- Force immediate reset
    
    -- STEP 6: Restore all player capabilities
    SetPedCanRagdoll(ped, true)
    SetPedCanBeDraggedOut(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
    
    -- STEP 7: FORCE cleanup ALL animation dictionaries
    RemoveAnimDict(Config.CarryingAnimation.dict)
    RemoveAnimDict(Config.Animation.dict)
    RemoveAnimDict(Config.ProcessingAnimation.dict)
    RemoveAnimSet(Config.CarryingAnimation.movementClipset)
    
    -- STEP 8: Additional cleanup for any remaining anims
    local additionalDicts = {
        "anim@heists@box_carry@",
        "amb@world_human_const_drill@male@drill@base"
    }
    
    for _, dict in pairs(additionalDicts) do
        if HasAnimDictLoaded(dict) then
            RemoveAnimDict(dict)
        end
    end
    
    --print('Debug: RemoveCarriedRock - All animations and dicts force removed')
    
    -- STEP 9: Re-enable ALL controls with delay
    CreateThread(function()
        Wait(500) -- Give time for complete cleanup
        
        -- Re-enable all possible controls
        local allControls = {20, 21, 22, 23, 24, 25, 73, 177, 322, 200, 202}
        for _, control in pairs(allControls) do
            for inputGroup = 0, 2 do
                EnableControlAction(inputGroup, control, true)
            end
        end
        
        -- Force clear any remaining disabled controls
        local ped = PlayerPedId()
        SetPedCanRagdoll(ped, true)
        SetPedCanBeDraggedOut(ped, true)
        
        --print('Debug: RemoveCarriedRock - All controls fully re-enabled')
    end)
    
    --print('Debug: RemoveCarriedRock - COMPLETE cleanup finished')
end

-- Create processing zones
function CreateProcessingZones()
    for i, location in pairs(Config.ProcessingLocations) do
        local coords = location.coords
        
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            options = {
                {
                    name = 'process_permanent_rock_' .. i,
                    label = 'Cắt đá',
                    icon = 'fas fa-cut',
                    onSelect = function()
                        ProcessCarriedRock()
                    end,
                    canInteract = function()
                        return isCarryingRock
                    end
                }
            }
        })
        
        processingZones[i] = true
    end
end

-- Create all permanent processing props
function CreateAllPermanentProcessingProps()
    for i, location in pairs(Config.ProcessingLocations) do
        local coords = location.coords
        local heading = location.heading
        
        local propHash = GetHashKey(Config.ProcessingProp.model)
        RequestModel(propHash)
        
        while not HasModelLoaded(propHash) do
            Wait(1)
        end
        
        local prop = CreateObject(
            propHash, 
            coords.x + Config.ProcessingProp.spawnOffset.x, 
            coords.y + Config.ProcessingProp.spawnOffset.y, 
            coords.z + Config.ProcessingProp.spawnOffset.z - 1.0, 
            false, false, false
        )
        
        SetEntityHeading(prop, heading)
        PlaceObjectOnGroundProperly(prop)
        FreezeEntityPosition(prop, true)
        
        processingProps[i] = prop
        SetModelAsNoLongerNeeded(propHash)
    end
end

-- Process carried rock (permanent system with 2-step process)
function ProcessCarriedRock()
    -- Check if player is in vehicle
    if Config.IsPlayerInVehicle() then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn không thể sẻ đá khi đang ngồi trên xe!',
            type = Config.Notifications.error
        })
        return
    end
    
    -- Check if player is busy with progressbar
    local busy = exports["progressbar"]:isDoingSomething()
    if busy or isBusy then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn đang thực hiện hành động khác!',
            type = Config.Notifications.error
        })
        return
    end
    
    if not isCarryingRock then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn không mang viên đá nào!',
            type = Config.Notifications.error
        })
        return
    end
    
    local ped = PlayerPedId()
    local wasCarrying = isCarryingRock
    local playerCoords = GetEntityCoords(ped)
    
    -- Find nearest processing prop (bandsaw)
    local nearestBandsaw = nil
    local nearestDistance = 999.0
    
    for i, prop in pairs(processingProps) do
        if prop and DoesEntityExist(prop) then
            local propCoords = GetEntityCoords(prop)
            local distance = #(playerCoords - propCoords)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestBandsaw = prop
            end
        end
    end
    
    if not nearestBandsaw or nearestDistance > Config.InteractionDistance then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn cần đứng gần máy cắt để xử lý đá!',
            type = Config.Notifications.error
        })
        return
    end
    
    -- SET STATE IMMEDIATELY HERE TO LOCK ACTIONS AND TARGET
    isBusy = true
    isCarryingRock = false
    TriggerServerEvent('xn_daodarp:startProcessing')
    
    -- STEP 1: Place rock on bandsaw
    --print('Debug: Step 1 - Placing rock on bandsaw')
    
    -- Temporarily pause carrying animations for placement
    StopAnimationProtection()
    
    -- Force stop ALL animations and tasks first
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    StopAnimTask(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 1.0)
    
    -- Reset movement clipset with proper wait
    ResetPedMovementClipset(ped, 0.0)
    Wait(200)
    
    -- Remove carried rock prop and create rock on bandsaw
    if currentCarriedRock and DoesEntityExist(currentCarriedRock) then
        DeleteEntity(currentCarriedRock)
        currentCarriedRock = nil
    end
    
    -- Create rock prop on bandsaw
    local bandsawCoords = GetEntityCoords(nearestBandsaw)
    local bandsawHeading = GetEntityHeading(nearestBandsaw)
    local rockOnBandsaw = CreateObject(GetHashKey(Config.CarryingRockPlacement.model), 
        bandsawCoords.x, bandsawCoords.y, bandsawCoords.z + 0.5, false, false, false)
    
    if not rockOnBandsaw or not DoesEntityExist(rockOnBandsaw) then
        isBusy = false
        isCarryingRock = true
        TriggerServerEvent('xn_daodarp:cancelProcessing')
        lib.notify({
            title = 'Lỗi',
            description = 'Không thể đặt đá lên máy cắt!',
            type = Config.Notifications.error
        })
        return
    end
    
    SetEntityHeading(rockOnBandsaw, bandsawHeading)
    PlaceObjectOnGroundProperly(rockOnBandsaw)
    --print('Debug: Rock placed on bandsaw successfully')
    
    -- Brief notification
    lib.notify({
        title = 'Thông báo',
        description = 'Đã đặt đá lên máy cắt...',
        type = Config.Notifications.info
    })
    
    Wait(1000) -- Brief pause to show placement
    
    -- STEP 2: Start processing with drilling animation
    --print('Debug: Step 2 - Starting processing with drilling animation')
    
    -- (isBusy is already true)
    
    exports['progressbar']:Progress({
        name = "processing_rock",
        duration = 3000,
        label = "Đang cắt đá...",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = Config.ProcessingAnimation.dict,
            anim = Config.ProcessingAnimation.anim,
            flags = Config.ProcessingAnimation.flag,
        }
    }, function(cancelled)
        -- Reset busy state
        isBusy = false
        
        if not cancelled then
            -- Processing successful
            --print('Debug: Processing successful - cleaning up')
            
            -- Remove rock from bandsaw
            if rockOnBandsaw and DoesEntityExist(rockOnBandsaw) then
                DeleteEntity(rockOnBandsaw)
                --print('Debug: Rock removed from bandsaw')
            end
            
            -- Force cleanup processing animation
            RemoveAnimDict(Config.ProcessingAnimation.dict)
            
            -- Complete cleanup
            CleanupAllThreads()
            RemoveCarriedRock()
            
            -- Give reward
            TriggerServerEvent('xn_daodarp:giveReward')
            
            lib.notify({
                title = 'Thông báo',
                description = 'Cắt đá thành công! Nhận được ' .. Config.RewardAmount .. ' ' .. Config.GetItemLabel(Config.RewardItem) .. '. Các viên đá vẫn có thể đào tiếp!',
                type = Config.Notifications.success
            })
            
            --print('Debug: Processing complete - all cleanup finished')
        else
            -- Processing cancelled
            --print('Debug: Processing cancelled - cleaning up')
            
            TriggerServerEvent('xn_daodarp:cancelProcessing')
            
            -- Remove rock from bandsaw
            if rockOnBandsaw and DoesEntityExist(rockOnBandsaw) then
                DeleteEntity(rockOnBandsaw)
                --print('Debug: Rock removed from bandsaw (cancelled)')
            end
            
            -- Cleanup processing animation
            RemoveAnimDict(Config.ProcessingAnimation.dict)
            
            -- Recreate carried rock and restore carrying state
            currentCarriedRock = CreateObject(GetHashKey(Config.CarryingRockPlacement.model), 
                playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
                
            if currentCarriedRock and DoesEntityExist(currentCarriedRock) then
                AttachEntityToEntity(currentCarriedRock, ped, 
                    GetPedBoneIndex(ped, Config.CarryingRockPlacement.bone),
                    Config.CarryingRockPlacement.pos.x, 
                    Config.CarryingRockPlacement.pos.y, 
                    Config.CarryingRockPlacement.pos.z,
                    Config.CarryingRockPlacement.rot.x, 
                    Config.CarryingRockPlacement.rot.y, 
                    Config.CarryingRockPlacement.rot.z,
                    true, true, false, true, 1, true)
            end
            
            -- Restore carrying animation
            RequestAnimDict(Config.CarryingAnimation.dict)
            while not HasAnimDictLoaded(Config.CarryingAnimation.dict) do
                Wait(10)
            end
            
            TaskPlayAnim(ped, Config.CarryingAnimation.dict, Config.CarryingAnimation.anim, 8.0, -8.0, -1, Config.CarryingAnimation.flag, 0, false, false, false)
            
            -- Restore movement clipset
            RequestAnimSet(Config.CarryingAnimation.movementClipset)
            while not HasAnimSetLoaded(Config.CarryingAnimation.movementClipset) do
                Wait(10)
            end
            SetPedMovementClipset(ped, Config.CarryingAnimation.movementClipset, 0.2)
            
            -- Restart protection
            StartAnimationProtection()
            
            isCarryingRock = true -- Restore carrying state
            
            lib.notify({
                title = 'Thông báo',
                description = 'Cắt đá bị hủy!',
                type = Config.Notifications.error
            })
        end
    end)
end

-- Resource cleanup - delete all permanent objects
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        --print('Debug: Cleaning up all permanent objects...')
        
        isCarryingRock = false
        animationProtectionThread = nil
        controlProtectionThread = nil
        
        CleanupAllThreads()
        
        -- Delete carried rock prop
        if currentCarriedRock and DoesEntityExist(currentCarriedRock) then
            DeleteObject(currentCarriedRock)
        end
        
        -- Delete all permanent rock objects
        for _, rock in pairs(rockObjects) do
            if DoesEntityExist(rock) then
                DeleteObject(rock)
            end
        end
        
        -- Delete all permanent processing props
        for _, prop in pairs(processingProps) do
            if DoesEntityExist(prop) then
                DeleteObject(prop)
            end
        end
        
        -- Delete shop NPC if exists
        if shopPed and DoesEntityExist(shopPed) then
            DeleteEntity(shopPed)
        end
        if npcPoint then
            npcPoint:remove()
        end
        
        -- Cleanup animations
        RemoveAnimDict(Config.Animation.dict)
        RemoveAnimDict(Config.CarryingAnimation.dict)
        RemoveAnimSet(Config.CarryingAnimation.movementClipset)
        
        --print('Debug: All permanent objects cleaned up')
    end
end)

-- Player unload cleanup
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isCarryingRock = false
    animationProtectionThread = nil
    controlProtectionThread = nil
    
    CleanupAllThreads()
    
    if currentCarriedRock and DoesEntityExist(currentCarriedRock) then
        SetEntityVisible(currentCarriedRock, false, false)
    end
    
    RemoveAnimDict(Config.Animation.dict)
    RemoveAnimDict(Config.CarryingAnimation.dict)
    RemoveAnimSet(Config.CarryingAnimation.movementClipset)
end)

-- Debug command - check permanent rocks status
RegisterCommand('checkpermanentrocks', function()
    local totalRocks = #Config.RockLocations
    local existingObjects = 0
    
    --print('=== PERMANENT ROCKS STATUS ===')
    for i = 1, totalRocks do
        local rock = rockObjects[i]
        local hasObject = rock and DoesEntityExist(rock) or false
        
        if hasObject then
            existingObjects = existingObjects + 1
        end
        
        --print('Rock ' .. i .. ': HasObject=' .. tostring(hasObject) .. ' (Always available for mining)')
        if hasObject then
            --print('  Entity ID: ' .. tostring(rock))
        end
    end
    
    --print('=== SUMMARY ===')
    --print('Total rock locations: ' .. totalRocks)
    --print('Existing permanent objects: ' .. existingObjects)
    --print('All rocks are always available for mining')
    --print('===============')
    
    lib.notify({
        title = 'Debug',
        description = 'Permanent rocks: ' .. existingObjects .. '/' .. totalRocks .. ' (Always available)',
        type = 'inform'
    })
end, false)

-- Debug command - force cleanup everything
RegisterCommand('forcecleanup', function()
    --print('Debug: FORCE CLEANUP - Cleaning everything')
    
    -- Force stop all states
    isCarryingRock = false
    animationProtectionThread = nil
    controlProtectionThread = nil
    
    -- Force cleanup all threads
    CleanupAllThreads()
    
    -- Force remove carried rock
    RemoveCarriedRock()
    
    -- Additional cleanup
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    
    -- Force cleanup all possible animation dicts
    local allDicts = {
        Config.Animation.dict,
        Config.CarryingAnimation.dict, 
        Config.ProcessingAnimation.dict,
        "anim@heists@box_carry@",
        "amb@world_human_const_drill@male@drill@base"
    }
    
    for _, dict in pairs(allDicts) do
        if HasAnimDictLoaded(dict) then
            RemoveAnimDict(dict)
            --print('Debug: Removed dict: ' .. dict)
        end
    end
    
    -- Force cleanup animsets
    if HasAnimSetLoaded(Config.CarryingAnimation.movementClipset) then
        RemoveAnimSet(Config.CarryingAnimation.movementClipset)
        --print('Debug: Removed animset: ' .. Config.CarryingAnimation.movementClipset)
    end
    
    lib.notify({
        title = 'Debug',
        description = 'Force cleanup completed - all animations cleared',
        type = 'success'
    })
    
    --print('Debug: FORCE CLEANUP - Complete')
end, false)

-- Debug command - check resmon and threads
RegisterCommand('checkresmon', function()
    local threadCount = 0
    local carryingState = isCarryingRock
    local animThread = animationProtectionThread ~= nil
    local controlThread = controlProtectionThread ~= nil
    
    if animThread then threadCount = threadCount + 1 end
    if controlThread then threadCount = threadCount + 1 end
    
    --print('=== RESMON DEBUG ===')
    --print('Carrying rock: ' .. tostring(carryingState))
    --print('Animation thread active: ' .. tostring(animThread))
    --print('Control thread active: ' .. tostring(controlThread))
    --print('Total active threads: ' .. threadCount)
    
    -- Check loaded dicts
    local loadedDicts = 0
    local dicts = {
        Config.Animation.dict,
        Config.CarryingAnimation.dict,
        Config.ProcessingAnimation.dict
    }
    
    for _, dict in pairs(dicts) do
        if HasAnimDictLoaded(dict) then
            loadedDicts = loadedDicts + 1
            --print('Loaded dict: ' .. dict)
        end
    end
    
    --print('Total loaded dicts: ' .. loadedDicts)
    --print('===================')
    
    lib.notify({
        title = 'Resmon Debug',
        description = 'Threads: ' .. threadCount .. ' | Dicts: ' .. loadedDicts .. ' | Carrying: ' .. tostring(carryingState),
        type = 'inform'
    })
end, false)

-- Admin command - recreate all permanent objects
RegisterCommand('recreatepermanent', function()
    if QBCore.Functions.GetPlayerData().job.name == 'admin' then
        -- Clean up existing objects
        for _, rock in pairs(rockObjects) do
            if DoesEntityExist(rock) then
                exports.ox_target:removeLocalEntity(rock)
                DeleteObject(rock)
            end
        end
        
        for _, prop in pairs(processingProps) do
            if DoesEntityExist(prop) then
                DeleteObject(prop)
            end
        end
        
        -- Reset tables
        rockObjects = {}
        processingProps = {}
        
        -- Recreate all permanent objects
        CreateAllPermanentRocks()
        CreateAllPermanentProcessingProps()
        
        lib.notify({
            title = 'Admin',
            description = 'Đã tái tạo tất cả objects vĩnh viễn!',
            type = 'success'
        })
    end
end, false)

-- Function to open the Drill Shop menu
local function OpenDrillShopMenu()
    lib.registerContext({
        id = 'drill_shop_menu',
        title = 'Cửa hàng Máy Khoan',
        options = {
            {
                title = 'Mua ' .. Config.GetItemLabel(Config.RequiredItem),
                description = 'Giá: $' .. Config.ShopNPC.price .. ' | Thiết bị dùng để đào đá thô.',
                icon = 'fa-solid fa-screwdriver-wrench',
                onSelect = function()
                    TriggerServerEvent('xn_daodarp:buyDrill')
                end
            }
        }
    })
    lib.showContext('drill_shop_menu')
end

-- Thread to spawn Shop NPC locally using lib.points (runs only when player is near to optimize performance)
CreateThread(function()
    if Config.ShopNPC and Config.ShopNPC.enabled then
        local coords = Config.ShopNPC.coords
        npcPoint = lib.points.new({
            coords = vector3(coords.x, coords.y, coords.z),
            distance = 50.0,
            onEnter = function()
                local model = GetHashKey(Config.ShopNPC.model)
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(10)
                end
                
                shopPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
                SetEntityVisible(shopPed, true, false)
                FreezeEntityPosition(shopPed, true)
                SetEntityInvincible(shopPed, true)
                SetBlockingOfNonTemporaryEvents(shopPed, true)
                
                -- Add target interaction to the spawned ped
                exports.ox_target:addLocalEntity(shopPed, {
                    {
                        name = 'buy_drill_npc',
                        label = Config.ShopNPC.label,
                        icon = Config.ShopNPC.icon,
                        onSelect = function()
                            OpenDrillShopMenu()
                        end,
                        distance = Config.ShopNPC.distance
                    }
                })
            end,
            onExit = function()
                if shopPed and DoesEntityExist(shopPed) then
                    exports.ox_target:removeLocalEntity(shopPed)
                    DeleteEntity(shopPed)
                    shopPed = nil
                end
            end
        })
    end
end)
