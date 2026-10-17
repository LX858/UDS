local clipSizes = {
  ["WEAPON_ASSAULTRIFLE"] = 30,
  ["WEAPON_CARBINERIFLE"] = 30,
  ["WEAPON_PISTOL"] = 12,
  ["WEAPON_COMBATPISTOL"] = 12,
  ["WEAPON_PUMPSHOTGUN"] = 8,
  ["WEAPON_APPISTOL"] = 18,
  ["WEAPON_SMG"] = 30,
  ["WEAPON_MICROSMG"] = 30,
  ["WEAPON_SNIPERRIFLE"] = 10,
  ['WEAPON_BULLPUPRIFLE'] = 30,
  ['WEAPON_ASSAULTSMG'] = 30,
}

local Impl = NewImpl("Main")
function Impl:Init()
  main:LogInfo("%s initialized", self:GetName())
end

function Impl:OnReady()
  self.playerData = nil
  self.teams = nil
  self.histories = nil
  self.inGame = false
  self.currentMatch = nil
  self.currentPvpWeapon = nil
  self.uiOpen = false
  self.readyCheckActive = false
  self.delayPress = 0
  self.lastCoords = GetEntityCoords(cache.ped)
  self:InitFirst()
  self:CreatePvpNpc()
  self:EventHandler()
  self:NuiCallbacks()
  self:Callbacks()
end

function Impl:Callbacks()
  lib.callback.register("mp_pvp_v2:cl:inviteToTeam", function(leaderName)
    local alert = lib.alertDialog({
      header = 'PVP',
      content = 'Bạn được mời vào team của [' .. leaderName .. '], bạn có đồng ý không ?',
      centered = true,
      cancel = true,
      labels = {
        confirm = "Đồng ý",
        cancel = "Từ chối"
      }
    })
    if alert == "confirm" then
      return true
    else
      return false
    end
  end)
end

function Impl:OpenPvpMenu()
  if not self.playerData then
    self.playerData, self.teams, self.histories = lib.callback.await("mp_pvp_v2:sv:getPlayerData", false)
  end
  while not self.playerData or not self.teams or not self.histories do
    Wait(100)
  end
  if self.inGame then
    return Framework.Functions.Notify("Bạn đang trong trận đấu")
  end

  if LocalPlayer.state.isDead then
    return Framework.Functions.Notify("Bạn đang chết, không thể mở menu")
  end

  if LocalPlayer.state.handcuff then
    return Framework.Functions.Notify("Bạn đang bị còng, không thể mở menu")
  end

  local id = GetPlayerServerId(PlayerId())
  SendReactMessage("setPlayerId", id)
  local uiData = self:TeamsUIData()
  SendReactMessage("setPlayers", uiData)
  local historyData = self:HistoryUIData()
  SendReactMessage("setHistories", historyData)
  self:GetMyRank()
  local pvpOpenState = lib.callback.await("mp_pvp_v2:sv:getPvpOpenState", false)
  if pvpOpenState then
    SendReactMessage("setPvpOpenState", pvpOpenState)
  end
  self:ToggleUI(true)
end

function Impl:CreatePvpNpc()
  if not Config.PvpNpc or not Config.PvpNpc.enabled then return end

  local coords = Config.PvpNpc.coords
  local model = GetHashKey(Config.PvpNpc.model or "s_m_y_blackops_01")

  RequestModel(model)
  while not HasModelLoaded(model) do
    Wait(0)
  end

  self.pvpNpc = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
  SetEntityHeading(self.pvpNpc, coords.w)
  FreezeEntityPosition(self.pvpNpc, true)
  SetEntityInvincible(self.pvpNpc, true)
  SetBlockingOfNonTemporaryEvents(self.pvpNpc, true)
  SetModelAsNoLongerNeeded(model)

  CreateThread(function()
    local distance = Config.PvpNpc.interactDistance or 2.0
    while self.pvpNpc and DoesEntityExist(self.pvpNpc) do
      local sleep = 750
      local pedCoords = GetEntityCoords(cache.ped)
      local npcCoords = GetEntityCoords(self.pvpNpc)
      local dist = #(pedCoords - npcCoords)

      if dist <= distance and not self.uiOpen and not self.inGame then
        sleep = 0
        if not self.npcTextShown then
          lib.showTextUI("[E] Mở PVP")
          self.npcTextShown = true
        end
        if IsControlJustPressed(0, 38) then
          lib.hideTextUI()
          self.npcTextShown = false
          self:OpenPvpMenu()
        end
      elseif self.npcTextShown then
        lib.hideTextUI()
        self.npcTextShown = false
      end

      Wait(sleep)
    end
  end)

  AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if self.npcTextShown then
      lib.hideTextUI()
    end
    if self.pvpNpc and DoesEntityExist(self.pvpNpc) then
      DeleteEntity(self.pvpNpc)
    end
  end)
