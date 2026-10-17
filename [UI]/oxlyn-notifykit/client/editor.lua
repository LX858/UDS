

-- oxlyn-notifykit | client editor (cleaned from decompiled output)

local editorOpen = false

-- Targets the in-game installer is allowed to install/uninstall
local INSTALL_TARGETS = {
    esx    = true,
    qbcore = true,
    oxlib  = true,
    all    = true,
}

-- Builds the "setup" info table sent to the NUI
local function buildSetup()
    return {
        resource  = NK.resource,
        version   = GetResourceMetadata(NK.resource, "version", 0) or "?",
        framework = (Bridge and Bridge.framework) or "standalone",
        compat    = NK.Clean(NK.Compat or {}) or {},
        ace       = (Config.Admin and Config.Admin.ace) or "oxlyn.notifykit.admin",
        installer = NK.installerStatus,
    }
end

---------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------

function NK.OpenEditor()
    if editorOpen then return end

    if NK.CloseHistory then
        NK.CloseHistory()
    end

    editorOpen = true
    TriggerServerEvent("oxlyn-notifykit:requestAdmin")

    CreateThread(function()
        Wait(50) -- give the server time to answer the admin check

        if not editorOpen then return end

        NK.Focus("editor", true, false)
        NK.Send("openEditor", {
            admin               = (NK.isAdmin == true),
            look                = NK.look,
            serverLook          = NK.serverLook,
            defaults            = Utils.DefaultLook(),
            allowPlayerSettings = (Config.AllowPlayerSettings == true),
            setup               = buildSetup(),
        })
    end)
end

function NK.CloseEditor()
    if not editorOpen then return end

    editorOpen = false
    NK.Blur("editor")
    NK.Send("closeEditor", {})
end

function NK.IsEditorOpen()
    return editorOpen
end

exports("OpenEditor", NK.OpenEditor)
exports("CloseEditor", NK.CloseEditor)

---------------------------------------------------------------------
-- NUI callbacks
---------------------------------------------------------------------

RegisterNUICallback("editorClose", function(_, cb)
    cb(1)
    editorOpen = false
    NK.Blur("editor")
end)

RegisterNUICallback("editorSave", function(data, cb)
    cb(1)

    if type(data) ~= "table" or type(data.look) ~= "table" then return end

    local look = Utils.CleanLook(data.look)

    -- Personal (per-player) save
    if data.scope == "me" then
        if Config.AllowPlayerSettings then
            NK.SetPersonalLook(look)
            NK.Feedback(_U("ed_msg_saved_me"), "success")
        end
        return
    end

    -- Server-wide save (server validates admin)
    TriggerServerEvent("oxlyn-notifykit:saveLook", look)
end)

RegisterNUICallback("editorReset", function(data, cb)
    cb(1)

    if type(data) == "table" and data.scope == "me" then
        if Config.AllowPlayerSettings then
            NK.SetPersonalLook(nil)
        end
        return
    end

    TriggerServerEvent("oxlyn-notifykit:resetLook")
end)

RegisterNUICallback("editorBroadcast", function(data, cb)
    cb(1)

    if type(data) ~= "table" or type(data.data) ~= "table" then return end

    local notification = NK.Normalize(data.data)
    if not notification then return end

    TriggerServerEvent("oxlyn-notifykit:broadcast", notification, data.announce == true)
end)

RegisterNUICallback("editorInstaller", function(data, cb)
    cb(1)

    if type(data) ~= "table" then return end

    local action, target = data.action, data.target

    if action ~= "install" and action ~= "uninstall" then return end
    if type(target) ~= "string" or not INSTALL_TARGETS[target] then return end

    TriggerServerEvent("oxlyn-notifykit:installer", action, target)
end)

RegisterNUICallback("editorRequestSetup", function(_, cb)
    cb(1)
    TriggerServerEvent("oxlyn-notifykit:installerStatus")
end)

---------------------------------------------------------------------
-- Net events / handlers
---------------------------------------------------------------------

RegisterNetEvent("oxlyn-notifykit:installerStatus", function(status)
    -- Only accept a table, otherwise clear it
    NK.installerStatus = (type(status) == "table") and status or nil

    NK.Send("editorSetup", {
        installer = NK.installerStatus,
        compat    = NK.Clean(NK.Compat or {}) or {},
    })
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= NK.resource or not editorOpen then return end

    editorOpen = false
    NK.Blur("editor")
end)

