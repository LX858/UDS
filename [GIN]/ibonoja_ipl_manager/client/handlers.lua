-- IBONOJA IPL Manager - Client Event Handlers & State Bag Listeners

function ResolveIdReference(targetConfigName, options)
    for _, option in ipairs(options) do
        if option.configName == targetConfigName then
            if option.type ~= "scroll" then
                break
            end

            if not option.defaultIndex or not option.values then
                break
            end

            local selected = option.values[option.defaultIndex]
            if not selected or not selected.value or not selected.value.id then
                break
            end

            if type(selected.value.id) == "number" then
                return selected.value.id
            end

            break
        end
    end

    return nil
end

function ApplyState(option, value, utils, options)
    if option.type == "checkbox" then
        local isEnabled = (value == 1 or value == true)

        if option.ymap then
            utils.updateYmap(option.ymap.name, isEnabled)
        end

        if option.propset then
            local propData = { id = isEnabled and 1 or 0 }
            utils.updateEntityprop(option.propset, propData, isEnabled, true)
        end
    elseif option.type == "scroll" then
        if option.ymap and option.values then
            utils.updateScrollYmap(option.values, value, option.ymap, option.idReference, options)
        end

        if option.propset and option.values then
            utils.updateScrollEntityprop(option.values, value, option.propset, option.idReference, option.colorReference, options)
        end
    end
end

function CreateStateBagHandler(option, configName, menuId, optionIndex, options, utils)
    return function(bagName, key, value, _reserved, replicated)
        if option.type == "checkbox" then
            option.checked = (value == 1 or value == true) and 1 or 0
        elseif option.type == "scroll" then
            option.defaultIndex = value
        end

        lib.setMenuOptions(menuId, options[optionIndex], optionIndex)
        ApplyState(option, value, utils, options)
    end
end

function InitializeOptionState(option, utils, options)
    if option.type == "checkbox" then
        ApplyState(option, option.checked, utils, options)
    elseif option.type == "scroll" then
        ApplyState(option, option.defaultIndex, utils, options)
    end
end

function SetupCheckbox(option, statebagName, configName, menuId, optionIndex, options, utils)
    option.checked = GlobalState[statebagName]
    option.description = "0: Off, 1: On"

    AddStateBagChangeHandler(
        statebagName,
        "",
        CreateStateBagHandler(option, configName, menuId, optionIndex, options, utils)
    )

    InitializeOptionState(option, utils, options)
end

function SetupScroll(option, statebagName, configName, menuId, optionIndex, options, utils)
    option.defaultIndex = GlobalState[statebagName]

    if option.values then
        for _, val in ipairs(option.values) do
            local valId = (val.value and val.value.id) or 0
            local isCustom = false

            if option.ymap and option.ymap.customYmaps then
                for _, customYmap in ipairs(option.ymap.customYmaps) do
                    if val.label == customYmap.label then
                        isCustom = true
                        val.description = string.format("Custom Ymap: %s - Index in config: %d", customYmap.ymap, valId)
                        break
                    end
                end
            end

            if not isCustom then
                if type(valId) == "string" then
                    val.description = string.format("References: %s (color: %s)", val.value.id, tostring(val.value.color))
                else
                    val.description = string.format("Index in config: %d", valId)
                end
            end
        end
    end

    AddStateBagChangeHandler(
        statebagName,
        "",
        CreateStateBagHandler(option, configName, menuId, optionIndex, options, utils)
    )

    InitializeOptionState(option, utils, options)
end
