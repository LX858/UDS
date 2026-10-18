ScootBunker = {
  list = {},
}

local config = ScootConfig

function ScootBunker.notify(message)
  ScootRuntime.notify({
    description = message,
    type = "error",
  })
end

function ScootBunker.debug(message)
  if config.debug then
    print("[capsulerent] " .. message)
  end
end

function ScootBunker.seatNpc(bunker)
  local ped = bunker.ped
  if not ped or not DoesEntityExist(ped) then
    return
  end

  local anim = config.npc.animation
  ScootRuntime.requestAnimDict(anim.dict, 10000)

  local frame = Capsule.terminalFrame(bunker.entry)
  local variant = Capsule.variant(frame.side)
  local coords = Capsule.world(
    frame,
    variant.kioskCenter[1] + config.npc.offsetX,
    config.npc.offsetY,
    config.npc.z
  )

  ClearPedTasksImmediately(ped)
  SetEntityCollision(ped, false, false)
  SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
  SetEntityHeading(ped, (frame.heading or 0) + (config.npc.headingOffset or 0))
  FreezeEntityPosition(ped, true)
  SetPedKeepTask(ped, true)
  TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 2569, 1.0, false, false, false)
  bunker.npcAlignAt = GetGameTimer() + 700
end

function ScootBunker.updateNpc(bunker)
  local ped = bunker.ped
  if not ped or not DoesEntityExist(ped) then
    return
  end

  local now = GetGameTimer()
  local anim = config.npc.animation
  local npcCheck = bunker.npcCheck or 0

  if now > npcCheck then
    bunker.npcCheck = now + 2000
    if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
      ScootBunker.seatNpc(bunker)
      return
    end
  end

  if bunker.npcAlignAt and now >= bunker.npcAlignAt then
    if IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
      local frame = Capsule.terminalFrame(bunker.entry)
      local variant = Capsule.variant(frame.side)
      local target = Capsule.world(
        frame,
        variant.kioskCenter[1] + config.npc.offsetX,
        config.npc.offsetY,
        config.npc.seatHeight or 0.62
      )
      local bone = GetPedBoneCoords(ped, 11816, 0.0, 0.0, 0.0)
      local pedCoords = GetEntityCoords(ped)
      SetEntityCoordsNoOffset(
        ped,
        pedCoords.x + target.x - bone.x,
        pedCoords.y + target.y - bone.y,
        pedCoords.z + target.z - bone.z,
        true,
        true,
        false
      )
      bunker.npcAlignAt = nil
    end
  end
end

function createBunkerObject(modelName, placement, collision)
  local hash = joaat(modelName)
  ScootRuntime.requestModel(hash, 10000)
  local coords = placement.coords
  RequestCollisionAtCoord(coords.x, coords.y, coords.z)
  local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, true)
  if not entity or entity == 0 then
    error("Could not create " .. modelName)
  end

  local deadline = GetGameTimer() + 3000
  while not DoesEntityExist(entity) and GetGameTimer() < deadline do
    Wait(0)
  end
  if not DoesEntityExist(entity) then
    error("Could not create " .. modelName)
  end

  SetEntityHeading(entity, placement.heading or 0)
  SetEntityDynamic(entity, true)
  ActivatePhysics(entity)
  FreezeEntityPosition(entity, true)
  SetEntityInvincible(entity, true)
  SetEntityCollision(entity, collision, true)
  SetEntityLodDist(entity, 300)
  SetModelAsNoLongerNeeded(hash)
  return entity
end