end

function Impl:InitFirst()
  Wait(5000)
  local playerData, teams, history = lib.callback.await("mp_pvp_v2:sv:getPlayerData", false)

  if playerData then
    self.playerData = playerData
    self.teams = teams
    self.histories = history
  end
end

function Impl:NuiCallbacks()
  RegisterNuiCallback("close", function(data, cb)
    self:ToggleUI(false)
    cb('ok')
  end)

  RegisterNuiCallback("invitePlayer", function(data, cb)
    cb('ok')
    if not self:IsLeader() then
      SendReactMessage("setToast", {
        type = "error",
        message = "Bạn không phải là chủ đội của team này"
      })
      return
    end
    local input = lib.inputDialog('PVP', {
      { type = 'number', label = 'Mời chiến hữu', description = 'Nhập ID người chơi bạn muốn mời', icon = 'hashtag', required = true, min = 1 },
    })
    if input and input[1] then
      TriggerServerEvent("mp_pvp_v2:sv:invitePlayer", input[1])
    end
  end)

  RegisterNuiCallback("kickPlayer", function(data, cb)
    cb('ok')

    TriggerServerEvent("mp_pvp_v2:sv:kickPlayer", data)
  end)

  RegisterNuiCallback("leaveTeam", function(data, cb)
    cb('ok')

    TriggerServerEvent("mp_pvp_v2:sv:leaveTeam")
  end)

  RegisterNuiCallback("getLeaderboard", function(data, cb)
    cb('ok')
    local soloData, dualData, trioData = lib.callback.await("mp_pvp_v2:sv:getLeaderBoard", 500)
    local leaderBoard = {
      solo = soloData,
      dual = dualData,
      trio = trioData
    }
    SendReactMessage("setLeaderboard", self:LeaderBoardUIData(leaderBoard))
  end)

  RegisterNuiCallback("findMatch", function(data, cb)
    cb('ok')
    if self.inGame then
      SendReactMessage("setToast", {
        type = "error",
        message = "Bạn đang trong trận đấu"
      })
      return
    end
    if not self:IsLeader() then
      SendReactMessage("setToast", {
        type = "error",
        message = "Bạn không phải là đội trưởng của team này"
      })
      return
    end

    if self.cooldown then
      SendReactMessage("setToast", {
        type = "error",
        message = "Bạn đang trong thời gian chờ 30s"
      })
      return
    end

    if self.delayPress > GetGameTimer() then 
      SendReactMessage("setToast", {
        type = "error",
        message = "Vui lòng không spam"
      })
      return
    end
    self.delayPress = GetGameTimer() + 5000
    TriggerServerEvent("mp_pvp_v2:sv:findMatch")
  end)

  RegisterNuiCallback("cancelSearch", function(data, cb)
    cb('ok')
    TriggerServerEvent("mp_pvp_v2:sv:cancelSearch")
  end)

  RegisterNuiCallback("readyMatch", function(data, cb)
    cb('ok')
    if not data or not data.matchId then return end
    TriggerServerEvent("mp_pvp_v2:sv:readyResponse", data.matchId, data.accepted == true)
  end)

  RegisterNuiCallback("restoreNegativePoint", function(data, cb)
    cb('ok')
    TriggerServerEvent("mp_pvp_v2:sv:restoreNegativePoint")
  end)
