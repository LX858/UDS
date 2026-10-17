local scaleform = RequestScaleformMovie("DIGISCANNER")
local inScaleform = false
local currentWait = 1000
local activeSearch = nil
local targetCoords = vector3(0, 0, 0)
local searchRadiusBlip = nil
local searchCenterBlip = nil
local dropoffBlip = nil

local sfcolors = {
  red = { r = 255, g = 10, b = 10 },
  yellow = { r = 255, g = 209, b = 67 },
  lightblue = { r = 67, g = 200, b = 255 },
  green = { r = 0, g = 255, b = 80 }
}

local sfbars = {
  { dist = 500, bars = 30.0, wait = 7000 },
  { dist = 400, bars = 40.0, wait = 6000 },
  { dist = 300, bars = 50.0, wait = 5000 },
  { dist = 150, bars = 60.0, wait = 4000 },
  { dist = 80,  bars = 70.0, wait = 3000 },
  { dist = 40,  bars = 80.0, wait = 2000 },
  { dist = 10,  bars = 90.0, wait = 1000 },
  { dist = 0,   bars = 100.0, wait = 500 },
}

local sfpos = {
  x = 0.1,
  y = 0.24,
  width = 0.21,
  height = 0.51,
}

local function ScaleformMethod(sf, name, data)
  BeginScaleformMovieMethod(sf, name)
  for _, v in ipairs(data or {}) do
    if name == "SET_DISTANCE" then
      PushScaleformMovieMethodParameterFloat(v + 0.0)
    else
      PushScaleformMovieMethodParameterInt(v)
    end
  end
  PopScaleformMovieFunctionVoid()
end

local function SetScaleformColor(bar, dot)
  if not scaleform then return end
  ScaleformMethod(scaleform, "SET_COLOUR", { bar.r, bar.g, bar.b, dot.r, dot.g, dot.b })
end

local function Flashing(enable)
  if not scaleform then return end
  if enable then
    ScaleformMethod(scaleform, "flashOn")
  else
    ScaleformMethod(scaleform, "flashOff")
  end
end

local function HeadingCheck(playerCoords, playerHeading, target)
  local x = target.x - playerCoords.x
  local y = target.y - playerCoords.y
  local targetHeading = GetHeadingFromVector_2d(x, y)
  local diff = math.abs(playerHeading - targetHeading)
  if diff > 180.0 then
    diff = 360.0 - diff
  end
  return diff < 30.0
end

local function UpdateBars(dist)
  if not scaleform then return end
  for i = 1, #sfbars do
    if dist > sfbars[i].dist then
      currentWait = sfbars[i].wait
      ScaleformMethod(scaleform, "SET_DISTANCE", { sfbars[i].bars })
      break
    end
  end
end

local function DeleteSearchBlips()
  if searchRadiusBlip and DoesBlipExist(searchRadiusBlip) then
    RemoveBlip(searchRadiusBlip)
    searchRadiusBlip = nil
  end
  if searchCenterBlip and DoesBlipExist(searchCenterBlip) then
    RemoveBlip(searchCenterBlip)
    searchCenterBlip = nil
  end
end

local function DeleteDropoffBlip()
  if dropoffBlip and DoesBlipExist(dropoffBlip) then
    RemoveBlip(dropoffBlip)
    dropoffBlip = nil
  end
end

local function GetNearestChopShopDropoff()
  local ped = PlayerPedId()
  local pCoords = GetEntityCoords(ped)
  local nearestCoords = nil
  local nearestDist = 999999.0

  for _, chopShop in pairs(Config.ChopShops or {}) do
    if chopShop.dropOff then
      local d = #(pCoords - vector3(chopShop.dropOff.x, chopShop.dropOff.y, chopShop.dropOff.z))
      if d < nearestDist then
        nearestDist = d
        nearestCoords = chopShop.dropOff
      end
    end
  end

  return nearestCoords or vector3(-440.42, -1693.49, 19.22)
end

local function CreateDropoffBlip(dropOffCoords)
  DeleteDropoffBlip()
  dropoffBlip = AddBlipForCoord(dropOffCoords.x, dropOffCoords.y, dropOffCoords.z)
  SetBlipSprite(dropoffBlip, 380)
  SetBlipColour(dropoffBlip, 2)
  SetBlipScale(dropoffBlip, 0.9)
  SetBlipRoute(dropoffBlip, true)
  SetBlipRouteColour(dropoffBlip, 2)
  SetBlipAsShortRange(dropoffBlip, false)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(Translate("DROPOFF_BLIP"))
  EndTextCommandSetBlipName(dropoffBlip)

  SetNewWaypoint(dropOffCoords.x, dropOffCoords.y)
end

local function TriggerPoliceAlert()
  if PoliceCall then
    PoliceCall()
  elseif Main and Main.PoliceCall then
    Main:PoliceCall()
  else
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    if GetResourceState('ld-dispatch') == 'started' then
      exports['ld-dispatch']:sendDispatch({
        title = "Rã Xe",
        code = "11-10B",
        values = {
          { text = "RÃ XE", icon = "fa-solid fa-earth-americas" },
          { text = "2 sao", icon = "fa-solid fa-hashtag" },
        },
        valuestwo = {},
        jobs = { "police" },
        active = false,
        dispatchnumber = nil,
        coords = plyCoords,
        blip = { blipid = 562, blipcolor = 1 }
      })
    end
  end
