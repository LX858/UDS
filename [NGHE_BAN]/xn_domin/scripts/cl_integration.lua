-- Client script for QBCore/ox_inventory integration

local blip = nil
local area_blip = nil

CreateThread(function()
    if not Config.EnableBlip then return end
    AddTextEntry("PROSP_BLIP", Config.ProspectingBlipText)
    blip = AddBlipForCoord(Config.BlipLocation.x, Config.BlipLocation.y, Config.BlipLocation.z)
    SetBlipSprite(blip, Config.ProspectingBlipSprite)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("PROSP_BLIP")
    EndTextCommandSetBlipName(blip)
    
    area_blip = AddBlipForRadius(Config.BlipLocation.x, Config.BlipLocation.y, Config.BlipLocation.z, Config.AreaSize)
    SetBlipSprite(area_blip, 10)
end)

RegisterNetEvent('prospecting:startProspecting', function()
    local pos = GetEntityCoords(PlayerPedId())
    local dist = #(pos - Config.BlipLocation)
    
    if dist < Config.AreaSize then
        TriggerServerEvent('prospecting:activateProspecting')
    else
        lib.notify({
            description = 'You are not in a prospecting area!',
            type = 'error',
            duration = 5000
        })
    end
end)

RegisterNetEvent('prospecting:useDetector', function()
    if IsPedInAnyVehicle(PlayerPedId()) then
        lib.notify({
            description = 'You can not prospect from a vehicle!',
            type = 'error',
            duration = 5000
        })
    else
        TriggerEvent('prospecting:startProspecting')
    end
end)