end

function Impl:ToggleUI(state)
  self.uiOpen = state
  SendReactMessage('setShow', state)
  SetNuiFocus(state or self.readyCheckActive, state or self.readyCheckActive)
end

function Impl:EventHandler()
  RegisterNetEvent("mp_pvp_v2:cl:notify", function(type, message)
    SendReactMessage("setToast", {
      type = type,
      message = message
    })
  end)

  RegisterNetEvent("mp_pvp_v2:cl:searching", function(state)
    SendReactMessage("setSearching", state)
  end)

  RegisterNetEvent('mp_pvp_v2:cl:updateTeam', function(teamData)
    self.teams = teamData
    local uiData = self:TeamsUIData()
    SendReactMessage("setPlayers", uiData)
    self:GetMyRank()
  end)

  RegisterNetEvent('mp_pvp_v2:cl:readyCheck', function(data)
    self.readyCheckActive = true
    self:ToggleUI(false)
    SendReactMessage("showReadyCheck", data)
    SetNuiFocus(true, true)
  end)

  RegisterNetEvent('mp_pvp_v2:cl:readyCheckState', function(data)
    SendReactMessage("updateReadyCheck", data)
  end)

  RegisterNetEvent('mp_pvp_v2:cl:readyCheckCancel', function(reason)
    self.readyCheckActive = false
    SendReactMessage("hideReadyCheck")
    SetNuiFocus(self.uiOpen, self.uiOpen)
    if reason then
      Framework.Functions.Notify(reason, "error")
    end
  end)

  RegisterNetEvent('mp_pvp_v2:cl:readyCheckClose', function()
    self.readyCheckActive = false
    SendReactMessage("hideReadyCheck")
    SetNuiFocus(false, false)
  end)

  RegisterNetEvent('mp_pvp_v2:cl:startMatch', function(weapon, playerIdx, matchId, mode, idx)
    self.readyCheckActive = false
    SendReactMessage("hideReadyCheck")
    self:ToggleUI(false)
    self.currentMatch = matchId
    self.inGame = true
    SendReactMessage("setSearching", false)
    self.lastCoords = GetEntityCoords(cache.ped)
    TriggerEvent("ox_inventory:disarm", true)
    -- exports["dpemotes"]:EmoteCancel()
    LocalPlayer.state.inPvP = true
    LocalPlayer.state.invBusy = true
    LocalPlayer.state.canUseWeapons = true
    exports.ox_inventory:weaponWheel(true)
    self:StartMatch(weapon, playerIdx, matchId, mode, idx)
  end)

  RegisterNetEvent('mp_pvp_v2:cl:matchFound', function(weapon, playerIdx, matchId, mode, idx)
    TriggerEvent('mp_pvp_v2:cl:startMatch', weapon, playerIdx, matchId, mode, idx)
  end)

  RegisterNetEvent('mp_pvp_v2:cl:matchEnded', function(state)
    self.inGame = false
    if state == 'win' then
      Framework.Functions.Notify("Bạn đã chiến thắng!", "success")
    elseif state == 'lose' then
      Framework.Functions.Notify("Bạn đã thua cuộc!", "error")
    else
      Framework.Functions.Notify("Trận đấu kết thúc với tỷ số hòa!", "info")
    end
    SetPedArmour(PlayerPedId(), 0.0)
    LocalPlayer.state.invBusy = false
    LocalPlayer.state.canUseWeapons = false
    self.cooldown = true
    SetNuiFocus(true, true)
    exports.ox_inventory:weaponWheel(false)
    TriggerEvent("ox_inventory:disarm", true)
    SetCurrentPedWeapon(cache.ped, GetHashKey("WEAPON_UNARMED"), true)
    self:RemovePvpWeapon()
    Citizen.SetTimeout(2500, function()
      TriggerEvent('qbx_medical:client:playerRevived', true)
    end)

    local returnCoords = self.lastCoords
    CreateThread(function()
      Wait(10000)
      LocalPlayer.state.canUseWeapons = true
      self:RemovePvpWeapon()
      if returnCoords then
        SetEntityCoords(cache.ped, returnCoords.x, returnCoords.y, returnCoords.z)
      end
      TriggerServerEvent("mp_pvp_v2:sv:resetBucket")
      LocalPlayer.state.inPvP = false
      SetNuiFocus(false, false)
      self.lastCoords = nil
      SetTimeout(30000, function()
        self.cooldown = false
        self:RemovePvpWeapon()
      end)
    end)
  end)
