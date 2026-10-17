lib.locale()


local appearance = nil

local function AutoDetectFramework()
    if GetResourceState("es_extended") == "started" then
        return "ESX"
    elseif GetResourceState("qb-core") == "started" then
        return "qbcore"
    else
        return "standalone"
    end
end

local function AutoDetectTarget()
    if GetResourceState("qtarget") == "started" then
        return "qtarget"
    elseif GetResourceState("qb-target") == "started" then
        return "qb-target"
    elseif GetResourceState("ox_target") == "started" then
        return "ox_target"
    end
end

local function AutoDetectBoss()
    if GetResourceState("esx_society") == "started" then
        return "esx_society"
    elseif GetResourceState("qb-management") == "started" then
        return "qb-management"
    end
end

local function AutoDetectClothing()
    if GetResourceState("esx_skin") == "started" and GetResourceState("illenium_appearance") ~= "started" and GetResourceState("ox_appearance") ~= "started" and GetResourceState("fivem-appearance") ~= "started" then
        return "esx_skin"
    elseif GetResourceState("qb-clothing") == "started" then
        return "qb-clothing"
    elseif GetResourceState("ox_appearance") == "started" then
        return "ox_appearance"
    elseif GetResourceState("fivem-appearance") == "started" then
        return "fivem-appearance"
    elseif GetResourceState("illenium-appearance") == "started" then
        return "illenium-appearance"
    end
end


if Config.Framework == "auto-detect" then
    Config.Framework = AutoDetectFramework()
end

if Config.Target == "auto-detect" then
    Config.Target = AutoDetectTarget()
end

if Config.BossMenu == "auto-detect" then
    Config.BossMenu = AutoDetectBoss()
end

if Config.Clothing == "auto-detect" then
    Config.Clothing = AutoDetectClothing()
end

if Config.Framework == "ESX" then
    if Config.NewESX then
        ESX = exports["es_extended"]:getSharedObject()
    else
        ESX = nil
        CreateThread(function()
            while ESX == nil do
                TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
                Wait(100)
            end
        end)
    end
elseif Config.Framework == "qbcore" then
    QBCore = nil
    QBCore = exports["qb-core"]:GetCoreObject()
elseif Config.Framework == "standalone" then
    -- ADD YOU FRAMEWORK
end

-- Your notification type settings
-- •» You can edit a type of notifications, with chaning type or triggering your own.
Notify = function(type, title, text)
    if Config.NotificationType == "ESX" then
        ESX.ShowNotification(text)
    elseif Config.NotificationType == "ox_lib" then
        if type == "info" then
            lib.notify({
                title = title,
                description = text,
                type = "inform"
            })
        elseif type == "error" then
            lib.notify({
                title = title,
                description = text,
                type = "error"
            })
        elseif type == "success" then
            lib.notify({
                title = title,
                description = text,
                type = "success"
            })
        end
    elseif Config.NotificationType == "qbcore" then
        if type == "success" then
            QBCore.Functions.Notify(text, "success")
        elseif type == "info" then
            QBCore.Functions.Notify(text, "primary")
        elseif type == "error" then
            QBCore.Functions.Notify(text, "error")
        end
    elseif Config.NotificationType == "custom" then
        print("add your notification system! in cl_Utils.lua")
        -- ADD YOUR NOTIFICATION | TYPES ARE info, error, success
    end
end

ProgressBar = function(duration, label)
    if Config.Progress == "ox_lib" then
        lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = false
        })
    elseif Config.Progress == "qbcore" then
        QBCore.Functions.Progressbar(label, label, duration - 500, false, true, {
        }, {}, {}, {}, function()
        end)
        Wait(duration)
    elseif Config.Progress == "progressBars" then
        exports['progressBars']:startUI(duration, label)
        Wait(duration)
    end
end

