CapsuleDui = {}
ScootUI = {
  visible = false,
}

local duiHandles = {}
local menuCam = nil
local openStationId = nil
local openingMenu = false
local actionBusy = false
local resourceName = GetCurrentResourceName()
local lastFlowColor = nil
local lastFlowAnimation = nil
local txdName = ("capsule_dui_%d"):format(GetGameTimer())
local duiReady = false
local ensuring = false
local config = ScootConfig

function sendDuiMessage(kind, payload)
  local handle = duiHandles[kind]
  if handle and IsDuiAvailable(handle) then
    SendDuiMessage(handle, json.encode(payload))
  end
end

function CapsuleDui.apply()
  for _, dict in ipairs({ "ninelabs_capsule_booth", "ninelabs_capsule_tablet" }) do
    if duiHandles.service then
      AddReplaceTexture(dict, "ninelabs_dui_service", txdName, "service")
    end
    if duiHandles.header then
      AddReplaceTexture(dict, "ninelabs_dui_header", txdName, "header")
    end
    if duiHandles.flow then
      AddReplaceTexture(dict, "ninelabs_flow", txdName, "flow")
    end
  end

  for _, dict in ipairs({ "ninelabs_capsule_base_left", "ninelabs_capsule_base_right" }) do
    if duiHandles.flow then
      AddReplaceTexture(dict, "ninelabs_flow", txdName, "flow")
    end
  end

  for side in pairs(Capsule.contract.variants) do
    local variant = Capsule.variant(side)
    if duiHandles.service then
      AddReplaceTexture(variant.duiTextureDictionary, "ninelabs_dui_service", txdName, "service")
    end
    if duiHandles.header then
      AddReplaceTexture(variant.duiTextureDictionary, "ninelabs_dui_header", txdName, "header")
    end
    if duiHandles.flow then
      for _, dict in ipairs(variant.flowTextureDictionaries) do
        AddReplaceTexture(dict, "ninelabs_flow", txdName, "flow")
      end
    end
  end
end

function CapsuleDui.color(accent)
  if not duiHandles.flow or not IsDuiAvailable(duiHandles.flow) then
    return
  end

  if accent == lastFlowColor and config.display.animation == lastFlowAnimation then
    return
  end

  lastFlowColor = accent
  lastFlowAnimation = config.display.animation
  sendDuiMessage("flow", {
    action = "config",
    display = {
      accent = accent,
      animation = lastFlowAnimation,
    },
  })
end

function CapsuleDui.busy(stationId, busy)
  if ScootUI.visible and openStationId == stationId then
    sendDuiMessage("service", {
      action = "busy",
      busy = busy,
    })
  end
end

function ScootUI.close()
  ScootUI.visible = false
  openStationId = nil

  sendDuiMessage("service", {
    action = "idle",
    display = config.display,
  })
  SendNUIMessage({
    action = "duiInput",
    enabled = false,
  })
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)

  if menuCam then
    RenderScriptCams(false, true, 250, true, true)
    DestroyCam(menuCam, false)
    menuCam = nil
  end
end

function screenOffsets(entry)
  return Capsule.screen(entry)
end

function ScootUI.open(stationId)
  if ScootUI.visible or openingMenu or ScootPlacement.active then
    return
  end

  if not duiReady then
    CapsuleDui.ensure()
    ScootRuntime.notify({
      description = ScootT("working"),
      type = "inform",
    })
    return
  end

  openingMenu = true
  local ok, result = pcall(ScootRuntime.callback.await, "capsulerent:menu", false, stationId)
  openingMenu = false

  if not ok or not result or not result.ok then
    ScootBunker.notify((result and result.error) or ScootT("connection_error"))
    return
  end

  local bunker = ScootBunker.list[stationId]
  if not bunker then
    return
  end

  ScootUI.visible = true
  openStationId = stationId

  local sx, sy, sz = screenOffsets(bunker.entry)
  local frame = Capsule.terminalFrame(bunker.entry)
  local camPos = Capsule.world(frame, sx, sy + config.tablet.cameraDistance, sz)
  local lookAt = Capsule.world(frame, sx, sy, sz)

  menuCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  SetCamCoord(menuCam, camPos.x, camPos.y, camPos.z)
  PointCamAtCoord(menuCam, lookAt.x, lookAt.y, lookAt.z)
  SetCamFov(menuCam, config.tablet.cameraFov)
  RenderScriptCams(true, true, 800, true, true)

  sendDuiMessage("service", {
    action = "menu",
    data = result,
    display = config.display,
    currency = config.ui.currency,
  })
  SendNUIMessage({
    action = "duiInput",
    enabled = true,
  })
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(true)
end

