local displayVersion = 0

local function setDisplay(display)
    SendNUIMessage({
        type = "ui",
        display = display
    })
end

RegisterNetEvent("jumpscare:toggleNUI")
AddEventHandler("jumpscare:toggleNUI", function(display)
    displayVersion = displayVersion + 1
    setDisplay(display)
end)

RegisterNetEvent("jumpscare:show")
AddEventHandler("jumpscare:show", function(timer)
    local duration = tonumber(timer) or 3000
    if duration ~= duration or duration <= 0 or duration > 2147483647 then return end

    displayVersion = displayVersion + 1
    local version = displayVersion
    setDisplay(true)

    SetTimeout(math.floor(duration), function()
        if version == displayVersion then
            setDisplay(false)
        end
    end)
end)
