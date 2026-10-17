--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class TextUIOptions
---@field position? 'right-center' | 'left-center' | 'top-center' | 'bottom-center';
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string;
---@field style? string | table;
---@field alignIcon? 'top' | 'center';
---@field world? boolean false keeps the text box when interact.lua replaces TextUI prompts

local isOpen = false
local currentText
-- Scripts that call showTextUI every frame (ESX.ShowHelpNotification loops) never call hide,
-- because GTA's own help text used to vanish by itself. Such prompts hide when the calls stop.
local lastCall, repeating = 0, false

---@param text string
---@param options? TextUIOptions
function lib.showTextUI(text, options)
    local now = GetGameTimer()

    if currentText == text then
        if now - lastCall < 250 then repeating = true end
        lastCall = now
        return
    end

    lastCall, repeating = now, false

    if not options then options = {} end

    options.text = text
    currentText = text

    -- interact.lua > replaceTextUI: "[E] ..." prompts are drawn in the world instead.
    -- A script can keep the text box for one prompt with options.world = false.
    if options.world ~= false and showWorldPrompt and showWorldPrompt(text) then
        SendNUIMessage({ action = 'textUiHide' })
        isOpen = true
        return
    end

    if hideWorldPrompt then hideWorldPrompt() end

    SendNUIMessage({
        action = 'textUi',
        data = options
    })

    isOpen = true
end

function lib.hideTextUI()
    repeating = false
    if hideWorldPrompt then hideWorldPrompt() end

    SendNUIMessage({
        action = 'textUiHide'
    })

    isOpen = false
    currentText = nil
end

---@return boolean, string | nil
function lib.isTextUIOpen()
    return isOpen, currentText
end

CreateThread(function()
    while true do
        if isOpen and repeating and GetGameTimer() - lastCall > 400 then
            lib.hideTextUI()
        end

        Wait(100)
    end
end)
