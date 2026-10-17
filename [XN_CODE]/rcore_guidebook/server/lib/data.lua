local gameName = GetGameName()

RegisterNetEvent(triggerName('requestData'), function(cbId, type, key)
    local _source = source
    if type == DataTypes.PAGE then
        local page = getPage(key)

        TriggerClientEvent(triggerName('receiveData'), _source, cbId, page, {
            type = type,
            key = key,
        })
    else
        dbg.critical('Not-implemented request %s', type)
    end
end)

RegisterNetEvent(triggerName('searchPageContents'), function(query, cbId)
    local _source = source

    local results = searchPageContents(query, _source)
    TriggerClientEvent(triggerName('receiveSearchResults'), _source, cbId, results)
end)

local function save(dataType, data, isScript)
    isScript = isScript or false
    local _source = source
    if dataType ~= DataTypes.CATEGORY and dataType ~= DataTypes.PAGE and dataType ~= DataTypes.POINT then
        dbg.critical('Wrong data type!')
        return
    end

    data.order_number = tonumber(data.order_number) or nil

    if dataType == DataTypes.CATEGORY then
        data.attributes = json.encode(data.attributes)

        local ok, rule, err = validate({
            ['required|number|min:0|max:999999'] = data.order_number,
            ['required|string|min:3'] = data.key,
            ['required|string|min:3'] = data.label,
            ['required|bool'] = data.default_expand,
            ['required|bool'] = data.is_enabled,
            ['string'] = data.attributes,
        })

        if not ok then
            dbg.critical('Validation error! Rule %s', rule)
            if not isScript then
                TriggerClientEvent(triggerName('updateFailedCategory'), _source)
            end

            return
        end

        local category = getCategory(data.key)
        local success = false
        if category then
            if not isScript then
                if not Ace.Can(_source, Permissions.EDIT_CATEGORY) then
                    log(
                        string.format("Player %s dont have permission to create category %s", getNiceName(_source),
                            data.key),
                        LogLevel.PERMISSION)
                    return
                end
            end

            success = updateCategory(data.key, data.label, data.order_number, data.is_enabled, data.default_expand,
                data.attributes)
            dbg.debug('Updating category %s', data.key)
        else
            if not isScript then
                if not Ace.Can(_source, Permissions.CREATE_CATEGORY) then
                    log(
                        string.format("Player %s dont have permission to create category %s", getNiceName(_source),
                            data.key),
                        LogLevel.PERMISSION)
                    return
                end
            end

            success = createCategory(data.key, data.label, data.order_number, data.is_enabled, data.default_expand,
                data.attributes)
            dbg.debug('Creating category %s', data.key)
        end

        if success then
            if not isScript then
                TriggerClientEvent(triggerName('updateCategoryCb'), _source)
            end
            TriggerClientEvent(triggerName('updateCategory'), -1, data.key, getCategory(data.key))
        else
            if not isScript then
                TriggerClientEvent(triggerName('updateFailedCategory'), _source)
            end
        end
    elseif dataType == DataTypes.PAGE then
        data.attributes = json.encode(data.attributes)

        local ok, rule, err = validate({
            ['required|number|min:0|max:999999'] = data.order_number,
            ['required|string|min:3'] = data.key,
            ['required|string|min:3'] = data.label,
            ['required|bool'] = data.is_enabled,
            ['required|string'] = data.content,
            ['required|string'] = data.category_key,
            ['string'] = data.attributes,
        })

        if not ok then
            dbg.critical('Validation error! Rule %s', rule)
            return
        end

        local category = getCategory(data.category_key)
        if category == nil then
            dbg.critical("Cannot found selected category!")
            if not isScript then
                TriggerClientEvent(triggerName('updateFailedPage'), _source)
            end
            return
        end

        local success = false
        local page = getPage(data.key)
        if page then
            if not isScript then
                if not Ace.Can(_source, Permissions.EDIT_PAGE) then
                    log(string.format("Player %s dont have permission to edit page %s", getNiceName(_source), data.key),
                        LogLevel.PERMISSION)
                    return
                end
            end

            success = updatePage(data.key, data.label, data.category_key, data.order_number, data.is_enabled,
                data.content, data.attributes)
        else
            if not isScript then
                if not Ace.Can(_source, Permissions.CREATE_PAGE) then
                    log(
                        string.format("Player %s dont have permission to create page %s", getNiceName(_source), data.key),
                        LogLevel.PERMISSION)
                    return
                end
            end

            success = createPage(data.key, data.label, data.category_key, data.order_number, data.is_enabled,
                data.content, data.attributes)
        end

        if success then
            dbg.debug('Sending updatePageCb %s', _source)
            if not isScript then
                TriggerClientEvent(triggerName('updatePageCb'), _source)
            end
            TriggerClientEvent(triggerName('updatePage'), -1, data.key, formatFrontendData())
        else
            if not isScript then
                TriggerClientEvent(triggerName('updateFailedPage'), _source)
            end
        end
    elseif dataType == DataTypes.POINT then
        data.is_enabled = data.is_enabled or false
        data.is_rotation_enabled = data.is_rotation_enabled or false
        data.can_navigate = data.can_navigate or false
        data.blip_enabled = data.blip_enabled or false
        data.marker_enabled = data.marker_enabled or false
        data.draw_distance = tonumber(data.draw_distance)
        data.size = tonumber(data.size)
        data.attributes = json.encode(data.attributes)

        local ok, rule, err = validate({
            ['required|table'] = data.position,
            ['required'] = data.position.x,
            ['required'] = data.position.y,
            ['required'] = data.position.y,
            ['required|table'] = data.color,
            ['required'] = data.color.r,
            ['required'] = data.color.g,
            ['required'] = data.color.b,
            ['required|number|min:0.0|max:999'] = data.size,
            ['required|string|min:3'] = data.key,
            ['required|string|min:3'] = data.label,
            ['required|bool'] = data.is_enabled,
            ['required|bool'] = data.is_rotation_enabled,
            ['string'] = data.content,
            ['required|bool'] = data.can_navigate,
            ['bool'] = data.blip_enabled,
            ['bool'] = data.marker_enabled,
            ['required|number|min:0|max:9999'] = data.draw_distance,
            ['string'] = data.attributes,
        })

        if not ok then
            dbg.critical('Validation error! Rule %s', rule)
            if not isScript then
                TriggerClientEvent(triggerName('savedPointCb'), _source, false)
            end
            return
        end

        if data.blip_enabled then
            data.blip_size = tonumber(data.blip_size)

            if gameName == GameType.FIVEM then
                data.blip_display_type = tonumber(data.blip_display_type)
                data.blip_sprite = tonumber(data.blip_sprite)

                ok, rule, err = validate({
                    ['required|number|min:0.0|max:20.0'] = data.blip_size,
                    ['required|number|min:0|max:8'] = data.blip_display_type,
                    ['required|number|min:0|max:9999'] = data.blip_sprite,
                })
            elseif gameName == GameType.REDM then
                ok, rule, err = validate({
                    ['required|min:0.0|max:20.0'] = data.blip_size,
                    ['required|string'] = data.blip_sprite,
                })
            end

            if not ok then
                dbg.critical('Blip validation error! Rule %s', rule)
                if not isScript then
                    TriggerClientEvent(triggerName('savedPointCb'), _source, false)
                end
                return
            end
        end

        if data.marker_enabled then
            data.marker_draw_distance = tonumber(data.marker_draw_distance)
            if gameName == GameType.FIVEM then
                data.marker_type = tonumber(data.marker_type)
                ok, rule, err = validate({
                    ['table'] = data.marker_size,
                    ['number|min:0.0|max:50.0'] = data.marker_size.x,
                    ['number|min:0.0|max:50.0'] = data.marker_size.y,
                    ['number|min:0.0|max:50.0'] = data.marker_size.z,
                    ['table'] = data.marker_color,
                    ['table'] = data.marker_rotation,
                    ['number|min:0|max:255'] = data.marker_color.r,
                    ['number|min:0|max:255'] = data.marker_color.g,
                    ['number|min:0|max:255'] = data.marker_color.b,
                    ['number|min:0|max:360'] = data.marker_rotation.x,
                    ['number|min:0|max:360'] = data.marker_rotation.y,
                    ['number|min:0|max:360'] = data.marker_rotation.z,
                    ['number|min:0|max:200'] = data.marker_draw_distance,
                    ['number|min:0|max:999'] = data.marker_type,
                })
            elseif gameName == GameType.REDM then
                ok, rule, err = validate({
                    ['table'] = data.marker_size,
                    ['number|min:0.0|max:50.0'] = data.marker_size.x,
                    ['number|min:0.0|max:50.0'] = data.marker_size.y,
                    ['number|min:0.0|max:50.0'] = data.marker_size.z,
                    ['table'] = data.marker_color,
                    ['table'] = data.marker_rotation,
                    ['number|min:0|max:255'] = data.marker_color.r,
                    ['number|min:0|max:255'] = data.marker_color.g,
                    ['number|min:0|max:255'] = data.marker_color.b,
                    ['number|min:0|max:360'] = data.marker_rotation.x,
                    ['number|min:0|max:360'] = data.marker_rotation.y,
                    ['number|min:0|max:360'] = data.marker_rotation.z,
                    ['number|min:0|max:200'] = data.marker_draw_distance,
                    ['string'] = data.marker_type,
                })
            end

            if not ok then
                dbg.critical('Marker validation error! Rule %s', rule)
                if not isScript then
                    TriggerClientEvent(triggerName('savedPointCb'), _source, false)
                end
                return
            end
        end

        if data.help_key and data.help_key ~= 'custom_content' then
            local page = getPage(data.help_key)
            if page == nil then
                dbg.critical("Cannot found page %s delegated in help_key variable", data.help_key)
                if not isScript then
                    TriggerClientEvent(triggerName('savedPointCb'), _source, false)
                end
                return
            end
        end

        local success = false
        local point = getPoint(data.key)
        if not point then
            success = createPoint(data)
        else
            success = updatePoint(data)
        end

        point = getPoint(data.key)
        if success then
            if not isScript then
                TriggerClientEvent(triggerName('savedPointCb'), _source, true)
            end
            TriggerClientEvent(triggerName('savedPoint'), -1, point.key, point)
        else
            if not isScript then
                TriggerClientEvent(triggerName('savedPointCb'), _source, false)
            end
        end
    end
