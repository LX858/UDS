---@class MainImpl : Impl
local Impl = NewImpl('Main')
local prefix = 'vx_airdrop:'

local function send(event, data)
  SendNUIMessage({ event = event, data = data })
end

local function secondsLeft(endsAt, serverNow)
  if type(endsAt) ~= 'number' or type(serverNow) ~= 'number' then return 0 end
  return math.max(0, endsAt - serverNow)
end

local function registrationSecondsLeft(deadlineMs)
  return math.max(0, math.ceil(((deadlineMs or 0) - GetGameTimer()) / 1000))
end

local function notify(message, kind)
  lib.notify({ title = 'Airdrop', description = message, type = kind or 'inform' })
end

local function pedGender(ped)
  return GetEntityModel(ped) == GetHashKey('mp_f_freemode_01') and 'female' or 'male'
end

local function captureOutfit(ped)
  local outfit = { components = {}, props = {} }
  for _, id in ipairs({ 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }) do
    outfit.components[id] = {
      GetPedDrawableVariation(ped, id), GetPedTextureVariation(ped, id), GetPedPaletteVariation(ped, id)
    }
  end
  for _, id in ipairs({ 0, 1, 2, 6, 7 }) do
    outfit.props[id] = { GetPedPropIndex(ped, id), GetPedPropTextureIndex(ped, id) }
  end
  return outfit
end

local function applyOutfit(ped, outfit, restoreSnapshot)
  if not outfit then return end
  for id, item in pairs(outfit.components or {}) do
    local component = tonumber(id)
    if component and item then
      local drawable, texture = tonumber(item[1]) or 0, tonumber(item[2]) or 0
      local maxDrawable = GetNumberOfPedDrawableVariations(ped, component)
      if drawable < 0 or drawable >= maxDrawable then
        drawable, texture = 0, 0
      else
        local maxTexture = GetNumberOfPedTextureVariations(ped, component, drawable)
        if texture < 0 or texture >= maxTexture then texture = 0 end
        if not IsPedComponentVariationValid(ped, component, drawable, texture) then
          texture = 0
          if not IsPedComponentVariationValid(ped, component, drawable, texture) then
            drawable, texture = 0, 0
          end
        end
      end
      if GetPedDrawableVariation(ped, component) ~= drawable
        or GetPedTextureVariation(ped, component) ~= texture then
        SetPedComponentVariation(ped, component, drawable, texture, item[3] or 0)
      end
    end
  end
  for id, item in pairs(outfit.props or {}) do
    local prop = tonumber(id)
    if prop and item then
      if item[1] == -1 then
        if GetPedPropIndex(ped, prop) ~= -1 then ClearPedProp(ped, prop) end
      elseif GetNumberOfPedPropDrawableVariations(ped, prop) > item[1] then
        local drawable, texture = tonumber(item[1]) or -1, tonumber(item[2]) or 0
        local maxTexture = GetNumberOfPedPropTextureVariations(ped, prop, drawable)
        if texture < 0 or texture >= maxTexture then texture = 0 end
        if GetPedPropIndex(ped, prop) ~= drawable or GetPedPropTextureIndex(ped, prop) ~= texture then
          SetPedPropIndex(ped, prop, drawable, texture, true)
        end
      elseif GetPedPropIndex(ped, prop) ~= -1 then
        ClearPedProp(ped, prop)
      end
    end
  end
end

local function applyTeamUniform(ped, team)
  local teamUniforms = Config.Airdrop.Uniforms[team]
  if ped == 0 or not DoesEntityExist(ped) or not teamUniforms then return end
  applyOutfit(ped, teamUniforms[pedGender(ped)])
end

