if not lib.checkDependency('stevo_lib', '1.7.1') then error('stevo_lib 1.7.1 required for stevo_trickortreat') end
lib.locale()
local config = require('config')
local stevo_lib = exports['stevo_lib']:import()
local progress = config.progressCircle and lib.progressCircle or lib.progressBar

local isEventActive = false
local blips = {}
local housePoints = {}
local houseZones = {}
local candyBuyerBlip = nil
local clownPed = nil
local vanVehicle = nil
local candyBuyerPoint = nil
local textUI, knocking = false, false
local activeTrickPeds = {}

local function isEventTime()
    if not config.timeRestriction or not config.timeRestriction.enabled then
        return true
    end

    local startHour = config.timeRestriction.startHour or 20
    local endHour = config.timeRestriction.endHour or 6
    local curHour = GetClockHours()

    if startHour > endHour then
        return (curHour >= startHour or curHour < endHour)
    else
        return (curHour >= startHour and curHour < endHour)
    end
end

local function trickPlayer(houseId, data)
    if not isEventActive or type(data) ~= 'table' or not config.houses[houseId] then return end
    local ped = data.ped
    local weapon = data.weapon
    local location = config.houses[houseId]

    lib.requestModel(ped)
    if not isEventActive then
        SetModelAsNoLongerNeeded(ped)
        return
    end

    local zombie = CreatePed(4, ped, location.x, location.y, location.z, 0.0, false, true)
    SetModelAsNoLongerNeeded(ped)
    if not DoesEntityExist(zombie) then return end
    local token = {}
    activeTrickPeds[zombie] = token

    AddRelationshipGroup('XN_TRICK_ZOMBIE')
    SetPedRelationshipGroupHash(zombie, `XN_TRICK_ZOMBIE`)
    local playerGroup = GetPedRelationshipGroupHash(cache.ped)
    SetRelationshipBetweenGroups(5, `XN_TRICK_ZOMBIE`, playerGroup)
    SetRelationshipBetweenGroups(5, playerGroup, `XN_TRICK_ZOMBIE`)

    SetPedMaxHealth(zombie, config.trickPedHealth)
    SetEntityMaxHealth(zombie, config.trickPedHealth)
    SetEntityHealth(zombie, config.trickPedHealth)
    SetPedFleeAttributes(zombie, 0, false)
    SetPedCombatAttributes(zombie, 5, true)
    SetPedCombatAttributes(zombie, 46, true)
    SetPedCombatAbility(zombie, 2)
    SetPedCombatMovement(zombie, 3)
    SetPedCombatRange(zombie, 0)
    SetPedKeepTask(zombie, true)

    GiveWeaponToPed(zombie, weapon, 1, false, true)
    TaskCombatPed(zombie, cache.ped, 0, 16)

    stevo_lib.Notify(locale("notify.gotTricked"), 'error', 3000)   

    CreateThread(function()
        local expiresAt = GetGameTimer() + 15000
        local lastSwing = false
        local lastHitAt = 0
        while isEventActive and activeTrickPeds[zombie] == token
            and DoesEntityExist(zombie) and not IsPedFatallyInjured(zombie) do
            local player = cache.ped
            if not DoesEntityExist(player) or IsEntityDead(player) then break end
            local distance = #(GetEntityCoords(zombie) - GetEntityCoords(player))
            if distance > 15.0 or GetGameTimer() >= expiresAt then break end

            local swinging = IsPedPerformingMeleeAction(zombie)
            if swinging and not lastSwing and distance <= 1.8 and GetGameTimer() - lastHitAt >= 900 then
                lastHitAt = GetGameTimer()
                local health, armour = GetEntityHealth(player), GetPedArmour(player)
                Wait(250)
                -- GTA/FiveM normally applies melee damage. Only fill in a missed damage event.
                if isEventActive and activeTrickPeds[zombie] == token
                    and DoesEntityExist(zombie) and not IsPedFatallyInjured(zombie)
                    and DoesEntityExist(player) and not IsEntityDead(player)
                    and #(GetEntityCoords(zombie) - GetEntityCoords(player)) <= 2.0
                    and GetEntityHealth(player) == health and GetPedArmour(player) == armour then
                    ApplyDamageToPed(player, config.trickDamage, false)
                end
            end
            lastSwing = swinging
            Wait(50)
        end
        if activeTrickPeds[zombie] == token then
            if DoesEntityExist(zombie) then DeleteEntity(zombie) end
            activeTrickPeds[zombie] = nil
        end
    end)
end

