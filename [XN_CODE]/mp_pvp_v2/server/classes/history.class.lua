History = class()

function History:Init()
  local histories = json.decode(LoadResourceFile(GetCurrentResourceName(), "history.json"))
  self.data = {}
  if histories then
    self.data = histories
  else
    SaveResourceFile(GetCurrentResourceName(), "history.json", json.encode(self.data))
  end
  self:EventHandler()
end

function History:EventHandler()
  RegisterNetEvent("mp_pvp_v2:sv:addHistory", function(playerId, state, type, point)
    self:AddHistory(playerId, state, type, point)
  end)
end

function History:AddHistory(playerId, state, type, point)
  if not self.data[tostring(playerId)] then
    self.data[tostring(playerId)] = {}
  end

  table.insert(self.data[tostring(playerId)], {
    time = os.time(),
    state = state,
    type = type,
    point = point
  })

  if #self.data[tostring(playerId)] > 10 then
    table.sort(self.data[tostring(playerId)], function(a, b)
      return a.time > b.time
    end)


    while #self.data[tostring(playerId)] > 10 do
      table.remove(self.data[tostring(playerId)])
    end
  end
  local xPlayer = GetPlayerFromId(playerId)
  if xPlayer then
    TriggerClientEvent("mp_pvp_v2:cl:updateHistory", xPlayer.PlayerData.source, self.data[tostring(playerId)])
  end
  SaveResourceFile(GetCurrentResourceName(), "history.json", json.encode(self.data))
end

function History:GetHistory(playerId)
  return self.data[tostring(playerId)] or {}
end