end

RegisterNetEvent(triggerName('save'), function(dataType, data)
    save(dataType, data)
end)

AddEventHandler(triggerName('saveInternal'), function(dataType, data)
    save(dataType, data, true)
end)

AddEventHandler(triggerName('supportDynamicSave'), function(cb)
    pcall(cb)
end)

RegisterNetEvent(triggerName('delete'), function(dataType, key)
    local _source = source
    if dataType ~= DataTypes.CATEGORY and dataType ~= DataTypes.PAGE and dataType ~= DataTypes.POINT then
        dbg.critical('Wrong data type!')
        return
    end

    local success = false

    if dataType == DataTypes.CATEGORY then
        if not Ace.Can(_source, Permissions.DELETE_CATEGORY) then
            log(string.format("Player %s dont have permission to delete category %s", getNiceName(_source), key),
                LogLevel.PERMISSION)
            return
        end

        success = deleteCategory(key)
    elseif dataType == DataTypes.PAGE then
        if not Ace.Can(_source, Permissions.DELETE_PAGE) then
            log(string.format("Player %s dont have permission to delete page %s", getNiceName(_source), key),
                LogLevel.PERMISSION)
            return
        end

        success = deletePage(key)
    elseif dataType == DataTypes.POINT then
        if not Ace.Can(_source, Permissions.DELETE_POINT) then
            log(string.format("Player %s dont have permission to delete point %s", getNiceName(_source), key),
                LogLevel.PERMISSION)
            return
        end

        success = deletePoint(key)
    end

    TriggerClientEvent(triggerName('deleteCb'), _source, dataType, key, success)
    if success then
        if dataType == DataTypes.POINT then
            TriggerClientEvent(triggerName('deletePoint'), -1, key)
        else
            TriggerClientEvent(triggerName('deleteEvent'), -1, dataType, key, formatFrontendData())
        end
    end
end)

