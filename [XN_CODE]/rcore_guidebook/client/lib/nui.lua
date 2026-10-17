NuiTypes = {
    OPEN = 'OPEN',
    OPEN_ADMIN = 'OPEN_ADMIN',
    OPEN_SPECIFIC_PAGE = 'OPEN_SPECIFIC_PAGE',
    CLOSE = 'CLOSE',
    INIT_DATA = 'INIT_DATA',
    REFRESH_PAGE = 'REFRESH_PAGE',
    UPDATED_PAGE = 'UPDATED_PAGE',
    UPDATED_CATEGORY = 'UPDATED_CATEGORY',
    POINTS = 'POINTS',
}

local opened = false

--- A simple wrapper around SendNUIMessage that you can use to
--- dispatch actions to the React frame.
---
---@param action string The action you wish to target
---@param data any The data you wish to send along with this action
function SendReactMessage(action, data)
    dbg.debug("Sending React message: [%s]", action)

    local function removeFunctions(data)
        if type(data) == 'table' then
            for k, v in pairs(data) do
                if type(v) == 'function' then
                    data[k] = nil
                elseif type(v) == 'table' then
                    removeFunctions(v)
                end
            end
        end
        return data
    end

    local data = removeFunctions(data)

    SendNUIMessage({
        action = action,
        data = data
    })
end

function isOpened()
    return opened
end

function updatedCategory(categoryKey)
    SendNuiMessage(json.encode({
        type = NuiTypes.UPDATED_CATEGORY,
        key = categoryKey,
    }))
end

function updatedPage(pageKey)
    SendNuiMessage(json.encode({
        type = NuiTypes.UPDATED_PAGE,
        key = pageKey,
    }))
end

function refreshPage(pageKey)
    SendReactMessage('refreshPage', pageKey)
end

function sendInitData(data, isDataFinishedLoading)
    local dataWithDefaults = table.merge(data, {
        pageScale = GetStoredPageScale(),
        isCopyDisabled = Config.DisablePageContentCopy,
        IFrameInsertIntoPage = Config.Experimental.IFrameInsertIntoPage,
        isJobPermissionEnabled = not Config.DisableDataPermissions,
        isDataFinishedLoading = isDataFinishedLoading or false,
        isJobPermissionDisabledForAdmin = Config.DisableDataPermissionsForAdmin,
        searchCooldown = Config.SearchCooldown or 3,
    })
    SendReactMessage('setInitData', dataWithDefaults)
end

function openNUI(openType, data)
    SendReactMessage('setVisible', true)
    SendReactMessage('openGuidebook', {
        type = openType,
        data = data,
    })
    SetNuiFocus(true, true)

    opened = true
end

function closeNUI()
    SendReactMessage('openGuidebook', {
        type = NuiTypes.CLOSE,
    })
    Citizen.CreateThread(function()
        Wait(150)
        SendReactMessage('setVisible', false)
        SetNuiFocus(false, false)
    end)

    opened = false
end

function openRootHelp(isAdmin, data)
    isAdmin = isAdmin or false

    if isAdmin then
        openNUI(NuiTypes.OPEN_ADMIN, data)
    else
        openNUI(NuiTypes.OPEN, data)
    end
end

function openSpecificHelp(pageData)
    if pageData.key then
        openNUI(NuiTypes.OPEN_SPECIFIC_PAGE, {
            key = pageData.key,
            isAdmin = pageData.isAdmin,
        })
    elseif pageData.customContent then
        openNUI(NuiTypes.OPEN_SPECIFIC_PAGE, {
            customContent = pageData.customContent,
            isAdmin = pageData.isAdmin,
        })
    end
end

function sendPoints(points)
    local feData = {}
    for _, point in pairs(points) do
        point.hide_date = nil
        point.show_date = nil
        table.insert(feData, point)
    end

    SendReactMessage('setPoints', feData)
end

function sendUITranslation()
    local locale = Config.Locale
    local translations = Locales[locale]?['ui']

    SendReactMessage('setTranslation', translations)
end

RegisterNUICallback('close', function(data, cb)
    local pageScale = data.pageScale
    if pageScale then
        StorePageScaleToKvp(pageScale)
        StoreAllToKVP()
    end
    closeNUI()
    cb('ok')
end)

RegisterNUICallback('requestPage', function(key, cb)
    if key == nil then
        dbg.critical('Cannot request page with nil key!')
        cb(false)
        return
    end

    requestPage(key, cb)
end)

RegisterNUICallback('saveEndpoint', function(data, cb)
    if data.type ~= DataTypes.PAGE and data.type ~= DataTypes.CATEGORY and data.type ~= DataTypes.POINT then
        dbg.critical('Client-side validation - unknown data type!')
        cb(false)
        return
    end

    TriggerServerEvent(triggerName('save'), data.type, data.data)
    setWaitingCallback(data.type, cb)
end)

RegisterNUICallback('deleteEndpoint', function(data, cb)
    if data.type ~= DataTypes.PAGE and data.type ~= DataTypes.CATEGORY and data.type ~= DataTypes.POINT then
        dbg.critical('Client-side validation - unknown data type!')
        cb(false)
        return
    end

    TriggerServerEvent(triggerName('delete'), data.type, data.key)
    setWaitingCallback(data.type, cb)
end)

RegisterNUICallback('teleport', function(data, cb)
    TriggerServerEvent(triggerName('teleport'), data.key)

    setWaitingCallback(DataTypes.TELEPORT, cb)
end)

RegisterNUICallback('navigate', function(data, cb)
    SetNewWaypoint(data.x, data.y)

    cb('ok')
end)

RegisterNUICallback('getCoords', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local x, y, z = table.unpack(coords)

    cb({
        x = x,
        y = y,
        z = z,
    })
end)

RegisterNUICallback('search', function(data, cb)
    setWaitingCallback(DataTypes.SEARCH, cb)
    searchContent(data.query, cb)
end)
