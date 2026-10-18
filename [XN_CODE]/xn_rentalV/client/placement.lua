ScootPlacement = { active = false }

local config = ScootConfig
local assets = ScootAssets

local ghostObj = nil
local draft = nil
local locations = nil
local busy = false
local typingActive = false
local aimHeld = false
local opening = false
local editingId = nil
local ghost = nil
local ghostKey = nil
local pinned = false
local raised = true
local groundValid = false
local groundProbe = nil
local lastProbeAt = 0
local lastStateAt = 0
local smoothPos = nil
local smoothHeading = nil
local terminalGroundCache = nil
local stage = "capsule"
local capsuleReady = false
local terminalReady = false
local browsePage = nil

function stageTarget()
  if stage == "terminal" and draft.terminal then
    return draft.terminal
  end
  return draft
end

function ScootPlacement.groundZ(z, kind)
  local offset = 0
  if kind == "capsule" then
    offset = config.creator.capsuleGroundOffset or 0.0
  elseif kind == "booth" then
    offset = config.creator.boothGroundOffset or 0.03
  end
  return z + math.max(0, offset)
end

function ScootPlacement.supportedZ(poseZ, minZ, maxZ, kind)
  if kind == "capsule" then
    return ScootPlacement.groundZ(maxZ, "capsule")
  end
  return ScootPlacement.groundZ(minZ, kind)
end

function ScootPlacement.terrainZ(coords)
  local handle = StartExpensiveSynchronousShapeTestLosProbe(
    coords.x, coords.y, coords.z + 2.0,
    coords.x, coords.y, coords.z - 10.0,
    1, ScootCache.ped, 7
  )
  local status, hit, hitPos = GetShapeTestResult(handle)
  if status == 2 and (hit == 1 or hit == true) then
    return hitPos.z
  end
end

function ensureDefaultTerminal()
  local terminal = Capsule.defaultTerminal(draft)
  local coords = terminal.coords
  if not (
    terminalGroundCache
    and terminalGroundCache.x == coords.x
    and terminalGroundCache.y == coords.y
    and terminalGroundCache.z == coords.z
  ) then
    terminalGroundCache = {
      x = coords.x,
      y = coords.y,
      z = coords.z,
      ground = ScootPlacement.terrainZ(coords),
    }
  end

  local ground = terminalGroundCache.ground
  if not ground then
    ground = draft.coords.z - math.max(0, config.creator.capsuleGroundOffset or 0.0)
  end
  terminal.coords.z = ScootPlacement.groundZ(ground, draft.version)
  return terminal
end

function ScootPlacement.previewPose(entry, poseStage, override, termReady)
  local pose = {}
  if poseStage == "capsule" and override.coords then
    pose.coords = override.coords
  else
    pose.coords = entry.coords
  end
  if poseStage == "capsule" and override.heading then
    pose.heading = override.heading
  else
    pose.heading = entry.heading
  end
  pose.side = entry.side
  pose.version = entry.version
  if poseStage == "terminal" and override then
    pose.terminal = override
  else
    pose.terminal = entry.terminal
  end
  pose.previewCapsuleOnly = poseStage == "capsule"
  if poseStage == "capsule" and not termReady then
    pose.terminal = Capsule.defaultTerminal(pose)
    pose.terminal.coords.z = entry.terminal.coords.z
  end
  return pose
end

function setStage(newStage)
  stage = newStage
  local flag
  if stage == "capsule" and capsuleReady then
    flag = capsuleReady
  else
    flag = terminalReady
  end
  pinned = flag
  groundValid = flag
  groundProbe = nil
  smoothPos = nil
  smoothHeading = nil
end

function refreshBrowseBlips()
  for i = 1, 12 do
    ScootBlips.remove("__scoot_browse_" .. i)
  end
  if not browsePage or not draft then
    return
  end

  local startSprite = (browsePage - 1) * 12 + 1
  local origin = draft.coords
  local rad = math.rad((draft.heading or 0.0) + 90.0)
  local dirX = -math.sin(rad)
  local dirY = math.cos(rad)

  for i = 1, 12 do
    local sprite = startSprite + i - 1
    if sprite <= 826 then
      local blipCfg = draft.blip or {}
      ScootBlips.set("__scoot_browse_" .. i, {
        coords = {
          x = origin.x + dirX * i * 6.0,
          y = origin.y + dirY * i * 6.0,
          z = origin.z,
        },
        blip = {
          sprite = sprite,
          color = blipCfg.color or 3,
          scale = 0.9,
          shortRange = false,
          label = ("#%d"):format(sprite),
        },
      })
    end
  end