Action = function(data)
    if Config.Framework == "ESX" then
        if data.status == "drunk" then
            TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
            local playerPed = PlayerPedId()
            DoScreenFadeOut(800)
            Wait(1000)
            RequestAnimSet("move_m@drunk@slightlydrunk")
            while not HasAnimSetLoaded("move_m@drunk@slightlydrunk") do
                Wait(0)
            end
            SetPedMovementClipset(playerPed, "move_m@drunk@slightlydrunk", true)
            SetTimecycleModifier("spectator5")
            SetPedMotionBlur(playerPed, true)
            SetPedIsDrunk(playerPed, true)
            DoScreenFadeIn(800)
            Wait(math.random(30000, 70000))
            DoScreenFadeOut(800)
            Wait(1000)
            ClearTimecycleModifier()
            ResetScenarioTypesEnabled()
            ResetPedMovementClipset(playerPed, 0)
            SetPedIsDrunk(playerPed, false)
            SetPedMotionBlur(playerPed, false)
            DoScreenFadeIn(800)
        else
            TriggerServerEvent("drc_wine:server:add", data.status, data.add)
        end
    elseif Config.Framework == "qbcore" then
        if data.status == "drunk" then
            TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
            local playerPed = PlayerPedId()
            DoScreenFadeOut(800)
            Wait(1000)
            RequestAnimSet("move_m@drunk@slightlydrunk")
            while not HasAnimSetLoaded("move_m@drunk@slightlydrunk") do
                Wait(0)
            end
            SetPedMovementClipset(playerPed, "move_m@drunk@slightlydrunk", true)
            SetTimecycleModifier("spectator5")
            SetPedMotionBlur(playerPed, true)
            SetPedIsDrunk(playerPed, true)
            DoScreenFadeIn(800)
            Wait(math.random(20000, 50000))
            DoScreenFadeOut(800)
            Wait(1000)
            ClearTimecycleModifier()
            ResetScenarioTypesEnabled()
            ResetPedMovementClipset(playerPed, 0)
            SetPedIsDrunk(playerPed, false)
            SetPedMotionBlur(playerPed, false)
            DoScreenFadeIn(800)
        else
            if tostring(data.status) == "hunger" then
                TriggerServerEvent("consumables:server:addHunger", QBCore.Functions.GetPlayerData().metadata["hunger"] + tonumber(data.add) / 10000)
                TriggerServerEvent('hud:server:RelieveStress', math.random(2, 4))
            elseif tostring(data.status) == "thirst" then
                TriggerServerEvent("consumables:server:addThirst", QBCore.Functions.GetPlayerData().metadata["thirst"] + tonumber(data.add) / 10000)
            end
        end
    end
end

--BossMenu
OpenBossMenu = function()
    if Config.BossMenu == "esx_society" then
        TriggerEvent('esx_society:openBossMenu', "wine", function(data, menu)
            menu.close()
        end, { wash = false })
    elseif Config.BossMenu == "qb-management" then
        TriggerEvent("qb-bossmenu:client:OpenMenu")
    end
end


TextUIShow = function(text)
    if Config.TextUI == "ox_lib" then
        lib.showTextUI(text)
    elseif Config.TextUI == "esx" then
        exports["esx_textui"]:TextUI(text)
    elseif Config.TextUI == "luke" then
        TriggerEvent('luke_textui:ShowUI', text)
    elseif Config.TextUI == "custom" then
        print("add your textui system! in cl_Utils.lua")
        -- ADD YOUR TEXTUI | TO SHOW
    end
end

IsTextUIShowed = function()
    if Config.TextUI == "ox_lib" then
        return lib.isTextUIOpen()
    elseif Config.TextUI == "esx" then
        --exports["esx_textui"]:TextUI(text)
    elseif Config.TextUI == "luke" then
        --TriggerEvent('luke_textui:ShowUI', text)
    elseif Config.TextUI == "custom" then
        print("add your textui system! in cl_Utils.lua")
        -- ADD YOUR TEXTUI | TO SHOW
    end
end

TextUIHide = function()
    if Config.TextUI == "ox_lib" then
        lib.hideTextUI()
    elseif Config.TextUI == "esx" then
        exports["esx_textui"]:HideUI()
    elseif Config.TextUI == "luke" then
        TriggerEvent('luke_textui:HideUI')
    elseif Config.TextUI == "custom" then
        print("add your textui system! in cl_Utils.lua")
        -- ADD YOUR TEXTUI | TO HIDE
    end
end

Draw3DText = function(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    
    if onScreen then
        SetTextFont(Config.FontId)
        SetTextScale(0.33, 0.30)
        SetTextDropshadow(10, 100, 100, 100, 255)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text)) / 350
        DrawRect(_x,_y+0.0135, 0.025+ factor, 0.03, 0, 0, 0, 10)
    end
