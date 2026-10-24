---@class MainImpl : Impl
local Impl = NewImpl('Main')
local cfg = Config.Torture

local function distance(a, b)
  return #(a - b)
end

local function finite(value)
  return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end

local function offsetPosition(origin, heading, offset)
  local r = math.rad(heading)
  return vector3(
    origin.x + offset.x * math.cos(r) - offset.y * math.sin(r),
    origin.y + offset.x * math.sin(r) + offset.y * math.cos(r),
    origin.z + offset.z
  )
end

local function referencePosition(chair, heading, original)
  local delta = original - cfg.referenceChair
  return offsetPosition(chair, heading - cfg.referenceHeading, delta)
end

local function isAlive(src)
  if not src or not GetPlayerName(src) then return false end
  local ped = GetPlayerPed(src)
  if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
  if Player(src).state.isDead then return false end
  return GetEntityHealth(ped) > 100
end

local function near(src, entity, maxDistance)
  local ped = GetPlayerPed(src)
  return ped ~= 0 and DoesEntityExist(ped) and entity ~= 0
    and DoesEntityExist(entity)
    and distance(GetEntityCoords(ped), GetEntityCoords(entity)) <= maxDistance
end

function Impl:Notify(src, key)
  self:EmitNet(self, 'notify', src, key)
end

local function failureReason(reason, fallback)
  return type(reason) == 'string' and cfg.failureReasons[reason] and reason or fallback
end

function Impl:SceneLog(event, setup, peer, reason)
  if not cfg.sceneDiagnostics and not reason then return end
  peer = peer or setup.peerScene or {}
  print(('[vx_torture] scene_v16 event=%s setup=%s owner=%s victim=%s token=%s kind=%s step=%s scene=%s reason=%s')
    :format(event, setup.id, setup.owner, setup.victim, peer.token or setup.toolToken,
      peer.kind, peer.step, peer.netScene, reason or '-'))
end

function Impl:NotifySceneFailure(setup)
  if setup.failureNotified then return end
  setup.failureNotified = true
  self:Notify(setup.owner, 'action_failed')
end

-- Both participants report the same immutable scene identity. Reports are
-- observations only: all gameplay checks and damage remain server-owned.
function Impl:CompleteScene(src, setupId, token, kind, step, netScene, success, reason)
  local setup
  for _, candidate in pairs(self.setups) do
    if candidate.id == setupId and (src == candidate.owner or src == candidate.victim) then
      setup = candidate; break
    end
  end
  if not setup then return end
  local busy, peer = setup.busy, setup.peerScene
  local selecting = kind == 'select' and setup.toolState == 'selecting'
    and setup.toolPhase == 'playing' and setup.toolToken == token and step == 0
  local acting = kind == 'action' and busy and busy.token == token and busy.stage == step
  if not selecting and not acting then return end
  local function fail(why)
    self:SceneLog('failed', setup, peer, why)
    if acting then self:CancelAction(setup, true, why) else self:StopTool(setup, true, why) end
  end
  if not peer or peer.token ~= token or peer.kind ~= kind or peer.step ~= step then
    if src == setup.owner then fail('completion_mismatch') end
    return
  end
  if peer.netScene ~= netScene then return end
  if peer.finished or (peer.completed and peer.completed[src]) then return end
  if success ~= true then return fail(failureReason(reason, 'action_validation')) end
  if not peer.ready then return fail('peer_ready') end
  if not isAlive(setup.owner) or not isAlive(setup.victim)
    or GetPlayerRoutingBucket(setup.owner) ~= setup.bucket
    or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
    or self.seated[setup.victim] ~= setup.id or not setup.seatReady
    or not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0)
    or not near(setup.victim, setup.entities.chair, cfg.candidateDistance) then
    return fail('action_validation')
  end
  local now = GetGameTimer()
  if selecting and now - setup.toolPhaseAt < 500 then return fail('completion_early') end
  if acting then
    local stage = cfg.actions[busy.key].stages[step]
    local minimum = stage.minimumMs or math.min(stage.durationMs * 0.5, 1200)
    if now - busy.stageAt < minimum or (stage.loopMs
      and (not peer.readyAt or now - peer.readyAt < stage.loopMs)) then
      return fail('stage_too_early')
    end
  end
  if not peer.completed then
    peer.completed = {}
    SetTimeout(cfg.stageConfirmTimeoutMs, function()
      if self.setups[setup.owner] == setup and setup.peerScene == peer and not peer.finished then
        fail('completion_timeout')
      end
    end)
  end
  peer.completed[src] = true
  self:SceneLog('complete_' .. (src == setup.owner and 'actor' or 'victim'), setup, peer)
  if not peer.completed[setup.owner] or not peer.completed[setup.victim] then return end
  peer.finished = true
  if selecting then
    setup.toolPhase = nil
    self:StartToolIdle(setup)
  elseif cfg.actions[busy.key].stages[step + 1] then
    self:StartStage(setup, step + 1)
  elseif now - busy.startedAt >= cfg.minimumActionMs then
    self:FinishAction(setup)
  else
    fail('completion_early')
  end
end

function Impl:SetPropSceneAccess(setup, allowed)
  for key, entity in pairs(setup.entities) do
    if DoesEntityExist(entity) then
      local net = NetworkGetNetworkIdFromEntity(entity)
      self.sceneProps[net] = { setup = setup, key = key }
      -- Allow only our props, never either player ped. The native engine
      -- owner may change between RequestControl and the scene packet arriving.
      if SetEntityRemoteSyncedScenesAllowed then SetEntityRemoteSyncedScenesAllowed(entity, allowed) end
    end
  end
end

