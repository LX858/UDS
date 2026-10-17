local Config = require 'config.config'


if Config.GiveVehicleRewards then 
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1)
            local sleep = 1000
            if IsPedInAnyVehicle(PlayerPedId(), true) then
                sleep = 5
                DisablePlayerVehicleRewards(PlayerId())
            end
            Citizen.Wait(sleep)
        end
    end)
end