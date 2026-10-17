---@param src number
RegisterNetEvent('LuxuModules:Server:PlayerLoaded', function(src)

end)


AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
      TriggerEvent('LuxuModules:Server:PlayerUnloaded', source)
end)