function Impl:CreateSetupProp(setup, key)
  local prop, pos = cfg.props[key], setup.positions[key]
  if not prop or not pos then return nil end
  local entity = CreateObjectNoOffset(joaat(prop.model), pos.x, pos.y, pos.z, true, true, false)
  if entity == 0 or not DoesEntityExist(entity) then return nil end
  FreezeEntityPosition(entity, true)
  SetEntityRoutingBucket(entity, setup.bucket)
  local rotation = setup.rotations and setup.rotations[key]
  if rotation then
    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
  elseif prop.rotation then
    SetEntityRotation(entity, prop.rotation.x, prop.rotation.y,
      (setup.heading + prop.rotation.z) % 360.0, 2, true)
  else
    SetEntityHeading(entity, setup.heading)
  end
  SetEntityOrphanMode(entity, 2)
  return entity
end

function Impl:DeleteToolProps(setup)
  -- Remove registrations even if another resource already deleted the entity.
  for net, entry in pairs(self.sceneProps) do
    if entry.setup == setup and cfg.props[entry.key].onDemand then self.sceneProps[net] = nil end
  end
  for key, entity in pairs(setup.entities) do
    if cfg.props[key] and cfg.props[key].onDemand then
      if DoesEntityExist(entity) then
        self.sceneProps[NetworkGetNetworkIdFromEntity(entity)] = nil
        DeleteEntity(entity)
      end
      setup.entities[key] = nil
    end
  end
end

function Impl:SpawnToolProps(setup, tool)
  self:DeleteToolProps(setup)
  for _, key in ipairs(cfg.toolProps[tool]) do
    local entity = self:CreateSetupProp(setup, key)
    if not entity then
      self:DeleteToolProps(setup)
      return false
    end
    setup.entities[key] = entity
  end
  return true
end

function Impl:ValidatePropScene(sender, data)
  local setup
  for _, track in ipairs(data.nonPedEntities or {}) do
    local entry = self.sceneProps[track.objectId]
    if entry then
      if setup and setup ~= entry.setup then return false end
      setup = entry.setup
    end
  end
  if not setup then return true end -- unrelated resources keep their own policy
  if self.setups[setup.owner] ~= setup or tonumber(sender) ~= setup.owner
    or setup.toolState == 'empty' or setup.toolState == 'exiting'
    or not setup.seatReady or not isAlive(setup.owner) or not isAlive(setup.victim)
    or GetPlayerRoutingBucket(setup.owner) ~= setup.bucket
    or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
    or not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0) then return false end
  local dictionaries = { [joaat('missfbi3_weapon_select_trolley')] = true }
  for _, scene in pairs(cfg.toolScenes[setup.tool] or {}) do dictionaries[joaat(scene.dict)] = true end
  for _, action in pairs(cfg.actions) do
    if action.tool == setup.tool then
      for _, scene in ipairs(action.stages) do dictionaries[joaat(scene.dict)] = true end
    end
  end
  -- Hashes arrive as unsigned uint32; joaat can be signed in Lua runtimes.
  local dictionaryAllowed = false
  for hash in pairs(dictionaries) do
    if hash == data.animDictHash or (type(hash) == 'number' and type(data.animDictHash) == 'number'
      and (hash & 0xffffffff) == (data.animDictHash & 0xffffffff)) then dictionaryAllowed = true break end
  end
  if not dictionaryAllowed or data.hasAttachEntity or #(data.mapEntities or {}) > 0 then return false end
  for _, track in ipairs(data.nonPedEntities or {}) do
    local entry = self.sceneProps[track.objectId]
    if not entry or entry.setup ~= setup then return false end
  end
  for _, track in ipairs(data.pedEntities or {}) do
    if track.objectId ~= NetworkGetNetworkIdFromEntity(GetPlayerPed(setup.owner)) then return false end
  end
  return true
end

function Impl:PlaceFailed(src, reason)
  if Config.Debug then
    print(('[vx_torture] Không đặt được ghế cho %s: %s'):format(src, reason))
  end
  self:Notify(src, 'place_failed')
end

function Impl:Snapshot(setup)
  local props = {}
  for key, entity in pairs(setup.entities) do
    if DoesEntityExist(entity) then
      props[key] = NetworkGetNetworkIdFromEntity(entity)
    end
  end
  return {
    id = setup.id,
    revision = setup.revision,
    owner = setup.owner,
    bucket = setup.bucket,
    coords = setup.coords,
    heading = setup.heading,
    positions = setup.positions,
    rotations = setup.rotations,
    props = props,
    victim = setup.victim,
    seatReady = setup.seatReady,
    tool = setup.tool,
    toolReady = setup.toolReady,
    toolState = setup.toolState,
    toolToken = setup.toolToken,
    toolEpoch = setup.toolEpoch,
    busy = setup.busy ~= nil,
  }
end

function Impl:Sync(setup)
  setup.revision = (setup.revision or 0) + 1
  self:EmitNet(self, 'setupUpdated', -1, self:Snapshot(setup))
end

function Impl:GetOwned(src, setupId)
  local setup = self.setups[src]
  if not setup or setup.id ~= setupId then return nil end
  if GetPlayerRoutingBucket(src) ~= setup.bucket or not isAlive(src) then return nil end
  return setup
end

function Impl:StopTool(setup, failed, reason)
  if not setup.tool or setup.toolState == 'empty' then return end
  local token = setup.toolToken
  setup.lastStoppedToolToken = token
  self:SetPropSceneAccess(setup, false)
  self:EmitNet(self, 'stopEffects', -1, token)
  if failed then
    reason = failureReason(reason, 'tool_validation')
    local peer = setup.peerScene
    print(('[vx_torture] tool_failed setup=%s owner=%s victim=%s tool=%s state=%s phase=%s token=%s peer=%s peerReady=%s reason=%s')
      :format(setup.id, setup.owner, setup.victim, setup.tool, setup.toolState,
        setup.toolPhase, token, peer and peer.kind, peer and peer.ready, reason or 'tool_validation'))
  end
  self:EmitNet(self, 'stopTool', setup.owner, setup.id, token, reason)
  if setup.victim then self:EmitNet(self, 'stopTool', setup.victim, setup.id, token, reason) end
  self:DeleteToolProps(setup)
  setup.tool = nil
  setup.toolReady = false
  setup.toolState = 'empty'
  setup.toolToken = nil
  setup.toolPhase = nil
  setup.toolPhaseAt = nil
  setup.toolReadyPeers = nil
  setup.peerScene = nil
  setup.sceneHandoff = nil
  setup.lastActorScene = nil
  self:Sync(setup)
  if failed then self:NotifySceneFailure(setup) end
