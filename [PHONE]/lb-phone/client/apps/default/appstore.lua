

local registerNUICallback = RegisterNUICallback
local appStoreEvent = "AppStore"

local function handleAppStoreEvent(eventData, callback)
    local currentPhoneCheck = currentPhone
    if not currentPhoneCheck then
        return
    end

    local action = eventData.action
    local debugMessage = "AppStore:"
    local actionString = action or ""

    debugMessage = debugMessage .. actionString
    debugprint(debugMessage)

    if "buyApp" == action then
        local callbackEvent = TriggerCallback
        local eventName = "appstore:buyApp"
        local appData = callback
        local appPrice = eventData.price
        callbackEvent(eventName, appData, appPrice)
    end
end

registerNUICallback(appStoreEvent, handleAppStoreEvent)