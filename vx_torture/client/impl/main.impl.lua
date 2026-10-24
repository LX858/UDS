---@class MainImpl : Impl
local Impl = NewImpl('Main')
local cfg = Config.Torture
local SCENE_DONT_INTERRUPT, SCENE_HIDE_WEAPON = 4, 1024
local SCENE_ABORT_ON_DEATH, SCENE_LOOP_WITHIN_SCENE = 2048, 64
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

local function nativeTrue(value)
  return value == true or (type(value) == 'number' and value ~= 0)
end

-- One identity for preparation, playback and completion. Engine scene IDs may
-- be reused; a coroutine must own this object before changing tasks or props.
function Impl:BeginSceneRun(setup, token, kind, step, data)
  self.runGeneration = (self.runGeneration or 0) + 1
  local previous = self.sceneRun
  if previous then previous.previous = nil end
  local run = { previous = previous, setup = setup, token = token, kind = kind, step = step,
    data = data, generation = self.runGeneration, startedAt = GetGameTimer() }
  self.sceneRun = run
  self:TraceScene('prepare', run)
  return run
end

function Impl:SceneCurrent(run)
  return run ~= nil and self.sceneRun == run
end

function Impl:ExpectScene(token, kind, step)
  local run = self.sceneRun
  -- A join event may precede its phase command. Preserve that pending join;
  -- retire only the previous scene's monitor while the successor is prepared.
  if run and run.token == token and run.kind == kind and run.step == step then return end
  self.sceneRun = nil
  self.victimJoin = nil
end

function Impl:TraceScene(event, run, reason)
  if not cfg.sceneDiagnostics or not run then return end
  print(('[vx_torture] scene_v16 event=%s setup=%s token=%s kind=%s step=%s generation=%s scene=%s elapsed=%s reason=%s')
    :format(event, run.setup.id, run.token, run.kind, run.step, run.generation,
      run.scene, GetGameTimer() - run.startedAt, reason or '-'))
end

function Impl:SampleScene(run)
  if not cfg.sceneDiagnostics or not run then return end
  local now = GetGameTimer()
  if now < (run.nextSample or 0) then return end
  run.nextSample = now + 100
  local player = GetPlayerFromServerId(run.setup.owner)
  local actor = player ~= -1 and GetPlayerPed(player) or 0
  local handle = run.scene and NetworkGetLocalSceneFromNetworkId(run.scene)
  local root, heading = run.origin, run.heading
  self.sceneSamples = self.sceneSamples or {}
  local samples = self.sceneSamples
  samples[#samples + 1] = { time = now, token = run.token, kind = run.kind,
    step = run.step, generation = run.generation, networkScene = run.scene,
    localScene = handle, root = root, heading = heading,
    elapsed = now - run.startedAt, dict = run.data.dict, clip = run.data.actor,
    phase = handle and handle >= 0 and GetSynchronizedScenePhase(handle) or nil,
    running = handle and handle >= 0 and nativeTrue(IsSynchronizedSceneRunning(handle)) or false,
    actor = actor ~= 0 and DoesEntityExist(actor) and {
      position = GetEntityCoords(actor), visible = IsEntityVisible(actor),
      alpha = GetEntityAlpha(actor), owner = NetworkGetEntityOwner(actor),
      playing = nativeTrue(IsEntityPlayingAnim(actor, run.data.dict, run.data.actor, 3)),
    } or nil, localPosition = GetEntityCoords(PlayerPedId()) }
  while #samples > 50 or (#samples > 0 and now - samples[1].time > 5000) do table.remove(samples, 1) end
end

function Impl:DumpSceneTrace(reason)
  if not cfg.sceneDiagnostics then return end
  print('[vx_torture] scene_trace ' .. json.encode({ version = 16,
    gameBuild = GetGameBuildNumber(), role = self.seated and 'victim' or 'actor', reason = reason }))
  for _, sample in ipairs(self.sceneSamples or {}) do
    if GetGameTimer() - sample.time <= 5000 then
      print('[vx_torture] scene_sample ' .. json.encode(sample))
    end
  end
end

-- Return live separately from tolerated: a transient failure must never count
-- as a completed animation, even while the grace period prevents cancellation.
function Impl:TrackHealth(track, healthy, fatal)
  local now = GetGameTimer()
  if fatal then return false, false end
  if healthy then track.lostAt = nil; return true, true end
  track.lostAt = track.lostAt or now
  return now - track.lostAt < cfg.remoteTrackGraceMs, false
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
      if nativeTrue(IsSynchronizedSceneRunning(localScene))
        and nativeTrue(IsEntityPlayingAnim(ped, dict, clip, 3)) then
        return localScene
      end
    end
    Wait(0)
  until GetGameTimer() >= expires
  print(('[vx_torture] Scene did not start: %s / %s (network=%s, local=%s)')
    :format(dict, clip, scene, localScene))
  return nil
end

function Impl:AddActorTrack(scene, ped, dict, clip, looped, origin, heading)
  -- Register the owning player BEFORE NetworkStartSynchronisedScene. The
  -- local handle is only used for phase/camera; do not inject a local task
  -- into the network scene after it starts.
  -- DONT_INTERRUPT blocks ambient events, not scripted successor tasks.
  -- Stop/replace tasks explicitly at the stage boundary.
  local flags = SCENE_DONT_INTERRUPT | SCENE_HIDE_WEAPON | SCENE_ABORT_ON_DEATH
    | (looped and SCENE_LOOP_WITHIN_SCENE or 0)
  local blend = (looped or GetAnimDuration(dict, clip) >= 1.0) and cfg.actorBlendSpeed or 8.0
  NetworkAddPedToSynchronisedScene(ped, scene, dict, clip,
    blend, -blend, flags, 0, 1000.0, 0)
  self.actorTrack = { scene = scene, dict = dict, clip = clip, looped = looped,
    origin = origin, heading = heading, startedAt = GetGameTimer() }
end

function Impl:ActorTrackRunning(scene)
  local track = self.actorTrack
  if not track or track.scene ~= scene or self.scene ~= scene then return false, false end
  local now = GetGameTimer()
  if nativeTrue(IsEntityDead(PlayerPedId())) then return false, false end
  if now < (track.nextHealthAt or 0) then return track.healthy, track.live end
  track.nextHealthAt = now + 100
  local run = self.sceneRun
  if run and (not targetReady(run.setup.props.chair)
    or not targetReady(run.setup.props[run.setup.tool])) then return false, false end
  local live = self.localScene and nativeTrue(IsSynchronizedSceneRunning(self.localScene))
    and nativeTrue(IsEntityPlayingAnim(PlayerPedId(), track.dict, track.clip, 3))
  track.healthy, track.live = self:TrackHealth(track, live)
  if not track.healthy and not track.reported then
    track.reported = true
    self:TraceScene('failed', self.sceneRun, 'actor_track_lost')
    self:DumpSceneTrace('actor_track_lost')
  end
  return track.healthy, track.live
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

function Impl:ApplyPropCollision(setup)
  if #(GetEntityCoords(PlayerPedId()) - setup.coords) > 45.0 then return end
  local resting = setup.toolState == 'empty'
    and not (self.toolSession and self.toolSession.setupId == setup.id)
    and not (self.activeAction and self.activeAction.setupId == setup.id)
  for _, key in ipairs(cfg.propOrder) do
    if targetReady(setup.props[key]) then
      local entity = NetworkGetEntityFromNetworkId(setup.props[key])
      if key ~= 'chair' and key ~= 'trolley' then SetEntityCollision(entity, false, false) end
      -- Reapply on streaming/ownership changes. Furniture never joins a scene;
      -- chair and tools are unlocked only by their owning scene controller.
      if key == 'trolley' or key == 'stool' or key == 'ecg'
        or (resting and NetworkHasControlOfEntity(entity)) then
        FreezeEntityPosition(entity, true)
      end
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
          if cfg.toolScenes[tool] then
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
  FreezeEntityPosition(entity, true)
  DetachEntity(entity, true, true)
  SetEntityCoordsNoOffset(entity, position.x, position.y, position.z, false, false, false)
  setDisplayRotation(entity, setup.heading, cfg.props[key], setup.rotations and setup.rotations[key])
  return true
end

function Impl:PutToolBack(setup, tool, current)
  local returned = self:PutPropBack(setup, tool, current)
  local hand = cfg.toolHand[tool]
  if hand and hand.companion then
    returned = self:PutPropBack(setup, hand.companion.key, current) and returned
  end
  return returned
end

