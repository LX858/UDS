---@class SVLoggerImpl : Impl
local Impl = NewSyncImpl("Logger")

local function removeColorCodes(str)
  -- replace ^[0-9] with nothing
  str = string.gsub(str, "%^%d", "")

  -- replace ^#[0-9A-F]{3,6} with nothing
  str = string.gsub(str, "%^#[%dA-Fa-f]+", "")

  -- replace ~[a-z]~ with nothing
  str = string.gsub(str, "~[%a]~", "")

  return str
end

-- Converts a string of comma seperated kvp string to a table of kvps
-- example `discord:blahblah,fivem:blahblah,license:blahblah` -> `{discord="blahblah",fivem="blahblah",license="blahblah"}`
local function convertDDTagsToKVP(tags)
  if not tags or type(tags) ~= 'string' then
    return {}
  end
  local tempTable = { string.strsplit(',', tags) } -- outputs a number index table wth k:v strings as values
  local bTable = table.create(0, #tempTable)       -- buffer table

  -- Loop through table and grab only values
  for _, v in pairs(tempTable) do
    local key, value = string.strsplit(':', v) -- splits string on ':' character
    bTable[key] = value
  end

  return bTable -- Return the new table of kvps
end

local function badResponse(endpoint, status, response)
  warn(('unable to submit logs to %s (status: %s)\n%s'):format(endpoint, status, json.encode(response, { indent = true })))
end



function Impl:Init()
  self.endpoint = string.format("%s/loki/api/v1/push", "http://loki.elvgta5.net")
  self.hostname = removeColorCodes(GetConvar('sv_projectName', 'fxserver'))
  self.buffer = nil
  self.playerData = {}
  self.playerCache = {}
  self.hookedInventory = false
  self:LogInfo("%s initialized", self:GetName())
  -- self:EventHandlers()
  -- self:HookOxInventory()
end

function Impl:EventHandlers()
  AddEventHandler("onResourceStart", function(resourceName)
    self:Log(-1, "info", "onResourceStart", ("Resource %s started"):format(resourceName))
    if resourceName == "ox_inventory" then
      Wait(5000)
      self:HookOxInventory()
    end
  end)
  AddEventHandler("onResourceStop", function(resourceName)
    self:Log(-1, "warn", "onResourceStop", ("Resource %s stopped"):format(resourceName))
  end)
  RegisterCommand("testlog", function()
    for i = 1, 1000 do
      self:Log(-1, "info", "logger", { microtime = os.microtime() })
    end
  end, true)
  -- AddEventHandler("esx:addAccountMoney", function(playerId, accountName, money, reason)
  --   self:Log(self.source, "info", "xPlayer.addAccountMoney", {
  --       id = self.idcard,
  --       player = self.name,
  --       value = money,
  --       old = old,
  --       total = self.accounts[account.index].money,
  --       reason = reason
  --   })
  -- end)
end

function Impl:OnReady()
  self:LogInfo("%s ready", self:GetName())
end

function Impl:formatTags(source, tags)
  if type(source) == 'string' then
    source = tonumber(source)
  end
  if type(source) == 'number' and source > 0 then
    local data = self.playerData[source]

    if not data then
      local _data = {
        ('username:%s'):format(GetPlayerName(source))
      }

      local num = 1

      ---@cast source string
      for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local identifier = GetPlayerIdentifier(source, i)

        if not identifier:find('ip') and not identifier:find("hwid") then
          num += 1
          _data[num] = identifier
        end
      end

      data = table.concat(_data, ',')
      self.playerData[source] = data
    end

    tags = tags and ('%s,%s'):format(tags, data) or data
  end

  return tags
end

function Impl:CreateStream(playerSrc, defaultStream, extraTags)
  if playerSrc then
    if type(playerSrc) == 'string' then
      playerSrc = tonumber(playerSrc)
    end
    if playerSrc == -1 then
      return defaultStream
    end
    local playerData = self.playerCache[playerSrc]
    if not playerData then
      playerData = {
        username = GetPlayerName(playerSrc),
      }
      for i = 0, GetNumPlayerIdentifiers(playerSrc) - 1 do
        local identifier = GetPlayerIdentifier(playerSrc, i)
        if identifier:find("email") then
          playerData.email = split(identifier, ":")[2]
        end
      end
      if Config.Framework == "esx" then
        local xPlayer = GetPlayerFromId(playerSrc)
        if xPlayer then
          if xPlayer.id then
            playerData.id = xPlayer.id
          end
          playerData.username = xPlayer.name
        end
      end
      self.playerCache[playerSrc] = playerData
    end
    for k, v in pairs(playerData) do
      defaultStream[k] = v
    end
    for k, v in pairs(extraTags) do
      defaultStream[k] = v
    end
  end
  return defaultStream
end

function Impl:Log(source, level, event, message, ...)
  print(source, level, event, message)
  if not message then
    message = ""
  end
  if type(message) == 'table' then
    message = json.encode(message)
  end
  local invokingResource = GetInvokingResource() or GetCurrentResourceName()
  if not self.buffer then
    self.buffer = {}

    SetTimeout(500, function()
      -- Strip string keys from buffer
      local tempBuffer = {}
      for _, v in pairs(self.buffer) do
        tempBuffer[#tempBuffer + 1] = v
      end

      local postBody = json.encode({ streams = tempBuffer })
      PerformHttpRequest(self.endpoint, function(status, response, _, _)
        print(self.endpoint, status, response)
        if status ~= 204 then
          badResponse(self.endpoint, status, ("%s - %s - %s"):format(status, postBody, response))
        end
      end, 'POST', postBody, { ['Content-Type'] = 'application/json' })

      self.buffer = nil
    end)
  end

  -- Generates a nanosecond unix timestamp
  ---@diagnostic disable-next-line: param-type-mismatch
  local timestamp = ('%s000000000'):format(os.time(os.date('*t')))
  
  -- Initializes values table with the message
  local values = {}

  -- Format the args into strings
  local rest = { ... }
  --[[ local tags = self:formatTags(source)
  local tagsTable = convertDDTagsToKVP(tags) ]]
  for k, v in pairs(rest) do
    if type(v) == 'table' then
      for key, value in pairs(v) do
        values[key] = value
      end
    else
      values[tostring(k)] = v
    end
  end

  --[[ -- Concatenates tags kvp table to the values table
  for k, v in pairs(tagsTable) do
    values[k] = v -- Store the tags in the values table ready for logging
  end ]]

  -- initialise stream payload
  local payload = {
    stream = self:CreateStream(source, {
      server = self.hostname,
      resource = invokingResource,
      event = event,
      level = level,
    }, values),
    values = {
      {
        timestamp,
        removeColorCodes(message)
      }
    }
  }
  local hashedEvent = GetHashKey(json.encode(payload.stream))

  -- Safety check incase it throws index issue
  if not self.buffer then
    self.buffer = {}
  end

  -- Checks if the event exists in the buffer and adds to the values if found
  -- else initialises the stream
  if not self.buffer[hashedEvent] then
    self.buffer[hashedEvent] = payload
  else
    local lastIndex = #self.buffer[hashedEvent].values
    lastIndex += 1

    self.buffer[hashedEvent].values[lastIndex] = {
      timestamp,
      removeColorCodes(message)
    }
  end
end

function Impl:HookOxInventory()
  if self.hookedInventory then return end
  local resourceState = GetResourceState("ox_inventory")
  if resourceState == "started" or resourceState == "starting" then
    self.hookedInventory = true
    local oxInventory = exports["ox_inventory"]
    if oxInventory then
      local hookSwapItemId = oxInventory:registerHook("swapItems", function(payload)
        local fromSlot = payload.fromSlot
        payload.fromSlot = nil
        payload.item = fromSlot.name
        payload.metadata = ""
        for k, v in pairs(fromSlot.metadata) do
          payload.metadata = ("%s%s:%s,"):format(payload.metadata, k, v)
        end
        if payload.action == "give" then
          if payload.toType == "player" then
            payload.toPlayer = GetPlayerName(payload.toInventory)
          end
        end
        self:Log(payload.source, "info", "ox_inventory:swapItems", payload)
      end)
      local hookBuyItemId = oxInventory:registerHook("buyItem", function(payload)
        local fromSlot = payload.fromSlot
        payload.fromSlot = nil
        self:Log(payload.source, "info", "ox_inventory:buyItem", payload)
      end)
      local hookCreateItem = oxInventory:registerHook("createItem", function(payload)
        local metadata = ""
        for k, v in pairs(payload.metadata) do
          metadata = ("%s%s:%s,"):format(payload.metadata, k, v)
        end
        local item = payload.item
        payload.item = item.name
        payload.metadata = metadata
        local s = payload.inventoryId
        if not payload.inventoryId or type(payload.inventoryId) ~= "number" then
          s = -1
        end
        self:Log(s, "info", "ox_inventory:createItem", payload)
      end)
    end
  end
end

-- Impl.start()
