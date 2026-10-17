

local discordColors = {
    info = tonumber("3498DB", 16),
    success = tonumber("66FFA3", 16),
    warning = tonumber("F1C40F", 16),
    error = tonumber("E74C3C", 16),
}

local avatars = {}

local function GetAvatar(source)
    if not Config.Logs.Avatar then
        debugprint("GetAvatar: Config.Logs.Avatar is set to false, returning random avatar")

        return "https://cdn.discordapp.com/embed/avatars/" .. math.random(0, 5) .. ".png"
    end

    if avatars[source] then
        debugprint("GetAvatar: using cached avatar for source", source)

        return avatars[source]
    end

    ---@type string | nil
    local avatar
    local fetchedAvatar = false
    local timeout = GetGameTimer() + 10000
    local discord = GetPlayerIdentifierByType(source, "discord")
    local fivem = GetPlayerIdentifierByType(source, "fivem")

    discord = discord and discord:sub(9)
    fivem = fivem and fivem:sub(7)

    if discord and DISCORD_TOKEN then
        debugprint("GetAvatar: fetching discord avatar for source", source)

        PerformHttpRequest("https://discord.com/api/v9/users/" .. discord, function(status, response)
            if status == 200 then
                local data = json.decode(response)

                if data.avatar then
                    avatar = "https://cdn.discordapp.com/avatars/" .. discord .. "/" .. data.avatar .. ".png"
                end
            end

            fetchedAvatar = true
        end, "GET", "", { ["Authorization"] = "Bot " .. DISCORD_TOKEN })
    else
        debugprint("GetAvatar: no discord, steam or fivem identifier found for source", source)

        fetchedAvatar = true
    end

    while not fetchedAvatar do
        Wait(500)

        if GetGameTimer() > timeout then
            debugprint("GetAvatar: timed out when fetching avatar for source", source)
            break
        end
    end

    debugprint("GetAvatar: fetched avatar for source", source)

    avatars[source] = avatar

    return avatar or ("https://cdn.discordapp.com/embed/avatars/" .. math.random(0, 5) .. ".png")
end

function GetTimestampISO()
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")

    if #timestamp < 24 then
        return
    elseif #timestamp > 24 then
        timestamp = timestamp:sub(1, 24)
    end

    if not timestamp:match("%d%d%d%d%-%d%d%-%d%dT%d%d%:%d%d%:%d%d%.%d%d%dZ") then
        debugprint("Invalid timestamp")
        return
    end

    return timestamp
end

local function LogToDiscord(source, action, level, title, metadata, image)
    if not LOGS[action] then
        infoprint("error", "No webhook set for action " .. action .. " and no default webhook set in lb-phone/server/apiKeys.lua")
        return
    end

	local cleanedUpIdentifiers = {}
	local accounts = {}
	local description = ""
	local accountsCount = 0

    if type(metadata) == "table" then
        description = "```json\n" .. json.encode(metadata, { indent = true }) .. "\n```\n"
    elseif type(metadata) == "string" then
        description = "```\n" .. metadata .. "\n```\n"
    end

    if source then
        local identifiers = GetPlayerIdentifiers(source)

        for i = 1, #identifiers do
            local identifierTypeIndex = identifiers[i]:find(":")

            if not identifierTypeIndex then
                goto continue
            end

            local identifierType = identifiers[i]:sub(1, identifierTypeIndex - 1)
            local identifier = identifiers[i]:sub(identifierTypeIndex + 1)

            accountsCount += 1
            accounts[accountsCount] = "🔗 **" .. identifierType:upper() .. ":** `" .. identifier .. "`"

            if identifierType ~= "ip" then
                cleanedUpIdentifiers[identifierType] = identifier
            end

            ::continue::
        end
    end

    -- Add player info section
    if source then
        description = description .. "👤 **Thông tin người chơi:**\n"
        description = description .. "**Tên:** `" .. GetPlayerName(source) .. "`\n"
        description = description .. "**ID:** `" .. source .. "`\n"
        description = description .. "**Thời gian:** <t:" .. math.floor(GetGameTimer() / 1000) .. ":F>\n\n"
    end

    -- Add accounts section with better formatting
	if accountsCount > 0 then
		description = description .. "🔑 **Tài khoản liên kết:**\n"
		for i = 1, accountsCount do
			description = description .. accounts[i] .. "\n"
		end
		description = description .. "\n"
	end

    -- Add identifiers section with better formatting
    local identifierCount = 0
    for _ in pairs(cleanedUpIdentifiers) do
        identifierCount = identifierCount + 1
    end
    
    if identifierCount > 0 then
        description = description .. "🆔 **Định danh:**\n"
        for identifierType, identifier in pairs(cleanedUpIdentifiers) do
            description = description .. "• **" .. identifierType:upper() .. ":** `" .. identifier .. "`\n"
        end
    end

    -- Create beautiful embed with better structure
	local embed = {
		title = "📱 " .. title,
		description = description,
		color = discordColors[level],
		timestamp = GetTimestampISO(),
        image = image and { url = image } or nil,
        thumbnail = source and { url = GetAvatar(source) } or nil,
		author = source and {
			name = "LB Phone Logs",
			icon_url = "https://docs.lbscripts.com/images/icons/icon.png"
		} or {
			name = "LB Phone System",
			icon_url = "https://docs.lbscripts.com/images/icons/icon.png"
		},
		footer = {
			text = "LB Phone • " .. os.date("%d/%m/%Y %H:%M:%S"),
			icon_url = "https://docs.lbscripts.com/images/icons/icon.png"
		},
        fields = {
            {
                name = "🎯 Hành động",
                value = "`" .. action .. "`",
                inline = true
            },
            {
                name = "📊 Mức độ",
                value = "`" .. level:upper() .. "`",
                inline = true
            },
            {
                name = "🕐 Thời gian",
                value = "<t:" .. math.floor(GetGameTimer() / 1000) .. ":R>",
                inline = true
            }
        }
	}

    ---@diagnostic disable-next-line: param-type-mismatch
	PerformHttpRequest(LOGS[action], function() end, "POST", json.encode({
		username = "LB Phone",
        avatar_url = "https://docs.lbscripts.com/images/icons/icon.png",
		embeds = { embed }
	}), { ["Content-Type"] = "application/json" })