function Impl:HoldTool(setup, tool, current)
  local entity = fromNet(setup.props[tool], 2500)
  local hand = cfg.toolHand[tool]
  if not entity or not hand or not requestControl(entity, 1500) then return false end
  local companion = hand.companion and fromNet(setup.props[hand.companion.key], 2500)
  if hand.companion and (not companion or not requestControl(companion, 1500)) then return false end
  if current and not current() then return false end
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
  if setup.owner == playerSource() and session.tool and not cfg.props[session.tool].onDemand then
    local generation = self.runGeneration
    CreateThread(function()
      local function current() return not self.toolSession and self.runGeneration == generation end
      for _ = 1, 3 do
        if not current() then return end
        if self:PutToolBack(setup, session.tool, current) then break end
        Wait(250)
      end
      self:RestoreBench(setup, session.tool, true, current)
    end)
  elseif returnToSeat then
    local restored = self:PlayIdle(setup)
    if not restored and self.seated == setup.id and not self.toolSession then
      self:EmitNet(self, 'seatRecoveryFailed', setup.id, session.token)
      self:ReleaseSeat(setup.id)
    end
  end
end

-- FBI3 f_23 tracks are local to the hand bone, unlike weapon-select tracks.
function Impl:StartHandProps(setup, stageData, looped, localScene, current)
  self.handPropTracks = {}
  for key, clip in pairs(stageData.handProps or {}) do
    local entity = fromNet(setup.props[key], 500)
    if current and not current() then return false end
    if not entity or not IsEntityAttachedToEntity(entity, PlayerPedId()) then return false end
    local phase = GetSynchronizedScenePhase(localScene)
    if not nativeTrue(PlayEntityAnim(entity, clip, stageData.dict, 8.0,
      looped, not looped, false, phase, 0)) then return false end
    self.handPropTracks[#self.handPropTracks + 1] = { entity = entity, dict = stageData.dict, clip = clip }
  end
  return true
end

function Impl:SyncHandProps()
  if not self.localScene then return true end
  for _, track in ipairs(self.handPropTracks or {}) do
    if not DoesEntityExist(track.entity) or not IsEntityAttachedToEntity(track.entity, PlayerPedId()) then return false end
    -- Use the actor clock for the attached object's internal animation too.
    SetEntityAnimCurrentTime(track.entity, track.dict, track.clip, GetSynchronizedScenePhase(self.localScene))
  end
  return true
end

function Impl:StaticChair(setup, current)
  local chair = fromNet(setup.props.chair, 500)
  if not chair or not requestControl(chair, 1000) then return false end
  if current and not current() then return false end
  local pos = setup.positions.chair
  SetEntityCoordsNoOffset(chair, pos.x, pos.y, pos.z, false, false, false)
  setDisplayRotation(chair, setup.heading, cfg.props.chair, setup.rotations and setup.rotations.chair)
  FreezeEntityPosition(chair, true)
  self.stageChair = nil
  self.stageChairRestore = nil
  return true
end

function Impl:ValidateSceneAssets(setup, stageData, current)
  if not loadDict(stageData.dict, 3000) then return false end
  if current and not current() then return false end
  local clips = { actor = stageData.actor, victim = stageData.victim,
    chair = stageData.chair, tool = stageData.tool,
    camera = stageData.camera or stageData.actor:gsub('_player$', '_cam') }
  for role, clip in pairs(clips) do
    if GetAnimDuration(stageData.dict, clip) <= 0.0 then
      print(('[vx_torture] missing_scene_clip role=%s dict=%s clip=%s'):format(role, stageData.dict, clip))
      return false
    end
  end
  for _, tracks in ipairs({ stageData.props or {}, stageData.handProps or {} }) do
    for key, clip in pairs(tracks) do
      if current and not current() then return false end
      if not setup.props[key] or not fromNet(setup.props[key], 300)
        or GetAnimDuration(stageData.dict, clip) <= 0.0 then
        print(('[vx_torture] missing_prop_clip prop=%s dict=%s clip=%s'):format(key, stageData.dict, clip))
        return false
      end
    end
  end
  return true
end

function Impl:UpdateSetup(setup)
  if self.removed[setup.id] then return end
  local old = self.setups[setup.id]
  if old and old.revision and setup.revision and old.revision > setup.revision then return end
  local session = self.toolSession
  -- prepare/select/idle carry authoritative snapshots too. A broadcast from
  -- before that command must not clear the newly prepared session.
  if session and session.setupId == setup.id and session.revision
    and setup.revision and setup.revision < session.revision then return end
  self.setups[setup.id] = setup
  for token, run in pairs(self.activeEffects) do
    if run.setup.id == setup.id and (run.setup.victim ~= setup.victim or not setup.seatReady) then
      self:StopEffectSounds(token)
    end
  end
  self:ApplyPropCollision(setup)
  self:AddTargets(setup)
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

function Impl:StopRetiredScenes(protectedScene)
  local retired = self.retiredScenes
  self.retiredScenes = nil
  local stopped = {}
  for _, scene in ipairs(retired or {}) do
    if scene == protectedScene then
      -- Finite bench scenes may have already ended and freed their engine ID.
      -- The successor can reuse that ID even while it is still in this list.
      -- Do not query/mutate/stop the newly reserved scene through the stale ID.
      if cfg.sceneDiagnostics then
        print(('[vx_torture] scene_retire_skip network=%s reason=reserved_successor'):format(scene))
      end
    elseif not stopped[scene] then
      stopped[scene] = true
      local localScene = NetworkGetLocalSceneFromNetworkId(scene)
      if localScene and localScene >= 0 then
        SetSynchronizedSceneHoldLastFrame(localScene, false)
        SetSynchronizedSceneLooped(localScene, false)
      end
      if cfg.sceneDiagnostics then
        print(('[vx_torture] scene_retire network=%s local=%s'):format(scene, localScene))
      end
      NetworkStopSynchronisedScene(scene)
      self.sceneStopPending = true
    end
  end
end

function Impl:ReserveActorScene(run, coords, heading, looped)
  if not self:SceneCurrent(run) then return nil end
  if self.pendingActorScene then
    -- A server timeout can supersede a coroutine during its two-frame yield.
    -- This reservation has never owned a ped/prop task and can be released now.
    NetworkStopSynchronisedScene(self.pendingActorScene)
    self.pendingActorScene = nil
  end
  -- Allocate while the predecessor still occupies its engine slot. Lua tokens
  -- cannot distinguish old/new engine tasks if both use the same network ID.
  -- This creates no ped task; stop the predecessor before adding any tracks.
  local previous = self.scene
  run.retiringActor = self.actorTrack
  local scene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z,
    0.0, 0.0, heading, 2, not looped, looped, 1.0, 0.0, 1.0)
  if not scene or scene == -1 then return nil end
  if scene == previous then
    print(('[vx_torture] scene_reservation_failed previous=%s next=%s token=%s')
      :format(previous, scene, run.token))
    return nil
  end
  self.pendingActorScene = scene
  run.scene = scene
  if cfg.sceneDiagnostics then
    print(('[vx_torture] scene_handoff token=%s kind=%s step=%s previous=%s next=%s')
      :format(run.token, run.kind, run.step, previous, scene))
  end
  return scene
end

-- A local frame yield does not flush the remote ped task tree. Before assigning
-- the successor, observe the old actor clip gone locally AND on the victim.
-- This is a bounded observation barrier, not a native stop acknowledgement.
function Impl:WaitForSceneHandoff(run)
  if not self:SceneCurrent(run) then return false, 'cancelled' end
  local old = run.retiringActor
  if not old then return self:SceneCurrent(run) end
  local pending = { run = run, previous = old.scene, nextScene = run.scene }
  self.sceneHandoff = pending
  -- A finite scene may retain its held ped task after NetworkStop. Retire
  -- that owned task once at this boundary; never clear/re-task the remote ped.
  if nativeTrue(IsEntityPlayingAnim(PlayerPedId(), old.dict, old.clip, 3)) then
    ClearPedTasks(PlayerPedId())
  end
  local expires = GetGameTimer() + cfg.scenePeerTimeoutMs
  self:TraceScene('handoff_wait', run)
  self:EmitNet(self, 'requestSceneHandoff', run.setup.id, run.token, run.kind,
    run.step, old.scene, run.scene)
  while self:SceneCurrent(run) and self.sceneHandoff == pending and GetGameTimer() < expires do
    if pending.ready == false then break end
    local playing = nativeTrue(IsEntityPlayingAnim(PlayerPedId(), old.dict, old.clip, 3))
    if pending.ready == true and not playing then
      self.sceneHandoff = nil
      self:TraceScene('handoff_ready', run)
      return true
    end
    Wait(0)
  end
  if self.sceneHandoff == pending then self.sceneHandoff = nil end
  return false, pending.reason or 'handoff_timeout'
end

