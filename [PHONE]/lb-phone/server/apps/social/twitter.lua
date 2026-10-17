-- ============================================================
-- twitter_decoded.lua
-- Đây là bản giải mã (deobfuscated) của twitter.lua
-- Tất cả tên biến L0_1, L1_2... đã được đặt lại tên có nghĩa
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- HELPER: Lấy username Twitter đang đăng nhập của 1 source player
-- ────────────────────────────────────────────────────────────
local function GetTwitterAccount(source)
    local phoneNumber = GetEquippedPhoneNumber(source)
    if not phoneNumber then
        return false
    end
    return GetLoggedInAccount(phoneNumber, "Twitter")
end

-- ────────────────────────────────────────────────────────────
-- HELPER: Đăng ký callback Birdy, tự động kiểm tra đăng nhập
-- Handler nhận: (source, phoneNumber, account, ...)
-- ────────────────────────────────────────────────────────────
local function RegisterBirdyCallback(callbackName, handler, defaultReturn, options)
    BaseCallback("birdy:" .. callbackName, function(source, phoneNumber, ...)
        local account = GetLoggedInAccount(phoneNumber, "Twitter")
        if not account then
            return defaultReturn
        end
        return handler(source, phoneNumber, account, ...)
    end, defaultReturn, options)
end

-- ────────────────────────────────────────────────────────────
-- HELPER: Gửi thông báo đến TẤT CẢ thiết bị đang đăng nhập
--         vào 1 tài khoản Twitter (trừ thiết bị của người gửi)
-- ────────────────────────────────────────────────────────────
local function NotifyAccountDevices(username, notification, senderPhone)
    local devices = MySQL.query.await(
        "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'Twitter' AND `active` = 1",
        { username }
    )
    notification.app = "Twitter"
    for _, device in ipairs(devices) do
        local phone = device.phone_number
        if phone ~= senderPhone then
            SendNotification(phone, notification)
        end
    end
end

-- ────────────────────────────────────────────────────────────
-- HELPER: Lấy thông tin profile Twitter đầy đủ
-- ────────────────────────────────────────────────────────────
local function GetTwitterProfile(username, phoneNumber)
    username = username:lower()

    local profileData = MySQL.single.await(
        "SELECT `display_name`, `bio`, `profile_image`, `profile_header`, `verified`, `follower_count`, `following_count`, `date_joined`, private FROM `phone_twitter_accounts` WHERE `username`=?",
        { username }
    )
    if not profileData then
        return false
    end

    local isFollowing          = false
    local isFollowingYou       = false
    local notificationsEnabled = false
    local requested            = false
    local pinnedTweet          = nil

    local loggedInAs = nil
    if phoneNumber then
        loggedInAs = GetLoggedInAccount(phoneNumber, "Twitter")
    end

    if loggedInAs then
        isFollowing = nil ~= MySQL.scalar.await(
            "SELECT `followed` FROM `phone_twitter_follows` WHERE `follower` = ? AND `followed` = ?",
            { loggedInAs, username }
        )
        isFollowingYou = nil ~= MySQL.scalar.await(
            "SELECT `followed` FROM `phone_twitter_follows` WHERE `follower` = ? AND `followed` = ?",
            { username, loggedInAs }
        )
        notificationsEnabled = true == MySQL.scalar.await(
            "SELECT `notifications` FROM `phone_twitter_follows` WHERE `follower` = ? AND `followed` = ?",
            { loggedInAs, username }
        )
        requested = nil ~= MySQL.scalar.await(
            "SELECT TRUE FROM phone_twitter_follow_requests WHERE requester = ? AND requestee = ?",
            { loggedInAs, username }
        )
        pinnedTweet = MySQL.scalar.await(
            "SELECT pinned_tweet FROM phone_twitter_accounts WHERE username = ?",
            { username }
        )
        if pinnedTweet then
            pinnedTweet = GetTweet(pinnedTweet, loggedInAs)
        end
    end

    return {
        name                 = profileData.display_name,
        username             = username,
        followers            = profileData.follower_count,
        following            = profileData.following_count,
        date_joined          = profileData.date_joined,
        bio                  = profileData.bio,
        verified             = profileData.verified,
        private              = profileData.private,
        profile_picture      = profileData.profile_image,
        header               = profileData.profile_header,
        isFollowing          = isFollowing,
        isFollowingYou       = isFollowingYou,
        notificationsEnabled = notificationsEnabled,
        pinnedTweet          = pinnedTweet,
        requested            = requested,
    }
end

-- ────────────────────────────────────────────────────────────
-- HELPER: Lấy danh sách {phone_number → source} các thiết bị
--         đang online và đăng nhập vào 1 tài khoản Twitter
-- ────────────────────────────────────────────────────────────
local function GetOnlineDevicesForAccount(username)
    local result  = {}
    local devices = MySQL.query.await(
        [[
            SELECT phone_number FROM phone_logged_in_accounts
                WHERE username = ? AND app = 'Twitter'
            UNION
            SELECT phone_number FROM phone_twitter_accounts
                WHERE username = ?
        ]],
        { username, username }
    )
    for _, device in ipairs(devices or {}) do
        local phone = device.phone_number
        local src   = GetSourceFromNumber(phone)
        if src and src > 0 then
            result[phone] = src
        end
    end
    return result
end

-- ────────────────────────────────────────────────────────────
-- Bảng map loại thông báo → locale key
-- ────────────────────────────────────────────────────────────
local NotificationTypeLocales = {
    like    = "BACKEND.TWITTER.LIKE",
    retweet = "BACKEND.TWITTER.RETWEET",
    reply   = "BACKEND.TWITTER.REPLY",
    follow  = "BACKEND.TWITTER.FOLLOW",
    tweet   = "BACKEND.TWITTER.TWEET",
}

