local version = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
if not version then
    version = "0.0.0"
end

local isCustomUI = GetResourceMetadata(GetCurrentResourceName(), "ui_page", 0) ~= "ui/dist/index.html"

local maxEvents = 25
local videoExtensions = {"webm", "mp4", "mov"}
local events = {}
local eventCount = 0
local serverId = nil

if not version:match("^%d+%.%d+%.%d+$") then
    version = "0.0.0"
end

local function sendStatistics(force)
    if not force then
        if eventCount < maxEvents then
            return
        end
    end
    
    if eventCount == 0 then
        return
    end
    
    if not serverId then
        local baseUrl = GetConvar("web_baseUrl", "")
        if baseUrl == "" then
            return
        end
        
        local urlLength = #baseUrl
        local reversedUrl = baseUrl:reverse()
        local dashIndex = reversedUrl:find("-")
        if not dashIndex then
            dashIndex = #baseUrl + 1
        end
        local startIndex = urlLength - dashIndex + 1
        serverId = string.sub(baseUrl, startIndex + 1, #baseUrl - #".users.cfx.re")
    end
    
    local payload = json.encode({
        serverId = serverId,
        version = version,
        events = events
    })
    
    eventCount = 0
    events = {}
    
    PerformHttpRequest("https://track.lbscripts.com/", function()
    end, "POST", payload, {
        ["Content-Type"] = "application/json"
    })
end

function TrackSimpleEvent(eventName)
    if isCustomUI then
        return
    end
    
    eventCount = eventCount + 1
    events[eventCount] = {
        event = eventName
    }
    sendStatistics()
end

function TrackSocialMediaPost(appName, fileList)
    if isCustomUI then
        return
    end
    
    local photoCount = 0
    local videoCount = 0
    
    if fileList then
        for i = 1, #fileList do
            local fileName = fileList[i]
            local extension = fileName:match("%.([^.]+)$")
            if not extension then
                extension = "webp"
            end
            
            if table.contains(videoExtensions, extension) then
                videoCount = videoCount + 1
            else
                photoCount = photoCount + 1
            end
        end
    end
    
    eventCount = eventCount + 1
    events[eventCount] = {
        event = "social_media_post",
        app = appName,
        amountVideos = videoCount,
        amountPhotos = photoCount
    }
    sendStatistics()
end

AddEventHandler("txAdmin:events:scheduledRestart", function(data)
    if data.secondsRemaining == 60 then
        sendStatistics(true)
    end
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    sendStatistics(true)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        sendStatistics(true)
    end
end)
