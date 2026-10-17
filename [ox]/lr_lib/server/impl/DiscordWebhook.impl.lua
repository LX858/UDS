---@class SVDiscordWebhookImpl : Impl
local Impl = NewSyncImpl("DiscordWebhook")

---@alias DiscordEmbedField {name: string, value: string, inline?: boolean}
---@alias DiscordEmbed {color?: number, author?: {name?: string, url?:string, icon_url?:string}, title?: string, url?:string, description?: string, fields?: DiscordEmbedField[], thumbnail?: {url?: string}, image?: {url?: string}, footer?: {text?: string, icon_url?:string}, timestamp?: string}
---@alias DiscordWebhookData {username?:string, avatar_url?:string, content?:string, embeds?:DiscordEmbed[]}

function Impl:Init()
  self:LogInfo("%s initialized", self:GetName())
end

function Impl:Test()
  local messageData = CreateDiscordWebhookMessage()
      .setUserName("Test")
      .addEmbed(
        CreateDiscordEmbed()
        .setAuthor({ name = "test embeds author", icon_url = "https://i.imgur.com/R66g1Pe.jpg" })
        .setTitle("Test title")
        .setDescription("Test description")
        .setColor(0x00ff00)
        .addField("Field 1", "Value 1", true)
        .addField("Field 2", "Value 2", true)
        .addField("Field 3", "Value 3", true)
        .addField("Field 4", "Value 4", true)
        .addField("Field 5", "Value 5", true)
        .setThumbnail("https://upload.wikimedia.org/wikipedia/commons/3/38/4-Nature-Wallpapers-2014-1_ukaavUI.jpg")
        .setImage("https://upload.wikimedia.org/wikipedia/commons/3/38/4-Nature-Wallpapers-2014-1_ukaavUI.jpg")
        .setFooter({ text = "Test footer", icon_url = "https://i.imgur.com/fKL31aD.jpg" })
        .build()
      )
      .addEmbed(
        CreateDiscordEmbed()
        .setAuthor({ name = "test2", icon_url = "https://i.imgur.com/R66g1Pe.jpg" })
        .setTitle("Test title 2")
        .setDescription("Test description")
        .setColor(0x000000)
        .addField("Field 1", "Value 1", true)
        .addField("Field 2", "Value 2", true)
        .addField("Field 4", "Value 4", true)
        .addField("Field 5", "Value 5", true)
        .setThumbnail("https://upload.wikimedia.org/wikipedia/commons/3/38/4-Nature-Wallpapers-2014-1_ukaavUI.jpg")
        .setImage("https://upload.wikimedia.org/wikipedia/commons/3/38/4-Nature-Wallpapers-2014-1_ukaavUI.jpg")
        .setFooter({ text = "Test footer2", icon_url = "https://i.imgur.com/fKL31aD.jpg" })
        .build()
      )
      .build()

  self:Send(
    "https://discord.com/api/webhooks/1313351540316311643/pvBPJJYXEpkkg9ta6q_HR6UsWulYj0PlWm1rNE-I1kizUrRNQhi2rDTvG8kQ7DABjPm9",
    messageData)
end

function Impl:OnReady()
  self:LogInfo("%s ready", self:GetName())
end

---Sends
---@param webhookUrl string
---@param data DiscordWebhookData
function Impl:Send(webhookUrl, data)
  PerformHttpRequest(webhookUrl, function(statusCode, text, headers)
    self:LogInfo("Webhook response: %s - %s", statusCode, text)
  end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end

Impl.start()
