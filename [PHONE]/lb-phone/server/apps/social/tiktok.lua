local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = GetEquippedPhoneNumber
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = GetLoggedInAccount
  L3_2 = L1_2
  L4_2 = "TikTok"
  return L2_2(L3_2, L4_2)
end
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = BaseCallback
  L4_2 = "tiktok:"
  L5_2 = A0_2
  L4_2 = L4_2 .. L5_2
  function L5_2(A0_3, A1_3, ...)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L2_3 = GetLoggedInAccount
    L3_3 = A1_3
    L4_3 = "TikTok"
    L2_3 = L2_3(L3_3, L4_3)
    if not L2_3 then
      L3_3 = A2_2
      return L3_3
    end
    L3_3 = A1_2
    L4_3 = A0_3
    L5_3 = A1_3
    L6_3 = L2_3
    L7_3 = ...
    return L3_3(L4_3, L5_3, L6_3, L7_3)
  end
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = MySQL
  L3_2 = L3_2.query
  L3_2 = L3_2.await
  L4_2 = "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'TikTok' AND `active` = 1"
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  A1_2.app = "TikTok"
  L4_2 = 1
  L5_2 = #L3_2
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = L3_2[L7_2]
    L8_2 = L8_2.phone_number
    if L8_2 ~= A2_2 then
      L9_2 = SendNotification
      L10_2 = L8_2
      L11_2 = A1_2
      L9_2(L10_2, L11_2)
    end
  end
end
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = "`name`, bio, avatar, username, verified, follower_count, following_count, like_count, twitter, instagram, show_likes"
  L3_2 = nil
  if A1_2 then
    L4_2 = MySQL
    L4_2 = L4_2.Sync
    L4_2 = L4_2.fetchAll
    L5_2 = [[
            SELECT %s,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = @loggedIn) AS isFollowingYou,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @loggedIn AND followed = @username) AS isFollowing
            FROM phone_tiktok_accounts WHERE username = @username
        ]]
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = L2_2
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = {}
    L6_2["@username"] = A0_2
    L6_2["@loggedIn"] = A1_2
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L4_2 = L4_2[1]
    end
    L3_2 = L4_2
  else
    L4_2 = MySQL
    L4_2 = L4_2.Sync
    L4_2 = L4_2.fetchAll
    L5_2 = "SELECT %s FROM phone_tiktok_accounts WHERE username = @username"
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = L2_2
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = {}
    L6_2["@username"] = A0_2
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L4_2 = L4_2[1]
    end
    L3_2 = L4_2
  end
  if L3_2 then
    L4_2 = L3_2.isFollowing
    L4_2 = 1 == L4_2
    L3_2.isFollowing = L4_2
    L4_2 = L3_2.isFollowingYou
    L4_2 = 1 == L4_2
    L3_2.isFollowingYou = L4_2
  end
  return L3_2
end
L4_1 = {}
L4_1.like = "BACKEND.TIKTOK.LIKE"
L4_1.save = "BACKEND.TIKTOK.SAVE"
L4_1.comment = "BACKEND.TIKTOK.COMMENT"
L4_1.follow = "BACKEND.TIKTOK.FOLLOW"
L4_1.like_comment = "BACKEND.TIKTOK.LIKED_COMMENT"
L4_1.reply = "BACKEND.TIKTOK.REPLIED_COMMENT"
L4_1.message = "BACKEND.TIKTOK.DM"
function L5_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L6_2 = L4_1
  L6_2 = L6_2[A2_2]
  if not L6_2 or A0_2 == A1_2 then
    return
  end
  L6_2 = L3_1
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    return
  end
  if "message" ~= A2_2 then
    L7_2 = {}
    L8_2 = A0_2
    L9_2 = A1_2
    L10_2 = A2_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L8_2 = "SELECT 1 FROM phone_tiktok_notifications WHERE username = ? AND `from` = ? AND `type` = ?"
    if A3_2 then
      L9_2 = L8_2
      L10_2 = " AND video_id = ?"
      L9_2 = L9_2 .. L10_2
      L8_2 = L9_2
      L9_2 = #L7_2
      L9_2 = L9_2 + 1
      L7_2[L9_2] = A3_2
    end
    if A4_2 then
      L9_2 = L8_2
      L10_2 = " AND comment_id = ?"
      L9_2 = L9_2 .. L10_2
      L8_2 = L9_2
      L9_2 = #L7_2
      L9_2 = L9_2 + 1
      L7_2[L9_2] = A4_2
    end
    L9_2 = MySQL
    L9_2 = L9_2.scalar
    L9_2 = L9_2.await
    L10_2 = L8_2
    L11_2 = L7_2
    L9_2 = L9_2(L10_2, L11_2)
    L9_2 = 1 == L9_2
    if L9_2 then
      return
    end
    L10_2 = MySQL
    L10_2 = L10_2.insert
    L11_2 = "INSERT INTO phone_tiktok_notifications (username, `from`, `type`, video_id, comment_id) VALUES (?, ?, ?, ?, ?)"
    L12_2 = {}
    L13_2 = A0_2
    L14_2 = A1_2
    L15_2 = A2_2
    L16_2 = A3_2
    L17_2 = A4_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L12_2[4] = L16_2
    L12_2[5] = L17_2
    L10_2(L11_2, L12_2)
  end
  if A3_2 then
    L7_2 = MySQL
    L7_2 = L7_2.Sync
    L7_2 = L7_2.fetchScalar
    L8_2 = "SELECT src FROM phone_tiktok_videos WHERE id = @id"
    L9_2 = {}
    L9_2["@id"] = A3_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      goto lbl_81
    end
  end
  L7_2 = nil
  ::lbl_81::
  L8_2 = {}
  L8_2.app = "TikTok"
  L9_2 = L
  L10_2 = L4_1
  L10_2 = L10_2[A2_2]
  L11_2 = {}
  L12_2 = L6_2.name
  L11_2.displayName = L12_2
  L9_2 = L9_2(L10_2, L11_2)
  L8_2.title = L9_2
  L8_2.thumbnail = L7_2
  if "message" == A2_2 then
    L9_2 = L6_2.avatar
    L8_2.avatar = L9_2
    L9_2 = A5_2.content
    L8_2.content = L9_2
    L8_2.showAvatar = true
  end
  L9_2 = MySQL
  L9_2 = L9_2.query
  L9_2 = L9_2.await
  L10_2 = "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'TikTok' AND `active` = 1"
  L11_2 = {}
  L12_2 = A0_2
  L11_2[1] = L12_2
  L9_2 = L9_2(L10_2, L11_2)
  L10_2 = 1
  L11_2 = #L9_2
  L12_2 = 1
  for L13_2 = L10_2, L11_2, L12_2 do
    L14_2 = SendNotification
    L15_2 = L9_2[L13_2]
    L15_2 = L15_2.phone_number
    L16_2 = L8_2
    L14_2(L15_2, L16_2)
  end
end
L6_1 = CreateThread
function L7_1()
  local L0_2, L1_2, L2_2
  while true do
    L0_2 = DatabaseCheckerFinished
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 500
    L0_2(L1_2)
  end
  while true do
    L0_2 = MySQL
    L0_2 = L0_2.Async
    L0_2 = L0_2.execute
    L1_2 = "DELETE FROM phone_tiktok_notifications WHERE `timestamp` < DATE_SUB(NOW(), INTERVAL 7 DAY)"
    L2_2 = {}
    L0_2(L1_2, L2_2)
    L0_2 = Wait
    L1_2 = 3600000
    L0_2(L1_2)
  end