local function doTrickOrTreat(houseId)
    if not isEventTime() then
        stevo_lib.Notify(locale("notify.notEventTime"), 'error', 3000)
        return
    end

    local canKnock = lib.callback.await('stevo_trickortreat:canKnock', false, houseId)
    if not canKnock then 
        stevo_lib.Notify(locale("notify.knockedRecently"), 'error', 3000)
        return 
    end
    if progress({
        duration = config.knockTime * 1000,
        position = 'bottom',
        label = locale('progress.knocking'),
        useWhileDead = false,
        anim = {
            dict = "timetable@jimmy@doorknock@",
            clip = "knockdoor_idle"
        },
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true, },
    }) then    
        if not isEventActive or not isEventTime() then return end
        local wasTricked = lib.callback.await('stevo_trickortreat:knockedOnDoor', false, houseId)

        if wasTricked == nil then
            stevo_lib.Notify(locale('notify.stoppedKnocking'), 'error', 3000)
        elseif wasTricked == false then
            stevo_lib.Notify(locale("notify.receivedTreat"), 'success', 3000)   
        else 
            trickPlayer(houseId, wasTricked)    
        end    

    else
        stevo_lib.Notify(locale("notify.stoppedKnocking"), 'error', 3000)
    end
end

local function trickOrTreat(houseId)
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end
    if knocking then return end
    knocking = true
    local ok, err = pcall(doTrickOrTreat, houseId)
    knocking = false
    if not ok then
        print(('[xn_doikeo] Knock failed at house %s: %s'):format(tostring(houseId), tostring(err)))
        stevo_lib.Notify(locale('notify.stoppedKnocking'), 'error', 3000)
    end
end

local function nearby(self)
    if not isEventTime() then return end

    if self.currentDistance < config.interactDistance and not textUI and not knocking then 
        lib.showTextUI(locale('textui.trickortreat')) 
        textUI = true
    end
    if self.currentDistance > config.interactDistance and textUI then 
        lib.hideTextUI()
        textUI = false 
    end
    if not knocking and self.currentDistance < config.interactDistance and IsControlJustPressed(0, 38) and not IsPedInAnyVehicle(PlayerPedId(), false) then
        lib.hideTextUI()
        textUI = false 
        trickOrTreat(self.houseId)               
    end
end

local function onExit(self)
    if textUI then 
        textUI = false
        lib.hideTextUI()
    end
end

