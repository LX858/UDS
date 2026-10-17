local Framework, frameworkName = getFramework()
loaded = false
local ready = false
local streetCache, lastStreetUpdate = "", 0

function updateInformation()
    local fetch = lib.callback.await('tipi-hud:getInformation', false)

    if fetch then
        while not ready do
            Citizen.Wait(1)
        end
        SendNUIMessage({
            action = "updateInformation",
            value = fetch
        })
        loaded = true
    end
end


RegisterNetEvent('tipi-hud:reset')
AddEventHandler('tipi-hud:reset', function()
    SendNUIMessage({
        action = "resetHud"
    })
end)

WS.RegisterEventHandler('tipi-hud:refreshPing', function(data)
    local ping = data.pings[GetPlayerServerId(PlayerId())] or 0

    if ping then
        SendNUIMessage({
            action = "updatePing",
            ping = ping,
            online = data.online
        })
    end
end)

RegisterNetEvent("QBCore:Client:OnMoneyChange")
AddEventHandler("QBCore:Client:OnMoneyChange", function(moneyType, amount, operation)
    if type(moneyType) == "table" and moneyType.money then
        PlayerCache.money.cash = moneyType.money.cash or PlayerCache.money.cash
        PlayerCache.money.bank = moneyType.money.bank or PlayerCache.money.bank
    end
    SendNUIMessage({
        action = "updateMoney",
        cash = PlayerCache.money.cash,
        bank = PlayerCache.money.bank
    })
end)

RegisterNetEvent("esx:setAccountMoney")
AddEventHandler("esx:setAccountMoney", function(data)
    money[data.name] = data.money

    SendNUIMessage({
        action = "updateMoney",
        cash = money["money"],
        bank = money["bank"]
    })
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    SendNUIMessage({
        action = "updateJob",
        job = job["name"].." "..job["grade_label"]
    })
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
    SendNUIMessage({
        action = "updateJob",
        job = job.label.." "..job.grade.name
    })
end)

local vehicleType = nil

if Config.UseCruiseControl then
    RegisterKeyMapping('togglecruisecontrol', 'Toggle Cruise Control', 'keyboard', Config.CruiseKey)
    RegisterCommand("togglecruisecontrol", function(src, args, raw)
        vehicleType = lib.callback.await('tipi-hud:getVehicleType')
        if vehicleType == "boat" or vehicleType == "plane" or vehicleType == "heli" then return end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
        local carSpeed = GetEntitySpeed(vehicle)

        if isDriver and vehicle ~= 0 then

            if carSpeed < 5 then 
                notify('CRUISE_CANT_SET')
                return 
            end
            
            if not Cruise then
                Cruise = true
                SetVehicleMaxSpeed(vehicle, carSpeed)
                notify('CRUISE_SET')
            else
                notify('CRUISE_DISABLED')
                Cruise = false
                SetVehicleMaxSpeed(vehicle, 0.0)
            end
        end
    end)
end

local LastNotification = 0
function ShowNotifyStatus(message)
    if LastNotification > GetGameTimer() then return end 
    LastNotification = GetGameTimer() + 60000
    notify(message)
end

