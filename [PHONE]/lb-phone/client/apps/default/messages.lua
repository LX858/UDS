

local messageActions = {}
messageActions[1] = "sendMessage"
messageActions[2] = "createGroup"
messageActions[3] = "renameGroup"

local registerNUICallback = RegisterNUICallback
local nuiCallbackName = "Messages"

local function handleMessageAction(data, callback)
  local currentPhoneInstance = currentPhone
  if not currentPhoneInstance then
    return
  end

  local action = data.action
  debugprint("Messages:" .. (action or ""))

  if table.contains(messageActions, action) then
    if not CanInteract() then
      return callback(false)
    end
  end

  local attachments = data.attachments
  if attachments then
    if #attachments == 0 then
      attachments = nil
    end
  end

  if not attachments then
    data.attachments = nil
  else
    local encodedAttachments = json.encode(data.attachments)
    data.attachments = encodedAttachments
  end

  if "sendMessage" == action then
    TriggerServerEvent("phone:messages:messageSent", data.number, data.content, data.attachments)
    TriggerCallback("messages:sendMessage", callback, data.number, data.content, data.attachments, data.id)
  elseif "createGroup" == action then
    local members = {}
    for i = 1, #data.members, 1 do
      members[i] = data.members[i].number
    end
    TriggerCallback("messages:createGroup", callback, members, data.content, data.attachments)
  elseif "renameGroup" == action then
    TriggerCallback("messages:renameGroup", callback, data.id, data.name)
  elseif "getRecentMessages" == action then
    local recentMessages = AwaitCallback("messages:getRecentMessages")
    local conversations = {}

    local function findConversationIndex(channelId)
      for i = 1, #conversations, 1 do
        if conversations[i].id == channelId then
          return i
        end
      end
      return false
    end

    for i = 1, #recentMessages, 1 do
      local messageData = recentMessages[i]
      local conversationIndex = findConversationIndex(messageData.channel_id)

      if not conversationIndex then
        if messageData.is_group then
          local newIndex = #conversations + 1
          local newConversation = {}
          newConversation.id = messageData.channel_id
          newConversation.lastMessage = messageData.last_message
          newConversation.timestamp = messageData.last_message_timestamp
          newConversation.name = messageData.name
          newConversation.isGroup = true
          local members = {}
          local memberData = {}
          memberData.isOwner = messageData.is_owner
          memberData.number = messageData.phone_number
          members[1] = memberData
          newConversation.members = members
          conversations[newIndex] = newConversation
        else
          local phoneNumber = messageData.phone_number
          if phoneNumber ~= currentPhone then
            local newIndex = #conversations + 1
            local newConversation = {}
            newConversation.id = messageData.channel_id
            newConversation.lastMessage = messageData.last_message
            newConversation.timestamp = messageData.last_message_timestamp
            newConversation.number = messageData.phone_number
            newConversation.isGroup = false
            conversations[newIndex] = newConversation
          end
        end
      else
        if messageData.is_group then
          local conversation = conversations[conversationIndex]
          local members = conversation.members
          local newIndex = #members + 1
          local newMember = {}
          newMember.isOwner = messageData.is_owner
          newMember.number = messageData.phone_number
          members[newIndex] = newMember
        end
      end
    end

    for i = 1, #recentMessages, 1 do
      local messageData = recentMessages[i]
      local conversationIndex = findConversationIndex(messageData.channel_id)
      if conversationIndex then
        local phoneNumber = messageData.phone_number
        if phoneNumber == currentPhone then
          local conversation = conversations[conversationIndex]
          conversation.deleted = messageData.deleted
          conversation.unread = messageData.unread > 0
        end
      end
    end

    callback(conversations)
  elseif "getMessages" == action then
    local function processMessages(messages)
      for i = 1, #messages, 1 do
        local message = messages[i]
        local encodedAttachments = message.attachments
        if not encodedAttachments then
          encodedAttachments = "[]"
        end
        message.attachments = json.decode(encodedAttachments)
      end
      callback(messages)
    end
    TriggerCallback("messages:getMessages", processMessages, data.id, data.page)
  else
    if "deleteMessage" == action then
      if Config.DeleteMessages then
        TriggerCallback("messages:deleteMessage", callback, data.id, data.channel)
      end
    elseif "addMember" == action then
      TriggerCallback("messages:addMember", callback, data.id, data.number)
    elseif "removeMember" == action then
      TriggerCallback("messages:removeMember", callback, data.id, data.number)
    elseif "leaveGroup" == action then
      TriggerCallback("messages:leaveGroup", callback, data.id)
    elseif "markRead" == action then
      TriggerCallback("messages:markRead", callback, data.id)
    elseif "deleteConversations" == action then
      TriggerCallback("messages:deleteConversations", callback, data.channels)
    end
  end
end

registerNUICallback(nuiCallbackName, handleMessageAction)

local registerNetEvent = RegisterNetEvent

local function onNewMessage(channelId, messageId, sender, content, attachments)
  local messageData = {}
  messageData.channelId = channelId
  messageData.messageId = messageId
  messageData.sender = sender
  messageData.content = content
  if attachments then
    local decodedAttachments = json.decode(attachments)
    messageData.attachments = decodedAttachments or {}
  else
    messageData.attachments = {}
  end
  SendReactMessage("messages:newMessage", messageData)
end

registerNetEvent("phone:messages:newMessage", onNewMessage)

local function onMessageDeleted(channelId, messageId, isLastMessage)
  local messageData = {}
  messageData.channelId = channelId
  messageData.messageId = messageId
  messageData.isLastMessage = isLastMessage
  SendReactMessage("messages:messageDeleted", messageData)
end

registerNetEvent("phone:messages:messageDeleted", onMessageDeleted)

local function onRenameGroup(channelId, name)
  local messageData = {}
  messageData.channelId = channelId
  messageData.name = name
  SendReactMessage("messages:renameGroup", messageData)
end

registerNetEvent("phone:messages:renameGroup", onRenameGroup)

local function onMemberAdded(channelId, number)
  local messageData = {}
  messageData.channelId = channelId
  messageData.number = number
  SendReactMessage("messages:addMember", messageData)
end

registerNetEvent("phone:messages:memberAdded", onMemberAdded)

local function onMemberRemoved(channelId, number)
  local messageData = {}
  messageData.channelId = channelId
  messageData.number = number
  SendReactMessage("messages:removeMember", messageData)
end

registerNetEvent("phone:messages:memberRemoved", onMemberRemoved)

local function onChangeOwner(channelId, number)
  local messageData = {}
  messageData.channelId = channelId
  messageData.number = number
  SendReactMessage("messages:changeOwner", messageData)
end

registerNetEvent("phone:messages:ownerChanged", onChangeOwner)

local function onNewChannel(channelData)
  SendReactMessage("messages:newChannel", channelData)
end

registerNetEvent("phone:messages:newChannel", onNewChannel)