local function startEvent()
    if isEventActive then return end
    isEventActive = true

    for locationId, location in pairs(config.houses) do 
        if config.interact == 'textui' then 
            local point = lib.points.new({
                coords = location,
                distance = config.interactDistance,
                houseId = locationId,
                nearby = nearby,
                onExit = onExit
            })
            housePoints[#housePoints + 1] = point
        else 
            local zoneName = 'stevotrickortreat'..locationId
            local options = {
                options = {
                    {
                        name = 'trickortreat',
                        type = "client",
                        action = function() 
                            trickOrTreat(locationId)   
                        end,
                        icon = 'fas fa-hand-fist',
                        label = locale("target.trickortreat"),
                    }
                },
                distance = config.interactDistance,
                rotation = 45
            }
            stevo_lib.target.AddBoxZone(zoneName, location, vec3(3, 3, 3), options)
            houseZones[#houseZones + 1] = zoneName
        end 

        local blip = config.houseBlips
        if blip then 
            local houseBlip = AddBlipForCoord(location.x, location.y, location.z)

            SetBlipAsShortRange(houseBlip, true)
            SetBlipSprite(houseBlip, blip.sprite) 
            SetBlipColour(houseBlip, blip.color) 
            SetBlipScale(houseBlip, blip.scale)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(locale("blips.house"))
            EndTextCommandSetBlipName(houseBlip)

            SetBlipDisplay(houseBlip, 4)
            SetBlipAsMissionCreatorBlip(houseBlip, true)
            blips[locationId] = houseBlip
        end
    end

    if config.candyBuyer then 
        local pedModel = config.candyBuyer.ped.model
        local pedCoords = config.candyBuyer.ped.coords
        lib.requestModel(pedModel)

        clownPed = CreatePed(28, pedModel, pedCoords.x, pedCoords.y, pedCoords.z, pedCoords.w, false, false)

        while not DoesEntityExist(clownPed) do Wait(50) end

        FreezeEntityPosition(clownPed, true)
        TaskStartScenarioInPlace(clownPed, 'WORLD_HUMAN_MUSICIAN', 0.0, true)
        SetModelAsNoLongerNeeded(pedModel)

        local vanModel = config.candyBuyer.van.model 
        local vanCoords = config.candyBuyer.van.coords
        lib.requestModel(vanModel)

        vanVehicle = CreateVehicle(vanModel, vanCoords.x, vanCoords.y, vanCoords.z, vanCoords.w, false, false)

        while not DoesEntityExist(vanVehicle) do Wait(50) end

        FreezeEntityPosition(vanVehicle, true)
        SetModelAsNoLongerNeeded(vanModel)
        SetVehicleDoorOpen(vanVehicle, 2, false, false)
        SetVehicleDoorOpen(vanVehicle, 3, false, false)
        SetVehicleDoorsLocked(vanVehicle, 2)

        if config.interact == 'textui' then 
            candyBuyerPoint = lib.points.new({
                coords = pedCoords.xyz,
                distance = config.interactDistance,
                onExit = function(self)
                    lib.hideTextUI()
                end,
                onEnter = function(self)
                    if not isEventTime() then return end
                    lib.showTextUI(locale('textui.sellCandy')) 
                end,
                nearby = function(self)
                    if not isEventTime() then return end
                    if IsControlJustPressed(0, 38) then
                        local soldCandy, profit, candySold = lib.callback.await('stevo_trickortreat:sellCandy', false)

                        if soldCandy then 
                            stevo_lib.Notify(locale('notify.soldCandy', candySold, profit), 'success', 5000)
                        else 
                            stevo_lib.Notify(locale('notify.noCandy'), 'error', 3000)
                        end            
                    end
                end
            })
        else 
            local options = {
                options = {
                    {
                        name = 'trickortreat',
                        type = "client",
                        action = function() 
                            if not isEventTime() then
                                stevo_lib.Notify(locale("notify.notEventTime"), 'error', 3000)
                                return
                            end
                            local soldCandy, profit, candySold = lib.callback.await('stevo_trickortreat:sellCandy', false)

                            if soldCandy then 
                                stevo_lib.Notify(locale('notify.soldCandy', candySold, profit), 'success', 5000)
                            else 
                                stevo_lib.Notify(locale('notify.noCandy'), 'error', 3000)
                            end
                        end,
                        icon = 'fas fa-handshake',
                        label = locale("target.sellcandy"),
                    }
                },
                distance = config.interactDistance,
                rotation = 45
            }
            stevo_lib.target.AddBoxZone('stevotrickortreatcandybuyer', pedCoords.xyz, vec3(3, 3, 3), options) 
        end

        local blip = config.candyBuyer.blip
        if blip then 
            candyBuyerBlip = AddBlipForCoord(vanCoords.x, vanCoords.y, vanCoords.z)

            SetBlipAsShortRange(candyBuyerBlip, true)
            SetBlipSprite(candyBuyerBlip, blip.sprite) 
            SetBlipColour(candyBuyerBlip, blip.color) 
            SetBlipScale(candyBuyerBlip, blip.scale)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(locale("blips.candyClown"))
            EndTextCommandSetBlipName(candyBuyerBlip)
            SetBlipDisplay(candyBuyerBlip, 4)
            SetBlipAsMissionCreatorBlip(candyBuyerBlip, true)
        end
    end
end

local function stopEvent()
    if not isEventActive then return end
    isEventActive = false

    for ped in pairs(activeTrickPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
        activeTrickPeds[ped] = nil
    end

    if textUI then 
        textUI = false
        lib.hideTextUI()
    end

    -- Remove house blips
    for locationId, blip in pairs(blips) do 
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}

    -- Remove house interactions
    if config.interact == 'textui' then
        for _, point in ipairs(housePoints) do
            if point and point.remove then
                point:remove()
            end
        end
        housePoints = {}
    else
        for _, zoneName in ipairs(houseZones) do
            pcall(function()
                stevo_lib.target.RemoveZone(zoneName)
            end)
        end
        houseZones = {}
    end

    -- Remove candy buyer blip
    if candyBuyerBlip and DoesBlipExist(candyBuyerBlip) then
        RemoveBlip(candyBuyerBlip)
        candyBuyerBlip = nil
    end

    -- Remove candy buyer interaction
    if config.interact == 'textui' then
        if candyBuyerPoint and candyBuyerPoint.remove then
            candyBuyerPoint:remove()
            candyBuyerPoint = nil
        end
    else
        pcall(function()
            stevo_lib.target.RemoveZone('stevotrickortreatcandybuyer')
        end)
    end

    -- Remove clown ped & van
    if clownPed and DoesEntityExist(clownPed) then
        DeleteEntity(clownPed)
        clownPed = nil
    end
    if vanVehicle and DoesEntityExist(vanVehicle) then
        DeleteEntity(vanVehicle)
        vanVehicle = nil
    end
end

CreateThread(function()
    local hasInitialized = false
    while true do
        local active = isEventTime()
        if active and not isEventActive then
            startEvent()
            if hasInitialized and config.timeRestriction and config.timeRestriction.notify then
                stevo_lib.Notify(locale('notify.eventStarted'), 'info', 5000)
            end
        elseif not active and isEventActive then
            stopEvent()
            if hasInitialized and config.timeRestriction and config.timeRestriction.notify then
                stevo_lib.Notify(locale('notify.eventEnded'), 'info', 5000)
            end
        end
        hasInitialized = true
        Wait(2000)
    end
end)

RegisterNetEvent('stevo_lib:playerLoaded', function()
    if isEventTime() and not isEventActive then
        startEvent()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    stopEvent()
end)
