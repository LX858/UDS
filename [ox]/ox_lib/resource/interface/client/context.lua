--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local contextMenus = {}
local openContextMenu = nil

---@class ContextMenuItem
---@field title? string
---@field menu? string
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string
---@field image? string
---@field progress? number
---@field onSelect? fun(args: any)
---@field arrow? boolean
---@field description? string
---@field metadata? string | { [string]: any } | string[]
---@field disabled? boolean
---@field readOnly? boolean
---@field event? string
---@field serverEvent? string
---@field args? any

---@class ContextMenuArrayItem : ContextMenuItem
---@field title string

---@class ContextMenuProps
---@field id string
---@field title string
---@field subtitle? string Small line under the title
---@field menu? string
---@field onExit? fun()
---@field onBack? fun()
---@field canClose? boolean
---@field options { [string]: ContextMenuItem } | ContextMenuArrayItem[]

local function closeContext(_, cb, onExit)
    if cb then cb(1) end

    lib.resetNuiFocus()

    if not openContextMenu then return end

    if (cb or onExit) and contextMenus[openContextMenu].onExit then contextMenus[openContextMenu].onExit() end

    if not cb then SendNUIMessage({ action = 'hideContext' }) end

    openContextMenu = nil
end

-- A copy the UI can take: json.encode throws on functions (onSelect and friends),
-- which left the cursor stuck on screen because focus was already taken.
local function forUi(value, depth)
    if type(value) ~= 'table' then
        return type(value) ~= 'function' and value or nil
    end

    if depth > 8 then return nil end

    local copy = {}

    for k, v in pairs(value) do
        if type(v) ~= 'function' then copy[k] = forUi(v, depth + 1) end
    end

    return copy
end

---@param id string
function lib.showContext(id)
    if not contextMenus[id] then error('No context menu of such id found.') end

    local data = contextMenus[id]

    local ok, message = pcall(json.encode, {
        action = 'showContext',
        data = {
            title = data.title,
            subtitle = data.subtitle,
            canClose = data.canClose,
            menu = data.menu,
            options = forUi(data.options, 0)
        }
    }, { sort_keys = true })

    if not ok then
        return lib.print.error(('context menu "%s" could not be opened: %s'):format(id, message))
    end

    openContextMenu = id
    SendNuiMessage(message)
    -- Take the cursor only once the menu is on screen, so a failure can never leave it stuck.
    lib.setNuiFocus(false)
end

---@param context ContextMenuProps | ContextMenuProps[]
function lib.registerContext(context)
    for k, v in pairs(context) do
        if type(k) == 'number' then
            contextMenus[v.id] = v
        else
            contextMenus[context.id] = context
            break
        end
    end
end

---@return string?
function lib.getOpenContextMenu() return openContextMenu end

---@param onExit boolean?
function lib.hideContext(onExit) closeContext(nil, nil, onExit) end

RegisterNUICallback('openContext', function(data, cb)
    cb(1)

    local menu = openContextMenu and contextMenus[openContextMenu]
    if data.back and menu and menu.onBack then menu.onBack() end

    lib.showContext(data.id)
end)

RegisterNUICallback('clickContext', function(id, cb)
    cb(1)

    if math.type(tonumber(id)) == 'float' then
        id = math.tointeger(id)
    elseif tonumber(id) then
        id += 1
    end

    local menu = openContextMenu and contextMenus[openContextMenu]
    local data = menu and menu.options[id]
    if not data then return end

    if not data.event and not data.serverEvent and not data.onSelect then return end

    openContextMenu = nil

    SendNUIMessage({ action = 'hideContext' })
    lib.resetNuiFocus()

    if data.onSelect then data.onSelect(data.args) end
    if data.event then TriggerEvent(data.event, data.args) end
    if data.serverEvent then TriggerServerEvent(data.serverEvent, data.args) end
end)

RegisterNUICallback('closeContext', closeContext)



