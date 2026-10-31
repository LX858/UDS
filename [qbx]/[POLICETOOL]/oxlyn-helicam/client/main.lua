-- Cleaned-up version of the decompiled helicopter camera entry-point script.
-- Logic is unchanged; names and structure were reconstructed from the decompiler output.
-- Registers the commands and key bindings that open / close the camera.

Heli = Heli or {}

-- Prints only when Config.Debug is enabled.
local function debugPrint(...)
    if Config and Config.Debug then
        print("[oxlyn-helicam]", ...)
    end
end

---------------------------------------------------------------------------
-- Open / close toggle
---------------------------------------------------------------------------

RegisterCommand("oxlynhelicam_toggle", function()
    if Heli.Toggle then
        Heli.Toggle()
    end
end, false)

RegisterKeyMapping(
    "oxlynhelicam_toggle",
    "HeliCam — open / close camera",
    "keyboard",
    (Config.Controls and Config.Controls.toggleKey) or "F5")

---------------------------------------------------------------------------
-- Close only (Backspace by default)
---------------------------------------------------------------------------

RegisterCommand("oxlynhelicam_close", function()
    if not Heli.Close then return end

    if Heli.active then
        Heli.Close("key")
    else
        Heli.HardReset(true)
    end
end, false)

RegisterKeyMapping("oxlynhelicam_close", "HeliCam — close camera", "keyboard", "BACK")

---------------------------------------------------------------------------
-- Chat commands
---------------------------------------------------------------------------

-- /helicam: same as the toggle key.
RegisterCommand("helicam", function()
    if Heli.Toggle then
        Heli.Toggle()
    end
end, false)

-- /helicamfix: force-resets the camera if it ever gets stuck.
RegisterCommand("helicamfix", function()
    if Heli.HardReset then
        Heli.HardReset(false)
    end
end, false)

---------------------------------------------------------------------------
-- Config sanity check
---------------------------------------------------------------------------

-- Warn if the toggle key is also bound to an in-feed action.
CreateThread(function()
    Wait(2000)

    local controls = Config.Controls or {}
    local toggleKey = tostring(controls.toggleKey or ""):upper()

    for _, action in ipairs({ "mode", "spotlight", "mark", "point", "clearPts", "recenter" }) do
        if toggleKey ~= "" and tostring(controls[action] or ""):upper() == toggleKey then
            print(("^3[oxlyn-helicam] Config.Controls.toggleKey and Config.Controls.%s are both \"%s\". The in-feed action wins that key — close the camera with Backspace, or move one of the two in config.lua.^7"):format(
                action, toggleKey))
        end
    end
end)

debugPrint("helicam entry points ready")