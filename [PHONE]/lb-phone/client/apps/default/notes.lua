

local registerNUICallback = RegisterNUICallback
local nuiName = "Notes"

local function handleNoteAction(eventData, callback)
    local currentDevice = currentPhone

    if not currentDevice then
        return
    end

    local action = eventData.action
    local debugMessage = "Notes:" .. (action or "")
    debugprint(debugMessage)

    local data = eventData.data
    if data then
        eventData = data
    end

    if action == "create" then
        local createNoteCallback = TriggerCallback
        local eventName = "notes:createNote"
        local noteTitle = eventData.title
        local noteContent = eventData.content

        createNoteCallback(eventName, callback, noteTitle, noteContent)
    elseif action == "save" then
        local saveNoteCallback = TriggerCallback
        local eventName = "notes:saveNote"
        local noteId = eventData.id
        local noteTitle = eventData.title
        local noteContent = eventData.content

        saveNoteCallback(eventName, callback, noteId, noteTitle, noteContent)
    elseif action == "fetch" then
        local getNotesCallback = TriggerCallback
        local eventName = "notes:getNotes"

        getNotesCallback(eventName, callback)
    elseif action == "remove" then
        local removeNoteCallback = TriggerCallback
        local eventName = "notes:removeNote"
        local noteId = eventData.id

        removeNoteCallback(eventName, callback, noteId)
    end
end

registerNUICallback(nuiName, handleNoteAction)