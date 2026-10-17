-- IBONOJA IPL Manager - Client Setup Module
-- Discovers active map resources, sets up ox_lib menus, and registers statebag handlers

local mapsConfig = Maps

local function BuildDefaultConfigs()
    lib.waitFor(function()
        if GlobalState["ibonoja_ipl_manager:loaded"] then
            return true
        end
    end)

    lib.registerMenu({
        id = "new_ipl_manager_main_menu",
        title = "IPL Manager",
        options = {
            {
                label = "Loading...",
                description = "Please wait while loading maps..."
            }
        }
    }, function(selected, scrollIndex, args)
        lib.showMenu(args.mapMenuId)
    end)

    local availableMaps = {}

    for _, mapConfig in ipairs(mapsConfig) do
        local resourceNames = type(mapConfig.ResourceMapName) == "table"
            and mapConfig.ResourceMapName
            or { mapConfig.ResourceMapName }

        local foundResource = nil
        for _, resName in ipairs(resourceNames) do
            if GetResourceState(resName) ~= "missing" then
                foundResource = resName
                break
            end
        end

        if foundResource then
            lib.waitFor(function()
                if GetResourceState(foundResource) == "started" then
                    return true
                end
            end)
            availableMaps[mapConfig.ConfigName] = mapConfig
        end
    end

    for configName, mapConfig in pairs(availableMaps) do
        local editable = EditableConfig[configName]
        if editable then
            for _, option in ipairs(mapConfig.Menu.options) do
                if option.ymap then
                    local customYmaps = editable[option.configName .. "Ymaps"]
                    if customYmaps and type(customYmaps) == "table" and #customYmaps > 0 then
                        local isValid = true
                        for _, ymapEntry in ipairs(customYmaps) do
                            if type(ymapEntry) ~= "table" or not ymapEntry.label or not ymapEntry.ymap then
                                isValid = false
                                break
                            end
                        end

                        if isValid then
                            option.ymap.customYmaps = customYmaps
                            if not option.values then
                                option.values = { { label = "Off" } }
                            end

                            local maxValueId = 0
                            for _, val in ipairs(option.values) do
                                if val.value and val.value.id and type(val.value.id) == "number" then
                                    maxValueId = math.max(maxValueId, val.value.id)
                                end
                            end

                            for _, ymapEntry in ipairs(customYmaps) do
                                maxValueId = maxValueId + 1
                                table.insert(option.values, {
                                    label = ymapEntry.label,
                                    value = { id = maxValueId },
                                    description = string.format("Custom Ymap: %s", ymapEntry.ymap)
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    local mainMenuOptions = {}
    local mapCount = 0

    for configName, mapConfig in pairs(availableMaps) do
        for optionIndex, option in ipairs(mapConfig.Menu.options) do
            option.statebag = string.format("%s:%s", mapConfig.Menu.id, option.statebag)

            if option.type == "checkbox" then
                SetupCheckbox(
                    option,
                    option.statebag,
                    configName,
                    mapConfig.Menu.id,
                    optionIndex,
                    mapConfig.Menu.options,
                    Utils
                )
            elseif option.type == "scroll" then
                SetupScroll(
                    option,
                    option.statebag,
                    configName,
                    mapConfig.Menu.id,
                    optionIndex,
                    mapConfig.Menu.options,
                    Utils
                )
            end
        end

        lib.registerMenu({
            id = mapConfig.Menu.id,
            title = mapConfig.Menu.title,
            options = mapConfig.Menu.options,
            onClose = function()
                lib.showMenu("new_ipl_manager_main_menu")
            end,
            onSideScroll = function(selected, scrollIndex)
                local option = availableMaps[configName].Menu.options[selected]
                TriggerServerEvent("ibonoja_ipl_manager:set", option.statebag, scrollIndex)
            end,
            onCheck = function(selected, checked)
                local option = availableMaps[configName].Menu.options[selected]
                TriggerServerEvent("ibonoja_ipl_manager:set", option.statebag, checked and 1 or 0)
            end
        })

        table.insert(mainMenuOptions, {
            label = mapConfig.Menu.title,
            description = "Manage IPLs for " .. mapConfig.Menu.title,
            args = {
                mapMenuId = mapConfig.Menu.id
            }
        })

        mapCount = mapCount + 1
    end

    lib.setMenuOptions("new_ipl_manager_main_menu", mainMenuOptions)

    return availableMaps, mapCount
end

Setup = {
    defaultConfigs = BuildDefaultConfigs
}
