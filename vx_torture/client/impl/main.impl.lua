---@class MainImpl : Impl
local Impl = NewImpl('Main')
local cfg = Config.Torture
-- Scripted animation flags (TASK_PLAY_ANIM), not synchronized-scene flags.
local AF_OVERRIDE_PHYSICS = 1024
local AF_EXTRACT_INITIAL_OFFSET = 4096
local AF_FORCE_START = 131072
local AF_USE_MOVER_EXTRACTION = 524288
local VICTIM_TRACK_FLAGS = AF_OVERRIDE_PHYSICS | AF_EXTRACT_INITIAL_OFFSET
  | AF_FORCE_START | AF_USE_MOVER_EXTRACTION

local function notify(key)
  lib.notify({ title = 'Ghế tra tấn', description = L(key), type = 'inform' })
end

local function previewFailed(reason)
  if Config.Debug then
    print(('[vx_torture] Không tạo được preview: %s'):format(reason))
  end
  notify('place_failed')
end

local function playerSource()
  return GetPlayerServerId(PlayerId())
end

local function fromNet(netId, timeoutMs)
  if not netId or netId == 0 then return nil end
  local untilTime = GetGameTimer() + (timeoutMs or 2000)
  repeat
    if NetworkDoesEntityExistWithNetworkId(netId) then
      local entity = NetworkGetEntityFromNetworkId(netId)
      if entity ~= 0 and DoesEntityExist(entity) then return entity end
    end
    Wait(50)
  until GetGameTimer() >= untilTime
  return nil
end

local function targetReady(netId)
  if not netId or netId == 0 or not NetworkDoesNetworkIdExist(netId)
    or not NetworkDoesEntityExistWithNetworkId(netId) then return false end
  local entity = NetworkGetEntityFromNetworkId(netId)
  return entity ~= 0 and DoesEntityExist(entity)
end

local function loadDict(dict, timeoutMs)
  if not DoesAnimDictExist(dict) then return false end
  RequestAnimDict(dict)
  local untilTime = GetGameTimer() + (timeoutMs or 5000)
  while not HasAnimDictLoaded(dict) and GetGameTimer() < untilTime do Wait(0) end
  return HasAnimDictLoaded(dict)
end

local function worldOffset(origin, heading, offset)
  local r = math.rad(heading)
  return vector3(
    origin.x + offset.x * math.cos(r) - offset.y * math.sin(r),
    origin.y + offset.x * math.sin(r) + offset.y * math.cos(r),
    origin.z + offset.z
  )
end

-- FBI3 animates the chair as well as the victim. Solve the scene root
-- from the chair track so every actor and prop track shares its placement.
local function alignedSceneOrigin(chair, heading)
  local alignment = cfg.seatAlignment
  if not HasAnimDictLoaded(alignment.dict) and not loadDict(alignment.dict, 3000) then
    return nil
  end
  local initialRotation = GetAnimInitialOffsetRotation(alignment.dict, alignment.chair,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2)
  local sceneHeading = (heading - initialRotation.z + cfg.sceneHeadingCorrection) % 360.0
  local initialChair = GetAnimInitialOffsetPosition(alignment.dict, alignment.chair,
    0.0, 0.0, 0.0, 0.0, 0.0, sceneHeading, 0.0, 2)
  if not initialChair then return nil end
  local desiredChair = worldOffset(chair, heading, cfg.sceneOffset)
  return vector3(desiredChair.x - initialChair.x,
    desiredChair.y - initialChair.y, desiredChair.z - initialChair.z), sceneHeading
end

local function sceneOrigin(setup)
  if not targetReady(setup.props.chair) or not setup.positions.chair then return nil end
  return alignedSceneOrigin(setup.positions.chair, setup.heading)
end

function Impl:WaitForActorTrack(scene, ped, dict, clip, looped, current)
  if not loadDict(dict, 3000) or not current() then return nil end
  local expires = GetGameTimer() + 2500
  local localScene = -1
  repeat
    if not current() then return nil end
    localScene = NetworkGetLocalSceneFromNetworkId(scene)
    if localScene and localScene >= 0 then
      SetSynchronizedSceneLooped(localScene, looped)
      SetSynchronizedSceneHoldLastFrame(localScene, not looped)
      if IsSynchronizedSceneRunning(localScene) and IsEntityPlayingAnim(ped, dict, clip, 3) then
        self:StopRetiredScenes()
        return localScene
      end
    end
    Wait(0)
  until GetGameTimer() >= expires
  print(('[vx_torture] Scene did not start: %s / %s (network=%s, local=%s)')
    :format(dict, clip, scene, localScene))
  return nil
end

function Impl:AddActorTrack(scene, ped, dict, clip, looped)
  -- Register the owning player BEFORE NetworkStartSynchronisedScene. The
  -- local handle is only used for phase/camera; do not inject a local task
  -- into the network scene after it starts.
  local flags = 1024 | 2048 | (looped and 64 or 0)
  NetworkAddPedToSynchronisedScene(ped, scene, dict, clip,
    8.0, -8.0, flags, 0, 1000.0, 0)
  self.actorTrack = { scene = scene, dict = dict, clip = clip, looped = looped }
end

function Impl:ActorTrackRunning(scene)
  local track = self.actorTrack
  if not track or track.scene ~= scene or self.scene ~= scene then return false end
  local playing = not IsEntityDead(PlayerPedId())
    and self.localScene and IsSynchronizedSceneRunning(self.localScene)
    and IsEntityPlayingAnim(PlayerPedId(), track.dict, track.clip, 3)
  if not playing then
    print(('[vx_torture] Actor track lost: %s / %s (network=%s, local=%s)')
      :format(track.dict, track.clip, scene, self.localScene))
  end
  return playing == true
end

local function loadModel(model, timeoutMs)
  if not IsModelInCdimage(model) or not IsModelValid(model) then return false end
  RequestModel(model)
  local untilTime = GetGameTimer() + timeoutMs
  while not HasModelLoaded(model) and GetGameTimer() < untilTime do Wait(0) end
  return HasModelLoaded(model)
end

local function setDisplayRotation(entity, heading, prop, restRotation)
  if restRotation then
    SetEntityRotation(entity, restRotation.x, restRotation.y, restRotation.z, 2, true)
    return
  end
  local rotation = prop.rotation
  if rotation then
    SetEntityRotation(entity, rotation.x, rotation.y, (heading + rotation.z) % 360.0, 2, true)
  else
    SetEntityHeading(entity, heading)
  end
end

local function verticalBounds(entity, min, max)
  local originZ = GetEntityCoords(entity).z
  local low, high = math.huge, -math.huge
  for _, x in ipairs({ min.x, max.x }) do
    for _, y in ipairs({ min.y, max.y }) do
      for _, z in ipairs({ min.z, max.z }) do
        local height = GetOffsetFromEntityInWorldCoords(entity, x, y, z).z - originZ
        low = math.min(low, height)
        high = math.max(high, height)
      end
    end
  end
  return low, high
end

local function groundAt(x, y, aroundZ)
  RequestCollisionAtCoord(x, y, aroundZ)
  local found, groundZ = GetGroundZFor_3dCoord(x, y, aroundZ + 5.0, false)
  return found and math.abs(groundZ - aroundZ) <= cfg.maxGroundStep and groundZ or aroundZ
end

