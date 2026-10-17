if not lib.loadJson or not lib.checkDependency('ox_lib', "3.19.2") then
      print("ox_lib is outdated, this resource will not work")
      print("please update ox_lib")
      print("ox_lib is outdated, this resource will not work")
      print("please update ox_lib")
      print("ox_lib is outdated, this resource will not work")
      print("please update ox_lib")
      print("ox_lib is outdated, this resource will not work")
      print("please update ox_lib")
      error("ox_lib is outdated, this resource will not work")
end



--[[ Timer Start ]]
local start_timer         = GetGameTimer()

FrameworkObj, QBCore, ESX = nil, nil, nil
CurrentFramework          = nil

---@class Luxu
local Luxu                = {
      utils = {},
}

_ENV.Luxu                 = Luxu


ResourceName           = GetCurrentResourceName()
local LoadResourceFile = LoadResourceFile
local context          = IsDuplicityVersion() and 'server' or 'client'

function IsResourceRunning(resource)
      return GetResourceState(resource) == 'started'
end

-- Dont Duplicate LuxuModules Config
if ResourceName ~= "LuxuModules" then
      --[[ Load Config ]]
      require '@LuxuModules.config'
end

--[[ Load Shared ]]
Luxu.utils = require '@LuxuModules.shared.utils'
--[[ error(("Error loading utils %s"):format(err), 3) ]]

--[[ Load Framework ]]

FrameworkObj = require '@LuxuModules.shared.framework'
QBCore       = FrameworkObj
ESX          = FrameworkObj

--[[ Refresh Framework Object ]]
RegisterNetEvent('QBCore:Client:UpdateObject', function()
      FrameworkObj = require '@LuxuModules.shared.framework'
      QBCore       = FrameworkObj
end)
RegisterNetEvent('QBCore:Server:UpdateObject', function()
      if source ~= '' then return false end
      FrameworkObj = require '@LuxuModules.shared.framework'
      QBCore       = FrameworkObj
end)

--[[ error(("Error loading framework %s"):format(err), 3) ]]

--[[ Load Client and Server ]]
if context == 'client' then
      local list = { 'client.lua', 'cl_utils.lua' }
      for _, v in ipairs(list) do
            local file = LoadResourceFile('LuxuModules', ('client/%s'):format(v))
            if file then
                  local chunk = load(file)
                  if chunk then pcall(chunk) else error(("Error Loading Chunk %s"):format(v)) end
            end
      end
elseif context == 'server' then
      local list = { 'server.lua', 'sv_utils.lua' }
      for _, v in ipairs(list) do
            local file = LoadResourceFile('LuxuModules', ('server/%s'):format(v))
            if file then
                  local chunk = load(file)
                  if chunk then pcall(chunk) else error(("Error Loading Chunk %s"):format(v)) end
            end
      end
      --[[ Check for Onesync ]]
      if Config.OnesyncInfity_Checker or Config.OnesyncInfinityChecker then
            local onesync = GetConvar('onesync', "false")
            if onesync == 'false' then
                  error('onesync is not enabled, please enable it to use this script.')
            elseif onesync == 'legacy' then
                  error('onesync legacy detected, please enable onesync infinity')
            else
                  print("Onesync Infinity is enabled!")
            end
      end
end

print(('[%s] initialized LuxuModules in %s ms!'):format(ResourceName, GetGameTimer() - start_timer))
