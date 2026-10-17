InExportCall = false
isVideoCall = false
currentCallId = nil
isInCall = false
activeCustomCall = nil
callStartTime = 0
callAnswered = false
customNumbers = {}
function EndCustomCall()
  debugprint("EndCustomCall triggered")
  if activeCustomCall then
    local callDuration = math.floor((GetGameTimer() - callStartTime) / 1000 + 0.5)
    debugprint("Custom call to", activeCustomCall.number, "ended after", callDuration, "seconds", "answered:", callAnswered)
    TriggerServerEvent("phone:logCall", activeCustomCall.number, callDuration)
  end
  isInCall = false
  activeCustomCall = nil
  currentCallId = nil
  callStartTime = 0
  callAnswered = false
  SetPhoneAction("default")
  SendReactMessage("call:endCall")
  if not phoneOpen then
    PlayCloseAnim()
  end
end
function TryCustomCall(number)
  local customNumber = customNumbers[number]
  if not customNumber then
    return false
  end
  local callId = "CUSTOM_NUMBER_" .. math.random(9999999)
  isInCall = true
  currentCallId = callId
  activeCustomCall = customNumber
  callStartTime = GetGameTimer()
  callAnswered = false
  Citizen.CreateThreadNow(function()
    customNumber.onCall({
      id = callId,
      accept = function()
        if not callAnswered then
          if currentCallId == callId then
            goto lbl_9
          end
        end
        do return end
        ::lbl_9::
        callAnswered = true
        SetPhoneAction("call")
        SendReactMessage("call:connected")
      end,
      deny = function()
        if currentCallId == callId then
          EndCustomCall()
        end
      end,
      setName = function(name)
        if currentCallId == callId then
          SendReactMessage("call:setContactData", {name = name})
        end
      end,
      hasEnded = function()
        return currentCallId ~= callId
      end
    })
  end)
  return true
end
function HandleCustomCallAction(action)
  if not activeCustomCall then
    return
  end
  if "end" == action then
    if activeCustomCall.onEnd then
      Citizen.CreateThreadNow(activeCustomCall.onEnd)
    end
    EndCustomCall()
    return
  end
  if action.find(action, "keypad_") then
    if not activeCustomCall.onKeypad then
      return
    end
    local key = action.sub(action, 8)
    if not key then
      return
    end
    Citizen.CreateThreadNow(function()
      activeCustomCall.onKeypad(key)
    end)
    return
  end
  if activeCustomCall.onAction then
    activeCustomCall.onAction(action)
  end