function ScootBunker.pose(bunker, frame)
  if not bunker or not bunker.mech or not DoesEntityExist(bunker.mech) then
    return
  end

  local now = GetGameTimer()
  local frameKey = math.floor(frame * 10) -- scrub at 0.1 frame steps
  if bunker.lastPoseKey == frameKey
    and bunker.lastHidden == bunker.hidden
    and now < (bunker.poseCheckAt or 0)
  then
    return
  end

  -- While the capsule is moving, update every tick; idle can throttle.
  local moving = frame > 0.5 and frame < 599.5
  bunker.poseCheckAt = now + (moving and 0 or 500)
  bunker.lastHidden = bunker.hidden
  bunker.lastPoseKey = frameKey

  local variant = Capsule.variant(bunker.entry.side)
  if not HasAnimDictLoaded(variant.animationDictionary) then
    RequestAnimDict(variant.animationDictionary)
    return
  end

  if not IsEntityPlayingAnim(bunker.mech, variant.animationDictionary, variant.clip, 3) then
    PlayEntityAnim(
      bunker.mech,
      variant.clip,
      variant.animationDictionary,
      8.0,
      false,
      true,
      false,
      0.0,
      0
    )
  end

  local animTime = math.min(math.max(frame / 600.0, 0.0), 0.99999)
  SetEntityAnimSpeed(bunker.mech, variant.animationDictionary, variant.clip, 0.0)
  SetEntityAnimCurrentTime(bunker.mech, variant.animationDictionary, variant.clip, animTime)
  if ForceEntityAiAndAnimationUpdate then
    ForceEntityAiAndAnimationUpdate(bunker.mech)
  end

  local curve = Capsule.curves[math.min(601, math.floor(frame) + 1)]
  if not curve then
    return
  end
  if bunker.plat then
    local base = bunker.entry.coords
    SetEntityCoordsNoOffset(
      bunker.plat,
      base.x,
      base.y,
      base.z + curve.platformCenterZ,
      false,
      false,
      false
    )

    local platCollision = not bunker.hidden and frame >= 160 and frame < 440
    SetEntityCollision(bunker.plat, platCollision, true)

    SetEntityCoordsNoOffset(
      bunker.roof,
      base.x,
      base.y,
      base.z + curve.capsuleZ,
      false,
      false,
      false
    )
    SetEntityCollision(bunker.roof, not bunker.hidden, true)

    if bunker.wall then
      SetEntityCoordsNoOffset(
        bunker.wall,
        base.x,
        base.y,
        base.z + curve.capsuleZ + curve.wallLocalZ,
        false,
        false,
        false
      )
      SetEntityCollision(bunker.wall, not bunker.hidden, true)
      SetEntityCoordsNoOffset(
        bunker.frame,
        base.x,
        base.y,
        base.z + curve.capsuleZ,
        false,
        false,
        false
      )
      SetEntityCollision(bunker.frame, not bunker.hidden, true)
    end
  end
end

function ScootBunker.makeGhost(entry)
  local variant = Capsule.variant(entry.side)
  ScootRuntime.requestAnimDict(variant.animationDictionary, 10000)

  local ghost = {
    entry = entry,
  }

  local ok, err = pcall(function()
    ghost.obj = createBunkerObject(Capsule.terminalModel(entry), Capsule.terminalFrame(entry), false)
    SetEntityVisible(ghost.obj, not entry.previewCapsuleOnly, false)

    if entry.terminal then
      ghost.base = createBunkerObject("ninelabs_capsule_base_" .. entry.side, entry, false)
      SetEntityAlpha(ghost.base, 190, false)
    end

    ghost.mech = createBunkerObject(variant.mechanism, entry, false)
    SetEntityAlpha(ghost.obj, 190, false)
    SetEntityAlpha(ghost.mech, 190, false)
    ScootBunker.pose(ghost, 300)
  end)

  if not ok then
    ScootBunker.destroy(ghost)
    error(err)
  end

  return ghost
end

function ScootBunker.moveGhost(ghost, entry, frame)
  ghost.entry = entry
  for _, key in ipairs({ "obj", "mech", "base" }) do
    local entity = ghost[key]
    if entity then
      local placement = entry
      if key == "obj" then
        placement = Capsule.terminalFrame(entry) or entry
      end
      SetEntityCoordsNoOffset(
        entity,
        placement.coords.x,
        placement.coords.y,
        placement.coords.z,
        false,
        false,
        false
      )
      SetEntityHeading(entity, placement.heading)
    end
  end
  ScootBunker.pose(ghost, frame)
end

