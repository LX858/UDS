--[[ Functions ]]
function Luxu.GetPlayerFrameworkIdentifier(id)
      if CurrentFramework == 'qb' then
            local player = type(id) == 'table' and id or QBCore.Functions.GetPlayer(id)
            if not player then return end
            return player.PlayerData.citizenid
      elseif CurrentFramework == 'esx' then
            local player = type(id) == 'table' and id or ESX.GetPlayerFromId(id)
            if not player then return end
            return player.getIdentifier()
      end
end

function Luxu.KillPlayer(id)
      if id == nil then return end
      if not GetPlayerName(id) then return end
      lib.callback.await('LuxuModules:Client:KillSelf', id)
      return true
end

function Luxu.SetStatus(id, status, value)
      if CurrentFramework == 'qb' then
            local Player = QBCore.Functions.GetPlayer(id)
            Player.Functions.SetMetaData(status, value)
            if status == 'hunger' or status == 'thirst' then
                  TriggerClientEvent('hud:client:UpdateNeeds', id, Player.PlayerData.metadata['hunger'],
                        Player.PlayerData.metadata['thirst'])
            end
      elseif CurrentFramework == 'esx' then
            if value == 100 then
                  TriggerClientEvent('esx_status:set', id, status, 1000000)
            end
      end
end

function Luxu.RevivePlayer(id)
      if id == nil then return end
      if not GetPlayerName(id) then return end

      TriggerClientEvent('visn_are:resetHealthBuffer', id)

      if IsResourceRunning('wasabi_ambulance') then
            exports.wasabi_ambulance:RevivePlayer(id)
      elseif IsResourceRunning('ars_ambulancejob') then
            TriggerClientEvent('ars_ambulancejob:healPlayer', id, { revive = true })
      else
            if CurrentFramework == 'qb' then
                  TriggerClientEvent('hospital:client:Revive', id)
                  TriggerClientEvent('qbx_medical:client:playerRevived', id)
            elseif CurrentFramework == 'esx' then
                  TriggerClientEvent('esx_ambulancejob:revive', id)
            end
            TriggerClientEvent('LuxuModules:Client:ReviveSelf', id)
      end


      TriggerClientEvent('refine-hp:client:Revive', id)
      TriggerClientEvent('refine-hp:client:adminHeal', id)

      return true
end

function Luxu.GetCharacterName(playerObj)
      if CurrentFramework == 'qb' then
            local firstName = playerObj.PlayerData.charinfo.firstname
            local lastName  = playerObj.PlayerData.charinfo.lastname
            return string.format('%s %s', firstName, lastName)
      elseif CurrentFramework == 'esx' then
            return playerObj.getName()
      end
end

function Luxu.GiveClothingMenu(id)
      if IsResourceRunning('illenium-appearance') then
            TriggerClientEvent("illenium-appearance:client:openClothingShop", id, true)
            return
      end
      if CurrentFramework == 'qb' then
            TriggerClientEvent('qb-clothing:client:openMenu', id)
      elseif CurrentFramework == 'esx' then
            TriggerClientEvent('esx_skin:openSaveableMenu', id)
      end
end

function Luxu.GetOwnedVehicles(id)
      if CurrentFramework == 'qb' then
            local playerObj = Luxu.GetPlayerObject(id)
            if not playerObj then return end
            local identifier = Luxu.GetFrameworkIdentifier(playerObj)

            local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = @citizenid', {
                  ['@citizenid'] = identifier
            })
            return result
      elseif CurrentFramework == 'esx' then
            local playerObj = Luxu.GetPlayerObject(id)
            if not playerObj then return end
            local identifier = Luxu.GetFrameworkIdentifier(playerObj)
            local result = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', {
                  ['@owner'] = identifier
            })
            return result
      end
end

function Luxu.GetPlayerAccounts(id)
      local playerObj = type(id) == 'table' and id or Luxu.GetPlayerObject(id)
      local data = {}
      if CurrentFramework == 'qb' then
            local accounts = playerObj.PlayerData.money

            for k, v in pairs(accounts) do
                  table.insert(data, {
                        name = k,
                        money = v
                  })
            end
      elseif CurrentFramework == 'esx' then
            local accounts = playerObj.getAccounts()

            for k, v in pairs(accounts) do
                  table.insert(data, {
                        name = v.name,
                        money = v.money
                  })
            end
      end
      return data
