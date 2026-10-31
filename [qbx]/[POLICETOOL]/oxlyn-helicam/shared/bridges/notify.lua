Notify = Notify or {}

local isServer = IsDuplicityVersion()

local function isStarted(resource)
    return GetResourceState(resource) == "started"
end

local function detectMode()
    local mode = (Config and Config.Notify) or "auto"
    if mode ~= "auto" then return mode end

    if isStarted("ox_lib") then return "ox_lib" end
    if isStarted("okokNotify") then return "okok" end
    if isStarted("mythic_notify") then return "mythic" end

    local fw = Framework and Framework.Name
    if fw == "esx" then return "esx" end
    if fw == "qbcore" or fw == "qbox" then return "qb" end

    return "builtin"
end

if not isServer then

    local TITLE = "OXLYN UAV"

    local function oxType(ntype)
        if ntype == "error" or ntype == "success" or ntype == "warning" then
            return ntype
        end
        return "inform"
    end

    local function builtin(message, ntype)
        SendNUIMessage({
            action  = "notify",
            message = message,
            ntype   = ntype,
        })
    end

    function Notify.Send(message, ntype)
        ntype = ntype or "info"

        -- While flying the camera, show it on the OSD instead
        if Heli and Heli.active then
            SendNUIMessage({ action = "osd", text = message, ntype = ntype })
            return
        end

        local mode = detectMode()

        if mode == "ox_lib" then
            pcall(function()
                exports.ox_lib:notify({
                    title       = TITLE,
                    description = message,
                    type        = oxType(ntype),
                })
            end)

        elseif mode == "okok" then
            pcall(function()
                exports.okokNotify:Alert(TITLE, message, 5000, ntype)
            end)

        elseif mode == "mythic" then
            pcall(function()
                exports.mythic_notify:DoHudText(ntype, message)
            end)

        elseif mode == "esx" then
            if Framework and Framework.Core and Framework.Core.ShowNotification then
                pcall(function()
                    Framework.Core.ShowNotification(message)
                end)
            else
                builtin(message, ntype)
            end

        elseif mode == "qb" then
            if Framework and Framework.Name == "qbox" and isStarted("ox_lib") then
                pcall(function()
                    exports.ox_lib:notify({
                        description = message,
                        type        = oxType(ntype),
                    })
                end)
            else
                local qbType = ntype == "warning" and "primary" or ntype
                pcall(function()
                    TriggerEvent("QBCore:Notify", message, qbType)
                end)
            end

        else
            builtin(message, ntype)
        end
    end

    RegisterNetEvent("oxlyn-helicam:notify", function(message, ntype)
        Notify.Send(message, ntype)
    end)

else

    -- target: player server id (or -1 for everyone)
    function Notify.Server(target, message, ntype)
        TriggerClientEvent("oxlyn-helicam:notify", target, message, ntype or "info")
    end

end