end
L6_1(L7_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:getNotifications"
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L0_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "not_logged_in"
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.fetchAll
  L5_2 = [[
        SELECT
            n.`type`, n.`timestamp`, n.video_id AS videoId,
            a.`name`, a.avatar, a.username, a.verified,
            CASE
                WHEN n.video_id IS NOT NULL THEN
                    v.src
                ELSE NULL
            END AS videoSrc,
            n.comment_id,
            CASE
                WHEN n.comment_id IS NOT NULL THEN
                    c.comment
                ELSE NULL
            END AS commentText,
            CASE
                WHEN n.`type` = 'follow' THEN
                    CASE
                        WHEN f.follower IS NOT NULL THEN
                            TRUE
                        ELSE FALSE
                    END
                ELSE NULL
            END AS isFollowing,
            CASE
                WHEN n.`type` = 'reply' THEN
                c_original.comment
                ELSE NULL
            END AS originalText
        FROM
            phone_tiktok_notifications n
            LEFT JOIN phone_tiktok_accounts a ON n.from = a.username
            LEFT JOIN phone_tiktok_videos v ON n.video_id = v.id
            LEFT JOIN phone_tiktok_comments c ON n.comment_id = c.id
            LEFT JOIN phone_tiktok_comments c_original ON c.reply_to = c_original.id
            LEFT JOIN phone_tiktok_follows f ON n.username = f.follower AND n.from = f.followed
        WHERE
            n.username = @username
        ORDER BY
            n.`timestamp` DESC
        LIMIT @page, @perPage
    ]]
  L6_2 = {}
  L6_2["@username"] = L3_2
  L7_2 = A2_2 or L7_2
  if not A2_2 then
    L7_2 = 0
  end
  L7_2 = L7_2 * 15
  L6_2["@page"] = L7_2
  L6_2["@perPage"] = 15
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = {}
    L2_3.success = true
    L2_3.data = A0_3
    L1_3(L2_3)
  end
  L4_2(L5_2, L6_2, L7_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:login"
function L8_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = GetEquippedPhoneNumber
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "no_number"
    return L5_2(L6_2)
  end
  L6_2 = A2_2
  L5_2 = A2_2.lower
  L5_2 = L5_2(L6_2)
  A2_2 = L5_2
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.fetchScalar
  L6_2 = "SELECT password FROM phone_tiktok_accounts WHERE username = @username"
  L7_2 = {}
  L7_2["@username"] = A2_2
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    if not A0_3 then
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "invalid_username"
      return L1_3(L2_3)
    end
    L1_3 = VerifyPasswordHash
    L2_3 = A3_2
    L3_3 = A0_3
    L1_3 = L1_3(L2_3, L3_3)
    if not L1_3 then
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "incorrect_password"
      return L1_3(L2_3)
    end
    L1_3 = L3_1
    L2_3 = A2_2
    L1_3 = L1_3(L2_3)
    if not L1_3 then
      L2_3 = A1_2
      L3_3 = {}
      L3_3.success = false
      L3_3.error = "invalid_username"
      return L2_3(L3_3)
    end
    L2_3 = AddLoggedInAccount
    L3_3 = L4_2
    L4_3 = "TikTok"
    L5_3 = A2_2
    L2_3(L3_3, L4_3, L5_3)
    L2_3 = A1_2
    L3_3 = {}
    L3_3.success = true
    L3_3.data = L1_3
    L2_3(L3_3)
  end
  L5_2(L6_2, L7_2, L8_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:signup"
function L8_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L5_2 = GetEquippedPhoneNumber
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "UNKNOWN"
    return L6_2(L7_2)
  end
  L7_2 = A2_2
  L6_2 = A2_2.lower
  L6_2 = L6_2(L7_2)
  A2_2 = L6_2
  L6_2 = IsUsernameValid
  L7_2 = A2_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "USERNAME_NOT_ALLOWED"
    return L6_2(L7_2)
  end
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.fetchScalar
  L7_2 = "SELECT TRUE FROM phone_tiktok_accounts WHERE username = @username"
  L8_2 = {}
  L8_2["@username"] = A2_2
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L7_2 = A1_2
    L8_2 = {}
    L8_2.success = false
    L8_2.error = "USERNAME_TAKEN"
    return L7_2(L8_2)
  end
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.execute
  L8_2 = "INSERT INTO phone_tiktok_accounts (`name`, username, password, phone_number) VALUES (@displayName, @username, @password, @phoneNumber)"
  L9_2 = {}
  L9_2["@displayName"] = A4_2
  L9_2["@username"] = A2_2
  L10_2 = GetPasswordHash
  L11_2 = A3_2
  L10_2 = L10_2(L11_2)
  L9_2["@password"] = L10_2
  L9_2["@phoneNumber"] = L5_2
  L7_2(L8_2, L9_2)
  L7_2 = AddLoggedInAccount
  L8_2 = L5_2
  L9_2 = "TikTok"
  L10_2 = A2_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = A1_2
  L8_2 = {}
  L8_2.success = true
  L7_2(L8_2)
  L7_2 = Config
  L7_2 = L7_2.AutoFollow
  L7_2 = L7_2.Enabled
  if L7_2 then
    L7_2 = Config
    L7_2 = L7_2.AutoFollow
    L7_2 = L7_2.Trendy
    L7_2 = L7_2.Enabled
    if L7_2 then
      L7_2 = Config
      L7_2 = L7_2.AutoFollow
      L7_2 = L7_2.Trendy
      L7_2 = L7_2.Accounts
      L8_2 = 1
      L9_2 = #L7_2
      L10_2 = 1
      for L11_2 = L8_2, L9_2, L10_2 do
        L12_2 = MySQL
        L12_2 = L12_2.update
        L12_2 = L12_2.await
        L13_2 = "INSERT INTO phone_tiktok_follows (followed, follower) VALUES (?, ?)"
        L14_2 = {}
        L15_2 = L7_2[L11_2]
        L16_2 = A2_2
        L14_2[1] = L15_2
        L14_2[2] = L16_2
        L12_2(L13_2, L14_2)
      end
    end
  end
end
L9_1 = {}
L9_1.preventSpam = true
L9_1.rateLimit = 4
L6_1(L7_1, L8_1, L9_1)
L6_1 = L1_1
L7_1 = "changePassword"
function L8_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = Config
  L5_2 = L5_2.ChangePassword
  L5_2 = L5_2.Trendy
  if not L5_2 then
    L5_2 = infoprint
    L6_2 = "warning"
    L7_2 = "%s tried to change password on Trendy, but it's not enabled in the config."
    L8_2 = L7_2
    L7_2 = L7_2.format
    L9_2 = A0_2
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L7_2(L8_2, L9_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L5_2 = false
    return L5_2
  end
  if A3_2 ~= A4_2 then
    L5_2 = #A4_2
    if not (L5_2 < 3) then
      goto lbl_25
    end
  end
  L5_2 = debugprint
  L6_2 = "same password / too short"
  L5_2(L6_2)
  L5_2 = false
  do return L5_2 end
  ::lbl_25::
  L5_2 = MySQL
  L5_2 = L5_2.scalar
  L5_2 = L5_2.await
  L6_2 = "SELECT password FROM phone_tiktok_accounts WHERE username = ?"
  L7_2 = {}
  L8_2 = A2_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  if L5_2 then
    L6_2 = VerifyPasswordHash
    L7_2 = A3_2
    L8_2 = L5_2
    L6_2 = L6_2(L7_2, L8_2)
    if L6_2 then
      goto lbl_44
    end
  end
  L6_2 = false
  do return L6_2 end
  ::lbl_44::
  L6_2 = MySQL
  L6_2 = L6_2.update
  L6_2 = L6_2.await
  L7_2 = "UPDATE phone_tiktok_accounts SET password = ? WHERE username = ?"
  L8_2 = {}
  L9_2 = GetPasswordHash
  L10_2 = A4_2
  L9_2 = L9_2(L10_2)
  L10_2 = A2_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L6_2 = L6_2(L7_2, L8_2)
  L6_2 = L6_2 > 0
  if not L6_2 then
    L7_2 = false
    return L7_2
  end
  L7_2 = L2_1
  L8_2 = A2_2
  L9_2 = {}
  L10_2 = L
  L11_2 = "BACKEND.MISC.LOGGED_OUT_PASSWORD.TITLE"
  L10_2 = L10_2(L11_2)
  L9_2.title = L10_2
  L10_2 = L
  L11_2 = "BACKEND.MISC.LOGGED_OUT_PASSWORD.DESCRIPTION"
  L10_2 = L10_2(L11_2)
  L9_2.content = L10_2
  L10_2 = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = MySQL
  L7_2 = L7_2.update
  L7_2 = L7_2.await
  L8_2 = "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'TikTok' AND phone_number != ?"
  L9_2 = {}
  L10_2 = A2_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L7_2(L8_2, L9_2)
  L7_2 = ClearActiveAccountsCache
  L8_2 = "TikTok"
  L9_2 = A2_2
  L10_2 = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = Log
  L8_2 = "Trendy"
  L9_2 = A0_2
  L10_2 = "info"
  L11_2 = L
  L12_2 = "BACKEND.LOGS.CHANGED_PASSWORD.TITLE"
  L11_2 = L11_2(L12_2)
  L12_2 = L
  L13_2 = "BACKEND.LOGS.CHANGED_PASSWORD.DESCRIPTION"
  L14_2 = {}
  L14_2.number = A1_2
  L14_2.username = A2_2
  L14_2.app = "Trendy"
  L12_2, L13_2, L14_2 = L12_2(L13_2, L14_2)
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = TriggerClientEvent
  L8_2 = "phone:logoutFromApp"
  L9_2 = -1
  L10_2 = {}
  L10_2.username = A2_2
  L10_2.app = "tiktok"
  L10_2.reason = "password"
  L10_2.number = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = true
  return L7_2
end
L9_1 = false
L6_1(L7_1, L8_1, L9_1)
L6_1 = L1_1
L7_1 = "deleteAccount"
function L8_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = Config
  L4_2 = L4_2.DeleteAccount
  L4_2 = L4_2.Trendy
  if not L4_2 then
    L4_2 = infoprint
    L5_2 = "warning"
    L6_2 = "%s tried to delete their account on Trendy, but it's not enabled in the config."
    L7_2 = L6_2
    L6_2 = L6_2.format
    L8_2 = A0_2
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2(L7_2, L8_2)
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L4_2 = false
    return L4_2
  end
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = "SELECT password FROM phone_tiktok_accounts WHERE username = ?"
  L6_2 = {}
  L7_2 = A2_2
  L6_2[1] = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L5_2 = VerifyPasswordHash
    L6_2 = A3_2
    L7_2 = L4_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 then
      goto lbl_34
    end
  end
  L5_2 = false
  do return L5_2 end
  ::lbl_34::
  L5_2 = MySQL
  L5_2 = L5_2.update
  L5_2 = L5_2.await
  L6_2 = "DELETE FROM phone_tiktok_accounts WHERE username = ?"
  L7_2 = {}
  L8_2 = A2_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  L5_2 = L5_2 > 0
  if not L5_2 then
    L6_2 = false
    return L6_2
  end
  L6_2 = L2_1
  L7_2 = A2_2
  L8_2 = {}
  L9_2 = L
  L10_2 = "BACKEND.MISC.DELETED_NOTIFICATION.TITLE"
  L9_2 = L9_2(L10_2)
  L8_2.title = L9_2
  L9_2 = L
  L10_2 = "BACKEND.MISC.DELETED_NOTIFICATION.DESCRIPTION"
  L9_2 = L9_2(L10_2)
  L8_2.content = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = MySQL
  L6_2 = L6_2.update
  L6_2 = L6_2.await
  L7_2 = "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'TikTok'"
  L8_2 = {}
  L9_2 = A2_2
  L8_2[1] = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = ClearActiveAccountsCache
  L7_2 = "TikTok"
  L8_2 = A2_2
  L6_2(L7_2, L8_2)
  L6_2 = Log
  L7_2 = "Trendy"
  L8_2 = A0_2
  L9_2 = "info"
  L10_2 = L
  L11_2 = "BACKEND.LOGS.DELETED_ACCOUNT.TITLE"
  L10_2 = L10_2(L11_2)
  L11_2 = L
  L12_2 = "BACKEND.LOGS.DELETED_ACCOUNT.DESCRIPTION"
  L13_2 = {}
  L13_2.number = A1_2
  L13_2.username = A2_2
  L13_2.app = "Trendy"
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L6_2 = TriggerClientEvent
  L7_2 = "phone:logoutFromApp"
  L8_2 = -1
  L9_2 = {}
  L9_2.username = A2_2
  L9_2.app = "tiktok"
  L9_2.reason = "deleted"
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = true
  return L6_2
end
L9_1 = false
L6_1(L7_1, L8_1, L9_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:logout"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = L0_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = false
    return L3_2(L4_2)
  end
  L3_2 = GetEquippedPhoneNumber
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = RemoveLoggedInAccount
  L5_2 = L3_2
  L6_2 = "TikTok"
  L7_2 = L2_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = A1_2
  L5_2 = true
  L4_2(L5_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:isLoggedIn"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = L0_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2
  if L2_2 then
    L4_2 = L3_1
    L5_2 = L2_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_13
    end
  end
  L4_2 = false
  ::lbl_13::
  L3_2(L4_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:getProfile"
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A1_2
  L4_2 = L3_1
  L5_2 = A2_2
  L6_2 = L0_1
  L7_2 = A0_2
  L6_2, L7_2 = L6_2(L7_2)
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2, L6_2, L7_2)
  L3_2(L4_2, L5_2, L6_2, L7_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:updateProfile"
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = GetEquippedPhoneNumber
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "no_number"
    return L4_2(L5_2)
  end
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "not_logged_in"
    return L5_2(L6_2)
  end
  L5_2 = A2_2.name
  L6_2 = A2_2.bio
  L7_2 = A2_2.avatar
  L8_2 = A2_2.twitter
  L9_2 = A2_2.instagram
  L10_2 = A2_2.show_likes
  L11_2 = #L5_2
  if L11_2 > 30 then
    L11_2 = A1_2
    L12_2 = {}
    L12_2.success = false
    L12_2.error = "display_name_too_long"
    return L11_2(L12_2)
  end
  if L6_2 then
    L11_2 = #L6_2
    L12_2 = 150
    if L11_2 > L12_2 then
      L11_2 = A1_2
      L12_2 = {}
      L12_2.success = false
      L12_2.error = "bio_too_long"
      return L11_2(L12_2)
    end
  end
  if L8_2 then
    L11_2 = MySQL
    L11_2 = L11_2.Sync
    L11_2 = L11_2.fetchScalar
    L12_2 = "SELECT TRUE FROM phone_logged_in_accounts WHERE phone_number = @phoneNumber and app = @app and username = @username"
    L13_2 = {}
    L13_2["@phoneNumber"] = L3_2
    L13_2["@app"] = "Twitter"
    L13_2["@username"] = L8_2
    L11_2 = L11_2(L12_2, L13_2)
    if not L11_2 then
      L12_2 = A1_2
      L13_2 = {}
      L13_2.success = false
      L13_2.error = "invalid_twitter"
      return L12_2(L13_2)
    end
  end
  if L9_2 then
    L11_2 = MySQL
    L11_2 = L11_2.Sync
    L11_2 = L11_2.fetchScalar
    L12_2 = "SELECT TRUE FROM phone_logged_in_accounts WHERE phone_number = @phoneNumber and app = @app and username = @username"
    L13_2 = {}
    L13_2["@phoneNumber"] = L3_2
    L13_2["@app"] = "Instagram"
    L13_2["@username"] = L9_2
    L11_2 = L11_2(L12_2, L13_2)
    if not L11_2 then
      L12_2 = A1_2
      L13_2 = {}
      L13_2.success = false
      L13_2.error = "invalid_instagram"
      return L12_2(L13_2)
    end
  end
  L11_2 = MySQL
  L11_2 = L11_2.Async
  L11_2 = L11_2.execute
  L12_2 = "UPDATE phone_tiktok_accounts SET `name` = @displayName, bio = @bio, avatar = @avatar, twitter = @twitter, instagram = @instagram, `show_likes` = @showLikes WHERE username = @username"
  L13_2 = {}
  L13_2["@displayName"] = L5_2
  L13_2["@bio"] = L6_2
  L13_2["@avatar"] = L7_2
  L13_2["@twitter"] = L8_2
  L13_2["@instagram"] = L9_2
  L14_2 = true == L10_2
  L13_2["@showLikes"] = L14_2
  L13_2["@username"] = L4_2
  function L14_2()
    local L0_3, L1_3
    L0_3 = A1_2
    L1_3 = {}
    L1_3.success = true
    L0_3(L1_3)
  end
  L11_2(L12_2, L13_2, L14_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:searchAccounts"
function L8_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.fetchAll
  L6_2 = [[
        SELECT `name`, username, avatar, verified, follower_count, video_count,
            (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = a.username) AS isFollowing

        FROM phone_tiktok_accounts a
        WHERE username LIKE @query OR `name` LIKE @query
        ORDER BY username
        LIMIT @page, @perPage
    ]]
  L7_2 = {}
  L8_2 = "%"
  L9_2 = A2_2
  L10_2 = "%"
  L8_2 = L8_2 .. L9_2 .. L10_2
  L7_2["@query"] = L8_2
  L7_2["@username"] = L4_2
  L8_2 = A3_2 or L8_2
  if not A3_2 then
    L8_2 = 0
  end
  L8_2 = L8_2 * 10
  L7_2["@page"] = L8_2
  L7_2["@perPage"] = 10
  L8_2 = A1_2
  L5_2(L6_2, L7_2, L8_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:toggleFollow"
function L8_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "not_logged_in"
    return L5_2(L6_2)
  end
  if A2_2 == L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "cannot_follow_self"
    return L5_2(L6_2)
  end
  L5_2 = L3_1
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "invalid_username"
    return L6_2(L7_2)
  end
  L6_2 = A1_2
  L7_2 = {}
  L7_2.success = true
  L6_2(L7_2)
  if true == A3_2 then
    L6_2 = "INSERT IGNORE INTO phone_tiktok_follows (follower, followed) VALUES (@follower, @followed)"
    if L6_2 then
      goto lbl_45
    end
  end
  L6_2 = "DELETE FROM phone_tiktok_follows WHERE follower = @follower AND followed = @followed"
  ::lbl_45::
  L7_2 = MySQL
  L7_2 = L7_2.Async
  L7_2 = L7_2.execute
  L8_2 = L6_2
  L9_2 = {}
  L9_2["@follower"] = L4_2
  L9_2["@followed"] = A2_2
  function L10_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    if 0 == A0_3 then
      return
    end
    L1_3 = A3_2
    if true == L1_3 then
      L1_3 = "add"
      if L1_3 then
        goto lbl_11
      end
    end
    L1_3 = "remove"
    ::lbl_11::
    L2_3 = TriggerClientEvent
    L3_3 = "phone:tiktok:updateFollowers"
    L4_3 = -1
    L5_3 = A2_2
    L6_3 = L1_3
    L2_3(L3_3, L4_3, L5_3, L6_3)
    L2_3 = TriggerClientEvent
    L3_3 = "phone:tiktok:updateFollowing"
    L4_3 = -1
    L5_3 = L4_2
    L6_3 = L1_3
    L2_3(L3_3, L4_3, L5_3, L6_3)
    L2_3 = A3_2
    if true == L2_3 then
      L2_3 = L5_1
      L3_3 = A2_2
      L4_3 = L4_2
      L5_3 = "follow"
      L2_3(L3_3, L4_3, L5_3)
    end
  end
  L7_2(L8_2, L9_2, L10_2)
end
L9_1 = {}
L9_1.preventSpam = true
L6_1(L7_1, L8_1, L9_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:getFollowing"
function L8_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.fetchAll
  L6_2 = [[
        SELECT
            a.username, a.`name`, a.avatar, a.verified,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = a.username AND followed = @loggedIn) AS isFollowingYou,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @loggedIn AND followed = a.username) AS isFollowing
        FROM phone_tiktok_follows f
        INNER JOIN phone_tiktok_accounts a ON a.username = f.followed
        WHERE f.follower = @username
        ORDER BY a.username
        LIMIT @page, @perPage
    ]]
  L7_2 = {}
  L7_2["@username"] = A2_2
  L7_2["@loggedIn"] = L4_2
  L8_2 = A3_2 or L8_2
  if not A3_2 then
    L8_2 = 0
  end
  L8_2 = L8_2 * 15
  L7_2["@page"] = L8_2
  L7_2["@perPage"] = 15
  L8_2 = A1_2
  L5_2(L6_2, L7_2, L8_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:getFollowers"
function L8_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.fetchAll
  L6_2 = [[
        SELECT
            a.username, a.`name`, a.avatar, a.verified,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = @loggedIn) AS isFollowingYou,
                (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @loggedIn AND followed = @username) AS isFollowing
        FROM phone_tiktok_follows f
        INNER JOIN phone_tiktok_accounts a ON a.username = f.follower
        WHERE f.followed = @username
        ORDER BY a.username
        LIMIT @page, @perPage
    ]]
  L7_2 = {}
  L7_2["@username"] = A2_2
  L7_2["@loggedIn"] = L4_2
  L8_2 = A3_2 or L8_2
  if not A3_2 then
    L8_2 = 0
  end
  L8_2 = L8_2 * 15
  L7_2["@page"] = L8_2
  L7_2["@perPage"] = 15
  L8_2 = A1_2
  L5_2(L6_2, L7_2, L8_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:uploadVideo"
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = L0_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "not_logged_in"
    return L4_2(L5_2)
  else
    L4_2 = ContainsBlacklistedWord
    L5_2 = A0_2
    L6_2 = "Trendy"
    L7_2 = A2_2.caption
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    if L4_2 then
      L4_2 = A1_2
      L5_2 = false
      return L4_2(L5_2)
    else
      L4_2 = A2_2.src
      if L4_2 then
        L4_2 = type
        L5_2 = A2_2.src
        L4_2 = L4_2(L5_2)
        if "string" == L4_2 then
          L4_2 = A2_2.src
          L4_2 = #L4_2
          if 0 ~= L4_2 then
            goto lbl_46
          end
        end
      end
      L4_2 = A1_2
      L5_2 = {}
      L5_2.success = false
      L5_2.error = "invalid_src"
      do return L4_2(L5_2) end
      goto lbl_65
      ::lbl_46::
      L4_2 = A2_2.caption
      if L4_2 then
        L4_2 = type
        L5_2 = A2_2.caption
        L4_2 = L4_2(L5_2)
        if "string" == L4_2 then
          L4_2 = A2_2.caption
          L4_2 = #L4_2
          if 0 ~= L4_2 then
            goto lbl_65
          end
        end
      end
      L4_2 = A1_2
      L5_2 = {}
      L5_2.success = false
      L5_2.error = "invalid_caption"
      return L4_2(L5_2)
    end
  end
  ::lbl_65::
  L4_2 = GenerateId
  L5_2 = "phone_tiktok_videos"
  L6_2 = "id"
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.execute
  L6_2 = "INSERT INTO phone_tiktok_videos (id, username, src, caption, metadata, music) VALUES (@id, @username, @src, @caption, @metadata, @music)"
  L7_2 = {}
  L7_2["@id"] = L4_2
  L7_2["@username"] = L3_2
  L8_2 = A2_2.src
  L7_2["@src"] = L8_2
  L8_2 = A2_2.caption
  L7_2["@caption"] = L8_2
  L8_2 = A2_2.metadata
  L7_2["@metadata"] = L8_2
  L8_2 = A2_2.music
  L7_2["@music"] = L8_2
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L0_3 = A1_2
    L1_3 = {}
    L1_3.success = true
    L2_3 = L4_2
    L1_3.id = L2_3
    L0_3(L1_3)
    L0_3 = {}
    L1_3 = L3_2
    L0_3.username = L1_3
    L1_3 = A2_2.caption
    L0_3.caption = L1_3
    L1_3 = A2_2.src
    L0_3.videoUrl = L1_3
    L1_3 = L4_2
    L0_3.id = L1_3
    L1_3 = TriggerClientEvent
    L2_3 = "phone:tiktok:newVideo"
    L3_3 = -1
    L4_3 = L0_3
    L1_3(L2_3, L3_3, L4_3)
    L1_3 = TriggerEvent
    L2_3 = "lb-phone:trendy:newPost"
    L3_3 = L0_3
    L1_3(L2_3, L3_3)
    L1_3 = TrackSocialMediaPost
    L2_3 = "trendy"
    L3_3 = {}
    L4_3 = A2_2.src
    L3_3[1] = L4_3
    L1_3(L2_3, L3_3)
    L1_3 = Log
    L2_3 = "Trendy"
    L3_3 = A0_2
    L4_3 = "success"
    L5_3 = L
    L6_3 = "BACKEND.LOGS.TRENDY_UPLOAD_TITLE"
    L5_3 = L5_3(L6_3)
    L6_3 = L
    L7_3 = "BACKEND.LOGS.TRENDY_UPLOAD_DESCRIPTION"
    L8_3 = {}
    L9_3 = L3_2
    L8_3.username = L9_3
    L9_3 = A2_2.caption
    L8_3.caption = L9_3
    L9_3 = L4_2
    L8_3.id = L9_3
    L6_3, L7_3, L8_3, L9_3 = L6_3(L7_3, L8_3)
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
  end
  L5_2(L6_2, L7_2, L8_2)
end
L9_1 = {}
L9_1.preventSpam = true
L9_1.rateLimit = 6
L6_1(L7_1, L8_1, L9_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:deleteVideo"
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = L0_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "not_logged_in"
    return L4_2(L5_2)
  end
  L4_2 = "DELETE FROM phone_tiktok_videos WHERE id = @id"
  L5_2 = IsAdmin
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = L4_2
    L6_2 = " AND username = @username"
    L5_2 = L5_2 .. L6_2
    L4_2 = L5_2
  end
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.execute
  L6_2 = L4_2
  L7_2 = {}
  L7_2["@id"] = A2_2
  L7_2["@username"] = L3_2
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L1_3 = A1_2
    L2_3 = {}
    L3_3 = A0_3 > 0
    L2_3.success = L3_3
    L1_3(L2_3)
    if A0_3 > 0 then
      L1_3 = Log
      L2_3 = "Trendy"
      L3_3 = A0_2
      L4_3 = "error"
      L5_3 = L
      L6_3 = "BACKEND.LOGS.TRENDY_DELETE_TITLE"
      L5_3 = L5_3(L6_3)
      L6_3 = L
      L7_3 = "BACKEND.LOGS.TRENDY_DELETE_DESCRIPTION"
      L8_3 = {}
      L9_3 = L3_2
      L8_3.username = L9_3
      L9_3 = A2_2
      L8_3.id = L9_3
      L6_3, L7_3, L8_3, L9_3 = L6_3(L7_3, L8_3)
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
    end
  end
  L5_2(L6_2, L7_2, L8_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "tiktok:togglePinnedVideo"
function L8_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "not_logged_in"
    return L5_2(L6_2)
  end
  if A3_2 then
    L5_2 = MySQL
    L5_2 = L5_2.Sync
    L5_2 = L5_2.fetchScalar
    L6_2 = "SELECT COUNT(*) FROM phone_tiktok_pinned_videos WHERE username = @username"
    L7_2 = {}
    L7_2["@username"] = L4_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 >= 3 and A3_2 then
      L6_2 = A1_2
      L7_2 = {}
      L7_2.success = false
      L7_2.error = "max_pinned"
      return L6_2(L7_2)
    end
  end
  L5_2 = nil
  if A3_2 then
    L5_2 = "INSERT INTO phone_tiktok_pinned_videos (username, video_id) VALUES (@username, @videoId)"
  else
    L5_2 = "DELETE FROM phone_tiktok_pinned_videos WHERE username = @username AND video_id = @videoId"
  end
  L6_2 = MySQL
  L6_2 = L6_2.Async
  L6_2 = L6_2.execute
  L7_2 = L5_2
  L8_2 = {}
  L8_2["@videoId"] = A2_2
  L8_2["@username"] = L4_2
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A1_2
    L2_3 = {}
    L3_3 = A0_3 > 0
    L2_3.success = L3_3
    L1_3(L2_3)
  end
  L6_2(L7_2, L8_2, L9_2)
end
L6_1(L7_1, L8_1)
L6_1 = [[
    SELECT
        v.id, v.src, v.caption, v.`timestamp`,
        p.video_id IS NOT NULL AS pinned,

        v.likes, v.comments, v.views, v.saves,
        (SELECT TRUE FROM phone_tiktok_likes WHERE username = @loggedIn AND video_id = v.id) AS liked,
        (SELECT TRUE FROM phone_tiktok_saves WHERE username = @loggedIn AND video_id = v.id) AS saved,
        w.video_id IS NOT NULL AS viewed,

        v.metadata, v.music,

        a.username, a.`name`, a.avatar, a.verified,
        (SELECT TRUE FROM phone_tiktok_follows WHERE follower = @username AND followed = a.username) AS following

    FROM phone_tiktok_videos v
    INNER JOIN phone_tiktok_accounts a ON a.username = v.username
    LEFT JOIN phone_tiktok_views w ON v.id = w.video_id AND w.username = @loggedIn
    LEFT JOIN phone_tiktok_pinned_videos p ON p.video_id = v.id AND p.username = @loggedIn
]]
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:getVideo"
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L0_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "not_logged_in"
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.fetchAll
  L5_2 = L6_1
  L6_2 = [[
        WHERE v.id = @id
    ]]
  L5_2 = L5_2 .. L6_2
  L6_2 = {}
  L6_2["@id"] = A2_2
  L6_2["@loggedIn"] = L3_2
  L6_2["@username"] = L3_2
  function L7_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = #A0_3
    if 0 == L1_3 then
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "invalid_id"
      return L1_3(L2_3)
    end
    L1_3 = A0_3[1]
    L2_3 = A1_2
    L3_3 = {}
    L3_3.success = true
    L3_3.video = L1_3
    L2_3(L3_3)
  end
  L4_2(L5_2, L6_2, L7_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:getVideos"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    return L5_2(L6_2)
  end
  L5_2 = nil
  L6_2 = nil
  L7_2 = A2_2.full
  if L7_2 then
    L7_2 = A2_2.type
    if "recent" == L7_2 then
      L7_2 = A2_2.id
      if L7_2 then
        L7_2 = A2_2.username
        if L7_2 then
          L7_2 = L6_1
          L8_2 = [[
                        WHERE v.username = @username AND v.`timestamp` %s (SELECT `timestamp` FROM phone_tiktok_videos WHERE id = @id)
                        ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                        LIMIT @page, @perPage
                    ]]
          L9_2 = L8_2
          L8_2 = L8_2.format
          L10_2 = A2_2.backwards
          if L10_2 then
            L10_2 = ">"
            if L10_2 then
              goto lbl_34
            end
          end
          L10_2 = "<"
          ::lbl_34::
          L8_2 = L8_2(L9_2, L10_2)
          L7_2 = L7_2 .. L8_2
          L5_2 = L7_2
        else
          L7_2 = L6_1
          L8_2 = [[
                        WHERE v.username != @loggedIn AND v.`timestamp` %s (SELECT `timestamp` FROM phone_tiktok_videos WHERE id = @id)
                        ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                        LIMIT @page, @perPage
                    ]]
          L9_2 = L8_2
          L8_2 = L8_2.format
          L10_2 = A2_2.backwards
          if L10_2 then
            L10_2 = ">"
            if L10_2 then
              goto lbl_48
            end
          end
          L10_2 = "<"
          ::lbl_48::
          L8_2 = L8_2(L9_2, L10_2)
          L7_2 = L7_2 .. L8_2
          L5_2 = L7_2
        end
      else
        L7_2 = L6_1
        L8_2 = [[
                    WHERE v.username != @loggedIn
                    ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                    LIMIT @page, @perPage
                ]]
        L7_2 = L7_2 .. L8_2
        L5_2 = L7_2
      end
    else
      L7_2 = A2_2.type
      if "following" == L7_2 then
        L7_2 = L6_1
        L8_2 = [[
                INNER JOIN phone_tiktok_follows f ON f.followed = v.username
                WHERE f.follower = @loggedIn
                ORDER BY (w.username IS NOT NULL), v.timestamp DESC
                LIMIT @page, @perPage
            ]]
        L7_2 = L7_2 .. L8_2
        L5_2 = L7_2
      end
    end
    L6_2 = 5
  else
    L7_2 = A2_2.type
    if "recent" == L7_2 then
      L7_2 = A2_2.username
      if L7_2 then
        if 0 == A3_2 then
          L5_2 = [[
                        SELECT
                            v.id, v.src, v.views,
                            p.video_id IS NOT NULL AS pinned
                        FROM phone_tiktok_videos v
                        LEFT JOIN phone_tiktok_pinned_videos p ON p.video_id = v.id AND p.username = @username
                        WHERE v.username = @username
                        ORDER BY (p.video_id IS NOT NULL) DESC, v.`timestamp` DESC
                        LIMIT @page, @perPage
                    ]]
        else
          L5_2 = [[
                        SELECT id, src, views
                        FROM phone_tiktok_videos
                        WHERE username = @username
                        ORDER BY `timestamp` DESC
                        LIMIT @page, @perPage
                    ]]
        end
      else
      end
    else
      L7_2 = A2_2.type
      if "liked" == L7_2 then
        L5_2 = [[
                SELECT v.id, v.src, v.views
                FROM phone_tiktok_videos v
                INNER JOIN phone_tiktok_likes l ON l.video_id = v.id
                WHERE l.username = @username
                ORDER BY v.`timestamp` DESC
                LIMIT @page, @perPage
            ]]
      else
        L7_2 = A2_2.type
        if "saved" == L7_2 then
          L7_2 = A2_2.username
          if L4_2 ~= L7_2 then
            L7_2 = debugprint
            L8_2 = "wrong account"
            L9_2 = L4_2
            L10_2 = #L4_2
            L11_2 = A2_2.username
            L12_2 = A2_2.username
            L12_2 = #L12_2
            L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
            L7_2 = A1_2
            L8_2 = {}
            return L7_2(L8_2)
          end
          L5_2 = [[
                SELECT v.id, v.src, v.views
                FROM phone_tiktok_videos v
                INNER JOIN phone_tiktok_saves s ON s.video_id = v.id
                WHERE s.username = @username
                ORDER BY v.`timestamp` DESC
                LIMIT @page, @perPage
            ]]
        end
      end
    end
    L6_2 = 15
  end
  if not L5_2 then
    L7_2 = A1_2
    L8_2 = {}
    return L7_2(L8_2)
  end
  L7_2 = MySQL
  L7_2 = L7_2.Async
  L7_2 = L7_2.fetchAll
  L8_2 = L5_2
  L9_2 = {}
  L10_2 = A2_2.username
  L9_2["@username"] = L10_2
  L9_2["@loggedIn"] = L4_2
  L10_2 = A2_2.id
  L9_2["@id"] = L10_2
  L10_2 = A3_2 or L10_2
  if not A3_2 then
    L10_2 = 0
  end
  L10_2 = L10_2 * L6_2
  L9_2["@page"] = L10_2
  L9_2["@perPage"] = L6_2
  L10_2 = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = L5_2
  L8_2 = " LIMIT @page, @perPage"
  L7_2 = L7_2 .. L8_2
  L5_2 = L7_2
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNetEvent
L8_1 = "phone:tiktok:setViewed"
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L0_1
  L2_2 = source
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = MySQL
  L2_2 = L2_2.Async
  L2_2 = L2_2.execute
  L3_2 = "INSERT IGNORE INTO phone_tiktok_views (username, video_id) VALUES (@username, @videoId)"
  L4_2 = {}
  L4_2["@username"] = L1_2
  L4_2["@videoId"] = A0_2
  L2_2(L3_2, L4_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:toggleVideoAction"
function L9_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if "like" ~= A2_2 and "save" ~= A2_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "invalid_action"
    return L5_2(L6_2)
  end
  L5_2 = L0_1
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "not_logged_in"
    return L6_2(L7_2)
  end
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.fetchScalar
  L7_2 = "SELECT username FROM phone_tiktok_videos WHERE id = @id"
  L8_2 = {}
  L8_2["@id"] = A3_2
  L6_2 = L6_2(L7_2, L8_2)
  if not L6_2 then
    L7_2 = A1_2
    L8_2 = {}
    L8_2.success = false
    L8_2.error = "invalid_id"
    return L7_2(L8_2)
  end
  L7_2 = A1_2
  L8_2 = {}
  L8_2.success = true
  L7_2(L8_2)
  if true == A4_2 then
    L7_2 = "INSERT IGNORE INTO phone_tiktok_%s (username, video_id) VALUES (@username, @videoId)"
    if L7_2 then
      goto lbl_52
    end
  end
  L7_2 = "DELETE FROM phone_tiktok_%s WHERE username = @username AND video_id = @videoId"
  ::lbl_52::
  L9_2 = L7_2
  L8_2 = L7_2.format
  if "like" == A2_2 then
    L10_2 = "likes"
    if L10_2 then
      goto lbl_59
    end
  end
  L10_2 = "saves"
  ::lbl_59::
  L8_2 = L8_2(L9_2, L10_2)
  L7_2 = L8_2
  L8_2 = MySQL
  L8_2 = L8_2.Async
  L8_2 = L8_2.execute
  L9_2 = L7_2
  L10_2 = {}
  L10_2["@username"] = L5_2
  L10_2["@videoId"] = A3_2
  function L11_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    if 0 == A0_3 then
      return
    end
    L1_3 = TriggerClientEvent
    L2_3 = "phone:tiktok:updateVideoStats"
    L3_3 = -1
    L4_3 = A2_2
    L5_3 = A3_2
    L6_3 = A4_2
    if true == L6_3 then
      L6_3 = "add"
      if L6_3 then
        goto lbl_16
      end
    end
    L6_3 = "remove"
    ::lbl_16::
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L1_3 = A4_2
    if L1_3 then
      L1_3 = L5_1
      L2_3 = L6_2
      L3_3 = L5_2
      L4_3 = A2_2
      L5_3 = A3_2
      L1_3(L2_3, L3_3, L4_3, L5_3)
    end
  end
  L8_2(L9_2, L10_2, L11_2)
end
L10_1 = {}
L10_1.preventSpam = true
L10_1.rateLimit = 30
L7_1(L8_1, L9_1, L10_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:postComment"
function L9_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L5_2 = L0_1
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "not_logged_in"
    return L6_2(L7_2)
  end
  if A4_2 then
    L6_2 = #A4_2
    if 0 ~= L6_2 then
      L6_2 = #A4_2
      L7_2 = 500
      if not (L6_2 > L7_2) then
        goto lbl_29
      end
    end
  end
  L6_2 = A1_2
  L7_2 = {}
  L7_2.success = false
  L7_2.error = "invalid_comment"
  do return L6_2(L7_2) end
  ::lbl_29::
  L6_2 = ContainsBlacklistedWord
  L7_2 = A0_2
  L8_2 = "Trendy"
  L9_2 = A4_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A1_2
    L7_2 = false
    return L6_2(L7_2)
  end
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.fetchScalar
  L7_2 = "SELECT username FROM phone_tiktok_videos WHERE id = @id"
  L8_2 = {}
  L8_2["@id"] = A2_2
  L6_2 = L6_2(L7_2, L8_2)
  if not L6_2 then
    L7_2 = A1_2
    L8_2 = {}
    L8_2.success = false
    L8_2.error = "invalid_id"
    return L7_2(L8_2)
  end
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.fetchScalar
  L8_2 = "SELECT username FROM phone_tiktok_comments WHERE id = @id"
  L9_2 = {}
  L9_2["@id"] = A3_2
  L7_2 = not A3_2 or L7_2
  if not L7_2 then
    L8_2 = A1_2
    L9_2 = {}
    L9_2.success = false
    L9_2.error = "invalid_reply_to"
    return L8_2(L9_2)
  end
  L8_2 = GenerateId
  L9_2 = "phone_tiktok_comments"
  L10_2 = "id"
  L8_2 = L8_2(L9_2, L10_2)
  L9_2 = MySQL
  L9_2 = L9_2.Async
  L9_2 = L9_2.execute
  L10_2 = "INSERT INTO phone_tiktok_comments (id, reply_to, video_id, username, comment) VALUES (@id, @replyTo, @videoId, @loggedIn, @comment)"
  L11_2 = {}
  L11_2["@id"] = L8_2
  L11_2["@replyTo"] = A3_2
  L11_2["@videoId"] = A2_2
  L11_2["@loggedIn"] = L5_2
  L11_2["@comment"] = A4_2
  function L12_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    if 0 == A0_3 then
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "failed_insert"
      return L1_3(L2_3)
    end
    L1_3 = TriggerClientEvent
    L2_3 = "phone:tiktok:updateVideoStats"
    L3_3 = -1
    L4_3 = "comment"
    L5_3 = A2_2
    L6_3 = "add"
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L1_3 = A3_2
    if L1_3 then
      L1_3 = MySQL
      L1_3 = L1_3.Async
      L1_3 = L1_3.execute
      L2_3 = "UPDATE phone_tiktok_comments SET replies = replies + 1 WHERE id = @id"
      L3_3 = {}
      L4_3 = A3_2
      L3_3["@id"] = L4_3
      L1_3(L2_3, L3_3)
      L1_3 = TriggerClientEvent
      L2_3 = "phone:tiktok:updateCommentStats"
      L3_3 = -1
      L4_3 = "reply"
      L5_3 = A3_2
      L6_3 = "add"
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
      L1_3 = L5_1
      L2_3 = L7_2
      L3_3 = L5_2
      L4_3 = "reply"
      L5_3 = A2_2
      L6_3 = L8_2
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    end
    L1_3 = A1_2
    L2_3 = {}
    L2_3.success = true
    L3_3 = L8_2
    L2_3.id = L3_3
    L1_3(L2_3)
    L1_3 = L5_1
    L2_3 = L6_2
    L3_3 = L5_2
    L4_3 = "comment"
    L5_3 = A2_2
    L6_3 = L8_2
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
  end
  L9_2(L10_2, L11_2, L12_2)
end
L10_1 = {}
L10_1.preventSpam = true
L10_1.rateLimit = 10
L7_1(L8_1, L9_1, L10_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:deleteComment"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "not_logged_in"
    return L5_2(L6_2)
  end
  L5_2 = ""
  L6_2 = IsAdmin
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L5_2 = " AND username = @username"
  end
  L6_2 = 0
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.fetchScalar
  L8_2 = "SELECT reply_to FROM phone_tiktok_comments WHERE id = @id"
  L9_2 = L5_2
  L8_2 = L8_2 .. L9_2
  L9_2 = {}
  L9_2["@id"] = A2_2
  L9_2["@username"] = L4_2
  L7_2 = L7_2(L8_2, L9_2)
  if L7_2 then
    L8_2 = MySQL
    L8_2 = L8_2.Async
    L8_2 = L8_2.execute
    L9_2 = "UPDATE phone_tiktok_comments SET replies = replies - 1 WHERE id = @id"
    L10_2 = {}
    L10_2["@id"] = L7_2
    L8_2(L9_2, L10_2)
    L8_2 = TriggerClientEvent
    L9_2 = "phone:tiktok:updateCommentStats"
    L10_2 = -1
    L11_2 = "reply"
    L12_2 = L7_2
    L13_2 = "remove"
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
  else
    L8_2 = MySQL
    L8_2 = L8_2.Sync
    L8_2 = L8_2.fetchScalar
    L9_2 = "SELECT COUNT(*) FROM phone_tiktok_comments WHERE reply_to = @id"
    L10_2 = {}
    L10_2["@id"] = A2_2
    L8_2 = L8_2(L9_2, L10_2)
    L6_2 = L8_2
  end
  L8_2 = MySQL
  L8_2 = L8_2.Async
  L8_2 = L8_2.execute
  L9_2 = "DELETE FROM phone_tiktok_comments WHERE id = @id"
  L10_2 = L5_2
  L9_2 = L9_2 .. L10_2
  L10_2 = {}
  L10_2["@id"] = A2_2
  L10_2["@username"] = L4_2
  function L11_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    if A0_3 > 0 then
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = true
      L1_3(L2_3)
      L1_3 = TriggerClientEvent
      L2_3 = "phone:tiktok:updateVideoStats"
      L3_3 = -1
      L4_3 = "comment"
      L5_3 = A3_2
      L6_3 = "remove"
      L7_3 = L6_2
      L7_3 = L7_3 + 1
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3)
    else
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "failed_delete"
      L1_3(L2_3)
    end
  end
  L8_2(L9_2, L10_2, L11_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:setPinnedComment"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "not_logged_in"
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Sync
  L5_2 = L5_2.fetchScalar
  L6_2 = "SELECT TRUE FROM phone_tiktok_videos WHERE id = @id AND username = @username"
  L7_2 = {}
  L7_2["@id"] = A3_2
  L7_2["@username"] = L4_2
  L5_2 = L5_2(L6_2, L7_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "invalid_id"
    return L6_2(L7_2)
  end
  if nil ~= A2_2 then
    L6_2 = MySQL
    L6_2 = L6_2.Sync
    L6_2 = L6_2.fetchScalar
    L7_2 = "SELECT TRUE FROM phone_tiktok_comments WHERE id = @id AND username = @username"
    L8_2 = {}
    L8_2["@id"] = A2_2
    L8_2["@username"] = L4_2
    L6_2 = L6_2(L7_2, L8_2)
    if not L6_2 then
      L7_2 = A1_2
      L8_2 = {}
      L8_2.success = false
      L8_2.error = "invalid_comment"
      return L7_2(L8_2)
    end
  end
  L6_2 = MySQL
  L6_2 = L6_2.Async
  L6_2 = L6_2.execute
  L7_2 = "UPDATE phone_tiktok_videos SET pinned_comment = @commentId WHERE id = @id"
  L8_2 = {}
  L8_2["@commentId"] = A2_2
  L8_2["@id"] = A3_2
  function L9_2(A0_3)
    local L1_3, L2_3
    if A0_3 > 0 then
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = true
      L1_3(L2_3)
    else
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "failed_update"
      L1_3(L2_3)
    end
  end
  L6_2(L7_2, L8_2, L9_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:getComments"
function L9_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L6_2 = L0_1
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L7_2 = A1_2
    L8_2 = {}
    L8_2.success = false
    L8_2.error = "not_logged_in"
    return L7_2(L8_2)
  end
  L7_2 = [[
        SELECT
            a.username, a.`name`, a.avatar, a.verified,
            c.id, c.comment, c.likes, c.replies AS reply_count, c.`timestamp`,
            (SELECT TRUE FROM phone_tiktok_comments_likes WHERE username = @loggedIn AND comment_id = c.id) AS liked,
            (SELECT TRUE FROM phone_tiktok_comments_likes WHERE username = @creator AND comment_id = c.id) AS creator_liked

        FROM phone_tiktok_comments c
        INNER JOIN phone_tiktok_accounts a ON a.username = c.username

        WHERE c.video_id = @videoId
    ]]
  if A3_2 then
    L8_2 = L7_2
    L9_2 = " AND c.reply_to = @replyTo"
    L8_2 = L8_2 .. L9_2
    L7_2 = L8_2
  else
    L8_2 = L7_2
    L9_2 = " AND c.reply_to IS NULL"
    L8_2 = L8_2 .. L9_2
    L7_2 = L8_2
  end
  L8_2 = L7_2
  L9_2 = " ORDER BY c.`timestamp` DESC LIMIT @page, @perPage"
  L8_2 = L8_2 .. L9_2
  L7_2 = L8_2
  L8_2 = MySQL
  L8_2 = L8_2.Async
  L8_2 = L8_2.fetchAll
  L9_2 = L7_2
  L10_2 = {}
  L10_2["@loggedIn"] = L6_2
  L10_2["@creator"] = A4_2
  L10_2["@videoId"] = A2_2
  L10_2["@replyTo"] = A3_2
  L11_2 = A5_2 or L11_2
  if not A5_2 then
    L11_2 = 0
  end
  L11_2 = L11_2 * 15
  L10_2["@page"] = L11_2
  L10_2["@perPage"] = 15
  function L11_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = {}
    L2_3.success = true
    L2_3.comments = A0_3
    L1_3(L2_3)
  end
  L8_2(L9_2, L10_2, L11_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:toggleLikeComment"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "not_logged_in"
    return L5_2(L6_2)
  end
  if not A2_2 or nil == A3_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "invalid_data"
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Sync
  L5_2 = L5_2.fetchAll
  L6_2 = "SELECT username, video_id FROM phone_tiktok_comments WHERE id = @id"
  L7_2 = {}
  L7_2["@id"] = A2_2
  L5_2 = L5_2(L6_2, L7_2)
  L5_2 = L5_2[1]
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "invalid_id"
    return L6_2(L7_2)
  end
  if true == A3_2 then
    L6_2 = "INSERT IGNORE INTO phone_tiktok_comments_likes (username, comment_id) VALUES (@username, @commentId)"
    if L6_2 then
      goto lbl_48
    end
  end
  L6_2 = "DELETE FROM phone_tiktok_comments_likes WHERE username = @username AND comment_id = @commentId"
  ::lbl_48::
  L7_2 = MySQL
  L7_2 = L7_2.Async
  L7_2 = L7_2.execute
  L8_2 = L6_2
  L9_2 = {}
  L9_2["@username"] = L4_2
  L9_2["@commentId"] = A2_2
  function L10_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L1_3 = A1_2
    L2_3 = {}
    L2_3.success = true
    L1_3(L2_3)
    if 0 == A0_3 then
      L1_3 = debugprint
      L2_3 = "Failed to toggle like comment, no rows changed"
      return L1_3(L2_3)
    end
    L1_3 = TriggerClientEvent
    L2_3 = "phone:tiktok:updateCommentStats"
    L3_3 = -1
    L4_3 = "like"
    L5_3 = A2_2
    L6_3 = A3_2
    if true == L6_3 then
      L6_3 = "add"
      if L6_3 then
        goto lbl_24
      end
    end
    L6_3 = "remove"
    ::lbl_24::
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L1_3 = A3_2
    if L1_3 then
      L1_3 = L5_1
      L2_3 = L5_2.username
      L3_3 = L4_2
      L4_3 = "like_comment"
      L5_3 = L5_2.video_id
      L6_3 = A2_2
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    end
  end
  L7_2(L8_2, L9_2, L10_2)
end
L10_1 = {}
L10_1.preventSpam = true
L7_1(L8_1, L9_1, L10_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:getRecentMessages"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L0_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    L4_2.success = false
    L4_2.error = "not_logged_in"
    return L3_2(L4_2)
  end
  L3_2 = MySQL
  L3_2 = L3_2.Async
  L3_2 = L3_2.fetchAll
  L4_2 = [[
        SELECT
            id, last_message, `timestamp`,
            a.username, a.`name`, a.avatar, a.verified, a.follower_count, a.following_count,
            (SELECT COALESCE(amount, 0) FROM phone_tiktok_unread_messages WHERE channel_id = id AND username = @loggedIn) AS unread_messages

        FROM phone_tiktok_channels
        INNNER JOIN phone_tiktok_accounts a ON a.username = IF(member_1 = @loggedIn, member_2, member_1)
        WHERE member_1 = @loggedIn OR member_2 = @loggedIn ORDER BY `timestamp` DESC
    ]]
  L5_2 = {}
  L5_2["@loggedIn"] = L2_2
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = {}
    L2_3.success = true
    L2_3.channels = A0_3
    L1_3(L2_3)
  end
  L3_2(L4_2, L5_2, L6_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:getMessages"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = L0_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "not_logged_in"
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Sync
  L5_2 = L5_2.fetchScalar
  L6_2 = "SELECT TRUE FROM phone_tiktok_channels WHERE id = @id AND (member_1 = @loggedIn OR member_2 = @loggedIn)"
  L7_2 = {}
  L7_2["@id"] = A2_2
  L7_2["@loggedIn"] = L4_2
  L5_2 = L5_2(L6_2, L7_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "invalid_id"
    return L6_2(L7_2)
  end
  L6_2 = MySQL
  L6_2 = L6_2.Async
  L6_2 = L6_2.fetchAll
  L7_2 = "SELECT id, sender, content, `timestamp` FROM phone_tiktok_messages WHERE channel_id = @channelId ORDER BY `timestamp` DESC LIMIT @page, @perPage"
  L8_2 = {}
  L8_2["@channelId"] = A2_2
  L9_2 = A3_2 or L9_2
  if not A3_2 then
    L9_2 = 0
  end
  L9_2 = L9_2 * 25
  L8_2["@page"] = L9_2
  L8_2["@perPage"] = 25
  function L9_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = {}
    L2_3.success = true
    L2_3.messages = A0_3
    L1_3(L2_3)
  end
  L6_2(L7_2, L8_2, L9_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:getUnreadMessages"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L0_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    L4_2.success = false
    L4_2.error = "not_logged_in"
    return L3_2(L4_2)
  end
  L3_2 = MySQL
  L3_2 = L3_2.Async
  L3_2 = L3_2.fetchScalar
  L4_2 = "SELECT COUNT(*) FROM phone_tiktok_unread_messages WHERE username = @username AND amount > 0"
  L5_2 = {}
  L5_2["@username"] = L2_2
  function L6_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = {}
    L2_3.success = true
    L2_3.unread = A0_3
    L1_3(L2_3)
  end
  L3_2(L4_2, L5_2, L6_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNetEvent
L8_1 = "phone:tiktok:clearUnreadMessages"
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L0_1
  L2_2 = source
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = MySQL
  L2_2 = L2_2.Async
  L2_2 = L2_2.execute
  L3_2 = "UPDATE phone_tiktok_unread_messages SET amount = 0 WHERE username = @username AND channel_id = @channelId"
  L4_2 = {}
  L4_2["@username"] = L1_2
  L4_2["@channelId"] = A0_2
  L2_2(L3_2, L4_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:sendMessage"
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = L0_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "not_logged_in"
    return L4_2(L5_2)
  end
  L4_2 = ContainsBlacklistedWord
  L5_2 = A0_2
  L6_2 = "Trendy"
  L7_2 = A2_2.content
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  if L4_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = A2_2.id
  L5_2 = A2_2.content
  L6_2 = A2_2.username
  if not L4_2 then
    if not L6_2 then
      L7_2 = A1_2
      L8_2 = {}
      L8_2.success = false
      L8_2.error = "invalid_id"
      return L7_2(L8_2)
    end
    L7_2 = MySQL
    L7_2 = L7_2.Sync
    L7_2 = L7_2.fetchScalar
    L8_2 = "SELECT id FROM phone_tiktok_channels WHERE (member_1 = @loggedIn AND member_2 = @username) OR (member_1 = @username AND member_2 = @loggedIn)"
    L9_2 = {}
    L9_2["@loggedIn"] = L3_2
    L9_2["@username"] = L6_2
    L7_2 = L7_2(L8_2, L9_2)
    L4_2 = L7_2
    if not L4_2 then
      L7_2 = GenerateId
      L8_2 = "phone_tiktok_channels"
      L9_2 = "id"
      L7_2 = L7_2(L8_2, L9_2)
      L4_2 = L7_2
      L7_2 = MySQL
      L7_2 = L7_2.Sync
      L7_2 = L7_2.execute
      L8_2 = "INSERT IGNORE INTO phone_tiktok_channels (id, last_message, member_1, member_2) VALUES (@id, @message, @member_1, @member_2)"
      L9_2 = {}
      L9_2["@id"] = L4_2
      L9_2["@message"] = L5_2
      L9_2["@member_1"] = L3_2
      L9_2["@member_2"] = L6_2
      L7_2 = L7_2(L8_2, L9_2)
      L7_2 = L7_2 > 0
      if not L7_2 then
        L8_2 = A1_2
        L9_2 = {}
        L9_2.success = false
        L9_2.error = "failed_create_channel"
        return L8_2(L9_2)
      end
    end
  end
  L7_2 = GenerateId
  L8_2 = "phone_tiktok_messages"
  L9_2 = "id"
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = MySQL
  L8_2 = L8_2.Async
  L8_2 = L8_2.execute
  L9_2 = "INSERT INTO phone_tiktok_messages (id, channel_id, sender, content) VALUES (@messageId, @channelId, @sender, @content)"
  L10_2 = {}
  L10_2["@messageId"] = L7_2
  L10_2["@channelId"] = L4_2
  L10_2["@sender"] = L3_2
  L10_2["@content"] = L5_2
  function L11_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
    L1_3 = A1_2
    L2_3 = {}
    L3_3 = A0_3 > 0
    L2_3.success = L3_3
    L3_3 = L7_2
    L2_3.id = L3_3
    L3_3 = L4_2
    L2_3.channelId = L3_3
    L2_3.error = "failed_insert"
    L1_3(L2_3)
    if A0_3 > 0 then
      L1_3 = MySQL
      L1_3 = L1_3.Async
      L1_3 = L1_3.execute
      L2_3 = [[
                INSERT INTO phone_tiktok_unread_messages
                    (username, channel_id, amount)
                VALUES
                    (@username, @channelId, 1)
                ON DUPLICATE KEY UPDATE
                    amount = amount + 1
            ]]
      L3_3 = {}
      L4_3 = L6_2
      L3_3["@username"] = L4_3
      L4_3 = L4_2
      L3_3["@channelId"] = L4_3
      L1_3(L2_3, L3_3)
      L1_3 = GetActiveAccounts
      L2_3 = "TikTok"
      L1_3 = L1_3(L2_3)
      L2_3 = pairs
      L3_3 = L1_3
      L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
      for L6_3, L7_3 in L2_3, L3_3, L4_3, L5_3 do
        L8_3 = L6_2
        if L7_3 == L8_3 then
          L8_3 = GetSourceFromNumber
          L9_3 = L6_3
          L8_3 = L8_3(L9_3)
          if L8_3 then
            L9_3 = TriggerClientEvent
            L10_3 = "phone:tiktok:receivedMessage"
            L11_3 = L8_3
            L12_3 = {}
            L13_3 = L7_2
            L12_3.id = L13_3
            L13_3 = L4_2
            L12_3.channelId = L13_3
            L13_3 = L3_2
            L12_3.sender = L13_3
            L13_3 = L5_2
            L12_3.content = L13_3
            L9_3(L10_3, L11_3, L12_3)
          end
        end
      end
      L2_3 = L5_1
      L3_3 = L6_2
      L4_3 = L3_2
      L5_3 = "message"
      L6_3 = nil
      L7_3 = nil
      L8_3 = {}
      L9_3 = L5_2
      L8_3.content = L9_3
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
    end
  end
  L8_2(L9_2, L10_2, L11_2)
end
L10_1 = {}
L10_1.preventSpam = true
L7_1(L8_1, L9_1, L10_1)
L7_1 = RegisterLegacyCallback
L8_1 = "tiktok:getChannelId"
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = L0_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "not_logged_in"
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Sync
  L4_2 = L4_2.fetchScalar
  L5_2 = "SELECT id FROM phone_tiktok_channels WHERE (member_1 = @loggedIn AND member_2 = @username) OR (member_1 = @username AND member_2 = @loggedIn)"
  L6_2 = {}
  L6_2["@loggedIn"] = L3_2
  L6_2["@username"] = A2_2
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "no_channel"
    return L5_2(L6_2)
  end
  L5_2 = A1_2
  L6_2 = {}
  L6_2.success = true
  L6_2.id = L4_2
  L5_2(L6_2)
end
L7_1(L8_1, L9_1)
