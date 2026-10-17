function CreateDiscordEmbed()
  ---@class DiscordWebhookEmbedBuilder
  local self = {}
  ---@type DiscordEmbed
  self.data = {}

  ---Set the color of the embedded messages
  ---@param color number
  ---@return DiscordWebhookEmbedBuilder
  function self.setColor(color)
    self.data.color = color
    return self
  end

  ---Set the author of the embedded messages
  ---@param author {name: string, url:string, icon_url:string}
  ---@return DiscordWebhookEmbedBuilder
  function self.setAuthor(author)
    self.data.author = author
    return self
  end

  ---Set the title of the embedded messages
  ---@param title string
  ---@return DiscordWebhookEmbedBuilder
  function self.setTitle(title)
    self.data.title = title
    return self
  end

  ---Set the url of the embedded messages
  ---@param url string
  ---@return DiscordWebhookEmbedBuilder
  function self.setUrl(url)
    self.data.url = url
    return self
  end

  ---Set the description of the embedded messages
  ---@param description string
  ---@return DiscordWebhookEmbedBuilder
  function self.setDescription(description)
    self.data.description = description
    return self
  end

  ---Add a field to the embedded messages
  ---@param name string
  ---@param value string
  ---@param inline boolean | nil
  ---@return DiscordWebhookEmbedBuilder
  function self.addField(name, value, inline)
    if not self.data.fields then
      self.data.fields = {}
    end
    table.insert(self.data.fields, { name = name, value = value, inline = inline })
    return self
  end

  ---Set the image of the embedded messages
  ---@param url string
  ---@return DiscordWebhookEmbedBuilder
  function self.setImage(url)
    self.data.image = { url = url }
    return self
  end

  ---Set the thumbnail of the embedded messages
  ---@param url string
  ---@return DiscordWebhookEmbedBuilder
  function self.setThumbnail(url)
    self.data.thumbnail = { url = url }
    return self
  end

  ---Set the footer of the embedded messages
  ---@param footer {text: string, icon_url: string}
  ---@return DiscordWebhookEmbedBuilder
  function self.setFooter(footer)
    self.data.footer = footer
    return self
  end

  ---Set the timestamp of the embedded messages
  ---@param timeStamp string
  ---@return DiscordWebhookEmbedBuilder
  function self.setTimestamp(timeStamp)
    self.data.timestamp = timeStamp
    return self
  end

  ---Build the embedded messages
  ---@return DiscordEmbed
  function self.build()
    return self.data
  end

  return self
end
