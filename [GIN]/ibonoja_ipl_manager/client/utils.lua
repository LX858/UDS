-- IBONOJA IPL Manager - Client Utilities
-- Handles IPL requesting/unloading, interior entity sets, propsets, and scroll options

local function UpdateYmap(ymapName, enabled)
    if enabled then
        if not IsIplActive(ymapName) then
            RequestIpl(ymapName)
        end
    else
        if IsIplActive(ymapName) then
            RemoveIpl(ymapName)
        end
    end
end

local function UpdateEntityprop(propset, propData, enabled, refresh)
    if not IsIplActive(propset.milo) then
        RequestIpl(propset.milo)
        lib.waitFor(function()
            if IsIplActive(propset.milo) then
                return true
            end
        end)
    end

    local interiorId = GetInteriorAtCoords(propset.coords.x, propset.coords.y, propset.coords.z)
    if not IsValidInterior(interiorId) then
        return nil
    end

    if enabled then
        if type(propData.id) == "number" then
            local propName = propset.pattern:format(propData.id)
            EnableInteriorProp(interiorId, propName)
            if propData.color then
                SetInteriorEntitySetColor(interiorId, propName, propData.color)
            end
        end
    elseif propData and propData.id and type(propData.id) == "number" then
        local propName = propset.pattern:format(propData.id)
        DisableInteriorProp(interiorId, propName)
    end

    if refresh then
        RefreshInterior(interiorId)
    end

    return interiorId
end

local function ResolveIdReference(targetConfigName, options)
    if not options then
        return nil
    end

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

local function ResolveColorReference(targetConfigName, options)
    if not options then
        return nil
    end

    for _, option in ipairs(options) do
        if option.configName == targetConfigName then
            if option.type == "scroll" and option.defaultIndex and option.values then
                local selected = option.values[option.defaultIndex]
                if selected and selected.value and selected.value.color then
                    return selected.value.color
                end
            end
            break
        end
    end

    return nil
end

local function UpdateScrollYmap(values, currentIndex, ymapConfig, idReference, options)
    local defaultCount = 0
    if ymapConfig.customYmaps then
        defaultCount = #values - #ymapConfig.customYmaps
    else
        defaultCount = #values
    end

    for index, item in ipairs(values) do
        local itemId = item.value and item.value.id
        local isCustom = index > defaultCount
        local customIndex = isCustom and (index - defaultCount) or nil

        if isCustom then
            if ymapConfig.customYmaps and ymapConfig.customYmaps[customIndex] then
                local customYmap = ymapConfig.customYmaps[customIndex]
                if index == currentIndex then
                    UpdateYmap(customYmap.ymap, true)
                else
                    UpdateYmap(customYmap.ymap, false)
                end
            end
        elseif itemId then
            if ymapConfig.pattern then
                if type(itemId) == "string" and idReference then
                    itemId = ResolveIdReference(idReference, options)
                end

                if itemId then
                    local ymapName = ymapConfig.pattern:format(itemId)
                    if index == currentIndex then
                        UpdateYmap(ymapName, true)
                    else
                        UpdateYmap(ymapName, false)
                    end
                end
            end
        end
    end
end

local function UpdateScrollEntityprop(values, currentIndex, propset, idReference, colorReference, options)
    local interiorId = nil
    local activeId = nil

    local selectedItem = values[currentIndex]
    if selectedItem and selectedItem.value then
        activeId = selectedItem.value.id
        if type(activeId) == "string" and idReference then
            activeId = ResolveIdReference(idReference, options)
        end
    end

    for index, item in ipairs(values) do
        local propId = item.value and item.value.id
        local propColor = item.value and item.value.color

        if type(propId) == "string" and idReference then
            propId = ResolveIdReference(idReference, options)
        end

        if colorReference and not propColor then
            propColor = ResolveColorReference(colorReference, options)
        end

        local propData = propId and { id = propId, color = propColor } or item.value

        if propData and propData.id and type(propData.id) == "number" then
            if index == currentIndex then
                interiorId = UpdateEntityprop(propset, propData, true, false)
            else
                if propData.id ~= activeId then
                    interiorId = UpdateEntityprop(propset, propData, false, false)
                end
            end
        end
    end

    if interiorId then
        RefreshInterior(interiorId)
    end
end

Utils = {
    updateYmap = UpdateYmap,
    updateEntityprop = UpdateEntityprop,
    updateScrollYmap = UpdateScrollYmap,
    updateScrollEntityprop = UpdateScrollEntityprop
}