-- ────────────────────────────────────────────────────────────
-- HELPER: Tạo thông báo Twitter trong DB và đẩy đến thiết bị online
-- ────────────────────────────────────────────────────────────
local function CreateTwitterNotification(targetUsername, fromUsername, notifType, tweetId)
    CreateThread(function()
        if targetUsername == fromUsername then return end

        local localeKey = NotificationTypeLocales[notifType]
        if not localeKey then return end

        -- Chống spam thông báo trùng
        if notifType == "like" or notifType == "retweet" or notifType == "follow" then
            local condition = (notifType ~= "follow") and " AND tweet_id=@tweet_id" or ""
            local exists = MySQL.scalar.await(
                "SELECT TRUE FROM phone_twitter_notifications WHERE username=@username AND `from`=@from AND `type`=@type" .. condition,
                { ["@username"] = targetUsername, ["@from"] = fromUsername, ["@type"] = notifType, ["@tweet_id"] = tweetId }
            )
            if exists then return end
        end

        local fromAccount = MySQL.single.await(
            "SELECT display_name, private FROM phone_twitter_accounts WHERE username = ?",
            { fromUsername }
        )

        if not fromAccount then return end

        local title = L(localeKey, { displayName = fromAccount.display_name, username = fromUsername })

        -- Lưu vào DB
        MySQL.update.await(
            "INSERT INTO phone_twitter_notifications (id, username, `from`, `type`, tweet_id) VALUES (@id, @username, @from, @type, @tweetId)",
            {
                ["@id"]       = GenerateId("phone_twitter_notifications", "id"),
                ["@username"] = targetUsername,
                ["@from"]     = fromUsername,
                ["@type"]     = notifType,
                ["@tweetId"]  = tweetId,
            }
        )

        -- Lấy nội dung tweet (nếu không phải follow)
        local content, thumbnail
        if notifType ~= "follow" then
            local tweetData = MySQL.single.await(
                "SELECT content, attachments FROM phone_twitter_tweets WHERE id = ?",
                { tweetId }
            )
            if tweetData then
                content = tweetData.content
                if tweetData.attachments then
                    thumbnail = json.decode(tweetData.attachments)
                end
            end
        end

        -- Gửi push notification đến các thiết bị online
        local onlineDevices = GetOnlineDevicesForAccount(targetUsername)
        for phone, _ in pairs(onlineDevices) do
            SendNotification(phone, {
                app       = "Twitter",
                title     = title,
                content   = content,
                thumbnail = thumbnail and thumbnail[1],
            })
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- CALLBACKS
-- ════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────
-- Lấy danh sách thông báo
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getNotifications", function(source, cb, page)
    local account = GetTwitterAccount(source)
    if not account then
        return cb({ notifications = {}, requests = 0 })
    end

    local notifications = MySQL.Sync.fetchAll([[
        SELECT
            n.`from`, n.`type`, n.tweet_id,
            t.username, t.content, t.attachments, t.reply_to, t.like_count,
            t.reply_count, t.retweet_count, t.`timestamp`,
            (SELECT TRUE FROM phone_twitter_likes l
                WHERE l.tweet_id=t.id AND l.username=@username) AS liked,
            (SELECT TRUE FROM phone_twitter_retweets r
                WHERE r.tweet_id=t.id AND r.username=@username) AS retweeted,
            a.display_name AS `name`, a.profile_image AS profile_picture, a.verified,
            (CASE WHEN t.reply_to IS NULL THEN NULL
                ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1)
            END) AS replyToAuthor
        FROM phone_twitter_notifications n
        LEFT JOIN phone_twitter_tweets t ON n.tweet_id = t.id
        JOIN phone_twitter_accounts a ON a.username = n.from
        WHERE n.username=@username
        ORDER BY n.`timestamp` DESC
        LIMIT @page, @perPage
    ]], {
        ["@username"] = account,
        ["@page"]     = page * 15,
        ["@perPage"]  = 15,
    })

    if page > 0 then
        return cb({ notifications = notifications })
    end

    local requestCount = MySQL.Sync.fetchScalar(
        "SELECT COUNT(1) FROM phone_twitter_follow_requests WHERE requestee=@username",
        { ["@username"] = account }
    )
    cb({ notifications = notifications, requests = requestCount })
end)

-- ────────────────────────────────────────────────────────────
-- Tạo tài khoản Birdy
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:createAccount", function(source, cb, displayName, username, password)
    local phoneNumber = GetEquippedPhoneNumber(source)
    if not phoneNumber then
        return cb(false)
    end

    username = username:lower()

    if not IsUsernameValid(username) then
        return cb({ success = false, error = "USERNAME_NOT_ALLOWED" })
    end

    local taken = MySQL.Sync.fetchScalar(
        "SELECT TRUE FROM phone_twitter_accounts WHERE username=@username",
        { ["@username"] = username }
    )
    if taken then
        return cb({ success = false, error = "USERNAME_TAKEN" })
    end

    MySQL.Sync.execute(
        "INSERT INTO phone_twitter_accounts (display_name, username, `password`, phone_number) VALUES (@displayName, @username, @password, @phonenumber)",
        {
            ["@displayName"] = displayName,
            ["@username"]    = username,
            ["@password"]    = GetPasswordHash(password),
            ["@phonenumber"] = phoneNumber,
        }
    )

    AddLoggedInAccount(phoneNumber, "Twitter", username)
    cb({ success = true })

    -- Auto-follow theo config
    if Config.AutoFollow.Enabled and Config.AutoFollow.Birdy.Enabled then
        for _, accountToFollow in ipairs(Config.AutoFollow.Birdy.Accounts) do
            MySQL.update.await(
                "INSERT INTO phone_twitter_follows (followed, follower) VALUES (?, ?)",
                { accountToFollow, username }
            )
        end
    end
end, {}, { preventSpam = true, rateLimit = 4 })

-- ────────────────────────────────────────────────────────────
-- Đổi mật khẩu
-- Handler: (source, phoneNumber, account, oldPassword, newPassword)
-- ────────────────────────────────────────────────────────────
RegisterBirdyCallback("changePassword", function(source, phoneNumber, account, oldPassword, newPassword)
    if not Config.ChangePassword.Birdy then
        infoprint("warning", ("%s tried to change password on Birdy, but it's not enabled in the config."):format(source))
        return false
    end

    if oldPassword == newPassword or #newPassword < 3 then
        debugprint("same password / too short")
        return false
    end

    local storedHash = MySQL.scalar.await(
        "SELECT password FROM phone_twitter_accounts WHERE username = ?",
        { account }
    )
    if not storedHash or not VerifyPasswordHash(oldPassword, storedHash) then
        return false
    end

    local updated = MySQL.update.await(
        "UPDATE phone_twitter_accounts SET password = ? WHERE username = ?",
        { GetPasswordHash(newPassword), account }
    )
    if updated <= 0 then return false end

    -- Gửi thông báo bị đăng xuất đến các thiết bị khác
    NotifyAccountDevices(account, {
        title   = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"),
        content = L("BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"),
    }, phoneNumber)

    -- Xóa session các thiết bị khác
    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Twitter' AND phone_number != ?",
        { account, phoneNumber }
    )
    ClearActiveAccountsCache("Twitter", account, phoneNumber)

    Log("Birdy", source, "info",
        L("BACKEND.LOGS.CHANGED_PASSWORD.TITLE"),
        L("BACKEND.LOGS.CHANGED_PASSWORD.DESCRIPTION", { number = phoneNumber, username = account, app = "Birdy" })
    )

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = account,
        app      = "twitter",
        reason   = "password",
        number   = phoneNumber,
    })

    return true
end, false)