local function placementLayout(ped, bounds, clips, objects)
  local wanted = GetOffsetFromEntityInWorldCoords(ped, 0.0, cfg.placementDistance, 0.0)
  local heading = GetEntityHeading(ped)
  local anchor = vector3(wanted.x, wanted.y, groundAt(wanted.x, wanted.y, wanted.z))
  local positions = {}
  local rotations = {}
  for _, key in ipairs(cfg.propOrder) do
    local prop, box = cfg.props[key], bounds[key]
    if box and prop.ground and not (prop.restClip and clips[key]) and not prop.referencePosition then
      local xy = worldOffset(anchor, heading, vector3(prop.offset.x, prop.offset.y, 0.0))
      positions[key] = vector3(xy.x, xy.y,
        groundAt(xy.x, xy.y, anchor.z) - box.verticalMin + prop.offset.z + cfg.groundClearance)
    end
  end
  local chair = positions.chair
  if chair then
    local sceneCoords, sceneHeading = alignedSceneOrigin(chair, heading)
    if not sceneCoords then return nil end
    for _, key in ipairs(cfg.propOrder) do
      local prop = cfg.props[key]
      if bounds[key] and prop.restClip and clips[key] then
        local clip = prop.restClip
        positions[key] = GetAnimInitialOffsetPosition(cfg.layoutDict, clip,
          sceneCoords.x, sceneCoords.y, sceneCoords.z, 0.0, 0.0, sceneHeading, 0.0, 2)
        rotations[key] = GetAnimInitialOffsetRotation(cfg.layoutDict, clip,
          sceneCoords.x, sceneCoords.y, sceneCoords.z, 0.0, 0.0, sceneHeading, 0.0, 2)
      elseif bounds[key] and prop.referencePosition then
        local original = cfg.referenceChair
        local delta = prop.referencePosition - original
        local r = math.rad(heading - cfg.referenceHeading)
        local x = chair.x + delta.x * math.cos(r) - delta.y * math.sin(r)
        local y = chair.y + delta.x * math.sin(r) + delta.y * math.cos(r)
        positions[key] = vector3(x, y, chair.z + delta.z)
        local rotation = prop.referenceRotation
        rotations[key] = vector3(rotation.x, rotation.y,
          (rotation.z + heading - cfg.referenceHeading) % 360.0)
      end
    end
    if positions.trolley and clips.trolley and objects.trolley then
      local trolley = positions.trolley
      local box = bounds.trolley
      setDisplayRotation(objects.trolley, heading, cfg.props.trolley, rotations.trolley)
      local bottom = verticalBounds(objects.trolley, box.min, box.max)
      local correctZ = groundAt(trolley.x, trolley.y, anchor.z) - bottom + cfg.groundClearance
      local shift = correctZ - trolley.z
      if shift ~= 0.0 then
        for _, key in ipairs(cfg.propOrder) do
          local prop = cfg.props[key]
          if prop.restClip and positions[key] then
            local position = positions[key]
            positions[key] = vector3(position.x, position.y, position.z + shift)
          end
        end
      end
    end
    if positions.stool and objects.stool then
      local stool = positions.stool
      local box = bounds.stool
      setDisplayRotation(objects.stool, heading, cfg.props.stool, rotations.stool)
      local bottom = verticalBounds(objects.stool, box.min, box.max)
      local correctZ = groundAt(stool.x, stool.y, anchor.z) - bottom + cfg.groundClearance
      local shift = correctZ - stool.z
      positions.stool = vector3(stool.x, stool.y, correctZ)
      if positions.ecg then
        local ecg = positions.ecg
        positions.ecg = vector3(ecg.x, ecg.y, ecg.z + shift)
      end
    end
  end
  for _, key in ipairs(cfg.propOrder) do
    local prop, box = cfg.props[key], bounds[key]
    if box and not positions[key] then
      local xy = worldOffset(anchor, heading, vector3(prop.offset.x, prop.offset.y, 0.0))
      local surface = prop.surface and positions[prop.surface]
      local surfaceBox = prop.surface and bounds[prop.surface]
      local baseZ = surface and surfaceBox and (surface.z + surfaceBox.verticalMax) or anchor.z
      positions[key] = vector3(xy.x, xy.y, baseZ - box.verticalMin + prop.offset.z)
    end
  end
  return { coords = anchor, heading = heading, positions = positions, rotations = rotations }
end

local function requestControl(entity, timeoutMs)
  if NetworkHasControlOfEntity(entity) then return true end
  local untilTime = GetGameTimer() + (timeoutMs or 1500)
  repeat
    NetworkRequestControlOfEntity(entity)
    if NetworkHasControlOfEntity(entity) then return true end
    Wait(50)
  until GetGameTimer() >= untilTime
  return false
end

function Impl:MySetup()
  for _, setup in pairs(self.setups) do
    if setup.owner == playerSource() then return setup end
  end
end

local function toolTargetPosition(setup, tool)
  local position = setup.positions and setup.positions[tool]
  if not position then return nil end
  local offset = cfg.props[tool].targetOffset
  if not offset then return position end
  local rotation = setup.rotations and setup.rotations[tool]
  return worldOffset(position, rotation and rotation.z or setup.heading, offset)
end

local function nearestRestingTool(setup, hitCoords)
  if not hitCoords then return nil end
  -- Tools have no collision, so the raycast hits the trolley beneath them.
  -- Compare XY only; a raised prop should still map to its table position.
  local nearest, bestDistance = nil, cfg.toolTargetRadius ^ 2 + 0.000001
  for _, tool in ipairs(cfg.toolOrder) do
    local position = toolTargetPosition(setup, tool)
    if tool ~= setup.tool and position and targetReady(setup.props[tool]) then
      local distanceSq = (hitCoords.x - position.x) ^ 2 + (hitCoords.y - position.y) ^ 2
      if distanceSq < bestDistance then
        nearest, bestDistance = tool, distanceSq
      end
    end
  end
  return nearest
end

function Impl:ApplyPropCollision(setup)
  if #(GetEntityCoords(PlayerPedId()) - setup.coords) > 45.0 then return end
  for _, key in ipairs(cfg.propOrder) do
    if key ~= 'chair' and key ~= 'trolley' and targetReady(setup.props[key]) then
      local entity = NetworkGetEntityFromNetworkId(setup.props[key])
      SetEntityCollision(entity, false, false)
    end
  end
end