local function clearInvincibility()
  if LocalPlayer.state.vxAirdropActive then return 'in_match' end
  local ped = PlayerPedId()
  if ped == 0 or not DoesEntityExist(ped) then return 'ped_missing' end
  local deathState = LocalPlayer.state['qbx_medical:deathState']
  if deathState == 2 or deathState == 3 or IsEntityDead(ped) then return 'dead' end
  SetPlayerInvincible(PlayerId(), false)
  SetEntityInvincible(ped, false)
  SetEntityCanBeDamaged(ped, true)
  SetEntityProofs(ped, false, false, false, false, false, false, false, false)
  SetPedCanRagdoll(ped, true)
  return 'cleared'
end

function Impl:Init()
  self.phase = nil
  self.roundId = nil
  self.joined = false
  self.declined = false
  self.deathReported = false
  self.tempWeapon = nil
  self.dropObject = nil
  self.outfit = nil
  self.uniformTeams = {}
  self.origin = nil
  print('vx_airdrop: MainImpl initialized')
end

function Impl:OnReady()
  RegisterNUICallback('chooseWeapon', function(data, cb)
    if self.phase == 'match' and type(data) == 'table' and type(data.weaponId) == 'string' then
      TriggerServerEvent(prefix .. 'sv:chooseWeapon', self.roundId, data.weaponId)
      cb({ ok = true })
    else
      cb({ ok = false })
    end
  end)

  lib.addKeybind({
    name = 'vx_airdrop_join', description = 'Tham gia Airdrop', defaultKey = 'Y',
    onPressed = function()
      if self.phase ~= 'registration' or self.joined or self.declined
        or registrationSecondsLeft(self.registrationEndsMs) == 0 then return end
      if IsPedInAnyVehicle(PlayerPedId(), false) then return notify('Bạn phải xuống xe để tham gia.', 'error') end
      TriggerServerEvent(prefix .. 'sv:join', self.roundId)
    end,
  })
  lib.addKeybind({
    name = 'vx_airdrop_decline', description = 'Từ chối Airdrop', defaultKey = 'X',
    onPressed = function()
      if self.phase ~= 'registration' or self.joined then return end
      self.declined = true
      send('airdrop:registration', nil)
      send('main:setShow', false)
    end,
  })

  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:registration', function(roundId, endsAt, joined, serverNow)
    if self.phase == 'match' then return end
    if self.roundId ~= roundId then self.declined = false end
    self.roundId = roundId
    self.phase = 'registration'
    self.registrationEndsMs = GetGameTimer() + secondsLeft(endsAt, serverNow) * 1000
    self.joined = joined == true
    if not self.declined and not self.joined then
      send('main:setShow', true)
      send('airdrop:registration', { roundId = roundId, remainingSeconds = registrationSecondsLeft(self.registrationEndsMs) })
    else
      send('airdrop:registration', nil)
    end
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:joined', function(roundId)
    if self.phase ~= 'registration' or roundId ~= self.roundId then return end
    self.joined = true
    send('airdrop:registration', nil)
    send('main:setShow', false)
    notify('Đã đăng ký airdrop. Hãy ở ngoài xe đến khi trận bắt đầu.', 'success')
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:unjoined', function(roundId, reason)
    if self.phase ~= 'registration' or roundId ~= self.roundId then return end
    self.joined = false
    if not self.declined and registrationSecondsLeft(self.registrationEndsMs) > 0 then
      send('main:setShow', true)
      send('airdrop:registration', { roundId = roundId, remainingSeconds = registrationSecondsLeft(self.registrationEndsMs) })
    end
    if reason then notify(reason, 'error') end
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:begin', function(roundId, team, endsAt, scores, serverNow)
    self:StartMatch(roundId, team, endsAt, scores, serverNow)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:matchSync', function(roundId, team, endsAt, scores, overtime, selecting, serverNow)
    if self.phase ~= 'match' then self:StartMatch(roundId, team, endsAt, scores, serverNow) end
    if self.roundId == roundId then
      self:UpdateScore(scores, endsAt, overtime, serverNow)
      if selecting then self:ShowWeapons() end
    end
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:uniforms', function(roundId, roster)
    if self.phase ~= 'match' or self.roundId ~= roundId or type(roster) ~= 'table' then return end
    local uniforms = {}
    for _, entry in ipairs(roster) do
      local serverId = type(entry) == 'table' and tonumber(entry.source) or nil
      local team = type(entry) == 'table' and entry.team or nil
      if serverId and (team == 'A' or team == 'B') then uniforms[serverId] = team end
    end
    self.uniformTeams = uniforms
    self.uniformTeams[GetPlayerServerId(PlayerId())] = self.team
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:score', function(roundId, scores, endsAt, overtime, serverNow)
    if self.phase == 'match' and roundId == self.roundId then self:UpdateScore(scores, endsAt, overtime, serverNow) end
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:weaponApproved', function(roundId, weaponName)
    if self.phase ~= 'match' or roundId ~= self.roundId then return end
    self:RemoveWeapon()
    local ped = PlayerPedId()
    self.tempWeapon = GetHashKey(weaponName)
    GiveWeaponToPed(ped, self.tempWeapon, 999, false, true)
    SetCurrentPedWeapon(ped, self.tempWeapon, true)
    send('airdrop:weapons', nil)
    SetNuiFocus(false, false)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:respawnWait', function(roundId, seconds)
    if self.phase ~= 'match' or roundId ~= self.roundId then return end
    self.deathReported = true
    send('airdrop:weapons', nil)
    SetNuiFocus(false, false)
    notify(('Bạn sẽ hồi sinh tại tế đàn sau %d giây.'):format(seconds))
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:respawn', function(roundId, team)
    if self.phase ~= 'match' or roundId ~= self.roundId then return end
    self.team = team
    self.uniformTeams[GetPlayerServerId(PlayerId())] = team
    self:RemoveWeapon()
    self:Teleport(Config.Airdrop.Teams[team].spawn, Config.Airdrop.Teams[team].heading)
    applyTeamUniform(PlayerPedId(), team)
    LocalPlayer.state.invBusy = true
    self.deathReported = false
    self:ShowWeapons()
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:result', function(roundId, won)
    if self.phase ~= 'match' or roundId ~= self.roundId then return end
    self.phase = 'result'
    send('airdrop:weapons', nil)
    send('airdrop:score', nil)
    send('airdrop:result', won and 'win' or 'lose')
    SetNuiFocus(false, false)
    send('main:setShow', true)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:leave', function(roundId, origin, reason)
    if self.roundId ~= roundId then return end
    self:Cleanup(origin)
    if reason then notify(reason, 'error') end
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:reset', function(roundId, reason)
    if self.phase == 'match' or self.phase == 'result' then return end -- cl:leave restores the match snapshot.
    if roundId and self.roundId and roundId ~= self.roundId then return end
    self:Cleanup()
    if reason then notify(reason) end
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:notify', function(message, kind)
    notify(message, kind)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'cl:clearInvincibility', function(token)
    if type(token) ~= 'string' or token == '' then return end
    if self.protectionResetToken == token then
      if self.protectionResetResult then
        TriggerServerEvent(prefix .. 'sv:protectionResetAck', token, self.protectionResetResult)
      end
      return
    end
    self.protectionResetToken = token
    self.protectionResetResult = nil
    CreateThread(function()
      clearInvincibility()
      Wait(12000) -- qbx_medical can still finish an older death coroutine during this interval.
      if self.protectionResetToken ~= token then return end
      self.protectionResetResult = clearInvincibility()
      TriggerServerEvent(prefix .. 'sv:protectionResetAck', token, self.protectionResetResult)
    end)
  end)

  CreateThread(function()
    while not self.destroyed do
      Wait(250)
      if self.phase == 'registration' and self.joined and IsPedInAnyVehicle(PlayerPedId(), false) then
        TriggerServerEvent(prefix .. 'sv:vehicle', self.roundId)
      elseif self.phase == 'match' then
        if IsPedInAnyVehicle(PlayerPedId(), false) then TriggerServerEvent(prefix .. 'sv:vehicle', self.roundId) end
        local state = LocalPlayer.state['qbx_medical:deathState']
        if (state == 2 or state == 3 or IsEntityDead(PlayerPedId())) and not self.deathReported
          and GetGameTimer() - (self.lastDeathRequest or -10000) >= 1000 then
          self.lastDeathRequest = GetGameTimer()
          send('airdrop:weapons', nil)
          SetNuiFocus(false, false)
          exports.qbx_medical:HideDeathUI()
          LocalPlayer.state.invBusy = true
          TriggerServerEvent(prefix .. 'sv:died', self.roundId)
        end
      end
    end
  end)
  CreateThread(function()
    while not self.destroyed do
      if self.phase == 'match' then
        local drop = Config.Airdrop.DropPosition
        if #(GetEntityCoords(PlayerPedId()) - drop) < 100.0 then
          DrawMarker(1, drop.x, drop.y, drop.z - 1.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, Config.Airdrop.ScoreRadius * 2, Config.Airdrop.ScoreRadius * 2, 2.5,
            255, 25, 25, 125, false, false, 2, false, nil, nil, false)
          Wait(0)
        else
          Wait(500)
        end
      else
        Wait(500)
      end
    end
  end)
  CreateThread(function()
    while not self.destroyed do
      Wait(1000)
      if self.phase == 'match' and self.team then
        if not self.deathReported then applyTeamUniform(PlayerPedId(), self.team) end
        for _, playerId in ipairs(GetActivePlayers()) do
          if playerId ~= PlayerId() then
            local serverId = GetPlayerServerId(playerId)
            applyTeamUniform(GetPlayerPed(playerId), self.uniformTeams[serverId])
          end
        end
      end
    end
  end)
  SetTimeout(2500, function() TriggerServerEvent(prefix .. 'sv:ready') end)