end
RegisterNUICallback("Phone", function(data, cb)
  if not currentPhone then
    return
  end
  local action = data.action
  debugprint("Phone:" .. (action or ""))
  if "getContacts" == action then
    TriggerCallback("getContacts", function(contacts)
      if Config.Companies.Enabled then
        for company, companyData in pairs(Config.Companies.Contacts) do
          contacts[#contacts + 1] = {
            firstname = companyData.name,
            avatar = companyData.photo,
            company = company
          }
        end
      end
      cb(contacts)
    end)
  elseif "toggleFavourite" == action then
    TriggerCallback("toggleFavourite", cb, data.number, data.favourite)
  elseif "toggleBlock" == action then
    TriggerCallback("toggleBlock", cb, data.number, data.blocked)
  elseif "removeContact" == action then
    TriggerCallback("removeContact", cb, data.number)
  elseif "updateContact" == action then
    TriggerCallback("updateContact", cb, data.data)
  elseif "saveContact" == action then
    TriggerCallback("saveContact", cb, data.data)
  elseif "getRecent" == action then
    TriggerCallback("getRecentCalls", cb, true == data.missed, data.lastId)
  elseif "getBlockedNumbers" == action then
    TriggerCallback("getBlockedNumbers", function(blockedList)
      local numbers = {}
      for index, contact in pairs(blockedList) do
        numbers[index] = contact.number
      end
      cb(numbers)
    end)
  elseif "toggleMute" == action then
    if not currentCallId then
      return cb(false)
    else
      if activeCustomCall then
        HandleCustomCallAction(data.toggle and "mute" or "unmute")
        return cb(data.toggle)
      end
    end
    if data.toggle then
      RemoveFromCall(currentCallId)
    else
      AddToCall(currentCallId)
    end
    TriggerServerEvent("phone:phone:toggleMute", data.toggle)
    cb(data.toggle)
  elseif "toggleSpeaker" == action then
    if not currentCallId then
      return cb(false)
    else
      if activeCustomCall then
        HandleCustomCallAction(data.toggle and "enable_speaker" or "disable_speaker")
        return cb(data.toggle)
      end
    end
    TriggerServerEvent("phone:phone:toggleSpeaker", data.toggle)
    ToggleSpeaker(data.toggle)
    cb(data.toggle)
  elseif "sendVoicemail" == action then
    TriggerCallback("sendVoicemail", cb, data.data)
  elseif "getVoiceMails" == action then
    TriggerCallback("getRecentVoicemails", cb, data.page)
  elseif "deleteVoiceMail" == action then
    TriggerCallback("deleteVoiceMail", cb, data.id)
  elseif "keypad" == action then
    cb("ok")
    if activeCustomCall then
      HandleCustomCallAction("keypad_" .. data.key)
    end
  end
  if "call" == action then
    if TryCustomCall(data.number) then
      return cb("CUSTOM_NUMBER")
    end
    if data.company then
      if Config.Companies.Enabled then
        if not data.videoCall then
          goto lbl_223
        end
      end
      do return end
      ::lbl_223::
      if not Config.Companies.Contacts[data.company] then
        local validService = false
        for i = 1, #Config.Companies.Services, 1 do
          if Config.Companies.Services[i].job == data.company then
            validService = true
            break
          end
        end
        if not validService then
          return
        end
      end
    end
    isVideoCall = data.videoCall
    TriggerCallback("call", cb, data)
  elseif "answerCall" == action then
    if IsInCall() then
      debugprint("answerCall: Already in call")
      return
    end
    if IsLive() then
      debugprint("answerCall: Ending live")
      TriggerCallback("instagram:endLive")
    else
      if IsWatchingLive() then
        debugprint("answerCall: Leaving live")
        SendReactMessage("instagram:liveEnded", IsWatchingLive())
      end
    end
    debugprint("Answering call", data.callId)
    TriggerCallback("answerCall", cb, data.callId)
    cb("ok")
  elseif "endCall" == action then
    EndCall()
    cb("ok")
  elseif "flipCamera" == action then
    ToggleSelfieCam(not IsSelfieCam())
  elseif "requestVideoCall" == action then
    TriggerCallback("requestVideoCall", cb, data.callId, data.peerId)
  elseif "answerVideoRequest" == action then
    TriggerCallback("answerVideoRequest", cb, data.callId, data.accept)
    if data.accept then
      isVideoCall = true
      EnableWalkableCam()
    end
  elseif "stopVideoCall" == action then
    TriggerCallback("stopVideoCall", cb, data.callId)
  end
end)
function EndCall()
  TriggerServerEvent("phone:endCall")
  if activeCustomCall then
    HandleCustomCallAction("end")
  end
end
RegisterNetEvent("phone:phone:setCall", function(callData)
  if not HasPhoneItem(currentPhone) then
    debugprint("no phone, not showing call")
    return
  end
  if phoneDisabled then
    debugprint("phone is disabled, not showing call")
    return
  end
  if not activeCustomCall then
    if not isInCall then
      goto lbl_33
    end
  end
  debugprint("in a (custom?) call", tostring(activeCustomCall), tostring(isInCall))
  do return end
  ::lbl_33::
  if IsPedDeadOrDying(PlayerPedId(), false) then
    debugprint("player is dead, not showing call")
    return
  else
    if CanOpenPhone then
      if not CanOpenPhone() then
        debugprint("can't open phone, not showing call")
        return
      end
    end
  end
  isVideoCall = callData.videoCall
  SendReactMessage("incomingCall", callData)
end)
RegisterNetEvent("phone:phone:enableExportCall", function()
  InExportCall = true
end)
RegisterNetEvent("phone:phone:connectCall", function(callId, skipUI)
  debugprint("phone:phone:connectCall", callId, skipUI)
  isInCall = true
  currentCallId = callId
  AddToCall(callId)
  if skipUI then
    return
  end
  SetPhoneAction("call")
  SendReactMessage("call:connected")
  if isVideoCall then
    EnableWalkableCam()
  end
end)
RegisterNetEvent("phone:phone:endCall", function()
  debugprint("phone:phone:endCall")
  local wasInCall = isInCall
  isInCall = false
  isVideoCall = false
  SetPhoneAction("default")
  DisableWalkableCam()
  if not phoneOpen and wasInCall then
    debugprint("close anim")
    PlayCloseAnim()
  end
  RemoveFromCall(currentCallId)
  currentCallId = nil
  InExportCall = false
  SendReactMessage("call:endCall")
end)
RegisterNetEvent("phone:phone:userUnavailable", function()
  debugprint("phone:phone:userUnavailable")
  SendReactMessage("call:userUnavailable")
end)
RegisterNetEvent("phone:phone:userBusy", function()
  debugprint("phone:phone:userBusy")
  SendReactMessage("call:userBusy")
end)
function IsInCall()
  return isInCall