RegisterNUICallback("duiPointer", function(data, cb)
  local bunker = openStationId and ScootBunker.list[openStationId]
  if not ScootUI.visible or not bunker
    or type(data.x) ~= "number"
    or type(data.y) ~= "number"
  then
    cb({ ok = false })
    return
  end

  local sx, sy, sz = screenOffsets(bunker.entry)
  local frame = Capsule.terminalFrame(bunker.entry)
  local topLeft = Capsule.world(frame, sx + 0.25, sy, sz + 0.4)
  local bottomRight = Capsule.world(frame, sx - 0.25, sy, sz - 0.4)

  local okA, ax, ay = GetScreenCoordFromWorldCoord(topLeft.x, topLeft.y, topLeft.z)
  local okB, bx, by = GetScreenCoordFromWorldCoord(bottomRight.x, bottomRight.y, bottomRight.z)

  if okA and okB and ax < bx and ay < by then
    local nx = (data.x - ax) / (bx - ax)
    local ny = (data.y - ay) / (by - ay)

    if nx >= 0 and nx <= 1 and ny >= 0 and ny <= 1 then
      SendDuiMouseMove(duiHandles.service, math.floor(nx * 799), math.floor(ny * 1279))

      if data.event == "down" then
        SendDuiMouseDown(duiHandles.service, "left")
      elseif data.event == "up" then
        SendDuiMouseUp(duiHandles.service, "left")
      elseif data.event == "wheel" then
        local wheel = data.delta > 0 and -120 or 120
        SendDuiMouseWheel(duiHandles.service, wheel, 0)
      end
    elseif data.event == "up" then
      SendDuiMouseUp(duiHandles.service, "left")
    end
  end

  cb({ ok = true })
end)

RegisterNUICallback("duiAction", function(data, cb)
  if not ScootUI.visible or not openStationId or actionBusy or type(data) ~= "table" then
    cb({ ok = false })
    return
  end

  if data.action == "close" then
    ScootUI.close()
    cb({ ok = true })
    return
  end

  local allowed = {
    rent = true,
    recover = true,
    returnRental = true,
    cancelRental = true,
  }
  if not allowed[data.action] then
    cb({ ok = false })
    return
  end

  actionBusy = true
  local stationId = openStationId
  local payload = stationId
  if data.action == "rent" then
    payload = {
      id = stationId,
      vehicle = data.vehicle,
      plan = data.plan,
      account = data.account,
    }
  end

  local ok, result = pcall(
    ScootRuntime.callback.await,
    "capsulerent:" .. data.action,
    false,
    payload
  )
  actionBusy = false

  if not ok or not result then
    result = {
      ok = false,
      error = ScootT("connection_error"),
    }
  end

  cb(result)

  if result.ok then
    ScootUI.close()
    if data.action == "cancelRental" then
      ScootRuntime.notify({
        description = ScootT("returned"),
        type = "success",
      })
    else
      local tipKey = data.action == "returnRental" and "return_drive_hint" or "delivering"
      ScootRuntime.notify({
        description = ScootT(tipKey),
        type = "success",
      })
    end
  end
end)

