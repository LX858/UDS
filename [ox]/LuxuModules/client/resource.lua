--[[ Events ]]
RegisterNetEvent('LuxuModules:Client:UpdateDeadStatus', function(value)
      IsDead = value
end)
RegisterNetEvent('baseevents:onPlayerDied', function()
      IsDead = true
      TriggerServerEvent('LuxuModules:Server:PlayerDied')
end)

RegisterNetEvent('LuxuModules:Client:Notify', function(data)
      Luxu.Notify(data)
end)

--[[ Callbacks ]]
lib.callback.register('LuxuModules:Client:KillSelf', Luxu.KillSelf)
lib.callback.register('LuxuModules:Client:HealSelf', Luxu.HealSelf)
lib.callback.register('LuxuModules:Client:CheckDeadStatus', Luxu.CheckDeadStatus)
lib.callback.register('LuxuModules:Client:GetMugshot', Luxu.GetMugShot)
lib.callback.register("LuxuModules:Client:GiveVehicleKeys", Luxu.GiveVehicleKeys)
lib.callback.register('LuxuModules:Client:SpawnCarAndReturnInfo', Luxu.SpawnCarAndReturnInfo)
lib.callback.register('LuxuModules:Client:GetVehiclePlate', function()
      local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
      if not vehicle then return end
      return Luxu.GetVehiclePlate(vehicle)
end)
RegisterNetEvent('LuxuModules:Client:ReviveSelf', function()
      if source == "" then return end
      local ped = PlayerPedId()
      local pos = GetEntityCoords(ped)
      NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
      --[[ Set ped health ]]
      SetEntityHealth(ped, 200)
      SetPedMaxHealth(ped, 200)
      SetEntityHealth(ped, 200)
      SetPlayerSprint(ped, true)
      ResetPedMovementClipset(ped, 0.0)
      TriggerServerEvent('hud:server:RelieveStress', 100)
      TriggerServerEvent("hospital:server:SetDeathStatus", false)
      TriggerServerEvent("hospital:server:SetLaststandStatus", false)
end)


exports('KillSelf', Luxu.KillSelf)
exports("HealSelf", Luxu.HealSelf)
exports('ReloadSkin', Luxu.ReloadSkin)
exports('GiveVehicleKeys', Luxu.GiveVehicleKeys)
exports('GetVehiclePlate', Luxu.GetVehiclePlate)




--[[ Events ]]
--[[ Revive ❤️‍🩹 ]]
RegisterNetEvent('playerSpawned', function()
      IsDead = false
end)

RegisterNetEvent('LuxuModules:ApperanceChanger', function()
      exports['fivem-appearance']:startPlayerCustomization(function(appearance)
            if (appearance) then
                  TriggerServerEvent('saveCharacterCustomization', json.encode(appearance))
            end
      end)
end)


--[[ Events ]]
--[[ Revive ❤️‍🩹 ]]
RegisterNetEvent('playerSpawned', function()
      IsDead = false
end)
