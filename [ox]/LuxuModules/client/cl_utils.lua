--[[ Functions ]]

---@diagnostic disable-next-line: duplicate-set-field
function Luxu.GetFrameworkObject()
      return exports.LuxuModules.GetFrameworkObject()
end

---@diagnostic disable-next-line: duplicate-set-field
function Luxu.Notify(data)
      local msg = data.msg
      local visual = data.type
      local duration = data.duration
      if not visual or visual == 'primary' then visual = 'info' end

      if Config.Notify['ox'] then
            lib.notify({ title = msg, type = visual, duration = duration or 5000 })
      elseif Config.Notify['okok'] then
            exports['okokNotify']:Alert("", msg, duration or 5000, visual, true)
      elseif Config.Notify['default'] then
            if CurrentFramework == 'qb' then
                  if visual == 'info' or visual == 'warning' then visual = 'primary' end
                  QBCore.Functions.Notify(msg, visual, duration or 5000)
            elseif CurrentFramework == 'esx' then
                  ESX.ShowNotification(msg, duration or 5000, visual)
            end
      end
end

function Luxu.ShowTextUI()
      -- Not being used at this moment
end

function Luxu.HealSelf()
      local ped = PlayerPedId()
      SetEntityMaxHealth(ped, 200)
      SetEntityHealth(ped, 200)
      ClearPedBloodDamage(ped)
      SetPlayerSprint(ped, true)
      ResetPedMovementClipset(ped, 0.0)
      TriggerServerEvent('hud:server:RelieveStress', 100)
      TriggerServerEvent("hospital:server:SetDeathStatus", false)
      TriggerServerEvent("hospital:server:SetLaststandStatus", false)
      TriggerEvent('ars_ambulancejob:healPlayer', { heal = true })
      TriggerEvent('visn_are:resetHealthBuffer')
      TriggerEvent('esx_basicneeds:healPlayer')
end

function Luxu.KillSelf()
      SetEntityHealth(PlayerPedId(), 0)
end

function Luxu.GodMode(mode)
      SetEntityInvincible(PlayerPedId(), mode)
end

function Luxu.GetVehicleModList(vehicle)
      if CurrentFramework == 'qb' then
            return QBCore.Functions.GetVehicleProperties(vehicle)
      elseif CurrentFramework == 'esx' then
            return ESX.Game.GetVehicleProperties(vehicle)
      end
end

function Luxu.GetVehicleProperties(vehicle)
      if CurrentFramework == 'qb' then
            return QBCore.Functions.GetVehicleProperties(vehicle)
      elseif CurrentFramework == 'esx' then
            return ESX.Game.GetVehicleProperties(vehicle)
      end
end

function Luxu.ReloadSkin()
      local model

      local function loadPlayerSkin(gender)
            if gender == 1 then
                  model = `mp_f_freemode_01` -- Female Model
            else
                  model = `mp_m_freemode_01` -- Male Model
            end

            RequestModel(model)
            while not HasModelLoaded(model) do
                  Wait(1)
            end
            SetPlayerModel(PlayerId(), model)
            SetModelAsNoLongerNeeded(model)
      end

      if IsResourceRunning('illenium-appearance') then
            TriggerEvent('illenium-appearance:client:reloadSkin')
      elseif IsResourceRunning('codem-appearance') then
            TriggerEvent('codem-appearance:reloadSkin')
      else
            if CurrentFramework == 'qb' then
                  -- QB Core
                  local playerData = QBCore.Functions.GetPlayerData()
                  if not playerData.charinfo.gender then
                        return
                  end

                  loadPlayerSkin(playerData.charinfo.gender)
                  TriggerServerEvent("qb-clothes:loadPlayerSkin")
                  Wait(2000)
            else
                  -- ESX
                  ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                        local isMale = skin.sex == 0
                        TriggerEvent('skinchanger:loadDefaultModel', isMale)
                        Wait(250)
                        TriggerEvent('skinchanger:loadSkin', skin)
                        Wait(100)
                  end)
            end
      end
