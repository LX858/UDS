---@class CLCruiseControlImpl : Impl
local Impl = NewImpl("CruiseControl")

function Impl:Init()
  self.cruiseControl = false
  main:LogInfo("%s initialized", self:GetName())
  self:RegisterCommands()
end

function Impl:OnReady()
  main:LogInfo("%s ready", self:GetName())
end

function Impl:RegisterCommands()
  RegisterCommand("cruisecontrol", function(source, args)
    self:ToggleCruiseControl()
  end, false)
  RegisterKeyMapping("cruisecontrol", "Bật/Tắt Cruise Control", "keyboard", "g")
end

function Impl:ToggleCruiseControl()
  if self.cruiseControl then
    self.cruiseControl = false
    Framework.ShowNotification("Đã tắt chế độ Cruise Control")
    return
  end
  local ped = PlayerPedId()
  local vehicle = GetVehiclePedIsIn(ped, false)
  if not vehicle or vehicle == 0 then
    return
  end
  local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
  if not isDriver then
    return
  end
  self.cruiseControl = true
  local captureSpeed = GetEntitySpeed(vehicle)
  Framework.ShowNotification(("Đã bật chế độ Cruise Control với tốc độ %.2f km/h"):format(captureSpeed * 3.6))
  Citizen.CreateThread(function()
    while self.cruiseControl do
      Wait(0)
      SetVehicleMaxSpeed(vehicle, captureSpeed)

      if IsControlJustReleased(0, 72) then
        self:ToggleCruiseControl()
      end
    end
    SetVehicleMaxSpeed(vehicle, 0.0)
  end)
end
