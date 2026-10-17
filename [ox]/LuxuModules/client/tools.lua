local mugHandle
local mugShottxd
local mugshotProm

MugshotsCache = {}

--[[ Functions ]]
local function GetMugShotBase64(Ped)
      mugshotProm = promise.new()
      if not Ped then return "" end
      mugHandle = nil
      mugHandle = RegisterPedheadshot(Ped)

      local timer = 2000
      while ((not mugHandle or not IsPedheadshotReady(mugHandle) or not IsPedheadshotValid(mugHandle)) and timer > 0) do
            Citizen.Wait(10)
            timer = timer - 10
      end

      if (IsPedheadshotReady(mugHandle) and IsPedheadshotValid(mugHandle)) then
            mugShottxd = GetPedheadshotTxdString(mugHandle)
      end

      SendNUIMessage({
            type = 'convert',
            MugShotTxd = mugShottxd
      })

      return Citizen.Await(mugshotProm)
end

--[[ NUI Callbacks ]]
RegisterNUICallback('ReceiveURL', function(data, cb)
      local base64 = (data.url)
      mugshotProm:resolve(base64)
      UnregisterPedheadshot(mugHandle)
      cb(true)
end)


exports('GetMugShotBase64', GetMugShotBase64)