end
exports("IsInCall", IsInCall)
exports("AddContact", function(contact)
  assert(type(contact) == "table", "contact must be a table")
  assert(type(contact.number) == "string", "contact.number must be a string")
  assert(type(contact.firstname) == "string", "contact.firstname must be a string")
  local success = AwaitCallback("saveContact", contact)
  if success then
    SendReactMessage("phone:contactAdded", contact)
  end
  return success
end)
RegisterNetEvent("phone:phone:videoRequested", function(peerId)
  debugprint("phone:phone:videoRequested", peerId)
  SendReactMessage("call:videoRequested", peerId)
end)
RegisterNetEvent("phone:phone:videoRequestAnswered", function(accepted)
  debugprint("phone:phone:videoRequestAnswered", accepted)
  SendReactMessage("call:videoRequestAnswered", accepted)
  if accepted then
    isVideoCall = true
    EnableWalkableCam()
  end
end)
RegisterNetEvent("phone:phone:stopVideoCall", function()
  debugprint("phone:phone:stopVideoCall")
  SendReactMessage("call:stopVideoCall")
  isVideoCall = false
  DisableWalkableCam()
end)
RegisterNetEvent("phone:phone:contactAdded", function(contact)
  debugprint("phone:phone:contactAdded", contact)
  SendReactMessage("phone:contactAdded", contact)
end)
function CreateCall(options)
  assert(type(options) == "table", "options must be a table")
  assert(options.number or options.company, "options must contain either a number or company")
  if not currentPhone then
    return debugprint("no phone")
  end
  if options.company then
    if not Config.Companies.Enabled then
      return debugprint("company calls are disabled in config")
    end
    local validCompany = false
    local companyLabel = options.company
    if Config.Companies.Contacts[options.company] then
      companyLabel = Config.Companies.Contacts[options.company].name
      validCompany = true
    else
      for i = 1, #Config.Companies.Services, 1 do
        if Config.Companies.Services[i].job == options.company then
          validCompany = true
          companyLabel = Config.Companies.Services[i].name
          break
        end
      end
    end
    if not validCompany then
      return debugprint("invalid company")
    end
    debugprint("CreateCall: company", options)
    SendReactMessage("call", {
      company = options.company,
      companylabel = companyLabel,
      hideCallerId = true == options.hideNumber
    })
  else
    debugprint("CreateCall: number", options)
    SendReactMessage("call", {
      number = options.number,
      videoCall = true == options.videoCall,
      hideCallerId = true == options.hideNumber
    })
  end
end
exports("CreateCall", CreateCall)
exports("CreateCustomNumber", function(number, data)
  local resource = GetInvokingResource()
  assert(type(number) == "string", "number must be a string")
  assert(type(data) == "table", "data must be a table")
  assert(type(data.onCall) == "function", "data.onCall must be a function")
  if customNumbers[number] then
    return false, "Number already exists"
  end
  customNumbers[number] = {
    resource = resource,
    number = number,
    onCall = data.onCall,
    onEnd = data.onEnd,
    onAction = data.onAction,
    onKeypad = data.onKeypad
  }
  return true
end)
exports("RemoveCustomNumber", function(number)
  local resource = GetInvokingResource()
  assert(type(number) == "string", "number must be a string")
  if not customNumbers[number] then
    return false, "Number does not exist"
  end
  local numberResource
  if customNumbers[number] then
    numberResource = customNumbers[number].resource
  end
  if numberResource ~= resource then
    return false, "Number was not created by " .. resource
  end
  customNumbers[number] = nil
  return true
end)
exports("EndCustomCall", function()
  if activeCustomCall then
    EndCustomCall()
    return true
  end
  return false
end)
AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() then
    return
  end
  for number, customNumber in pairs(customNumbers) do
    if customNumber.resource == resourceName then
      debugprint("Removed custom number", number, "due to resource stopping")
      if activeCustomCall == customNumber then
        HandleCustomCallAction("end")
      end
      customNumbers[number] = nil
    end
  end
end)
