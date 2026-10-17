function Luxu.GetVehiclePlate(veh)
      local vehicle = veh
      if not vehicle then
            vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
      end
      if vehicle == 0 then return end
      local plate = Luxu.utils:Trim(GetVehicleNumberPlateText(vehicle))
      return plate
end

function Luxu.GetMugShot()
      local ped = PlayerPedId()
      local result = exports['LuxuModules']:GetMugShotBase64(ped)
      return result
end

function Luxu.SpawnCarAndReturnInfo(model_name)
      local model = GetHashKey(model_name)
      RequestModel(model)
      while not HasModelLoaded(model) do
            Wait(10)
      end
      local veh = CreateVehicle(model, 0, 0, 0, 0, false, false)
      repeat
            Wait(0)
      until DoesEntityExist(veh)
      SetEntityCollision(veh, false, false)
      local class = GetVehicleClass(veh)
      SetVehicleEngineOn(veh, true, true, true)
      local mods = Luxu.GetVehicleModList(veh)

      mods["plate"] = Luxu.utils:CustomPlate()
      local info = {
            model = model_name,
            modelHash = model,
            plate = mods["plate"],
            mods = mods,
            class = class,
            type = GetVehicleType(veh)
      }
      DeleteVehicle(veh)
      SetModelAsNoLongerNeeded(model)
      return info
end