-- ────────────────────────────────────────────────────────────
-- Xóa tài khoản
-- Handler: (source, phoneNumber, account, password)
-- ────────────────────────────────────────────────────────────
RegisterBirdyCallback("deleteAccount", function(source, phoneNumber, account, password)
    if not Config.DeleteAccount.Birdy then
        infoprint("warning", ("%s tried to delete their account on Birdy, but it's not enabled in the config."):format(source))
        return false
    end

    local storedHash = MySQL.scalar.await(
        "SELECT password FROM phone_twitter_accounts WHERE username = ?",
        { account }
    )
    if not storedHash or not VerifyPasswordHash(password, storedHash) then
        return false
    end

    local deleted = MySQL.update.await(
        "DELETE FROM phone_twitter_accounts WHERE username = ?",
        { account }
    )
    if deleted <= 0 then return false end

    NotifyAccountDevices(account, {
        title   = L("BACKEND.MISC.DELETED_NOTIFICATION.TITLE"),
        content = L("BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION"),
    })

    MySQL.update.await(
        "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Twitter'",
        { account }
    )
    ClearActiveAccountsCache("Twitter", account)

    Log("Birdy", source, "info",
        L("BACKEND.LOGS.DELETED_ACCOUNT.TITLE"),
        L("BACKEND.LOGS.DELETED_ACCOUNT.DESCRIPTION", { number = phoneNumber, username = account, app = "Birdy" })
    )

    TriggerClientEvent("phone:logoutFromApp", -1, {
        username = account,
        app      = "twitter",
        reason   = "deleted",
    })

    return true
end, false)

-- ────────────────────────────────────────────────────────────
-- Đăng nhập
-- ────────────────────────────────────────────────────────────
BaseCallback("birdy:login", function(source, phoneNumber, username, password)
    username = username:lower()

    local storedHash = MySQL.scalar.await(
        "SELECT `password` FROM phone_twitter_accounts WHERE username = ?",
        { username }
    )
    if not storedHash then
        return { success = false, error = "INVALID_ACCOUNT" }
    end

    if not VerifyPasswordHash(password, storedHash) then
        return { success = false, error = "INVALID_PASSWORD" }
    end

    AddLoggedInAccount(phoneNumber, "Twitter", username)

    local profile = GetTwitterProfile(username)
    if not profile then
        return { success = false, error = "INVALID_ACCOUNT" }
    end

    return { success = true, data = profile }
end)

-- ────────────────────────────────────────────────────────────
-- Kiểm tra trạng thái đăng nhập
-- ────────────────────────────────────────────────────────────
RegisterBirdyCallback("isLoggedIn", function(source, phoneNumber, account)
    return GetTwitterProfile(account)
end, false)

-- ────────────────────────────────────────────────────────────
-- Lấy profile
-- ────────────────────────────────────────────────────────────
RegisterBirdyCallback("getProfile", function(source, phoneNumber, account, targetUsername)
    return GetTwitterProfile(targetUsername, phoneNumber)
end, false)

-- ────────────────────────────────────────────────────────────
-- Ghim / bỏ ghim bài đăng
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:pinPost", function(source, cb, tweetId)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end

    if tweetId then
        local owns = MySQL.scalar.await(
            "SELECT TRUE FROM phone_twitter_tweets WHERE id = ? AND username = ?",
            { tweetId, account }
        )
        if not owns then
            infoprint("warning", ("%s (%s) tried to pin a post on birdy that they didn't make."):format(account, source))
            return cb(false)
        end
    end

    MySQL.Async.execute(
        "UPDATE phone_twitter_accounts SET pinned_tweet=@tweetId WHERE username=@username",
        { ["@tweetId"] = tweetId or nil, ["@username"] = account },
        function()
            cb(true)
        end
    )
end)

-- ────────────────────────────────────────────────────────────
-- Đăng xuất
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:signOut", function(source, cb)
    local phoneNumber = GetEquippedPhoneNumber(source)
    if not phoneNumber then return cb(false) end

    local account = GetLoggedInAccount(phoneNumber, "Twitter")
    if not account then return cb(false) end

    RemoveLoggedInAccount(phoneNumber, "Twitter", account)
    cb(true)
end)

-- ────────────────────────────────────────────────────────────
-- Cập nhật profile
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:updateProfile", function(source, cb, profileData)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end

    MySQL.Async.execute(
        "UPDATE phone_twitter_accounts SET display_name=@displayName, bio=@bio, profile_image=@profilePicture, profile_header=@header, private=@private WHERE username=@username",
        {
            ["@username"]       = account,
            ["@displayName"]    = profileData.name,
            ["@bio"]            = profileData.bio,
            ["@profilePicture"] = profileData.profile_picture,
            ["@header"]         = profileData.header,
            ["@private"]        = profileData.private,
        },
        function()
            cb(true)
        end
    )
end)

-- ────────────────────────────────────────────────────────────
-- HELPER: Ghi log bài đăng mới
-- ────────────────────────────────────────────────────────────
local function LogNewPost(tweetId, username, content, attachments, source)
    local attCount = attachments and #attachments or 0
    local logText  = "**Username**: " .. username .. "\n\n**Content**: " .. (content or "")

    if attachments then
        logText = logText .. "\n\n**Attachments**:"
        for i = 1, attCount do
            logText = logText .. ("\n\n[Attachment %s](%s)"):format(i, attachments[i])
        end
    end

    logText = logText .. "\n\n**ID**: " .. tweetId
    Log("Birdy", source, "info", "New post", logText)
end

