

Oxlyn = Oxlyn or {}

local hudVisible = false

----------------------------------------------------------------------
-- Send HUD config (position, style, toggles, thresholds) to the NUI
----------------------------------------------------------------------
local function sendHudConfig()
    SendNUIMessage({
        action  = "hudConfig",
        visible = hudVisible,
        config  = {
            position  = Oxlyn.Eff("hudPosition") or "topright",
            scale     = Oxlyn.Eff("hudScale") or 1.0,
            opacity   = Oxlyn.Eff("hudOpacity") or 0.85,
            accent    = Oxlyn.Get("uiAccent") or "#FF2E43",
            blur      = Oxlyn.Get("uiBlur") ~= false,          -- default on
            animations = Oxlyn.Get("uiAnimations") ~= false,   -- default on

            showFrametime = Oxlyn.Eff("hudShowFrametime") == true,
            showLows      = Oxlyn.Eff("hudShowLows") == true,
            showPing      = Oxlyn.Eff("hudShowPing") == true,
            showGraph     = Oxlyn.Eff("hudShowGraph") == true,
            showEntities  = Oxlyn.Eff("hudShowEntities") == true,
        },
        thresholds = {
            excellent = Config.Metrics.fpsExcellent,
            good      = Config.Metrics.fpsGood,
            poor      = Config.Metrics.fpsPoor,
            pingGood  = Config.Metrics.pingGood,
            pingWarn  = Config.Metrics.pingWarn,
        },
    })
end

function Oxlyn.RefreshHud()
    hudVisible = Oxlyn.Get("hudEnabled") == true
    sendHudConfig()
end

-- Toggles the HUD, notifies the player, returns the new state
function Oxlyn.ToggleHud()
    local wasEnabled = Oxlyn.Get("hudEnabled") == true
    Oxlyn.Set("hudEnabled", not wasEnabled)

    Oxlyn.Notify(
        Oxlyn.L(wasEnabled and "notify_hud_off" or "notify_hud_on"),
        wasEnabled and "info" or "success"
    )
    return not wasEnabled
end

----------------------------------------------------------------------
-- HUD tick loop
----------------------------------------------------------------------
CreateThread(function()
    Wait(4000)
    Oxlyn.RefreshHud()

    while true do
        if hudVisible and not Oxlyn.State.open then
            local fps  = Oxlyn.FPS
            local real = Oxlyn.Metrics.real

            SendNUIMessage({
                action    = "hudTick",
                fps       = math.floor(fps.smooth + 0.5),
                frametime = math.floor(fps.frametime * 10 + 0.5) / 10,
                low1      = fps.low1,
                ping      = real.ping,
                entities  = real.totalEntities,
                peds      = real.peds,
                vehicles  = real.vehicles,
            })

            Wait(Config.Monitor.hudTickMs or 250)
        else
            Wait(600)
        end
    end
end)

----------------------------------------------------------------------
-- Hide the HUD while the main panel is open
----------------------------------------------------------------------
AddEventHandler("oxlyn_fps:panelStateChanged", function(isOpen)
    SendNUIMessage({
        action     = "hudSuppress",
        suppressed = isOpen and true or false,
    })
end)

