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
local textUI, knocking, trickPed = false, false, 0

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
    local ped = data.ped
    local weapon = data.weapon
    local location = config.houses[houseId]

    lib.requestModel(ped)

    trickPed = CreatePed(28, ped, location.x, location.y, location.z, 0.0, false, true)
    
    SetRelationshipBetweenGroups(5, GetPedRelationshipGroupHash(cache.ped), GetPedRelationshipGroupHash(trickPed))
    SetRelationshipBetweenGroups(5, GetPedRelationshipGroupHash(trickPed), GetPedRelationshipGroupHash(cache.ped))

    GiveWeaponToPed(trickPed, weapon, 250, false, true)
    TaskCombatPed(trickPed, cache.ped, 0, 16)

    stevo_lib.Notify(locale("notify.gotTricked"), 'error', 3000)   

    CreateThread(function()
        local pedAlive = 0
        while DoesEntityExist(trickPed) do 

            if IsPedFatallyInjured(trickPed) then 
                DeleteEntity(trickPed)
            end
            if #(GetEntityCoords(trickPed) - GetEntityCoords(cache.ped)) > 15 then 
                DeleteEntity(trickPed)
            end

            if pedAlive > 15000 then 
                DeleteEntity(trickPed)
            end

            pedAlive = pedAlive + 500

            Wait(500)
        end
    end)
end

local function trickOrTreat(houseId)
    if not isEventTime() then
        stevo_lib.Notify(locale("notify.notEventTime"), 'error', 3000)
        return
    end

    local canKnock = lib.callback.await('stevo_trickortreat:canKnock', false, houseId)
    if not canKnock then 
        knocking = false
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
        local wasTricked = lib.callback.await('stevo_trickortreat:knockedOnDoor', false, houseId)

        knocking = false

        if not wasTricked then
            stevo_lib.Notify(locale("notify.receivedTreat"), 'success', 3000)   
        else 
            trickPlayer(houseId, wasTricked)    
        end    

    else
        knocking = false
        stevo_lib.Notify(locale("notify.stoppedKnocking"), 'error', 3000)
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
    if self.currentDistance < config.interactDistance and IsControlJustPressed(0, 38) then
        lib.hideTextUI()
        textUI = false 
        knocking = true
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
