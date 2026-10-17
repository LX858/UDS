-- Player Connecting Event
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local handover = deferrals.handover
    handover({
        config = Config
    })
end)

-- Check if update checks are enabled
if not Config.CheckForUpdates then
    return
end

local resourceName = "wasabi_loadingscreen"
local expectedName = "wasabi_loadingscreen"
local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version")
local apiURL = "https://api.github.com/repos/wasabi-versions/" .. resourceName .. "/releases/latest"

-- Fetch latest version from GitHub
local function fetchLatestVersion()
    local latestVersion = false

    PerformHttpRequest(apiURL, function(status, response)
        if status == 200 then
            local data = json.decode(response)
            latestVersion = data.tag_name
        end
    end, "GET")

    repeat
        Wait(50)
    until latestVersion

    return latestVersion
end

-- Compare versions and warn if outdated
local function checkVersion(_, _, _)
    local latest = fetchLatestVersion()

    CreateThread(function()
        if currentVersion ~= latest then
            Wait(4500)
            print("^0[^3WARNING^0] " .. resourceName .. " is ^1NOT ^0up to date!")
            print("^0[^3WARNING^0] Your Version: ^1" .. currentVersion .. "^0")
            print("^0[^3WARNING^0] Latest Version: ^2" .. latest .. "^0")
            print("^0[^3WARNING^0] ^1Get the latest version from keymaster!^0")
        end
    end)
end

-- Run version checker thread
CreateThread(function()
    local actualResourceName = GetCurrentResourceName()

    if actualResourceName ~= expectedName then
        expectedName = expectedName .. "(" .. actualResourceName .. ")"
        Wait(4500)
        print("^0[^3WARNING^0] Rename the folder to \"" .. resourceName ..
              "\", otherwise this resource needs Config.CheckForUpdates set to false!")
    end

    while true do
        PerformHttpRequest(apiURL, checkVersion, "GET")
        Wait(3600000) -- every hour
    end
end)