RegisterNUICallback("duiReady", function(data, cb)
  cb({ ok = true })

  if data.kind == "header" or data.kind == "flow" then
    sendDuiMessage(data.kind, {
      action = "config",
      display = config.display,
    })
  elseif data.kind == "service" then
    sendDuiMessage(data.kind, {
      action = "idle",
      display = config.display,
    })
  end
end)

RegisterNUICallback("close", function(_, cb)
  -- Respond before clearing NUI focus or the fetch never resolves in CEF.
  cb({ ok = true })
  if ScootPlacement.active then
    ScootPlacement.close()
  else
    ScootUI.close()
  end
end)

function CapsuleDui.ready()
  return duiReady
end

function CapsuleDui.ensure()
  if duiReady then
    CapsuleDui.apply()
    return
  end
  if ensuring then
    return
  end

  ensuring = true
  CreateThread(function()
    local txd = CreateRuntimeTxd(txdName)
    local pages = {
      { "header", 2048, 512 },
      { "service", 800, 1280 },
      { "flow", 512, 64 },
    }

    for _, page in ipairs(pages) do
      local kind = page[1]
      local url = ("https://cfx-nui-%s/web/dui.html?kind=%s&resource=%s"):format(
        resourceName,
        kind,
        resourceName
      )
      duiHandles[kind] = CreateDui(url, page[2], page[3])

      local deadline = GetGameTimer() + 15000
      while true do
        if IsDuiAvailable(duiHandles[kind]) then
          break
        end
        if GetGameTimer() >= deadline then
          break
        end
        Wait(50)
      end

      if not IsDuiAvailable(duiHandles[kind]) then
        print("[capsulerent] tablet display page did not load: " .. kind)
        DestroyDui(duiHandles[kind])
        duiHandles[kind] = nil
        ensuring = false
        return
      end

      CreateRuntimeTextureFromDuiHandle(txd, kind, GetDuiHandle(duiHandles[kind]))
    end

    duiReady = true
    ensuring = false
    CapsuleDui.apply()

    Wait(1500)
    sendDuiMessage("header", {
      action = "config",
      display = config.display,
    })
    sendDuiMessage("flow", {
      action = "config",
      display = config.display,
    })
    lastFlowColor = nil
    lastFlowAnimation = nil
    sendDuiMessage("service", {
      action = "idle",
      display = config.display,
    })
  end)
end

CreateThread(function()
  while true do
    if ScootUI.visible then
      SetEntityLocallyInvisible(ScootCache.ped)
      DisableAllControlActions(0)

      if IsDisabledControlJustReleased(0, 200) then
        ScootUI.close()
      end

      local bunker = openStationId and ScootBunker.list[openStationId]
      local shouldClose = not bunker
        or IsEntityDead(ScootCache.ped)
        or #(GetEntityCoords(ScootCache.ped) - Capsule.service(bunker.entry)) > (config.interactDistance + 1)

      if shouldClose then
        ScootUI.close()
      end
    end

    Wait(ScootUI.visible and 0 or 500)
  end
end)

AddEventHandler("onResourceStop", function(stopped)
  if stopped ~= resourceName then
    return
  end

  ScootUI.close()

  for _, dict in ipairs({
    "ninelabs_capsule_booth",
    "ninelabs_capsule_tablet",
    "ninelabs_capsule_base_left",
    "ninelabs_capsule_base_right",
  }) do
    for _, tex in ipairs({ "ninelabs_dui_service", "ninelabs_dui_header", "ninelabs_flow" }) do
      RemoveReplaceTexture(dict, tex)
    end
  end

  for _, variant in pairs(Capsule.contract.variants) do
    RemoveReplaceTexture(variant.duiTextureDictionary, "ninelabs_dui_service")
    RemoveReplaceTexture(variant.duiTextureDictionary, "ninelabs_dui_header")
    for _, dict in ipairs(variant.flowTextureDictionaries) do
      RemoveReplaceTexture(dict, "ninelabs_flow")
    end
  end

  for _, handle in pairs(duiHandles) do
    DestroyDui(handle)
  end
end)
