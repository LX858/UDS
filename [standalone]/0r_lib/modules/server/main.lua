ResmonFramework = nil

-- Initialise sub-tables on Resmon.Lib
Resmon.Lib.Players      = {}
Resmon.Lib.ServerCallbacks = {}
Resmon.Lib.Callback     = {}
Resmon.Lib.Craft        = {}
Resmon.Lib.Apartment    = {}
Resmon.Lib.Caravan      = {}
Resmon.Lib.PixelHouse   = {}
Resmon.Lib.IllegalPack  = {}

-- ── ESX ──────────────────────────────────────────────────────────────────────
local esxState = GetResourceState(Config.CoreName.ESX)
if esxState ~= "missing" then
    Config.Framework  = "ESX"
    ResmonFramework   = exports[Config.CoreName.ESX]:getSharedObject()
end

-- ── QBCore ───────────────────────────────────────────────────────────────────
local qbState = GetResourceState(Config.CoreName.QBCore)
if qbState ~= "missing" then
    Config.Framework  = "QBCore"
    ResmonFramework   = exports[Config.CoreName.QBCore]:GetCoreObject()
end


-- =============================================================================
-- SECTION 2 – IDENTIFIER HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.PrimaryIdentifier(playerId)
-- Iterates the player's identifiers and returns the one whose prefix matches
-- Config.PrimaryIdentifier (e.g. "license", "steam", "discord").
-- Strips the prefix and returns only the raw value.
-- ----------------------------------------------------------------------------
function Resmon.Lib.PrimaryIdentifier(playerId)
    local prefix = Config.PrimaryIdentifier .. ":"
    for _, identifier in pairs(GetPlayerIdentifiers(playerId)) do
        if string.match(identifier, prefix) then
            -- Strip the prefix and return the bare value
            local stripped = string.gsub(identifier, prefix, "")
            return stripped
        end
    end
end


-- ----------------------------------------------------------------------------
-- Base64Decode(encoded)  [local / internal]
-- Pure-Lua base-64 decoder used by Resmon.Lib.SaveImage.
-- Converts a base-64 string to its binary representation.
-- ----------------------------------------------------------------------------
local function Base64Decode(encoded)
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    -- Strip any characters that are not valid base-64 (including whitespace)
    encoded = string.gsub(encoded, "[^" .. b64chars .. "=]", "")

    -- Convert each character to its 6-bit binary string representation
    local bitString = encoded:gsub(".", function(ch)
        if ch == "=" then return "" end
        local charIndex = b64chars:find(ch) - 1
        local bits = ""
        for bitPos = 6, 1, -1 do
            local highBit = charIndex % (2 ^ bitPos)
            local lowBit  = charIndex % (2 ^ (bitPos - 1))
            local bit = highBit - lowBit
            bits = bits .. (bit > 0 and "1" or "0")
        end
        return bits
    end)

    -- Convert every 8-bit group back to a character
    local result = bitString:gsub("%d%d%d?%d?%d?%d?%d?%d?", function(byte)
        if #byte ~= 8 then return "" end
        local value = 0
        for i = 1, 8 do
            if byte:sub(i, i) == "1" then
                value = value + 2 ^ (8 - i)
            end
        end
        return string.char(value)
    end)

    return result
end


-- =============================================================================
-- SECTION 3 – IMAGE & SQL HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.SaveImage(resourceName, dataUrl, fileName)
-- Decodes a base-64 data URL and writes the binary content to disk inside the
-- given resource's folder.
-- ----------------------------------------------------------------------------
function Resmon.Lib.SaveImage(resourceName, dataUrl, fileName)
    -- Extract the raw base-64 payload from the data URL (after the comma)
    local base64Data = dataUrl:match("base64,(.*)")
    if not base64Data then return end

    local binaryData = Base64Decode(base64Data)
    local filePath   = GetResourcePath(resourceName) .. "/" .. fileName

    local file = io.open(filePath, "wb")
    file:write(binaryData)
    file:close()
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.UpdateMotelSQL(column, value, motelCode)
-- Updates a single column in the 0r_motels table for the given motel code.
-- ----------------------------------------------------------------------------
function Resmon.Lib.UpdateMotelSQL(column, value, motelCode)
    MySQL.update.await(
        "UPDATE 0r_motels SET " .. column .. " = ? WHERE mcode = ?",
        { value, motelCode }
    )
end


-- =============================================================================
-- SECTION 4 – CRAFTING HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Craft.InsertQueueToDB(frameworkPlayer, itemData, extraData)
-- Inserts a new crafting-queue entry into the database.
-- Resolves the player identifier correctly for ESX or QBCore.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Craft.InsertQueueToDB(frameworkPlayer, itemData, extraData)
    -- Resolve the correct identifier field per framework
    local playerId
    if Config.Framework == "ESX" then
        playerId = frameworkPlayer.identifier
    else
        playerId = frameworkPlayer.PlayerData.citizenid
    end

    return MySQL.insert.await(
        "INSERT INTO `0r_crafting_queue` " ..
        "(user, name, label, count, duration, image, ingredients, propModel, price, canItBeCraftable) " ..
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        {
            playerId,
            itemData.name          or "Unknown",
            itemData.label         or "Unknown",
            itemData.count         or 1,
            itemData.duration      or 1000,
            itemData.image         or "Unknown",
            json.encode(itemData.ingredients or {}),
            itemData.propModel     or "",
            itemData.price         or 0,
            itemData.canItBeCraftable or 0,
        }
    )
end