end

function Log(action, source, level, title, metadata, image)
	if not Config.Logs?.Enabled or not Config.Logs.Actions[action] then
		return
	end

    Citizen.CreateThreadNow(function()
        if Config.Logs.Service == "ox_lib" then
            ---@diagnostic disable-next-line: undefined-global
            if not lib or GetResourceState("ox_lib") ~= "started" then
                infoprint("error", "Config.Logs.Service is set to 'ox_lib', but ox_lib is not started. To log using ox_lib, you need to install ox_lib from https://github.com/overextended/ox_lib/releases/latest.")
                return
            end

            ---@diagnostic disable-next-line: undefined-global
            lib.logger(source or -1, level, title)
        elseif Config.Logs.Service == "fivemanage" then
            if GetResourceState("fmsdk") ~= "started" then
                infoprint("error", "Config.Logs.Service is set to 'fivemanage', but fmsdk is not started. To log using Fivemanage, you need to install fmsdk from https://github.com/fivemanage/sdk/releases/latest.")
                return
            end

            if not metadata then
                metadata = {}
            end

            if type(metadata) == "string" then
                metadata = { message = metadata }
            end

            metadata.playerSource = source

            --exports.fmsdk:Log(Config.Logs.Dataset or "default", level, title, metadata)
        elseif Config.Logs.Service == "discord" then
            LogToDiscord(source, action, level, title, metadata, image)
        else
            infoprint("error", "Config.Logs.Service is set to an invalid value")
            return
        end
    end)
end

Wait(0)

if Config.Logs?.Enabled and Config.Logs?.Service == "ox_lib" then
	debugprint("Logs set to ox_lib, loading...")

	local oxInit = LoadResourceFile("ox_lib", "init.lua")

    if oxInit then
        load(oxInit)()
		debugprint("Loaded ox_lib")
	else
        Config.Logs.Enabled = false

        infoprint("error", "Failed to load ox_lib")
    end
end

if Config.Logs?.Enabled and Config.Logs?.Service == "discord" then
    ---@type string?
    local defaultWebhook = LOGS?.Default

    if type(defaultWebhook) ~= "string" or defaultWebhook == "https://discord.com/api/webhooks/" then
        defaultWebhook = nil
    end

    if not defaultWebhook then
        infoprint("warning", "No default webhook, or invalid webhook, set in lb-phone/server/apiKeys.lua")
    end

    for action, enabled in pairs(Config.Logs.Actions) do
        if not enabled then
            goto continue
        end

        local webhook = LOGS[action]

        if type(webhook) ~= "string" or webhook == "https://discord.com/api/webhooks/" then
            if defaultWebhook then
                debugprint("Using default webhook for ^5" .. action .. "^7")
            else
                infoprint("warning", "No webhook set for action " .. action .. " and no default webhook set in lb-phone/server/apiKeys.lua")
            end

            LOGS[action] = defaultWebhook
        end

        ::continue::
    end
end

AddEventHandler("playerDropped", function()
    avatars[source] = nil
end)
