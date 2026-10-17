local settings = require 'client.settings'

local state = {}

local isActive = false
local centerCursor = GetConvarInt('ox_target:centerCursor', 1) == 1
local ownsFocus = false

---The eye is drawn by the NUI, so it needs to know where the cursor starts:
---no mousemove event arrives before the player actually moves the mouse.
local function getCursorFraction()
    if centerCursor then return 0.5, 0.5 end

    local x, y = GetNuiCursorPosition()
    local width, height = GetActiveScreenResolution()

    if not x or not width or width == 0 or height == 0 then return 0.5, 0.5 end

    return math.max(0, math.min(1, x / width)), math.max(0, math.min(1, y / height))
end

---@return boolean
function state.isActive()
    return isActive
end

---@param value boolean
function state.setActive(value)
    isActive = value

    if value then
        local config = settings.get()
        local cursorX, cursorY = getCursorFraction()

        SendNuiMessage(json.encode({
            event = 'visible',
            state = true,
            vignette = config.vignette,
            tilt = settings.isTiltEnabled(),
            handCursor = config.handCursor,
            cursor = { x = cursorX, y = cursorY },
        }))
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        ownsFocus = true
    else
        if ownsFocus then
            SetNuiFocus(false, false)
            ownsFocus = false
        end
    end
end

local nuiFocus = false

---@return boolean
function state.isNuiFocused()
    return nuiFocus
end

---@param value boolean
function state.setNuiFocus(value, cursor)
    nuiFocus = value
    if value then
        SetNuiFocus(value, cursor or false)
        SetNuiFocusKeepInput(value)
        ownsFocus = true
    elseif ownsFocus then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        ownsFocus = false
    end
end

local isDisabled = false

---@return boolean
function state.isDisabled()
    return isDisabled
end

---@param value boolean
function state.setDisabled(value)
    isDisabled = value
end

return state
