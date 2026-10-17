---@class BabloWrapperMenuElement
---@field icon? string # https://fontawesome.com/search?ic=free
---@field label string
---@field description? string # Description text for supported menu systems
---@field progress? number # Progress value (0-100) for supported menu systems
---@field options? string[]
---@field action? fun(self: BabloWrapperMenuElement, selectedItem?: number)
---@field canInteract? fun(): boolean
---@field disabled? boolean # If true, the option is shown but not selectable
---@field [string] any

Menus = Menus or {}

local resourceName = GetCurrentResourceName()
local menuName = "bablo_wrapper:" .. resourceName

---@param title string
---@param elements BabloWrapperMenuElement[]
---@param onClose? fun()
function Menus:openMenu(title, elements, onClose)
    ---@type BabloWrapperMenuElement[]
    local cleanedElements = {}

    for i = 1, #elements do
        local element = elements[i]

        if not element.canInteract or element.canInteract() then
            cleanedElements[#cleanedElements + 1] = element
        end
    end

    if Config.MenuSystem == "ox_lib_menu" then
        self:openOXLibMenu(title, cleanedElements, onClose)
    elseif Config.MenuSystem == "ox_lib_context" then
        self:openOXLibContextMenu(title, cleanedElements, onClose)
    elseif Config.MenuSystem == "qb-menu" then
        self:openQBMenu(title, cleanedElements, onClose)
    elseif Config.MenuSystem == "esx_menu_default" then
        self:openESXDefaultMenu(title, cleanedElements, onClose)
    elseif Config.MenuSystem == "esx_context" then
        self:openESXContextMenu(title, cleanedElements, onClose)
    else
        error("Unknown menu system: " .. tostring(Config.MenuSystem))
    end
end

function Menus:closeMenu()
    if Config.MenuSystem == "ox_lib_menu" then
        lib.hideMenu()
    elseif Config.MenuSystem == "ox_lib_context" then
        lib.hideContext()
    elseif Config.MenuSystem == "qb-menu" then
        exports["qb-menu"]:closeMenu()
    elseif Config.MenuSystem == "esx_menu_default" then
        ESX.UI.Menu.CloseAll()
    elseif Config.MenuSystem == "esx_context" then
        ESX.CloseContext()
    end
end

---@param menuTitle string
---@param inputTitle string
---@param inputPlaceholder string
---@param icon string
function Menus:openInput(menuTitle, inputTitle, inputPlaceholder, icon)
    if Config.MenuSystem == "ox_lib_menu" or Config.MenuSystem == "ox_lib_context" then
        local input = lib.inputDialog(menuTitle, {
            {
                type = "input",
                label = inputTitle,
                icon = icon,
                default = inputPlaceholder,
                required = true,
            },
        })

        return input and input[1]
    elseif Config.MenuSystem == "qb-menu" then
        local dialog = exports["qb-input"]:ShowInput({
            header = menuTitle,
            submitText = "Submit",
            inputs = {
                {
                    type = "text",
                    isRequired = true,
                    name = "input",
                    text = inputTitle,
                }
            }
        })

        return dialog and dialog.input
    elseif Config.MenuSystem == "esx_menu_default" then
        return self:openESXDialogInput(menuTitle, inputTitle, inputPlaceholder)
    elseif Config.MenuSystem == "esx_context" then
        return self:openESXContextInput(menuTitle, inputTitle, inputPlaceholder, icon)
    end
end

---@param title string
---@param elements BabloWrapperMenuElement[]
---@param onClose? fun()
function Menus:openOXLibMenu(title, elements, onClose)
    local menuOptions = {}

    for i = 1, #elements do
        local option = elements[i]

        local menuOption = {
            icon = option.icon,
            label = option.label,
            values = option.options,
            disabled = option.disabled,
            args = {
                action = function(scrollIndex)
                    if not option.action then
                        return
                    end

                    option:action(scrollIndex)

                    if onClose then
                        onClose()
                    end
                end,
            },
        }

        -- Add description if supported (ox_lib menu supports description)
        if option.description then
            menuOption.description = option.description
        end

        -- ox_lib menu doesn't support progress bars in the same way

        menuOptions[#menuOptions + 1] = menuOption
    end

    exports.ox_lib:registerMenu({
        id = menuName,
        title = title,
        options = menuOptions,
        onClose = function()
            if onClose then
                onClose()
            end
        end,
    }, function(selected, scrollIndex, args)
        args.action(scrollIndex)
    end)

    exports.ox_lib:showMenu(menuName)
end

---@param title string
---@param elements BabloWrapperMenuElement[]
---@param onClose? fun()
function Menus:openOXLibContextMenu(title, elements, onClose)
    local menuOptions = {}

    for i = 1, #elements do
        local option = elements[i]

        local contextOption = {
            icon = option.icon,
            title = option.label,
            disabled = option.disabled,
            onSelect = function()
                if not option.options then
                    if not option.action then
                        return
                    end

                    option:action()

                    if onClose then
                        onClose()
                    end

                    return
                end

                local nestedOptions = {}

                for j = 1, #option.options do
                    local nestedOption = option.options[j]

                    nestedOptions[#nestedOptions + 1] = {
                        label = nestedOption,
                        action = function()
                            option:action(j)
                        end,
                    }
                end

                self:openMenu(option.label, nestedOptions, function()
                    SetTimeout(50, function()
                        self:openMenu(title, elements, onClose)
                    end)
                end)
            end,
        }

        -- Add description if supported
        if option.description then
            contextOption.description = option.description
        end

        -- Add progress if supported
        if option.progress then
            contextOption.progress = option.progress
            contextOption.colorScheme = "green"
        end

        menuOptions[#menuOptions + 1] = contextOption
    end

    exports.ox_lib:registerContext({
        id = menuName,
        title = title,
        options = menuOptions,
        onExit = function()
            if onClose then
                onClose()
            end
        end,
    })

    exports.ox_lib:showContext(menuName)
end

function OpenMenu(title, elements, onClose)
    return Menus:openMenu(title, elements, onClose)
end

function CloseMenu()
    return Menus:closeMenu()
end

function OpenInput(menuTitle, inputTitle, inputPlaceholder, icon)
    return Menus:openInput(menuTitle, inputTitle, inputPlaceholder, icon)
end