-- ────────────────────────────────────────────────────────────
-- HELPER: Gửi bài đăng mới lên Discord Webhook
-- ────────────────────────────────────────────────────────────
local function SendPostToDiscordWebhook(username, content, attachments, replyTo)
    if not (Config.Post.Birdy and not replyTo) then return end
    if not BIRDY_WEBHOOK then return end
    if BIRDY_WEBHOOK:sub(-14) == "/api/webhooks/" then return end

    local avatar = MySQL.scalar.await(
        "SELECT profile_image FROM phone_twitter_accounts WHERE username = ?",
        { username }
    )

    local webhookUsername = (Config.Post.Accounts and Config.Post.Accounts.Birdy and Config.Post.Accounts.Birdy.Username) or "Birdy"
    local webhookAvatar   = (Config.Post.Accounts and Config.Post.Accounts.Birdy and Config.Post.Accounts.Birdy.Avatar)  or "https://loaf-scripts.com/fivem/lb-phone/icons/Birdy.png"

    local description = (content and #content > 0) and content or nil
    local embedImage  = (attachments and #attachments > 0) and { url = attachments[1] } or nil

    PerformHttpRequest(BIRDY_WEBHOOK, function() end, "POST", json.encode({
        username   = webhookUsername,
        avatar_url = webhookAvatar,
        embeds = {
            {
                title       = L("APPS.TWITTER.NEW_POST"),
                description = description,
                color       = 1942002,
                timestamp   = GetTimestampISO(),
                author = {
                    name     = "@" .. username,
                    icon_url = avatar or "https://cdn.discordapp.com/embed/avatars/5.png",
                },
                image  = embedImage,
                footer = {
                    text     = "LB Phone",
                    icon_url = "https://docs.lbscripts.com/images/icons/icon.png",
                },
            }
        },
    }), { ["Content-Type"] = "application/json" })
end

-- ────────────────────────────────────────────────────────────
-- CORE: Đăng tweet (hàm nội bộ)
-- Trả về: success (bool), tweetId (string)
-- ────────────────────────────────────────────────────────────
local function PostBirdyInternal(username, content, attachments, replyTo, hashtags, source)
    if not content then content = "" end

    assert(type(username) == "string", "PostBirdy: Expected string for argument 1 (username), got " .. type(username))
    assert(type(content)  == "string", "PostBirdy: Expected string/nil for argument 2 (content), got " .. type(content))

    local tweetId = GenerateId("phone_twitter_tweets", "id")
    local params  = { tweetId, username, content }
    local query   = "INSERT INTO phone_twitter_tweets (id, username, content"

    -- Xử lý attachments
    if attachments then
        if type(attachments) == "table" then
            if table.type(attachments) == "array" and #attachments > 0 then
                query            = query .. ", attachments"
                params[#params + 1] = json.encode(attachments)
            end
        else
            error("PostBirdy: Expected table/nil for argument 3 (attachments), got " .. type(attachments))
        end
    else
        -- Kiểm tra content không chỉ có khoảng trắng
        if #content:gsub(" ", "") == 0 then
            debugprint("PostBirdy: No content & no attachments")
            return false
        end
    end

    -- Xử lý reply_to
    if replyTo then
        if type(replyTo) == "string" then
            query            = query .. ", reply_to"
            params[#params + 1] = replyTo
        else
            error("PostBirdy: Expected string/nil for argument 4 (replyTo), got " .. type(replyTo))
        end
    end

    -- Tạo chuỗi VALUES (?, ?, ...)
    local placeholders = ("?, "):rep(#params):sub(1, -3)
    query = query .. ") VALUES (" .. placeholders .. ")"

    local inserted = MySQL.update.await(query, params)
    if inserted == 0 then return false end

    local accountData = MySQL.single.await(
        "SELECT display_name, profile_image, verified, private FROM phone_twitter_accounts WHERE username = ?",
        { username }
    )
    if not accountData then
        accountData = { display_name = username }
    end

    -- Cập nhật reply count nếu là reply
    if replyTo then
        MySQL.update(
            "UPDATE phone_twitter_tweets SET reply_count = reply_count + 1 WHERE id = ?",
            { replyTo }
        )
        TriggerClientEvent("phone:twitter:updateTweetData", -1, replyTo, "replies", true)

        -- Tìm tweet gốc của thread (đi ngược chuỗi reply_to)
        local rootId        = replyTo
        local safetyCounter = 0
        while safetyCounter < 50 do
            safetyCounter = safetyCounter + 1
            local parent = MySQL.scalar.await(
                "SELECT reply_to FROM phone_twitter_tweets WHERE id = ?",
                { rootId }
            )
            if not parent then break end
            rootId = parent
        end

        -- Lấy tất cả người đã đăng bài trong thread (root + mọi reply trong thread)
        local participants = MySQL.query.await([[
            SELECT DISTINCT username FROM phone_twitter_tweets
                WHERE id = ? OR reply_to = ?
                   OR reply_to IN (SELECT id FROM (
                        SELECT id FROM phone_twitter_tweets WHERE reply_to = ?
                   ) AS sub)
        ]], { rootId, rootId, rootId })

        local notified = { [username] = true }
        for _, row in ipairs(participants or {}) do
            if row.username and not notified[row.username] then
                notified[row.username] = true
                CreateTwitterNotification(row.username, username, "reply", tweetId)
            end
        end
    end

    -- Thông báo bài đăng mới: CHỈ khi không phải reply
    if not replyTo then
        -- Cho followers có bật chuông
        local followers = MySQL.query.await(
            "SELECT follower FROM phone_twitter_follows WHERE followed = ? AND notifications=1",
            { username }
        )
        for _, row in ipairs(followers or {}) do
            CreateTwitterNotification(row.follower, username, "tweet", tweetId)
        end

        -- Push toàn server
        NotifyEveryone("online", {
            app       = "Twitter",
            title     = L("BACKEND.TWITTER.TWEET", { username = username }),
            content   = content,
            thumbnail = attachments and attachments[1],
        })
    end

    TrackSocialMediaPost("birdy", attachments)

    if source then
        LogNewPost(tweetId, username, content, attachments, source)
    end

    -- Nếu tài khoản không private
    if not accountData.private then
        SendPostToDiscordWebhook(username, content, attachments, replyTo)

        -- Xử lý trending hashtags
        if Config.BirdyTrending.Enabled
            and type(hashtags) == "table"
            and table.type(hashtags) == "array"
            and #hashtags > 0
        then
            local hashtagPlaceholders = ("(?, 1), "):rep(#hashtags):sub(1, -3)
            MySQL.update(
                "INSERT INTO phone_twitter_hashtags (hashtag, amount) VALUES "
                    .. hashtagPlaceholders
                    .. " ON DUPLICATE KEY UPDATE amount = amount + 1",
                hashtags
            )
        end

        -- Broadcast tweet mới tới tất cả clients
        local newTweet = {
            id            = tweetId,
            username      = username,
            content       = content,
            attachments   = attachments,
            like_count    = 0,
            reply_count   = 0,
            retweet_count = 0,
            reply_to      = replyTo,
            timestamp     = os.time() * 1000,
            liked         = false,
            retweeted     = false,
            display_name  = accountData.display_name,
            profile_image = accountData.profile_image,
            verified      = accountData.verified,
        }

        if replyTo then
            newTweet.replyToAuthor = MySQL.scalar.await(
                "SELECT username FROM phone_twitter_tweets WHERE id = ?",
                { replyTo }
            )
        end

        TriggerClientEvent("phone:twitter:newtweet", -1, newTweet)
        TriggerEvent("lb-phone:birdy:newPost", newTweet)
    end

    return true, tweetId
end

exports("PostBirdy", PostBirdyInternal)

-- ────────────────────────────────────────────────────────────
-- Callback: Client gửi bài đăng
-- Handler: (source, phoneNumber, account, content, attachments, replyTo, hashtags)
-- ────────────────────────────────────────────────────────────
RegisterBirdyCallback("sendPost", function(source, phoneNumber, account, content, attachments, replyTo, hashtags)
    if ContainsBlacklistedWord(source, "Birdy", content) then
        return false
    end
    local success, _ = PostBirdyInternal(account, content, attachments, replyTo, hashtags, source)
    return success
end, nil, { preventSpam = true, rateLimit = 15 })

-- ────────────────────────────────────────────────────────────
-- Lấy hashtag trending gần đây
-- ────────────────────────────────────────────────────────────
RegisterCallback("birdy:getRecentHashtags", function()
    if not Config.BirdyTrending.Enabled then return {} end
    return MySQL.query.await(
        "SELECT hashtag, amount AS uses FROM phone_twitter_hashtags ORDER BY amount DESC LIMIT 5"
    )
end)

-- ────────────────────────────────────────────────────────────
-- Xóa bài đăng
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:deletePost", function(source, cb, tweetId)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end

    local replyTo = MySQL.Sync.fetchScalar(
        "SELECT reply_to FROM phone_twitter_tweets WHERE id=@id",
        { ["@id"] = tweetId }
    )

    -- Admin có thể xóa bất kỳ bài nào
    local canDelete = IsAdmin(source) or MySQL.Sync.fetchScalar(
        "SELECT TRUE FROM phone_twitter_tweets WHERE id=@id AND username=@username",
        { ["@id"] = tweetId, ["@username"] = account }
    )
    if not canDelete then return cb(false) end

    local params = { ["@id"] = tweetId }
    MySQL.Sync.execute("DELETE FROM phone_twitter_likes        WHERE tweet_id=@id", params)
    MySQL.Sync.execute("DELETE FROM phone_twitter_retweets     WHERE tweet_id=@id", params)
    MySQL.Sync.execute("DELETE FROM phone_twitter_notifications WHERE tweet_id=@id", params)

    local deleted = MySQL.Sync.execute("DELETE FROM phone_twitter_tweets WHERE id=@id", params) > 0
    cb(deleted)

    if not deleted then return end

    -- Cập nhật reply_count của bài gốc
    if replyTo then
        local replyCount = MySQL.Sync.fetchScalar(
            "SELECT COUNT(id) FROM phone_twitter_tweets WHERE reply_to=@replyTo",
            { ["@replyTo"] = replyTo }
        )
        MySQL.Sync.execute(
            "UPDATE phone_twitter_tweets SET reply_count=@count WHERE id=@replyTo",
            { ["@replyTo"] = replyTo, ["@count"] = replyCount }
        )
        TriggerClientEvent("phone:twitter:updateTweetData", -1, replyTo, "replies", false)
    end

    Log("Birdy", source, "info", "Post deleted", "**ID**: " .. tweetId)
end)

-- ────────────────────────────────────────────────────────────
-- Lấy bài đăng được quảng cáo ngẫu nhiên
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getRandomPromoted", function(source, cb)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end

    local promotedTweetId = MySQL.Sync.fetchScalar(
        "SELECT tweet_id FROM phone_twitter_promoted WHERE promotions > 0 ORDER BY RAND() LIMIT 1"
    )
    if not promotedTweetId then return cb(false) end

    MySQL.Async.execute(
        "UPDATE phone_twitter_promoted SET promotions = promotions - 1, views = views + 1 WHERE tweet_id = @tweetId",
        { ["@tweetId"] = promotedTweetId }
    )

    cb(GetTweet(promotedTweetId))
end)

-- ────────────────────────────────────────────────────────────
-- Quảng cáo bài đăng (mất tiền)
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:promotePost", function(source, cb, tweetId)
    if not (Config.PromoteBirdy and Config.PromoteBirdy.Enabled) or not RemoveMoney then
        return cb(false)
    end
    if not RemoveMoney(source, Config.PromoteBirdy.Cost) then
        return cb(false)
    end

    MySQL.Async.execute([[
        INSERT INTO phone_twitter_promoted (tweet_id, promotions, views) VALUES (@tweetId, @promotions, 0)
            ON DUPLICATE KEY UPDATE promotions = promotions + @promotions
    ]], {
        ["@tweetId"]    = tweetId,
        ["@promotions"] = Config.PromoteBirdy.Views,
    })

    cb(true)
end)

-- ────────────────────────────────────────────────────────────
-- Tìm kiếm tài khoản
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:searchAccounts", function(source, cb, searchQuery)
    MySQL.Async.fetchAll([[
        SELECT display_name, username, profile_image, verified, private
        FROM phone_twitter_accounts
        WHERE
            username LIKE CONCAT(@search, "%")
            OR display_name LIKE CONCAT("%", @search, "%")
    ]], { ["@search"] = searchQuery }, cb)
end)

-- ────────────────────────────────────────────────────────────
-- Tìm kiếm tweet
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:searchTweets", function(source, cb, searchQuery, page)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end

    MySQL.Async.fetchAll([[
        SELECT
            DISTINCT t.id, t.username, t.content, t.attachments,
            t.like_count, t.reply_count, t.retweet_count, t.reply_to,
            t.`timestamp`,
            (CASE WHEN t.reply_to IS NULL THEN NULL
                ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1)
            END) AS replyToAuthor,
            a.display_name, a.username, a.profile_image, a.verified,
            (SELECT TRUE FROM phone_twitter_likes l    WHERE l.tweet_id=t.id AND l.username=@loggedInAs) AS liked,
            (SELECT TRUE FROM phone_twitter_retweets r WHERE r.tweet_id=t.id AND r.username=@loggedInAs) AS retweeted
        FROM phone_twitter_tweets t
            LEFT JOIN phone_twitter_accounts a ON a.username=t.username
        WHERE t.content LIKE CONCAT("%", @search, "%")
        ORDER BY t.`timestamp` DESC
        LIMIT @page, @perPage
    ]], {
        ["@search"]     = searchQuery,
        ["@loggedInAs"] = account,
        ["@page"]       = page * 10,
        ["@perPage"]    = 10,
    }, cb)
end)