function ScootBunker.hide(stationId, hidden)
  local bunker = ScootBunker.list[stationId]
  if not bunker then
    return
  end

  bunker.hidden = hidden
  for _, key in ipairs({ "obj", "mech", "ped", "base" }) do
    if bunker[key] then
      SetEntityVisible(bunker[key], not hidden, false)
    end
  end

  if bunker.base then
    SetEntityCollision(bunker.base, not hidden, true)
  end

  SetEntityCollision(bunker.obj, not hidden, not hidden)

  if bunker.plat then
    SetEntityCollision(bunker.plat, false, true)
    SetEntityCollision(bunker.roof, not hidden, true)
  end

  if bunker.wall then
    SetEntityCollision(bunker.wall, not hidden, true)
    SetEntityCollision(bunker.frame, not hidden, true)
  end
end

function ScootBunker.destroy(bunker)
  if not bunker then
    return
  end

  ScootAudio.stop(bunker.soundId)

  if bunker.zone then
    pcall(ScootClientBridge.removeTarget, bunker.zone)
  end
  if bunker.bayZone then
    pcall(ScootClientBridge.removeTarget, bunker.bayZone)
  end

  for _, key in ipairs({ "ped", "obj", "mech", "plat", "roof", "wall", "frame", "base" }) do
    local entity = bunker[key]
    if entity and DoesEntityExist(entity) then
      DeleteEntity(entity)
    end
  end
end

function ScootBunker.spawn(stationId, entry)
  local variant = Capsule.variant(entry.side)
  local bunker = {
    entry = entry,
    coords = vector3(entry.coords.x, entry.coords.y, entry.coords.z),
  }
  ScootBunker.list[stationId] = bunker

  local ok, err = pcall(function()
    ScootRuntime.requestAnimDict(variant.animationDictionary, 10000)

    bunker.obj = createBunkerObject(
      Capsule.terminalModel(entry),
      Capsule.terminalFrame(entry),
      true
    )

    if entry.terminal then
      bunker.base = createBunkerObject("ninelabs_capsule_base_" .. entry.side, entry, true)
    end

    bunker.mech = createBunkerObject(variant.mechanism, entry, false)
    bunker.plat = createBunkerObject(variant.proxies[1].model, entry, false)
    bunker.roof = createBunkerObject(variant.proxies[2].model, entry, true)
    bunker.wall = createBunkerObject("ninelabs_capsule_wallcol_" .. entry.side, entry, true)
    bunker.frame = createBunkerObject("ninelabs_capsule_framecol_" .. entry.side, entry, true)

    SetEntityAlpha(bunker.plat, 0, false)
    SetEntityAlpha(bunker.roof, 0, false)
    SetEntityAlpha(bunker.wall, 0, false)
    SetEntityAlpha(bunker.frame, 0, false)
    ScootBunker.pose(bunker, 0)

    if not DoesEntityHavePhysics(bunker.obj) or not DoesEntityHavePhysics(bunker.roof) then
      print("[capsulerent] WARNING: streamed model has no physics. Reconnect after updating YTYP assets; run /vaultdiag.")
    end

    local skipNpc = entry.terminal and entry.version == "tablet"
    if config.npc.enabled and not skipNpc then
      ScootRuntime.requestModel(joaat(config.npc.model), 10000)
      local frame = Capsule.terminalFrame(entry)
      local frameVariant = Capsule.variant(frame.side)
      local coords = Capsule.world(
        frame,
        frameVariant.kioskCenter[1] + config.npc.offsetX,
        config.npc.offsetY,
        config.npc.z
      )

      bunker.ped = CreatePed(
        4,
        joaat(config.npc.model),
        coords.x,
        coords.y,
        coords.z,
        frame.heading,
        false,
        false
      )
      SetEntityCoordsNoOffset(bunker.ped, coords.x, coords.y, coords.z, false, false, false)
      FreezeEntityPosition(bunker.ped, true)
      SetEntityInvincible(bunker.ped, true)
      SetBlockingOfNonTemporaryEvents(bunker.ped, true)
      SetPedCanRagdoll(bunker.ped, false)
      SetPedCanBeTargetted(bunker.ped, false)
      ScootBunker.seatNpc(bunker)
      SetModelAsNoLongerNeeded(joaat(config.npc.model))
    end

    ScootBunker.addTarget(stationId, bunker)
    CapsuleDui.ensure()
  end)

  if not ok then
    ScootBunker.destroy(bunker)
    ScootBunker.list[stationId] = nil
    ScootBunker.notify(tostring(err))
  end