end

Target = function()
    if Config.Target == "qtarget" then
        return exports['qtarget']
    end
    if Config.Target == "qb-target" then
        return exports['qb-target']
    end
    if Config.Target == "ox_target" then
        return exports['ox_target']
    end
end

-- Track zones registered in this session so we only remove what we added
local _registeredZones = {}

RemoveTargetZone = function(name)
    if Config.Target == "ox_target" then
        if _registeredZones[name] then
            exports['ox_target']:removeZone(name)
            _registeredZones[name] = nil
        end
    else
        Target():RemoveZone(name)
    end
end

-- Keys that belong to the ox_target option schema (not extra event data)
local _oxKnownKeys = {
    label = true, icon = true, iconColor = true, distance = true,
    groups = true, canInteract = true, onSelect = true, export = true,
    event = true, serverEvent = true, bones = true, netFilter = true,
    pedFilter = true, playerPed = true, items = true,
    -- keys we handle ourselves:
    action = true, job = true, type = true,
}

AddTargetZone = function(name, coords, radius, options, distance, debugPoly)
    if Config.Target == "ox_target" then
        local oxOptions = {}
        for _, opt in ipairs(options) do
            -- Collect extra data fields (anything not in the ox_target schema)
            local extraData = {}
            for k, v in pairs(opt) do
                if not _oxKnownKeys[k] then
                    extraData[k] = v
                end
            end

            local oxOpt = {}
            oxOpt.label    = opt.label
            oxOpt.icon     = opt.icon
            oxOpt.iconColor = opt.iconColor
            oxOpt.distance = distance or 3.5

            -- canInteract passthrough
            if opt.canInteract then
                oxOpt.canInteract = opt.canInteract
            end

            -- Convert job → groups
            -- NOTE: the pattern `Config.DisableJob and nil or JobName` in Lua always
            -- evaluates to JobName (nil is falsy), so we must guard with Config.DisableJob here.
            if opt.job ~= nil and not Config.DisableJob then
                if type(opt.job) == "string" then
                    oxOpt.groups = { [opt.job] = 0 }
                elseif type(opt.job) == "table" then
                    oxOpt.groups = opt.job
                end
            end

            -- action → onSelect closure
            if opt.action then
                local fn = opt.action
                oxOpt.onSelect = function() fn() end

            -- event: ox_target only passes zone/entity data, not extra fields.
            -- Build an onSelect closure that forwards the extra data manually.
            elseif opt.event then
                local evtName = opt.event
                local captured = extraData
                oxOpt.onSelect = function()
                    TriggerEvent(evtName, captured)
                end

            elseif opt.serverEvent then
                local evtName = opt.serverEvent
                local captured = extraData
                oxOpt.onSelect = function()
                    TriggerServerEvent(evtName, captured)
                end

            elseif opt.onSelect then
                oxOpt.onSelect = opt.onSelect
            end

            table.insert(oxOptions, oxOpt)
        end
        exports['ox_target']:addSphereZone({
            name = name,
            coords = coords,
            radius = radius,
            debug = debugPoly or false,
            options = oxOptions
        })
        _registeredZones[name] = true
    else
        local target = Target()
        target:AddCircleZone(name, coords, radius, {
            name = name,
            debugPoly = debugPoly or false,
            useZ = true
        }, {
            options = options,
            distance = distance or 3.5
        })
    end
end

OpenStash = function(stash)
    if Config.Inventory == "qb-new" then
        local data = nil
        for _, stashData in pairs(Config.wine.Stashes) do
            if stashData.name == stash then
                data = stashData
                break
            end
        end
        TriggerServerEvent("drc_wine:server:OpenInventory", "stash"..stash, data.Weight, data.Slots)
    elseif Config.Inventory == "qb" then
    local data = nil
    for _, stashData in pairs(Config.wine.Stashes) do
        if stashData.name == stash then
            data = stashData
            break
        end
    end
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stash, {
        maxweight = data.Weight,
        slots = data.Slots,
    })
    TriggerEvent("inventory:client:SetCurrentStash", stash)
    elseif Config.Inventory == "ox" then
        exports.ox_inventory:openInventory('stash', stash)
    elseif Config.Inventory == "quasar" then
        local data = nil
        for _, stashData in pairs(Config.wine.Stashes) do
            if stashData.name == stash then
                data = stashData
                break
            end
        end
        TriggerServerEvent("inventory:server:OpenInventory", "stash", stash, {
            maxweight = data.Weight,
            slots = data.Slots,
        })
        TriggerEvent("inventory:client:SetCurrentStash", stash)
    elseif Config.Inventory == "chezza" then
        TriggerEvent('inventory:openStorage', "Stash", "stash"..stash, 100, 1000, nil)
    end
