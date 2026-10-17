function CreateDiscordWebhookMessage()
  ---@class DiscordWebhookMessageBuilder
  local self = {}
  ---@type DiscordWebhookData
  self.data = {}

  ---Set the username of the webhook message
  ---@param userName string
  ---@return DiscordWebhookMessageBuilder
  function self.setUserName(userName)
    self.data.username = userName
    return self
  end

  ---Set the avatar url of the webhook message
  ---@param url string
  ---@return DiscordWebhookMessageBuilder
  function self.setAvatarUrl(url)
    self.data.avatar_url = url
    return self
  end

  ---Set the content of the webhook message
  ---@param content string
  ---@return DiscordWebhookMessageBuilder
  function self.setContent(content)
    self.data.content = content
    return self
  end

  ---Add an embed to the webhook message
  ---@param embed DiscordEmbed
  ---@return DiscordWebhookMessageBuilder
  function self.addEmbed(embed)
    if not self.data.embeds then
      self.data.embeds = {}
    end
    table.insert(self.data.embeds, embed)
    return self
  end

  ---Build the webhook message
  ---@return DiscordWebhookData
  function self.build()
    return self.data
  end

  return self
end
