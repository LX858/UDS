local Config = require 'config.config'


local spawnedPeds = {}
local function NearPed(model, coords, gender, animDict, animName, scenario, skin)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(50)
    end
    spawnedPed = CreatePed(Config.GenderNumbers[gender], model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAlpha(spawnedPed, 0, false)
    FreezeEntityPosition(spawnedPed, true)
    SetEntityInvincible(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    if animDict and animName then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(50)
        end
        TaskPlayAnim(spawnedPed, animDict, animName, 8.0, 0, -1, 1, 0, 0, 0)
    end
    if scenario then
        TaskStartScenarioInPlace(spawnedPed, scenario, 0, true)
    end
    for i = 0, 255, 51 do
        Wait(50)
        SetEntityAlpha(spawnedPed, i, false)
    end
    return spawnedPed
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000)
    LoadPed()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k, v in pairs(Config.Target) do
        exports.ox_target:removeZone(v.name .. k)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    LoadPed()
end)

function LoadPed()
    for k, v in pairs(Config.Target) do
        exports.ox_target:addBoxZone({
            name = v.name .. k,
            coords = vec3(v.coords.x, v.coords.y, v.coords.z),
            size = vec3(2, 2 , 2),
            rotation = 0.0,
            debug = false,
            drawSprite = true,
            options = {
                {
                    name = "Target_"..v.name .. k,
                    icon = "fas fa-circle",
                    label = v.label,
                    groups = v.Job or nil,
                    distance = v.distance,
                    onSelect = function()
                        TriggerEvent(v.event)
                    end
                }
            }
        })
    end
end

CreateThread(function()
    while true do
        Wait(2000)
        for k,v in pairs(Config.PedList) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - v.coords.xyz)
            if distance < 20 and not spawnedPeds[k] then
                local spawnedPed = NearPed(v.model, v.coords, v.gender, v.animDict, v.animName, v.scenario, v.skin)
                spawnedPeds[k] = { spawnedPed = spawnedPed }
            end
            if distance >= 20 and spawnedPeds[k] then
                for i = 255, 0, -51 do
                    Wait(50)
                    SetEntityAlpha(spawnedPeds[k].spawnedPed, i, false)
                end
                DeletePed(spawnedPeds[k].spawnedPed)
                spawnedPeds[k] = nil
            end
        end
    end
end)