function Impl:StopStage(keepVictimTask, transitioning)
  local stoppedRun = self.sceneRun
  if transitioning then stoppedRun = stoppedRun and stoppedRun.previous end
  self:TraceScene('stop', stoppedRun)
  if self.sceneRun then self.sceneRun.previous = nil end
  if not transitioning then self.sceneRun = nil; self.sceneHandoff = nil; self.remoteHandoff = nil end
  self.stageGeneration = (self.stageGeneration or 0) + 1
  local generation = self.stageGeneration
  for _, track in ipairs(self.handPropTracks or {}) do
    if DoesEntityExist(track.entity) then StopEntityAnim(track.entity, track.clip, track.dict, -8.0) end
  end
  self.handPropTracks = nil
  if self.peerScene and self.peerScene.ready == nil then
    self.peerScene.reason = self.peerScene.reason or 'session_stopped_before_ack'
  end
  self.peerScene = nil
  if not keepVictimTask then self:StopVictimScene() end
  self.retiredScenes = self.retiredScenes or {}
  if not transitioning and self.pendingActorScene then
    -- An unstarted reservation has no tracks. It still needs releasing when
    -- cancellation happens during the yielding stop/prop-preparation work.
    self.retiredScenes[#self.retiredScenes + 1] = self.pendingActorScene
    self.pendingActorScene = nil
  end
  for _, scene in ipairs(self.benchScenes or {}) do
    self.retiredScenes[#self.retiredScenes + 1] = scene
  end
  self.benchScenes = nil
  for _, key in ipairs({ 'benchScene', 'chairScene', 'scene' }) do
    if self[key] then
      self.retiredScenes[#self.retiredScenes + 1] = self[key]
      self[key] = nil
    end
  end
  self.localScene = nil
  self.actorTrack = nil
  -- Stop every old network task BEFORE assigning these peds/props again.
  -- Stopping the old scene after starting the successor can abort its tasks
  -- one frame later. NetworkStopSynchronisedScene has no acknowledgement;
  -- a retained local handle/held clip is not proof that the stop failed.
  self:StopRetiredScenes(transitioning and self.pendingActorScene or nil)
  if transitioning then
    if self.sceneStopPending then
      -- Drain the local stop queue first. WaitForSceneHandoff then observes
      -- retirement on both participants before any successor task is assigned.
      for _ = 1, 2 do
        Wait(0)
        if self.stageGeneration ~= generation then return false end
      end
      self.sceneStopPending = nil
    end
    return true
  end
  local camera = self.camera
  self.camera = nil
  if camera and DoesCamExist(camera) then
    RenderScriptCams(false, false, 0, true, false)
    SetCamActive(camera, false)
    DestroyCam(camera, false)
  end
  if self.stageChair and DoesEntityExist(self.stageChair) then
    if self.stageChairRestore and requestControl(self.stageChair, 700) then
      if self.stageGeneration ~= generation then return false end
      local position = self.stageChairRestore.coords
      SetEntityCoordsNoOffset(self.stageChair, position.x, position.y, position.z,
        false, false, false)
      setDisplayRotation(self.stageChair, self.stageChairRestore.heading,
        cfg.props.chair, self.stageChairRestore.rotation)
    end
    if self.stageGeneration ~= generation then return false end
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

function Impl:StopVictimScene(keepJoin)
  if not keepJoin then self.victimJoin = nil end
  self.remoteActorTrack = nil
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

function Impl:PlayVictimTrack(setup, stageData, looped, phase, masterScene, current)
  if self.seated ~= setup.id or IsEntityDead(PlayerPedId())
    or not loadDict(stageData.dict, 3000) then return false end
  if self.seated ~= setup.id or nativeTrue(IsEntityDead(PlayerPedId()))
    or (current and not current()) then return false end
  local root, heading = sceneOrigin(setup)
  if not root then return false end
  if self.sceneRun then self.sceneRun.origin, self.sceneRun.heading = root, heading end
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
    if current and not current() then return false end
    if nativeTrue(IsEntityPlayingAnim(ped, track.dict, track.clip, 3))
      and chairPosition and #(GetEntityCoords(ped) - chairPosition)
        <= cfg.seatAlignment.maxDistance + 0.8 then return true end
    Wait(0)
  end
  print(('[vx_torture] Victim track missing/off chair (%s / %s, distance=%.2f)')
    :format(track.dict, track.clip,
      chairPosition and #(GetEntityCoords(ped) - chairPosition) or -1.0))
  if self.victimScene == track then self:StopVictimScene(true) end
  return false
end

function Impl:StartVictimScene(setup, stageData, looped)
  return self:PlayVictimTrack(setup, stageData, looped, 0.0, nil)
end

function Impl:PlayIdle(setup)
  local generation = self.runGeneration
  if self.victimSceneStarting then return false end
  self.victimSceneStarting = true
  -- The chair is a networked prop. Only the actor may animate it during a
  -- tool scene; the seated player's base loop animates its own ped alone.
  local ready = self:PlayVictimTrack(setup, cfg.seatAlignment, true, 0.0, nil,
    function() return self.runGeneration == generation end)
  self.victimSceneStarting = false
  self.nextSeatRecoveryAt = GetGameTimer() + 1500
  return ready
end

function Impl:WaitForVictimScene(setup, token, kind, step, scene, localScene)
  local pending = { token = token, kind = kind, step = step, scene = scene }
  self.peerScene = pending
  -- The actor scene must keep advancing. Pausing a network scene while the
  -- other player resolves it stalls every track, including chair and camera.
  self:EmitNet(self, 'bindVictimScene', setup.id, token, kind, step, scene, self.chairScene)
  local expires = GetGameTimer() + cfg.scenePeerTimeoutMs
  while self.peerScene == pending and self.scene == scene and pending.ready == nil
    and GetGameTimer() < expires do
    if not self:ActorTrackRunning(scene) then pending.reason = 'actor_track_lost' break end
    if kind ~= 'idle' and not (self.actorTrack and self.actorTrack.looped)
      and GetSynchronizedScenePhase(localScene) >= 0.95 then
      pending.reason = 'scene_ended_before_ack'
      break
    end
    Wait(0)
  end
  if self.peerScene ~= pending or self.scene ~= scene or pending.ready ~= true then
    pending.reason = pending.reason or 'ack_timeout'
    print(('[vx_torture] peer_failed reason=%s token=%s kind=%s step=%s scene=%s ready=%s')
      :format(pending.reason or 'ack_timeout', token, kind, step, scene, pending.ready))
    return false
  end
  return self:ActorTrackRunning(scene)
end

function Impl:JoinVictimScene(setup, stageData, scene, looped, current, victimClock)
  if not current() then return false, 'victim_state_changed' end
  if not loadDict(stageData.dict, 1000) or not current() then return false, 'victim_state_changed' end
  -- A Lua event can overtake the engine's scene packet. A fabricated phase 0
  -- used to acknowledge a scene that had never replicated to this client.
  local expires = GetGameTimer() + cfg.sceneReplicationTimeoutMs
  local phase, remote, reason
  repeat
    if not current() then return false, 'victim_state_changed' end
    local actorPlayer = GetPlayerFromServerId(setup.owner)
    local actor = actorPlayer ~= -1 and GetPlayerPed(actorPlayer) or 0
    local actorLocal = NetworkGetLocalSceneFromNetworkId(scene)
    local masterLocal = NetworkGetLocalSceneFromNetworkId(victimClock or scene)
    reason = 'remote_scene_timeout'
    if actorLocal and actorLocal >= 0 and masterLocal and masterLocal >= 0
      and nativeTrue(IsSynchronizedSceneRunning(actorLocal))
      and nativeTrue(IsSynchronizedSceneRunning(masterLocal)) then
      reason = 'remote_actor_timeout'
      if actor ~= 0 and DoesEntityExist(actor)
        and nativeTrue(IsEntityPlayingAnim(actor, stageData.dict, stageData.actor, 3)) then
        phase = GetSynchronizedScenePhase(masterLocal)
        remote = { actor = actor, scene = scene, localScene = actorLocal,
          clock = masterLocal, dict = stageData.dict, clip = stageData.actor }
        break
      end
    end
    Wait(0)
  until GetGameTimer() >= expires
  if not phase then
    print(('[vx_torture] remote_scene_failed reason=%s actor=%s network=%s clock=%s dict=%s clip=%s')
      :format(reason, setup.owner, scene, victimClock or scene, stageData.dict, stageData.actor))
    return false, reason
  end
  if not looped and phase >= 0.90 then return false, 'victim_scene_late' end
  local success = self:PlayVictimTrack(setup, stageData, looped, phase, scene, current)
  if not success then return false, 'victim_track_failed' end
  if not current() or self.victimMasterScene ~= scene then return false, 'victim_state_changed' end
  self.remoteActorTrack = remote
  return true
end

function Impl:MonitorVictimRun(run)
  if not self:SceneCurrent(run) or not run.joined or run.failed then return end
  local setup, data = run.setup, run.data
  if self.seated ~= setup.id then return end
  local remote = self.remoteActorTrack
  local actorPlayer = GetPlayerFromServerId(setup.owner)
  local actor = actorPlayer ~= -1 and GetPlayerPed(actorPlayer) or 0
  local handle = run.scene and NetworkGetLocalSceneFromNetworkId(run.scene)
  local fatal = nativeTrue(IsEntityDead(PlayerPedId())) or actor == 0
    or not DoesEntityExist(actor) or nativeTrue(IsEntityDead(actor))
    or not targetReady(setup.props.chair)
    or not targetReady(setup.props[setup.tool])
  for _, tracks in ipairs({ data.props or {}, data.handProps or {} }) do
    for key in pairs(tracks) do if not targetReady(setup.props[key]) then fatal = true end end
  end
  local ownLive = self.victimScene and self.victimMasterScene == run.scene
    and nativeTrue(IsEntityPlayingAnim(PlayerPedId(), data.dict, data.victim, 3))
  local actorLive = remote and handle and handle >= 0
    and nativeTrue(IsSynchronizedSceneRunning(handle))
    and nativeTrue(IsEntityPlayingAnim(actor, data.dict, data.actor, 3))
  local healthy, live = self:TrackHealth(run, ownLive and actorLive, fatal)
  if not healthy then
    run.failed = true
    local reason = fatal and 'entity_missing' or (not ownLive and 'victim_track_failed' or 'remote_track_lost')
    self:TraceScene('failed', run, reason)
    self:DumpSceneTrace(reason)
    if run.kind == 'action' then
      self:EmitNet(self, 'stageFailed', setup.id, run.token, run.step, reason)
    else
      self:EmitNet(self, 'toolSceneFailed', setup.id, run.token, run.kind, run.step, reason)
    end
    return
  end
  if not live or run.completed or run.kind == 'idle' or not run.peersReadyAt then return end
  local finished
  if data.loopMs then
    finished = GetGameTimer() - run.peersReadyAt >= data.loopMs
  else
    finished = GetSynchronizedScenePhase(handle) >= 0.97
    -- An independent seated loop has no finite endpoint. Other victim tracks
    -- must reach their own endpoint too; the actor clock alone is insufficient.
    if not data.victimLoop then
      finished = finished and GetEntityAnimCurrentTime(PlayerPedId(), data.dict, data.victim) >= 0.95
    end
  end
  if finished then
    run.completed = true
    self:TraceScene('complete', run)
    self:EmitNet(self, 'sceneComplete', setup.id, run.token, run.kind, run.step, run.scene, true)
  end
end

function Impl:PrintSceneDiagnostics()
  self:DumpSceneTrace("manual")
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
  local actorPlayer = GetPlayerFromServerId(setup.owner)
  local actorPed = actorPlayer ~= -1 and GetPlayerPed(actorPlayer) or 0
  local remote = self.remoteActorTrack
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
    gameBuild = GetGameBuildNumber(),
    remoteActor = actorPed ~= 0 and {
      ped = actorPed, visible = IsEntityVisible(actorPed), alpha = GetEntityAlpha(actorPed),
      position = GetEntityCoords(actorPed), networkOwner = NetworkGetEntityOwner(actorPed),
      dict = remote and remote.dict, clip = remote and remote.clip,
      playing = remote and IsEntityPlayingAnim(actorPed, remote.dict, remote.clip, 3),
      networkScene = remote and remote.scene,
      localScene = remote and NetworkGetLocalSceneFromNetworkId(remote.scene),
    } or { streamed = false },
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
  local run = self:BeginSceneRun(setup, token, looped and 'idle' or 'select',
    looped and session.idleEpoch or 0, stageData)
  local function current() return self:SceneCurrent(run) and self.toolSession == session end
  local function fail(reason)
    if not current() then return false, 'cancelled' end
    self:TraceScene('failed', run, reason)
    self:DumpSceneTrace(reason)
    print(('[vx_torture] tool_scene_failed reason=%s tool=%s phase=%s dict=%s clip=%s token=%s network=%s local=%s')
      :format(reason, session.tool, looped and 'idle' or 'select', stageData.dict,
        stageData.actor, token, self.scene, self.localScene))
    if self.toolSession == session then self:StopStage() end
    return false, reason
  end
  local coords, heading = sceneOrigin(setup)
  run.origin, run.heading = coords, heading
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
  if not current() then return false end
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
    self:PutToolBack(setup, session.tool, current)
  elseif attachSelected then
    local selected = fromNet(setup.props[session.tool], 700)
    if not selected or not requestControl(selected, 1000) then return fail('selected_tool_control') end
  end
  if not current() then return false end
  local scene = self:ReserveActorScene(run, coords, heading, looped)
  if not scene then return fail('scene_create') end
  if not self:StopStage(false, true) then return fail('previous_scene_stop') end
  if not current() then return false end
  local handed, handoffReason = self:WaitForSceneHandoff(run)
  if not handed then return fail(handoffReason or 'cancelled') end
  if not stageData.chair and not self:StaticChair(setup, current) then return fail('static_chair') end
  if attachSelected and not self:HoldTool(setup, session.tool, current) then
    return fail('attach_tool')
  end
  if not current() then return false end
  self.pendingActorScene = nil
  self.scene = scene
  self.actorStageActive = true
  self:AddActorTrack(scene, ped, stageData.dict, stageData.actor, looped, coords, heading)
  if chair then
    FreezeEntityPosition(chair, false)
    self.stageChair = chair
    self.stageChairRestore = { coords = setup.positions.chair, heading = setup.heading,
      rotation = setup.rotations and setup.rotations.chair }
    local chairScene = scene
    if not looped and stageData.victimLoop then
      -- FBI3 func_428 uses scene 37 for the independent seated loop.
      -- Its ~13.33s chair clip must not extend the finite selection clock.
      chairScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z,
        0.0, 0.0, heading, 2, false, true, 1.0, 0.0, 1.0)
      if not chairScene or chairScene == -1 then return fail('create_chair_scene') end
      self.chairScene = chairScene
    end
    NetworkAddEntityToSynchronisedScene(chair, chairScene, stageData.dict, stageData.chair,
      8.0, -8.0, (looped or stageData.victimLoop) and 64 or 0)
    if chairScene ~= scene then NetworkStartSynchronisedScene(chairScene) end
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
    -- CStartNetworkSyncedSceneEvent serializes only 3/4/5 non-ped tracks
    -- depending on game build. The old 6-7 prop bench exceeded even build 3258.
    -- Three per group also works on older builds. Never duplicate the actor.
    self.benchScenes = {}
    local benchScene, count
    for _, key in ipairs(cfg.propOrder) do
      local entity = benchEntities[key]
      if entity then
        if not benchScene or count == 3 then
          benchScene = NetworkCreateSynchronisedScene(
            coords.x, coords.y, coords.z + trolleyPosition.z - expected.z,
            0.0, 0.0, heading, 2, false, false, 1.0, 0.0, 1.0)
          if not benchScene or benchScene == -1 then return fail('create_bench_scene') end
          self.benchScenes[#self.benchScenes + 1] = benchScene
          count = 0
        end
        DetachEntity(entity, true, true)
        FreezeEntityPosition(entity, false)
        NetworkAddEntityToSynchronisedScene(entity, benchScene,
          'missfbi3_weapon_select_trolley', benchTracks[key], 8.0, -8.0, 0)
        count = count + 1
      end
    end
    for _, bench in ipairs(self.benchScenes) do NetworkStartSynchronisedScene(bench) end
  end
  self:TraceScene('start', run)
  NetworkStartSynchronisedScene(scene)
  local localScene = self:WaitForActorTrack(scene, ped, stageData.dict, stageData.actor, looped,
    function() return current() and self.scene == scene end)
  if not localScene then
    return fail('actor_start')
  end
  self.localScene = localScene
  if not self:StartHandProps(setup, stageData, looped, localScene, current) then return fail('hand_prop_start') end
  if not current() then return false end
  local cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
  if not PlaySynchronizedCamAnim(cam, localScene, stageData.camera, stageData.dict) then
    DestroyCam(cam, false)
    return fail('camera_start')
  end
  self:ReplaceSceneCamera(cam)
  if not self:WaitForVictimScene(setup, token, looped and 'idle' or 'select',
    looped and session.idleEpoch or 0, scene, localScene) then
    return fail(self.peerScene and self.peerScene.reason or 'peer_ready')
  end
  self:TraceScene('ready', run)
  if looped then
    if session.restoreBench then
      session.restoreBench = nil
      CreateThread(function()
        self:RestoreBench(setup, session.tool, false,
          current)
      end)
    end
    return true
  end
  local untilTime = GetGameTimer() + cfg.toolSelectTimeoutMs
  local attached = false
  while current() and self.scene == scene
    and GetGameTimer() < untilTime do
    local healthy, live = self:ActorTrackRunning(scene)
    if not healthy then return fail('actor_track_lost') end
    local phase = GetSynchronizedScenePhase(localScene)
    if stageData.attachAt and not attached and phase >= stageData.attachAt then
      attached = self:HoldTool(setup, session.tool, current)
      if not attached then return fail('attach_at_phase') end
    end
    if live and phase >= 0.97 then
      -- Keep the last selection frame/camera through the server round trip.
      -- Idle already owns the selected tool track (or attaches it on entry).
      -- Restoring the other bench props must not block the idle/menu handoff.
      session.restoreBench = true
      self:TraceScene("complete", run)
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
  local function current() return self.toolSession == session end
  if not self:HoldTool(setup, session.tool, current) then return false end
  local trolley = fromNet(setup.props.trolley, 700)
  if not trolley or not current() then return false end
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
  local loaded = reached and loadDict('pickup_object', 1500)
  if not current() then return false end
  if loaded then
    TaskPlayAnim(ped, 'pickup_object', 'putdown_low', 8.0, -8.0,
      cfg.toolReturnAnimMs, 0, 0.0, false, false, false)
    Wait(math.floor(cfg.toolReturnAnimMs * 0.5))
    if self.toolSession ~= session then return false end
    returned = self:PutToolBack(setup, session.tool, current)
    Wait(math.ceil(cfg.toolReturnAnimMs * 0.5))
    if self.toolSession ~= session then return false end
  else
    returned = self:PutToolBack(setup, session.tool, current)
    reached = false
  end
  self:RestoreBench(setup, session.tool, true, current)
  if not current() then return false end
  self:StopStage()
  ClearPedTasks(ped)
  return reached and returned and self.toolSession == session
end

function Impl:RunActorStage(setup, token, key, index)
  local startedAt = GetGameTimer()
  local action = cfg.actions[key]
  local stageData = action.stages[index]
  local looped = stageData.loopMs ~= nil
  local active = self.activeAction
  if not active or active.token ~= token then return false, 'cancelled' end
  local run = self:BeginSceneRun(setup, token, 'action', index, stageData)
  local function current() return self:SceneCurrent(run) and self.activeAction == active end
  local function fail(reason)
    if not current() then return false, 'cancelled' end
    self:TraceScene('failed', run, reason)
    self:DumpSceneTrace(reason)
    self:StopStage()
    return false, reason
  end
  local coords, heading = sceneOrigin(setup)
  run.origin, run.heading = coords, heading
  if not coords or not current() then return fail("scene_origin") end
  local ped = PlayerPedId()
  local chair = fromNet(setup.props.chair, 500)
  local tool = fromNet(setup.props[action.tool], 500)
  if not chair or not tool then return fail("entity_missing") end
  local controlledChair = not stageData.chair or requestControl(chair, 1000)
  local sceneProps = {}
  if stageData.tool then sceneProps[action.tool] = stageData.tool end
  for propKey, clip in pairs(stageData.props or {}) do sceneProps[propKey] = clip end
  local propEntities = {}
  for propKey in pairs(sceneProps) do
    local entity = fromNet(setup.props[propKey], 500)
    if not entity or not requestControl(entity, 1000) then return fail("entity_control") end
    propEntities[propKey] = entity
  end
  if not controlledChair then return fail("entity_control") end
  if not current() then return fail("action_validation") end
  local scene = self:ReserveActorScene(run, coords, heading, looped)
  if not scene then return fail('scene_create') end
  if not self:StopStage(false, true) then return fail('cancelled') end
  if not current() then return fail("action_validation") end
  local handed, handoffReason = self:WaitForSceneHandoff(run)
  if not handed then return fail(handoffReason or 'cancelled') end
  if not stageData.chair and not self:StaticChair(setup, current) then return fail("action_validation") end
  if stageData.attachTool and not self:HoldTool(setup, action.tool, current) then return fail("action_validation") end
  if not current() then return fail("action_validation") end
  if scene and scene ~= -1 then
    self.pendingActorScene = nil
    self.actorStageActive = true
    self.scene = scene
    self:AddActorTrack(scene, ped, stageData.dict, stageData.actor, looped, coords, heading)
    if stageData.chair then
      FreezeEntityPosition(chair, false)
      self.stageChair = chair
      self.stageChairRestore = { coords = setup.positions.chair, heading = setup.heading,
        rotation = setup.rotations and setup.rotations.chair }
      local chairScene = scene
      if stageData.victimLoop and not looped then
        chairScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z,
          0.0, 0.0, heading, 2, false, true, 1.0, 0.0, 1.0)
        if not chairScene or chairScene == -1 then return fail("scene_create") end
        self.chairScene = chairScene
      end
      NetworkAddEntityToSynchronisedScene(chair, chairScene, stageData.dict, stageData.chair,
        8.0, -8.0, (looped or stageData.victimLoop) and 64 or 0)
      -- Start the secondary clock after its background prop tracks are added.
    end
    for propKey, clip in pairs(sceneProps) do
      local entity = propEntities[propKey]
      DetachEntity(entity, true, true)
      FreezeEntityPosition(entity, false)
      local followsVictim = stageData.victimProps and stageData.victimProps[propKey]
      local propScene = followsVictim and self.chairScene or scene
      if not propScene then return fail("scene_create") end
      NetworkAddEntityToSynchronisedScene(entity, propScene, stageData.dict, clip,
        8.0, -8.0, (looped or followsVictim) and 64 or 0)
    end
    if self.chairScene then NetworkStartSynchronisedScene(self.chairScene) end
    self:TraceScene('start', run)
    NetworkStartSynchronisedScene(scene)
    local localScene = self:WaitForActorTrack(scene, ped, stageData.dict, stageData.actor, looped,
      function() return current() and self.scene == scene end)
    if localScene then
      self.localScene = localScene
      if not self:StartHandProps(setup, stageData, looped, localScene, current) then return fail("hand_prop_start") end
      if not current() then return false, "cancelled" end
      local camName = stageData.camera or stageData.actor:gsub('_player$', '_cam')
      local cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
      if PlaySynchronizedCamAnim(cam, localScene, camName, stageData.dict) then
        self:ReplaceSceneCamera(cam)
      else
        DestroyCam(cam, false)
        return fail("camera_start")
      end
      if not self:WaitForVictimScene(setup, token, 'action', index, scene, localScene) then
        return fail(self.peerScene and self.peerScene.reason or 'peer_ready')
      end
      -- durationMs is an effect/gameplay estimate, not the loaded clip length.
      -- Advance by the real scene phase, with the same hard deadline as server.
      self:TraceScene("ready", run)
      local untilTime = startedAt + cfg.stageTimeoutMs
      local loopStartedAt = GetGameTimer() -- count only after both peers are ready
      while current()
        and GetGameTimer() < untilTime do
        local healthy, live = self:ActorTrackRunning(scene)
        if not healthy then return fail('actor_track_lost') end
        if not self:SyncHandProps() then return fail('hand_prop_lost') end
        if live and ((looped and GetGameTimer() - loopStartedAt >= stageData.loopMs)
          or (not looped and GetSynchronizedScenePhase(localScene) >= 0.97)) then
          self:TraceScene("complete", run)
          return true -- hold this frame until the next stage/idle is prepared
        end
        Wait(0)
      end
      if not current() then return fail("action_validation") end
      return fail("stage_timeout")
    end
    if not current() then return fail("action_validation") end
    return fail("actor_start")
  end
  return fail("scene_create")
end

function Impl:StopEffectSounds(token)
  local run = self.activeEffects[token]
  self.activeEffects[token] = nil
  for _, id in ipairs(self.activeSounds[token] or {}) do StopSound(id); ReleaseSoundId(id) end
  self.activeSounds[token] = nil
  if run then
    for _, handle in ipairs(run.particles) do StopParticleFxLooped(handle, false) end
    for _, entity in ipairs(run.objects) do
      if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    if run.camera and DoesCamExist(run.camera) then StopCamShaking(run.camera, true) end
    for bank in pairs(run.banks) do
      self.fxBanks[bank] = (self.fxBanks[bank] or 1) - 1
      if self.fxBanks[bank] <= 0 then
        self.fxBanks[bank] = nil
        ReleaseNamedScriptAudioBank(bank)
      end
    end
    if run.audioScene then
      local entry = self.fxAudioScenes[run.audioScene]
      if entry then
        entry.count = entry.count - 1
        if entry.count <= 0 then
          if entry.owned then StopAudioScene(run.audioScene) end
          self.fxAudioScenes[run.audioScene] = nil
        end
      end
    end
  end
end

local function effectEntity(setup, key)
  if key == 'actor' or key == 'victim' then
    local player = GetPlayerFromServerId(key == 'actor' and setup.owner or setup.victim)
    if player == -1 then return nil end
    local ped = GetPlayerPed(player)
    return ped ~= 0 and DoesEntityExist(ped) and ped or nil
  end
  local net = setup.props[key or 'chair']
  if targetReady(net) then return NetworkGetEntityFromNetworkId(net) end
end

function Impl:EffectCurrent(token, run)
  return self.activeEffects[token] == run and GetGameTimer() < run.expiresAt
end

function Impl:QueueSceneEffects(setup, token, identity, data, netScene, kind)
  if not cfg.fx.enabled then return end
  local previous = self.activeEffects[token]
  if previous and previous.identity == identity then return end
  self:StopEffectSounds(token)
  local duration
  if kind == 'idle' or kind == 'ambient' then duration = math.huge
  else duration = data.loopMs or cfg.stageTimeoutMs end
  local run = { setup = setup, identity = identity, data = data, netScene = netScene,
    kind = kind, particles = {}, evolutions = {}, objects = {}, banks = {}, fired = {},
    expiresAt = GetGameTimer() + duration }
  self.activeEffects[token] = run
  for _, cue in ipairs(data.effects or {}) do
    if cue.sound == 'FBI_03_TORTURE_Heart_Monitor_Flatline' then
      self:StopEffectSounds(('monitor:%s'):format(setup.id))
    end
  end
  -- Audio mixes affect only the two participants, never nearby observers.
  local audioScene = kind ~= 'ambient' and cfg.toolAudioScenes[setup.tool]
  if cfg.fx.sounds and cfg.fx.audioScenes and audioScene
    and (playerSource() == setup.owner or playerSource() == setup.victim) then
    local entry = self.fxAudioScenes[audioScene]
    if not entry then
      local active = nativeTrue(IsAudioSceneActive(audioScene))
      entry = { count = 0, owned = not active and nativeTrue(StartAudioScene(audioScene)) }
      self.fxAudioScenes[audioScene] = entry
    end
    entry.count = entry.count + 1
    run.audioScene = audioScene
  end
  if duration < math.huge then
    SetTimeout(duration, function()
      if self.activeEffects[token] == run then self:StopEffectSounds(token) end
    end)
  end
  for _, cue in ipairs(data.effects or {}) do
    if cue.particle and cfg.fx.particles then RequestNamedPtfxAsset('scr_fbi3') end
    if cue.sound and cfg.fx.sounds and not run.banks[cue.bank] then
      run.banks[cue.bank] = true
      self.fxBanks[cue.bank] = (self.fxBanks[cue.bank] or 0) + 1
      RequestScriptAudioBank(cue.bank, false)
    end
  end
  self:TickEffect(token, run)
end

function Impl:QueueEffect(setup, token, key, index, netScene)
  local data = cfg.actions[key] and cfg.actions[key].stages[index]
  if data then self:QueueSceneEffects(setup, token, key .. ':' .. index, data, netScene, 'action') end
end

function Impl:TickEffect(token, run)
  local chair = effectEntity(run.setup, 'chair')
  local victim = effectEntity(run.setup, 'victim')
  if not self:EffectCurrent(token, run) or not chair or not victim or IsEntityDead(victim)
    or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(chair)) > cfg.observerFxDistance then
    return self:StopEffectSounds(token)
  end
  local phase = 0.0
  if run.netScene then
    local scene = NetworkGetLocalSceneFromNetworkId(run.netScene)
    if not scene or scene < 0 then return end -- wait for replication; never guess a phase
    if not nativeTrue(IsSynchronizedSceneRunning(scene)) then
      if run.seenScene then self:StopEffectSounds(token) end
      return
    end
    run.seenScene = true
    phase = GetSynchronizedScenePhase(scene)
  end
  for index, cue in ipairs(run.data.effects or {}) do
    if not run.fired[index] and phase >= (cue.atPhase or 0.0) then
      run.fired[index] = true
      CreateThread(function() self:PlayEffect(run.setup, token, cue, run) end)
    end
  end
  for handle, evolution in pairs(run.evolutions) do
    SetParticleFxLoopedEvolution(handle, evolution.name,
      evolution.from + (evolution.to - evolution.from) * phase, false)
  end
end

function Impl:PlayEffect(setup, token, cue, run)
  local function current() return self:EffectCurrent(token, run) end
  if not current() then return end
  if cue.shake then
    if cfg.fx.cameraShake and setup.owner == playerSource() and self.camera and DoesCamExist(self.camera) then
      run.camera = self.camera
      ShakeCam(run.camera, cue.shake, cue.amplitude or 0.25)
    end
    return
  end
  local entity = effectEntity(setup, cue.entity)
  if not entity then return end
  if cue.particle and cfg.fx.particles then
    local untilTime = GetGameTimer() + cfg.fx.assetTimeoutMs
    RequestNamedPtfxAsset('scr_fbi3')
    while current() and not HasNamedPtfxAssetLoaded('scr_fbi3') and GetGameTimer() < untilTime do Wait(0) end
    if not current() then return end
    if not HasNamedPtfxAssetLoaded('scr_fbi3') then
      print('[vx_torture] particle_asset_timeout asset=scr_fbi3')
      return
    end
    if cue.cosmetic then
      local model = joaat(cue.cosmetic.model)
      local loaded = loadModel(model, cfg.fx.assetTimeoutMs)
      if not current() or not loaded or not DoesEntityExist(entity) then
        SetModelAsNoLongerNeeded(model); return
      end
      local pos = GetEntityCoords(entity)
      local object = CreateObjectNoOffset(model, pos.x, pos.y, pos.z, false, false, false)
      SetModelAsNoLongerNeeded(model)
      if not object or object == 0 then return end
      run.objects[#run.objects + 1] = object
      SetEntityCollision(object, false, false)
      AttachEntityToEntity(object, entity, GetPedBoneIndex(entity, cue.cosmetic.bone),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
      entity = object
    end
    if not current() or not DoesEntityExist(entity) then return end
    local o, r = cue.offset or vector3(0, 0, 0), cue.rotation or vector3(0, 0, 0)
    UseParticleFxAssetNextCall('scr_fbi3')
    local handle
    if cue.bone then
      -- These natives take the skeleton bone ID used by FBI3, not GetPedBoneIndex.
      if cue.looped then
        handle = StartParticleFxLoopedOnPedBone(cue.particle, entity, o.x, o.y, o.z,
          r.x, r.y, r.z, cue.bone, cue.scale or 1.0, false, false, false)
      else
        StartParticleFxNonLoopedOnPedBone(cue.particle, entity, o.x, o.y, o.z,
          r.x, r.y, r.z, cue.bone, cue.scale or 1.0, false, false, false)
      end
    elseif cue.looped then
      handle = StartParticleFxLoopedOnEntity(cue.particle, entity, o.x, o.y, o.z,
        r.x, r.y, r.z, cue.scale or 1.0, false, false, false)
    else
      StartParticleFxNonLoopedOnEntity(cue.particle, entity, o.x, o.y, o.z,
        r.x, r.y, r.z, cue.scale or 1.0, false, false, false)
    end
    if cue.looped then
      if handle and handle ~= 0 then
        run.particles[#run.particles + 1] = handle
        if cue.evolution then
          run.evolutions[handle] = cue.evolution
          SetParticleFxLoopedEvolution(handle, cue.evolution.name, cue.evolution.from, false)
        elseif cue.particle == 'scr_fbi3_elec_smoulder' then
          SetParticleFxLoopedEvolution(handle, 'smoke', 0.0, false)
        end
      else print(('[vx_torture] particle_start_failed effect=%s'):format(cue.particle)) end
    end
  end
  if cue.sound and cfg.fx.sounds then
    local untilTime = GetGameTimer() + cfg.fx.assetTimeoutMs
    local loaded = nativeTrue(RequestScriptAudioBank(cue.bank, false))
    while current() and not loaded and GetGameTimer() < untilTime do
      Wait(0)
      if current() then loaded = nativeTrue(RequestScriptAudioBank(cue.bank, false)) end
    end
    if not current() or not DoesEntityExist(entity) then return end
    if not loaded then
      print(('[vx_torture] audio_bank_timeout bank=%s sound=%s'):format(cue.bank, cue.sound))
      return
    end
    local id = GetSoundId()
    PlaySoundFromEntity(id, cue.sound, entity, cue.soundset or 0, false, 0)
    self.activeSounds[token] = self.activeSounds[token] or {}
    self.activeSounds[token][#self.activeSounds[token] + 1] = id
    for name, value in pairs(cue.variables or {}) do SetVariableOnSound(id, name, value) end
  end
end

function Impl:SyncMonitorEffects()
  for _, setup in pairs(self.setups) do
    local token = ('monitor:%s'):format(setup.id)
    local entity = effectEntity(setup, 'ecg')
    local victim = setup.victim and effectEntity(setup, 'victim')
    local enabled = cfg.fx.enabled and cfg.fx.sounds and cfg.fx.monitor and setup.seatReady
      and entity and victim and not IsEntityDead(victim)
      and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity)) <= cfg.observerFxDistance
    local flatline = false
    for _, run in pairs(self.activeEffects) do
      if run.setup.id == setup.id then
        for _, cue in ipairs(run.data.effects or {}) do
          if cue.sound == 'FBI_03_TORTURE_Heart_Monitor_Flatline' then flatline = true end
        end
      end
    end
    if enabled and not flatline then
      self:QueueSceneEffects(setup, token, 'monitor', { effects = {
        { sound = 'FBI_03_TORTURE_Heart_Monitor_Single', bank = 'FBI_03_TORTURE_General',
          entity = 'ecg', variables = { BPM = cfg.fx.monitorBpm } },
      } }, nil, 'ambient')
    else self:StopEffectSounds(token) end
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
        if prop.onDemand then
          -- Keep authored placement transforms for later server spawning,
          -- without creating hidden/display objects during preview.
          preview.bounds[key] = { min = min, max = max, verticalMin = min.z, verticalMax = max.z }
        else
          local here = GetEntityCoords(ped)
          local entity = CreateObjectNoOffset(model, here.x, here.y, here.z - 5.0,
            false, false, false)
          if entity ~= 0 and DoesEntityExist(entity) then
            FreezeEntityPosition(entity, true)
            preview.objects[key] = entity
            setDisplayRotation(entity, GetEntityHeading(ped), prop)
            local verticalMin, verticalMax = verticalBounds(entity, min, max)
            preview.bounds[key] = {
              min = min, max = max, verticalMin = verticalMin, verticalMax = verticalMax,
            }
            SetEntityCollision(entity, false, false)
            SetEntityAlpha(entity, cfg.previewAlpha, false)
          elseif prop.required then
            SetModelAsNoLongerNeeded(model)
            self:EndPreview(token, true)
            return previewFailed(key .. ':create_object')
          else
            preview.bounds[key] = nil
          end
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
  self.victimJoin = nil
  self.remoteActorTrack = nil
  self.victimSceneStarting = false
  self.nextSeatRecoveryAt = 0
  self.peerScene = nil
  self.benchScene = nil
  self.benchScenes = nil
  self.camera = nil
  self.stageChair = nil
  self.actorStageActive = false
  self.activeSounds = {}
  self.activeEffects = {}
  self.fxBanks = {}
  self.fxAudioScenes = {}
  self.toolSession = nil
  self.toolMenuId = nil
  self.nextToolHealthAt = 0
  self.preview = nil
end

function Impl:OnReady()
  print(('[vx_torture] scene handoff v16 loaded (client) gameBuild=%s'):format(GetGameBuildNumber()))
  RegisterCommand('vx_torture_diag', function() self:PrintSceneDiagnostics() end, false)
  self:OnNet('sceneHandoffReady', function(token, kind, step, previous, nextScene, success, reason)
    local pending = self.sceneHandoff
    local run = pending and pending.run
    if run and self:SceneCurrent(run) and run.token == token and run.kind == kind
      and run.step == step and pending.previous == previous and pending.nextScene == nextScene then
      pending.ready = success == true
      pending.reason = reason
    end
  end)
  self:OnNet('awaitSceneHandoff', function(setup, token, kind, step, previous, nextScene, old)
    if self.seated ~= setup.id or setup.victim ~= playerSource() then return end
    local session, action = self.toolSession, self.activeAction
    if kind == 'action' then
      if not action or action.token ~= token or action.stage > step then return end
    else
      if not session or session.token ~= token then return end
      if kind == 'idle' and session.idleEpoch and session.idleEpoch > step then return end
      if kind == 'select' and session.phase ~= 'prepare' and session.phase ~= 'select' then return end
    end
    local prior = self.remoteHandoff
    if prior and prior.token == token and prior.kind == kind and prior.step == step then return end
    local pending = { token = token, kind = kind, step = step }
    self.remoteHandoff = pending
    CreateThread(function()
      local expires = GetGameTimer() + cfg.sceneReplicationTimeoutMs
      local absentAt, phaseSeen, success, reason
      reason = 'handoff_timeout'
      while self.remoteHandoff == pending and self.seated == setup.id and GetGameTimer() < expires do
        local session, action = self.toolSession, self.activeAction
        local current = kind == 'action' and action and action.token == token and action.stage == step
          or kind == 'idle' and session and session.token == token and session.idleEpoch == step
            and session.phase == 'startingIdle' and not action
          or kind == 'select' and session and session.token == token and session.phase == 'select'
        if phaseSeen and not current then return end
        if current then
          phaseSeen = true
          local player = GetPlayerFromServerId(setup.owner)
          local actor = player ~= -1 and GetPlayerPed(player) or 0
          if actor == 0 or not DoesEntityExist(actor) or nativeTrue(IsEntityDead(actor)) then
            reason = 'entity_missing'; break
          end
          if nativeTrue(IsEntityPlayingAnim(actor, old.dict, old.clip, 3)) then
            absentAt = nil
          else
            absentAt = absentAt or GetGameTimer()
            if GetGameTimer() - absentAt >= 100 then success = true; break end
          end
        end
        Wait(0)
      end
      if self.remoteHandoff ~= pending or self.seated ~= setup.id then return end
      if cfg.sceneDiagnostics then
        print(('[vx_torture] handoff_observed token=%s kind=%s step=%s previous=%s next=%s success=%s reason=%s')
          :format(token, kind, step, previous, nextScene, success == true, success and '-' or reason))
      end
      self:EmitNet(self, 'sceneHandoffObserved', setup.id, token, kind, step,
        previous, nextScene, success == true, not success and reason or nil)
    end)
  end)
  self:OnNet('scenePeersReady', function(token, kind, step, scene)
    local run = self.sceneRun
    if run and run.token == token and run.kind == kind and run.step == step and run.scene == scene then
      run.peersReadyAt = run.peersReadyAt or GetGameTimer()
    end
  end)
  self:OnNet('victimSceneReady', function(token, kind, step, scene, success, reason)
    local pending = self.peerScene
    if pending and pending.token == token and pending.kind == kind
      and pending.step == step and pending.scene == scene then
      pending.ready = success == true
      pending.reason = reason
    end
  end)
  self:OnNet('joinVictimScene', function(setup, token, kind, step, scene, stageData, looped, victimClock)
    if setup.victim ~= playerSource() then return end
    if self.seated ~= setup.id then
      print(('[vx_torture] peer_join_failed reason=victim_wrong_seat token=%s seat=%s expected=%s')
        :format(token, self.seated, setup.id))
      return self:EmitNet(self, 'victimSceneReady', setup.id, token, kind, step, scene, false, 'victim_wrong_seat')
    end
    local previous = self.victimJoin
    local sessionNow, actionNow = self.toolSession, self.activeAction
    if kind == 'idle' and sessionNow and sessionNow.token == token
      and sessionNow.idleEpoch and sessionNow.idleEpoch > step then return end
    if kind == 'select' and sessionNow and sessionNow.token == token
      and sessionNow.phase ~= 'prepare' and sessionNow.phase ~= 'select' then return end
    if kind == 'action' and actionNow and actionNow.token == token
      and actionNow.stage and actionNow.stage > step then return end
    if previous and previous.token == token and previous.kind == kind
      and previous.step == step and previous.scene == scene then return end
    local join = { token = token, kind = kind, step = step, scene = scene }
    self.victimJoin = join
    local run = self:BeginSceneRun(setup, token, kind, step, stageData)
    run.scene = scene
    local function current()
      if self.victimJoin ~= join or not self:SceneCurrent(run) then return false end
      if self.seated ~= setup.id then return false end
      if kind == 'action' then
        local active = self.activeAction
        return active and active.token == token and active.stage == step
      end
      local session = self.toolSession
      return session and session.token == token
        and (kind == 'select' and session.phase == 'select'
          or kind == 'idle' and session.idleEpoch == step and not self.activeAction
            and (session.phase == 'startingIdle' or session.phase == 'idle'))
    end
    CreateThread(function()
      local readyUntil = GetGameTimer() + 1500
      while not current() and self.seated == setup.id and GetGameTimer() < readyUntil do Wait(0) end
      if not current() then
        if self.victimJoin ~= join then return end
        print(('[vx_torture] peer_join_failed reason=victim_state_timeout token=%s kind=%s step=%s phase=%s')
          :format(token, kind, step, self.toolSession and self.toolSession.phase))
        self:EmitNet(self, 'victimSceneReady', setup.id, token, kind, step, scene, false, 'victim_state_timeout')
        return
      end
      local session = self.toolSession
      local success, reason = self:JoinVictimScene(setup, stageData, scene, looped, current, victimClock)
      if self.victimJoin ~= join then return end
      if not success then
        print(('[vx_torture] peer_join_failed reason=%s token=%s kind=%s step=%s scene=%s')
          :format(reason, token, kind, step, scene))
      end
      run.joined = success == true
      self:TraceScene(success and 'ready' or 'failed', run, reason)
      if not success then self:DumpSceneTrace(reason) end
      self:EmitNet(self, 'victimSceneReady', setup.id, token, kind, step, scene, success == true, reason)
      if not current() then return end
      if kind == 'idle' then
        session.idleReady = success == true
        if success then session.phase = 'idle' end
        self:EmitNet(self, 'toolIdleReady', setup.id, token, step, success == true, reason)
      elseif not success then
        if kind == 'action' then self:EmitNet(self, 'stageFailed', setup.id, token, step, reason)
        else self:EmitNet(self, 'toolSceneFailed', setup.id, token, kind, step, reason) end
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
    for token, run in pairs(self.activeEffects) do
      if run.setup.id == setupId then self:StopEffectSounds(token) end
    end
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
    if self.toolSession and self.toolSession.token == token then return end
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
      actor = actor, phase = 'prepare', menuPending = false, revision = setup.revision }
    self.toolSession = session
    if cfg.fx.enabled and cfg.fx.particles then RequestNamedPtfxAsset('scr_fbi3') end
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
          ready = self:ValidateSceneAssets(setup, scene, function() return self.toolSession == session end)
          if not ready then break end
        end
      end
      if self.toolSession ~= session then return end
      if ready and not actor and not self.victimScene then ready = self:PlayIdle(setup) end
      self:EmitNet(self, 'readyTool', setup.id, token, ready, not ready and 'asset_clip' or nil)
      if not ready then self:EndToolSession(setup) end
    end)
  end)
  self:OnNet('playToolSelect', function(setup, token)
    local session = self.toolSession
    if not session or session.token ~= token then return end
    session.revision = math.max(session.revision or 0, setup.revision or 0)
    if session.selectStarted then return end
    session.selectStarted = true
    session.phase = 'select'
    local selectScene = cfg.toolScenes[session.tool].select
    if not session.actor then return end -- joined through the actor's scene id
    CreateThread(function()
      if self.toolSession ~= session or session.phase ~= 'select' then return end
      local success, reason = self:RunActorToolScene(setup, token, selectScene, false)
      if self.toolSession ~= session or session.phase ~= 'select' then return end
      local run = self.sceneRun
      if success then
        self:EmitNet(self, 'toolSelected', setup.id, token, true, run and run.scene)
      else
        self:EmitNet(self, 'toolSceneFailed', setup.id, token, 'select', 0, reason)
      end
    end)
  end)
  self:OnNet('startToolIdle', function(setup, token, epoch)
    local session = self.toolSession
    if not session or session.token ~= token then return end
    if session.idleEpoch and epoch <= session.idleEpoch then return end
    session.revision = math.max(session.revision or 0, setup.revision or 0)
    session.idleEpoch = epoch
    self:ExpectScene(token, 'idle', epoch)
    session.phase = 'startingIdle'
    session.idleReady = false
    session.menuPending = false
    local idleScene = cfg.toolScenes[session.tool].idle
    if not session.actor then return end -- readiness is sent after joining
    CreateThread(function()
      if self.toolSession ~= session or session.idleEpoch ~= epoch then return end
      local success, reason = self:RunActorToolScene(setup, token, idleScene, true)
      if self.toolSession == session and session.idleEpoch == epoch then
        session.idleReady = success == true
        if success then session.phase = 'idle' end
        self:EmitNet(self, 'toolIdleReady', setup.id, token, epoch, success == true, reason)
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
      self.sceneRun = nil
      self.victimJoin = nil
      session.phase = 'exit'
      local setup = self.setups[setupId]
      if setup then self:PlayIdle(setup) end
    end
  end)
  self:OnNet('stopTool', function(setupId, token, reason)
    local session = self.toolSession
    if session and session.setupId == setupId and session.token == token then
      if reason then self:TraceScene('cancel', self.sceneRun, reason); self:DumpSceneTrace(reason) end
      if self.peerScene and self.peerScene.token == token then
        self.peerScene.reason = self.peerScene.reason or reason
      end
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
    if self.activeAction and self.activeAction.token == token then return end
    if not action or self.activeAction then
      return self:EmitNet(self, 'readyAction', setup.id, token, false)
    end
    local active = {
      setupId = setup.id, token = token, key = key, stage = 0,
      actor = setup.owner == playerSource(), preparing = true,
      expiresAt = GetGameTimer() + (#action.stages * cfg.stageTimeoutMs) + cfg.prepareTimeoutMs,
    }
    self.activeAction = active
    CreateThread(function()
      if self.activeAction ~= active then return end
      local ready = fromNet(setup.props.chair, 2000) ~= nil
      if ready then
        for index, stageData in ipairs(action.stages) do
          if not self:ValidateSceneAssets(setup, stageData, function() return self.activeAction == active end) then
            print(('[vx_torture] action_asset_failed action=%s stage=%s dict=%s actor=%s victim=%s chair=%s tool=%s')
              :format(key, index, stageData.dict, stageData.actor, stageData.victim, stageData.chair, stageData.tool))
            ready = false
            break
          end
        end
      end
      if self.activeAction ~= active then return end
      active.preparing = false
      self:EmitNet(self, 'readyAction', setup.id, token, ready, not ready and 'asset_clip' or nil)
    end)
  end)
  self:OnNet('playStage', function(setup, token, key, index)
    local active = self.activeAction
    if not active or active.token ~= token or active.setupId ~= setup.id then return end
    local stageData = cfg.actions[key] and cfg.actions[key].stages[index]
    if not stageData then return end
    if active.stage and index <= active.stage then return end
    self:ExpectScene(token, 'action', index)
    active.stage = index
    if active.actor then
      CreateThread(function()
        if self.activeAction ~= active or active.stage ~= index then return end
        local success, reason = self:RunActorStage(setup, token, key, index)
        if self.activeAction ~= active or active.stage ~= index then return end
        if not success then
          print(('[vx_torture] action_stage_failed action=%s stage=%d dict=%s clip=%s token=%s')
            :format(key, index, stageData.dict, stageData.actor, token))
        end
        if success then
          self:EmitNet(self, 'stageDone', setup.id, token, index, true, self.sceneRun and self.sceneRun.scene)
        else
          self:EmitNet(self, 'stageFailed', setup.id, token, index, reason)
        end
      end)
    end
  end)
  self:OnNet('stageEffect', function(setup, token, key, index, netScene)
    self:QueueEffect(setup, token, key, index, netScene)
  end)
  self:OnNet('toolEffect', function(setup, token, kind, epoch, netScene)
    local data = cfg.toolScenes[setup.tool] and cfg.toolScenes[setup.tool][kind]
    if data then self:QueueSceneEffects(setup, token, kind .. ':' .. epoch, data, netScene, kind) end
  end)
  self:OnNet('stopEffects', function(token) self:StopEffectSounds(token) end)
  self:OnNet('stopAction', function(setupId, token, resumeIdle, reason)
    self:StopEffectSounds(token)
    if not self.activeAction or self.activeAction.token ~= token then return end
    if reason then self:TraceScene('cancel', self.sceneRun, reason); self:DumpSceneTrace(reason) end
    local actionKey = self.activeAction.key
    self.activeAction = nil
    if resumeIdle and self.toolSession and self.toolSession.setupId == setupId then
      self.sceneRun = nil
      self.victimJoin = nil
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
    self:SyncMonitorEffects()
    for _, setup in pairs(self.setups) do
      self:ApplyPropCollision(setup)
      self:AddTargets(setup)
    end
  end)
  self:Interval('effectsSync', 50, function()
    for token, run in pairs(self.activeEffects) do self:TickEffect(token, run) end
  end)
  self:Interval('sceneHealth', 100, function()
    local run = self.sceneRun
    if not run then return end
    self:SampleScene(run)
    if self.seated then self:MonitorVictimRun(run) end
  end)
  self:Interval('seatControl', 0, function()
    self:SyncHandProps()
    if self.activeAction and self.activeAction.expiresAt
      and GetGameTimer() > self.activeAction.expiresAt and not self.activeAction.expiryReported then
      local active = self.activeAction
      active.expiryReported = true
      self:DumpSceneTrace('stage_timeout')
      self:EmitNet(self, 'stageFailed', active.setupId, active.token, active.stage, 'stage_timeout')
      self:StopStage()
    end
    local session = self.toolSession
    if session and session.actor and session.phase == 'idle' and not self.activeAction
      and GetGameTimer() >= self.nextToolHealthAt then
      self.nextToolHealthAt = GetGameTimer() + 100
      local setup = self.setups[session.setupId]
      if setup and setup.toolState == 'idle' and setup.toolReady then
        local idle = cfg.toolScenes[session.tool].idle
        local reason
        if not targetReady(setup.props.chair) or not targetReady(setup.props[session.tool]) then
          reason = 'entity_missing'
        elseif not self:ActorTrackRunning(self.scene) then reason = 'actor_track_lost'
        elseif not self:SyncHandProps() then reason = 'hand_prop_lost'
        elseif not self.camera or not DoesCamExist(self.camera) then reason = 'camera_start' end
        for key in pairs(idle.props or {}) do
          if not targetReady(setup.props[key]) then reason = 'entity_missing' end
        end
        if self.toolSession ~= session or session.phase ~= 'idle' or self.activeAction then return end
        local healthy = reason == nil
        if not healthy then
          self:EmitNet(self, 'toolSceneFailed', setup.id, session.token, 'idle', session.idleEpoch, reason)
          session.phase = 'failed' -- server owns recovery; report once
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
      if activeSetup.toolState ~= 'empty' then
        local other = GetPlayerFromServerId(self.seated and activeSetup.owner or activeSetup.victim)
        if other ~= -1 then SetEntityNoCollisionEntity(PlayerPedId(), GetPlayerPed(other), true) end
      end
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
      and not nativeTrue(IsEntityPlayingAnim(PlayerPedId(), cfg.seatAlignment.dict, cfg.seatAlignment.victim, 3)) then
      self:PlayIdle(setup)
    end
  end)
end

function Impl:OnDestroy()
  self:EndPreview(nil, false)
  self.activeAction = nil
  for token in pairs(self.activeEffects) do self:StopEffectSounds(token) end
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
