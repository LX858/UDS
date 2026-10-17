


local function NotifyActiveDarkChatDevices(username, notif, excludeNumber)
    local sql = ("SELECT phone_number FROM phone_logged_in_accounts " ..
                "WHERE app = 'DarkChat' AND `active` = 1 AND username = ?")
    local params = { username }

    if excludeNumber ~= nil then
        sql = sql .. " AND phone_number != ?"
        params[#params + 1] = excludeNumber
    end

    local rows = MySQL.query.await(sql, params)
    if not rows or #rows == 0 then return end

    for i = 1, #rows do
        SendNotification(rows[i].phone_number, notif)
    end
end
local function RegisterDarkChatAuthedCallback(name, handler, fallback)
    BaseCallback("darkchat:" .. name, function(source, number, ...)
        local username = GetLoggedInAccount(number, "DarkChat")
        if not username then
            return fallback
        end
        return handler(source, number, username, ...)
    end, fallback)
end

BaseCallback("darkchat:getUsername", function(source, number)
    local username = GetLoggedInAccount(number, "DarkChat")
    if not username then
        local found = MySQL.scalar.await(
            "SELECT username FROM phone_darkchat_accounts WHERE phone_number = ? AND `password` IS NULL",
            { number }
        )
        username = found
        if username then
            AddLoggedInAccount(number, "DarkChat", username)
        else
            return false
        end
    end

    local hasPassword = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_accounts WHERE username = ? AND `password` IS NOT NULL",
        { username }
    )

    return { username = username, password = hasPassword and true or false }
end)

BaseCallback("darkchat:setPassword", function(source, number, newPassword)
    if #newPassword < 3 then
        debugprint("DarkChat: password < 3 characters")
        return false
    end

    local username = GetLoggedInAccount(number, "DarkChat")
    if not username then return false end

    local alreadyHasPassword = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_accounts WHERE username = ? AND `password` IS NOT NULL",
        { username }
    )
    if alreadyHasPassword then
        return false
    end

    local hash = GetPasswordHash(newPassword)
    MySQL.update.await(
        "UPDATE phone_darkchat_accounts SET `password` = ? WHERE username = ?",
        { hash, username }
    )
    return true
end)

BaseCallback("darkchat:login", function(source, number, username, password)
    local hash = MySQL.scalar.await(
        "SELECT `password` FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )

    if not hash then
        return { success = false, reason = "invalid_username" }
    end
    if not VerifyPasswordHash(password, hash) then
        return { success = false, reason = "incorrect_password" }
    end

    AddLoggedInAccount(number, "DarkChat", username)
    return { success = true }
end)

BaseCallback("darkchat:register", function(source, number, username, password)
    username = username:lower()

    if not IsUsernameValid(username) then
        return { success = false, reason = "USERNAME_NOT_ALLOWED" }
    end

    local exists = MySQL.scalar.await(
        "SELECT 1 FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )
    if exists then
        return { success = false, reason = "username_taken" }
    end

    local hash = GetPasswordHash(password)
    local affected = MySQL.update.await(
        "INSERT INTO phone_darkchat_accounts (phone_number, username, `password`) VALUES (?, ?, ?)",
        { number, username, hash }
    )
    if not affected or affected <= 0 then
        return { success = false, reason = "unknown" }
    end

    AddLoggedInAccount(number, "DarkChat", username)
    return { success = true }
end)

RegisterDarkChatAuthedCallback("changePassword", function(source, number, username, oldPw, newPw)
    if oldPw == newPw or #newPw < 3 then
        debugprint("same password / too short")
        return false
    end

    if not (Config.ChangePassword and Config.ChangePassword.DarkChat) then
        infoprint("warning", ("%s tried to change password on DarkChat, but it's not enabled in the config."):format(source))
        return false
    end

    local currentHash = MySQL.scalar.await(
        "SELECT `password` FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )
    if not currentHash or not VerifyPasswordHash(oldPw, currentHash) then
        return false
    end

    local ok = MySQL.update.await(
        "UPDATE phone_darkchat_accounts SET `password` = ? WHERE username = ?",
        { GetPasswordHash(newPw), username }
    )
    if not ok or ok <= 0 then return false end

    -- notifier tous les autres appareils connectés et forcer logout
    NotifyActiveDarkChatDevices(username, {
        title = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
        content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
    }, number)

    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'DarkChat' AND phone_number != ?",
        { username, number }
    )

    ClearActiveAccountsCache("DarkChat", username, number)
    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = username,
        app = "darkchat",
        reason = "password",
        number = number
    })

    return true
end, false)