-- ────────────────────────────────────────────────────────────
-- Lấy dữ liệu: followers / following / likes / retweets
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getData", function(source, cb, dataType, targetId, page)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end

    local tableName = "phone_twitter_likes"
    local colWhere  = "tweet_id"
    local colSelect = "username"

    if dataType == "following" or dataType == "followers" then
        tableName = "phone_twitter_follows"
        if dataType == "following" then
            colWhere  = "follower"
            colSelect = "followed"
        else
            colWhere  = "followed"
            colSelect = "follower"
        end
    elseif dataType == "retweeters" then
        tableName = "phone_twitter_retweets"
        colWhere  = "tweet_id"
        colSelect = "username"
    end

    local query = ([[
        SELECT
            a.display_name AS `name`,
            a.username,
            a.profile_image AS profile_picture,
            a.bio,
            a.verified,
            (SELECT CASE WHEN f.followed IS NULL THEN FALSE ELSE TRUE END
                FROM phone_twitter_follows f
                WHERE f.follower=@loggedInAs AND a.username=f.followed
            ) AS isFollowing,
            (SELECT CASE WHEN f.follower IS NULL THEN FALSE ELSE TRUE END
                FROM phone_twitter_follows f
                WHERE f.follower=a.username AND f.followed=@loggedInAs
            ) AS isFollowingYou
        FROM %s w
        JOIN phone_twitter_accounts a ON a.username=w.%s
        WHERE w.%s=@whereValue
        ORDER BY a.username DESC
        LIMIT @page, @perPage
    ]]):format(tableName, colSelect, colWhere)

    MySQL.Async.fetchAll(query, {
        ["@loggedInAs"] = account,
        ["@whereValue"] = targetId,
        ["@page"]       = page * 20,
        ["@perPage"]    = 20,
    }, cb)