function Impl:AddTargets(setup)
  if setup.owner ~= playerSource() then return end
  local names = self.targets[setup.id] or {}
  local function targetName(suffix) return ('vx_torture:%d:%s'):format(setup.id, suffix) end
  if not names.chair and targetReady(setup.props.chair) then
    names.chair = { targetName('seat'), targetName('release'), targetName('pack') }
    exports.ox_target:addEntity(setup.props.chair, {
    {
      name = names.chair[1], icon = 'fa-solid fa-chair', label = L('chair_seat'),
      distance = cfg.interactDistance,
      canInteract = function()
        local current = self.setups[setup.id]
        return current and current.owner == playerSource() and not current.victim and not current.busy
      end,
      onSelect = function()
        local current = self.setups[setup.id]
        if not current then return end
        CreateThread(function()
          local candidates = self:Callback(self, 'getCandidates', current.id)
          if not candidates or #candidates == 0 then return notify('no_candidates') end
          if #candidates == 1 then
            return self:EmitNet(self, 'seat', current.id, candidates[1].id)
          end
          local options = {}
          for _, candidate in ipairs(candidates) do
            local candidateId = candidate.id
            options[#options + 1] = {
              title = ('%s [%d]'):format(candidate.name, candidateId),
              onSelect = function() self:EmitNet(self, 'seat', current.id, candidateId) end,
            }
          end
          lib.registerContext({
            id = 'vx_torture_candidates', title = L('choose_victim'), options = options,
          })
          lib.showContext('vx_torture_candidates')
        end)
      end,
    },
    {
      name = names.chair[2], icon = 'fa-solid fa-unlock', label = L('chair_release'),
      distance = cfg.interactDistance,
      canInteract = function()
        local current = self.setups[setup.id]
        return current and current.owner == playerSource() and current.victim ~= nil
          and current.toolState == 'empty'
      end,
      onSelect = function() self:EmitNet(self, 'release', setup.id) end,
    },
    {
      name = names.chair[3], icon = 'fa-solid fa-box', label = L('chair_pack'),
      distance = cfg.interactDistance,
      canInteract = function()
        local current = self.setups[setup.id]
        return current and current.owner == playerSource() and not current.busy
          and current.toolState == 'empty'
      end,
      onSelect = function() self:EmitNet(self, 'pack', setup.id) end,
    },
    })
  end

  if not names.trolley and targetReady(setup.props.trolley) then
    names.trolley = { targetName('take') }
    -- A box around the chest also receives ray hits on its top or on props
    -- and peds in front of it; an entity-only option disappears in those cases.
    local trolleyOptions = {
    {
      name = names.trolley[1], icon = 'fa-solid fa-toolbox', label = L('trolley_take'),
      distance = cfg.interactDistance,
      canInteract = function()
        local current = self.setups[setup.id]
        return current and current.owner == playerSource()
          and current.toolState == 'empty' and not current.busy
      end,
      onSelect = function()
        local current = self.setups[setup.id]
        if not current then return end
        if not current.victim or not current.seatReady then return notify('invalid_state') end
        local options = {}
        for _, tool in ipairs(cfg.toolOrder) do
          if current.props[tool] then
            local selectedTool = tool
            options[#options + 1] = {
              title = cfg.toolLabels[tool],
              onSelect = function() self:EmitNet(self, 'takeTool', current.id, selectedTool) end,
            }
          end
        end
        lib.registerContext({
          id = 'vx_torture_tools_' .. current.id, title = L('trolley_take'), options = options,
        })
        lib.showContext('vx_torture_tools_' .. current.id)
      end,
    },
    }
    for _, tool in ipairs(cfg.toolOrder) do
      local selectedTool = tool
      local name = targetName('take_' .. selectedTool)
      names.trolley[#names.trolley + 1] = name
      trolleyOptions[#trolleyOptions + 1] = {
        name = name,
        icon = 'fa-solid fa-hand',
        label = L('take_tool', cfg.toolLabels[selectedTool]),
        distance = cfg.interactDistance,
        canInteract = function(_, _, hitCoords)
          local current = self.setups[setup.id]
          return current and current.owner == playerSource() and current.victim
            and current.seatReady and current.toolState == 'empty' and not current.busy
            and nearestRestingTool(current, hitCoords) == selectedTool
        end,
        onSelect = function()
          self:EmitNet(self, 'takeTool', setup.id, selectedTool)
        end,
      }
    end
    local trolley = NetworkGetEntityFromNetworkId(setup.props.trolley)
    local min, max = GetModelDimensions(GetEntityModel(trolley))
    local center = GetOffsetFromEntityInWorldCoords(trolley,
      (min.x + max.x) * 0.5, (min.y + max.y) * 0.5, (min.z + max.z) * 0.5)
    local padding = cfg.trolleyTargetPadding
    names.trolleyZone = exports.ox_target:addBoxZone({
      name = targetName('trolley_zone'), coords = center,
      size = vector3(max.x - min.x + padding.x,
        max.y - min.y + padding.y, max.z - min.z + padding.z),
      rotation = GetEntityHeading(trolley), debug = Config.DebugZones == true,
      options = trolleyOptions,
    })
  end
  self.targets[setup.id] = names
end

function Impl:RemoveTargets(setup)
  local names = self.targets[setup.id]
  if names then
    if names.trolleyZone then exports.ox_target:removeZone(names.trolleyZone) end
    if names.chair and setup.props.chair then
      exports.ox_target:removeEntity(setup.props.chair, names.chair)
    end
  end
  self.targets[setup.id] = nil
end

function Impl:PutPropBack(setup, key, current)
  local entity = fromNet(setup.props[key], 500)
  local position = setup.positions and setup.positions[key]
  if not entity or not position or not requestControl(entity, 1500) then return false end
  if current and not current() then return false end
  DetachEntity(entity, true, true)
  SetEntityCoordsNoOffset(entity, position.x, position.y, position.z, false, false, false)
  setDisplayRotation(entity, setup.heading, cfg.props[key], setup.rotations and setup.rotations[key])
  FreezeEntityPosition(entity, true)
  return true
end

function Impl:PutToolBack(setup, tool)
  local returned = self:PutPropBack(setup, tool)
  local hand = cfg.toolHand[tool]
  if hand and hand.companion then
    returned = self:PutPropBack(setup, hand.companion.key) and returned
  end
  return returned
end

function Impl:HoldTool(setup, tool)
  local entity = fromNet(setup.props[tool], 2500)
  local hand = cfg.toolHand[tool]
  if not entity or not hand or not requestControl(entity, 1500) then return false end
  local companion = hand.companion and fromNet(setup.props[hand.companion.key], 2500)
  if hand.companion and (not companion or not requestControl(companion, 1500)) then return false end
  FreezeEntityPosition(entity, false)
  local ped = PlayerPedId()
  local bone = GetPedBoneIndex(ped, hand.bone)
  if bone == -1 then bone = GetPedBoneIndex(ped, 57005) end
  if bone == -1 then return false end
  AttachEntityToEntity(entity, ped, bone,
    hand.offset.x, hand.offset.y, hand.offset.z,
    hand.rotation.x, hand.rotation.y, hand.rotation.z,
    false, false, false, false, 2, true)
  if companion then
    local other = hand.companion
    local otherBone = GetPedBoneIndex(ped, other.bone)
    if otherBone == -1 then otherBone = GetPedBoneIndex(ped, 18905) end
    if otherBone == -1 then return false end
    FreezeEntityPosition(companion, false)
    AttachEntityToEntity(companion, ped, otherBone,
      other.offset.x, other.offset.y, other.offset.z,
      other.rotation.x, other.rotation.y, other.rotation.z,
      false, false, false, false, 2, true)
  end
  return IsEntityAttachedToEntity(entity, ped)
    and (not companion or IsEntityAttachedToEntity(companion, ped))
end

function Impl:EndToolSession(setup)
  local session = self.toolSession
  if not session or session.setupId ~= setup.id then return end
  self.toolSession = nil
  if self.toolMenuId and lib.getOpenContextMenu() == self.toolMenuId then
    lib.hideContext(false)
  end
  local returnToSeat = self.seated == setup.id and not self.activeAction
  self:StopStage(returnToSeat)
  if setup.owner == playerSource() and session.tool then
    CreateThread(function()
      for _ = 1, 3 do
        if self:PutToolBack(setup, session.tool) then break end
        Wait(250)
      end
      self:RestoreBench(setup, session.tool, true)
    end)
  elseif returnToSeat then
    self:PlayIdle(setup)
  end
end

function Impl:UpdateSetup(setup)
  if self.removed[setup.id] then return end
  local old = self.setups[setup.id]
  if old and old.revision and setup.revision and old.revision > setup.revision then return end
  self.setups[setup.id] = setup
  self:ApplyPropCollision(setup)
  self:AddTargets(setup)
  local session = self.toolSession
  if session and session.setupId == setup.id
    and (setup.toolToken ~= session.token or setup.toolState == 'empty') then
    self:EndToolSession(old or setup)
  end
  if setup.owner == playerSource() and setup.toolState == 'idle'
    and setup.toolReady and self.toolSession
    and self.toolSession.token == setup.toolToken then
    self:ShowToolMenu(setup)
  end
end

function Impl:StopRetiredScenes()
  local retired = self.retiredScenes
  self.retiredScenes = nil
  for _, scene in ipairs(retired or {}) do NetworkStopSynchronisedScene(scene) end
end

function Impl:StopStage(keepVictimTask, transitioning)
  self.peerScene = nil
  if not keepVictimTask then self:StopVictimScene() end
  self.retiredScenes = self.retiredScenes or {}
  for _, key in ipairs({ 'benchScene', 'scene' }) do
    if self[key] then
      self.retiredScenes[#self.retiredScenes + 1] = self[key]
      self[key] = nil
    end
  end
  self.localScene = nil
  self.actorTrack = nil
  -- Keep the old task's clock/camera alive while the successor obtains its
  -- local handle. Retire it only after the new ped task is actually playing.
  if transitioning then return end
  self:StopRetiredScenes()
  local camera = self.camera
  self.camera = nil
  if camera and DoesCamExist(camera) then
    RenderScriptCams(false, false, 0, true, false)
    SetCamActive(camera, false)
    DestroyCam(camera, false)
  end
  if self.stageChair and DoesEntityExist(self.stageChair) then
    if self.stageChairRestore and requestControl(self.stageChair, 700) then
      local position = self.stageChairRestore.coords
      SetEntityCoordsNoOffset(self.stageChair, position.x, position.y, position.z,
        false, false, false)
      setDisplayRotation(self.stageChair, self.stageChairRestore.heading,
        cfg.props.chair, self.stageChairRestore.rotation)
    end
    FreezeEntityPosition(self.stageChair, true)
    self.stageChair = nil
  end
  self.stageChairRestore = nil
  if self.actorStageActive then
    ClearPedTasks(PlayerPedId())
    self.actorStageActive = false
  end
end

function Impl:ReplaceSceneCamera(camera)
  local previous = self.camera
  self.camera = camera
  RenderScriptCams(true, false, 0, true, false)
  if previous and previous ~= camera and DoesCamExist(previous) then
    SetCamActive(previous, false)
    DestroyCam(previous, false)
  end
end

function Impl:StopVictimScene()
  local scene = self.victimScene
  self.victimScene = nil
  -- The seated player only controls its own ped task. Never stop the actor's
  -- network scene or request control of the chair from this client.
  if scene or self.victimMasterScene then ClearPedTasks(PlayerPedId()) end
  self.victimMasterScene = nil
end

local function victimTrackTransform(setup, stageData)
  local root, heading = sceneOrigin(setup)
  if not root then return nil end
  local position = GetAnimInitialOffsetPosition(stageData.dict, stageData.victim,
    root.x, root.y, root.z, 0.0, 0.0, heading, 0.0, 2)
  local rotation = GetAnimInitialOffsetRotation(stageData.dict, stageData.victim,
    root.x, root.y, root.z, 0.0, 0.0, heading, 0.0, 2)
  return position, rotation
end

function Impl:PlayVictimTrack(setup, stageData, looped, phase, masterScene)
  if self.seated ~= setup.id or IsEntityDead(PlayerPedId())
    or not loadDict(stageData.dict, 3000) then return false end
  local root, heading = sceneOrigin(setup)
  if not root then return false end
  local ped = PlayerPedId()
  local flags = VICTIM_TRACK_FLAGS | (looped and 1 or 2) -- loop / hold last frame
  local track = { dict = stageData.dict, clip = stageData.victim, flags = flags }
  -- FBI3 clips contain authored mover offsets. Supply the common scene origin
  -- and let initial-offset/mover extraction apply the clip transform exactly once.
  -- Override physics keeps the seated capsule from being pushed onto the floor.
  -- Replace the previous task directly; finite tracks hold until their successor.
  TaskPlayAnimAdvanced(ped, track.dict, track.clip,
    root.x, root.y, root.z, 0.0, 0.0, heading,
    8.0, -8.0, -1, flags, phase or 0.0, 2, 0)
  self.victimScene = track
  self.victimMasterScene = masterScene
  local chairPosition = setup.positions and setup.positions.chair
  local expires = GetGameTimer() + 2500
  while self.victimScene == track and self.seated == setup.id and GetGameTimer() < expires do
    if IsEntityPlayingAnim(ped, track.dict, track.clip, 3)
      and chairPosition and #(GetEntityCoords(ped) - chairPosition)
        <= cfg.seatAlignment.maxDistance + 0.8 then return true end
    Wait(0)
  end
  print(('[vx_torture] Victim track missing/off chair (%s / %s, distance=%.2f)')
    :format(track.dict, track.clip,
      chairPosition and #(GetEntityCoords(ped) - chairPosition) or -1.0))
  if self.victimScene == track then self:StopVictimScene() end
  return false
end

function Impl:StartVictimScene(setup, stageData, looped)
  return self:PlayVictimTrack(setup, stageData, looped, 0.0, nil)
end

function Impl:PlayIdle(setup)
  if self.victimSceneStarting then return false end
  self.victimSceneStarting = true
  -- The chair is a networked prop. Only the actor may animate it during a
  -- tool scene; the seated player's base loop animates its own ped alone.
  local ready = self:StartVictimScene(setup, cfg.seatAlignment, true)
  self.victimSceneStarting = false
  self.nextSeatRecoveryAt = GetGameTimer() + 1500
  return ready
end

function Impl:WaitForVictimScene(setup, token, kind, step, scene, localScene)
  local pending = { token = token, kind = kind, step = step, scene = scene }
  self.peerScene = pending
  -- The actor scene must keep advancing. Pausing a network scene while the
  -- other player resolves it stalls every track, including chair and camera.
  self:EmitNet(self, 'bindVictimScene', setup.id, token, kind, step, scene)
  local expires = GetGameTimer() + cfg.scenePeerTimeoutMs
  while self.peerScene == pending and self.scene == scene and pending.ready == nil
    and GetGameTimer() < expires do
    if not self:ActorTrackRunning(scene) then return false end
    if kind ~= 'idle' and GetSynchronizedScenePhase(localScene) >= 0.95 then break end
    Wait(0)
  end
  if self.peerScene ~= pending or self.scene ~= scene then return false end
  if pending.ready ~= true then
    print(('[vx_torture] Victim scene handshake failed: %s / %s / %s'):format(kind, step, scene))
    return false
  end
  return self:ActorTrackRunning(scene)
end

function Impl:JoinVictimScene(setup, stageData, scene, looped, current)
  if not current() then return false end
  local masterLocal = NetworkGetLocalSceneFromNetworkId(scene)
  local phase = masterLocal and masterLocal >= 0
    and IsSynchronizedSceneRunning(masterLocal) and GetSynchronizedScenePhase(masterLocal) or 0.0
  if not looped and phase >= 0.90 then return false end
  local success = self:PlayVictimTrack(setup, stageData, looped, phase, scene)
  return success and current() and self.victimMasterScene == scene
end

function Impl:PrintSceneDiagnostics()
  local setup = self.seated and self.setups[self.seated] or self:MySetup()
  if not setup then print('[vx_torture] No local setup/seat session') return end
  local root, heading = sceneOrigin(setup)
  local session = self.toolSession
  local localScene = not self.seated and self.localScene or nil
  local track = self.seated and self.victimScene or nil
  local trackPosition, trackRotation
  if track then
    trackPosition, trackRotation = victimTrackTransform(setup,
      { dict = track.dict, victim = track.clip })
  end
  local running = self.seated and track
    and IsEntityPlayingAnim(PlayerPedId(), track.dict, track.clip, 3)
    or (localScene and IsSynchronizedSceneRunning(localScene)) or false
  local victimPlayer = setup.victim and GetPlayerFromServerId(setup.victim) or -1
  local victimPed = victimPlayer ~= -1 and GetPlayerPed(victimPlayer) or 0
  print('[vx_torture] diagnostics ' .. json.encode({
    setup = setup.id, role = self.seated and 'victim' or 'actor',
    state = setup.toolState, tool = setup.tool, ready = setup.toolReady,
    token = setup.toolToken, epoch = setup.toolEpoch,
    phase = session and session.phase, idleReady = session and session.idleReady,
    menu = lib.getOpenContextMenu(), masterScene = self.victimMasterScene or self.scene,
    localScene = localScene, running = running,
    actorTrack = self.actorTrack,
    actorPlaying = self.actorTrack and IsEntityPlayingAnim(PlayerPedId(),
      self.actorTrack.dict, self.actorTrack.clip, 3) or false,
    actorPhase = self.actorTrack and GetEntityAnimCurrentTime(PlayerPedId(),
      self.actorTrack.dict, self.actorTrack.clip) or nil,
    victimTrack = track, victimTrackStart = trackPosition,
    victimTrackRotation = trackRotation,
    scenePhase = running and (localScene and GetSynchronizedScenePhase(localScene)
      or GetEntityAnimCurrentTime(PlayerPedId(), track.dict, track.clip)) or nil,
    sceneRate = localScene and running and GetSynchronizedSceneRate(localScene) or nil,
    sceneRoot = root, sceneHeading = heading, chairRest = setup.positions.chair,
    chairNow = targetReady(setup.props.chair) and GetEntityCoords(NetworkGetEntityFromNetworkId(setup.props.chair)) or nil,
    victimPosition = victimPed ~= 0 and GetEntityCoords(victimPed) or nil,
  }))
end

function Impl:ReleaseSeat(setupId)
  if self.seated ~= setupId then return end
  local setup = self.setups[setupId]
  if setup and self.toolSession and self.toolSession.setupId == setupId then
    self:EndToolSession(setup)
  end
  self:StopStage()
  self.activeAction = nil
  self.seated = nil
  local medicallyDown = LocalPlayer.state.isDead or IsEntityDead(PlayerPedId())
  if not medicallyDown then
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    if setup then
      local position = worldOffset(setup.coords, setup.heading, vector3(-0.8, 1.2, 0.0))
      local found, groundZ = GetGroundZFor_3dCoord(position.x, position.y, position.z + 2.0, false)
      SetEntityCoordsNoOffset(ped, position.x, position.y, found and groundZ or position.z,
        false, false, false)
    end
    LocalPlayer.state.invBusy = self.previousInvBusy or false
  end
  self.previousInvBusy = nil
end

function Impl:RestoreBench(setup, selectedTool, returnCompanions, current)
  local selectScene = cfg.toolScenes[selectedTool] and cfg.toolScenes[selectedTool].select
  if not selectScene then return end
  for key in pairs(selectScene.bench or {}) do
    if current and not current() then return end
    if key ~= selectedTool and setup.props[key] then self:PutPropBack(setup, key, current) end
  end
  if returnCompanions and selectedTool == 'waterboard' and setup.props.rag then
    self:PutPropBack(setup, 'rag', current)
  end
end

function Impl:ShowToolMenu(setup)
  local session = self.toolSession
  if not session or not session.actor or session.phase ~= 'idle' or not session.idleReady
    or setup.toolState ~= 'idle' or not setup.toolReady or self.activeAction
    or session.idleEpoch ~= setup.toolEpoch or session.token ~= setup.toolToken or session.menuPending
    or (self.toolMenuId and lib.getOpenContextMenu() == self.toolMenuId) then return end
  local options = {}
  for key, action in pairs(cfg.actions) do
    if action.tool == session.tool then
      local actionKey = key
      options[#options + 1] = {
        title = action.label,
        onSelect = function()
          local current = self.setups[setup.id]
          if not current or current.toolToken ~= session.token then return end
          session.menuPending = true
          self:EmitNet(self, 'startAction', current.id, current.victim, actionKey)
        end,
      }
    end
  end
  table.sort(options, function(a, b) return a.title < b.title end)
  options[#options + 1] = {
    title = L('tool_exit'), icon = 'fa-solid fa-door-open',
    onSelect = function()
      session.menuPending = true
      self:EmitNet(self, 'exitTool', setup.id, session.token)
    end,
  }
  self.toolMenuId = 'vx_torture_tool_' .. setup.id
  lib.registerContext({
    id = self.toolMenuId, title = cfg.toolLabels[session.tool],
    position = 'top-right', canClose = false, options = options,
  })
  lib.showContext(self.toolMenuId)
end

function Impl:RunActorToolScene(setup, token, stageData, looped)
  local session = self.toolSession
  if not session or session.token ~= token then return false end
  local function fail(reason)
    print(('[vx_torture] tool_scene_failed reason=%s tool=%s phase=%s dict=%s clip=%s token=%s network=%s local=%s')
      :format(reason, session.tool, looped and 'idle' or 'select', stageData.dict,
        stageData.actor, token, self.scene, self.localScene))
    if self.toolSession == session then self:StopStage() end
    return false
  end
  local coords, heading = sceneOrigin(setup)
  if not coords then return fail('scene_origin') end
  local ped = PlayerPedId()
  local chair = stageData.chair and fromNet(setup.props.chair, 700) or nil
  if stageData.chair and (not chair or not requestControl(chair, 1000)) then return fail('chair_control') end
  local sceneProps = {}
  if stageData.tool then sceneProps[session.tool] = { dict = stageData.dict, clip = stageData.tool, required = true } end
  for key, clip in pairs(stageData.props or {}) do
    sceneProps[key] = { dict = stageData.dict, clip = clip, required = true }
  end
  local benchTracks = {}
  if not looped and stageData.bench and loadDict(cfg.layoutDict, 2000)
    and loadDict('missfbi3_weapon_select_trolley', 2000) then
    for key, clip in pairs(stageData.bench) do
      if key ~= 'trolley' and not sceneProps[key] and setup.props[key] then
        benchTracks[key] = clip
      end
    end
  end
  local entities = {}
  for key, track in pairs(sceneProps) do
    local entity = fromNet(setup.props[key], track.required and 700 or 100)
    if entity and requestControl(entity, track.required and 1000 or 200) then
      entities[key] = entity
    elseif track.required then
      return fail('prop_control:' .. key)
    else
      sceneProps[key] = nil
    end
  end
  if self.toolSession ~= session then return false end
  local benchEntities = {}
  for key in pairs(benchTracks) do
    local entity = fromNet(setup.props[key], 100)
    if entity and requestControl(entity, 200) then
      benchEntities[key] = entity
    end
  end
  local attachSelected = looped and not stageData.tool
    and not (stageData.props and stageData.props[session.tool])
  if not looped and not stageData.tool and not (stageData.props and stageData.props[session.tool]) then
    -- Syringe has no separate entity track in the original selection scene.
    self:PutToolBack(setup, session.tool)
  elseif attachSelected then
    local selected = fromNet(setup.props[session.tool], 700)
    if not selected or not requestControl(selected, 1000) then return fail('selected_tool_control') end
  end
  if self.toolSession ~= session then return false end
  self:StopStage(false, true)
  if attachSelected and not self:HoldTool(setup, session.tool) then
    return fail('attach_tool')
  end
  local scene = NetworkCreateSynchronisedScene(
    coords.x, coords.y, coords.z, 0.0, 0.0, heading,
    2, not looped, looped, 1.0, 0.0, 1.0
  )
  if not scene or scene == -1 then return fail('create_scene') end
  self.scene = scene
  self.actorStageActive = true
  self:AddActorTrack(scene, ped, stageData.dict, stageData.actor, looped)
  if chair then
    FreezeEntityPosition(chair, false)
    self.stageChair = chair
    self.stageChairRestore = { coords = setup.positions.chair, heading = setup.heading,
      rotation = setup.rotations and setup.rotations.chair }
    NetworkAddEntityToSynchronisedScene(chair, scene, stageData.dict, stageData.chair,
      8.0, -8.0, (looped or stageData.victimLoop) and 64 or 0)
  end
  for key, entity in pairs(entities) do
    local track = sceneProps[key]
    DetachEntity(entity, true, true)
    FreezeEntityPosition(entity, false)
    NetworkAddEntityToSynchronisedScene(entity, scene, track.dict, track.clip,
      8.0, -8.0, looped and 64 or 0)
  end
  if next(benchEntities) then
    local trolleyClip = cfg.props.trolley.restClip
    local expected = GetAnimInitialOffsetPosition(cfg.layoutDict, trolleyClip,
      coords.x, coords.y, coords.z, 0.0, 0.0, heading, 0.0, 2)
    local trolleyPosition = setup.positions.trolley
    local benchScene = NetworkCreateSynchronisedScene(
      coords.x, coords.y, coords.z + trolleyPosition.z - expected.z,
      0.0, 0.0, heading, 2, false, false, 1.0, 0.0, 1.0)
    if benchScene and benchScene ~= -1 then
      self.benchScene = benchScene
      for key, entity in pairs(benchEntities) do
        DetachEntity(entity, true, true)
        FreezeEntityPosition(entity, false)
        NetworkAddEntityToSynchronisedScene(entity, benchScene,
          'missfbi3_weapon_select_trolley', benchTracks[key], 8.0, -8.0, 0)
      end
      NetworkStartSynchronisedScene(benchScene)
    end
  end
  NetworkStartSynchronisedScene(scene)
  local localScene = self:WaitForActorTrack(scene, ped, stageData.dict, stageData.actor, looped,
    function() return self.toolSession == session and self.scene == scene end)
  if not localScene then
    return fail('actor_start')
  end
  self.localScene = localScene
  local cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
  if not PlaySynchronizedCamAnim(cam, localScene, stageData.camera, stageData.dict) then
    DestroyCam(cam, false)
    return fail('camera_start')
  end
  self:ReplaceSceneCamera(cam)
  if not self:WaitForVictimScene(setup, token, looped and 'idle' or 'select',
    looped and session.idleEpoch or 0, scene, localScene) then
    return fail('peer_ready')
  end
  if looped then
    if session.restoreBench then
      session.restoreBench = nil
      CreateThread(function()
        self:RestoreBench(setup, session.tool, false,
          function() return self.toolSession == session end)
      end)
    end
    return true
  end
  local untilTime = GetGameTimer() + cfg.toolSelectTimeoutMs
  local attached = false
  while self.toolSession == session and session.token == token and self.scene == scene
    and GetGameTimer() < untilTime do
    if not self:ActorTrackRunning(scene) then return fail('actor_track_lost') end
    local phase = GetSynchronizedScenePhase(localScene)
    if stageData.attachAt and not attached and phase >= stageData.attachAt then
      attached = self:HoldTool(setup, session.tool)
      if not attached then return fail('attach_at_phase') end
    end
    if phase >= 0.97 then
      -- Keep the last selection frame/camera through the server round trip.
      -- Idle already owns the selected tool track (or attaches it on entry).
      -- Restoring the other bench props must not block the idle/menu handoff.
      session.restoreBench = true
      return true
    end
    Wait(0)
  end
  return fail('selection_timeout_or_cancelled')
end

function Impl:RunToolExit(setup, token)
  local session = self.toolSession
  if not session or session.token ~= token then return false end
  self:StopStage()
  if not self:HoldTool(setup, session.tool) then return false end
  local trolley = fromNet(setup.props.trolley, 700)
  if not trolley then return false end
  local cameraPos = GetOffsetFromEntityInWorldCoords(trolley,
    cfg.toolExitCameraOffset.x, cfg.toolExitCameraOffset.y, cfg.toolExitCameraOffset.z)
  local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
  SetCamCoord(cam, cameraPos.x, cameraPos.y, cameraPos.z)
  PointCamAtEntity(cam, trolley, 0.0, 0.0, 0.5, true)
  self.camera = cam
  RenderScriptCams(true, true, 500, true, false)
  local point = GetOffsetFromEntityInWorldCoords(trolley,
    cfg.toolReturnOffset.x, cfg.toolReturnOffset.y, cfg.toolReturnOffset.z)
  local ped = PlayerPedId()
  TaskGoStraightToCoord(ped, point.x, point.y, point.z, 1.0, 5000,
    (GetEntityHeading(trolley) + 180.0) % 360.0, 0.2)
  local walkUntil = GetGameTimer() + 5000
  while self.toolSession == session and GetGameTimer() < walkUntil
    and #(GetEntityCoords(ped) - point) > 0.75 do Wait(50) end
  if self.toolSession ~= session then return false end
  local reached = self.toolSession == session and #(GetEntityCoords(ped) - point) <= 0.75
  local returned
  if reached and loadDict('pickup_object', 1500) then
    TaskPlayAnim(ped, 'pickup_object', 'putdown_low', 8.0, -8.0,
      cfg.toolReturnAnimMs, 0, 0.0, false, false, false)
    Wait(math.floor(cfg.toolReturnAnimMs * 0.5))
    if self.toolSession ~= session then return false end
    returned = self:PutToolBack(setup, session.tool)
    Wait(math.ceil(cfg.toolReturnAnimMs * 0.5))
    if self.toolSession ~= session then return false end
  else
    returned = self:PutToolBack(setup, session.tool)
    reached = false
  end
  self:RestoreBench(setup, session.tool, true)
  self:StopStage()
  ClearPedTasks(ped)
  return reached and returned and self.toolSession == session
end

function Impl:RunActorStage(setup, token, key, index)
  local action = cfg.actions[key]
  local stageData = action.stages[index]
  local coords, heading = sceneOrigin(setup)
  if not coords or not self.activeAction or self.activeAction.token ~= token then return false end
  local ped = PlayerPedId()
  local chair = fromNet(setup.props.chair, 500)
  local tool = fromNet(setup.props[action.tool], 500)
  if not chair or not tool then return false end
  local controlledChair = not stageData.chair or requestControl(chair, 1000)
  local sceneProps = {}
  if stageData.tool then sceneProps[action.tool] = stageData.tool end
  for propKey, clip in pairs(stageData.props or {}) do sceneProps[propKey] = clip end
  local propEntities = {}
  for propKey in pairs(sceneProps) do
    local entity = fromNet(setup.props[propKey], 500)
    if not entity or not requestControl(entity, 1000) then return false end
    propEntities[propKey] = entity
  end
  if not controlledChair then return false end
  if not self.activeAction or self.activeAction.token ~= token then return false end
  self:StopStage(false, true)
  local scene = NetworkCreateSynchronisedScene(
    coords.x, coords.y, coords.z, 0.0, 0.0, heading,
    2, true, false, 1.0, 0.0, 1.0
  )
  if scene and scene ~= -1 then
    self.actorStageActive = true
    self.scene = scene
    self:AddActorTrack(scene, ped, stageData.dict, stageData.actor, false)
    if stageData.chair then
      FreezeEntityPosition(chair, false)
      self.stageChair = chair
      self.stageChairRestore = { coords = setup.positions.chair, heading = setup.heading,
        rotation = setup.rotations and setup.rotations.chair }
      NetworkAddEntityToSynchronisedScene(chair, scene, stageData.dict, stageData.chair,
        8.0, -8.0, 0)
    end
    for propKey, clip in pairs(sceneProps) do
      local entity = propEntities[propKey]
      DetachEntity(entity, true, true)
      FreezeEntityPosition(entity, false)
      NetworkAddEntityToSynchronisedScene(entity, scene, stageData.dict, clip,
        8.0, -8.0, 0)
    end
    NetworkStartSynchronisedScene(scene)
    local localScene = self:WaitForActorTrack(scene, ped, stageData.dict, stageData.actor, false,
      function() return self.scene == scene and self.activeAction and self.activeAction.token == token end)
    if localScene then
      self.localScene = localScene
      local camName = stageData.actor:gsub('_player$', '_cam')
      local cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
      if PlaySynchronizedCamAnim(cam, localScene, camName, stageData.dict) then
        self:ReplaceSceneCamera(cam)
      else
        DestroyCam(cam, false)
        self:StopStage()
        self:HoldTool(setup, action.tool)
        return false
      end
      if not self:WaitForVictimScene(setup, token, 'action', index, scene, localScene) then
        if self.scene == scene then self:StopStage() end
        return false
      end
      local untilTime = GetGameTimer() + math.min(cfg.stageTimeoutMs, stageData.durationMs + 2500)
      while self.activeAction and self.activeAction.token == token
        and GetGameTimer() < untilTime do
        if not self:ActorTrackRunning(scene) then
          self:StopStage()
          return false
        end
        if GetSynchronizedScenePhase(localScene) >= 0.97 then
          return true -- hold this frame until the next stage/idle is prepared
        end
        Wait(0)
      end
      if not self.activeAction or self.activeAction.token ~= token then return false end
      self:StopStage()
      self:HoldTool(setup, action.tool)
      return false
    end
    if not self.activeAction or self.activeAction.token ~= token then return false end
    self:StopStage()
    self:HoldTool(setup, action.tool)
  end
  if self.activeAction and self.activeAction.token == token then self:StopStage() end
  return false
end

function Impl:StopEffectSounds(token)
  local sounds = self.activeSounds[token]
  if not sounds then return end
  self.activeSounds[token] = nil
  for _, soundId in ipairs(sounds) do
    StopSound(soundId)
    ReleaseSoundId(soundId)
  end
  ReleaseScriptAudioBank()
end

function Impl:PlayEffect(setup, token, key, index)
  local stageData = cfg.actions[key].stages[index]
  local effect = stageData.effect
  if not effect then return end
  local chair = fromNet(setup.props.chair, 300)
  if not chair or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(chair)) > cfg.observerFxDistance then return end
  local entity = chair
  if setup.victim then
    local player = GetPlayerFromServerId(setup.victim)
    if player ~= -1 then entity = GetPlayerPed(player) end
  end
  if effect.particle then
    RequestNamedPtfxAsset('scr_fbi3')
    local untilTime = GetGameTimer() + 2000
    while not HasNamedPtfxAssetLoaded('scr_fbi3') and GetGameTimer() < untilTime do Wait(0) end
    if HasNamedPtfxAssetLoaded('scr_fbi3') then
      UseParticleFxAssetNextCall('scr_fbi3')
      StartParticleFxNonLoopedOnEntity(effect.particle, entity,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end
  end
  if effect.sound and effect.bank and RequestScriptAudioBank(effect.bank, false) then
    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, effect.sound, chair, effect.soundset or 'FBI_03_Torture_Sounds', false, 0)
    self.activeSounds[token] = self.activeSounds[token] or {}
    self.activeSounds[token][#self.activeSounds[token] + 1] = soundId
    SetTimeout(math.min(stageData.durationMs, 5000), function()
      local sounds = self.activeSounds[token]
      if not sounds then return end
      for i, id in ipairs(sounds) do
        if id == soundId then
          StopSound(id)
          ReleaseSoundId(id)
          table.remove(sounds, i)
          if #sounds == 0 then
            self.activeSounds[token] = nil
            ReleaseScriptAudioBank()
          end
          break
        end
      end
    end)
  end
end

function Impl:EndPreview(token, tellServer)
  local preview = self.preview
  if not preview or (token and preview.token ~= token) then return end
  self.preview = nil
  if preview.textShown then
    local open, currentText = lib.isTextUIOpen()
    if open and currentText == L('preview_help') then lib.hideTextUI() end
  end
  for _, entity in pairs(preview.objects) do
    if DoesEntityExist(entity) then DeleteEntity(entity) end
  end
  if tellServer then self:EmitNet(self, 'cancelPlacement', preview.token) end
end

function Impl:StartPreview(token)
  if self.preview then self:EndPreview(nil, true) end
  local preview = { token = token, objects = {}, bounds = {}, clips = {} }
  self.preview = preview
  CreateThread(function()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
      self:EndPreview(token, true)
      return notify('invalid_state')
    end
    if not loadDict(cfg.layoutDict, 4000)
      or not loadDict(cfg.seatAlignment.dict, 4000) then
      self:EndPreview(token, true)
      return previewFailed('scene_dict')
    end
    for _, key in ipairs(cfg.propOrder) do
      if self.preview ~= preview then return end
      local prop = cfg.props[key]
      if prop.restClip then
        -- The FBI3 weapon-select object tracks can be static. Their initial
        -- transform is usable even when GET_ANIM_DURATION reports zero.
        preview.clips[key] = true
      end
      local model = joaat(prop.model)
      if loadModel(model, 4000) then
        local min, max = GetModelDimensions(model)
        local here = GetEntityCoords(ped)
        local entity = CreateObjectNoOffset(model, here.x, here.y, here.z - 5.0,
          false, false, false)
        if entity ~= 0 and DoesEntityExist(entity) then
          preview.objects[key] = entity
          setDisplayRotation(entity, GetEntityHeading(ped), prop)
          local verticalMin, verticalMax = verticalBounds(entity, min, max)
          preview.bounds[key] = {
            min = min, max = max, verticalMin = verticalMin, verticalMax = verticalMax,
          }
          SetEntityCollision(entity, false, false)
          SetEntityAlpha(entity, cfg.previewAlpha, false)
          FreezeEntityPosition(entity, true)
        elseif prop.required then
          SetModelAsNoLongerNeeded(model)
          self:EndPreview(token, true)
          return previewFailed(key .. ':create_object')
        else
          preview.bounds[key] = nil
        end
        SetModelAsNoLongerNeeded(model)
      elseif prop.required then
        self:EndPreview(token, true)
        return previewFailed(key .. ':load_model')
      end
    end
    if self.preview ~= preview then return end
    lib.showTextUI(L('preview_help'))
    preview.textShown = true
    local expiresAt = GetGameTimer() + cfg.placementTimeoutMs
    while self.preview == preview do
      ped = PlayerPedId()
      if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or GetGameTimer() >= expiresAt then
        self:EndPreview(token, true)
        break
      end
      local placement = placementLayout(ped, preview.bounds, preview.clips, preview.objects)
      if not placement then
        self:EndPreview(token, true)
        return previewFailed('scene_alignment')
      end
      for key, entity in pairs(preview.objects) do
        local position = placement.positions[key]
        if position then
          SetEntityCoordsNoOffset(entity, position.x, position.y, position.z,
            false, false, false)
          setDisplayRotation(entity, placement.heading, cfg.props[key], placement.rotations[key])
        end
      end
      DisableControlAction(0, 38, true)
      if IsDisabledControlJustPressed(0, 38) then
        self:EndPreview(token, false)
        self:EmitNet(self, 'confirmPlacement', token, placement)
        break
      end
      if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) then
        self:EndPreview(token, true)
        break
      end
      Wait(0)
    end
  end)
end

function Impl:Init()
  self.setups = {}
  self.removed = {}
  self.targets = {}
  self.seated = nil
  self.previousInvBusy = nil
  self.activeAction = nil
  self.scene = nil
  self.localScene = nil
  self.victimScene = nil
  self.victimMasterScene = nil
  self.victimSceneStarting = false
  self.nextSeatRecoveryAt = 0
  self.peerScene = nil
  self.benchScene = nil
  self.camera = nil
  self.stageChair = nil
  self.actorStageActive = false
  self.activeSounds = {}
  self.toolSession = nil
  self.toolMenuId = nil
  self.nextToolHealthAt = 0
  self.preview = nil
end

function Impl:OnReady()
  RegisterCommand('vx_torture_diag', function() self:PrintSceneDiagnostics() end, false)
  self:OnNet('victimSceneReady', function(token, kind, step, scene, success)
    local pending = self.peerScene
    if pending and pending.token == token and pending.kind == kind
      and pending.step == step and pending.scene == scene then pending.ready = success == true end
  end)
  self:OnNet('joinVictimScene', function(setup, token, kind, step, scene, stageData, looped)
    if setup.victim ~= playerSource() or self.seated ~= setup.id then return end
    local function current()
      if self.seated ~= setup.id then return false end
      if kind == 'action' then
        local active = self.activeAction
        return active and active.token == token and active.stage == step
      end
      local session = self.toolSession
      return session and session.token == token
        and (kind == 'select' and session.phase == 'select'
          or kind == 'idle' and session.idleEpoch == step)
    end
    CreateThread(function()
      local readyUntil = GetGameTimer() + 1500
      while not current() and self.seated == setup.id and GetGameTimer() < readyUntil do Wait(0) end
      if not current() then
        self:EmitNet(self, 'victimSceneReady', setup.id, token, kind, step, scene, false)
        return
      end
      local session = self.toolSession
      local success = self:JoinVictimScene(setup, stageData, scene, looped, current)
      self:EmitNet(self, 'victimSceneReady', setup.id, token, kind, step, scene, success == true)
      if not current() then return end
      if kind == 'idle' then
        session.idleReady = success == true
        if success then session.phase = 'idle' end
        self:EmitNet(self, 'toolIdleReady', setup.id, token, step, success == true)
      elseif not success then
        if kind == 'action' then self:EmitNet(self, 'stageFailed', setup.id, token, step)
        else self:EmitNet(self, 'toolSceneFailed', setup.id, token) end
      end
    end)
  end)
  self:OnNet('beginPlacement', function(token) self:StartPreview(token) end)
  self:OnNet('cancelPreview', function(token) self:EndPreview(token, false) end)
  self:OnNet('notify', function(key)
    notify(key)
    if key == 'invalid_state' and self.toolSession then
      local setup = self.setups[self.toolSession.setupId]
      if setup and setup.toolState == 'idle' and setup.toolReady then
        self.toolSession.menuPending = false
        self:ShowToolMenu(setup)
      end
    end
  end)
  self:OnNet('setupUpdated', function(setup) self:UpdateSetup(setup) end)
  self:OnNet('setupRemoved', function(setupId)
    self.removed[setupId] = true
    local setup = self.setups[setupId]
    if not setup then return end
    if self.toolSession and self.toolSession.setupId == setupId then
      self:EndToolSession(setup)
    end
    if self.seated == setupId then self:ReleaseSeat(setupId) end
    if self.activeAction and self.activeAction.setupId == setupId then
      self.activeAction = nil
      self:StopStage()
    end
    self:RemoveTargets(setup)
    self.setups[setupId] = nil
  end)
  self:OnNet('prepareTool', function(setup, token)
    if self.toolSession then
      return self:EmitNet(self, 'readyTool', setup.id, token, false)
    end
    local toolScenes = cfg.toolScenes[setup.tool]
    if not toolScenes then return self:EmitNet(self, 'readyTool', setup.id, token, false) end
    local actor = setup.owner == playerSource()
    if not actor and self.seated ~= setup.id then
      return self:EmitNet(self, 'readyTool', setup.id, token, false)
    end
    local session = { setupId = setup.id, token = token, tool = setup.tool,
      actor = actor, phase = 'prepare', menuPending = false }
    self.toolSession = session
    CreateThread(function()
      local ready = fromNet(setup.props.chair, 2000) ~= nil
        and fromNet(setup.props.trolley, 2000) ~= nil
        and fromNet(setup.props[setup.tool], 2000) ~= nil
      if not actor then
        ready = ready and self.seated == setup.id
      else
        local victimPlayer = GetPlayerFromServerId(setup.victim)
        ready = ready and victimPlayer ~= -1 and DoesEntityExist(GetPlayerPed(victimPlayer))
      end
      if ready then
        for _, scene in pairs(toolScenes) do
          if not loadDict(scene.dict, 3000)
            or GetAnimDuration(scene.dict, scene.actor) <= 0.0
            or GetAnimDuration(scene.dict, scene.victim) <= 0.0 then
            ready = false
            break
          end
          for key in pairs(scene.props or {}) do
            if not setup.props[key] or not fromNet(setup.props[key], 300) then
              ready = false
              break
            end
          end
          if not ready then break end
        end
      end
      if self.toolSession ~= session then return end
      if ready and not actor and not self.victimScene then ready = self:PlayIdle(setup) end
      self:EmitNet(self, 'readyTool', setup.id, token, ready)
      if not ready then self:EndToolSession(setup) end
    end)
  end)
  self:OnNet('playToolSelect', function(setup, token)
    local session = self.toolSession
    if not session or session.token ~= token then return end
    session.phase = 'select'
    local selectScene = cfg.toolScenes[session.tool].select
    if not session.actor then return end -- joined through the actor's scene id
    CreateThread(function()
      local success = self:RunActorToolScene(setup, token, selectScene, false)
      self:EmitNet(self, 'toolSelected', setup.id, token, success == true)
    end)
  end)
  self:OnNet('startToolIdle', function(setup, token, epoch)
    local session = self.toolSession
    if not session or session.token ~= token then return end
    if session.idleEpoch and epoch <= session.idleEpoch then return end
    session.idleEpoch = epoch
    session.phase = 'startingIdle'
    session.idleReady = false
    session.menuPending = false
    local idleScene = cfg.toolScenes[session.tool].idle
    if not session.actor then return end -- readiness is sent after joining
    CreateThread(function()
      local success = self:RunActorToolScene(setup, token, idleScene, true)
      if self.toolSession == session then
        session.idleReady = success == true
        if success then session.phase = 'idle' end
        self:EmitNet(self, 'toolIdleReady', setup.id, token, epoch, success == true)
        local current = self.setups[setup.id]
        if success and current then self:ShowToolMenu(current) end
      end
    end)
  end)
  self:OnNet('playToolExit', function(setup, token)
    local session = self.toolSession
    if not session or session.token ~= token or not session.actor then return end
    session.phase = 'exit'
    if self.toolMenuId and lib.getOpenContextMenu() == self.toolMenuId then
      lib.hideContext(false)
    end
    CreateThread(function()
      local success = self:RunToolExit(setup, token)
      self:EmitNet(self, 'toolExited', setup.id, token, success == true)
    end)
  end)
  self:OnNet('restoreToolVictim', function(setupId, token)
    local session = self.toolSession
    if session and session.setupId == setupId and session.token == token
      and self.seated == setupId then
      session.phase = 'exit'
      local setup = self.setups[setupId]
      if setup then self:PlayIdle(setup) end
    end
  end)
  self:OnNet('stopTool', function(setupId, token)
    local session = self.toolSession
    if session and session.setupId == setupId and session.token == token then
      local setup = self.setups[setupId]
      if setup then self:EndToolSession(setup) end
    end
  end)
  self:OnNet('seat', function(setup)
    if self.seated or IsEntityDead(PlayerPedId()) or IsPedInAnyVehicle(PlayerPedId(), false) then
      return self:EmitNet(self, 'seatReady', setup.id, false)
    end
    self.seated = setup.id
    self.previousInvBusy = LocalPlayer.state.invBusy
    LocalPlayer.state.invBusy = true
    if not self:PlayIdle(setup) then
      self:ReleaseSeat(setup.id)
      return self:EmitNet(self, 'seatReady', setup.id, false)
    end
    Wait(250)
    local position = GetEntityCoords(PlayerPedId())
    local chair = setup.positions and setup.positions.chair
    local distanceSq = chair and ((position.x - chair.x) ^ 2 + (position.y - chair.y) ^ 2)
    local aligned = distanceSq and distanceSq <= cfg.seatAlignment.maxDistance ^ 2
      and IsEntityPlayingAnim(PlayerPedId(), cfg.seatAlignment.dict, cfg.seatAlignment.victim, 3)
    if not aligned then
      if Config.Debug then print(('[vx_torture] seat alignment failed: %.2f m'):format(
        distanceSq and math.sqrt(distanceSq) or -1.0)) end
      self:ReleaseSeat(setup.id)
      return self:EmitNet(self, 'seatReady', setup.id, false)
    end
    self:EmitNet(self, 'seatReady', setup.id, true)
  end)
  self:OnNet('releaseSeat', function(setupId) self:ReleaseSeat(setupId) end)
  self:OnNet('prepareAction', function(setup, token, key)
    local action = cfg.actions[key]
    if not action or self.activeAction then
      return self:EmitNet(self, 'readyAction', setup.id, token, false)
    end
    CreateThread(function()
      local ready = fromNet(setup.props.chair, 2000) ~= nil
      if ready then
        for _, stageData in ipairs(action.stages) do
          if not loadDict(stageData.dict, 3000)
            or GetAnimDuration(stageData.dict, stageData.actor) <= 0.0
            or GetAnimDuration(stageData.dict, stageData.victim) <= 0.0
            or (stageData.chair and GetAnimDuration(stageData.dict, stageData.chair) <= 0.0)
            or (stageData.tool and GetAnimDuration(stageData.dict, stageData.tool) <= 0.0) then
            ready = false
            break
          end
          for propKey, clip in pairs(stageData.props or {}) do
            if not setup.props[propKey] or GetAnimDuration(stageData.dict, clip) <= 0.0 then
              ready = false
              break
            end
          end
          if not ready then break end
        end
      end
      if ready then
        self.activeAction = {
          setupId = setup.id, token = token, key = key,
          actor = setup.owner == playerSource(),
          expiresAt = GetGameTimer() + (#action.stages * cfg.stageTimeoutMs) + cfg.prepareTimeoutMs,
        }
      end
      self:EmitNet(self, 'readyAction', setup.id, token, ready)
    end)
  end)
  self:OnNet('playStage', function(setup, token, key, index)
    local active = self.activeAction
    if not active or active.token ~= token or active.setupId ~= setup.id then return end
    local stageData = cfg.actions[key] and cfg.actions[key].stages[index]
    if not stageData then return end
    active.stage = index
    if active.actor then
      CreateThread(function()
        local success = self:RunActorStage(setup, token, key, index)
        self:EmitNet(self, 'stageDone', setup.id, token, index, success == true)
      end)
    end
  end)
  self:OnNet('stageEffect', function(setup, token, key, index)
    CreateThread(function() self:PlayEffect(setup, token, key, index) end)
  end)
  self:OnNet('stopEffects', function(token) self:StopEffectSounds(token) end)
  self:OnNet('stopAction', function(setupId, token, resumeIdle)
    self:StopEffectSounds(token)
    if not self.activeAction or self.activeAction.token ~= token then return end
    local actionKey = self.activeAction.key
    self.activeAction = nil
    if resumeIdle and self.toolSession and self.toolSession.setupId == setupId then
      self.toolSession.phase = 'startingIdle'
      self.toolSession.idleReady = false
      return -- next idle replaces the held action directly on both clients
    end
    self:StopStage(self.seated == setupId)
    local setup = self.setups[setupId]
    if setup and setup.owner == playerSource() and not self.toolSession
      and cfg.actions[actionKey] and cfg.actions[actionKey].tool == 'waterboard' then
      CreateThread(function() self:PutPropBack(setup, 'rag') end)
    end
    if setup and setup.owner == playerSource() and setup.tool and not self.toolSession then
      CreateThread(function() self:HoldTool(setup, setup.tool) end)
    elseif setup and self.seated == setupId then
      -- Stay seated between the stopped action and the next shared idle scene.
      -- During a tool session the actor remains responsible for the chair.
      self:PlayIdle(setup)
    end
  end)
  self:OnNet('applyDamage', function(setupId, amount)
    if self.seated ~= setupId or type(amount) ~= 'number' then return end
    local ped = PlayerPedId()
    if not IsEntityDead(ped) and not LocalPlayer.state.isDead then
      SetEntityHealth(ped, math.max(101, GetEntityHealth(ped) - amount))
    end
  end)
  self:OnNet('killVictim', function(setupId)
    if self.seated == setupId then self:ReleaseSeat(setupId) end
    if not LocalPlayer.state.isDead then exports.qbx_medical:KillPlayer() end
  end)
  CreateThread(function()
    local ok, snapshots = pcall(function() return self:Callback(self, 'getSetups') end)
    if ok and type(snapshots) == 'table' then
      for _, setup in ipairs(snapshots) do self:UpdateSetup(setup) end
    end
  end)
  self:Interval('targetSync', 1000, function()
    for _, setup in pairs(self.setups) do
      self:ApplyPropCollision(setup)
      self:AddTargets(setup)
    end
  end)
  if Config.Debug then
    self:Interval('toolTargetDebug', 0, function()
      local setup = self:MySetup()
      if not setup or #(GetEntityCoords(PlayerPedId()) - setup.coords) > 6.0 then
        Wait(250)
        return
      end
      for _, tool in ipairs(cfg.toolOrder) do
        if tool ~= setup.tool and targetReady(setup.props[tool]) then
          local position = toolTargetPosition(setup, tool)
          if position then
            DrawMarker(28, position.x, position.y, position.z, 0.0, 0.0, 0.0,
              0.0, 0.0, 0.0, 0.14, 0.14, 0.14, 255, 170, 0, 180,
              false, false, 2, false, nil, nil, false)
          end
        end
      end
    end)
  end
  self:Interval('seatControl', 0, function()
    if self.activeAction and GetGameTimer() > self.activeAction.expiresAt then
      self.activeAction = nil
      self:StopStage()
    end
    local session = self.toolSession
    if session and session.phase == 'idle' and not self.activeAction
      and GetGameTimer() >= self.nextToolHealthAt then
      self.nextToolHealthAt = GetGameTimer() + 500
      local setup = self.setups[session.setupId]
      if setup and setup.toolState == 'idle' and setup.toolReady then
        local idle = cfg.toolScenes[session.tool].idle
        local clip = session.actor and idle.actor or idle.victim
        local healthy = targetReady(setup.props.chair)
          and targetReady(setup.props[session.tool])
          and IsEntityPlayingAnim(PlayerPedId(), idle.dict, clip, 3)
        if session.actor then
          healthy = healthy and self.localScene and IsSynchronizedSceneRunning(self.localScene)
        else
          healthy = healthy and self.victimScene and self.victimMasterScene
            and #(GetEntityCoords(PlayerPedId()) - setup.positions.chair)
              <= cfg.seatAlignment.maxDistance + 0.8
        end
        if session.actor then
          healthy = healthy and self.camera and DoesCamExist(self.camera)
        elseif self.seated ~= setup.id then
          healthy = false
        end
        for key in pairs(idle.props or {}) do
          healthy = healthy and targetReady(setup.props[key])
        end
        if not healthy then
          self:EmitNet(self, 'toolSceneFailed', setup.id, session.token)
          self:EndToolSession(setup)
        elseif session.actor then
          -- Also handles a ready snapshot arriving before the local startup
          -- coroutine has returned. The menu never stops the looping scene.
          self:ShowToolMenu(setup)
        end
      end
    end
    if not self.seated and not (self.activeAction and self.activeAction.actor)
      and not (self.toolSession and self.toolSession.actor) then
      Wait(200)
      return
    end
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    local activeSetup = self.setups[self.seated or (self.toolSession and self.toolSession.setupId)]
    if activeSetup then
      for _, key in ipairs({ 'chair', 'trolley', 'stool' }) do
        if targetReady(activeSetup.props[key]) then
          SetEntityNoCollisionEntity(PlayerPedId(), NetworkGetEntityFromNetworkId(activeSetup.props[key]), true)
        end
      end
    end
    if not self.seated then return end
    local setup = self.setups[self.seated]
    if setup and not self.activeAction and not self.toolSession
      and not self.victimSceneStarting
      and GetGameTimer() >= (self.nextSeatRecoveryAt or 0)
      and not LocalPlayer.state.isDead and not IsEntityDead(PlayerPedId())
      and not IsEntityPlayingAnim(PlayerPedId(), cfg.seatAlignment.dict, cfg.seatAlignment.victim, 3) then
      self:PlayIdle(setup)
    end
  end)
end

function Impl:OnDestroy()
  self:EndPreview(nil, false)
  self.activeAction = nil
  for token in pairs(self.activeSounds) do self:StopEffectSounds(token) end
  if self.toolSession then
    local setup = self.setups[self.toolSession.setupId]
    if setup then self:EndToolSession(setup) end
  end
  self:StopStage()
  if self.seated then self:ReleaseSeat(self.seated) end
  for _, setup in pairs(self.setups) do self:RemoveTargets(setup) end
end

function Impl:OnResourceStop()
  self:OnDestroy()
end