end

function refreshDraftBlip()
  if not draft then
    ScootBlips.remove("__scoot_draft")
    return
  end
  local blipCfg = draft.blip or {}
  if blipCfg.enabled == false then
    ScootBlips.remove("__scoot_draft")
    return
  end
  ScootBlips.set("__scoot_draft", {
    coords = draft.coords,
    name = draft.name,
    blip = blipCfg,
  })
end

function pushCreatorState()
  if not draft then
    return
  end
  if stage == "capsule" and not terminalReady then
    draft.terminal = ensureDefaultTerminal()
  end
  refreshDraftBlip()
  SendNUIMessage({
    action = "creatorState",
    draft = draft,
    pinned = pinned,
    raised = raised,
    groundValid = groundValid,
    browsePage = browsePage,
    stage = stage,
    capsuleReady = capsuleReady,
    terminalReady = terminalReady,
  })
end

function ScootPlacement.close()
  ScootPlacement.active = false
  SendNUIMessage({ action = "closeCreator" })
  if ghost then
    ScootBunker.destroy(ghost)
  end
  ghost = nil
  ghostKey = nil
  if editingId and ScootBunker.list[editingId] then
    ScootBunker.hide(editingId, false)
  end
  ScootBlips.remove("__scoot_draft")
  browsePage = nil
  refreshBrowseBlips()
  groundProbe = nil
  editingId = nil
  draft = nil
  ghostObj = nil
  terminalGroundCache = nil
  busy = false
  typingActive = false
  aimHeld = false
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
end

function loadDraft(existing)
  terminalGroundCache = nil
  groundProbe = nil
  if editingId and ScootBunker.list[editingId] then
    ScootBunker.hide(editingId, false)
  end
  editingId = nil

  local pedCoords = GetEntityCoords(ScootCache.ped)
  local forward = GetEntityForwardVector(ScootCache.ped) * 3.0
  pedCoords = pedCoords + forward

  draft = {
    name = ScootT("new_station"),
    coords = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z },
    heading = GetEntityHeading(ScootCache.ped),
    color = ScootColor(config.glow and config.glow.color),
    blip = {},
    side = config.defaultSide,
    version = "booth",
  }
  stage = "capsule"
  capsuleReady = false
  terminalReady = false
  groundValid = false
  pinned = false

  if existing then
    draft = {
      id = existing.id,
      revision = existing.revision,
      side = existing.side or config.defaultSide,
      color = existing.color,
      blip = existing.blip or {},
      name = existing.name or ScootT("station"),
      coords = {
        x = existing.coords.x,
        y = existing.coords.y,
        z = existing.coords.z,
      },
      heading = existing.heading,
      version = existing.version or "booth",
    }
    if existing.terminal then
      draft.terminal = {
        coords = {
          x = existing.terminal.coords.x,
          y = existing.terminal.coords.y,
          z = existing.terminal.coords.z,
        },
        heading = existing.terminal.heading,
      }
    end
    capsuleReady = true
    terminalReady = true
    groundValid = true
    pinned = true
    if ScootBunker.list[existing.id] then
      editingId = existing.id
      ScootBunker.hide(existing.id, true)
    end
  end

  draft.terminal = draft.terminal or ensureDefaultTerminal()

  smoothPos = nil
  smoothHeading = nil
  pushCreatorState()
end

function teleportToStation(entry)
  local coords = entry.coords
  local rad = math.rad(entry.heading or 0.0)
  local x = coords.x - math.sin(rad) * 3.0
  local y = coords.y + math.cos(rad) * 3.0
  local ped = ScootCache.ped

  DoScreenFadeOut(200)
  while not IsScreenFadedOut() do
    Wait(0)
  end

  SetEntityCoordsNoOffset(ped, x, y, coords.z + 1.0, false, false, false)
  RequestCollisionAtCoord(x, y, coords.z)
  local deadline = GetGameTimer() + 6000
  while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
    RequestCollisionAtCoord(x, y, coords.z)
    Wait(50)
  end

  local found, groundZ = GetGroundZFor_3dCoord(x, y, coords.z + 3.0, false)
  local z = (found and groundZ) or coords.z
  SetEntityCoordsNoOffset(ped, x, y, z + 0.15, false, false, false)
  SetEntityHeading(ped, ((entry.heading or 0.0) + 180.0) % 360.0)
  smoothPos = nil
  smoothHeading = nil
  DoScreenFadeIn(300)
