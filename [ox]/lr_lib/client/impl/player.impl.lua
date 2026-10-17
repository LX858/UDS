---@class CLPlayerImpl : Impl
local Impl = NewImpl("Player")

function Impl:Init()
  self:LogInfo("initialized")
  self.hunger = 0
  self.thirst = 0
  self:RegisterEvents()
  self:StatThread()
  self.playerCount = GlobalState.PlayerCount or 0
  -- self:RichPresence()
end

function Impl:RichPresence()
  CreateThread(function()
    while true do
      local PlayerCount = GlobalState['PlayerCount']
      local MaxPlayers = GetConvarInt('sv_maxclients', 999)
      local Players = PlayerCount + (math.floor(PlayerCount / 10))
      SetDiscordAppId("1412454734161248406")
      SetDiscordRichPresenceAsset("logo")
      SetDiscordRichPresenceAssetText("VNO")
      SetDiscordRichPresenceAssetSmall("logo")
      SetDiscordRichPresenceAssetSmallText("Lối chơi độc đáo - mới lạ")
      SetDiscordRichPresenceAction(0, "Discord", "https://discord.gg/gta5online")
      SetDiscordRichPresenceAction(1, "Chơi Ngay", 'https://gta5online.com.vn')
      SetRichPresence(string.format('Trực tuyến %s/%s', Players, MaxPlayers))
      Wait(10 * 1000)
    end
  end)
end

function IsInjuredOrDead()
  if LocalPlayer.state.isDead then
    return true
  end
  return false
end

function Impl:StatThread()
  CreateThread(function()
    while true do
      Wait(5000)
      self.hunger = CORE.CallService("PlayerService", "getStatByName", "hunger")
      self.thirst = CORE.CallService("PlayerService", "getStatByName", "thirst")
      if self.hunger.value <= 0 or self.thirst.value <= 0 then
        if not IsInjuredOrDead() then
          local EntityHealth = GetEntityHealth(cache.ped)
          local newHealth = EntityHealth - 5
          if newHealth <= 101 then
            SetEntityHealth(cache.ped, 101)
          else
            ApplyDamageToPed(cache.ped, 5, false)
          end
        end
      end
    end
  end)
end

function Impl:OnReady()
  self:LogInfo("ready")
  ---@type PlayerData
  self.playerData = lib.callback.await('lr_lib:server:onPlayerLoaded')
  self:LogInfo("playerData %s", json.encode(self.playerData, { indent = true }))
  self:UpdateLocalState()
end

function Impl:RegisterEvents()
  -- RegisterCommand('testPos', function()
  --   TriggerEvent('playerSpawned')
  -- end, false)
  ---@param key string
  ---@param value any
  RegisterNetEvent("lr_lib:client:playerMetaDataChanged", function(key, value)
    self.playerData.metadata[key] = value
    self:UpdateLocalState()
  end)

  AddStateBagChangeHandler('PlayerCount', '', function(bagName, _, value)
    if bagName == 'global' and value then
      SetRichPresence(('Người Chơi %s/%s'):format(value, 999))
    end
  end)

  --[[ AddEventHandler('playerSpawned', function()
    local coords = lib.callback.await('lr_lib:sv:getPlayerLastPosition')
    if coords then
      SetEntityCoords(PlayerPedId(), coords[1], coords[2], coords[3])
    else
      SetEntityCoords(PlayerPedId(), 217.8740, -816.4077, 30.6007)
    end
  end) ]]
end

function Impl:UpdateLocalState()
  LocalPlayer.state:set("lr_lib:playerData", self.playerData, false)
end
