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

function Impl:StopTool(setup, failed)
  if not setup.tool or setup.toolState == 'empty' then return end
  local token = setup.toolToken
  if failed then
    local peer = setup.peerScene
    print(('[vx_torture] tool_failed setup=%s owner=%s victim=%s tool=%s state=%s phase=%s token=%s peer=%s peerReady=%s')
      :format(setup.id, setup.owner, setup.victim, setup.tool, setup.toolState,
        setup.toolPhase, token, peer and peer.kind, peer and peer.ready))
  end
  self:EmitNet(self, 'stopTool', setup.owner, setup.id, token)
  if setup.victim then self:EmitNet(self, 'stopTool', setup.victim, setup.id, token) end
  setup.tool = nil
  setup.toolReady = false
  setup.toolState = 'empty'
  setup.toolToken = nil
  setup.toolPhase = nil
  setup.toolPhaseAt = nil
  setup.toolReadyPeers = nil
  setup.peerScene = nil
  self:Sync(setup)
  print(failed, 'action_failed')
  if failed then self:Notify(setup.owner, 'action_failed') end
end

function Impl:StartToolIdle(setup)
  print(setup.tool, setup.victim, setup.seatReady, isAlive(setup.victim), GetPlayerRoutingBucket(setup.victim), setup.bucket, near(setup.victim, setup.entities.chair, cfg.candidateDistance), near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0))
  if not setup.tool or not setup.victim or not setup.seatReady
    or not isAlive(setup.victim) or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
    or not near(setup.victim, setup.entities.chair, cfg.candidateDistance)
    or not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.0) then
    return self:StopTool(setup, true)
  end
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
      and not setup.toolReady then self:StopTool(setup, true) end
  end)
end

function Impl:CancelAction(setup, notifyOwner)
  local busy = setup.busy
  if not busy then return end
  setup.busy = nil
  local resumeIdle = setup.toolState == 'action' and setup.victim and setup.seatReady
    and isAlive(setup.victim) and GetPlayerRoutingBucket(setup.victim) == setup.bucket
  self:EmitNet(self, 'stopEffects', -1, busy.token)
  self:EmitNet(self, 'stopAction', setup.owner, setup.id, busy.token, resumeIdle == true)
  if setup.victim then
    self:EmitNet(self, 'stopAction', setup.victim, setup.id, busy.token, resumeIdle == true)
  end
  if notifyOwner then self:Notify(setup.owner, 'action_failed') end
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
  for _, key in ipairs(cfg.propOrder) do
    local prop = cfg.props[key]
    local pos = positions[key]
    local entity = pos and CreateObjectNoOffset(joaat(prop.model), pos.x, pos.y, pos.z, true, true, false) or 0
    if entity == 0 or not DoesEntityExist(entity) then
      if prop.required then
        for _, spawned in pairs(entities) do DeleteEntity(spawned) end
        return self:PlaceFailed(src, key .. ':spawn')
      end
    else
      SetEntityRoutingBucket(entity, bucket)
      if rotations[key] then
        local rotation = rotations[key]
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
      elseif prop.rotation then
        SetEntityRotation(entity, prop.rotation.x, prop.rotation.y,
          (placement.heading + prop.rotation.z) % 360.0, 2, true)
      else
        SetEntityHeading(entity, placement.heading)
      end
      SetEntityOrphanMode(entity, 2)
      FreezeEntityPosition(entity, true)
      entities[key] = entity
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
    or not cfg.toolScenes[tool] or not setup.entities[tool]
    or not setup.victim or not setup.seatReady
    or self.seated[setup.victim] ~= setup.id or not isAlive(setup.victim)
    or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
    or not near(setup.victim, setup.entities.chair, cfg.candidateDistance)
    or not near(src, setup.entities.trolley, cfg.actionDistance) then
    return self:Notify(src, 'invalid_state')
  end
  self.nextTool = self.nextTool + 1
  setup.tool = tool
  setup.toolReady = false
  setup.toolState = 'selecting'
  setup.toolToken = ('%d:tool:%d'):format(setup.id, self.nextTool)
  setup.toolEpoch = 0
  setup.toolPhase = nil
  setup.toolPhaseAt = GetGameTimer()
  setup.toolReadyPeers = {}
  self:Sync(setup)
  local snapshot = self:Snapshot(setup)
  self:EmitNet(self, 'prepareTool', src, snapshot, setup.toolToken)
  self:EmitNet(self, 'prepareTool', setup.victim, snapshot, setup.toolToken)
  local token, phaseAt = setup.toolToken, setup.toolPhaseAt
  SetTimeout(cfg.toolPrepareTimeoutMs, function()
    print(json.encode(setup, {indent = true}))
    if self.setups[src] == setup and setup.toolToken == token
      and setup.toolState == 'selecting' and setup.toolPhase == nil
      and setup.toolPhaseAt == phaseAt then
      self:StopTool(setup, true)
    end
  end)