end

function Impl:StartToolIdle(setup)
  if not setup.tool or not setup.victim or not setup.seatReady
    or not isAlive(setup.victim) or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
    or not near(setup.victim, setup.entities.chair, cfg.candidateDistance)
    or not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0) then
    return self:StopTool(setup, true, 'tool_validation')
  end
  self:EmitNet(self, 'stopEffects', -1, setup.toolToken)
  setup.toolState = 'idle'
  setup.toolPhase = nil
  setup.toolEpoch = (setup.toolEpoch or 0) + 1
  setup.toolReady = false
  setup.toolPhaseAt = GetGameTimer()
  setup.toolReadyPeers = {}
  setup.peerScene = nil
  self:Sync(setup)
  local snapshot = self:Snapshot(setup)
  self:EmitNet(self, 'startToolIdle', setup.victim, snapshot, setup.toolToken, setup.toolEpoch)
  self:EmitNet(self, 'startToolIdle', setup.owner, snapshot, setup.toolToken, setup.toolEpoch)
  local token, phaseAt = setup.toolToken, setup.toolPhaseAt
  SetTimeout(cfg.toolIdleTimeoutMs, function()
    if self.setups[setup.owner] == setup and setup.toolToken == token
      and setup.toolState == 'idle' and setup.toolPhaseAt == phaseAt
      and not setup.toolReady then self:StopTool(setup, true, 'idle_timeout') end
  end)
end

function Impl:CancelAction(setup, notifyOwner, reason)
  local busy = setup.busy
  if not busy then return end
  if notifyOwner then self:SceneLog('cancel', setup, setup.peerScene,
    failureReason(reason, 'action_validation')) end
  setup.busy = nil
  local resumeIdle = setup.toolState == 'action' and setup.victim and setup.seatReady
    and isAlive(setup.owner) and isAlive(setup.victim)
    and GetPlayerRoutingBucket(setup.owner) == setup.bucket
    and GetPlayerRoutingBucket(setup.victim) == setup.bucket
  self:EmitNet(self, 'stopEffects', -1, busy.token)
  self:EmitNet(self, 'stopAction', setup.owner, setup.id, busy.token, resumeIdle == true, notifyOwner and failureReason(reason, 'action_validation') or nil)
  if setup.victim then
    self:EmitNet(self, 'stopAction', setup.victim, setup.id, busy.token, resumeIdle == true, notifyOwner and failureReason(reason, 'action_validation') or nil)
  end
  if notifyOwner then self:NotifySceneFailure(setup) end
  if resumeIdle then
    self:StartToolIdle(setup)
  elseif setup.toolState == 'action' then
    self:StopTool(setup)
  else
    self:Sync(setup)
  end
end

function Impl:Release(setup)
  -- Clear the action first without starting a new idle scene during teardown.
  local busy = setup.busy
  if busy then
    setup.busy = nil
    self:EmitNet(self, 'stopEffects', -1, busy.token)
    self:EmitNet(self, 'stopAction', setup.owner, setup.id, busy.token)
    if setup.victim then self:EmitNet(self, 'stopAction', setup.victim, setup.id, busy.token) end
  end
  self:StopTool(setup)
  local victim = setup.victim
  if not victim then return end
  setup.victim = nil
  setup.seatReady = false
  self.seated[victim] = nil
  self:EmitNet(self, 'releaseSeat', victim, setup.id)
  self:Sync(setup)
end

function Impl:Pack(setup, notifyOwner)
  self:Release(setup)
  for net, entry in pairs(self.sceneProps) do
    if entry.setup == setup then self.sceneProps[net] = nil end
  end
  self.setups[setup.owner] = nil
  self.pending[setup.owner] = nil
  self:EmitNet(self, 'setupRemoved', -1, setup.id)
  for _, entity in pairs(setup.entities) do
    if DoesEntityExist(entity) then DeleteEntity(entity) end
  end
  if notifyOwner then self:Notify(setup.owner, 'packed') end
end