end

function Luxu.GetAccountMoney(id, account)
      local playerObj = type(id) == 'table' and id or Luxu.GetPlayerObject(id)
      if CurrentFramework == 'qb' then
            local accounts = playerObj.PlayerData.money
            for k, v in pairs(accounts) do
                  if k == account then return v end
            end
      elseif CurrentFramework == 'esx' then
            local accounts = playerObj.getAccounts()

            for k, v in pairs(accounts) do
                  if v.name == account then return v.money end
            end
      end
end

function Luxu.SetAccountMoney(id, account, operation, amount)
      local playerObj = Luxu.GetPlayerObject(id)
      local accounts = Luxu.GetPlayerAccounts(id)
      local balance
      for _, v in ipairs(accounts) do
            if v.name == account then
                  balance = v.money
                  break
            end
      end
      if type(balance) ~= 'number' then return end
      if not playerObj then return end
      if CurrentFramework == 'qb' then
            if operation == 'add' then
                  playerObj.Functions.AddMoney(account, amount)
            elseif operation == 'remove' then
                  playerObj.Functions.RemoveMoney(account, amount)
            elseif operation == 'set' then
                  playerObj.Functions.SetMoney(account, amount)
            end
      elseif CurrentFramework == 'esx' then
            if operation == 'add' then
                  playerObj.addAccountMoney(account, amount)
            elseif operation == 'remove' then
                  playerObj.removeAccountMoney(account, amount)
            elseif operation == 'set' then
                  playerObj.setAccountMoney(account, amount)
            end
      end
      return true
end

function Luxu.SetTime(hours, minutes)
      if IsResourceRunning('Renewed-Weathersync') then
            exports["qb-weathersync"]:setTime(hours, minutes)
      elseif IsResourceRunning('cd_easytime') then
            exports['cd_easytime']:forceUpdate({ hours = hours, minutes = minutes })
      elseif IsResourceRunning('qb-weathersync') then
            exports["qb-weathersync"]:setTime(hours, minutes)
      end

      return true
end

---@param weather string
function Luxu.SetWeather(weather)
      if IsResourceRunning('Renewed-Weathersync') then
            exports["qb-weathersync"]:setWeather(weather)
      elseif IsResourceRunning('cd_easytime') then
            exports['cd_easytime']:forceUpdate({ weather = weather, instantweather = true })
      elseif IsResourceRunning('qb-weathersync') then
            exports["qb-weathersync"]:setWeather(weather)
      end
      return true
end

function Luxu.FreezeTime()
      if IsResourceRunning('Renewed-Weathersync') then
            status = exports["qb-weathersync"]:setTimeFreeze();
      elseif IsResourceRunning('cd_easytime') then
            local data = exports['cd_easytime']:GetWeather()
            status = not data.freeze
            exports['cd_easytime']:forceUpdate({ freeze = status })
      elseif IsResourceRunning('qb-weathersync') then
            status = exports["qb-weathersync"]:setTimeFreeze();
      end
      return true, status
end

function Luxu.SetBlackout(state)
      if IsResourceRunning('Renewed-Weathersync') then
            exports["qb-weathersync"]:setBlackout(state)
      elseif IsResourceRunning('cd_easytime') then
            exports['cd_easytime']:forceUpdate({ blackout = state })
      elseif IsResourceRunning('qb-weathersync') then
            exports["qb-weathersync"]:setBlackout(state)
      end
end

function Luxu.GiveVehicle(src, model)
      local playerObj = Luxu.GetPlayerObject(src)
      if not playerObj then return end

      local CarInfo = lib.callback.await('LuxuModules:Client:SpawnCarAndReturnInfo', src, model)

      if not CarInfo then return false end


      local identifier = Luxu.GetFrameworkIdentifier(playerObj)
      if CurrentFramework == 'qb' then
            local license = playerObj.PlayerData.license
            return MySQL.Sync.execute(
                  'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage, vehicle_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
                  , {
                        license,
                        identifier,
                        CarInfo.model,
                        CarInfo.modelHash,
                        json.encode(CarInfo.mods),
                        CarInfo.plate,
                        1,
                        Config.DefaultParkingGarage?.qb and Config.DefaultParkingGarage.qb or "pillboxgarage",
                        CarInfo.type
                  })
      elseif CurrentFramework == 'esx' then
            return MySQL.Sync.execute(
                  'INSERT INTO owned_vehicles (owner, plate, vehicle, stored, parking, type) VALUES (?, ?, ?, ?, ?, ?)'
                  , {
                        identifier,
                        CarInfo.plate,
                        json.encode(CarInfo.mods),
                        1,
                        Config.DefaultParkingGarage?.esx and Config.DefaultParkingGarage.esx or "SanAndreasAvenue",
                        CarInfo.type
                  })
      end
      return false
