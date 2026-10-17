

local function GenerateString(length)
    local out = ""
    local n = length or 15
    for _ = 1, n do
        if math.random(1, 2) == 1 then
            local c = string.char(math.random(97, 122))
            if math.random(1, 2) == 1 then
                c = c:upper()
            end
            out = out .. c
        else
            out = out .. tostring(math.random(1, 9))
        end
    end
    return out
end
_G.GenerateString = GenerateString

local function GenerateId(tableName, fieldName)
    local unique, candidate
    while not unique do
        candidate = GenerateString(5)
        local exists = MySQL.Sync.fetchScalar(
            ("SELECT `%s` FROM `%s` WHERE `%s` = @id"):format(fieldName, tableName, fieldName),
            { ["@id"] = candidate }
        )
        unique = (exists == nil)
        if not unique then Wait(50) end
    end
    return candidate
end
_G.GenerateId = GenerateId

local function GeneratePhoneNumber()
    local prefixes = Config.PhoneNumber.Prefixes
    local ok, number

    while not ok do
        local body = ""
        for _ = 1, Config.PhoneNumber.Length do
            body = body .. tostring(math.random(0, 9))
        end

        if #prefixes == 0 then
            number = body
        else
            number = prefixes[math.random(1, #prefixes)] .. body
        end

        local exists = MySQL.Sync.fetchScalar(
            "SELECT phone_number FROM phone_phones WHERE phone_number = @number",
            { ["@number"] = number }
        )
        ok = (exists == nil)
        if not ok then Wait(0) end
    end

    return number
end
_G.GeneratePhoneNumber = GeneratePhoneNumber

local OnlineOwnersByNumber = {}

local SettingsCache = {}

local DirtySettings = {}

local PhoneObjects = {}

function GetSettings(phoneNumber)
    return SettingsCache[phoneNumber]
end
exports("GetSettings", GetSettings)

local function SetSettings(phoneNumber, settings)
    if not settings then
        if DirtySettings[phoneNumber] then
            DirtySettings[phoneNumber] = nil
            if Config.CacheSettings ~= false then
                debugprint("Updating settings in database for", phoneNumber)
                MySQL.update(
                    "UPDATE phone_phones SET settings = ? WHERE phone_number = ?",
                    { json.encode(SettingsCache[phoneNumber]), phoneNumber }
                )
            end
        end
        return
    end

    SettingsCache[phoneNumber] = settings
end

local function SaveAllSettings()
    if Config.CacheSettings == false then return end

    infoprint("info", "Saving all settings")

    for phoneNumber, settings in pairs(SettingsCache) do
        if DirtySettings[phoneNumber] then
            MySQL.update(
                "UPDATE phone_phones SET settings = ? WHERE phone_number = ?",
                { json.encode(settings), phoneNumber }
            )
        else
            debugprint("Not saving settings for", phoneNumber, "because no changes were made")
        end
    end
end

local function GetEquippedPhoneNumber(src, cb)
    -- Keep this global for compatibility with other modules expecting it
    for number, ownerSrc in pairs(OnlineOwnersByNumber) do
        if ownerSrc == src then
            if cb then cb(number) end
            return number
        end
    end
end

_G.GetEquippedPhoneNumber = GetEquippedPhoneNumber

function GetSourceFromNumber(phoneNumber)
    if not phoneNumber then return false end
    return OnlineOwnersByNumber[phoneNumber] or false
end
exports("GetSourceFromNumber", GetSourceFromNumber)

local LatestVersion -- string|nil
PerformHttpRequest("https://loaf-scripts.com/versions/phone/version.json", function(status, body, headers, err)
    if status ~= 200 then
        debugprint("Failed to get latest script version")
        debugprint("Status:", status)
        debugprint("Body:", body)
        debugprint("Headers:", headers)
        debugprint("Error:", err)
        return
    end
    local parsed = json.decode(body)
    LatestVersion = parsed.latest
end, "GET")

RegisterCallback("getLatestVersion", function()
    -- Trả về version hiện tại để UI không hiện badge "có bản mới"
    return GetResourceMetadata(GetCurrentResourceName(), "version", 0)
end)

RegisterLegacyCallback("playerLoaded", function(src, cb)
    local identifier = GetIdentifier(src)
    debugprint(GetPlayerName(src), src, identifier, "triggered phone:playerLoaded")

    if not Config.Item.Unique then
        local existingNumber = MySQL.scalar.await(
            "SELECT phone_number FROM phone_phones WHERE id = ?",
            { identifier }
        )
        if existingNumber then
            if HasPhoneItem(src, existingNumber) then
                OnlineOwnersByNumber[existingNumber] = src
                MySQL.update("UPDATE phone_phones SET last_seen = CURRENT_TIMESTAMP WHERE phone_number = ?",
                    { existingNumber })
            end
        end
        return cb(existingNumber)
    end

    -- Unique phones enabled
    local lastNumber = MySQL.scalar.await("SELECT phone_number FROM phone_last_phone WHERE id = ?", { identifier })
    debugprint("result from phone_last_phone: ", lastNumber)

    if lastNumber then
        debugprint(("checking if %s has phone with metadata for last phone number equipped"):format(src))
        if HasPhoneItem(src, lastNumber) then
            debugprint(("%s has phone with metadata"):format(src))
            OnlineOwnersByNumber[lastNumber] = src
            MySQL.update("UPDATE phone_phones SET last_seen = CURRENT_TIMESTAMP WHERE phone_number = ?", { lastNumber })
            return cb(lastNumber)
        end
        debugprint(("%s doesn't have phone with metadata for last phone number equipped"):format(src))
        return cb()
    end

    debugprint(("checking if %s has an empty phone"):format(src))
    if not HasPhoneItem(src) then
        debugprint(("%s does not have an empty phone"):format(src))
        return cb()
    end

    debugprint(("%s does have an empty phone, checking if they have an existing phone from pre-unique phone"):format(src))
    local oldNumber = MySQL.scalar.await(
        "SELECT phone_number FROM phone_phones WHERE id = ? AND assigned = FALSE",
        { identifier }
    )

    if oldNumber and SetPhoneNumber(src, oldNumber) then
        debugprint(("%s does have an existing phone from pre-unique phone"):format(src))
        MySQL.update(
            "UPDATE phone_phones SET assigned = TRUE, last_seen = CURRENT_TIMESTAMP WHERE phone_number = ?",
            { oldNumber }
        )
        MySQL.update(
            "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?)",
            { identifier, oldNumber }
        )
        OnlineOwnersByNumber[oldNumber] = src
        return cb(oldNumber)
    end

    debugprint(("%s does not have an existing phone from pre-unique phone, or failed to set number to item metadata"):format(src))
    return cb()
end)

RegisterLegacyCallback("setLastPhone", function(src, cb, phoneNumber)
    local identifier = GetIdentifier(src)
    local equipped = GetEquippedPhoneNumber(src)

    SaveBattery(src)

    -- Clear last phone
    if not phoneNumber then
        MySQL.update("DELETE FROM phone_last_phone WHERE id = ?", { identifier })
        if equipped then
            OnlineOwnersByNumber[equipped] = nil
            local st = Player(src).state
            st.phoneOpen = false
            st.phoneName = nil
            st.phoneNumber = nil

            local cached = GetSettings(equipped)
            if cached then SetSettings(equipped, nil) end
        end
        return cb()
    end

    -- Prevent taking ownership if a different owner has it online
    local ownerSrc = OnlineOwnersByNumber[phoneNumber]
    if ownerSrc and ownerSrc ~= src then
        return cb()
    end

    -- Verify phone exists
    local exists = MySQL.scalar.await("SELECT 1 FROM phone_phones WHERE phone_number = ?", { phoneNumber })
    if not exists then
        infoprint(
            "warning",
            ("%s | %s tried to use a phone with a number that doesn't exist. This usually happens when you delete the phone from phone_phones, without deleting the phone item from the player's inventory. Phone number: %s")
                :format(GetPlayerName(src), src, phoneNumber)
        )
        return cb()
    end

    -- Upsert last phone mapping
    MySQL.update.await(
        "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
        { identifier, phoneNumber, phoneNumber }
    )

    -- Remove old mapping + cache
    if equipped then
        OnlineOwnersByNumber[equipped] = nil
        local prevCached = GetSettings(equipped)
        if prevCached then SetSettings(equipped, nil) end
    end

    -- Map new phone online
    OnlineOwnersByNumber[phoneNumber] = src
    cb()
end)

RegisterLegacyCallback("generatePhoneNumber", function(src, cb)
    local identifier = GetIdentifier(src)
    local recordId = identifier
    debugprint(GetPlayerName(src), src, identifier, "wants to generate a phone number")

    if Config.Item.Unique then
        debugprint(("unique phones enabled, checking if %s has a phone item without a number assigned"):format(GetPlayerName(src)))
        if not HasPhoneItem(src) then
            debugprint(("%s does not have a phone item without a number assigned"):format(GetPlayerName(src)))
            return cb()
        end
        recordId = GenerateId("phone_phones", "id")
    else
        local existing = MySQL.scalar.await("SELECT phone_number FROM phone_phones WHERE id = ?", { identifier })
        if existing then
            infoprint(
                "warning",
                ("%s wants to generate a phone number, but they already have one. Please set Config.Debug to true, and send the full log in customer-support if this happens again."):format(GetPlayerName(src))
            )
            OnlineOwnersByNumber[existing] = src
            return cb(existing)
        end
    end

    local newNumber = GeneratePhoneNumber()
    MySQL.update.await(
        "INSERT INTO phone_phones (id, owner_id, phone_number) VALUES (?, ?, ?)",
        { recordId, identifier, newNumber }
    )

    TriggerEvent("lb-phone:phoneNumberGenerated", src, newNumber)

    if Config.Item.Unique then
        SetPhoneNumber(src, newNumber)
        MySQL.update.await(
            "UPDATE phone_phones SET assigned = TRUE WHERE phone_number = ?",
            { newNumber }
        )
        MySQL.update.await(
            "INSERT INTO phone_last_phone (id, phone_number) VALUES (?, ?) ON DUPLICATE KEY UPDATE phone_number = ?",
            { GetIdentifier(src), newNumber, newNumber }
        )
    end

    OnlineOwnersByNumber[newNumber] = src
    cb(newNumber)
end)

RegisterLegacyCallback("getPhone", function(src, cb, phoneNumber)
    debugprint(GetPlayerName(src), "triggered phone:getPhone. checking if they have an item")
    if not HasPhoneItem(src, phoneNumber) then
        debugprint(GetPlayerName(src), "does not have an item")
        return cb()
    end

    debugprint(GetPlayerName(src), "has an item, getting phone data")
    local phone = MySQL.single.await(
        "SELECT owner_id, is_setup, settings, `name`, battery FROM phone_phones WHERE phone_number = ?",
        { phoneNumber }
    )
    if not phone then
        debugprint(GetPlayerName(src), "does not have any phone data")
        return cb()
    end

    if phone.settings then
        local cached = GetSettings(phoneNumber) or json.decode(phone.settings)
        phone.settings = cached
        if not GetSettings(phoneNumber) then
            SetSettings(phoneNumber, phone.settings)
        end
    end

    debugprint(GetPlayerName(src), "has phone data")

    if not phone.owner_id then
        debugprint(("%s's phone does not have an owner, setting owner to %s"):format(GetPlayerName(src), GetIdentifier(src)))
        MySQL.update(
            "UPDATE phone_phones SET owner_id = ? WHERE phone_number = ?",
            { GetIdentifier(src), phoneNumber }
        )
    end

    cb(phone)
end)

RegisterLegacyCallback("isAdmin", function(src, cb)
    local isAdmin, extra = IsAdmin(src)
    cb(isAdmin, extra)
end)

RegisterLegacyCallback("getCharacterName", function(src, cb)
    local firstname, lastname = GetCharacterName(src)
    cb({ firstname = firstname, lastname = lastname })
end)

-- =========================
-- Net Events
-- =========================

RegisterNetEvent("phone:finishedSetup", function(settings)
    local src = source
    local number = GetEquippedPhoneNumber(src)
    if not number then return end

    SetSettings(number, settings)
    MySQL.update(
        "UPDATE phone_phones SET is_setup = true, settings = ? WHERE phone_number = ?",
        { json.encode(settings), number }
    )

    if Config.AutoCreateEmail then
        GenerateEmailAccount(src, number)
    end
end)

RegisterNetEvent("phone:setName", function(name)
    local src = source
    local number = GetEquippedPhoneNumber(src)
    if not number then return end

    if Config.NameFilter then
        local ok = name:match(Config.NameFilter)
        if not ok then
            infoprint("warning", "Player " .. GetPlayerName(src) .. " tried to set an invalid phone name: " .. name)
            local fn, ln = GetCharacterName(src)
            name = L("BACKEND.MISC.X_PHONE", { name = fn, lastname = ln })
        end
    end

    MySQL.Async.execute(
        "UPDATE phone_phones SET `name`=@name WHERE phone_number=@phoneNumber",
        { ["@phoneNumber"] = number, ["@name"] = name }
    )

    if Config.Item.Unique and SetItemName then
        SetItemName(src, number, name)
    end

    local cached = GetSettings(number)
    if cached then cached.name = name end

    local st = Player(src).state
    st.phoneName = name
end)

-- BaseCallback used in original for settings writes
BaseCallback("setSettings", function(_, phoneNumber, settings)
    debugprint("setSettings", "saving settings for phone number", phoneNumber)
    DirtySettings[phoneNumber] = true
    SetSettings(phoneNumber, settings)

    if Config.CacheSettings == false then
        -- Write-through mode (no caching)
        MySQL.update(
            "UPDATE phone_phones SET settings = ? WHERE phone_number = ?",
            { json.encode(settings), phoneNumber }
        )
    end
end)

RegisterNetEvent("phone:togglePhone", function(isOpen, phoneName)
    local src = source
    local st = Player(src).state
    st.phoneOpen = isOpen

    local number = GetEquippedPhoneNumber(src)
    if not number then return end

    st.phoneName = phoneName
    st.phoneNumber = number
end)

RegisterNetEvent("phone:toggleFlashlight", function(enabled)
    local st = Player(source).state
    st.flashlight = enabled
end)

local function deletePhoneObjectFor(src)
    local netId = PhoneObjects[src]
    if netId then
        local ent = NetworkGetEntityFromNetworkId(netId)
        if ent then DeleteEntity(ent) end
        PhoneObjects[src] = nil
    end
end

RegisterNetEvent("phone:setPhoneObject", function(netId)
    local src = source

    if Config.ServerSideSpawn and not netId then
        if PhoneObjects[src] then
            debugprint("Deleting phone object for player " .. src)
            deletePhoneObjectFor(src)
        end
    end

    PhoneObjects[src] = netId
end)

-- =========================
-- Player/Resource Lifecycle
-- =========================

AddEventHandler("playerDropped", function()
    local src = source
    local number = GetEquippedPhoneNumber(src)

    deletePhoneObjectFor(src)

    if number then
        Wait(1000)
        SetSettings(number, nil)         -- flush & clear dirty
        OnlineOwnersByNumber[number] = nil
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for src, _ in pairs(PhoneObjects) do
        deletePhoneObjectFor(src)
    end

    SaveAllSettings()
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    SaveAllSettings()
end)

-- =========================
-- Factory Reset
-- =========================

---Factory reset a phone by number (server-side). Also notifies client if online.
---@param phoneNumber string
local function FactoryReset(phoneNumber)
    -- clear logged in accounts
    MySQL.update.await("DELETE FROM phone_logged_in_accounts WHERE phone_number = ?", { phoneNumber })

    -- reset phone flags & security
    local affected = MySQL.update.await(
        "UPDATE phone_phones SET is_setup = false, settings = NULL, pin = NULL, face_id = NULL WHERE phone_number = ?",
        { phoneNumber }
    ) > 0

    if affected then
        local ownerSrc = OnlineOwnersByNumber[phoneNumber]
        if ownerSrc then
            TriggerClientEvent("phone:factoryReset", ownerSrc)
            SetSettings(phoneNumber, nil)      -- flush & clear
            OnlineOwnersByNumber[phoneNumber] = nil
        end
    end
end

RegisterNetEvent("phone:factoryReset", function()
    local number = GetEquippedPhoneNumber(source)
    if not number then return end
    FactoryReset(number)
end)

exports("FactoryReset", FactoryReset)
