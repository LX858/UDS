

local activeAccounts = {}

local supportedApps = {
    Twitter = true,
    Instagram = true,
    Mail = true,
    TikTok = true,
    DarkChat = true
}

local appAliases = {
    instapic = "Instagram",
    birdy = "Twitter",
    trendy = "TikTok",
    darkchat = "DarkChat",
    mail = "Mail"
}

for appName, _ in pairs(supportedApps) do
    activeAccounts[appName] = {}
end

BaseCallback("accountSwitcher:switchAccount", function(source, phoneNumber, app, username)
    if not supportedApps[app] then
        return false
    end
    
    local hasAccess = MySQL.scalar.await("SELECT TRUE FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ? AND username = ?", {
        phoneNumber,
        app,
        username
    })
    
    if not hasAccess then
        print(("Possible abuse? %s (%i) tried to switch to an account they aren't logged into."):format(GetPlayerName(source), source))
        return false
    end
    
    local success = MySQL.update.await("UPDATE phone_logged_in_accounts SET `active` = (username = ?) WHERE phone_number = ? AND app = ?", {
        username,
        phoneNumber,
        app
    }) > 0
    
    if success then
        activeAccounts[app][phoneNumber] = username
        TriggerEvent("phone:loggedInToAccount", app, phoneNumber, username)
    end
    
    return success
end)

BaseCallback("accountSwitcher:getAccounts", function(source, phoneNumber, app)
    if not supportedApps[app] then
        return {}
    end
    
    return MySQL.query.await("SELECT username FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ?", {
        phoneNumber,
        app
    })
end)

function AddLoggedInAccount(phoneNumber, app, username)
    assert(supportedApps[app], "Invalid app: " .. app)
    assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")
    assert(type(username) == "string", "Invalid username. Expected string.")
    
    MySQL.update.await("UPDATE phone_logged_in_accounts SET `active` = 0 WHERE phone_number = ? AND app = ? AND username != ?", {
        phoneNumber,
        app,
        username
    })
    
    local success = MySQL.update.await("INSERT INTO phone_logged_in_accounts (phone_number, app, username, active) VALUES (?, ?, ?, 1) ON DUPLICATE KEY UPDATE active = 1", {
        phoneNumber,
        app,
        username
    }) > 0
    
    if success then
        activeAccounts[app][phoneNumber] = username
        TriggerEvent("phone:loggedInToAccount", app, phoneNumber, username)
    end
    
    return success
end

function RemoveLoggedInAccount(phoneNumber, app, username)
    assert(supportedApps[app], "Invalid app: " .. app)
    assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")
    assert(type(username) == "string", "Invalid username. Expected string.")
    
    local success = MySQL.update.await("DELETE FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ? AND username = ?", {
        phoneNumber,
        app,
        username
    }) > 0
    
    if success then
        if activeAccounts[app][phoneNumber] == username then
            activeAccounts[app][phoneNumber] = nil
        end
        TriggerEvent("phone:loggedOutFromAccount", app, username, phoneNumber)
    end
    
    return success
end

function GetLoggedInAccount(phoneNumber, app, skipCache)
    assert(supportedApps[app], "Invalid app: " .. app)
    assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")
    
    local cachedUsername = activeAccounts[app][phoneNumber]
    if cachedUsername then
        return cachedUsername
    end
    
    local username = MySQL.scalar.await("SELECT username FROM phone_logged_in_accounts WHERE phone_number = ? AND app = ? AND active = 1", {
        phoneNumber,
        app
    })
    
    if username and not skipCache then
        debugprint("AccountSwitcher: Setting cache for " .. phoneNumber .. ", logged in as " .. username .. " on " .. app)
        activeAccounts[app][phoneNumber] = username
    end
    
    return username or false
end

function GetLoggedInNumbers(app, username)
    assert(supportedApps[app], "Invalid app: " .. app)
    assert(type(username) == "string", "Invalid username. Expected string.")
    
    local results = MySQL.query.await("SELECT phone_number FROM phone_logged_in_accounts WHERE app = ? AND username = ?", {
        app,
        username
    })
    
    if not results then
        return {}
    end
    
    local phoneNumbers = {}
    for i = 1, #results do
        phoneNumbers[#phoneNumbers + 1] = results[i].phone_number
    end
    
    return phoneNumbers
end

function GetActiveAccounts(app)
    return activeAccounts[app] or {}
end

function ClearActiveAccountsCache(app, username, excludePhoneNumber)
    assert(supportedApps[app], "Invalid app: " .. app)
    assert(type(username) == "string", "Invalid username. Expected string.")
    
    for phoneNumber, cachedUsername in pairs(activeAccounts[app]) do
        if cachedUsername == username and phoneNumber ~= excludePhoneNumber then
            activeAccounts[app][phoneNumber] = nil
        end
    end
end

exports("GetSocialMediaUsername", function(phoneNumber, app)
    assert(type(phoneNumber) == "string", "Invalid phone number. Expected string.")
    assert(type(app) == "string", "Invalid app. Expected string.")
    assert(appAliases[app], "Invalid app: " .. app)
    
    return GetLoggedInAccount(phoneNumber, appAliases[app], true)
end)

AddEventHandler("playerDropped", function()
    local phoneNumber = GetEquippedPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    for app, accounts in pairs(activeAccounts) do
        if accounts[phoneNumber] then
            accounts[phoneNumber] = nil
            debugprint("AccountSwitcher: Player dropped, logging out " .. phoneNumber .. " from " .. app)
        end
    end
end)