end
OpenCloakRoomMenu = function()
    lib.registerContext({
        id = 'wine_cloakroom',
        title = 'CloakRoom',
        options = {
            ['Outfits'] = {
                arrow = false,
                event = 'drc_wine:outfits'
            },
            ['Put on job outfit'] = {
                arrow = false,
                event = 'drc_wine:joboutfit'
            },
            ['Put on civil outfit'] = {
                arrow = false,
                event = 'drc_wine:civiloutfit'
            }
        }
    })
    lib.showContext('wine_cloakroom')
end

RegisterNetEvent("drc_wine:civiloutfit", function()
    if Config.Clothing == "esx_skin" then
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
    elseif Config.Clothing == "fivem-appearance" or Config.Clothing == "ox_appearance" then
        if appearance then
            exports['fivem-appearance']:setPedAppearance(PlayerPedId(), appearance)
            appearance = nil
        end
    elseif Config.Clothing == "illenium-appearance" then
        if appearance then
            exports['illenium-appearance']:setPedAppearance(PlayerPedId(), appearance)
            appearance = nil
        end
    elseif Config.Clothing == "qb-clothing" then
        TriggerServerEvent('qb-clothes:loadPlayerSkin')
    end
end)

RegisterNetEvent("drc_wine:joboutfit", function()
    if Config.Clothing == "qb-clothing" then
        if GetEntityModel(cache.ped) == joaat('mp_m_freemode_01') then
			local Male = {
				outfitData = {
					["pants"]       = { item = 90, texture = 0},
					["arms"]        = { item = 11, texture = 0},  
					["t-shirt"]     = { item = 15, texture = 1},  
					["torso2"]      = { item = 95, texture = 7}, 
					["shoes"]       = { item = 66, texture = 2},  
                    ["hat"]         = { item = 105, texture = 2},  
				},
			}
			TriggerEvent('qb-clothing:client:loadOutfit', Male)
		else
			local Female = {
				outfitData = {
					["pants"]       = { item = 93, texture = 3},  
					["arms"]        = { item = 14, texture = 0},  
					["t-shirt"]     = { item = 15, texture = 0},  
					["vest"]        = { item = 0, texture = 0},  
					["torso2"]      = { item = 224, texture = 7}, 
					["shoes"]       = { item = 59, texture = 1}, 
				},
			}
			TriggerEvent('qb-clothing:client:loadOutfit', Female)
		end
    end
    
    if Config.Clothing == "ox_appearance" or Config.Clothing == "fivem-appearance" then
        if not appearance then
            appearance = exports['fivem-appearance']:getPedAppearance(PlayerPedId())
        end
        if GetEntityModel(cache.ped) == joaat('mp_m_freemode_01') then
            arms = {component_id = 3, texture = 0, drawable = 11}
            torso = {component_id = 11, texture = 2, drawable = 95}
            undershirt = {component_id = 8, texture = 1, drawable = 15}
            pants = {component_id = 4, texture = 0, drawable = 90}
            shoes = {component_id = 6, texture = 1, drawable = 66}
            exports['fivem-appearance']:setPedComponents(cache.ped, {torso, undershirt, pants, shoes, arms})
            exports['fivem-appearance']:setPedProp(cache.ped, { prop_id = 0, drawable = 105, texture = 19 })
        else
            arms = {component_id = 3, texture = 0, drawable = 14}
            torso = {component_id = 11, texture = 7, drawable = 224}
            undershirt = {component_id = 8, texture = 0, drawable = 15}
            pants = {component_id = 4, texture = 3, drawable = 93}
            shoes = {component_id = 6, texture = 1, drawable = 59}
            bag = {component_id = 5, texture = 0, drawable = 0}
            accesories = {component_id = 7, texture = 0, drawable = 0}
            kevlar = {component_id = 9, texture = 0, drawable = 0}
            badge = {component_id = 10, texture = 0, drawable = 0}
            exports['fivem-appearance']:setPedComponents(cache.ped, {torso, undershirt, pants, shoes, bag, accesories, kevlar, badge, arms})
        end
    end
    if Config.Clothing == "illenium-appearance" then
        if not appearance then
            appearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
        end
        local model = GetEntityModel(cache.ped)
        if model == joaat('mp_m_freemode_01') then
            arms = {component_id = 3, texture = 0, drawable = 11}
            torso = {component_id = 11, texture = 2, drawable = 95}
            undershirt = {component_id = 8, texture = 1, drawable = 15}
            pants = {component_id = 4, texture = 0, drawable = 90}
            shoes = {component_id = 6, texture = 1, drawable = 66}
            exports['illenium-appearance']:setPedComponents(cache.ped, {torso, undershirt, pants, shoes, arms})
            exports['illenium-appearance']:setPedProp(cache.ped, { prop_id = 0, drawable = 105, texture = 19 })
        else
            arms = {component_id = 3, texture = 0, drawable = 14}
            torso = {component_id = 11, texture = 7, drawable = 224}
            undershirt = {component_id = 8, texture = 0, drawable = 15}
            pants = {component_id = 4, texture = 3, drawable = 93}
            shoes = {component_id = 6, texture = 1, drawable = 59}
            bag = {component_id = 5, texture = 0, drawable = 0}
            accesories = {component_id = 7, texture = 0, drawable = 0}
            kevlar = {component_id = 9, texture = 0, drawable = 0}
            badge = {component_id = 10, texture = 0, drawable = 0}
            exports['illenium-appearance']:setPedComponents(cache.ped, {torso, undershirt, pants, shoes, bag, accesories, kevlar, badge, arms})
        end
    end
    if Config.Clothing == "esx_skin" then
        TriggerEvent('skinchanger:getSkin', function(skin)
        if GetEntityModel(cache.ped) == joaat('mp_m_freemode_01') then
                TriggerEvent('skinchanger:loadSkin', {
                    sex = 0,
                    tshirt_1 = 15,
                    tshirt_2 = 0,
                    arms     = 11,
                    torso_1  = 66,
                    torso_2  = 7,
                    pants_1  = 90,
                    pants_2  = 0,
                    shoes_1 = 96,
                    shoes_2 = 2,
                    chain_1 = 0,
                    chain_2 = 0,
                })
            else
                TriggerEvent('skinchanger:loadSkin', {
                    sex = 1,
                    tshirt_1 = 15,
                    tshirt_2 = 0,
                    arms = 14,
                    torso_1 = 224,
                    torso_2 = 7,
                    pants_1 = 93,
                    pants_2 = 3,
                    shoes_1 = 59,
                    shoes_2 = 1,
                })
            end
        end)
    end
end)
RegisterNetEvent("drc_wine:outfits", function()
    if Config.Clothing == "esx_skin" then
        ESX.TriggerServerCallback('drc_wine:getPlayerDressing', function(dressing)
            local elements = {}

            for i = 1, #dressing, 1 do
                table.insert(elements, {
                    label = dressing[i],
                    value = i
                })
            end

            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_dressing', {
                title    = property.label .. ' - ' .. _U('player_clothes'),
                align    = 'top-left',
                elements = elements
            }, function(data, menu)
                TriggerEvent('skinchanger:getSkin', function(skin)
                    ESX.TriggerServerCallback('drc_wine:getPlayerOutfit', function(clothes)
                        TriggerEvent('skinchanger:loadClothes', skin, clothes)
                        TriggerEvent('esx_skin:setLastSkin', skin)

                        TriggerEvent('skinchanger:getSkin', function(skin)
                            TriggerServerEvent('esx_skin:save', skin)
                        end)
                    end, data.current.value)
                end)
            end, function(data, menu)
                menu.close()
            end)
        end)
    elseif Config.Clothing == "ox_appearance" then
        TriggerEvent("ox_appearance:wardrobe")
    elseif Config.Clothing == "fivem-appearance" then
        TriggerEvent("fivem-appearance:clothingShop")
    elseif Config.Clothing == "illenium-appearance" then
        TriggerEvent("illenium-appearance:clothingShop")
    elseif Config.Clothing == "qb-clothing" then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.4)
        TriggerEvent('qb-clothing:client:openOutfitMenu')
    end