end

local function OnVehicleFound()
  if not activeSearch or activeSearch.found then
    return
  end

  activeSearch.found = true
  inScaleform = false

  DeleteSearchBlips()

  local vehicleEntity = nil
  if activeSearch.netId and activeSearch.netId ~= 0 then
    vehicleEntity = NetworkGetEntityFromNetworkId(activeSearch.netId)
  end

  if vehicleEntity and DoesEntityExist(vehicleEntity) then
    SetVehicleDoorsLocked(vehicleEntity, 0)
    SetVehicleDoorsLockedForAllPlayers(vehicleEntity, false)
  end

  PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)
  Framework:Notify(Translate("VEHICLE_FOUND"), 6000, "success")

  local dropoff = GetNearestChopShopDropoff()
  CreateDropoffBlip(dropoff)

  if Config.PoliceAlertOnFound then
    TriggerPoliceAlert()
  end

  TriggerServerEvent(eventName .. "server:vehicleFound", activeSearch.netId)
end

-- Setup scaleform and rendertarget immediately on load
Citizen.CreateThread(function()
  while not HasScaleformMovieLoaded(scaleform) do
    Citizen.Wait(0)
  end

  if not IsNamedRendertargetRegistered('digiscanner') then
    RegisterNamedRendertarget('digiscanner', 0)
  end

  local weapModel = GetWeapontypeModel(joaat('weapon_digiscanner'))
  if weapModel ~= 0 and not IsNamedRendertargetLinked(weapModel) then
    LinkNamedRendertarget(weapModel)
  end
  if not IsNamedRendertargetLinked(joaat('w_am_digiscanner')) then
    LinkNamedRendertarget(joaat('w_am_digiscanner'))
  end
  if not IsNamedRendertargetLinked(joaat('prop_digiscanner_01')) then
    LinkNamedRendertarget(joaat('prop_digiscanner_01'))
  end
end)

local function InitiateDigiScanner()
  local ped = PlayerPedId()
  if not inScaleform then
    inScaleform = true
    local data = 0
    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    local dist = #(playerCoords - targetCoords)

    if HeadingCheck(playerCoords, playerHeading, targetCoords) then
      SetScaleformColor(sfcolors.lightblue, sfcolors.yellow)
    else
      SetScaleformColor(sfcolors.red, sfcolors.red)
    end

    UpdateBars(dist)

    if not IsNamedRendertargetRegistered('digiscanner') then
      RegisterNamedRendertarget('digiscanner', 0)
    end

    local weapModel = GetWeapontypeModel(joaat('weapon_digiscanner'))
    if weapModel ~= 0 and not IsNamedRendertargetLinked(weapModel) then
      LinkNamedRendertarget(weapModel)
    end
    if not IsNamedRendertargetLinked(joaat('w_am_digiscanner')) then
      LinkNamedRendertarget(joaat('w_am_digiscanner'))
    end
    if not IsNamedRendertargetLinked(joaat('prop_digiscanner_01')) then
      LinkNamedRendertarget(joaat('prop_digiscanner_01'))
    end

    if IsNamedRendertargetRegistered('digiscanner') then
      data = GetNamedRendertargetRenderId('digiscanner')
    end

    Citizen.CreateThread(function()
      while inScaleform do
        if data == 0 or not data then
          data = GetNamedRendertargetRenderId('digiscanner')
        end

        SetTextRenderId(data)
        DrawScaleformMovie(scaleform, sfpos.x, sfpos.y, sfpos.width, sfpos.height, 100, 100, 100, 255, 0)
        SetTextRenderId(1)

        if IsPlayerFreeAiming(PlayerId()) or IsControlPressed(0, 25) then
          local pCoords = GetEntityCoords(PlayerPedId())
          local pHeading = GetEntityHeading(PlayerPedId())

          if HeadingCheck(pCoords, pHeading, targetCoords) then
            SetScaleformColor(sfcolors.lightblue, sfcolors.yellow)
          else
            SetScaleformColor(sfcolors.red, sfcolors.red)
          end

          local curDist = #(pCoords - targetCoords)
          if curDist < 4.0 then
            SetScaleformColor(sfcolors.green, sfcolors.green)
            Flashing(true)
            ScaleformMethod(scaleform, "SET_DISTANCE", { 100.0 })
            currentWait = 250
          else
            Flashing(false)
            UpdateBars(curDist)
          end
        end

        if inScaleform == false then
          break
        end

        Citizen.Wait(1)
      end
    end)
  end
end