function Impl:Candidates(setup)
  local result = {}
  local chair = setup.entities.chair
  if not chair or not DoesEntityExist(chair) then return result end
  local chairPos = GetEntityCoords(chair)
  for _, raw in ipairs(GetPlayers()) do
    local src = tonumber(raw)
    if src ~= setup.owner and not self.seated[src] and isAlive(src)
      and GetPlayerRoutingBucket(src) == setup.bucket
      and distance(GetEntityCoords(GetPlayerPed(src)), chairPos) <= cfg.candidateDistance then
      result[#result + 1] = { id = src, name = GetPlayerName(src) }
    end
  end
  table.sort(result, function(a, b) return a.id < b.id end)
  return result
end

function Impl:BeginPlacement(src)
  if self.destroyed then return end
  if self.setups[src] then return self:Notify(src, 'already_placed') end
  if self.pending[src] then return self:Notify(src, 'placement_busy') end
  if not isAlive(src) or GetVehiclePedIsIn(GetPlayerPed(src), false) ~= 0 then
    return self:Notify(src, 'invalid_state')
  end
  if exports.ox_inventory:GetItemCount(src, cfg.item) < 1 then
    return self:Notify(src, 'no_item')
  end

  self.nextId = self.nextId + 1
  local token = self.nextId
  self.pending[src] = token
  self:EmitNet(self, 'beginPlacement', src, token)
  SetTimeout(cfg.placementTimeoutMs, function()
    if self.pending[src] == token then
      self.pending[src] = nil
      self:EmitNet(self, 'cancelPreview', src, token)
      self:Notify(src, 'preview_timeout')
    end
  end)
end

function Impl:Place(src, token, placement)
  if self.pending[src] ~= token then return end
  self.pending[src] = nil
  if type(placement) ~= 'table' or type(placement.coords) ~= 'vector3'
    or type(placement.positions) ~= 'table' or type(placement.rotations) ~= 'table'
    or not finite(placement.heading) or placement.heading < 0.0 or placement.heading > 360.0 then
    return self:PlaceFailed(src, 'payload')
  end
  if self.setups[src] or not isAlive(src)
    or GetVehiclePedIsIn(GetPlayerPed(src), false) ~= 0
    or exports.ox_inventory:GetItemCount(src, cfg.item) < 1 then
    return self:Notify(src, 'invalid_state')
  end
  local ped = GetPlayerPed(src)
  local coords = placement.coords
  if not finite(coords.x) or not finite(coords.y) or not finite(coords.z) then
    return self:PlaceFailed(src, 'coords')
  end
  local expected = offsetPosition(GetEntityCoords(ped), GetEntityHeading(ped), vector3(0.0, cfg.placementDistance, 0.0))
  if distance(coords, expected) > 1.25 or math.abs(coords.z - GetEntityCoords(ped).z) > 1.5 then
    return self:PlaceFailed(src, 'distance_from_player')
  end
  local positions, rotations = {}, {}
  for _, key in ipairs(cfg.propOrder) do
    local prop = cfg.props[key]
    local position = placement.positions[key]
    if position ~= nil then
      if type(position) ~= 'vector3' or not finite(position.x) or not finite(position.y)
        or not finite(position.z) then
        return self:PlaceFailed(src, key .. ':position')
      end
      if prop.restClip then
        -- FBI3 computes each object's root from its animation track. That
        -- root need not match the old display offset or the visible mesh.
        if (position.x - coords.x) ^ 2 + (position.y - coords.y) ^ 2 > 6.0 ^ 2
          or math.abs(position.z - coords.z) > 5.0 then
          return self:PlaceFailed(src, key .. ':scene_bounds')
        end
      else
        local expectedXY = prop.referencePosition
          and referencePosition(positions.chair or coords, placement.heading, prop.referencePosition)
          or offsetPosition(coords, placement.heading, prop.offset)
        if math.abs(position.x - expectedXY.x) > 0.1
          or math.abs(position.y - expectedXY.y) > 0.1
          or math.abs(position.z - coords.z) > 3.0 then
          return self:PlaceFailed(src, key .. ':offset')
        end
      end
      local rotation = placement.rotations[key]
      if prop.restClip or prop.referencePosition then
        if type(rotation) ~= 'vector3' or not finite(rotation.x)
          or not finite(rotation.y) or not finite(rotation.z)
          or math.abs(rotation.x) > 1080.0 or math.abs(rotation.y) > 1080.0
          or math.abs(rotation.z) > 1080.0 then
          return self:PlaceFailed(src, key .. ':rotation')
        end
        rotations[key] = rotation
      end
      positions[key] = position
    elseif prop.required then
      return self:PlaceFailed(src, key .. ':missing')
    end
  end
  if positions.trolley then
    for _, key in ipairs(cfg.propOrder) do
      local prop, position = cfg.props[key], positions[key]
      if prop.surface == 'trolley' and position
        and (position.x - positions.trolley.x) ^ 2
          + (position.y - positions.trolley.y) ^ 2 > 6.0 ^ 2 then
        return self:PlaceFailed(src, key .. ':trolley_bounds')
      end
    end
  end
  local bucket = GetPlayerRoutingBucket(src)
  for _, other in pairs(self.setups) do
    if other.bucket == bucket and distance(coords, other.coords) < cfg.minSetupSpacing then
      return self:PlaceFailed(src, 'too_close_to_setup')
    end
  end

  local entities = {}
  local placementSetup = { positions = positions, rotations = rotations,
    bucket = bucket, heading = placement.heading }
  for _, key in ipairs(cfg.propOrder) do
    local prop = cfg.props[key]
    if not prop.onDemand then
      local entity = self:CreateSetupProp(placementSetup, key)
      if entity then
        entities[key] = entity
      elseif prop.required then
        for _, spawned in pairs(entities) do DeleteEntity(spawned) end
        return self:PlaceFailed(src, key .. ':spawn')
      end
    end
  end
  local setup = {
    id = token, owner = src, bucket = bucket, coords = coords,
    heading = placement.heading, positions = positions, rotations = rotations,
    entities = entities,
    victim = nil, seatReady = false, tool = nil, toolReady = false,
    toolState = 'empty', toolToken = nil, toolEpoch = 0,
    busy = nil, revision = 0,
  }
  self.setups[src] = setup
  self:Sync(setup)
  SetTimeout(750, function()
    if self.setups[src] == setup then self:Sync(setup) end
  end)
  self:Notify(src, 'placed')
end

function Impl:Seat(src, setupId, victim)
  local setup = self:GetOwned(src, setupId)
  if not setup or setup.victim or setup.busy
    or not near(src, setup.entities.chair, cfg.interactDistance) then
    return self:Notify(src, 'invalid_state')
  end
  victim = tonumber(victim)
  if not victim or victim == src then return self:Notify(src, 'target_lost') end
  local valid = false
  for _, candidate in ipairs(self:Candidates(setup)) do
    if candidate.id == victim then valid = true break end
  end
  if not valid then return self:Notify(src, 'target_lost') end
  setup.victim = victim
  setup.seatReady = false
  self.seated[victim] = setup.id
  self:Sync(setup)
  self:EmitNet(self, 'seat', victim, self:Snapshot(setup))
  SetTimeout(cfg.seatTimeoutMs, function()
    if self.setups[src] == setup and setup.victim == victim and not setup.seatReady then
      self:Release(setup)
      self:Notify(src, 'action_failed')
    end
  end)
end

function Impl:TakeTool(src, setupId, tool)
  local setup = self:GetOwned(src, setupId)
  if not setup or setup.busy or setup.toolState ~= 'empty'
    or not cfg.toolScenes[tool] or not cfg.toolProps[tool]
    or not setup.victim or not setup.seatReady
    or self.seated[setup.victim] ~= setup.id or not isAlive(setup.victim)
    or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
    or not near(setup.victim, setup.entities.chair, cfg.candidateDistance)
    or not near(src, setup.entities.trolley, cfg.actionDistance) then
    return self:Notify(src, 'invalid_state')
  end
  if not self:SpawnToolProps(setup, tool) then
    self:Sync(setup)
    return self:Notify(src, 'action_failed')
  end
  setup.failureNotified = false
  self.nextTool = self.nextTool + 1
  setup.tool = tool
  setup.toolReady = false
  setup.toolState = 'selecting'
  setup.toolToken = ('%d:tool:%d'):format(setup.id, self.nextTool)
  setup.toolEpoch = 0
  setup.toolPhase = nil
  setup.toolPhaseAt = GetGameTimer()
  setup.toolReadyPeers = {}
  self:SetPropSceneAccess(setup, true)
  self:Sync(setup)
  local snapshot = self:Snapshot(setup)
  self:EmitNet(self, 'prepareTool', src, snapshot, setup.toolToken)
  self:EmitNet(self, 'prepareTool', setup.victim, snapshot, setup.toolToken)
  local token, phaseAt = setup.toolToken, setup.toolPhaseAt
  SetTimeout(cfg.toolPrepareTimeoutMs, function()
    if self.setups[src] == setup and setup.toolToken == token
      and setup.toolState == 'selecting' and setup.toolPhase == nil
      and setup.toolPhaseAt == phaseAt then
      self:StopTool(setup, true, 'prepare_timeout')
    end
  end)
end

function Impl:StartStage(setup, index)
  local busy = setup.busy
  if not busy then return end
  local action = cfg.actions[busy.key]
  local stageData = action.stages[index]
  if not stageData then return self:CancelAction(setup, true, 'action_validation') end
  if busy.stage > 0 then self:EmitNet(self, 'stopEffects', -1, busy.token) end
  busy.stage = index
  busy.stageAt = GetGameTimer()
  setup.peerScene = nil
  local snapshot = self:Snapshot(setup)
  self:EmitNet(self, 'playStage', setup.victim, snapshot, busy.token, busy.key, index)
  self:EmitNet(self, 'playStage', setup.owner, snapshot, busy.token, busy.key, index)
  SetTimeout(cfg.stageTimeoutMs, function()
    if self.setups[setup.owner] == setup and setup.busy == busy and busy.stage == index then
      self:CancelAction(setup, true, 'stage_timeout')
    end
  end)
end

function Impl:StartAction(src, setupId, victim, actionKey)
  local setup = self:GetOwned(src, setupId)
  local action = cfg.actions[actionKey]
  if not setup or not action or not setup.victim or setup.victim ~= tonumber(victim)
    or not setup.seatReady or setup.busy or setup.tool ~= action.tool or not setup.toolReady
    or setup.toolState ~= 'idle'
    or not isAlive(setup.victim) or self.seated[setup.victim] ~= setup.id
    or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
    or not near(setup.victim, setup.entities.chair, cfg.candidateDistance)
    or not near(src, setup.entities.chair, cfg.actionDistance) then
    return self:Notify(src, 'invalid_state')
  end
  setup.failureNotified = false
  self.nextAction = self.nextAction + 1
  local token = ('%d:%d'):format(setup.id, self.nextAction)
  local busy = { token = token, key = actionKey, ready = {}, stage = 0, startedAt = nil }
  setup.busy = busy
  self:EmitNet(self, 'stopEffects', -1, setup.toolToken)
  setup.toolState = 'action'
  setup.toolReady = false
  self:Sync(setup)
  local snapshot = self:Snapshot(setup)
  self:EmitNet(self, 'prepareAction', src, snapshot, token, actionKey)
  self:EmitNet(self, 'prepareAction', setup.victim, snapshot, token, actionKey)
  SetTimeout(cfg.prepareTimeoutMs, function()
    if self.setups[src] == setup and setup.busy == busy and busy.stage == 0 then
      self:CancelAction(setup, true, 'prepare_timeout')
    end
  end)
end

function Impl:FinishAction(setup)
  local busy = setup.busy
  if not busy then return end
  local action = cfg.actions[busy.key]
  local victim = setup.victim
  if not action or not victim or not isAlive(victim)
    or GetPlayerRoutingBucket(victim) ~= setup.bucket
    or not near(victim, setup.entities.chair, cfg.candidateDistance)
    or not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0) then
    return self:CancelAction(setup, true, 'action_validation')
  end
  local result = action.result
  if result.mode == 'kill' then
    self:Release(setup)
    self:EmitNet(self, 'killVictim', victim, setup.id)
  elseif result.mode == 'damage' and type(result.amount) == 'number'
    and result.amount > 0 and result.amount <= 200 then
    self:CancelAction(setup, false)
    self:EmitNet(self, 'applyDamage', victim, setup.id, math.floor(result.amount))
  else
    self:CancelAction(setup, true, 'action_validation')
  end