RegisterDarkChatAuthedCallback("deleteAccount", function(source, number, username, password)
    if not (Config.DeleteAccount and Config.DeleteAccount.DarkChat) then
        infoprint("warning", ("%s tried to delete their account on DarkChat, but it's not enabled in the config."):format(source))
        return false
    end

    local hash = MySQL.scalar.await(
        "SELECT `password` FROM phone_darkchat_accounts WHERE username = ?",
        { username }
    )
    if not hash or not VerifyPasswordHash(password, hash) then
        return false
    end

    -- notifier, puis supprimer sessions & caches
    NotifyActiveDarkChatDevices(username, {
        title   = L("BACKEND.MISC.DELETED_NOTIFICATION.TITLE"),
        content = L("BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION")
    })

    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'DarkChat'",
        { username }
    )
    ClearActiveAccountsCache("DarkChat", username)

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = username,
        app = "darkchat",
        reason = "deleted"
    })

    return true
end, false)

RegisterDarkChatAuthedCallback("logout", function(_source, number, username)
    RemoveLoggedInAccount(number, "DarkChat", username)
    return true
end, false)

RegisterDarkChatAuthedCallback("joinChannel", function(source, number, username, channel)
    local inChannel = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_members WHERE channel_name = ? AND username = ?",
        { channel, username }
    )
    if inChannel then
        debugprint("darkchat: already in channel")
        return false
    end

    local exists = MySQL.scalar.await(
        "SELECT TRUE FROM phone_darkchat_channels WHERE `name` = ?",
        { channel }
    )
    if not exists then
        MySQL.update.await(
            "INSERT INTO phone_darkchat_channels (`name`) VALUES (?)",
            { channel }
        )
        Log("DarkChat", source, "info",
            L("BACKEND.LOGS.DARKCHAT_CREATED_TITLE"),
            L("BACKEND.LOGS.DARKCHAT_CREATED_DESCRIPTION", { creator = username, channel = channel })
        )
    end

    local ok = MySQL.update.await(
        "INSERT INTO phone_darkchat_members (channel_name, username) VALUES (?, ?)",
        { channel, username }
    )
    if not ok or ok <= 0 then
        debugprint("darkchat: failed to insert into members")
        return false
    end

    if not exists then
        return { name = channel, members = 1 }
    end

    local info = MySQL.single.await([[
        SELECT `name`,
                (SELECT COUNT(username) FROM phone_darkchat_members WHERE channel_name = `name`) AS members
        FROM phone_darkchat_channels c
        WHERE `name` = ?
    ]], { channel })

    local last = MySQL.single.await([[
        SELECT sender, content, `timestamp`
        FROM phone_darkchat_messages
        WHERE `channel` = ?
        ORDER BY `timestamp` DESC
        LIMIT 1
    ]], { channel })

    if last then
        info.sender      = last.sender
        info.lastMessage = last.content
        info.timestamp   = last.timestamp
    end

    TriggerClientEvent("phone:darkChat:updateChannel", -1, channel, username, "joined")
    return info
end, false)