end

function ScootBunker.despawn(stationId)
  ScootBunker.destroy(ScootBunker.list[stationId])
  ScootBunker.list[stationId] = nil
end

function ScootBunker.addTarget(stationId, bunker)
  if bunker.zone or not ScootClientBridge.usesTarget() then
    return
  end

  local flow = CapsuleFlow
  bunker.zone = ScootClientBridge.addTarget(
    stationId,
    Capsule.service(bunker.entry),
    1.0,
    config.interactDistance,
    {
      {
        label = ScootT("interact"),
        icon = "fa-solid fa-tablet-screen-button",
        onSelect = function()
          flow.act("open", stationId)
        end,
        canInteract = function()
          return flow.can(stationId, "open")
        end,
      },
    }
  )

  local capsuleCenter = Capsule.variant(bunker.entry.side).capsuleCenter
  bunker.bayZone = ScootClientBridge.addTarget(
    stationId .. ":bay",
    Capsule.world(bunker.entry, capsuleCenter[1], capsuleCenter[2], 0.6),
    4.0,
    12.0,
    {
      {
        label = ScootT("prompt_prepare"),
        icon = "fa-solid fa-car",
        onSelect = function()
          flow.act("prepare", stationId)
        end,
        canInteract = function()
          return flow.can(stationId, "prepare")
        end,
      },
      {
        label = ScootT("prompt_return"),
        icon = "fa-solid fa-check",
        onSelect = function()
          flow.act("return", stationId)
        end,
        canInteract = function()
          return flow.can(stationId, "return")
        end,
      },
    }
  )
end

AddEventHandler("onClientResourceStart", function(resourceName)
  if resourceName ~= "ox_target" and resourceName ~= "qb-target" then
    return
  end

  for stationId, bunker in pairs(ScootBunker.list) do
    bunker.zone = nil
    bunker.bayZone = nil
    ScootBunker.addTarget(stationId, bunker)
  end
end)

CapsuleStates = {}

RegisterNetEvent("capsulerent:cycle", function(stationId, state)
  if source ~= 65535 then
    return
  end

  local bunker = ScootBunker.list[stationId]
  local prev = CapsuleStates[stationId]

  -- Force-show the rent car when the cycle closes without keeping it attached.
  if bunker and prev and prev.mode == "rent" and prev.netId then
    local closingWithoutCar = type(state) == "table" and state.phase == "closing" and not state.netId
    local cleared = not state
    if closingWithoutCar or cleared then
      if NetworkDoesEntityExistWithNetworkId(prev.netId) then
        local vehicle = NetToVeh(prev.netId) or 0
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
          FreezeEntityPosition(vehicle, false)
          SetEntityVisible(vehicle, true, false)
          SetEntityCollision(vehicle, true, true)
          SetVehicleDoorsLocked(vehicle, 1)
          SetVehicleUndriveable(vehicle, false)
          ResetEntityAlpha(vehicle)
          ActivatePhysics(vehicle)
        end
      end
    end
  end

  if state and type(state) == "table" then
    state.received = GetGameTimer()
    CapsuleStates[stationId] = state
  else
    CapsuleStates[stationId] = nil
  end

  if CapsuleDui then
    CapsuleDui.busy(stationId, CapsuleStates[stationId] ~= nil)
  end
end)