end

function Impl:Init()
  self.sceneProps = {}
  self.setups = {}
  self.seated = {}
  self.pending = {}
  self.nextId = 0
  self.nextAction = 0
  self.nextTool = 0
end

function Impl:OnReady()
  print(('[vx_torture] scene handoff v16 loaded (server) artifact=%s enforcedBuild=%s')
    :format(GetConvar and GetConvar('version', 'unknown') or 'unknown',
      GetConvar and GetConvar('sv_enforceGameBuild', 'unknown') or 'unknown'))
  self:AddEventHandler('startNetworkSyncedSceneEvent', function(sender, data)
    if not self:ValidatePropScene(sender, data) then
      CancelEvent()
      if Config.Debug then
        print(('[vx_torture] prop_scene_rejected sender=%s scene=%s dict=%s')
          :format(sender, data.sceneId, data.animDictHash))
      end
    end
  end)
  exports.qbx_core:CreateUseableItem(cfg.item, function(src)
    self:BeginPlacement(src)
  end)
  self:OnNet('confirmPlacement', function(token, placement)
    self:Place(source, token, placement)
  end)
  self:OnNet('cancelPlacement', function(token)
    if self.pending[source] == token then self.pending[source] = nil end
  end)
  self:RegisterCallback('getSetups', function()
    local snapshots = {}
    for _, setup in pairs(self.setups) do
      snapshots[#snapshots + 1] = self:Snapshot(setup)
    end
    return snapshots
  end)
  self:RegisterCallback('getCandidates', function(src, setupId)
    local setup = self:GetOwned(src, setupId)
    if not setup or setup.victim or not near(src, setup.entities.chair, cfg.interactDistance) then return {} end
    return self:Candidates(setup)
  end)
  self:OnNet('seat', function(setupId, victim) self:Seat(source, setupId, victim) end)
  local function sceneStage(setup, token, kind, step)
    if kind == 'action' then
      local busy = setup.busy
      if busy and busy.token == token and busy.stage == step then
        local stage = cfg.actions[busy.key].stages[step]
        if stage then return stage, stage.loopMs ~= nil or stage.victimLoop == true end
      end
    elseif setup.toolToken == token and setup.tool and cfg.toolScenes[setup.tool] then
      if kind == 'select' and step == 0 and setup.toolState == 'selecting'
        and setup.toolPhase == 'playing' then
        local scene = cfg.toolScenes[setup.tool].select
        return scene, scene.victimLoop == true
      elseif kind == 'idle' and setup.toolState == 'idle' and setup.toolEpoch == step then
        return cfg.toolScenes[setup.tool].idle, true
      end
    end
  end
  local function handoffValid(setup)
    return setup and setup.victim and setup.seatReady and self.seated[setup.victim] == setup.id
      and isAlive(setup.owner) and isAlive(setup.victim)
      and GetPlayerRoutingBucket(setup.owner) == setup.bucket
      and GetPlayerRoutingBucket(setup.victim) == setup.bucket
      and near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0)
      and near(setup.victim, setup.entities.chair, cfg.candidateDistance)
  end
  self:OnNet('requestSceneHandoff', function(setupId, token, kind, step, previous, nextScene)
    local setup = self:GetOwned(source, setupId)
    if not handoffValid(setup) or not sceneStage(setup, token, kind, step) then return end
    if not finite(nextScene) or nextScene < 0 or nextScene % 1 ~= 0 or nextScene > 2147483647
      or previous == nextScene then return end
    local old = setup.lastActorScene
    if not old or old.netScene ~= previous then
      self:EmitNet(self, 'sceneHandoffReady', setup.owner, token, kind, step,
        previous, nextScene, false, 'handoff_mismatch')
      return
    end
    local prior = setup.sceneHandoff
    if prior and prior.token == token and prior.kind == kind and prior.step == step then return end
    local pending = { token = token, kind = kind, step = step, previous = previous,
      nextScene = nextScene, expires = GetGameTimer() + cfg.scenePeerTimeoutMs }
    setup.sceneHandoff = pending
    self:EmitNet(self, 'awaitSceneHandoff', setup.victim, self:Snapshot(setup), token,
      kind, step, previous, nextScene, { dict = old.dict, clip = old.clip })
  end)
  self:OnNet('sceneHandoffObserved', function(setupId, token, kind, step, previous, nextScene, success, reason)
    local setup
    for _, candidate in pairs(self.setups) do
      if candidate.id == setupId and candidate.victim == source then setup = candidate; break end
    end
    local pending = setup and setup.sceneHandoff
    if not pending or pending.reported or pending.token ~= token or pending.kind ~= kind
      or pending.step ~= step or pending.previous ~= previous or pending.nextScene ~= nextScene
      or GetGameTimer() > pending.expires or not sceneStage(setup, token, kind, step)
      or not handoffValid(setup) then return end
    pending.reported = true
    pending.ready = success == true
    self:EmitNet(self, 'sceneHandoffReady', setup.owner, token, kind, step, previous,
      nextScene, pending.ready, not pending.ready and failureReason(reason, 'handoff_timeout') or nil)
  end)
  self:OnNet('bindVictimScene', function(setupId, token, kind, step, netScene, victimClock)
    local setup = self:GetOwned(source, setupId)
    if not setup or not setup.victim or not finite(netScene) or netScene < 0
      or netScene % 1 ~= 0 or netScene > 2147483647 then return end
    local function reject(reason)
      print(('[vx_torture] peer_bind_rejected reason=%s setup=%s token=%s kind=%s step=%s scene=%s')
        :format(reason, setupId, token, kind, step, netScene))
      self:EmitNet(self, 'victimSceneReady', setup.owner, token, kind, step, netScene, false, reason)
    end
    local scene, looped = sceneStage(setup, token, kind, step)
    if not scene then return reject('server_stage_mismatch') end
    local handoff = setup.sceneHandoff
    if handoff and handoff.token == token and handoff.kind == kind and handoff.step == step
      and (not handoff.ready or handoff.nextScene ~= netScene) then return reject('handoff_mismatch') end
    if victimClock ~= nil and ((kind ~= 'select' and kind ~= 'action') or not scene.victimLoop
      or not finite(victimClock) or victimClock < 0 or victimClock % 1 ~= 0
      or victimClock > 2147483647 or victimClock == netScene) then
      return reject('invalid_victim_clock')
    end
    if not isAlive(setup.victim) then return reject('victim_not_alive') end
    if GetPlayerRoutingBucket(setup.victim) ~= setup.bucket then return reject('victim_bucket') end
    if not near(source, setup.entities.chair, cfg.actionDistance + 1.0) then
      return reject('actor_distance')
    end
    local previous = setup.peerScene
    if previous and previous.token == token and previous.kind == kind and previous.step == step then return end
    setup.peerScene = { token = token, kind = kind, step = step, netScene = netScene,
      victimClock = victimClock, ready = false }
    setup.lastActorScene = { netScene = netScene, dict = scene.dict, clip = scene.actor }
    self:SceneLog("bind", setup, setup.peerScene)
    self:EmitNet(self, 'joinVictimScene', setup.victim, self:Snapshot(setup), token, kind, step, netScene, scene, looped, victimClock)
  end)
  self:OnNet('victimSceneReady', function(setupId, token, kind, step, netScene, success, reason)
    local setup
    for _, candidate in pairs(self.setups) do
      if candidate.id == setupId and candidate.victim == source then setup = candidate break end
    end
    local peer = setup and setup.peerScene
    if not peer or peer.ready or peer.token ~= token or peer.kind ~= kind
      or peer.step ~= step or peer.netScene ~= netScene or not sceneStage(setup, token, kind, step) then return end
    self:SceneLog('ready', setup, peer)
    peer.ready = success == true and isAlive(source) and GetPlayerRoutingBucket(source) == setup.bucket
    -- Diagnostic reasons are a fixed vocabulary, never client-provided log text.
    local reasons = { victim_wrong_seat = true, victim_state_timeout = true,
      victim_scene_late = true, victim_track_failed = true, victim_state_changed = true,
      remote_scene_timeout = true, remote_actor_timeout = true }
    local failure = not peer.ready and (reasons[reason] and reason or 'victim_rejected') or nil
    if failure then
      print(('[vx_torture] peer_ack_failed reason=%s setup=%s token=%s kind=%s step=%s scene=%s')
        :format(failure, setupId, token, kind, step, netScene))
    end
    self:EmitNet(self, 'victimSceneReady', setup.owner, token, kind, step, netScene, peer.ready, failure)
    if peer.ready then
      peer.readyAt = GetGameTimer()
      self:EmitNet(self, 'scenePeersReady', setup.victim, token, kind, step, netScene)
    end
    if peer.ready and kind == 'action' then
      self:EmitNet(self, 'stageEffect', -1, self:Snapshot(setup), token, setup.busy.key, step, netScene)
    elseif peer.ready and (kind == 'select' or kind == 'idle') then
      self:EmitNet(self, 'toolEffect', -1, self:Snapshot(setup), token, kind, step, netScene)
    end
  end)
  self:OnNet('seatReady', function(setupId, success)
    local setup
    for _, candidate in pairs(self.setups) do
      if candidate.id == setupId and candidate.victim == source then setup = candidate break end
    end
    if not setup or setup.victim ~= source or setup.seatReady then return end
    if success and isAlive(source) and GetPlayerRoutingBucket(source) == setup.bucket
      and near(source, setup.entities.chair, cfg.candidateDistance) then
      setup.seatReady = true
      self:Sync(setup)
    else
      self:Release(setup)
    end
  end)
  self:OnNet('seatRecoveryFailed', function(setupId, token)
    for _, setup in pairs(self.setups) do
      if setup.id == setupId and setup.victim == source and setup.toolState == 'empty'
        and setup.lastStoppedToolToken == token then
        self:SceneLog('release', setup, nil, 'seat_recovery_failed')
        self:Release(setup)
        return
      end
    end
  end)
  self:OnNet('release', function(setupId)
    local setup = self:GetOwned(source, setupId)
    if setup and near(source, setup.entities.chair, cfg.interactDistance) then self:Release(setup) end
  end)
  self:OnNet('pack', function(setupId)
    local setup = self:GetOwned(source, setupId)
    if setup and near(source, setup.entities.chair, cfg.interactDistance) then self:Pack(setup, true) end
  end)
  self:OnNet('takeTool', function(setupId, tool) self:TakeTool(source, setupId, tool) end)
  self:OnNet('exitTool', function(setupId, token)
    local setup = self:GetOwned(source, setupId)
    if setup and setup.toolToken == token and setup.toolState == 'idle'
      and setup.toolReady and not setup.busy
      and near(source, setup.entities.chair, cfg.actionDistance + 1.0) then
      self:EmitNet(self, 'stopEffects', -1, setup.toolToken)
      setup.toolState = 'exiting'
      setup.toolReady = false
      setup.toolPhaseAt = GetGameTimer()
      self:Sync(setup)
      self:EmitNet(self, 'playToolExit', setup.owner, self:Snapshot(setup), token)
      if setup.victim then self:EmitNet(self, 'restoreToolVictim', setup.victim, setup.id, token) end
      local phaseAt = setup.toolPhaseAt
      SetTimeout(cfg.toolExitTimeoutMs, function()
        if self.setups[setup.owner] == setup and setup.toolToken == token
          and setup.toolState == 'exiting' and setup.toolPhaseAt == phaseAt then
          self:StopTool(setup, true, 'exit_timeout')
        end
      end)
    else
      self:Notify(source, 'invalid_state')
    end
  end)
  self:OnNet('readyTool', function(setupId, token, success, reason)
    local setup = self.setups[source]
    if not setup or setup.id ~= setupId then
      for _, candidate in pairs(self.setups) do
        if candidate.id == setupId and candidate.victim == source then setup = candidate break end
      end
    end
    if not setup or setup.id ~= setupId or setup.toolToken ~= token
      or setup.toolState ~= 'selecting' or setup.toolPhase ~= nil
      or (source ~= setup.owner and source ~= setup.victim) then return end
    if not success then return self:StopTool(setup, true, failureReason(reason, 'asset_clip')) end
    setup.toolReadyPeers[source] = true
    if setup.toolReadyPeers[setup.owner] and setup.toolReadyPeers[setup.victim] then
      setup.toolReadyPeers = {}
      setup.toolPhase = 'playing'
      setup.toolPhaseAt = GetGameTimer()
      local snapshot = self:Snapshot(setup)
      self:EmitNet(self, 'playToolSelect', setup.victim, snapshot, token)
      self:EmitNet(self, 'playToolSelect', setup.owner, snapshot, token)
      local phaseAt = setup.toolPhaseAt
      SetTimeout(cfg.toolSelectTimeoutMs + 4000, function()
        if self.setups[setup.owner] == setup and setup.toolToken == token
          and setup.toolState == 'selecting' and setup.toolPhaseAt == phaseAt then
          self:StopTool(setup, true, 'stage_timeout')
        end
      end)
    end
  end)
  self:OnNet('sceneComplete', function(setupId, token, kind, step, netScene, success, reason)
    self:CompleteScene(source, setupId, token, kind, step, netScene, success, reason)
  end)
  self:OnNet('toolSelected', function(setupId, token, success, netScene, reason)
    self:CompleteScene(source, setupId, token, 'select', 0, netScene, success, reason)
  end)
  self:OnNet('toolSceneFailed', function(setupId, token, kind, step, reason)
    for _, setup in pairs(self.setups) do
      if setup.id == setupId and (source == setup.owner or source == setup.victim)
        and setup.toolToken == token
        and ((kind == 'select' and step == 0 and setup.toolState == 'selecting')
          or (kind == 'idle' and step == setup.toolEpoch and setup.toolState == 'idle')) then
        self:StopTool(setup, true, failureReason(reason, 'tool_validation'))
        return
      end
    end
  end)
  self:OnNet('toolIdleReady', function(setupId, token, epoch, success, reason)
    local setup = self.setups[source]
    if not setup or setup.id ~= setupId then
      for _, candidate in pairs(self.setups) do
        if candidate.id == setupId and candidate.victim == source then setup = candidate break end
      end
    end
    if not setup or setup.id ~= setupId or setup.toolToken ~= token
      or setup.toolEpoch ~= epoch
      or setup.toolState ~= 'idle' or setup.toolReady
      or (source ~= setup.owner and source ~= setup.victim) then return end
    if not success then return self:StopTool(setup, true, failureReason(reason, 'asset_clip')) end
    local peer = setup.peerScene
    if not peer or not peer.ready or peer.kind ~= 'idle' or peer.token ~= token or peer.step ~= epoch then return end
    setup.toolReadyPeers[source] = true
    if setup.toolReadyPeers[setup.owner] and setup.toolReadyPeers[setup.victim] then
      setup.toolReady = true
      self:Sync(setup)
    end
  end)
  self:OnNet('toolExited', function(setupId, token, success)
    local setup = self:GetOwned(source, setupId)
    if not setup or setup.toolToken ~= token or setup.toolState ~= 'exiting' then return end
    self:StopTool(setup, not success)
  end)
  self:OnNet('startAction', function(setupId, victim, actionKey)
    self:StartAction(source, setupId, victim, actionKey)
  end)
  self:OnNet('readyAction', function(setupId, token, success, reason)
    for _, setup in pairs(self.setups) do
      local busy = setup.busy
      if setup.id == setupId and busy and busy.token == token
        and (source == setup.owner or source == setup.victim) and busy.stage == 0 then
        if not success then return self:CancelAction(setup, true, failureReason(reason, 'asset_clip')) end
        busy.ready[source] = true
        if busy.ready[setup.owner] and busy.ready[setup.victim] then
          busy.startedAt = GetGameTimer()
          self:StartStage(setup, 1)
        end
        return
      end
    end
  end)
  self:OnNet('stageDone', function(setupId, token, index, success, netScene, reason)
    self:CompleteScene(source, setupId, token, 'action', index, netScene, success, reason)
  end)
  self:OnNet('stageFailed', function(setupId, token, index, reason)
    for _, setup in pairs(self.setups) do
      local busy = setup.busy
      if setup.id == setupId and (source == setup.victim or source == setup.owner) and busy
        and busy.token == token and busy.stage == index then
        return self:CancelAction(setup, true, failureReason(reason, 'victim_track_failed'))
      end
    end
  end)
  self:AddEventHandler('playerDropped', function()
    local src = source
    self.pending[src] = nil
    local owned = self.setups[src]
    if owned then self:Pack(owned, false) end
    for _, setup in pairs(self.setups) do
      if setup.victim == src then self:Release(setup) end
    end
  end)
  self:Interval('sessionHealth', 500, function()
    for _, setup in pairs(self.setups) do
      if not isAlive(setup.owner) or GetPlayerRoutingBucket(setup.owner) ~= setup.bucket
        or not DoesEntityExist(setup.entities.chair) then
        self:Pack(setup, false)
      elseif setup.victim and (not isAlive(setup.victim)
        or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
        or not near(setup.victim, setup.entities.chair, cfg.candidateDistance + 1.0)) then
        self:Release(setup)
      elseif setup.busy and not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0) then
        self:CancelAction(setup, true, 'action_validation')
      elseif setup.toolState ~= 'empty' and not setup.busy
        and not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.5) then
        self:StopTool(setup, true, 'actor_distance_health')
      end
    end
  end)
end

function Impl:OnDestroy()
  for _, setup in pairs(self.setups) do self:Pack(setup, false) end
end

function Impl:OnResourceStop()
  self:OnDestroy()
end
