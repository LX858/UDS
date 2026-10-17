local supportedApps = {
    twitter = true,
    instagram = true,
    tiktok = true
}

local appAliases = {
    birdy = "twitter",
    instapic = "instagram",
    trendy = "tiktok"
}

local appDisplayNames = {
    twitter = "Twitter",
    instagram = "Instagram",
    tiktok = "TikTok"
}

function ToggleVerified(app, username, verified)
    assert(type(app) == "string", "Invalid app")
    
    app = app:lower()
    if not supportedApps[app] then
        app = tostring(appAliases[app])
    end
    
    assert(supportedApps[app], "Invalid app")
    assert(type(username) == "string", "Invalid username")
    
    TriggerEvent("lb-phone:toggleVerified", app, username, verified)
    
    local success = MySQL.Sync.execute(("UPDATE phone_%s_accounts SET verified=@verified WHERE username=@username"):format(app), {
        ["@username"] = username,
        ["@verified"] = verified
    }) > 0
    
    if success and verified then
        local displayName = appDisplayNames[app]
        if displayName then
            local accounts = MySQL.query.await("SELECT phone_number FROM phone_logged_in_accounts WHERE app = ? AND username = ? AND `active` = 1", {
                app,
                username
            })
            
            for i = 1, #accounts do
                local phoneNumber = accounts[i].phone_number
                SendNotification(phoneNumber, {
                    app = displayName,
                    title = L("BACKEND.MISC.VERIFIED")
                })
            end
        end
    end
    
    return success
end

exports("ToggleVerified", ToggleVerified)

exports("IsVerified", function(app, username)
    assert(type(app) == "string", "Invalid app")
    
    app = app:lower()
    if not supportedApps[app] then
        app = tostring(appAliases[app])
    end
    
    assert(supportedApps[app], "Invalid app")
    assert(type(username) == "string", "Invalid username")
    
    local verified = MySQL.Sync.fetchScalar(("SELECT verified FROM phone_%s_accounts WHERE username=@username"):format(app), {
        ["@username"] = username
    })
    
    if not verified then
        verified = false
    end
    
    return verified
end)

local usernameFields = {
    twitter = "username",
    instagram = "username",
    tiktok = "username",
    mail = "address",
    darkchat = "username"
}

function ChangePassword(app, username, password)
    assert(type(app) == "string", "Invalid app")
    
    app = app:lower()
    if not usernameFields[app] then
        app = tostring(appAliases[app])
    end
    
    assert(usernameFields[app], "Invalid app")
    assert(type(username) == "string", "Invalid username")
    assert(type(password) == "string", "Invalid password")
    
    local success = MySQL.Sync.execute(("UPDATE phone_%s_accounts SET password=@password WHERE %s=@username"):format(app, usernameFields[app]), {
        ["@username"] = username,
        ["@password"] = GetPasswordHash(password)
    }) > 0
    
    if not success then
        return false
    end
    
    MySQL.update("DELETE FROM phone_logged_in_accounts WHERE app = ? AND username = ?", {
        app,
        username
    })
    
    return true
end

exports("ChangePassword", ChangePassword)

exports("GetEquippedPhoneNumber", function(identifier)
    if type(identifier) == "number" then
        return GetEquippedPhoneNumber(identifier)
    end
    
    local source = GetSourceFromIdentifier and GetSourceFromIdentifier(identifier)
    if source then
        return GetEquippedPhoneNumber(source)
    end
    
    local tableName = "phone_phones"
    if Config.Item.Unique then
        tableName = "phone_last_phone"
    end
    
    local fieldName = "id"
    return MySQL.scalar.await(("SELECT phone_number FROM %s WHERE %s = ?"):format(tableName, fieldName), {
        identifier
    })
end)
