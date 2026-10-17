local function SendReactMessage(action, data)
  SendNUIMessage({
    action = action,
    data = data
  })
end

RegisterNetEvent("demi_lootbox:RollCase", function(lootPool, winner)
  SetNuiFocus(true, true)
  SendReactMessage('setLootData', { pool = lootPool, winner = winner })
end)

RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  TriggerServerEvent('demi_lootbox:getQueuedItem')
  cb({})
end)

RegisterNUICallback('finished', function(_, cb)
  SetNuiFocus(false, false)
  TriggerServerEvent('demi_lootbox:getQueuedItem')
  cb({})
end)