end

---@param modelName string
function Luxu.SaveVehicleToDB(license, identifier, modelName, plate, props)
      modelName = modelName:lower()
      if props then
            props["plate"] = plate
      end
      if CurrentFramework == 'qb' then
            return MySQL.prepare.await(
                  'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) SELECT p.license, ?, ?, ?, ?, ?, ?, ? FROM players p WHERE p.citizenid = ?'
                  , {
                        identifier,
                        modelName,
                        GetHashKey(modelName),
                        json.encode(props),
                        plate,
                        1,
                        Config.DefaultParkingGarage?.qb and Config.DefaultParkingGarage.qb or "pillboxgarage",
                        identifier
                  })
      elseif CurrentFramework == 'esx' then
            return MySQL.Sync.execute(
                  'INSERT INTO owned_vehicles (owner, plate, vehicle, stored, parking) VALUES (?, ?, ?, ?, ?)'
                  , {
                        identifier,
                        plate,
                        json.encode({ model = GetHashKey(modelName), plate = plate }),
                        1,
                        Config.DefaultParkingGarage?.esx and Config.DefaultParkingGarage.esx or "SanAndreasAvenue"
                  }
            )
      end
end

function Luxu.UpdateVehiclePlate(oldPlate, newPlate)
      if CurrentFramework == "esx" then
            local mods = MySQL.prepare.await("SELECT vehicle FROM owned_vehicles WHERE plate = ? LIMIT 1", { oldPlate }) --[[ @as string? ]]
            print(mods)
            if not mods then return end
            mods = json.decode(mods)
            mods.plate = newPlate
            MySQL.prepare.await("UPDATE owned_vehicles SET plate = ?, vehicle = ? WHERE plate = ?",
                  { newPlate, json.encode(mods), oldPlate })
      else
            local mods = MySQL.prepare.await("SELECT mods FROM player_vehicles WHERE plate = ?", { oldPlate }) --[[ @as string? ]]
            if not mods then return end
            mods = json.decode(mods)
            mods.plate = newPlate
            MySQL.prepare.await("UPDATE player_vehicles SET plate = ?, mods = ? WHERE plate = ? LIMIT 1",
                  { newPlate, json.encode(mods), oldPlate })
      end
end

---@param viewerSrc number
---@param targetSrc number
function Luxu.OpenPlayerInventory(viewerSrc, targetSrc)
      if IsResourceRunning("ox_inventory") then
            exports.ox_inventory:forceOpenInventory(tonumber(viewerSrc), 'player', tonumber(targetSrc))
      elseif IsResourceRunning("origen_inventory") then
            exports.origen_inventory:OpenInventoryById(viewerSrc, targetSrc)
      elseif IsResourceRunning("ps-inventory") then
            exports["ps-inventory"].OpenInventoryById(viewerSrc, targetSrc)
      elseif IsResourceRunning("tgiann-inventory") then
            exports["tgiann-inventory"]:OpenInventory(targetSrc, "otherplayer", viewerSrc, nil, { showClothe = false })
      elseif IsResourceRunning("codem-inventory") then
            TriggerEvent("codem-inventory:OpenInventory", viewerSrc, targetSrc)
            TriggerClientEvent("codem-inventory:client:openplayerinventory", viewerSrc, targetSrc)
      else
            if not xpcall(function()
                      exports["qb-inventory"]:OpenInventoryById(viewerSrc, targetSrc)
                      return true
                end, function() end) then
                  TriggerClientEvent("LuxuModules:Client:OpenInventory", viewerSrc, targetSrc)
            end
      end
end