end)

-- ────────────────────────────────────────────────────────────
-- HELPER: Lấy 1 tweet theo ID (có kiểm tra privacy)
-- ────────────────────────────────────────────────────────────
local function GetTweetInternal(tweetId, loggedInAs)
    if not tweetId then return end

    local result = MySQL.Sync.fetchAll([[
        SELECT
            DISTINCT t.id, t.username, t.content, t.attachments,
            t.like_count, t.reply_count, t.retweet_count, t.reply_to,
            t.`timestamp`,
            (CASE WHEN t.reply_to IS NULL THEN NULL
                ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1)
            END) AS replyToAuthor,
            a.display_name, a.username, a.profile_image, a.verified,
            (SELECT TRUE FROM phone_twitter_likes l    WHERE l.tweet_id=t.id AND l.username=@loggedInAs) AS liked,
            (SELECT TRUE FROM phone_twitter_retweets r WHERE r.tweet_id=t.id AND r.username=@loggedInAs) AS retweeted
        FROM phone_twitter_tweets t
        INNER JOIN phone_twitter_accounts a ON a.username=t.username
        WHERE t.id=@tweetId AND (
            a.private=0
            OR a.username=@loggedInAs
            OR (SELECT TRUE FROM phone_twitter_follows f WHERE f.follower=@loggedInAs AND f.followed=a.username)
        )
    ]], {
        ["@tweetId"]    = tweetId,
        ["@loggedInAs"] = loggedInAs,
    })

    return result and result[1]
end

GetTweet = GetTweetInternal

-- Export: GetTweet (deprecated)
exports("GetTweet", function(tweetId, cb)
    assert(type(tweetId) == "string", "Expected string for argument 1, got " .. type(tweetId))
    infoprint("warning", "GetTweet is deprecated, use GetBirdyPost instead")
    MySQL.Async.fetchAll([[
        SELECT
            DISTINCT t.id, t.username, t.content, t.attachments,
            t.like_count, t.reply_count, t.retweet_count, t.reply_to,
            t.`timestamp`,
            a.display_name, a.username, a.profile_image, a.verified
        FROM (phone_twitter_tweets t, phone_twitter_accounts a)
        WHERE t.id=@tweetId AND t.username=a.username
    ]], { ["@tweetId"] = tweetId }, cb)
end)

-- Export: GetBirdyPost (mới, sync)
exports("GetBirdyPost", function(tweetId)
    local post = MySQL.single.await([[
        SELECT
            t.id,
            t.username,
            t.content,
            t.attachments,
            t.like_count    AS likes,
            t.reply_count   AS replies,
            t.retweet_count AS reposts,
            t.reply_to      AS replyTo,
            t.`timestamp`,
            a.display_name  AS displayName,
            a.profile_image AS avatar,
            a.verified
        FROM phone_twitter_tweets t
        LEFT JOIN phone_twitter_accounts a ON a.username = t.username
        WHERE t.id = ?
    ]], { tweetId })

    if post then
        local decoded    = post.attachments and json.decode(post.attachments)
        post.attachments = decoded or nil
    end

    return post
end)

-- ────────────────────────────────────────────────────────────
-- Lấy 1 bài đăng theo ID
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getPost", function(source, cb, tweetId)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end
    cb(GetTweet(tweetId, account))
end)

-- ────────────────────────────────────────────────────────────
-- Lấy danh sách bài đăng (feed, profile, following, v.v.)
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getPosts", function(source, cb, filter, page)
    local account = GetTwitterAccount(source)
    if not account then return cb({}) end

    local whereClause    = ""
    local joinClause     = ""
    local orderBy        = "`timestamp` DESC"
    local includeRetweet = false
    local rtJoin         = ""
    local rtWhere        = ""

    if not filter then
        -- Trang chủ: tất cả bài không reply
        whereClause    = "t.reply_to IS NULL"
        includeRetweet = true
    else
        local t = filter.type
        if t == "following" then
            whereClause    = "t.reply_to IS NULL AND f.follower=@loggedInAs AND f.followed=t.username"
            joinClause     = "JOIN phone_twitter_follows f"
            rtJoin         = "JOIN phone_twitter_follows f ON f.follower=@loggedInAs AND r.username=f.followed"
            includeRetweet = true
        elseif t == "replyTo" then
            whereClause = "t.reply_to=@replyTo"
            orderBy     = "t.like_count DESC, t.timestamp DESC"
        elseif t == "user" then
            whereClause    = "t.username=@username AND t.reply_to IS NULL"
            rtWhere        = " AND r.username=@username"
            includeRetweet = true
        elseif t == "media" then
            whereClause = "t.username=@username AND t.attachments IS NOT NULL"
        elseif t == "replies" then
            whereClause = "t.username=@username AND t.reply_to IS NOT NULL"
        elseif t == "liked" then
            whereClause = "l.username=@username AND t.id=l.tweet_id"
            joinClause  = "JOIN phone_twitter_likes l"
            orderBy     = "l.timestamp DESC"
        end
    end

    -- Phần SELECT chính
    local query = ([[
        SELECT
            (CASE WHEN t.reply_to IS NULL THEN NULL
                ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1)
            END) AS replyToAuthor,
            t.id, t.username, t.content, t.attachments,
            t.like_count, t.reply_count, t.retweet_count, t.reply_to,
            t.`timestamp`,
            a.display_name, a.profile_image, a.verified, a.private,
            (SELECT TRUE FROM phone_twitter_likes l2    WHERE l2.tweet_id=t.id AND l2.username=@loggedInAs) AS liked,
            (SELECT TRUE FROM phone_twitter_retweets r2 WHERE r2.tweet_id=t.id AND r2.username=@loggedInAs) AS retweeted,
            NULL AS tweet_timestamp, NULL AS retweeted_by_display_name, NULL AS retweeted_by_username
        FROM phone_twitter_tweets t
        INNER JOIN phone_twitter_accounts a ON a.username=t.username
        %s
        WHERE (a.private=0 OR a.username=@loggedInAs OR (
            SELECT TRUE FROM phone_twitter_follows f WHERE f.follower=@loggedInAs AND f.followed=a.username
        )) AND %s
    ]]):format(joinClause, whereClause)

    -- Thêm UNION ALL cho retweets
    if includeRetweet then
        query = query .. ([[
            UNION ALL
            SELECT
                (CASE WHEN t.reply_to IS NULL THEN NULL
                    ELSE (SELECT username FROM phone_twitter_tweets WHERE id=t.reply_to LIMIT 1)
                END) AS replyToAuthor,
                t.id, t.username, t.content, t.attachments,
                t.like_count, t.reply_count, t.retweet_count, t.reply_to,
                r.timestamp,
                a.display_name, a.profile_image, a.verified, a.private,
                (SELECT TRUE FROM phone_twitter_likes l2    WHERE l2.tweet_id=t.id AND l2.username=@loggedInAs) AS liked,
                (SELECT TRUE FROM phone_twitter_retweets r2 WHERE r2.tweet_id=t.id AND r2.username=@loggedInAs) AS retweeted,
                t.`timestamp` AS tweet_timestamp,
                (SELECT display_name FROM phone_twitter_accounts a2 WHERE r.username=a2.username) AS retweeted_by_display_name,
                r.username AS retweeted_by_username
            FROM phone_twitter_tweets t
            INNER JOIN phone_twitter_accounts a ON a.username=t.username
            JOIN phone_twitter_retweets r ON r.tweet_id=t.id
            %s
            WHERE (a.private=0 OR a.username=@loggedInAs OR (
                SELECT TRUE FROM phone_twitter_follows f WHERE f.follower=@loggedInAs AND f.followed=a.username
            )) %s
        ]]):format(rtJoin, rtWhere)
    end

    query = query .. ("ORDER BY %s\n\nLIMIT @page, @perPage"):format(orderBy)

    MySQL.Async.fetchAll(query, {
        ["@page"]       = page * 10,
        ["@perPage"]    = 10,
        ["@username"]   = filter and filter.username,
        ["@replyTo"]    = filter and filter.tweet_id,
        ["@loggedInAs"] = account,
    }, cb)
