

local registerNUICallback = RegisterNUICallback
local nuiEventName = "VoiceMemo"

local function handleVoiceMemoEvent(eventData, callback)
    local currentPhoneContext = currentPhone
    if not currentPhoneContext then
        return
    end

    local action = eventData.action
    local debugMessage = "VoiceMemo:"
    local actionString = action or ""
    if not action then
        actionString = ""
    end
    debugMessage = debugMessage .. actionString
    debugprint(debugMessage)

    if "upload" == action then
        TriggerCallback("voiceMemo:saveRecording", callback, eventData.data)
    elseif "get" == action then
        TriggerCallback("voiceMemo:getMemos", callback)
    elseif "delete" == action then
        TriggerCallback("voiceMemo:deleteMemo", callback, eventData.id)
    elseif "rename" == action then
        TriggerCallback("voiceMemo:renameMemo", callback, eventData.id, eventData.title)
    end
end

registerNUICallback(nuiEventName, handleVoiceMemoEvent)