function Luxu.GivePlayerItem(source, item, amount, metadata)
      local PlayerObj = Luxu.GetPlayerObject(source)

      if IsResourceRunning('ox_inventory') then
            exports.ox_inventory:AddItem(source, item, amount, metadata, nil, nil)
      elseif IsResourceRunning("origen_inventory") then
            exports.origen_inventory:AddItem(source, item, amount, nil, metadata)
      elseif IsResourceRunning('ak47_inventory') then
            exports['ak47_inventory']:AddItem(source, item, amount, nil, metadata)
      elseif IsResourceRunning('core_inventory') then
            local identifier = Luxu.GetFrameworkIdentifier(PlayerObj)
            local inventory = 'content-' .. identifier:gsub(':', '')
            exports['core_inventory']:addItem(inventory, item, amount, metadata, "content")
      elseif IsResourceRunning('qs-inventory') then
            exports['qs-inventory']:AddItem(source, item, amount, nil, metadata)
      elseif IsResourceRunning("tgiann-inventory") then
            exports["tgiann-inventory"]:AddItem(source, item, amount)
      elseif IsResourceRunning("codem-inventory") then
            exports["codem-inventory"]:AddItem(source, item, amount, nil, metadata)
      else
            if CurrentFramework == 'qb' then
                  local result = PlayerObj.Functions.AddItem(item, amount, nil, metadata)
                  return result
            elseif CurrentFramework == 'esx' then
                  PlayerObj.addInventoryItem(item, amount)
            end
      end
      return true
end

---@return boolean
function Luxu.CanCarryItem(source, item, amount)
      local PlayerObj = Luxu.GetPlayerObject(source)

      if IsResourceRunning('ox_inventory') then
            return exports.ox_inventory:CanCarryItem(source, item, amount) == true
      elseif IsResourceRunning("origen_inventory") then
            return exports.origen_inventory:CanCarryItem(source, item, amount)
      elseif IsResourceRunning("ak47_inventory") then
            return exports['ak47_inventory']:CanAddItem(source, item, amount)
      elseif IsResourceRunning('core_inventory') then
            local identifier = Luxu.GetFrameworkIdentifier(PlayerObj)
            local inventory = 'content-' .. identifier:gsub(":", "")
            return exports['core_inventory']:canCarry(inventory, item, amount)
      elseif IsResourceRunning('qs-inventory') then
            return exports['qs-inventory']:CanCarryItem(source, item, amount)
      elseif IsResourceRunning("tgiann-inventory") then
            return exports["tgiann-inventory"]:CanCarryItem(source, item, amount)
      elseif IsResourceRunning("codem-inventory") then
            local itemList = exports["codem-inventory"]:GetItemList()
            local itemData = itemList[item]
            if not itemData then
                  print("CANCARRYITEM: Item not found in codem-inventory itemList:", item)
                  return false
            end

            -- Debug pentru greutate
            local itemWeight = itemData.weight
            if not itemWeight then
                  print("CANCARRYITEM: Weight not defined for item:", item)
                  return false
            end

            return exports["codem-inventory"]:CanCarryItem(source, item, amount)
      else
            if CurrentFramework == 'qb' then
                  local totalWeight = QBCore.Player.GetTotalWeight(PlayerObj.PlayerData.items)
                  local info = QBCore.Shared.Items[item:lower()]
                  return (totalWeight + (info['weight'] * amount)) <= 120000
            elseif CurrentFramework == 'esx' then
                  return PlayerObj.canCarryItem(item, amount)
            end
      end

      return true
end

