--- A simple wrapper around SendNUIMessage that you can use to
--- dispatch actions to the React frame.
---
---@param action string The action you wish to target
---@param data any The data you wish to send along with this action
function SendReactMessage(action, data)
  SendNUIMessage({
    action = action,
    data = data
  })
end

local currentResourceName = GetCurrentResourceName()

local debugIsEnabled = GetConvarInt(('%s-debugMode'):format(currentResourceName), 0) == 1

--- A simple debug print function that is dependent on a convar
--- will output a nice prettfied message if debugMode is on
function debugPrint(...)
  if not debugIsEnabled then return end
  local args <const> = { ... }

  local appendStr = ''
  for _, v in ipairs(args) do
    appendStr = appendStr .. ' ' .. tostring(v)
  end
  local msgTemplate = '^3[%s]^0%s'
  local finalMsg = msgTemplate:format(currentResourceName, appendStr)
  print(finalMsg)
end

function GetPlayerServerIdFromPed(pedId)
  local players = GetActivePlayers()
  for _, playerId in ipairs(players) do
    local ped = GetPlayerPed(playerId)
    if ped == pedId then
      return GetPlayerServerId(playerId)
    end
  end
end

function GetRank(score)
  for rankName, rankData in pairs(Config.Ranks) do
    if score >= rankData.min and (not rankData.max or score <= rankData.max) then
      return {
        name = rankName,
        label = rankData.label,
        min = rankData.min,
        max = rankData.max or nil
      }
    elseif score <= 0 then
      return {
        name = "dong",
        label = "Đồng",
        min = 0,
        max = 0
      }
    end
  end
  return nil
end
