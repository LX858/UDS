

local currentMail = nil

local function decodeMailData(mailData)
  if not mailData then
    return false
  end

  if not mailData.attachments then
    mailData.attachments = {}
  else
    mailData.attachments = json.decode(mailData.attachments)
  end

  if not mailData.actions then
    mailData.actions = {}
  else
    mailData.actions = json.decode(mailData.actions)
  end

  return mailData
end

local registerNUICallback = RegisterNUICallback
local nuiEventName = "Mail"

local function handleMailEvent(postData, callback)
  local action = postData.action
  debugprint("Mail:", action or "")

  if action == "isLoggedIn" then
    TriggerCallback("mail:isLoggedIn", callback)
  elseif action == "createMail" then
    local email = postData.data.email
    local password = postData.data.password
    TriggerCallback("mail:createAccount", callback, email, password)
  elseif action == "changePassword" then
    local oldPassword = postData.oldPassword
    local newPassword = postData.newPassword
    TriggerCallback("mail:changePassword", callback, oldPassword, newPassword)
  elseif action == "deleteAccount" then
    local password = postData.password
    TriggerCallback("mail:deleteAccount", callback, password)
  elseif action == "login" then
    local email = postData.data.email
    local password = postData.data.password
    TriggerCallback("mail:login", callback, email, password)
  elseif action == "logout" then
    TriggerCallback("mail:logout", callback)
  elseif action == "getMails" then
    local requestData = {}
    requestData.lastId = postData.lastId
    TriggerCallback("mail:getMails", callback, requestData)
  elseif action == "getMail" then
    local function processMailData(mailData)
      local decodedMail = decodeMailData(mailData)
      currentMail = decodedMail
      callback(decodedMail)
    end

    local mailId = postData.id
    TriggerCallback("mail:getMail", processMailData, mailId)
  elseif action == "search" then
    local requestData = {}
    requestData.search = postData.query
    requestData.lastId = postData.lastId
    TriggerCallback("mail:getMails", callback, requestData)
  elseif action == "sendMail" then
    local mailData = postData.data
    TriggerCallback("mail:sendMail", callback, mailData)
  elseif action == "deleteMail" then
    local mailId = postData.id
    TriggerCallback("mail:deleteMail", callback, mailId)
  elseif action == "action" then
    local expectedMailId = currentMail.id
    local actualMailId = postData.id

    if expectedMailId ~= actualMailId then
      debugprint("wrong mail id for action")
      return
    end

    local actionId = postData.actionId or 0
    actionId = actionId + 1
    local actionData = currentMail.actions[actionId]

    if actionData then
      actionData = actionData.data
    end

    if not actionData then
      debugprint("no action found", actionId)
      return
    end

    local qbMailData = actionData.data
    if qbMailData then
      qbMailData = qbMailData.qbMail
    end

    if qbMailData then
      TriggerEvent(actionData.event, actionData.data.data)
      return callback("ok")
    end

    local isServerAction = actionData.isServer
    local eventName = actionData.event
    local mailId = postData.id
    local actionSpecificData = actionData.data

    if isServerAction then
      TriggerServerEvent(eventName, mailId, actionSpecificData)
    else
      TriggerEvent(eventName, mailId, actionSpecificData)
    end

    callback("ok")
  end
end

registerNUICallback(nuiEventName, handleMailEvent)

local registerNetEvent = RegisterNetEvent

local function handleNewMail(mailData)
  SendReactMessage("mail:newMail", mailData)
end

registerNetEvent("phone:mail:newMail", handleNewMail)

local function handleMailDeletion(mailId)
  SendReactMessage("mail:deleteMail", mailId)
end

registerNetEvent("phone:mail:mailDeleted", handleMailDeletion)