---@return boolean
function Luxu.HasItem(source, item, amount)
      local PlayerObj = Luxu.GetPlayerObject(source)
      if IsResourceRunning('ox_inventory') then
            local count = exports.ox_inventory:GetItem(source, item, nil, true)
            return count >= amount
      elseif IsResourceRunning('origen_inventory') then
            return exports.origen_inventory:HasItem(source, item, amount)
      elseif IsResourceRunning('ak47_inventory') then
            return exports['ak47_inventory']:GetAmount(source, item) >= amount
      elseif IsResourceRunning('core_inventory') then
            local identifier = Luxu.GetFrameworkIdentifier(PlayerObj)
            local inventory = 'content-' .. identifier:gsub(":", "")
            local item = exports['core_inventory']:getItem(inventory, item)
            local count = item and item.amount or 0
            return count >= amount
      elseif IsResourceRunning('qs-inventory') then
            local count = exports['qs-inventory']:GetItemTotalAmount(source, item)
            return count >= amount
      elseif IsResourceRunning("codem-inventory") then
            return exports["codem-inventory"]:CheckItemValid(source, item, amount)
      elseif IsResourceRunning("tgiann-inventory") then
            return exports["tgiann-inventory"]:HasItem(source, item, amount)
      else
            if CurrentFramework == 'qb' then
                  local items = PlayerObj.PlayerData.items
                  local count = 0
                  for k, v in pairs(items) do
                        if item == v.name then
                              count = count + v.amount
                        end
                  end
                  return count >= amount
            elseif CurrentFramework == 'esx' then
                  return PlayerObj.getInventoryItem(item).count >= amount
            end
      end

      return false
end

---@param source number
---@param item string
---@param amount number
---@param slot? number
function Luxu.RemoveItem(source, item, amount, slot)
      local playerObj = Luxu.GetPlayerObject(source)

      if IsResourceRunning('ox_inventory') then
            exports.ox_inventory:RemoveItem(source, item, amount)
      elseif IsResourceRunning('origen_inventory') then
            exports.origen_inventory:RemoveItem(source, item, amount)
      elseif IsResourceRunning('ak47_inventory') then
            exports['ak47_inventory']:RemoveItem(source, item, amount)
      elseif IsResourceRunning('core_inventory') then
            local identifier = Luxu.GetFrameworkIdentifier(playerObj)
            local inventory = 'content-' .. identifier:gsub(":", "")
            exports['core_inventory']:removeItem(inventory, item, tonumber(amount))
      elseif IsResourceRunning('qs-inventory') then
            exports['qs-inventory']:RemoveItem(source, item, amount)
      elseif IsResourceRunning("tgiann-inventory") then
            exports["tgiann-inventory"]:RemoveItem(source, item, amount)
      elseif IsResourceRunning("codem-inventory") then
            exports["codem-inventory"]:RemoveItem(source, item, amount, slot)
      else
            if CurrentFramework == 'qb' then
                  playerObj.Functions.RemoveItem(item, amount)
            elseif CurrentFramework == 'esx' then
                  playerObj.removeInventoryItem(item, amount)
            end
      end
end

function Luxu.SetPlayerJob(id, job, grade)
      local PlayerObj = type(id) == 'number' and Luxu.GetPlayerObject(id) or id
      if not PlayerObj then return end
      if CurrentFramework == 'qb' then
            PlayerObj.Functions.SetJob(job, grade)
      elseif CurrentFramework == 'esx' then
            if not ESX.DoesJobExist(job, grade) then return end
            PlayerObj.setJob(job, grade)
      end
      return true
end

function Luxu.ToggleJobDuty(id, mode)
      local PlayerObj = type(id) == 'number' and Luxu.GetPlayerObject(id) or id
      if not PlayerObj then return end
      if CurrentFramework == 'qb' then
            Player.Functions.SetJobDuty(mode)
      elseif CurrentFramework == 'esx' then
            --[[ Unknown ]]
      end
end

function Luxu.GetVehicleList()
      if CurrentFramework == 'qb' then
            local vehs = require '@qb-core.shared.vehicles'
            local l = {}
            for k, v in pairs(vehs) do
                  l[#l + 1] = { name = v.name, model = v.model, category = v.category }
            end
            return l
      elseif CurrentFramework == 'esx' then
            local result = MySQL.await.fetchAll('SELECT name,model,category FROM vehicles')
            return result
      end
end

---@diagnostic disable-next-line:duplicate-set-field
function Luxu.DeleteVehicle(vehicle)
      if not DoesEntityExist(vehicle) then return end
      if IsResourceRunning('cd_garage') then
            local plate = Luxu.GetVehiclePlate(vehicle)
            TriggerEvent('cd_garage:RemovePersistentVehicles', plate)
      end
      if IsResourceRunning('jg-advancedgarages') then
            TriggerEvent('jg-advancedgarages:server:DeleteVehicleEntity', vehicle)
      end
      DeleteEntity(vehicle)
end