end

function Impl:Teleport(coords, heading)
  local ped = PlayerPedId()
  RequestCollisionAtCoord(coords.x, coords.y, coords.z)
  SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
  SetEntityHeading(ped, heading or 0.0)
end

function Impl:CreateDrop(roundId)
  local model = GetHashKey(Config.Airdrop.DropModel)
  RequestModel(model)
  local deadline = GetGameTimer() + 5000
  while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(50) end
  if self.phase ~= 'match' or self.roundId ~= roundId then
    SetModelAsNoLongerNeeded(model)
    return
  end
  if not HasModelLoaded(model) then return self:LogError('Airdrop prop did not load') end
  local pos = Config.Airdrop.DropPosition
  self.dropObject = CreateObjectNoOffset(model, pos.x, pos.y, pos.z, false, false, false)
  if self.dropObject ~= 0 then FreezeEntityPosition(self.dropObject, true) end
  SetModelAsNoLongerNeeded(model)
end

function Impl:StartMatch(roundId, team, endsAt, scores, serverNow)
  if self.phase == 'match' and self.roundId == roundId then return end
  local reuseSnapshot = LocalPlayer.state.vxAirdropSnapshotRound == roundId
  local savedOutfit = reuseSnapshot and LocalPlayer.state.vxAirdropOutfitSnapshot or nil
  local savedOrigin = reuseSnapshot and LocalPlayer.state.vxAirdropOrigin or nil
  if self.phase == 'match' or self.phase == 'result' then
    self:Cleanup()
  else
    SetNuiFocus(false, false)
    send('airdrop:registration', nil)
    send('airdrop:score', nil)
    send('airdrop:weapons', nil)
    send('airdrop:result', nil)
    if self.dropObject and DoesEntityExist(self.dropObject) then DeleteEntity(self.dropObject) end
    self.dropObject = nil
    self:RemoveWeapon()
  end
  LocalPlayer.state:set('vxAirdropActive', true, false)
  local ped = PlayerPedId()
  local currentCoords = GetEntityCoords(ped)
  self.origin = savedOrigin or {
    x = currentCoords.x, y = currentCoords.y, z = currentCoords.z, heading = GetEntityHeading(ped)
  }
  LocalPlayer.state:set('vxAirdropOrigin', self.origin, false)
  self.outfit = savedOutfit or captureOutfit(ped)
  LocalPlayer.state:set('vxAirdropOutfitSnapshot', self.outfit, false)
  LocalPlayer.state:set('vxAirdropSnapshotRound', roundId, false)
  self.previousInvBusy = LocalPlayer.state.invBusy
  self.previousCanUseWeapons = LocalPlayer.state.canUseWeapons
  self.phase, self.roundId, self.team = 'match', roundId, team
  self.uniformTeams = { [GetPlayerServerId(PlayerId())] = team }
  self.deathReported = false
  TriggerEvent('ox_inventory:disarm', true)
  exports.ox_inventory:weaponWheel(true)
  LocalPlayer.state.invBusy = true
  LocalPlayer.state.canUseWeapons = true
  self:Teleport(Config.Airdrop.Teams[team].spawn, Config.Airdrop.Teams[team].heading)
  FreezeEntityPosition(PlayerPedId(), true)
  CreateThread(function()
    Wait(5000)
    FreezeEntityPosition(PlayerPedId(), false)
  end)
  applyTeamUniform(PlayerPedId(), team)
  send('airdrop:registration', nil)
  send('airdrop:myTeam', team)
  send('main:setShow', true)
  self:UpdateScore(scores, endsAt, false, serverNow)
  self:ShowWeapons()
  CreateThread(function() self:CreateDrop(roundId) end)