end)

-- ────────────────────────────────────────────────────────────
-- Config bảng cho like/retweet
-- ────────────────────────────────────────────────────────────
local InteractionConfig = {
    like    = { table = "phone_twitter_likes",    column1 = "username", column2 = "tweet_id" },
    retweet = { table = "phone_twitter_retweets", column1 = "username", column2 = "tweet_id" },
}

-- ────────────────────────────────────────────────────────────
-- Toggle like / retweet
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:toggleInteraction", function(source, cb, interactionType, tweetId, newState)
    if interactionType ~= "like" and interactionType ~= "retweet" then return end

    local account = GetTwitterAccount(source)
    if not account then return cb(not newState) end

    local cfg       = InteractionConfig[interactionType]
    local tableName = cfg.table
    local col1      = cfg.column1
    local col2      = cfg.column2

    local function onComplete(affectedRows)
        if affectedRows == 0 then
            return cb(not newState)
        end
        cb(newState)

        local dataKey = (interactionType == "like") and "likes" or "retweets"
        TriggerClientEvent("phone:twitter:updateTweetData", -1, tweetId, dataKey, newState == true)

        if newState then
            local tweetAuthor = MySQL.Sync.fetchScalar(
                "SELECT username FROM phone_twitter_tweets WHERE id=@tweetId",
                { ["@tweetId"] = tweetId }
            )
            CreateTwitterNotification(tweetAuthor, account, interactionType, tweetId)
        end
    end

    if newState then
        MySQL.Async.execute(
            ("INSERT IGNORE INTO %s (%s, %s) VALUES (@loggedInAs, @tweetId)"):format(tableName, col1, col2),
            { ["@loggedInAs"] = account, ["@tweetId"] = tweetId },
            onComplete
        )
    else
        MySQL.Async.execute(
            ("DELETE FROM %s WHERE %s=@loggedInAs AND %s=@tweetId"):format(tableName, col1, col2),
            { ["@loggedInAs"] = account, ["@tweetId"] = tweetId },
            onComplete
        )
    end
end, {}, { preventSpam = true, rateLimit = 30 })

-- ────────────────────────────────────────────────────────────
-- Bật/tắt thông báo từ 1 người dùng
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:toggleNotifications", function(source, cb, targetUsername, enabled)
    local account = GetTwitterAccount(source)
    if not account then return cb(not enabled) end

    MySQL.Async.execute(
        "UPDATE phone_twitter_follows SET notifications=@enabled WHERE follower=@loggedInAs AND followed=@username ",
        { ["@enabled"] = enabled, ["@loggedInAs"] = account, ["@username"] = targetUsername },
        function(rows)
            cb(rows > 0 and enabled or not enabled)
        end
    )
end)

-- ────────────────────────────────────────────────────────────
-- Follow / Unfollow (có hỗ trợ tài khoản private)
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:toggleFollow", function(source, cb, targetUsername, newState)
    local account = GetTwitterAccount(source)
    if not account or targetUsername == account then
        return cb(not newState)
    end

    local params    = { ["@loggedInAs"] = account, ["@username"] = targetUsername }
    local isPrivate = MySQL.Sync.fetchScalar(
        "SELECT private FROM phone_twitter_accounts WHERE username=@username",
        params
    )

    if isPrivate then
        if newState then
            -- Gửi follow request
            MySQL.Async.execute(
                "INSERT IGNORE INTO phone_twitter_follow_requests (requester, requestee) VALUES (@loggedInAs, @username)",
                params,
                function(rows)
                    cb(newState)
                    if rows == 0 then return end
                    local devices = GetOnlineDevicesForAccount(targetUsername)
                    for phone, _ in pairs(devices) do
                        SendNotification(phone, {
                            app     = "Twitter",
                            content = L("BACKEND.TWITTER.NEW_FOLLOW_REQUEST", { username = account }),
                        })
                    end
                end
            )
        else
            -- Hủy follow request
            MySQL.Async.execute(
                "DELETE FROM phone_twitter_follow_requests WHERE requester=@loggedInAs AND requestee=@username",
                params
            )
        end
        return
    end

    -- Tài khoản public
    local query = newState
        and "INSERT IGNORE INTO phone_twitter_follows (followed, follower, notifications) VALUES (@username, @loggedInAs, 1)"
        or  "DELETE FROM phone_twitter_follows WHERE followed=@username AND follower=@loggedInAs"

    MySQL.Async.execute(query, params, function(rows)
        if rows == 0 then return cb(not newState) end

        TriggerClientEvent("phone:twitter:updateProfileData", -1, targetUsername, "followers", newState == true)
        TriggerClientEvent("phone:twitter:updateProfileData", -1, account,        "following", newState == true)

        if newState then
            CreateTwitterNotification(targetUsername, account, "follow")
        end

        cb(newState)
    end)
end, {}, { preventSpam = true, rateLimit = 30 })