end

function isFiniteNumber(value)
  return type(value) == "number" and value == value
end

function saveDraft(cb)
  if not (
    ScootPlacement.active
    and not busy
    and draft
    and (pinned or groundValid)
  ) then
    if cb then
      cb({ ok = false, error = ScootT("ground_failed") })
    end
    return
  end

  if stage == "capsule" then
    if not terminalReady then
      draft.terminal = ensureDefaultTerminal()
    end
    capsuleReady = true
    setStage("terminal")
    pushCreatorState()
    if cb then
      cb({ ok = true })
    end
    return
  end

  if not capsuleReady then
    if cb then
      cb({ ok = false, error = ScootT("capsule_first") })
    end
    return
  end

  if not Capsule.terminalClear(draft) then
    local result = { ok = false, error = ScootT("terminal_clear") }
    SendNUIMessage({ action = "creatorError", error = result.error })
    if cb then
      cb(result)
    end
    return
  end

  if not pinned then
    pinned = true
    pushCreatorState()
  end

  busy = true
  local center = Capsule.variant(draft.side).capsuleCenter
  local isTablet = draft.version == "tablet"
  local probes = {
    {
      pose = draft,
      corners = {
        { center[1] - 2.3, center[2] - 3.7 },
        { center[1] + 2.3, center[2] - 3.7 },
        { center[1] - 2.3, center[2] + 3.7 },
        { center[1] + 2.3, center[2] + 3.7 },
      },
    },
    {
      pose = draft.terminal,
      corners = isTablet and {
        { -0.35, -0.28 },
        { 0.35, -0.28 },
        { -0.35, 0.28 },
        { 0.35, 0.28 },
      } or {
        { -1.6, -1.44 },
        { 1.6, -1.44 },
        { -1.6, 3.34 },
        { 1.6, 3.34 },
      },
    },
  }

  for _, probe in ipairs(probes) do
    local hits = {}
    for _, corner in ipairs(probe.corners) do
      local world = Capsule.world(probe.pose, corner[1], corner[2], 0)
      local handle = StartShapeTestRay(
        world.x, world.y, world.z + 2,
        world.x, world.y, world.z - 2,
        1, ScootCache.ped, 7
      )
      local deadline = GetGameTimer() + 1000
      local status, hit, hitPos
      repeat
        Wait(0)
        status, hit, hitPos = GetShapeTestResult(handle)
        if status ~= 1 then
          break
        end
      until GetGameTimer() > deadline
      if status == 2 and (hit == 1 or hit == true) then
        hits[#hits + 1] = hitPos.z
      end
    end

    table.sort(hits)
    if not (#hits == 4 and (hits[4] - hits[1]) <= 0.23) then
      busy = false
      local result = { ok = false, error = ScootT("flat_ground") }
      SendNUIMessage({ action = "creatorError", error = result.error })
      if cb then
        cb(result)
      end
      return
    end

    local kind = probe.pose == draft and "capsule" or draft.version
    probe.pose.coords.z = ScootPlacement.supportedZ(
      probe.pose.coords.z,
      hits[1],
      hits[4],
      kind
    )
  end

  terminalReady = true
  if not ScootPlacement.active then
    busy = false
    if cb then
      cb({ ok = false })
    end
    return
  end

  local ok, result = pcall(ScootRuntime.callback.await, "capsulerent:saveLocation", false, draft)
  busy = false
  if not ok or not result then
    result = { ok = false, error = ScootT("connection_error") }
  end
  if cb then
    cb(result)
  end
  if result.ok then
    ScootRuntime.notify({ description = ScootT("saved"), type = "success" })
    ScootPlacement.close()
  else
    SendNUIMessage({ action = "creatorError", error = result.error })
  end
end

function openCreator(stationId)
  if ScootPlacement.active or busy or opening then
    return
  end

  if GetVehiclePedIsIn(ScootCache.ped, false) ~= 0 then
    ScootBunker.notify(ScootT("exit_vehicle"))
    return
  end

  opening = true
  local ok, result = pcall(ScootRuntime.callback.await, "capsulerent:creator", false)
  if not (ok and result and result.ok) then
    opening = false
    ScootBunker.notify((result and result.error) or ScootT("connection_error"))
    return
  end

  local model = joaat(assets.model)
  local loaded = pcall(function()
    ScootRuntime.requestModel(model, 10000)
    ScootRuntime.requestAnimDict(assets.animDict, 10000)
  end)
  opening = false
  if not loaded then
    ScootBunker.notify(ScootT("model_failed"))
    return
  end

  ScootUI.close()
  locations = result.locations
  SetModelAsNoLongerNeeded(model)
  raised = true
  ScootPlacement.active = true
  SendNUIMessage({
    action = "openCreator",
    locale = ScootTranslations(),
    theme = ScootTheme(),
    locations = locations,
    presets = (config.glow or {}).presets,
    blips = config.blips,
  })

  loadDraft(stationId and locations[stationId] or nil)
  SetNuiFocus(true, true)
  -- Keep game input so Enter / arrows / Q-E still place the vault.
  -- Pause menu is blocked every frame below instead.
  SetNuiFocusKeepInput(true)
  aimHeld = false

  CreateThread(function()
    while ScootPlacement.active do
      DisablePlayerFiring(PlayerId(), true)

      -- Kill pause / ESC on every input group so the map never opens over the creator.
      for _, group in ipairs({ 0, 1, 2 }) do
        DisableControlAction(group, 199, true) -- P pause
        DisableControlAction(group, 200, true) -- ESC pause
        DisableControlAction(group, 322, true) -- ESC alt
      end
      if IsPauseMenuActive() then
        SetFrontendActive(false)
      end

      for _, control in ipairs({
        24, 25, 37, 38, 44, 140, 141, 142,
        174, 175, 172, 173, 10, 11, 191,
      }) do
        DisableControlAction(0, control, true)
      end

      if typingActive then
        DisableAllControlActions(0)
        DisableAllControlActions(1)
        DisableAllControlActions(2)
        for _, group in ipairs({ 0, 1, 2 }) do
          DisableControlAction(group, 199, true)
          DisableControlAction(group, 200, true)
          DisableControlAction(group, 322, true)
        end
        SetNuiFocusKeepInput(false)
      else
        local aiming = IsDisabledControlPressed(0, 25)
        if aiming ~= aimHeld then
          aimHeld = aiming
          SetNuiFocus(not aiming, not aiming)
          SetNuiFocusKeepInput(true)
        elseif not aimHeld then
          SetNuiFocusKeepInput(true)
        end
        if not aimHeld then
          DisableControlAction(0, 1, true)
          DisableControlAction(0, 2, true)
        end
      end

      if IsEntityDead(ScootCache.ped) then
        ScootPlacement.close()
        break
      end

      local now = GetGameTimer()
      if not pinned and not busy then
        if groundProbe then
          local status, hit, hitPos = GetShapeTestResult(groundProbe)
          if status ~= 1 then
            groundProbe = nil
            groundValid = hit == 1 or hit == true
            if groundValid then
              local target = stageTarget()
              local kind = stage == "capsule" and "capsule" or draft.version
              target.coords = {
                x = hitPos.x,
                y = hitPos.y,
                z = ScootPlacement.groundZ(hitPos.z, kind),
              }
            end
          end
        elseif now - lastProbeAt >= 60 then
          lastProbeAt = now
          local cam = GetGameplayCamCoord()
          local rot = GetGameplayCamRot(2)
          local pitch = math.rad(rot.x)
          local yaw = math.rad(rot.z)
          local dir = vec3(
            -math.sin(yaw) * math.cos(pitch),
            math.cos(yaw) * math.cos(pitch),
            math.sin(pitch)
          )
          local dest = cam + dir * config.creator.maxDistance
          groundProbe = StartShapeTestRay(
            cam.x, cam.y, cam.z,
            dest.x, dest.y, dest.z,
            1, ScootCache.ped, 7
          )
        end
      end

      if not typingActive and not busy then
        local target = stageTarget()
        local speed = math.min(GetFrameTime(), 0.05) * 60
        local precision = IsControlPressed(0, 21) and (config.creator.precisionMultiplier or 1) or 1
        local move = config.creator.moveStep * speed * precision
        local rotate = config.creator.rotateStep * speed * precision

        local moving = IsDisabledControlPressed(0, 174)
          or IsDisabledControlPressed(0, 175)
          or IsDisabledControlPressed(0, 172)
          or IsDisabledControlPressed(0, 173)
          or IsDisabledControlPressed(0, 10)
          or IsDisabledControlPressed(0, 11)

        if moving and not pinned and groundValid then
          pinned = true
          pushCreatorState()
        end

        if pinned then
          if IsDisabledControlPressed(0, 174) then
            target.coords.x = target.coords.x - move
          end
          if IsDisabledControlPressed(0, 175) then
            target.coords.x = target.coords.x + move
          end
          if IsDisabledControlPressed(0, 172) then
            target.coords.y = target.coords.y + move
          end
          if IsDisabledControlPressed(0, 173) then
            target.coords.y = target.coords.y - move
          end
          if IsDisabledControlPressed(0, 10) then
            target.coords.z = target.coords.z + move
          end
          if IsDisabledControlPressed(0, 11) then
            target.coords.z = target.coords.z - move
          end
        end

        if IsDisabledControlPressed(0, 44) then
          target.heading = (target.heading - rotate) % 360
        end
        if IsDisabledControlPressed(0, 38) then
          target.heading = (target.heading + rotate) % 360
        end

        if IsDisabledControlJustReleased(0, 191) then
          if not pinned then
            pinned = groundValid
            pushCreatorState()
          else
            CreateThread(function()
              saveDraft()
            end)
          end
        end
      end

      if IsDisabledControlJustReleased(0, 200) or IsDisabledControlJustReleased(0, 322) then
        ScootPlacement.close()
        break
      end

      if not ScootPlacement.active then
        break
      end

      local target = stageTarget()
      local coords = target.coords
      local alpha = 1.0 - math.exp(-18.0 * math.min(GetFrameTime(), 0.1))

      if not smoothPos or #(vec3(coords.x, coords.y, coords.z) - smoothPos) > 6.0 then
        smoothPos = vec3(coords.x, coords.y, coords.z)
        smoothHeading = target.heading
      else
        smoothPos = smoothPos + (vec3(coords.x, coords.y, coords.z) - smoothPos) * alpha
        local delta = ((target.heading - smoothHeading) + 540.0) % 360.0 - 180.0
        smoothHeading = (smoothHeading + delta * alpha) % 360.0
      end

      local previewEntry = {
        coords = { x = smoothPos.x, y = smoothPos.y, z = smoothPos.z },
        heading = smoothHeading,
      }
      local preview = ScootPlacement.previewPose(draft, stage, previewEntry, terminalReady)
      local key = draft.side .. ":" .. draft.version

      if ghostKey ~= key or not ghost then
        if ghost then
          ScootBunker.destroy(ghost)
        end
        local made, newGhost = pcall(ScootBunker.makeGhost, preview)
        if not made then
          ScootPlacement.close()
          ScootBunker.notify(tostring(newGhost))
          break
        end
        if not ScootPlacement.active then
          ScootBunker.destroy(newGhost)
          break
        end
        ghost = newGhost
        ghostKey = key
        ghostObj = ghost.obj
      end

      ScootBunker.moveGhost(ghost, preview, raised and 300 or 0)
      SetEntityVisible(ghost.obj, stage == "terminal", false)
      if CapsuleDui then
        CapsuleDui.color(draft.color or config.glow.color)
      end

      local rad = math.rad(smoothHeading)
      local fx = -math.sin(rad)
      local fy = math.cos(rad)
      local tipX = smoothPos.x + fx * 4
      local tipY = smoothPos.y + fy * 4
      local tipZ = smoothPos.z + 0.1
      DrawLine(smoothPos.x, smoothPos.y, tipZ, tipX, tipY, tipZ, 0, 229, 180, 255)
      DrawLine(
        tipX, tipY, tipZ,
        tipX - fx * 0.6 + fy * 0.35,
        tipY - fy * 0.6 - fx * 0.35,
        tipZ,
        0, 229, 180, 255
      )
      DrawLine(
        tipX, tipY, tipZ,
        tipX - fx * 0.6 - fy * 0.35,
        tipY - fy * 0.6 + fx * 0.35,
        tipZ,
        0, 229, 180, 255
      )

      if now - lastStateAt > 120 then
        lastStateAt = now
        pushCreatorState()
      end
      Wait(0)
    end
  end)
end

local creatorCmd = (config.creator and config.creator.command) or "taochotthue"
RegisterCommand(creatorCmd, function()
  openCreator()
end, false)
if creatorCmd ~= "vaultplace" then
  RegisterCommand("vaultplace", function()
    openCreator()
  end, false)
end

local function handleRemoveCommand(source, args)
  local ok, result = pcall(ScootRuntime.callback.await, "capsulerent:creator", false)
  if not (ok and result and result.ok) then
    ScootBunker.notify((result and result.error) or ScootT("connection_error"))
    return
  end

  local pedCoords = GetEntityCoords(ScootCache.ped)
  local nearestId = nil
  local nearestDist = config.creator.maxDistance
  for id, entry in pairs(result.locations or {}) do
    local dist = #(pedCoords - vec3(entry.coords.x, entry.coords.y, entry.coords.z))
    if not entry.fixed and nearestDist > dist then
      nearestId = id
      nearestDist = dist
    end
  end

  if not nearestId then
    ScootBunker.notify(ScootT("no_station"))
    return
  end

  if args and (args[1] == "confirm" or args[1] == "force" or args[1] == "xacnhan") then
    local delOk, delRes = pcall(ScootRuntime.callback.await, "capsulerent:deleteLocation", false, nearestId)
    if delOk and delRes and delRes.ok then
      ScootRuntime.notify({ description = ScootT("deleted"), type = "success" })
    else
      ScootBunker.notify((delRes and delRes.error) or ScootT("storage_failed"))
    end
    return
  end

  openCreator(nearestId)
end

local removeCmd = (config.creator and config.creator.removeCommand) or "xoachotthue"
RegisterCommand(removeCmd, handleRemoveCommand, false)
if removeCmd ~= "vaultremove" then
  RegisterCommand("vaultremove", handleRemoveCommand, false)
end

RegisterNUICallback("creatorTyping", function(data, cb)
  typingActive = data.active == true
  -- While typing in NUI fields, don't feed keys to the game. Otherwise keep input
  -- so Enter can lock the vault and arrows/Q-E still nudge it.
  SetNuiFocusKeepInput(not typingActive)
  cb({ ok = true })
end)

RegisterNUICallback("creatorAction", function(data, cb)
  if not (ScootPlacement.active and not busy and draft) then
    cb({ ok = false })
    return
  end

  local action = data.action
  if action == "save" then
    saveDraft(cb)
    return
  end

  if action == "delete" then
    if not draft or not draft.id then
      cb({ ok = false })
      return
    end
    busy = true
    local targetId = draft.id
    local ok, result = pcall(
      ScootRuntime.callback.await,
      "capsulerent:deleteLocation",
      false,
      { id = targetId, revision = draft.revision }
    )
    busy = false
    if not ok or not result then
      result = { ok = false, error = ScootT("connection_error") }
    end
    cb(result)
    if result.ok then
      if editingId and ScootBunker.list[editingId] then
        ScootBunker.despawn(editingId)
        editingId = nil
      end
      if locations then
        locations[targetId] = nil
      end
      ScootPlacement.close()
      ScootRuntime.notify({ description = ScootT("deleted"), type = "success" })
    else
      ScootRuntime.notify({ description = result.error or ScootT("connection_error"), type = "error" })
    end
    return
  end

  if action == "new" then
    loadDraft()
  elseif action == "edit" then
    local entry = locations and locations[data.id]
    if entry then
      local dist = #(GetEntityCoords(ScootCache.ped) - vec3(entry.coords.x, entry.coords.y, entry.coords.z))
      if dist > config.creator.maxDistance then
        teleportToStation(entry)
      end
      if not entry.fixed then
        loadDraft(entry)
      end
    end
  elseif action == "remove" then
    local entry = locations and locations[data.id]
    if not entry or entry.fixed then
      cb({ ok = false, error = ScootT("invalid") })
      return
    end
    local dist = #(GetEntityCoords(ScootCache.ped) - vec3(entry.coords.x, entry.coords.y, entry.coords.z))
    if dist > config.creator.maxDistance then
      teleportToStation(entry)
    end
    busy = true
    local targetId = entry.id
    local ok, result = pcall(
      ScootRuntime.callback.await,
      "capsulerent:deleteLocation",
      false,
      { id = targetId, revision = entry.revision }
    )
    busy = false
    if not ok or not result then
      result = { ok = false, error = ScootT("connection_error") }
    end
    if result.ok then
      locations = result.locations or locations or {}
      locations[targetId] = nil
      if ScootBunker.list[targetId] then
        ScootBunker.despawn(targetId)
      end
      if editingId == targetId then
        editingId = nil
      end
      if draft and draft.id == targetId then
        loadDraft()
      end
      ScootRuntime.notify({ description = ScootT("deleted"), type = "success" })
      SendNUIMessage({
        action = "openCreator",
        locale = ScootTranslations(),
        theme = ScootTheme(),
        locations = locations,
        presets = (config.glow or {}).presets,
        blips = config.blips,
      })
    else
      ScootRuntime.notify({ description = result.error or ScootT("connection_error"), type = "error" })
    end
    cb(result)
    pushCreatorState()
    return
  elseif action == "stage" then
    if data.value == "capsule" or data.value == "terminal" then
      if data.value == "terminal" and not capsuleReady then
        cb({ ok = false, error = ScootT("capsule_first") })
        return
      end
      if stage == "terminal" and pinned then
        terminalReady = true
      end
      setStage(data.value)
    end
  elseif action == "version" then
    if data.value == "booth" or data.value == "tablet" then
      draft.version = data.value
      terminalReady = false
      if stage == "terminal" then
        pinned = false
        groundValid = false
      end
    end
  elseif action == "pin" then
    if not pinned and groundValid then
      pinned = true
    else
      pinned = false
    end
  elseif action == "preview" then
    raised = not raised
  elseif action == "side" then
    if data.value == "left" or data.value == "right" then
      draft.side = data.value
    end
  elseif action == "color" then
    if type(data.value) == "string" then
      draft.color = ScootColor(data.value) or draft.color
    end
  elseif action == "blip" then
    if type(data.field) == "string" then
      draft.blip = draft.blip or {}
      local field = data.field
      local value = data.value
      if field == "enabled" or field == "shortRange" or field == "flash" then
        draft.blip[field] = value == true
      elseif field == "sprite" then
        if isFiniteNumber(value) then
          draft.blip.sprite = math.max(1, math.min(5000, math.floor(value)))
        end
      elseif field == "color" then
        if isFiniteNumber(value) then
          draft.blip.color = math.max(0, math.min(85, math.floor(value)))
        end
      elseif field == "scale" then
        if isFiniteNumber(value) then
          draft.blip.scale = math.max(0.1, math.min(2.0, value + 0.0))
        end
      elseif field == "flashInterval" then
        if isFiniteNumber(value) then
          draft.blip.flashInterval = math.max(100, math.min(5000, math.floor(value)))
        end
      elseif field == "label" then
        if type(value) == "string" then
          draft.blip.label = value:sub(1, 40)
        end
      elseif field == "browse" then
        if value == false then
          browsePage = nil
        else
          browsePage = math.max(1, math.min(math.ceil(68.83333333333333), math.floor(value)))
        end
        refreshBrowseBlips()
      end
    end
  elseif action == "name" then
    if type(data.value) == "string" then
      draft.name = data.value:sub(1, 80)
    end
  elseif action == "heading" then
    if isFiniteNumber(data.value) then
      stageTarget().heading = data.value % 360
    end
  elseif action == "coordinate" then
    if ({ x = true, y = true, z = true })[data.axis] and isFiniteNumber(data.value) then
      pinned = true
      stageTarget().coords[data.axis] = data.value
    end
  elseif action == "ground" then
    local coords = stageTarget().coords
    local terrain = ScootPlacement.terrainZ(coords)
    if terrain then
      local kind = stage == "capsule" and "capsule" or draft.version
      stageTarget().coords.z = ScootPlacement.groundZ(terrain, kind)
      pinned = true
      groundValid = true
    else
      cb({ ok = false, error = ScootT("ground_failed") })
      return
    end
  end

  pushCreatorState()
  cb({ ok = true })
end)