function measureVehicleFit(modelName)
  if type(modelName) ~= "string" or modelName == "" then
    return { ok = false, reason = "model_missing" }
  end

  local hash = joaat(modelName)
  if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
    return { ok = false, reason = "model_missing" }
  end

  ScootRuntime.requestModel(hash, 10000)
  local minDim, maxDim = GetModelDimensions(hash)
  local width = maxDim.x - minDim.x
  local length = maxDim.y - minDim.y
  local height = maxDim.z - minDim.z

  if width > 2.3 or length > 5.6 or height > 2.0 then
    return { ok = false, reason = "model_too_big" }
  end

  return {
    ok = true,
    x = (minDim.x + maxDim.x) / 2,
    y = (minDim.y + maxDim.y) / 2,
    z = minDim.z,
  }
end

ScootRuntime.callback.register("capsulerent:fit", function(modelName)
  local ok, result = pcall(measureVehicleFit, modelName)
  if ok and type(result) == "table" then
    return result
  end
  return { ok = false, reason = "model_failed" }
end)

CreateThread(function()
  while true do
    local anyMoving = false

    for stationId, bunker in pairs(ScootBunker.list) do
      ScootBunker.updateNpc(bunker)

      if bunker.mech then
        local state = CapsuleStates[stationId]
        local frame = 0
        if state then
          frame = Capsule.frame(state, GetGameTimer() - state.received) or 0
        end

        ScootBunker.pose(bunker, frame)

        if state then
          if not anyMoving then
            anyMoving = state.phase ~= "hold"
          end

          local soundCue = nil
          for _, cue in ipairs(config.sounds) do
            if state.phase ~= "paused" and frame >= cue.frame and frame < cue.endFrame then
              soundCue = cue
              break
            end
          end

          if bunker.soundCue ~= soundCue or bunker.soundToken ~= state.token then
            ScootAudio.stop(bunker.soundId)
            bunker.soundCue = soundCue
            bunker.soundToken = state.token
            if soundCue then
              bunker.soundId = ScootAudio.play(
                soundCue.file,
                bunker.coords,
                soundCue.volume,
                (soundCue.endFrame - frame) / 30
              )
            else
              bunker.soundId = nil
            end
          end

          local vehicle = state.vehicle
          if not vehicle then
            if state.netId and NetworkDoesEntityExistWithNetworkId(state.netId) then
              vehicle = NetToVeh(state.netId) or 0
            else
              vehicle = 0
            end
          end

          if vehicle ~= 0 then
            local phase = state.phase
            if state.phase == "paused" and state.resumePhase then
              phase = state.resumePhase
            end

            -- Rent: ride the platform up while opening only.
            -- Return: never teleport while opening/hold — player drives in; attach only while closing.
            local attaching
            if state.mode == "rent" then
              attaching = phase == "opening" and frame < 250
            elseif state.mode == "return" then
              attaching = phase == "closing"
            else
              attaching = false
            end

            if DoesEntityExist(vehicle) then
              local hasControl = state.preview or NetworkHasControlOfEntity(vehicle)

              if state.mode == "return" and not attaching then
                -- Leave the player's car alone while the bay opens / waits.
                SetEntityVisible(vehicle, true, false)
                SetEntityCollision(vehicle, true, true)
                FreezeEntityPosition(vehicle, false)
                SetVehicleDoorsLocked(vehicle, 1)
                SetVehicleUndriveable(vehicle, false)
              else
                -- Keep the rental car visible while it rises with the platform (rent open / return close).
                SetEntityVisible(vehicle, true, false)
                ResetEntityAlpha(vehicle)
                SetEntityCollision(vehicle, not attaching, true)

                if attaching then
                  FreezeEntityPosition(vehicle, true)

                  if not hasControl then
                    if state.src == GetPlayerServerId(PlayerId()) then
                      if GetGameTimer() > (bunker.controlAt or 0) then
                        bunker.controlAt = GetGameTimer() + 500
                        NetworkRequestControlOfEntity(vehicle)
                      end
                    end
                  end

                  if hasControl then
                    local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
                    local capsuleCenter = Capsule.variant(bunker.entry.side).capsuleCenter
                    local curve = Capsule.curves[math.floor(frame) + 1]
                    if curve then
                      local worldPos = Capsule.world(
                        bunker.entry,
                        capsuleCenter[1] - (minDim.x + maxDim.x) / 2,
                        capsuleCenter[2] - (minDim.y + maxDim.y) / 2,
                        curve.platformTopZ - minDim.z
                      )
                      SetEntityCoordsNoOffset(vehicle, worldPos.x, worldPos.y, worldPos.z, false, false, false)
                      SetEntityHeading(vehicle, bunker.entry.heading)
                      SetVehicleDoorsLocked(vehicle, 2)
                    end
                  end
                else
                  FreezeEntityPosition(vehicle, false)
                  SetEntityCollision(vehicle, true, true)
                  SetVehicleDoorsLocked(vehicle, 1)
                  SetVehicleUndriveable(vehicle, false)

                  if not state.preview then
                    local isOwner = hasControl or state.src == GetPlayerServerId(PlayerId())
                    if isOwner then
                      if state.mode == "rent" and state.phase == "hold" then
                        if bunker.holdToken ~= state.token then
                          bunker.holdToken = state.token
                          bunker.holdSince = GetGameTimer()
                        end

                        local graceMs = math.floor(((config.rental and config.rental.pickupGraceSeconds) or 25) * 1000)
                        local ped = PlayerPedId()
                        local inVehicle = GetVehiclePedIsIn(ped, false) == vehicle
                        local leftBay = not Capsule.bay(bunker.entry, GetEntityCoords(vehicle), 0.35)
                        local timedOut = (GetGameTimer() - (bunker.holdSince or GetGameTimer())) >= graceMs

                        -- Close only after the renter drives out of the bay (or grace timeout).
                        if ((inVehicle and leftBay) or timedOut) and GetGameTimer() > (bunker.releaseAck or 0) then
                          bunker.releaseAck = GetGameTimer() + 1000
                          TriggerServerEvent("capsulerent:released", stationId, state.token)
                        end
                      end
                    end

                    if hasControl and state.mode == "rent" and bunker.fuelToken ~= state.token then
                      bunker.fuelToken = state.token
                      SetVehicleFuelLevel(vehicle, 100.0)
                      Entity(vehicle).state:set("fuel", 100, true)
                    end
                  end
                end
              end
            end
          end
        else
          if bunker.soundId then
            ScootAudio.stop(bunker.soundId)
            bunker.soundId = nil
            bunker.soundCue = nil
          end
        end
      end
    end

    Wait(anyMoving and 0 or 100)
  end
end)