local ENSURE_DATA_ERRORS = {
    ALREADY_EXISTS = "Data already exists",
    WRONG_DATA_TYPE = "Wrong data type",
    NO_KEY = "Data does not have key",
    NOT_INITIALIZED = "Guidebook is not initialized yet, please wait.",
}

RegisterNetEvent(triggerName('ensureData'), function(dataType, data, cb)
    if not IsDataFinishedLoading then
        dbg.critical('[ensureData]: Guidebook is not initialized yet, please wait.')
        cb(false, ENSURE_DATA_ERRORS.NOT_INITIALIZED)
        return
    end

    if dataType ~= DataTypes.CATEGORY and dataType ~= DataTypes.PAGE and dataType ~= DataTypes.POINT then
        dbg.critical('Wrong data type!')
        cb(false, ENSURE_DATA_ERRORS.WRONG_DATA_TYPE)
        return
    end

    if not data.key then
        dbg.critical('[ensureData]: Data does not have key!')
        cb(false, ENSURE_DATA_ERRORS.NO_KEY)
        return
    end

    local existingData = nil

    if dataType == DataTypes.CATEGORY then
        existingData = getCategory(data.key)
    elseif dataType == DataTypes.PAGE then
        existingData = getPage(data.key)
    elseif dataType == DataTypes.POINT then
        existingData = getPoint(data.key)
    end

    if existingData then
        dbg.debug('[ensureData]: Item "%s" with type "%s" already exists, returning.', data.key, dataType)
        cb(false, ENSURE_DATA_ERRORS.ALREADY_EXISTS)
        return
    end

    cb(true)
    dbg.debug('[ensureData]: Item "%s" with type "%s" does not exists, creating now.', data.key, dataType)
    save(dataType, data, true)
end)
