RegisterNUICallback("Clock", function(data, cb)
  local action = data.action
  debugprint("Clock:" .. (action or ""))
  if "getAlarms" == action then
    TriggerCallback("clock:getAlarms", cb)
  elseif "createAlarm" == action then
    TriggerCallback("clock:createAlarm", cb, data.label, data.hours, data.minutes)
  elseif "deleteAlarm" == action then
    TriggerCallback("clock:deleteAlarm", cb, data.id)
  elseif "toggleAlarm" == action then
    TriggerCallback("clock:toggleAlarm", cb, data.id, data.enabled)
  elseif "updateAlarm" == action then
    TriggerCallback("clock:updateAlarm", cb, data.id, data.label, data.hours, data.minutes)
  end
end)