end

function Impl:RemovePvpWeapon()
  if self.currentPvpWeapon then
    SetPedAmmo(cache.ped, self.currentPvpWeapon, 0)
    RemoveWeaponFromPed(cache.ped, self.currentPvpWeapon)
    self.currentPvpWeapon = nil
  end
  SetCurrentPedWeapon(cache.ped, GetHashKey("WEAPON_UNARMED"), true)
end

function Impl:StartMatch(__wId, playerIdx, matchId, mode, idx)
  print(__wId, playerIdx, matchId, mode, idx)
  local timeout = GetGameTimer() + 5000
  DoScreenFadeOut(0)
  Wait(100)
  local coords = Config.TeamCoords[tonumber(mode)][idx][playerIdx]
  SetFocusPosAndVel(coords.x, coords.y, coords.z)
  RequestCollisionAtCoord(coords.x, coords.y, coords.z)
  SetEntityCoords(cache.ped, coords.x, coords.y, coords.z + 1.0)
  timeout = GetGameTimer() + 2000
  while not HasCollisionLoadedAroundEntity(cache.ped) and (timeout - GetGameTimer()) > 3000 do
    Wait(100)
  end
  local remain = (timeout - GetGameTimer())
  remain = remain > 0 and remain or 0
  ClearFocus()
  DoScreenFadeIn(200)
  SetEntityHealth(cache.ped, 200)
  SetPedArmour(cache.ped, 100.0)
  SetEntityHeading(cache.ped, coords.w)
  SetEntityInvincible(cache.ped, true)
  FreezeEntityPosition(cache.ped, true)
  Citizen.CreateThreadNow(function()
    Wait(remain)
    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)
  end)
  Wait(1000)
  local Weapon = Config.Weapons[__wId].name
  local weaponHash = GetHashKey(Weapon)
  self.currentPvpWeapon = weaponHash
  RequestWeaponAsset(weaponHash, 31, 0)
  while not HasWeaponAssetLoaded(weaponHash) do
    Wait(0)
  end
  GiveWeaponToPed(cache.ped, weaponHash, 1000, false, true)
  SetCurrentPedWeapon(cache.ped, weaponHash, true)
  SetWeaponsNoAutoswap(true)
  SetPedAmmo(cache.ped, weaponHash, 1000)
  local clipSize = clipSizes[Weapon] or 30
  SetAmmoInClip(cache.ped, weaponHash, clipSize)

  CreateThread(function()
    local retval, ammo = GetAmmoInClip(cache.ped, weaponHash)

    while self.inGame and ammo < clipSize do
      Wait(100)
      if not self.inGame then break end
      TaskReloadWeapon(cache.ped, true)
      Wait(2500)
      if not self.inGame then break end
      retval, ammo = GetAmmoInClip(cache.ped, weaponHash)
      if ammo >= clipSize then
        break
      end
    end
  end)

  CreateThread(function()
    while self.inGame do
      Wait(0)
      if not self.inGame then break end
      local currentWeapon = GetSelectedPedWeapon(cache.ped)
      if currentWeapon ~= weaponHash then
        GiveWeaponToPed(cache.ped, weaponHash, 9999, false, true)
        SetCurrentPedWeapon(cache.ped, weaponHash, true)
      end
      if IsEntityDead(cache.ped) then
        self.inGame = false
        self:RemovePvpWeapon()
        TriggerServerEvent("mp_pvp_v2:sv:playerDied", matchId, mode, idx, playerIdx)
        break
      end
    end
  end)