-- ────────────────────────────────────────────────────────────
-- Lấy danh sách yêu cầu follow (tài khoản private)
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getFollowRequests", function(source, cb, page)
    local account = GetTwitterAccount(source)
    if not account then return cb({}) end

    MySQL.Async.fetchAll([[
        SELECT a.username, a.display_name AS `name`, a.profile_image AS profile_picture, a.verified,
            (SELECT CASE WHEN f.follower IS NULL THEN FALSE ELSE TRUE END
                FROM phone_twitter_follows f WHERE f.follower=a.username AND f.followed=@loggedInAs
            ) AS isFollowingYou
        FROM phone_twitter_follow_requests r
        INNER JOIN phone_twitter_accounts a ON a.username=r.requester
        WHERE r.requestee=@loggedInAs
        ORDER BY r.`timestamp` DESC
        LIMIT @page, @perPage
    ]], {
        ["@loggedInAs"] = account,
        ["@page"]       = (page or 0) * 15,
        ["@perPage"]    = 15,
    }, cb)
end)

-- ────────────────────────────────────────────────────────────
-- Chấp nhận / từ chối yêu cầu follow
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:handleFollowRequest", function(source, cb, requesterUsername, accept)
    local account = GetTwitterAccount(source)
    if not account then return cb(false) end

    local params = { ["@loggedInAs"] = account, ["@username"] = requesterUsername }

    local deleted = MySQL.Sync.execute(
        "DELETE FROM phone_twitter_follow_requests WHERE requestee=@loggedInAs AND requester=@username",
        params
    )
    if deleted == 0 then return cb(false) end

    if not accept then return cb(true) end

    -- Chấp nhận → thêm vào follows
    MySQL.Sync.execute(
        "INSERT IGNORE INTO phone_twitter_follows (follower, followed, notifications) VALUES (@username, @loggedInAs, 1)",
        params
    )

    TriggerClientEvent("phone:twitter:updateProfileData", -1, account,           "followers", true)
    TriggerClientEvent("phone:twitter:updateProfileData", -1, requesterUsername, "following", true)

    CreateTwitterNotification(account, requesterUsername, "follow")

    -- Thông báo cho người gửi request
    local requesterDevices = GetOnlineDevicesForAccount(requesterUsername)
    for phone, _ in pairs(requesterDevices) do
        SendNotification(phone, {
            app     = "Twitter",
            content = L("BACKEND.TWITTER.FOLLOW_REQUEST_ACCEPTED_DESCRIPTION", { username = account }),
        })
    end

    cb(true)
end)

-- ────────────────────────────────────────────────────────────
-- Gửi tin nhắn DM
-- Handler: (source, phoneNumber, account, recipient, content, attachments)
-- ────────────────────────────────────────────────────────────
RegisterBirdyCallback("sendMessage", function(source, phoneNumber, account, recipient, content, attachments)
    if ContainsBlacklistedWord(source, "Birdy", content) then
        return false
    end

    local inserted = MySQL.update.await([[
        INSERT INTO phone_twitter_messages (id, sender, recipient, content, attachments)
        VALUES (@id, @sender, @recipient, @content, @attachments)
    ]], {
        ["@id"]          = GenerateId("phone_twitter_messages", "id"),
        ["@sender"]      = account,
        ["@recipient"]   = recipient,
        ["@content"]     = content,
        ["@attachments"] = attachments and json.encode(attachments) or nil,
    })
    if inserted == 0 then return false end

    -- Đẩy tin nhắn thời gian thực đến thiết bị recipient online
    local recipientDevices = GetOnlineDevicesForAccount(recipient)
    for phone, src in pairs(recipientDevices) do
        if src then
            TriggerClientEvent("phone:twitter:newMessage", src, {
                sender      = account,
                recipient   = recipient,
                content     = content,
                attachments = attachments,
                timestamp   = os.time() * 1000,
            })
        end
    end

    -- Gửi push notification cho recipient
    local senderProfile = GetTwitterProfile(account)
    if not senderProfile then return true end

    for phone, _ in pairs(recipientDevices) do
        SendNotification(phone, {
            app        = "Twitter",
            title      = senderProfile.name,
            content    = content,
            thumbnail  = attachments and attachments[1],
            avatar     = senderProfile.profile_picture,
            showAvatar = true,
        })
    end

    return true
end, nil, { preventSpam = true, rateLimit = 15 })

-- ────────────────────────────────────────────────────────────
-- Lấy cuộc hội thoại DM với 1 người
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getMessages", function(source, cb, otherUsername, page)
    local account = GetTwitterAccount(source)
    if not account then return cb({}) end

    MySQL.Async.fetchAll([[
        SELECT sender, recipient, content, attachments, `timestamp`
        FROM phone_twitter_messages
        WHERE (sender=@loggedInAs AND recipient=@username) OR (sender=@username AND recipient=@loggedInAs)
        ORDER BY `timestamp` DESC
        LIMIT @page, @perPage
    ]], {
        ["@loggedInAs"] = account,
        ["@username"]   = otherUsername,
        ["@page"]       = page * 25,
        ["@perPage"]    = 25,
    }, cb)
end)

-- ────────────────────────────────────────────────────────────
-- Lấy danh sách cuộc hội thoại DM gần đây
-- ────────────────────────────────────────────────────────────
RegisterLegacyCallback("birdy:getRecentMessages", function(source, cb, page)
    local account = GetTwitterAccount(source)
    if not account then return cb({}) end

    MySQL.Async.fetchAll([[
        SELECT
            m.content, m.attachments, m.sender, f_m.username, m.`timestamp`,
            a.display_name AS `name`, a.profile_image AS profile_picture, a.verified
        FROM phone_twitter_messages m
        JOIN ((
            SELECT (CASE WHEN recipient!=@loggedInAs THEN recipient ELSE sender END) AS username,
                   MAX(`timestamp`) AS `timestamp`
            FROM phone_twitter_messages
            WHERE sender=@loggedInAs OR recipient=@loggedInAs
            GROUP BY username
        ) f_m) ON m.`timestamp`=f_m.`timestamp`
        INNER JOIN phone_twitter_accounts a ON a.username=f_m.username
        WHERE m.sender=@loggedInAs OR m.recipient=@loggedInAs
        GROUP BY f_m.username
        ORDER BY m.`timestamp` DESC
        LIMIT @page, @perPage
    ]], {
        ["@loggedInAs"] = account,
        ["@page"]       = (page or 0) * 15,
        ["@perPage"]    = 15,
    }, cb)
end)

-- ────────────────────────────────────────────────────────────
-- Thread: Dọn dẹp hashtag cũ định kỳ (mỗi 1 giờ)
-- ────────────────────────────────────────────────────────────
CreateThread(function()
    if not Config.BirdyTrending.Enabled then return end

    -- Chờ database sẵn sàng
    while not DatabaseCheckerFinished do
        Wait(500)
    end

    while true do
        local resetHours = tostring(Config.BirdyTrending.Reset or 24)
        MySQL.Async.execute(
            ("DELETE FROM phone_twitter_hashtags WHERE last_used < DATE_SUB(NOW(), INTERVAL %s HOUR)"):format(resetHours),
            {}
        )
        Wait(3600000) -- 1 tiếng
    end
end)
