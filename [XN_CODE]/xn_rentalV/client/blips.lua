local config = ScootConfig
local ScootBlipsApi = {}
local activeBlips = {}

function resolveBlipOptions(station)
  local defaults = config.blips or {}
  local override = station.blip or {}

  local enabled = override.enabled
  if enabled == false then
    return nil
  end
  if defaults.enabled == false and enabled ~= true then
    return nil
  end

  local sprite = math.floor(tonumber(override.sprite) or defaults.sprite or 1)
  local color = math.floor(tonumber(override.color) or defaults.color or 3)
  local scale = math.max(0.1, math.min(2.0, tonumber(override.scale) or defaults.scale or 0.75))

  local shortRange = override.shortRange or defaults.shortRange
  local flash = override.flash or defaults.flash
  local flashInterval = math.max(100, math.floor(tonumber(override.flashInterval) or defaults.flashInterval or 500))

  local label
  if override.label ~= nil and override.label ~= "" then
    label = override.label
  else
    label = station.name or defaults.label or "ALLGAMERS"
  end

  return {
    sprite = sprite,
    color = color,
    scale = scale,
    shortRange = shortRange,
    flash = flash,
    flashInterval = flashInterval,
    label = label,
  }
end

function ScootBlipsApi.set(id, station)
  ScootBlipsApi.remove(id)

  local options = resolveBlipOptions(station)
  if not options then
    return
  end

  local coords = station.coords
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, options.sprite)
  SetBlipColour(blip, options.color)
  SetBlipScale(blip, options.scale + 0.0)
  SetBlipAsShortRange(blip, options.shortRange == true)
  SetBlipFlashes(blip, options.flash == true)
  if options.flash then
    SetBlipFlashInterval(blip, options.flashInterval)
  end

  BeginTextCommandSetBlipName("STRING")
  AddTextComponentSubstringPlayerName(options.label)
  EndTextCommandSetBlipName(blip)

  activeBlips[id] = blip
end

function ScootBlipsApi.remove(id)
  local blip = activeBlips[id]
  if blip and DoesBlipExist(blip) then
    RemoveBlip(blip)
  end
  activeBlips[id] = nil
end

function ScootBlipsApi.refresh(stations)
  for id in pairs(activeBlips) do
    if not stations[id] then
      ScootBlipsApi.remove(id)
    end
  end

  for id, station in pairs(stations) do
    ScootBlipsApi.set(id, station)
  end
end

function ScootBlipsApi.clear()
  for id in pairs(activeBlips) do
    ScootBlipsApi.remove(id)
  end
end

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == ScootCache.resource then
    ScootBlipsApi.clear()
  end
end)

ScootBlips = ScootBlipsApi