end

function Impl:GetMyRank()
  local data = {}
  local pointSolo = self.playerData.solo or 0
  local pointDual = self.playerData.dual or 0
  local pointTrio = self.playerData.trio or 0
  local userId = tostring(LocalPlayer.state.userId)
  local teamData = userId and self.teams.members[userId] or nil
  data.solo = {
    point = teamData and teamData.solo or 0,
    rank = GetRank(pointSolo).name,
    rankLabel = GetRank(pointSolo).label,
    position = 0
  }
  data.dual = {
    point = teamData and teamData.dual or 0,
    rank = GetRank(pointDual).name,
    rankLabel = GetRank(pointDual).label,
    position = 0
  }
  data.trio = {
    point = teamData and teamData.trio or 0,
    rank = GetRank(pointTrio).name,
    rankLabel = GetRank(pointTrio).label,
    position = 0
  }
  SendReactMessage("setMyRank", data)
  return data
end

function Impl:TeamsUIData()
  local data = {}
  for k, v in pairs(self.teams.members) do
    data[#data + 1] = {
      id            = v.id,
      leader        = v.leader,
      solo          = v.solo,
      dual          = v.dual,
      trio          = v.trio,
      soloRank      = GetRank(v.solo).name,
      soloRankLabel = GetRank(v.solo).label,
      dualRank      = GetRank(v.dual).name,
      dualRankLabel = GetRank(v.dual).label,
      trioRank      = GetRank(v.trio).name,
      trioRankLabel = GetRank(v.trio).label,
      name          = v.name,
    }
  end
  return data
end

function Impl:HistoryUIData()
  local data = {}
  for k, v in pairs(self.histories) do
    data[#data + 1] = {
      time = v.time,
      state = v.state,
      type = v.type,
      point = v.point
    }
  end
  table.sort(data, function(a, b)
    return a.time > b.time
  end)
  return data
end

function Impl:IsLeader()
  local playerId = LocalPlayer.state.userId
  if tonumber(self.teams.leader) == tonumber(playerId) then
    return true
  end
  return false
end

function Impl:LeaderBoardUIData(data)
  local returnData = {}
  local soloData = {}
  local dualData = {}
  local trioData = {}
  local seenSolo = {}
  local seenDual = {}
  local seenTrio = {}
  for k, v in pairs(data) do
    if k == "solo" then
      for _, player in pairs(v) do
        local id = tostring(player.id)
        if not seenSolo[id] then
          seenSolo[id] = true
          soloData[#soloData + 1] = {
            name = player.name,
            point = player.solo,
            rank = GetRank(player.solo).name,
            id = player.id,
            rankLabel = GetRank(player.solo).label
          }
        end
      end
    elseif k == "dual" then
      for _, player in pairs(v) do
        local id = tostring(player.id)
        if not seenDual[id] then
          seenDual[id] = true
          dualData[#dualData + 1] = {
            name = player.name,
            point = player.dual,
            rank = GetRank(player.dual).name,
            id = player.id,
            rankLabel = GetRank(player.dual).label
          }
        end
      end
    elseif k == "trio" then
      for _, player in pairs(v) do
        local id = tostring(player.id)
        if not seenTrio[id] then
          seenTrio[id] = true
          trioData[#trioData + 1] = {
            name = player.name,
            point = player.trio,
            rank = GetRank(player.trio).name,
            id = player.id,
            rankLabel = GetRank(player.trio).label
          }
        end
      end
    end
  end
  table.sort(soloData, function(a, b)
    return a.point > b.point
  end)
  table.sort(dualData, function(a, b)
    return a.point > b.point
  end)
  table.sort(trioData, function(a, b)
    return a.point > b.point
  end)
  returnData.solo = soloData
  returnData.dual = dualData
  returnData.trio = trioData
  return returnData
end
