function Response(isSuccess, message, data)
  if not isSuccess then
    return {
      status = "error",
      message = message
    }
  end
  return {
    status = "success",
    data = data,
    message = message
  }
end

function AddVehicle(player, vehicleName)
  if Config.Framework == 'ProjectStarboy' then
    return player.addVehicle(vehicleName)
  elseif Config.Framework == 'esx' then
    TriggerEvent("hm_vehicleshop:addVehicle", player.source, vehicleName, true)
  end
end

---@param vehicle number
function DeleteVehicle(vehicle)
  if DoesEntityExist(vehicle) then
    DeleteEntity(vehicle)
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

function ShallowCopy(t)
  local nt = {}
  for k, v in pairs(t) do
    nt[k] = v
  end
  return nt
end
