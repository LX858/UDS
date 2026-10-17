-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Check if update checking is enabled in config
if not Config.CheckForUpdates then
    return
end

-- Resource information
local EXPECTED_RESOURCE_NAME = "wasabi_bridge"
local DISPLAY_NAME = "wasabi_bridge"

-- Get current version from resource metadata
local CURRENT_VERSION = GetResourceMetadata(GetCurrentResourceName(), "version")

-- GitHub API URL for checking latest release
local GITHUB_API_URL = "https://api.github.com/repos/wasabi-versions/" .. EXPECTED_RESOURCE_NAME .. "/releases/latest"

-- Fetch the latest version from GitHub
-- @return string|boolean - Latest version tag or false if request fails
local function fetchLatestVersion()
    local latestVersion = false
    
    PerformHttpRequest(GITHUB_API_URL, function(statusCode, responseBody, headers)
        if statusCode == 200 then
            local data = json.decode(responseBody)
            latestVersion = data.tag_name
        end
    end, "GET")
    
    -- Wait for HTTP request to complete
    repeat
        Wait(50)
    until latestVersion
    
    return latestVersion
end

-- Compare versions and display warning if outdated
-- @param statusCode number - HTTP status code (unused)
-- @param responseBody string - Response body (unused)
-- @param headers table - Response headers (unused)
local function checkVersionAndNotify(statusCode, responseBody, headers)
    local latestVersion = fetchLatestVersion()
    
    CreateThread(function()
        -- Compare current version with latest version
        if CURRENT_VERSION ~= latestVersion then
            Wait(4500)  -- Wait before displaying warnings
            
            print("^0[^3WARNING^0] " .. DISPLAY_NAME .. " is ^1NOT ^0up to date!")
            print("^0[^3WARNING^0] Your Version: ^1" .. CURRENT_VERSION .. "^0")
            print("^0[^3WARNING^0] Latest Version: ^2" .. latestVersion .. "^0")
            print("^0[^3WARNING^0] ^1Get the latest version from keymaster!^0")
        end
    end)
end

-- Main verification thread
CreateThread(function()
    local currentResourceName = GetCurrentResourceName()
    
    -- Check if resource folder is named correctly
    if currentResourceName ~= EXPECTED_RESOURCE_NAME then
        -- Update display name to show actual folder name
        DISPLAY_NAME = EXPECTED_RESOURCE_NAME .. " (" .. GetCurrentResourceName() .. ")"
        
        Wait(4500)
        print("^0[^3WARNING^0] Rename the folder to \"" .. EXPECTED_RESOURCE_NAME .. "\", otherwise this resource could experience problems!")
    end
    
    -- Periodic version checking (every hour)
    while true do
        PerformHttpRequest(GITHUB_API_URL, checkVersionAndNotify, "GET")
        
        -- Wait 1 hour (3,600,000 milliseconds) before next check
        Wait(3600000)
    end
end)