-- Idle / Fallback draw thread for weapon_digiscanner when in hand but not in mission
Citizen.CreateThread(function()
  while true do
    local sleep = 500
    local ped = PlayerPedId()

    if GetSelectedPedWeapon(ped) == joaat('weapon_digiscanner') and not inScaleform then
      sleep = 0
      local data = 0
      if IsNamedRendertargetRegistered('digiscanner') then
        data = GetNamedRendertargetRenderId('digiscanner')
      end

      if data ~= 0 and scaleform and HasScaleformMovieLoaded(scaleform) then
        SetScaleformColor(sfcolors.red, sfcolors.red)
        ScaleformMethod(scaleform, "SET_DISTANCE", { 10.0 })
        SetTextRenderId(data)
        DrawScaleformMovie(scaleform, sfpos.x, sfpos.y, sfpos.width, sfpos.height, 100, 100, 100, 255, 0)
        SetTextRenderId(1)
      end
    end

    Citizen.Wait(sleep)
  end
end)

function StartVehicleSearch(data)
  if not data or not data.coords then
    return
  end

  DeleteSearchBlips()
  DeleteDropoffBlip()

  local coords = vector3(data.coords.x, data.coords.y, data.coords.z)
  local radar = data.radarCoords and vector3(data.radarCoords.x, data.radarCoords.y, data.radarCoords.z) or coords

  targetCoords = radar

  activeSearch = {
    coords = coords,
    radarCoords = radar,
    netId = data.netId,
    model = data.model,
    plate = data.plate,
    found = false,
  }

  local radius = Config.SearchRadius or 140.0
  -- Đảm bảo tâm vòng tròn bị lệch ngẫu nhiên so với xe (từ 40% đến 75% bán kính)
  local minOffset = math.floor(radius * 0.40)
  local maxOffset = math.floor(radius * 0.75)
  local offsetDist = math.random(minOffset, maxOffset) + (math.random(0, 99) / 100)
  local offsetAngle = math.rad(math.random(0, 360))

  -- Tọa độ tâm vùng tròn (lệch ngẫu nhiên cả trục X và Y)
  local blipX = coords.x + (math.cos(offsetAngle) * offsetDist)
  local blipY = coords.y + (math.sin(offsetAngle) * offsetDist)

  -- Chỉ hiển thị duy nhất vùng khoanh tròn màu Cam, không có icon tâm chỉ điểm
  searchRadiusBlip = AddBlipForRadius(blipX, blipY, coords.z, radius)
  SetBlipSprite(searchRadiusBlip, 9)
  SetBlipColour(searchRadiusBlip, 47) -- Màu cam (Orange)
  SetBlipAlpha(searchRadiusBlip, 120)
  SetBlipAsShortRange(searchRadiusBlip, false)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(Translate("SEARCH_ZONE_BLIP"))
  EndTextCommandSetBlipName(searchRadiusBlip)

  -- Đặt GPS điều hướng tới khu vực khoanh vùng
  SetNewWaypoint(blipX, blipY)

  Framework:Notify(Translate("SEARCH_ZONE_NOTIFY"), 8000, "info")


  InitiateDigiScanner()
end


function StopVehicleSearch()
  activeSearch = nil
  inScaleform = false
  DeleteSearchBlips()
  DeleteDropoffBlip()
end

-- Thread for scanner audio beep
Citizen.CreateThread(function()
  while true do
    local sleep = 1000
    local ped = PlayerPedId()

    if inScaleform and GetSelectedPedWeapon(ped) == joaat('weapon_digiscanner') then
      if IsPlayerFreeAiming(PlayerId()) or IsControlPressed(0, 25) then
        local c = GetEntityCoords(ped)
        PlaySoundFromCoord(-1, "IDLE_BEEP", c.x, c.y, c.z, 'EPSILONISM_04_SOUNDSET', true, 5.0, false)
        sleep = currentWait or 1000
      else
        sleep = 250
      end
    else
      sleep = 1000
    end

    Citizen.Wait(sleep)
  end
end)

-- Thread for detecting when player reaches the vehicle
Citizen.CreateThread(function()
  while true do
    local sleep = 500

    if activeSearch and not activeSearch.found then
      sleep = 200
      local ped = PlayerPedId()
      local pCoords = GetEntityCoords(ped)
      local dist = #(pCoords - activeSearch.coords)

      if dist <= 5.0 then
        OnVehicleFound()
      elseif IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and DoesEntityExist(veh) then
          local vehCoords = GetEntityCoords(veh)
          if #(vehCoords - activeSearch.coords) < 15.0 or (activeSearch.netId and NetworkGetNetworkIdFromEntity(veh) == activeSearch.netId) then
            OnVehicleFound()
          end
        end
      end
    end

    Citizen.Wait(sleep)
  end
end)

function GetActiveSearchModel()
  if activeSearch and not activeSearch.found then
    return activeSearch.model
  end
  return nil
end

RegisterNetEvent(eventName .. "client:startVehicleSearch", function(data)
  StartVehicleSearch(data)
end)

RegisterNetEvent(eventName .. "client:stopVehicleSearch", function()
  StopVehicleSearch()
end)

exports('SetupDigiScanner', function(v3, params)
  targetCoords = v3
  InitiateDigiScanner()
end)
exports('StartVehicleSearch', StartVehicleSearch)
exports('StopVehicleSearch', StopVehicleSearch)
exports('GetActiveSearchModel', GetActiveSearchModel)

