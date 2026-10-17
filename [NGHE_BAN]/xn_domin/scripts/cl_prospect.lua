local blip = nil
local area_blip = nil

CreateThread(function()
    if not Config.EnableBlip then return end

    blip = AddBlipForCoord(Config.BlipLocation.x, Config.BlipLocation.y, Config.BlipLocation.z)
    SetBlipSprite(blip, Config.ProspectingBlipSprite)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 0.75)
    SetBlipColour(blip, 1) -- Màu đỏ (1 = red)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.ProspectingBlipText)
    EndTextCommandSetBlipName(blip)
    
    area_blip = AddBlipForRadius(Config.BlipLocation.x, Config.BlipLocation.y, Config.BlipLocation.z, Config.AreaSize)
    SetBlipColour(area_blip, 2) -- Màu đỏ cho vùng radius
    SetBlipAlpha(area_blip, 100) -- Độ trong suốt
end)


RegisterNetEvent('r3_prospecting:startProspecting', function()
    local pos = GetEntityCoords(PlayerPedId())

    -- Make sure the player is within the prospecting zone before they start
    local dist = #(pos - Config.BlipLocation)
    if dist < Config.AreaSize then
        TriggerServerEvent('r3_prospecting:activateProspecting')
    else
		lib.notify({
            description = 'You are not in a prospecting area!',
            type = 'error',
            duration = 5000
        })
	end
end)

RegisterNetEvent('r3_prospecting:useDetector', function()
	if IsPedInAnyVehicle(PlayerPedId()) then
		lib.notify({
            description = 'You can not prospect from a vehicle!',
            type = 'error',
            duration = 5000
        })
	else
		TriggerEvent('r3_prospecting:startProspecting')
	end
end)