end

function Impl:StartStage(setup, index)
  local busy = setup.busy
  if not busy then return end
  local action = cfg.actions[busy.key]
  local stageData = action.stages[index]
  print('not found stageData', json.encode(stageData, {indent = true}))
  if not stageData then return self:CancelAction(setup, true) end
  busy.stage = index
  busy.stageAt = GetGameTimer()
  setup.peerScene = nil
  local snapshot = self:Snapshot(setup)
  self:EmitNet(self, 'playStage', setup.victim, snapshot, busy.token, busy.key, index)
  self:EmitNet(self, 'playStage', setup.owner, snapshot, busy.token, busy.key, index)
  SetTimeout(cfg.stageTimeoutMs, function()
    if self.setups[setup.owner] == setup and setup.busy == busy and busy.stage == index then
      self:CancelAction(setup, true)
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
  self.nextAction = self.nextAction + 1
  local token = ('%d:%d'):format(setup.id, self.nextAction)
  local busy = { token = token, key = actionKey, ready = {}, stage = 0, startedAt = nil }
  setup.busy = busy
  setup.toolState = 'action'
  setup.toolReady = false
  self:Sync(setup)
  local snapshot = self:Snapshot(setup)
  self:EmitNet(self, 'prepareAction', src, snapshot, token, actionKey)
  self:EmitNet(self, 'prepareAction', setup.victim, snapshot, token, actionKey)
  SetTimeout(cfg.prepareTimeoutMs, function()
    if self.setups[src] == setup and setup.busy == busy and busy.stage == 0 then
      self:CancelAction(setup, true)
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
    return self:CancelAction(setup, true)
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
    self:CancelAction(setup, true)
  end
end

function Impl:Init()
  self.setups = {}
  self.seated = {}
  self.pending = {}
  self.nextId = 0
  self.nextAction = 0
  self.nextTool = 0
end

function Impl:OnReady()
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
        return cfg.actions[busy.key].stages[step], false
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
  self:OnNet('bindVictimScene', function(setupId, token, kind, step, netScene)
    local setup = self:GetOwned(source, setupId)
    if not setup or not setup.victim or not finite(netScene) or netScene < 0
      or netScene % 1 ~= 0 or netScene > 2147483647 then return end
    local scene, looped = sceneStage(setup, token, kind, step)
    if not scene or not isAlive(setup.victim)
      or GetPlayerRoutingBucket(setup.victim) ~= setup.bucket
      or not near(source, setup.entities.chair, cfg.actionDistance + 1.0) then return end
    local previous = setup.peerScene
    if previous and previous.token == token and previous.kind == kind and previous.step == step then return end
    setup.peerScene = { token = token, kind = kind, step = step, netScene = netScene, ready = false }
    self:EmitNet(self, 'joinVictimScene', setup.victim, self:Snapshot(setup), token, kind, step, netScene, scene, looped)
  end)
  self:OnNet('victimSceneReady', function(setupId, token, kind, step, netScene, success)
    local setup
    for _, candidate in pairs(self.setups) do
      if candidate.id == setupId and candidate.victim == source then setup = candidate break end
    end
    local peer = setup and setup.peerScene
    if not peer or peer.ready or peer.token ~= token or peer.kind ~= kind
      or peer.step ~= step or peer.netScene ~= netScene or not sceneStage(setup, token, kind, step) then return end
    peer.ready = success == true and isAlive(source) and GetPlayerRoutingBucket(source) == setup.bucket
    self:EmitNet(self, 'victimSceneReady', setup.owner, token, kind, step, netScene, peer.ready)
    if peer.ready and kind == 'action' then
      local stage = sceneStage(setup, token, kind, step)
      if stage.effect then
        self:EmitNet(self, 'stageEffect', -1, self:Snapshot(setup), token, setup.busy.key, step)
      end
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
          self:StopTool(setup, true)
        end
      end)
    else
      self:Notify(source, 'invalid_state')
    end
  end)
  self:OnNet('readyTool', function(setupId, token, success)
    local setup = self.setups[source]
    if not setup or setup.id ~= setupId then
      for _, candidate in pairs(self.setups) do
        if candidate.id == setupId and candidate.victim == source then setup = candidate break end
      end
    end
    if not setup or setup.id ~= setupId or setup.toolToken ~= token
      or setup.toolState ~= 'selecting' or setup.toolPhase ~= nil
      or (source ~= setup.owner and source ~= setup.victim) then return end
    if not success then return self:StopTool(setup, true) end
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
          self:StopTool(setup, true)
        end
      end)
    end
  end)
  self:OnNet('toolSelected', function(setupId, token, success)
    local setup = self:GetOwned(source, setupId)
    if not setup or setup.toolToken ~= token or setup.toolState ~= 'selecting'
      or setup.toolPhase ~= 'playing' then return end
    local peer = setup.peerScene
    if not success or not peer or not peer.ready or peer.kind ~= 'select' or peer.token ~= token
      or GetGameTimer() - setup.toolPhaseAt < 500
      or not near(source, setup.entities.chair, cfg.actionDistance + 1.0) then
      return self:StopTool(setup, true)
    end
    setup.toolPhase = nil
    self:StartToolIdle(setup)
  end)
  self:OnNet('toolSceneFailed', function(setupId, token)
    local setup = self.setups[source]
    if not setup or setup.id ~= setupId then
      for _, candidate in pairs(self.setups) do
        if candidate.id == setupId and candidate.victim == source then setup = candidate break end
      end
    end
    if setup and setup.id == setupId and setup.toolToken == token
      and (setup.toolState == 'selecting' or setup.toolState == 'idle') then
      self:StopTool(setup, true)
    end
  end)
  self:OnNet('toolIdleReady', function(setupId, token, epoch, success)
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
    if not success then return self:StopTool(setup, true) end
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
  self:OnNet('readyAction', function(setupId, token, success)
    for _, setup in pairs(self.setups) do
      local busy = setup.busy
      if setup.id == setupId and busy and busy.token == token
        and (source == setup.owner or source == setup.victim) and busy.stage == 0 then
        if not success then return self:CancelAction(setup, true) end
        busy.ready[source] = true
        if busy.ready[setup.owner] and busy.ready[setup.victim] then
          busy.startedAt = GetGameTimer()
          self:StartStage(setup, 1)
        end
        return
      end
    end
  end)
  self:OnNet('stageDone', function(setupId, token, index, success)
    local setup = self.setups[source]
    local busy = setup and setup.busy
    if not busy or setup.id ~= setupId or busy.token ~= token or busy.stage ~= index then return end
    local peer = setup.peerScene
    if not success or not peer or not peer.ready or peer.kind ~= 'action'
      or peer.token ~= token or peer.step ~= index then return self:CancelAction(setup, true) end
    local stageData = cfg.actions[busy.key].stages[index]
    if GetGameTimer() - busy.stageAt < math.min(stageData.durationMs * 0.5, 1200) then
      return self:CancelAction(setup, true)
    end
    if cfg.actions[busy.key].stages[index + 1] then
      self:StartStage(setup, index + 1)
    elseif GetGameTimer() - busy.startedAt >= cfg.minimumActionMs then
      self:FinishAction(setup)
    else
      self:CancelAction(setup, true)
    end
  end)
  self:OnNet('stageFailed', function(setupId, token, index)
    for _, setup in pairs(self.setups) do
      local busy = setup.busy
      if setup.id == setupId and setup.victim == source and busy
        and busy.token == token and busy.stage == index then
        return self:CancelAction(setup, true)
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
        self:CancelAction(setup, true)
      elseif setup.toolState ~= 'empty' and not setup.busy
        and not near(setup.owner, setup.entities.chair, cfg.actionDistance + 1.5) then
        self:StopTool(setup, true)
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
