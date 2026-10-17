eventName = "bablo-chopshop:"

Locales = Locales or {}
Locale = Locale or {}
Target = Target or {}
Inventory = Inventory or {}
Framework = Framework or {}

local function initializeVehicles()
  local qbVehicles = nil
  if GetResourceState('qbx_core') == 'started' then
    local success, result = pcall(function()
      return exports.qbx_core:GetVehiclesByName()
    end)
    if success then
      qbVehicles = result
    end
  elseif GetResourceState('qb-core') == 'started' then
    local QBCore = exports['qb-core']:GetCoreObject()
    if QBCore and QBCore.Shared and QBCore.Shared.Vehicles then
      qbVehicles = QBCore.Shared.Vehicles
    end
  end

  if qbVehicles then
    local fetchedHashes = {}
    for model, vehicleData in pairs(qbVehicles) do
      local hash = vehicleData.hash
      if not hash or hash == 0 then
        hash = GetHashKey(model)
      end
      table.insert(fetchedHashes, {
        class = vehicleData.category or "Unknown",
        hash = hash,
        spawnName = model,
        displayName = vehicleData.name or model
      })
    end
    Config.VehicleHashes = fetchedHashes
  end

  local vehicleHashes = {}
  local vehicleSpawnNames = {}

  for _, vehicleData in ipairs(Config.VehicleHashes or {}) do
    if vehicleData.hash then
      vehicleHashes[tostring(vehicleData.hash)] = vehicleData
    end

    if vehicleData.spawnName then
      vehicleSpawnNames[vehicleData.spawnName:lower()] = vehicleData
    end
  end

  Config.VehicleHashes = vehicleHashes
  Config.VehicleSpawnNames = vehicleSpawnNames

  local localeCode = Config.Locale or "en-US"
  Locale.t = Locales[localeCode] or Locales["en-US"] or {}
end

initializeVehicles()

function NormalizeVehicleModel(model)
  if type(model) ~= "string" then
    return model
  end

  local modelName = model:lower()
  local alias = Config.VehicleModelAliases and Config.VehicleModelAliases[modelName]

  return alias or modelName
end

function Locale:Get(key)
  if self.t and self.t[key] then
    return self.t[key]
  end

  return key
end