RegisterDarkChatAuthedCallback("leaveChannel", function(source, number, username, channel)
    local ok = MySQL.update.await(
        "DELETE FROM phone_darkchat_members WHERE channel_name = ? AND username = ?",
        { channel, username }
    )
    if not ok or ok <= 0 then return false end

    TriggerClientEvent("phone:darkChat:updateChannel", -1, channel, username, "left")
    return true
end, false)

RegisterDarkChatAuthedCallback("getChannels", function(source, number, username)
    return MySQL.query.await([[
        SELECT
            c.`name`,
            (SELECT COUNT(username) FROM phone_darkchat_members WHERE channel_name = c.`name`) AS members,
            m.sender AS sender,
            m.content AS lastMessage,
            m.`timestamp` AS `timestamp`
        FROM phone_darkchat_channels c
        LEFT JOIN phone_darkchat_messages m ON m.`channel` = c.`name`
        WHERE EXISTS (
            SELECT TRUE FROM phone_darkchat_members
            WHERE channel_name = c.`name` AND username = ?
        )
        AND COALESCE(m.`timestamp`, '1970-01-01 00:00:00') = (
            SELECT COALESCE(MAX(`timestamp`), '1970-01-01 00:00:00')
            FROM phone_darkchat_messages WHERE `channel` = c.`name`
        )
    ]], { username })
end, {})

RegisterDarkChatAuthedCallback("getMessages", function(source, number, username, channel, page)

    return MySQL.query.await([[
        SELECT sender, content, `timestamp`
        FROM phone_darkchat_messages
        WHERE `channel` = ?
        ORDER BY `timestamp` DESC
        LIMIT ?, ?
    ]], { channel, page * 15, 15 })
end, {})

local function InsertDarkChatMessage(sender, channel, content)
    local id = MySQL.insert.await(
        "INSERT INTO phone_darkchat_messages (sender, `channel`, content) VALUES (?, ?, ?)",
        { sender, channel, content }
    )
    if not id then return false end

    NotifyPhones([[
        phone_darkchat_members m
        JOIN phone_logged_in_accounts l
            ON l.app = 'DarkChat'
            AND l.`active` = 1
            AND l.username = m.username
        WHERE m.channel_name = @channel
            AND m.username != @username
    ]], {
        app = "DarkChat",
        title = channel,
        content = (sender .. ": " .. content)
    }, "l.", { ["@channel"] = channel, ["@username"] = sender })

    TriggerClientEvent("phone:darkChat:newMessage", -1, channel, sender, content)
    return true
end

RegisterDarkChatAuthedCallback("sendMessage", function(source, number, username, channel, content)
    if ContainsBlacklistedWord(source, "DarkChat", content) then
        return false
    end
    if not InsertDarkChatMessage(username, channel, content) then
        return false
    end

    Log("DarkChat", source, "info",
        L("BACKEND.LOGS.DARKCHAT_MESSAGE_TITLE"),
        L("BACKEND.LOGS.DARKCHAT_MESSAGE_DESCRIPTION", {
            sender  = username,
            channel = channel,
            message = content
        })
    )
    return true
end, false)

exports("SendDarkChatMessage", function(username, channel, message, cb)
    assert(type(username) == "string", "username must be a string")
    assert(type(channel)  == "string", "channel must be a string")
    assert(type(message)  == "string", "message must be a string")

    local ok = InsertDarkChatMessage(username, channel, message)
    if cb then cb(ok) end
    return ok
end)

exports("SendDarkChatLocation", function(username, channel, pos, cb)
    assert(type(username) == "string", "Expected string for argument 1, got " .. type(username))
    assert(type(channel)  == "string", "Expected string for argument 2, got " .. type(channel))
    assert(type(pos)      == "vector2","Expected vector2 for argument 3, got " .. type(pos))

    local msg = ("<!SENT-LOCATION-X=%sY=%s!>"):format(pos.x, pos.y)
    local ok = InsertDarkChatMessage(username, channel, msg)
    if cb then cb(ok) end
    return ok
end)