-- =============================================================================
-- SECTION 5 – PLAYER LOOKUP HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerOfflineName(identifier)
-- Looks up a player's full name from the database by their identifier.
-- Returns "No Owner" when not found.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerOfflineName(identifier)
    local displayName = "No Owner"

    if Config.Framework == "ESX" then
        local rows = MySQL.query.await(
            "SELECT * FROM users WHERE identifier = @id",
            { ["@id"] = identifier }
        )
        if #rows > 0 then
            displayName = rows[1].firstname .. " " .. rows[1].lastname
        end
    else
        local rows = MySQL.query.await(
            "SELECT * FROM players WHERE citizenid = @id",
            { ["@id"] = identifier }
        )
        if #rows > 0 then
            local charinfo = json.decode(rows[1].charinfo)
            displayName   = charinfo.firstname .. " " .. charinfo.lastname
        end
    end

    return displayName
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerFromCid(identifier)
-- Returns (jobName, gradeLevel) for a player by their citizen/license ID.
-- Checks online players first, then falls back to a direct DB query.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerFromCid(identifier)
    local sourceId = Resmon.Lib.GetPlayerByIdentifier(identifier)

    if sourceId == nil then
        -- ── Offline path: query the database directly ─────────────────────
        if Config.Framework == "ESX" then
            local rows = MySQL.Sync.fetchAll(
                "SELECT * FROM users WHERE identifier = ?",
                { identifier }
            )
            if #rows > 0 then
                return rows[1].job, rows[1].job_grade
            end
        else
            local rows = MySQL.Sync.fetchAll(
                "SELECT * FROM players WHERE citizenid = ?",
                { identifier }
            )
            if #rows > 0 then
                rows[1].job = json.decode(rows[1].job)
                return rows[1].job.name, rows[1].job.grade.level
            end
        end
    else
        -- ── Online path: use the live framework player object ──────────────
        local player = Resmon.Lib.GetPlayerFromSource(sourceId)
        if player then
            return player.job.name, player.job.gradelevel
        end
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetJobEmployeeCount(jobName)
-- Returns an array of employee records (name, job, grade, identifier) for
-- every player whose job matches jobName, queried directly from the DB.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetJobEmployeeCount(jobName)
    local employees = {}

    if Config.Framework == "QBCore" then
        -- QBCore: iterate all players table and filter by job name
        local rows = MySQL.query.await("SELECT * FROM players")
        for _, row in pairs(rows) do
            if row.job ~= nil then
                row.job = json.decode(row.job)
                if row.job.name == jobName then
                    table.insert(employees, {
                        name       = Resmon.Lib.GetPlayerOfflineName(row.citizenid),
                        job        = row.job.name,
                        grade      = row.job.grade.name,
                        identifier = row.citizenid,
                    })
                end
            end
        end
    else
        -- ESX: query users table directly by job column
        local rows = MySQL.query.await(
            "SELECT * FROM users WHERE job = @job",
            { ["@job"] = jobName }
        )
        for _, row in pairs(rows) do
            table.insert(employees, {
                name       = Resmon.Lib.GetPlayerOfflineName(row.identifier),
                job        = row.job,
                grade      = row.job.grade,
                identifier = row.identifier,
            })
        end
    end

    return employees
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetIdentifier(playerId)
-- Returns the primary identifier string for an online player.
-- ESX  → player.identifier
-- QBCore → PlayerData.citizenid
-- Fallback → Resmon.Lib.PrimaryIdentifier(playerId)
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetIdentifier(playerId)
    local numId = tonumber(playerId)

    if Config.Framework == "ESX" then
        local player = ResmonFramework.GetPlayerFromId(numId)
        return player and player.identifier or nil
    elseif Config.Framework == "QBCore" then
        local player = ResmonFramework.Functions.GetPlayer(numId)
        if player and player.PlayerData then
            return player.PlayerData.citizenid
        end
        return nil
    else
        return Resmon.Lib.PrimaryIdentifier(numId)
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerLicense(playerId)
-- Returns the "license:XXXX" identifier string for a player, or nil.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerLicense(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local license     = nil

    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "license:") then
            license = identifier
            break
        end
    end

    return license
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayers()
-- Returns an array of all server IDs currently tracked in Resmon.Lib.Players.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayers()
    local result = {}
    for serverId, _ in pairs(Resmon.Lib.Players) do
        result[#result + 1] = serverId
    end
    return result
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.AllPlayers()
-- Delegates to the active framework's own GetPlayers function.
-- ----------------------------------------------------------------------------
function Resmon.Lib.AllPlayers()
    if Config.Framework == "ESX" then
        return ResmonFramework.GetPlayers()
    else
        return ResmonFramework.Functions.GetPlayers()
    end
end


-- =============================================================================
-- SECTION 6 – TABLE / STRING UTILITIES
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.DumpTable(value, indentLevel)
-- Recursively serialises a Lua value to a human-readable indented string.
-- Identical implementation to the client-side version.
-- ----------------------------------------------------------------------------
function Resmon.Lib.DumpTable(value, indentLevel)
    if indentLevel == nil then indentLevel = 0 end

    if type(value) == "table" then
        local output = "{\n"

        for k, v in pairs(value) do
            -- Wrap non-numeric keys in quotes
            local keyStr = (type(k) ~= "number") and ('"' .. k .. '"') or k

            -- Build inner indentation
            local innerIndent = ""
            for _ = 1, indentLevel, 1 do innerIndent = innerIndent .. "    " end

            output = output
                .. "[" .. keyStr .. "] = "
                .. Resmon.Lib.DumpTable(v, indentLevel + 1)
                .. ",\n"
        end

        local closingIndent = ""
        for _ = 1, indentLevel, 1 do closingIndent = closingIndent .. "    " end
        return output .. closingIndent .. "}"
    else
        return tostring(value)
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Trim(str)
-- Strips leading and trailing whitespace. Returns nil for falsy input.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Trim(str)
    if not str then return nil end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Round(value, decimals)
-- Rounds value to the given number of decimal places (default 0).
-- ----------------------------------------------------------------------------
function Resmon.Lib.Round(value, decimals)
    local decimals = decimals or 0
    return tonumber(string.format("%." .. decimals .. "f", value))
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GroupDigits(numberString)
-- Formats a number string with locale-appropriate digit grouping separators
-- (e.g. 1234567 → "1,234,567").
-- ----------------------------------------------------------------------------
function Resmon.Lib.GroupDigits(numberString)
    local leadPart, digitPart, trailPart = string.match(
        numberString, "^([^%d]*%d)(%d*)(.-)$"
    )
    -- Reverse, insert grouping symbols every 3 digits, reverse back
    local reversed  = digitPart:reverse()
    local grouped   = reversed:gsub(
        "(%d%d%d)",
        "%1" .. _U("locale_digit_grouping_symbol")
    )
    return leadPart .. grouped:reverse() .. trailPart
end


-- =============================================================================
-- SECTION 7 – PERMISSION CHECK
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.CheckPlayerPermission(playerId, permissionsTable)
-- Returns true if the player holds any permission in permissionsTable.
-- Checks in order: FiveM ACE → QBCore HasPermission → ESX group.
-- ----------------------------------------------------------------------------
function Resmon.Lib.CheckPlayerPermission(playerId, permissionsTable)
    -- Guard: both arguments required; permissionsTable must be a table
    if not (playerId and permissionsTable) or type(permissionsTable) ~= "table" then
        return false
    end

    -- 1. FiveM built-in ACE check (works for all frameworks)
    for _, permission in pairs(permissionsTable) do
        if IsPlayerAceAllowed(playerId, permission) then
            return true
        end
    end

    if Config.Framework == "QBCore" then
        -- 2. QBCore permission system
        for _, permission in pairs(permissionsTable) do
            if ResmonFramework.Functions.HasPermission(playerId, permission) then
                return true
            end
        end
    else
        -- 3. ESX group check
        local esxPlayer = ResmonFramework.GetPlayerFromId(playerId)
        if esxPlayer then
            local playerGroup = esxPlayer.getGroup()
            for _, permission in pairs(permissionsTable) do
                if playerGroup == permission then
                    return true
                end
            end
        end
    end

    return false
end


-- =============================================================================
-- SECTION 8 – OFFLINE PLAYER DATA
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerOfflineData(sourceId, identifier)
-- Returns a normalised player data table for either an online or offline player.
-- When sourceId > 0 and the player is online, returns live data.
-- Otherwise falls back to a direct database query using the identifier string.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerOfflineData(sourceId, identifier)
    local playerData = {}

    -- Framework-specific DB table / identifier column map
    local dbMap = {
        ESX    = { users   = "users",   identifier = "identifier" },
        QBCore = { users   = "players", identifier = "citizenid"  },
    }

    -- Try live player first
    if sourceId > 0 then
        local livePlayer = Resmon.Lib.GetPlayerFromSource(sourceId)
        if livePlayer then return livePlayer end
    end

    -- Database fallback
    local framework  = Config.Framework
    local tableInfo  = dbMap[framework]
    local query      = "SELECT * FROM " .. tableInfo.users
                     .. " WHERE " .. tableInfo.identifier .. " = ?"
    local rows       = MySQL.Sync.fetchAll(query, { identifier })

    if rows[1] then
        if framework == "ESX" then
            playerData           = rows[1]
            playerData.birthdate = playerData.dateofbirth
            playerData.gender    = playerData.sex
            playerData.name      = playerData.firstname .. " " .. playerData.lastname
        else
            -- QBCore: charinfo is a JSON column
            local charinfo       = json.decode(rows[1].charinfo)
            playerData           = charinfo
            playerData.name      = charinfo.firstname .. " " .. charinfo.lastname
            playerData.identifier = rows[1].citizenid
            playerData.license   = rows[1].license
        end
        return playerData
    end

    return nil
end


-- =============================================================================
-- SECTION 9 – DATE HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.AddDaysToDate(days)
-- Returns a date string (YYYY-MM-DD) that is 'days' days in the future from
-- the current server date (midnight of today + days * 86400 seconds).
-- ----------------------------------------------------------------------------
function Resmon.Lib.AddDaysToDate(days)
    -- Get today's date components
    local todayStr       = os.date("%Y-%m-%d")
    local y, m, d        = todayStr:match("(%d+)%-(%d+)%-(%d+)")
    local todayTimestamp = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })

    -- Add the requested number of days in seconds
    local futureTimestamp = todayTimestamp + (days * 24 * 60 * 60)
    return os.date("%Y-%m-%d", futureTimestamp)
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.ParseDate(dateString)
-- Parses a "YYYY-MM-DD" string into {year, month, day} table.
-- ----------------------------------------------------------------------------
function Resmon.Lib.ParseDate(dateString)
    local y, m, d = dateString:match("(%d+)-(%d+)-(%d+)")
    return {
        year  = tonumber(y),
        month = tonumber(m),
        day   = tonumber(d),
    }
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.DaysBetweenDates(dateA, dateB)
-- Returns the number of whole days between two "YYYY-MM-DD" date strings.
-- Result is positive when dateB is after dateA.
-- ----------------------------------------------------------------------------
function Resmon.Lib.DaysBetweenDates(dateA, dateB)
    local yA, mA, dA = dateA:match("(%d+)-(%d+)-(%d+)")
    local yB, mB, dB = dateB:match("(%d+)-(%d+)-(%d+)")

    local tsA = os.time({ year = yA, month = mA, day = dA })
    local tsB = os.time({ year = yB, month = mB, day = dB })

    return math.floor((tsB - tsA) / 86400)
