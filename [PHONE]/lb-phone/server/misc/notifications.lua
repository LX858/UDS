

local disabledNotifications = Config.DisabledNotifications
if not disabledNotifications then
    disabledNotifications = {}
end

function SendNotification(phoneNumberOrSource, notificationData, callback)
    if table.contains(disabledNotifications, notificationData.app) then
        if callback then
            callback(false)
        end
        debugprint("Notification are disabled for app", notificationData.app)
        return
    end
    
    notificationData = table.clone(notificationData)
    
    if type(notificationData) == "table" then
        if notificationData.app then
            -- Valid data, continue
        elseif type(phoneNumberOrSource) ~= "string" then
            -- Valid data, continue
        else
            if callback then
                callback(false)
            end
            debugprint("Invalid data or no app")
            return
        end
    else
        if callback then
            callback(false)
        end
        debugprint("Invalid data or no app")
        return
    end
    
    if notificationData.content then
        if #notificationData.content > 500 then
            if callback then
                callback(false)
            end
            debugprint("Content too long")
            return
        end
    end
    
    if type(phoneNumberOrSource) == "number" then
        notificationData.source = phoneNumberOrSource
    end
    
    if notificationData.app then
        if not notificationData.source then
            if type(phoneNumberOrSource) == "string" then
                local source = GetSourceFromNumber(phoneNumberOrSource)
                if source then
                    notificationData.source = source
                end
            end
        end
    end
    
    if notificationData.app and type(phoneNumberOrSource) == "string" then
        -- Save to database
    else
        if callback then
            callback(true)
        end
        
        if notificationData.source then
            TriggerClientEvent("phone:sendNotification", notificationData.source, notificationData)
            debugprint("Sending notification to source: " .. notificationData.source)
        else
            debugprint("Couldn't find source, no notification printing")
        end
        
        debugprint("No app or no phone number provided (not a string)")
        return
    end
    
    if Config.MaxNotifications then
        local oldNotificationId = MySQL.scalar.await("SELECT id FROM phone_notifications WHERE phone_number = ? ORDER BY id DESC LIMIT ?, 1", {
            phoneNumberOrSource,
            Config.MaxNotifications - 1
        })
        
        if oldNotificationId then
            debugprint("Max notifications reached, deleting all older notifications", phoneNumberOrSource, oldNotificationId)
            MySQL.update.await("DELETE FROM phone_notifications WHERE phone_number = ? AND id <= ?", {
                phoneNumberOrSource,
                oldNotificationId
            })
        end
    end
    
    local customDataJson = nil
    if notificationData.customData then
        customDataJson = json.encode(notificationData.customData)
    end
    
    local notificationId = MySQL.insert.await("INSERT IGNORE INTO phone_notifications (phone_number, app, title, content, thumbnail, avatar, show_avatar, custom_data) VALUES (@phoneNumber, @app, @title, @content, @thumbnail, @avatar, @showAvatar, @data)", {
        ["@phoneNumber"] = phoneNumberOrSource,
        ["@app"] = notificationData.app,
        ["@title"] = notificationData.title,
        ["@content"] = notificationData.content,
        ["@thumbnail"] = notificationData.thumbnail,
        ["@avatar"] = notificationData.avatar,
        ["@showAvatar"] = notificationData.showAvatar,
        ["@data"] = customDataJson
    })
    
    notificationData.id = notificationId
    
    if notificationData.source then
        TriggerClientEvent("phone:sendNotification", notificationData.source, notificationData)
        debugprint("Sending notification to source: " .. notificationData.source)
    else
        debugprint("Couldn't find source, no notification printing")
    end
    
    if callback then
        callback(notificationId)
    end
end

exports("SendNotification", SendNotification)

function NotifyEveryone(notifyType, notificationData)
    assert(notifyType == "all" or notifyType == "online", "Invalid notify")
    assert(type(notificationData.app) == "string", "Invalid app")
    assert(type(notificationData.title) == "string", "Invalid title")
    
    if table.contains(disabledNotifications, notificationData.app) then
        debugprint("NotifyEveryone: Notification are disabled for app", notificationData.app)
        return
    end
    
    if notifyType == "all" then
        MySQL.insert([[
            INSERT INTO phone_notifications
                (phone_number, app, title, content, thumbnail, avatar, show_avatar)
            SELECT
                phone_number, @app, @title, @content, @thumbnail, @avatar, @showAvatar
            FROM
                phone_phones
            WHERE
                last_seen > DATE_SUB(NOW(), INTERVAL 7 DAY)
        ]], {
            ["@app"] = notificationData.app,
            ["@title"] = notificationData.title,
            ["@content"] = notificationData.content,
            ["@thumbnail"] = notificationData.thumbnail,
            ["@avatar"] = notificationData.avatar,
            ["@showAvatar"] = notificationData.showAvatar
        })
    end
    
    TriggerClientEvent("phone:sendNotification", -1, notificationData)
end

exports("NotifyEveryone", NotifyEveryone)

function NotifyPhones(tableName, notificationData, whereClause, params)
    if table.contains(disabledNotifications, notificationData.app) then
        debugprint("NotifyPhones: Notification are disabled for app", notificationData.app)
        return
    end
    
    if not params then
        params = {}
    end
    
    if not whereClause then
        whereClause = ""
    end
    
    params["@app"] = notificationData.app
    params["@title"] = notificationData.title
    params["@content"] = notificationData.content
    params["@thumbnail"] = notificationData.thumbnail
    params["@avatar"] = notificationData.avatar
    params["@showAvatar"] = notificationData.showAvatar
    
    local query = ([[
        INSERT INTO phone_notifications
            (phone_number, app, title, content, thumbnail, avatar, show_avatar)
        SELECT
            %sphone_number, @app, @title, @content, @thumbnail, @avatar, @showAvatar
        FROM
            %s
        RETURNING
            id, phone_number
    ]]):format(whereClause, tableName)
    
    MySQL.query(query, params, function(results)
        for i = 1, #results do
            local phoneNumber = results[i].phone_number
            local source = GetSourceFromNumber(phoneNumber)
            if source then
                notificationData.id = results[i].id
                TriggerClientEvent("phone:sendNotification", source, notificationData)
            end
        end
    end)
end

function EmergencyNotification(source, data)
    assert(type(source) == "number", "Invalid source")
    assert(type(data) == "table", "Invalid data")
    
    SendNotification(source, {
        title = data.title or "Emergency Alert",
        content = data.content or "This is a test emergency alert.",
        icon = "./assets/img/icons/" .. (data.icon or "warning") .. ".png"
    })
end

exports("SendAmberAlert", EmergencyNotification)
exports("EmergencyNotification", EmergencyNotification)

BaseCallback("getNotifications", function(source, phoneNumber, ...)
    return MySQL.query.await("SELECT id, app, title, content, thumbnail, avatar, show_avatar AS showAvatar, custom_data, `timestamp` FROM phone_notifications WHERE phone_number=?", {
        phoneNumber
    })
end, {})

BaseCallback("deleteNotification", function(source, phoneNumber, notificationId)
    return MySQL.update.await("DELETE FROM phone_notifications WHERE id=? AND phone_number=?", {
        notificationId,
        phoneNumber
    }) > 0
end)

BaseCallback("clearNotifications", function(source, phoneNumber, app)
    MySQL.update.await("DELETE FROM phone_notifications WHERE phone_number=? AND app=?", {
        phoneNumber,
        app
    })
    return true
end)