end)
--Config.Blips creating
CreateThread(function()
    for _, v in pairs(Config.Blips) do
        local blip = AddBlipForCoord(v.BlipCoords)
        SetBlipSprite(blip, v.Sprite)
        SetBlipDisplay(blip, v.Display)
        SetBlipScale(blip, v.Scale)
        SetBlipColour(blip, v.Colour)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(v.Name)
        EndTextCommandSetBlipName(blip)
    end
end)

--job Blips
CreateThread(function()
    while not GetJob() do
        Wait(1000)
    end
    if (Config.DisableJob and not ShopBlips) or (GetJob() == Config.JobName and not ShopBlips) then
        for _, v in pairs(Config.JobBlips) do
            local ShopBlips = AddBlipForCoord(v.BlipCoords)
            SetBlipSprite(ShopBlips, v.Sprite)
            SetBlipDisplay(ShopBlips, v.Display)
            SetBlipScale(ShopBlips, v.Scale)
            SetBlipColour(ShopBlips, v.Colour)
            SetBlipAsShortRange(ShopBlips, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(v.Name)
            EndTextCommandSetBlipName(ShopBlips)
        end
    end
end)

--Get Player job
function GetJob()
    if Config.Framework == "ESX" then
        if ESX.GetPlayerData().job then
            return ESX.GetPlayerData().job.name
        else
            return false
        end
    elseif Config.Framework == "qbcore" then
        if QBCore.Functions.GetPlayerData().job then
            return QBCore.Functions.GetPlayerData().job.name
        else
            return false
        end
    end
end

SpawnVehicle = function(model, coords, heading, livery)
    if Config.Framework == "ESX" then
        ESX.Game.SpawnVehicle(model, coords, heading, function(vehicle)
            SetEntityHeading(vehicle, heading)
            SetVehicleLivery(vehicle, livery)
        end)
    elseif Config.Framework == "qbcore" then
        QBCore.Functions.SpawnVehicle(model, function(vehicle)
            SetEntityHeading(vehicle, heading)
            SetVehicleLivery(vehicle, livery)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(vehicle))
        end, coords, true)
    elseif Config.Framework == "standalone" then
        -- ADD YOU FRAMEWORK
    end
