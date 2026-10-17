local dataRequestCallbacks = {}
local pageCache = {}
local points = {}

function requestPage(pageKey, pageLoadedCallback)
    if pageCache[pageKey] ~= nil then
        return pageCache[pageKey]
    end

    local cbId = #dataRequestCallbacks + 1
    dataRequestCallbacks[cbId] = pageLoadedCallback

    TriggerServerEvent(triggerName('requestData'), cbId, DataTypes.PAGE, pageKey)

    dbg.debug('Callback %s requested', cbId)
end

function searchContent(query, cb)
    local cbId = #dataRequestCallbacks + 1
    dataRequestCallbacks[cbId] = cb

    TriggerServerEvent(triggerName('searchPageContents'), query, cbId)
    dbg.debug('Callback %s requested', cbId)
end

RegisterNetEvent(triggerName('receiveSearchResults'), function(cbId, results)
    local dataCallback = dataRequestCallbacks[cbId]
    if dataCallback == nil then
        dbg.critical('Callback cannot be found (#%s)!', cbId)
        return
    end

    local ok, err = pcall(dataCallback, results)
    if not ok then
        dbg.critical("Called callback %s with error %s", cbId, err)
        return
    end

    dbg.debug('Callback %s successfully called!', cbId)
end)

RegisterNetEvent(triggerName('receiveData'), function(cbId, data, requestData)
    local dataCallback = dataRequestCallbacks[cbId]
    if dataCallback == nil then
        dbg.critical('Callback cannot be found (#%s)!', cbId)
        return
    end

    local ok, err = pcall(dataCallback, data)
    if not ok then
        dbg.critical("Called callback %s with error %s", cbId, err)
        return
    end

    if requestData.type == DataTypes.PAGE then
        pageCache[requestData.key] = data
    end

    dbg.debug('Callback %s successfully called!', cbId)
end)

RegisterNetEvent(triggerName('receiveInitDataLazy'), function(initData)
    setInitData(initData, true)

    dbg.debug('Lazy init data received.')
end)

function getPoints()
    return points
end

RegisterNetEvent(triggerName('receivePoints'), function(pointsData, isAdmin)
    points = pointsData

    dbg.debug('Receive %s points', table.len(pointsData))
    sendPoints(pointsData)
    initMarkers(isAdmin)
end)

RegisterNetEvent(triggerName('savedPoint'), function(key, data)
    points[key] = data

    sendPoints(points)
    initMarkers()
end)

RegisterNetEvent(triggerName('deletePoint'), function(key)
    points[key] = nil

    tryDeleteMarker(key)

    sendPoints(points)
end)

RegisterNetEvent(triggerName('savedPointCb'), function(state)
    callWaitingCallback(DataTypes.POINT, state)
end)

RegisterNetEvent(triggerName('failedUpdateCategory'), function()
    callWaitingCallback(DataTypes.CATEGORY, false)
end)

RegisterNetEvent(triggerName('updateCategoryCb'), function()
    callWaitingCallback(DataTypes.CATEGORY, true)
end)

RegisterNetEvent(triggerName('updateCategory'), function(categoryKey, categoryData)
    local existed = false
    local initData = getInitData()
    if table.isEmpty(initData) then
        dbg.debug('Cannot provide update of categories - init data is empty! Skipping.')
        return
    end

    for index, catData in pairs(initData.categories) do
        if catData.key == categoryKey then
            initData.categories[index] = categoryData
            existed = true
        end
    end

    if existed == false then
        initData.categories[categoryKey] = categoryData
    end

    dbg.info('Updated category %s', categoryKey)

    setInitData(initData)
    updatedCategory(categoryKey)
end)

RegisterNetEvent(triggerName('failedUpdatePage'), function()
    callWaitingCallback(DataTypes.PAGE, false)
end)

RegisterNetEvent(triggerName('updatePageCb'), function()
    callWaitingCallback(DataTypes.PAGE, true)
end)

RegisterNetEvent(triggerName('updatePage'), function(pageKey, initData)
    pageCache[pageKey] = nil
    updatedPage(pageKey)
    refreshPage(pageKey)

    setInitData(initData)
end)

--Delete
RegisterNetEvent(triggerName('deleteCb'), function(dataType, key, result)
    callWaitingCallback(dataType, result)
end)

RegisterNetEvent(triggerName('deleteEvent'), function(dataType, key, initData)
    if dataType == DataTypes.PAGE then
        pageCache[key] = nil
    end

    setInitData(initData)
end)

RegisterNetEvent(triggerName('teleportCb'), function(state)
    callWaitingCallback(DataTypes.TELEPORT, state)
end)
