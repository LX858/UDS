if not lib then return end

local Utils = {}

local webHook = "https://discord.com/api/webhooks/1372816846612463727/ji1d1Q6QX65dqEuz1L4ZXNGH9_je_gLMJuHnRghIwIhBcBMjTccEY5SBgDcEjUdL5WRN"

if webHook ~= '' then
	local validHosts = {
		['i.imgur.com'] = true,
		['raw.githubusercontent.com'] = true,
	}

	local validExtensions = {
		['png'] = true,
		['apng'] = true,
		['webp'] = true,
	}

	local headers = { ['Content-Type'] = 'application/json' }

	function Utils.IsValidImageUrl(url)
		local host, extension = url:match('^https?://([^/]+).+%.([%l]+)')
		return host and extension and validHosts[host] and validExtensions[extension]
	end

	---@param title string
	---@param message string
	---@param image string
	function Utils.DiscordEmbed(title, message, image, color)
		PerformHttpRequest(webHook, function() end, 'POST', json.encode({
			username = 'ox_inventory', embeds = {
				{
					title = title,
					color = color,
					footer = {
						text = os.date('%c'),
					},
					description = message,
					thumbnail = {
						url = image,
						width = 100,
					}
				}
			}
		}), headers)
	end
end

---@param source number
---@param event string
---@param reason string
---@param kick? boolean
function Utils.LogExploit(source, event, reason, kick)
	local playerName = (source and source > 0 and GetPlayerName(source)) or 'Unknown'
	local msg = ('[EXPLOIT] Player %s (%s) triggered %s: %s'):format(source, playerName, event, reason)
	print('^1' .. msg .. '^0')
	lib.logger(source, 'exploit', ('Event: %s | Lý do: %s'):format(event, reason))
	if kick and source and source > 0 then
		DropPlayer(source, ('[Anticheat] %s'):format(reason))
	end
end

return Utils
