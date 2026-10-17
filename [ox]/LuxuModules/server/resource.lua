--[[ Events ]]

lib.callback.register('LuxuModules:Server:GetTargetMugshot', function(source, target)
      if not GetPlayerName(target) then return end
      local mugshot = Luxu.GetTargetMugshot(target)
      return mugshot
end)

RegisterNetEvent('LuxuModules:Server:PlayerDied', function(id)

end)

RegisterNetEvent('LuxuModules:Server:PlayerDied', function(_src)
      local src = _src or source
end)

RegisterNetEvent('LuxuModules:Server:GiveKeyItem', function(modelName, plate)
      local src = tonumber(source)
      exports['gflp10-carkeys']:AddCarkey(src, plate, modelName)
end)

RegisterNetEvent('QBCore:Server:SetMetaData', function(meta, data)
      local src = source
      if meta == "inlaststand" or meta == 'isdead' then
            TriggerClientEvent('LuxuModules:Client:UpdateDeadStatus', src, data)
            if data == true then
                  TriggerEvent('LuxuModules:Server:PlayerDied', src)
            end
      end
end)

RegisterNetEvent('hospital:server:SetDeathStatus', function(isDead)
      TriggerClientEvent('LuxuModules:Client:UpdateDeadStatus', source, isDead)
      if isDead then
            TriggerEvent('LuxuModules:Server:PlayerDied', source)
      end
end)
RegisterNetEvent('hospital:server:SetLaststandStatus', function(isDead)
      TriggerClientEvent('LuxuModules:Client:UpdateDeadStatus', source, isDead)
      if isDead then
            TriggerEvent('LuxuModules:Server:PlayerDied', source)
      end
end)


--[[ Exports ]]
exports('GetPlayerObject', Luxu.GetPlayerObject)
exports('GetPlayerFrameworkIdentifier', Luxu.GetPlayerFrameworkIdentifier)
exports('GetPlayerJob', Luxu.GetPlayerJob)
exports('KillPlayer', Luxu.KillPlayer)
exports('RevivePlayer', Luxu.RevivePlayer)
exports('GetCharacterName', Luxu.GetCharacterName)
exports('GetPlayerData', Luxu.GetPlayerData)
exports('SetTime', Luxu.SetTime)
exports('SetWeather', Luxu.SetWeather)
exports('GetVehicleInfoByPlate', Luxu.GetVehicleInfoByPlate)
exports('GiveVehicle', Luxu.GiveVehicle)
exports('GetOwnedVehicles', Luxu.GetOwnedVehicles)
exports('GetPlayerAccounts', Luxu.GetPlayerAccounts)
exports('SetAccountMoney', Luxu.SetAccountMoney)
exports('GiveClothingMenu', Luxu.GiveClothingMenu)
exports('Notify', Luxu.Notify)
exports('SetPlayerJob', Luxu.SetPlayerJob)
exports('GivePlayerItem', Luxu.GivePlayerItem)
exports('GetAccountMoney', Luxu.GetAccountMoney)
