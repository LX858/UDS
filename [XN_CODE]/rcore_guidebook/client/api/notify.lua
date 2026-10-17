local gameName = GetGameName()

-- This is used to display most of notifications in whole script.
-- If needed, you can replace the content of this function for your own notification system
local function UINotify(title, message, isError)
    SendReactMessage('notify', {
        title = title,
        message = message,
        isError = isError
    })
end

-- This is to display the native GTA notification above map
function NativeNotify(txt)
    if gameName == GameType.REDM then
        TriggerEvent('redem_roleplay:NotifyLeft', 'Help', txt, "generic_textures", "tick", 8000)
    elseif gameName == GameType.FIVEM then
        AddTextEntry('rcore_notify', txt)
        BeginTextCommandThefeedPost('rcore_notify')
        EndTextCommandThefeedPostTicker(false)
    end
end

-- Help text is used to display texts like "Press E to open" when you are in a marker
function ShowHelpText(txt)
    if gameName == GameType.REDM then
        TriggerEvent('redem_roleplay:Tip', txt, 8000)
    elseif gameName == GameType.FIVEM then
        --Default GTA native
        AddTextEntry('showHelpNotify', txt)
        BeginTextCommandDisplayHelp('showHelpNotify')
        EndTextCommandDisplayHelp(0, false, true, -1)

        --Okok notify
        --exports['okokTextUI']:Open(txt, 'lightblue', 'left')
        --
        --SetTimeout(3000, function()
        --    exports['okokTextUI']:Close()
        --end)
    end
end

---- Ignore all below this line ----
RegisterNUICallback('notify', function(data, cb)
    if Config.UseFrameworkNotify and (Config.Framework == 1 or Config.Framework == 2) then
        ShowNotification(data.message, data.isError and "error" or nil)
    else
        UINotify(data.title, data.message, data.isError)
    end

    cb({})
end)

RegisterNetEvent(triggerName('notification'), function(text, type)
    NativeNotify(text)
end)


exports('open', function()
    TriggerServerEvent('rcore_guidebook:open')
end)