end

GetClosestCar = function(coords)
    if Config.Framework == "ESX" then
        return ESX.Game.GetClosestVehicle(coords)
    elseif Config.Framework == "qbcore" then
        return QBCore.Functions.GetClosestVehicle()
    elseif Config.Framework == "standalone" then
        -- ADD YOU FRAMEWORK
    end
end

Minigame = function()
    success = lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    return success
end

local using = false
RegisterNetEvent('drc_wine:consumables', function(text, animation, duration, effect)
    if not using then
        using = true
        if animation.emote.enabled then
            dict = animation.emote.anim.dict
            clip = animation.emote.anim.clip
            model = animation.emote.prop.model
            pos = animation.emote.prop.pos
            rot = animation.emote.prop.rot
            bone = animation.emote.prop.bone
            RequestAnimDict(dict)
            while (not HasAnimDictLoaded(dict)) do Wait(0) end
            TaskPlayAnim(cache.ped, dict, clip, 3.0, 1.0, -1, 49, 0, false, false, false)
            local hash = model
            RequestModel(hash)
            while not HasModelLoaded(hash) do
                Wait(100)
                RequestModel(hash)
            end
            local prop = CreateObject(hash, GetEntityCoords(cache.ped), true, true, true)
            AttachEntityToEntity(prop, cache.ped, GetPedBoneIndex(cache.ped, bone), pos, rot,
                true, true, false, false, 1, true)
            ProgressBar(duration, text)
            using = false
            DetachEntity(prop, false, false)
            DeleteEntity(prop)
            ClearPedTasks(cache.ped)
            Action(effect)
            using = false
        elseif animation.scenario.enabled then
            TaskStartScenarioInPlace(cache.ped, animation.scenario.anim.scenario, 0, false)
            ProgressBar(duration, text)
            using = false
            ClearPedTasks(cache.ped)
            Action(effect)
            using = false
        end
    end
end)