end

function Impl:UpdateScore(scores, endsAt, overtime, serverNow)
  send('airdrop:score', {
    team1Score = scores.A, team2Score = scores.B,
    remainingSeconds = secondsLeft(endsAt, serverNow),
    overtime = overtime == true, team = self.team,
  })
end

function Impl:ShowWeapons()
  if self.phase ~= 'match' then return end
  send('airdrop:weapons', Config.Airdrop.Weapons)
  SetNuiFocus(true, true)
end

function Impl:RemoveWeapon()
  if self.tempWeapon then
    RemoveWeaponFromPed(PlayerPedId(), self.tempWeapon)
    self.tempWeapon = nil
  end
end

function Impl:Cleanup(origin)
  local wasInMatch = self.phase == 'match' or self.phase == 'result'
  local leavingRoundId = self.roundId
  local returnPosition = origin or self.origin or LocalPlayer.state.vxAirdropOrigin
  self.phase, self.roundId, self.team = nil, nil, nil
  self.uniformTeams = {}
  self.joined, self.declined, self.deathReported = false, false, false
  SetNuiFocus(false, false)
  send('airdrop:registration', nil)
  send('airdrop:score', nil)
  send('airdrop:weapons', nil)
  send('airdrop:result', nil)
  send('main:setShow', false)
  if self.dropObject and DoesEntityExist(self.dropObject) then DeleteEntity(self.dropObject) end
  self.dropObject = nil
  if wasInMatch then
    self:RemoveWeapon()
    exports.ox_inventory:weaponWheel(false)
    TriggerEvent('ox_inventory:disarm', true)
    LocalPlayer.state.invBusy = self.previousInvBusy or false
    LocalPlayer.state.canUseWeapons = self.previousCanUseWeapons ~= false
    applyOutfit(PlayerPedId(), self.outfit or LocalPlayer.state.vxAirdropOutfitSnapshot, true)
    if returnPosition then self:Teleport(returnPosition, returnPosition.heading) end
  end
  LocalPlayer.state:set('vxAirdropActive', false, false)
  self.outfit = nil
  self.origin = nil
  LocalPlayer.state:set('vxAirdropOutfitSnapshot', nil, false)
  LocalPlayer.state:set('vxAirdropOrigin', nil, false)
  LocalPlayer.state:set('vxAirdropSnapshotRound', nil, false)
  if wasInMatch and leavingRoundId then
    TriggerServerEvent(prefix .. 'sv:clothingRestored', leavingRoundId)
  end
end

function Impl:OnResourceStop()
  self:Cleanup()
end

function Impl:OnDestroy()
  self:Cleanup()
end