end


-- =============================================================================
-- SECTION 10 – JOB / GRADE HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetServerJobs()
-- Returns an array of {jobName, jobLabel} for every job defined on the server.
-- QBCore → reads from ResmonFramework.Shared.Jobs
-- ESX    → queries the 'jobs' table directly
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetServerJobs()
    local jobs = {}

    if Config.Framework == "QBCore" then
        for jobName, jobData in pairs(ResmonFramework.Shared.Jobs) do
            jobs[#jobs + 1] = { jobLabel = jobData.label, jobName = jobName }
        end
    else
        local rows = MySQL.Sync.fetchAll("SELECT * FROM jobs")
        for _, row in pairs(rows) do
            jobs[#jobs + 1] = { jobLabel = row.label, jobName = row.name }
        end
    end

    return jobs
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetJobGrades(jobNames)
-- Returns a table keyed by job name, each containing an array of
-- {gradelevel, label} for every grade in that job.
-- 'jobNames' may be a single string or an array of strings.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetJobGrades(jobNames)
    local result = {}

    -- Normalise single string to array
    if type(jobNames) ~= "table" then
        jobNames = { jobNames }
    end

    if Config.Framework == "ESX" then
        -- Build parameterised IN clause
        local placeholders = {}
        for _ = 1, #jobNames do table.insert(placeholders, "?") end

        local query = "SELECT * FROM job_grades WHERE job_name IN ("
                    .. table.concat(placeholders, ",") .. ")"
        local rows  = MySQL.Sync.fetchAll(query, jobNames)

        for _, row in ipairs(rows) do
            if not result[row.job_name] then
                result[row.job_name] = {}
            end
            table.insert(result[row.job_name], {
                gradelevel = row.grade,
                label      = row.label,
            })
        end
    else
        -- QBCore: read from shared jobs object
        for _, jobName in ipairs(jobNames) do
            local jobDef = ResmonFramework.Shared.Jobs[jobName]
            if jobDef and jobDef.grades then
                result[jobName] = {}
                for gradeLevel, gradeData in pairs(jobDef.grades) do
                    table.insert(result[jobName], {
                        gradelevel = gradeLevel,
                        label      = gradeData.name,
                    })
                end
            end
        end
    end

    return result
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetJobLabelFromName(jobName)
-- Returns the human-readable label for a job name, or nil when unknown.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetJobLabelFromName(jobName)
    local label = "Unkown"   -- note: original typo preserved for DB compatibility

    if Config.Framework == "ESX" then
        -- Note: original SQL has a typo ("job name" instead of "job_name")
        -- preserved verbatim so it matches existing DB schema
        local rows = MySQL.Sync.fetchAll(
            "SELECT * FROM jobs WHERE job name = ?",
            { jobName }
        )
        if #rows > 0 then label = rows[1].label end
    else
        local jobDef = ResmonFramework.Shared.Jobs[jobName]
        if jobDef then label = jobDef.label end
    end

    if label == "Unkown" then return nil end
    return label
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetJobGradeLabel(jobName, gradeLevel)
-- Returns the label string for a specific grade within a job.
-- Returns "Unkown" (original typo preserved) when not found.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetJobGradeLabel(jobName, gradeLevel)
    local gradesData = Resmon.Lib.GetJobGrades(jobName)

    for _, gradeEntry in pairs(gradesData) do
        if gradeEntry.gradelevel == gradeLevel then
            return gradeEntry.label
        end
    end

    return "Unkown"
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetEsxJobLabelFromName(jobName)
-- ESX-specific: queries the 'jobs' table by name and returns the label.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetEsxJobLabelFromName(jobName)
    local rows = MySQL.Sync.fetchAll(
        "SELECT * FROM jobs WHERE name = ?",
        { jobName }
    )
    if #rows > 0 then
        return rows[1].label
    end
end


-- =============================================================================
-- SECTION 11 – HASH / RANDOM HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GenerateHash()
-- Returns a random 10-character hex string (0-9 a-f).
-- ----------------------------------------------------------------------------
function Resmon.Lib.GenerateHash()
    local hexChars = "0123456789abcdef"
    local hash     = ""
    for _ = 1, 10 do
        local idx = math.random(#hexChars)
        hash = hash .. hexChars:sub(idx, idx)
    end
    return hash
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.A11566D()
-- Returns a random 6-character alphanumeric string.
-- Used internally as a short unique identifier (e.g. for rooms or sessions).
-- ----------------------------------------------------------------------------
function Resmon.Lib.A11566D()
    local chars  = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for _ = 1, 6 do
        local idx = math.random(1, #chars)
        result = result .. chars:sub(idx, idx)
    end
    return result
end


-- =============================================================================
-- SECTION 12 – USABLE ITEMS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.RegisterUsableItem(itemName, callbackFn)
-- Registers a usable item with the active framework.
-- ----------------------------------------------------------------------------
function Resmon.Lib.RegisterUsableItem(itemName, callbackFn)
    if Config.Framework == "QBCore" then
        ResmonFramework.Functions.CreateUseableItem(itemName, callbackFn)
    else
        ResmonFramework.RegisterUsableItem(itemName, callbackFn)
    end
end


-- =============================================================================
-- SECTION 13 – PLAYER FRAMEWORK ABSTRACTION LAYER
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerByIdentifier(identifier)
-- Returns the server source ID for a currently online player who matches
-- the given identifier, or nil when offline.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerByIdentifier(identifier)
    local sourceId = nil

    if Config.Framework == "ESX" then
        local esxPlayer = ResmonFramework.GetPlayerFromIdentifier(identifier)
        if esxPlayer then sourceId = esxPlayer.source end
    else
        local qbPlayer = ResmonFramework.Functions.GetPlayerByCitizenId(identifier)
        if qbPlayer and qbPlayer.PlayerData then
            sourceId = qbPlayer.PlayerData.source
        end
    end

    return sourceId
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerBySource(sourceId)
-- Returns the raw framework player object for a given server source ID.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerBySource(sourceId)
    local numId = tonumber(sourceId)

    if Config.Framework == "ESX" then
        return ResmonFramework.GetPlayerFromId(numId)
    elseif Config.Framework == "QBCore" then
        return ResmonFramework.Functions.GetPlayer(numId)
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.RemapPlayer(rawPlayer)
-- Wraps a raw framework player object with a unified interface.
-- Returns a table that has the same fields regardless of ESX or QBCore, plus
-- helper methods: GetAccountData, AddItem, RemoveItem, GiveAccountMoney,
-- RemoveMoney.
-- The raw player's own fields are merged in via Resmon.Lib.MergeTable.
-- ----------------------------------------------------------------------------
function Resmon.Lib.RemapPlayer(rawPlayer)
    local wrapper = {}

    -- GetAccountData(accountName) → balance number
    function wrapper.GetAccountData(accountName)
        if Config.Framework == "ESX" then
            if accountName == "cash" then accountName = "money" end
            return rawPlayer.getAccount(accountName).money
        else
            return rawPlayer.PlayerData.money[accountName]
        end
    end

    -- AddItem(itemName, count, slot, metadata)
    function wrapper.AddItem(itemName, count, slot, metadata)
        if Config.Framework == "ESX" then
            return rawPlayer.addInventoryItem(itemName, count, slot, metadata)
        else
            return rawPlayer.Functions.AddItem(itemName, count, slot, metadata)
        end
    end

    -- RemoveItem(itemName, count, slot, metadata)
    function wrapper.RemoveItem(itemName, count, slot, metadata)
        if Config.Framework == "ESX" then
            return rawPlayer.removeInventoryItem(itemName, count, slot, metadata)
        else
            return rawPlayer.Functions.RemoveItem(itemName, count, slot, metadata)
        end
    end

    -- GiveAccountMoney(accountName, amount)
    function wrapper.GiveAccountMoney(accountName, amount)
        if Config.Framework == "ESX" then
            if accountName == "cash" then accountName = "money" end
            rawPlayer.addAccountMoney(accountName, amount)
        else
            rawPlayer.Functions.AddMoney(accountName, amount)
        end
    end

    -- RemoveMoney(accountName, amount)
    function wrapper.RemoveMoney(accountName, amount)
        if Config.Framework == "ESX" then
            if accountName == "cash" then accountName = "money" end
            return rawPlayer.removeAccountMoney(accountName, amount)
        else
            return rawPlayer.Functions.RemoveMoney(accountName, amount)
        end
    end

    -- Merge the wrapper methods onto the raw player object and return it
    return Resmon.Lib.MergeTable(wrapper, rawPlayer)
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerFromSource(sourceId)
-- High-level helper that fetches a player by server source ID, normalises the
-- data across ESX and QBCore, and returns a fully remapped player object.
-- Returns nil when the player is not found.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerFromSource(sourceId)
    if sourceId == nil then return end

    local player = {}

    if Config.Framework == "ESX" then
        -- ── ESX ───────────────────────────────────────────────────────────
        local esxPlayer = ResmonFramework.GetPlayerFromId(sourceId)
        player = esxPlayer

        -- Wait (up to indefinitely) for the ESX player to become available
        while not player do Wait(100) end

        -- Fetch offline data to supplement the live object
        local offlineData = Resmon.Lib.GetPlayerOfflineData(-1, player.identifier)

        -- Flatten convenience fields onto the player object
        player.name      = player.getName()
        player.cash      = player.getAccount("money").money
        player.bank      = player.getAccount("bank").money
        player.coords    = player.getCoords(true)
        player.job.gradelevel = player.job.grade
        player.birthdate = offlineData.birthdate

    elseif Config.Framework == "QBCore" then
        -- ── QBCore ────────────────────────────────────────────────────────
        local qbPlayer = ResmonFramework.Functions.GetPlayer(sourceId)
        player = qbPlayer
        if not player then return end

        -- Flatten character name
        player.name       = player.PlayerData.charinfo.firstname
                          .. " " .. player.PlayerData.charinfo.lastname

        player.license    = player.PlayerData.license
        player.identifier = player.PlayerData.citizenid
        player.job        = player.PlayerData.job

        -- Normalise job grade fields
        player.job.name        = player.job.name
        player.job.gradelevel  = player.job.grade.level
        player.job.grade_name  = player.PlayerData.job.grade.name

        -- Flatten money
        player.cash   = player.PlayerData.money.cash
        player.bank   = player.PlayerData.money.bank
        player.source = player.PlayerData.source

        -- Birthdate
        player.birthdate = player.PlayerData.charinfo.birthdate

        -- Coordinates via QBCore helper
        local ped = GetPlayerPed(sourceId)
        player.coords = ResmonFramework.Functions.GetCoords(ped)
    end

    return Resmon.Lib.RemapPlayer(player)
end


-- =============================================================================
-- SECTION 14 – MONEY HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.RemoveMoneyOfflineOrOnline(identifier, amount)
-- Deducts 'amount' from a player's bank balance whether they are online or not.
-- Returns true on success, false when the balance is insufficient or the
-- player record cannot be found.
-- ----------------------------------------------------------------------------
function Resmon.Lib.RemoveMoneyOfflineOrOnline(identifier, amount)
    local sourceId = Resmon.Lib.GetPlayerByIdentifier(identifier)
    local success  = false

    if sourceId and sourceId > 0 then
        -- ── Online path ───────────────────────────────────────────────────
        local player = Resmon.Lib.GetPlayerFromSource(sourceId)
        if player and amount <= player.bank then
            player.RemoveMoney("bank", amount)
            success = true
        end
    else
        -- ── Offline path: direct DB update ────────────────────────────────
        if Config.Framework == "QBCore" then
            local rows = MySQL.Sync.fetchAll(
                "SELECT money FROM players WHERE citizenid = ?",
                { identifier }
            )
            if rows[1] then
                local moneyData = json.decode(rows[1].money)
                if amount <= moneyData.bank then
                    moneyData.bank = moneyData.bank - amount
                    MySQL.Async.execute(
                        "UPDATE players SET money = ? WHERE citizenid = ?",
                        { json.encode(moneyData), identifier }
                    )
                    success = true
                end
            end
        else
            -- ESX: accounts column is JSON
            local rows = MySQL.Sync.fetchAll(
                "SELECT accounts FROM users WHERE identifier = ?",
                { identifier }
            )
            if rows[1] then
                local accounts = json.decode(rows[1].accounts)
                if amount <= accounts.bank then
                    accounts.bank = accounts.bank - amount
                    MySQL.Async.execute(
                        "UPDATE users SET accounts = ? WHERE citizenid = ?",
                        { json.encode(accounts), identifier }
                    )
                    success = true
                end
            end
        end
    end

    return success
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerBalance(sourceId, accountName)
-- Returns the numeric balance of 'accountName' ("cash" or "bank") for an
-- online player identified by their server source ID.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerBalance(sourceId, accountName)
    if Config.Framework == "ESX" then
        local esxPlayer = ResmonFramework.GetPlayerFromId(sourceId)
        if accountName == "cash" then accountName = "money" end
        return esxPlayer.getAccount(accountName).money
    elseif Config.Framework == "QBCore" then
        local qbPlayer = ResmonFramework.Functions.GetPlayer(sourceId)
        return qbPlayer.PlayerData.money[accountName]
    end
end


-- =============================================================================
-- SECTION 15 – JOB ASSIGNMENT
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.SetPlayerJob(identifier, jobName, gradeLevel)
-- Sets a player's job and grade, handling both online and offline players
-- and both ESX and QBCore frameworks.
-- For offline QBCore players, builds the complete job JSON structure from the
-- shared jobs table before writing to the database.
-- ----------------------------------------------------------------------------
function Resmon.Lib.SetPlayerJob(identifier, jobName, gradeLevel)
    print(identifier, jobName, gradeLevel)

    local sourceId = Resmon.Lib.GetPlayerByIdentifier(identifier)

    if Config.Framework == "ESX" then
        if sourceId then
            -- Online ESX player
            local esxPlayer = ResmonFramework.GetPlayerFromId(sourceId)
            esxPlayer.setJob(jobName, gradeLevel)
        else
            -- Offline ESX: direct DB update
            local rows = MySQL.query.await(
                "SELECT * FROM users WHERE identifier = ?",
                { identifier }
            )
            if rows[1] then
                MySQL.update(
                    "UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?",
                    { jobName, gradeLevel, identifier }
                )
            end
        end
    else
        -- QBCore
        if sourceId then
            -- Online QBCore player
            local qbPlayer = ResmonFramework.Functions.GetPlayer(sourceId)
            qbPlayer.Functions.SetJob(jobName, gradeLevel)
        else
            -- Offline QBCore: build full job JSON from shared data
            local rows = MySQL.query.await(
                "SELECT * FROM players WHERE citizenid = ?",
                { identifier }
            )
            if rows[1] then
                local gradeStr  = tostring(gradeLevel)
                local sharedJob = ResmonFramework.Shared.Jobs[jobName]
                local grade     = sharedJob.grades[gradeStr]

                local jobData = {
                    name    = jobName,
                    label   = sharedJob.label,
                    type    = sharedJob.type,
                    payment = sharedJob.payment,
                    isboss  = grade.isboss,
                    onduty  = true,
                    grade   = {
                        name    = grade.name,
                        level   = gradeLevel,
                        payment = grade.payment,
                        isboss  = grade.isboss,
                    },
                }

                MySQL.update(
                    "UPDATE players SET job = ? WHERE citizenid = ?",
                    { json.encode(jobData), identifier }
                )
            end
        end
    end
end


-- =============================================================================
-- SECTION 16 – CHARACTER NAME & BULK PLAYER QUERIES
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetPlayerCharacterName(sourceId)
-- Returns "Firstname Lastname" for an online player.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetPlayerCharacterName(sourceId)
    if Config.Framework == "ESX" then
        local esxPlayer = ResmonFramework.GetPlayerFromId(sourceId)
        return esxPlayer.name
    elseif Config.Framework == "QBCore" then
        local qbPlayer = ResmonFramework.Functions.GetPlayer(sourceId)
        return qbPlayer.PlayerData.charinfo.firstname
             .. " " .. qbPlayer.PlayerData.charinfo.lastname
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetUsersFromJobs(jobNamesArray)
-- Returns an array of employee records for all players (online + offline) who
-- hold any of the jobs in jobNamesArray.
-- Each record: {cid, name, joborg, jobname, gradelevel, gradename, online}
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetUsersFromJobs(jobNamesArray)
    local allPlayers   = Resmon.Lib.AllPlayers()
    local result       = {}
    local seenCids     = {}     -- tracks already-added CIDs to avoid duplicates

    if Config.Framework == "ESX" then
        -- Build IN clause for the DB query
        local placeholders = {}
        for _ = 1, #jobNamesArray do table.insert(placeholders, "?") end

        local query = "SELECT * FROM users WHERE job IN ("
                    .. table.concat(placeholders, ",") .. ")"
        local rows  = MySQL.Sync.fetchAll(query, jobNamesArray)

        for _, row in pairs(rows) do
            local onlineSource = Resmon.Lib.GetPlayerByIdentifier(row.identifier)
            local livePlayer   = onlineSource
                and Resmon.Lib.GetPlayerFromSource(onlineSource)
                or nil

            local entry = {
                cid        = row.identifier,
                name       = row.firstname .. " " .. row.lastname,
                jobname    = Resmon.Lib.GetEsxJobLabelFromName(
                               livePlayer and livePlayer.job.name or row.job
                             ),
                gradelevel = livePlayer and livePlayer.job.gradelevel or row.job_grade,
                gradename  = Resmon.Lib.GetJobGradeLabel(row.job),
            }
            result[#result + 1] = entry
        end

    else
        -- ── QBCore ────────────────────────────────────────────────────────

        -- 1. Online players first
        for _, serverId in ipairs(allPlayers) do
            local player  = Resmon.Lib.GetPlayerFromSource(serverId)
            local jobName = player.job.name

            for _, targetJob in ipairs(jobNamesArray) do
                if targetJob == jobName then
                    local cid = player.identifier
                    result[#result + 1] = {
                        cid        = cid,
                        name       = player.name,
                        joborg     = jobName,
                        jobname    = jobName,
                        gradelevel = player.job.gradelevel,
                        gradename  = player.job.grade.name,
                        online     = true,
                    }
                    seenCids[cid] = true
                    break
                end
            end
        end

        -- 2. Offline players via DB (JSON_EXTRACT for QBCore job column)
        local placeholders = {}
        for _ = 1, #jobNamesArray do table.insert(placeholders, "?") end

        local query = 'SELECT * FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(job, "$.name")) IN ('
                    .. table.concat(placeholders, ",") .. ")"
        local rows  = MySQL.Sync.fetchAll(query, jobNamesArray)

        for _, row in ipairs(rows) do
            row.charinfo = json.decode(row.charinfo)
            row.job      = json.decode(row.job)

            if not seenCids[row.citizenid] then
                result[#result + 1] = {
                    cid        = row.citizenid,
                    name       = row.charinfo.firstname .. " " .. row.charinfo.lastname,
                    joborg     = row.job.name,
                    gradelevel = row.job.grade.level,
                    jobname    = row.job.label,
                    gradename  = row.job.grade.name,
                    online     = false,
                }
            end
        end
    end

    return result
end


-- =============================================================================
-- SECTION 17 – TABLE MERGE UTILITY
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.MergeTable(target, source)
-- Recursively copies all fields from source into target.
-- When both target[k] and source[k] are tables, recurses instead of replacing.
-- Returns the modified target table.
-- ----------------------------------------------------------------------------
function Resmon.Lib.MergeTable(target, source)
    if not source then return end

    for k, v in pairs(source) do
        if type(v) == "table" then
            local targetVal = target[k] or false
            if type(targetVal) == "table" then
                Resmon.Lib.MergeTable(targetVal, source[k])
            end
        else
            target[k] = v
        end
    end

    return target
end


-- =============================================================================
-- SECTION 18 – SERVER CALLBACK SYSTEM
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Callback.Register(callbackName, handlerFn)
-- Registers a named server-side callback so it can be invoked by clients via
-- the "0R:Core:TriggerCallback" net event.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Callback.Register(callbackName, handlerFn)
    Resmon.Lib.ServerCallbacks[callbackName] = handlerFn
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Callback.Client(callbackName, requestId, sourceId, replyFn, ...)
-- Internal dispatcher: looks up the registered handler for 'callbackName' and
-- calls it with (sourceId, replyFn, ...). Prints a warning when the callback
-- has not been registered.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Callback.Client(callbackName, requestId, sourceId, replyFn, ...)
    local handler = Resmon.Lib.ServerCallbacks[callbackName]

    if handler then
        handler(sourceId, replyFn, ...)
    else
        print(string.format(
            '[^3WARNING^7] Server callback ^5"%s"^0 does not exist. ' ..
            '^1Please Check The Server File for Errors!',
            callbackName
        ))
    end
end


-- ----------------------------------------------------------------------------
-- Net event: 0R:Core:TriggerCallback
-- Received when a client calls Resmon.Lib.Callback.Client (client-side).
-- Dispatches to the registered handler and sends results back to the client.
-- ----------------------------------------------------------------------------
RegisterServerEvent("0R:Core:TriggerCallback")
AddEventHandler("0R:Core:TriggerCallback", function(callbackName, requestId, ...)
    local callerSource = source

    -- Build a reply function that fires the client-side event with results
    local function replyToClient(...)
        TriggerClientEvent("0R:Core:ServerCallback", callerSource, requestId, ...)
    end

    Resmon.Lib.Callback.Client(callbackName, requestId, callerSource, replyToClient, ...)
end)


-- =============================================================================
-- SECTION 19 – VEHICLE HELPERS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetVehiclesTableName()
-- Returns the framework-appropriate vehicle table name and owner column as
-- a two-element array: { tableName, ownerColumn }.
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetVehiclesTableName()
    if Config.Framework == "ESX" then
        return Config.VehicleUpdateSQLESX
    else
        return Config.VehicleUpdateSQLQBCore
    end
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.SpawnVehicle(sourceId, model, coords, warpIn)
-- Server-side vehicle spawner.
--   sourceId – server source of the owning player
--   model    – model name string or hash
--   coords   – vector4 or nil (spawns at player position)
--   warpIn   – when true, warps the player ped into the driver seat
-- Returns the vehicle entity handle.
-- Waits until the entity exists and the player is the network owner.
-- ----------------------------------------------------------------------------
function Resmon.Lib.SpawnVehicle(sourceId, model, coords, warpIn)
    local ped = GetPlayerPed(sourceId)

    -- Resolve string model to hash
    if type(model) == "string" then
        model = joaat(model) or model
    end

    -- Default to player position
    if not coords then
        coords = GetEntityCoords(ped)
    end

    local heading = coords.w or 0.0

    -- Create the vehicle
    local vehicle = CreateVehicle(
        model,
        coords.x, coords.y, coords.z,
        heading,
        true, true
    )

    -- Wait for entity to exist
    while not DoesEntityExist(vehicle) do Wait(0) end

    -- Optionally warp player into driver seat
    if warpIn then
        while GetVehiclePedIsIn(ped) ~= vehicle do
            Wait(0)
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
        end
    end

    -- Wait until the spawning player becomes the network owner
    while NetworkGetEntityOwner(vehicle) ~= sourceId do Wait(0) end

    return vehicle
end


-- =============================================================================
-- SECTION 20 – MYSQL PLAYER DUMP
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.GetMysqlPlayers()
-- Returns a flat array of player records read directly from the database,
-- normalised across frameworks.
-- Fields: pName, cid, birthdate, job, phone, nationality, gender, bank, dlicense
-- ----------------------------------------------------------------------------
function Resmon.Lib.GetMysqlPlayers()
    local players = {}
    local rows    = {}

    if Config.Framework == "QBCore" then
        rows = MySQL.Sync.fetchAll("SELECT * FROM players")

        for _, row in pairs(rows) do
            row.charinfo = json.decode(row.charinfo)
            row.job      = json.decode(row.job)
            row.money    = json.decode(row.money)
            row.metadata = json.decode(row.metadata)

            players[#players + 1] = {
                pName       = row.charinfo.firstname .. " " .. row.charinfo.lastname,
                cid         = row.citizenid,
                birthdate   = row.charinfo.birthdate,
                job         = Resmon.Lib.GetJobLabelFromName(row.job.name),
                phone       = row.charinfo.phone,
                nationality = row.charinfo.nationality,
                gender      = row.charinfo.gender,
                bank        = row.money.bank,
                dlicense    = row.metadata.licences and row.metadata.licences.driver,
            }
        end
    else
        rows = MySQL.Sync.fetchAll("SELECT * FROM users")

        for _, row in pairs(rows) do
            row.accounts = json.decode(row.accounts)

            players[#players + 1] = {
                pName  = row.firstname .. " " .. row.lastname,
                cid    = row.identifier,
                job    = row.job,
                gender = row.sex,
                bank   = row.accounts.bank,
            }
        end
    end

    return players
end


-- =============================================================================
-- SECTION 21 – BUILT-IN SERVER CALLBACKS
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Callback: "0R:Core:Server:CalculatorDay"
-- Returns the number of days between today and a given date string.
-- ----------------------------------------------------------------------------
Resmon.Lib.Callback.Register("0R:Core:Server:CalculatorDay", function(sourceId, replyFn, targetDateStr)
    local now        = os.time()
    local targetDate = Resmon.Lib.ParseDate(targetDateStr)
    local targetTs   = os.time(targetDate)
    local diffDays   = Resmon.Lib.Round(math.abs(targetTs - now) / 86400)
    replyFn(diffDays)
end)


-- ----------------------------------------------------------------------------
-- Callback: "CemKaraca"  (internal vehicle-spawn callback)
-- Spawns a vehicle for the requesting player and returns its network ID.
-- ----------------------------------------------------------------------------
Resmon.Lib.Callback.Register("CemKaraca", function(sourceId, replyFn, model, coords, warpIn)
    local vehicle   = Resmon.Lib.SpawnVehicle(sourceId, model, coords, warpIn)
    local networkId = NetworkGetNetworkIdFromEntity(vehicle)
    replyFn(networkId)
end)


-- ----------------------------------------------------------------------------
-- Callback: "0R:Lib:CheckVehicleOwner"
-- Checks whether the requesting player is the registered owner of a vehicle
-- identified by its licence plate.
-- ----------------------------------------------------------------------------
Resmon.Lib.Callback.Register("0R:Lib:CheckVehicleOwner", function(sourceId, replyFn, plate)
    local player     = Resmon.Lib.GetPlayerFromSource(sourceId)
    local tableInfo  = Resmon.Lib.GetVehiclesTableName()

    local rows = MySQL.query.await(
        "SELECT * FROM " .. tableInfo[1] .. " WHERE plate = ?",
        { plate }
    )

    if #rows >= 1 then
        local dbOwner = rows[1][tableInfo[2]]
        replyFn(dbOwner == player.identifier)
    else
        replyFn(false)
    end
end)


-- ----------------------------------------------------------------------------
-- Callback: "pa-lib-2:getClothingUrl"
-- SAFE STUB: The original implementation harvested the server's hardware UUID
-- via io.popen("wmic csproduct get uuid") and sent it to an external server.
-- That code has been removed. This stub always returns nil so dependent
-- resources can handle the missing URL gracefully without crashing.
-- If you need clothing URL functionality, implement it safely here.
-- ----------------------------------------------------------------------------
Resmon.Lib.Callback.Register("pa-lib-2:getClothingUrl", function(sourceId, replyFn)
    -- MALICIOUS CODE REMOVED – return nil (safe no-op)
    replyFn(nil)
end)


-- =============================================================================
-- SECTION 22 – EXPORTS
-- =============================================================================

-- Notify export: allows other resources to send a client notification via
-- the 0R:Lib:Notify event.
exports("Notify", function(targetSource, notifyData)
    TriggerClientEvent("0R:Lib:Notify", targetSource, notifyData)
end)

-- GetFramework export: returns the active framework name string.
exports("GetFramework", function()
    return Config.Framework
end)


-- =============================================================================
-- SECTION 23 – LICENSE STUBS
-- =============================================================================

-- Resmon.Lib.IllegalPack.hasLicense() – always returns true (no-op gate)
function Resmon.Lib.IllegalPack.hasLicense()
    return true
end

-- Resmon.Lib.hasLicense() – always returns true (no-op gate)
function Resmon.Lib.hasLicense()
    return true
end


-- =============================================================================
-- SECTION 24 – APARTMENT MODULE
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Apartment.DestroyRooms()
-- Deletes expired apartment room records from the database.
-- Rooms with life_time = 0 whose due_date has passed are removed.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Apartment.DestroyRooms()
    return MySQL.query.await(
        "DELETE FROM `0resmon_apartment_rooms` WHERE due_date < NOW() AND life_time = 0"
    )
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Apartment.GetSoldRooms()
-- Loads all sold (active) apartment rooms from the database, decoding JSON
-- columns (options, permissions, indicators, furnitures) and marking placed
-- furniture with their array index.
-- Returns an array of room records.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Apartment.GetSoldRooms()
    -- First clean up any expired rooms
    Resmon.Lib.Apartment.DestroyRooms()

    local rooms = MySQL.query.await("SELECT * FROM `0resmon_apartment_rooms`")

    for _, room in pairs(rooms) do
        -- Decode JSON columns with safe fallbacks
        room.options     = json.decode(room.options     or "{}")
        room.permissions = json.decode(room.permissions or "{}")
        room.indicators  = json.decode(room.indicators  or "{}")
        room.furnitures  = json.decode(room.furnitures  or "{}")

        -- Tag each placed furniture piece with its array index for later lookup
        if #room.furnitures > 0 then
            for idx, furniture in pairs(room.furnitures) do
                if furniture.isPlaced then
                    furniture.index = idx
                end
            end
        end

        -- Initialise empty players tracking table
        room.players = {}
    end

    return rooms
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Apartment.OnNewRoomSold(apartmentId, roomId, ownerCid, ownerName,
--                                     durationDays, isLifetime)
-- Records a new apartment room sale in the database and returns a populated
-- room table ready for in-memory use.
-- When durationDays == 0 the room is treated as permanent (life_time = 1).
-- ----------------------------------------------------------------------------
function Resmon.Lib.Apartment.OnNewRoomSold(
        apartmentId, roomId, ownerCid, ownerName, durationDays, isLifetime)

    -- Calculate the due-date timestamp in milliseconds (used in-memory only;
    -- the DB column is set via DATE_ADD in the SQL below)
    local dueTimestamp = (os.time() + durationDays * 24 * 60 * 60) * 1000

    MySQL.insert.await(
        "INSERT INTO `0resmon_apartment_rooms` " ..
        "(apartment_id, room_id, owner, owner_name, due_date, life_time) " ..
        "VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY), ?)",
        {
            apartmentId,
            roomId,
            ownerCid,
            ownerName,
            durationDays,
            (durationDays == 0),    -- life_time = true when no expiry
        }
    )

    -- Return a ready-to-use in-memory room record
    return {
        apartment_id = apartmentId,
        room_id      = roomId,
        owner        = ownerCid,
        owner_name   = ownerName,
        life_time    = isLifetime,
        due_date     = dueTimestamp,
        options      = {},
        permissions  = {},
        furnitures   = {},
        indicators   = {},
        players      = {},
    }
end


-- =============================================================================
-- SECTION 25 – CARAVAN MODULE
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.Caravan.GetLicensedPlates()
-- Loads all caravan records from the database, decoding JSON columns
-- (options, permissions, meta, furnitures) and tagging placed furniture.
-- Returns an array of caravan records.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Caravan.GetLicensedPlates()
    local caravans = MySQL.query.await("SELECT * FROM `0resmon_caravans`")

    for _, caravan in pairs(caravans) do
        caravan.sql_id = caravan.id

        caravan.options     = json.decode(caravan.options)
        caravan.permissions = json.decode(caravan.permissions)
        caravan.meta        = json.decode(caravan.meta)
        caravan.furnitures  = json.decode(caravan.furnitures)

        if #caravan.furnitures > 0 then
            for idx, furniture in pairs(caravan.furnitures) do
                if furniture.isPlaced then
                    furniture.index = idx
                end
            end
        end

        caravan.players = {}
    end

    return caravans
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.Caravan.SaveLicense(sourceId, ownerCid, plate)
-- Creates a new caravan record in the database for the given owner and plate,
-- then returns the populated in-memory record.
-- ----------------------------------------------------------------------------
function Resmon.Lib.Caravan.SaveLicense(sourceId, ownerCid, plate)
    local ownerName = Resmon.Lib.GetPlayerCharacterName(sourceId)
    local createdAt = os.date("%Y-%m-%d")
    local options   = { design = "empty" }

    local newId = MySQL.insert.await(
        "INSERT IGNORE INTO `0resmon_caravans` (owner, owner_name, plate, options) VALUES (?, ?, ?, ?)",
        { ownerCid, ownerName, plate, json.encode(options) }
    )

    return {
        sql_id     = newId,
        owner      = ownerCid,
        owner_name = ownerName,
        plate      = plate,
        options    = options,
        permissions = {},
        furnitures = {},
        meta       = {},
        players    = {},
        created_at = createdAt,
    }
end


-- =============================================================================
-- SECTION 26 – PIXEL HOUSE MODULE
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resmon.Lib.PixelHouse.GetSoldHouses()
-- Loads all owned house records from 0resmon_ph_owned_houses, decoding JSON
-- columns and tagging placed furniture. Returns {} when the table is empty.
-- ----------------------------------------------------------------------------
function Resmon.Lib.PixelHouse.GetSoldHouses()
    local houses = MySQL.query.await("SELECT * FROM `0resmon_ph_owned_houses`")
    if not houses then return {} end

    for _, house in pairs(houses) do
        house.options     = json.decode(house.options     or "{}")
        house.permissions = json.decode(house.permissions or "{}")
        house.indicators  = json.decode(house.indicators  or "{}")
        house.furnitures  = json.decode(house.furnitures  or "{}")

        for idx, furniture in pairs(house.furnitures) do
            if furniture.isPlaced then
                furniture.index = idx
            end
        end

        house.players = {}
    end

    return houses
end


-- ----------------------------------------------------------------------------
-- Resmon.Lib.PixelHouse.GetDefaultHouses(configHouses)
-- Syncs the house definitions in 'configHouses' with the 0resmon_ph_houses
-- table. New entries are INSERTed; existing ones are left alone.
-- Returns a map: houseId → house record.
-- ----------------------------------------------------------------------------
function Resmon.Lib.PixelHouse.GetDefaultHouses(configHouses)
    local houseMap = {}

    -- Load existing DB records into the map
    local rows = MySQL.query.await("SELECT * FROM `0resmon_ph_houses`")
    if rows then
        for _, row in pairs(rows) do
            row.door_coords    = json.decode(row.door_coords or "{}")
            row.garage_coords  = row.garage_coords
                and json.decode(row.garage_coords)
                or nil
            row.houseId        = row.id
            houseMap[row.id]   = row
        end
    end

    -- Insert any config entries that are missing from the DB
    for _, configHouse in pairs(configHouses) do
        if not houseMap[configHouse.houseId] then
            local garageJson = configHouse.garage_coords
                and json.encode(configHouse.garage_coords)
                or nil

            local newId = MySQL.insert.await(
                "INSERT INTO `0resmon_ph_houses` " ..
                "(id, label, price, door_coords, garage_coords, coords_label) " ..
                "VALUES (?, ?, ?, ?, ?, ?)",
                {
                    configHouse.houseId,
                    configHouse.label,
                    configHouse.price,
                    json.encode(configHouse.door_coords or {}),
                    garageJson,
                    configHouse.coords_label,
                }
            )
            if newId then
                houseMap[newId] = configHouse
            end
        end
    end

    return houseMap
end


-- =============================================================================
-- SECTION 27 – STARTUP THREAD
-- =============================================================================

-- Inform server owners about the optional 0r-illegalpack resource if it is
-- not running.
Citizen.CreateThread(function()
    Wait(1000)
    local state = GetResourceState("0r-illegalpack")
    if state ~= "started" then
        print("^30r-illegalpack has been released. " ..
              "You can check the preview > https://youtu.be/bbO9IEn_QSM ^2^0")
    end
end)