end

function Luxu.FixVehicle(vehicle)
      SetVehicleFixed(vehicle)
      SetVehicleDeformationFixed(vehicle)
      SetVehicleFuelLevel(vehicle, 100.0)
      SetVehicleUndriveable(vehicle, false)
      SetVehicleEngineOn(vehicle, true, true, false)
      SetVehiclePetrolTankHealth(vehicle, 1000.0)
      SetVehicleOilLevel(vehicle, 100.0)
      SetVehicleDirtLevel(vehicle, 0.0)
      SetVehicleEngineHealth(vehicle, 1000.0)
      SetVehicleBodyHealth(vehicle, 1000.0)
      SetVehicleTyreFixed(vehicle, 0)
      if IsResourceRunning('ti_fuel') then
            exports["ti_fuel"]:setFuel(vehicle, 100.0, "RON91")
      end
      for i = 0, 7 do
            SetVehicleTyreFixed(vehicle, i)
      end
end

--[[ Vehicle Keys  ]]
function Luxu.GiveVehicleKeys(veh)
      local vehicle = veh
      if not vehicle then
            vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
      end
      if vehicle == 0 then return end
      local plate = Luxu.GetVehiclePlate(vehicle)
      local model = GetEntityModel(vehicle)

      -- Here we are getting the vehicle model name
      -- This might not work in some custom vehicles
      -- Custom vehicles require a custom vehicles.meta
      local modelName = GetDisplayNameFromVehicleModel(model)

      if IsResourceRunning("qb-vehiclekeys") then
            TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
      elseif IsResourceRunning('qs-vehiclekeys') then
            exports['qs-vehiclekeys']:GiveKeys(plate, model)
      elseif IsResourceRunning('cd_garage') then
            TriggerEvent('cd_garage:AddKeys', plate)
      elseif IsResourceRunning('gflp10-carkeys') then
            TriggerServerEvent('LuxuModules:Server:GiveKeyItem', modelName, plate)
      elseif IsResourceRunning('wasabi_carlock') then
            exports.wasabi_carlock:GiveKeys(plate, false)
      elseif IsResourceRunning("okokGarage") then
            TriggerServerEvent("okokGarage:GiveKeys", plate)
      end
      TriggerEvent("vehiclekeys:client:SetOwner", plate)
      return true
end

--[[ Target ]]
function Luxu.GetTargetSystem()
      local target_systems = { 'ox_target', 'qb-target', 'qtarget', }

      for _, system in ipairs(target_systems) do
            if IsResourceRunning(system) then
                  return system
            end
      end
end

---@diagnostic disable-next-line: duplicate-set-field
function Luxu.DeleteVehicle(vehicle)
      SetEntityAsMissionEntity(vehicle, true, true)
      if IsResourceRunning('cd_garage') then
            TriggerServerEvent('cd_garage:RemovePersistentVehicles', exports['cd_garage']:GetPlate(vehicle))
      end
      if IsResourceRunning('jg-advancedgarages') then
            TriggerServerEvent('jg-advancedgarages:server:DeleteVehicleEntity', NetworkGetNetworkIdFromEntity(vehicle))
      end
      DeleteEntity(vehicle)
end

RegisterNetEvent("LuxuModules:Client:OpenInventory", function(targetSrc)
      local src = source
      if src == "" then return end

      if IsResourceRunning('qs-inventory') then
            TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", targetSrc)
      elseif IsResourceRunning("core_inventory") then
            TriggerServerEvent('core_inventory:server:openInventory', targetSrc, 'otherplayer', nil, nil, true)
      else
            TriggerEvent('inventory:openPlayerInventory', targetSrc) -- cheeza
            if CurrentFramework == 'qb' then
                  TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', targetSrc)
            elseif CurrentFramework == 'esx' then
                  TriggerServerEvent('esx_inventoryhud:openPlayerInventory', targetSrc)
            end
      end
end)