function applyCapsuleTravel(vehicle, traveling)
  if traveling == true then
    SetEntityCollision(vehicle, false, true)
    FreezeEntityPosition(vehicle, true)
    SetEntityVisible(vehicle, false, false)
  elseif traveling == false then
    SetEntityVisible(vehicle, true, false)
    SetEntityCollision(vehicle, true, true)
    FreezeEntityPosition(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleUndriveable(vehicle, false)
    ActivatePhysics(vehicle)
  end
end

AddStateBagChangeHandler("capsuleTravel", nil, function(bagName, _key, value)
  local netId = tonumber(bagName:match("^entity:(%d+)"))
  if not netId then
    return
  end

  CreateThread(function()
    local deadline = GetGameTimer() + 3000
    local entity = 0
    repeat
      if NetworkDoesEntityExistWithNetworkId(netId) then
        entity = NetworkGetEntityFromNetworkId(netId)
      end
      if entity ~= 0 then
        break
      end
      Wait(50)
    until GetGameTimer() > deadline

    if entity ~= 0 and DoesEntityExist(entity) then
      if Entity(entity).state.capsuleTravel == value then
        applyCapsuleTravel(entity, value)
      end
    end
  end)
end)

CreateThread(function()
  Wait(2000)
  for _, vehicle in ipairs(GetGamePool("CVehicle")) do
    local state = Entity(vehicle).state
    if state.capsuleRental and state.capsuleTravel ~= nil then
      applyCapsuleTravel(vehicle, state.capsuleTravel)
    end
  end
end)
