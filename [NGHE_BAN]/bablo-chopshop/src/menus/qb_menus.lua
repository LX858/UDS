if Config.Framework ~= "qbcore" or Config.MenuSystem ~= "qb-menu" then
    return
end

local resourceName = GetCurrentResourceName()
local menuName = "bablo_wrapper:" .. resourceName

---@param title string
---@param elements BabloWrapperMenuElement[]
---@param onClose? fun()
function Menus:openQBMenu(title, elements, onClose)
    local formattedElements = {
        {
            header = title,
            isMenuHeader = true,
            icon = "fa-solid fa-info-circle",
        }
    }

    ---@param element BabloWrapperMenuElement
    local function OnElementSelect(element)
        if not element.options then
            element:action()

            if onClose then
                onClose()
            end

            return
        end

        local nestedOptions = {}

        for j = 1, #element.options do
            local nestedOption = element.options[j]

            nestedOptions[#nestedOptions + 1] = {
                label = nestedOption,
                action = function()
                    element:action(j)
                end,
            }
        end

        self:openQBMenu(element.label, nestedOptions, function()
            self:openQBMenu(title, elements, onClose)
        end)
    end

    for i = 1, #elements do
        local element = elements[i]

        local menuElement = {
            icon = element.icon,
            header = element.label,
            action = function()
                OnElementSelect(element)
            end
        }

        -- Add description if supported (QB-Menu supports 'txt' field)
        if element.description then
            menuElement.txt = element.description
        end

        -- QB-Menu doesn't support progress bars, so we skip that

        formattedElements[i + 1] = menuElement
    end

    exports["qb-menu"]:openMenu(formattedElements)
end