Citizen.CreateThread(function()
    while true do 
        local hunger = getHunger() / 100 * 100
        local thirst = getThirst() / 100 * 100
        if hunger <= 10 and thirst <= 10 then 
            ShowNotifyStatus('Nhân vật đang rất đói và khát vui lòng ăn uống ngay !')
        elseif hunger <= 10 then 
            ShowNotifyStatus('Nhân vật đang rất đói vui lòng ăn ngay !')
        elseif thirst <= 10 then 
            ShowNotifyStatus('Nhân vật đang rất khát vui lòng uống nước ngay !')
        end
        Citizen.Wait(5000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if loaded then
            local playerPed = PlayerPedId()
            
            local health = (GetEntityHealth(playerPed) - 100) / (GetEntityMaxHealth(playerPed) - 100) * 100
            local armor = GetPedArmour(playerPed) / 100 * 100
            local hunger = getHunger() / 100 * 100
            local thirst = getThirst() / 100 * 100
            local sleep = getSleepiness() / 100 * 100
            local poop = getPoop() / 100 * 100
            local pee = getPee() / 100 * 100
            local playerId = PlayerId()
            local stamina = (100 - GetPlayerSprintStaminaRemaining(playerId)) / 100 * 100
            local inWater = IsEntityInWater(playerPed)
            local isSwimming = IsPedSwimming(playerPed) or IsPedSwimmingUnderWater(playerPed)
            local isUnderwater = inWater or isSwimming
            local oxygen = 100
            if isUnderwater then
                oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
            end
            local now = GetGameTimer()
            if now - lastStreetUpdate > 1000 then
                local coords = GetEntityCoords(playerPed)
                local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                local mainStreet = GetStreetNameFromHashKey(streetHash)
                local crossingStreet = ""
                if crossingHash and crossingHash ~= 0 then
                    crossingStreet = GetStreetNameFromHashKey(crossingHash)
                end
                if crossingStreet ~= "" and crossingStreet ~= mainStreet then
                    streetCache = mainStreet .. "/" .. crossingStreet
                else
                    streetCache = mainStreet
                end
                lastStreetUpdate = now
            end
            local street = streetCache
            local heading = GetEntityHeading(playerPed)
            local gameHours, gameMinutes, gameDay, gameMonth, gameYear = getGameClockTime()
            local isTalking = NetworkIsPlayerTalking(playerId)
            local isInPauseMenu = IsPauseMenuActive()
            if IsMoveHudActive and IsMoveHudActive() then
                isInPauseMenu = false
            end
            local weaponPayload = GetWeaponHudPayload(playerPed)
            SendNUIMessage({
                action = "updateBar",
                health = health,
                armor = armor,
                hunger = hunger,
                thirst = thirst,
                stamina = stamina,
                oxygen = oxygen,
                stress = (stress or 0) / 100 * 100,
                blessing = getBlessing(),
                sleep = sleep,
                poop = poop,
                pee = pee,
                street = street,
                rotation = heading,
                gameHours = gameHours,
                gameMinutes = gameMinutes,
                gameDay = gameDay,
                gameMonth = gameMonth,
                gameYear = gameYear,
                isTalking = isTalking,
                isInPauseMenu = isInPauseMenu,
                isInWater = isUnderwater,
            })
            SendNUIMessage({
                action = "updateWeapon",
                value = weaponPayload,
            })
        end
        
        Citizen.Wait(100)
    end
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end

    if not loggedIn then
        RefreshPlayerCache()
        Wait(500)
        updateInformation()

        SendNUIMessage({
            action = "updateSvInfo",
            SecondTextColor = Config.SecondTextColor,
            FirstTextColor = Config.FirstTextColor,
            LinkTextColor = Config.LinkTextColor,
            logo = Config.ServerLogo
        })
        loggedIn = true
    end
end)

RegisterCommand(Config.SettingsCommand, function()
    SendNUIMessage({
        action = "settings"
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('exit', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('ready', function(_, cb)
    ready = true
    SetMinimapUiReady(true)
    SendNUIMessage({
        action = "updateSvInfo",
        SecondTextColor = Config.SecondTextColor,
        FirstTextColor = Config.FirstTextColor,
        LinkTextColor = Config.LinkTextColor,
        logo = Config.ServerLogo
    })
    cb({})
end)

RegisterNUICallback('save', function(_, cb)
    cb({})
end)

RegisterNUICallback('reset', function(data, cb)
    TriggerServerEvent('tipi-hud:reset')
    cb({})
end)

hideAllActive = false

local function applyHideAll(value)
    hideAllActive = value
    SendNUIMessage({
        action = "hideAll",
        value  = value
    })
    if CheckRadarDisplay then
        CheckRadarDisplay()
    end
end

RegisterNUICallback('hideAll', function(data, cb)
    applyHideAll(data.value)
    cb({})
end)

AddEventHandler('tipi_hud:setHideAll', function(value)
    applyHideAll(value == true)
end)

AddEventHandler('tipi_hud:toggleHideAll', function()
    applyHideAll(not hideAllActive)
end)

CreateThread(function()
    while true do
        if hideAllActive then
            DisplayRadar(false)
        end

        HideHudComponentThisFrame(1)
        HideHudComponentThisFrame(2)
        HideHudComponentThisFrame(3)
        HideHudComponentThisFrame(4)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudComponentThisFrame(13)

        Wait(0)
    end
end)

Citizen.CreateThread(function()
    local fetch = lib.callback.await('tipi-hud:isRestart', false)

    if fetch then
        print('Script restarting dedected, Script loaded succesfully.')
        updateInformation()
    end
end)

AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource == GetCurrentResourceName() then
        TriggerServerEvent('tipi-hud:setRestart')
    end
end)