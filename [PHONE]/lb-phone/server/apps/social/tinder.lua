local L0_1, L1_1, L2_1, L3_1
L0_1 = BaseCallback
L1_1 = "tinder:createAccount"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = MySQL
  L3_2 = L3_2.scalar
  L3_2 = L3_2.await
  L4_2 = "SELECT TRUE FROM phone_tinder_accounts WHERE phone_number = ?"
  L5_2 = {}
  L6_2 = A1_2
  L5_2[1] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = MySQL
  L3_2 = L3_2.update
  L3_2 = L3_2.await
  L4_2 = [[
        INSERT INTO phone_tinder_accounts
            (`name`, phone_number, photos, bio, dob, is_male, interested_men, interested_women)
        VALUES
            (@name, @phoneNumber, @photos, @bio, @dob, @isMale, @showMen, @showWomen)
    ]]
  L5_2 = {}
  L6_2 = A2_2.name
  L5_2["@name"] = L6_2
  L5_2["@phoneNumber"] = A1_2
  L6_2 = json
  L6_2 = L6_2.encode
  L7_2 = A2_2.photos
  L6_2 = L6_2(L7_2)
  L5_2["@photos"] = L6_2
  L6_2 = A2_2.bio
  L5_2["@bio"] = L6_2
  L6_2 = A2_2.dob
  L5_2["@dob"] = L6_2
  L6_2 = A2_2.isMale
  L5_2["@isMale"] = L6_2
  L6_2 = A2_2.showMen
  L5_2["@showMen"] = L6_2
  L6_2 = A2_2.showWomen
  L5_2["@showWomen"] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  L3_2 = L3_2 > 0
  return L3_2
end
L3_1 = false
L0_1(L1_1, L2_1, L3_1)
L0_1 = BaseCallback
L1_1 = "tinder:deleteAccount"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Config
  L2_2 = L2_2.DeleteAccount
  L2_2 = L2_2.Spark
  if not L2_2 then
    L2_2 = infoprint
    L3_2 = "warning"
    L4_2 = "%s tried to delete their spark account, but it's not enabled in the config."
    L5_2 = L4_2
    L4_2 = L4_2.format
    L6_2 = A0_2
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2, L6_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    L2_2 = false
    return L2_2
  end
  L2_2 = MySQL
  L2_2 = L2_2.update
  L2_2 = L2_2.await
  L3_2 = "DELETE FROM phone_tinder_accounts WHERE phone_number = ?"
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  L2_2 = L2_2 > 0
  if not L2_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = MySQL
  L3_2 = L3_2.update
  L4_2 = "DELETE FROM phone_tinder_swipes WHERE swiper = ? OR swipee = ?"
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A1_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2(L4_2, L5_2)
  L3_2 = MySQL
  L3_2 = L3_2.update
  L4_2 = "DELETE FROM phone_tinder_matches WHERE phone_number_1 = ? OR phone_number_2 = ?"
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A1_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2(L4_2, L5_2)
  L3_2 = MySQL
  L3_2 = L3_2.update
  L4_2 = "DELETE FROM phone_tinder_messages WHERE sender = ? OR recipient = ?"
  L5_2 = {}
  L6_2 = A1_2
  L7_2 = A1_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L3_2(L4_2, L5_2)
  L3_2 = true
  return L3_2
end
L0_1(L1_1, L2_1)
L0_1 = BaseCallback
L1_1 = "tinder:updateAccount"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = MySQL
  L3_2 = L3_2.update
  L3_2 = L3_2.await
  L4_2 = [[
        UPDATE phone_tinder_accounts
        SET
            `name`=@name,
            photos=@photos,
            bio=@bio,
            is_male=@isMale,
            interested_men=@showMen,
            interested_women=@showWomen,
            `active`=@active

        WHERE phone_number=@phoneNumber
    ]]
  L5_2 = {}
  L6_2 = A2_2.name
  L5_2["@name"] = L6_2
  L6_2 = json
  L6_2 = L6_2.encode
  L7_2 = A2_2.photos
  L6_2 = L6_2(L7_2)
  L5_2["@photos"] = L6_2
  L6_2 = A2_2.bio
  L5_2["@bio"] = L6_2
  L6_2 = A2_2.isMale
  L5_2["@isMale"] = L6_2
  L6_2 = A2_2.showMen
  L5_2["@showMen"] = L6_2
  L6_2 = A2_2.showWomen
  L5_2["@showWomen"] = L6_2
  L6_2 = A2_2.active
  L5_2["@active"] = L6_2
  L5_2["@phoneNumber"] = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  L3_2 = L3_2 > 0
  return L3_2
end
L3_1 = false
L0_1(L1_1, L2_1, L3_1)
L0_1 = BaseCallback
L1_1 = "tinder:isLoggedIn"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = MySQL
  L2_2 = L2_2.single
  L2_2 = L2_2.await
  L3_2 = "SELECT `name`, photos, bio, dob, is_male, interested_men, interested_women, `active` FROM phone_tinder_accounts WHERE phone_number = ?"
  L4_2 = {}
  L5_2 = A1_2
  L4_2[1] = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = MySQL
    L3_2 = L3_2.update
    L3_2 = L3_2.await
    L4_2 = "UPDATE phone_tinder_accounts SET last_seen = NOW() WHERE phone_number = ?"
    L5_2 = {}
    L6_2 = A1_2
    L5_2[1] = L6_2
    L3_2(L4_2, L5_2)
  end
  return L2_2
end
L3_1 = false
L0_1(L1_1, L2_1, L3_1)
L0_1 = BaseCallback
L1_1 = "tinder:getFeed"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = MySQL
  L3_2 = L3_2.query
  L3_2 = L3_2.await
  L4_2 = [[
        SELECT
            a.`name`, a.phone_number, a.photos, a.bio, a.dob
        FROM
            phone_tinder_accounts a

        JOIN
            phone_tinder_accounts b
        ON
            b.phone_number = @phoneNumber

        WHERE
            a.phone_number != @phoneNumber
            AND a.`active` = 1
            AND (a.is_male = b.interested_men OR a.is_male=(NOT b.interested_women))
            AND (a.interested_men=b.is_male OR a.interested_women=(NOT b.is_male))
            AND NOT EXISTS (SELECT TRUE FROM phone_tinder_swipes WHERE swiper = @phoneNumber AND swipee = a.phone_number)

        ORDER BY a.phone_number

        LIMIT @page, @perPage
    ]]
  L5_2 = {}
  L5_2["@phoneNumber"] = A1_2
  L6_2 = A2_2 * 10
  L5_2["@page"] = L6_2
  L5_2["@perPage"] = 10
  return L3_2(L4_2, L5_2)
end
L3_1 = {}
L0_1(L1_1, L2_1, L3_1)
L0_1 = BaseCallback
L1_1 = "tinder:swipe"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L4_2 = MySQL
  L4_2 = L4_2.query
  L4_2 = L4_2.await
  L5_2 = "INSERT INTO phone_tinder_swipes (swiper, swipee, liked) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE liked = ?"
  L6_2 = {}
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L10_2 = A3_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  L6_2[4] = L10_2
  L4_2 = L4_2(L5_2, L6_2)
  if 0 == L4_2 or not A3_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = "SELECT liked FROM phone_tinder_swipes WHERE swiper = ? AND swipee = ?"
  L6_2 = {}
  L7_2 = A2_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2 = L4_2(L5_2, L6_2)
  L4_2 = true == L4_2
  if not L4_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = MySQL
  L5_2 = L5_2.update
  L5_2 = L5_2.await
  L6_2 = "INSERT INTO phone_tinder_matches (phone_number_1, phone_number_2) VALUES (?, ?)"
  L7_2 = {}
  L8_2 = A1_2
  L9_2 = A2_2
  L7_2[1] = L8_2
  L7_2[2] = L9_2
  L5_2(L6_2, L7_2)
  L5_2 = MySQL
  L5_2 = L5_2.single
  L5_2 = L5_2.await
  L6_2 = "SELECT `name`, photos FROM phone_tinder_accounts WHERE phone_number = ?"
  L7_2 = {}
  L8_2 = A1_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  if not L5_2 then
    return
  end
  L6_2 = SendNotification
  L7_2 = A2_2
  L8_2 = {}
  L8_2.app = "Tinder"
  L9_2 = L
  L10_2 = "BACKEND.TINDER.NEW_MATCH"
  L9_2 = L9_2(L10_2)
  L8_2.title = L9_2
  L9_2 = L
  L10_2 = "BACKEND.TINDER.MATCHED_WITH"
  L11_2 = {}
  L12_2 = L5_2.name
  L11_2.name = L12_2
  L9_2 = L9_2(L10_2, L11_2)
  L8_2.content = L9_2
  L9_2 = json
  L9_2 = L9_2.decode
  L10_2 = L5_2.photos
  L9_2 = L9_2(L10_2)
  L9_2 = L9_2[1]
  L8_2.thumbnail = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = true
  return L6_2
end
L0_1(L1_1, L2_1)
L0_1 = BaseCallback
L1_1 = "tinder:getMatches"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = MySQL
  L2_2 = L2_2.query
  L2_2 = L2_2.await
  L3_2 = [[
        SELECT
            a.`name`, a.phone_number, a.photos, a.dob, a.bio, a.is_male, b.latest_message
        FROM
            phone_tinder_accounts a

        JOIN
            phone_tinder_matches b
        ON
            (b.phone_number_1 = @phoneNumber
            AND b.phone_number_2 = a.phone_number)
            OR
            (b.phone_number_2 = @phoneNumber
            AND b.phone_number_1 = a.phone_number)

        ORDER BY b.latest_message_timestamp DESC
    ]]
  L4_2 = {}
  L4_2["@phoneNumber"] = A1_2
  return L2_2(L3_2, L4_2)
end
L0_1(L1_1, L2_1)
L0_1 = BaseCallback
L1_1 = "tinder:sendMessage"
function L2_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = ContainsBlacklistedWord
  L6_2 = A0_2
  L7_2 = "Spark"
  L8_2 = A3_2
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  if L5_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = MySQL
  L5_2 = L5_2.single
  L5_2 = L5_2.await
  L6_2 = "SELECT `name`, photos FROM phone_tinder_accounts WHERE phone_number = ?"
  L7_2 = {}
  L8_2 = A1_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  if not L5_2 then
    L6_2 = true
    return L6_2
  end
  L6_2 = MySQL
  L6_2 = L6_2.insert
  L6_2 = L6_2.await
  L7_2 = "INSERT INTO phone_tinder_messages (sender, recipient, content, attachments) VALUES (?, ?, ?, ?)"
  L8_2 = {}
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = A4_2
  L8_2[1] = L9_2
  L8_2[2] = L10_2
  L8_2[3] = L11_2
  L8_2[4] = L12_2
  L6_2 = L6_2(L7_2, L8_2)
  if not L6_2 then
    L7_2 = false
    return L7_2
  end
  L7_2 = MySQL
  L7_2 = L7_2.update
  L7_2 = L7_2.await
  L8_2 = "UPDATE phone_tinder_matches SET latest_message = ? WHERE (phone_number_1 = ? AND phone_number_2 = ?) OR (phone_number_2 = ? AND phone_number_1 = ?)"
  L9_2 = {}
  L10_2 = A3_2
  L11_2 = A1_2
  L12_2 = A2_2
  L13_2 = A1_2
  L14_2 = A2_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L7_2(L8_2, L9_2)
  L7_2 = GetSourceFromNumber
  L8_2 = A2_2
  L7_2 = L7_2(L8_2)
  if L7_2 then
    L8_2 = TriggerClientEvent
    L9_2 = "phone:tinder:receiveMessage"
    L10_2 = L7_2
    L11_2 = {}
    L11_2.sender = A1_2
    L11_2.recipient = A2_2
    L11_2.content = A3_2
    L11_2.attachments = A4_2
    L12_2 = os
    L12_2 = L12_2.time
    L12_2 = L12_2()
    L12_2 = L12_2 * 1000
    L11_2.timestamp = L12_2
    L8_2(L9_2, L10_2, L11_2)
  end
  L8_2 = SendNotification
  L9_2 = A2_2
  L10_2 = {}
  L10_2.app = "Tinder"
  L11_2 = L5_2.name
  L10_2.title = L11_2
  L10_2.content = A3_2
  L11_2 = A4_2 or L11_2
  if A4_2 then
    L11_2 = json
    L11_2 = L11_2.decode
    L12_2 = A4_2
    L11_2 = L11_2(L12_2)
    L11_2 = L11_2[1]
  end
  L10_2.thumbnail = L11_2
  L11_2 = json
  L11_2 = L11_2.decode
  L12_2 = L5_2.photos
  L11_2 = L11_2(L12_2)
  L11_2 = L11_2[1]
  L10_2.avatar = L11_2
  L10_2.showAvatar = true
  L8_2(L9_2, L10_2)
  L8_2 = true
  return L8_2
end
L0_1(L1_1, L2_1)
L0_1 = BaseCallback
L1_1 = "tinder:getMessages"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = MySQL
  L4_2 = L4_2.query
  L4_2 = L4_2.await
  L5_2 = [[
        SELECT
            sender, recipient, content, attachments, timestamp
        FROM
            phone_tinder_messages

        WHERE
            (sender = @phoneNumber AND recipient = @number)
            OR
            (recipient = @phoneNumber AND sender = @number)

        ORDER BY timestamp DESC

        LIMIT @page, @perPage
    ]]
  L6_2 = {}
  L6_2["@phoneNumber"] = A1_2
  L6_2["@number"] = A2_2
  L7_2 = A3_2 * 25
  L6_2["@page"] = L7_2
  L6_2["@perPage"] = 25
  return L4_2(L5_2, L6_2)
end
L0_1(L1_1, L2_1)
L0_1 = CreateThread
function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Config
  L0_2 = L0_2.AutoDisableSparkAccounts
  if not L0_2 then
    return
  end
  L0_2 = 3600000
  L1_2 = 7
  L2_2 = type
  L3_2 = Config
  L3_2 = L3_2.AutoDisableSparkAccounts
  L2_2 = L2_2(L3_2)
  if "number" == L2_2 then
    L2_2 = math
    L2_2 = L2_2.max
    L3_2 = Config
    L3_2 = L3_2.AutoDisableSparkAccounts
    L4_2 = 1
    L2_2 = L2_2(L3_2, L4_2)
    L1_2 = L2_2
  end
  while true do
    L2_2 = DatabaseCheckerFinished
    if L2_2 then
      break
    end
    L2_2 = Wait
    L3_2 = 500
    L2_2(L3_2)
  end
  while true do
    L2_2 = MySQL
    L2_2 = L2_2.update
    L3_2 = "UPDATE phone_tinder_accounts SET active = 0 WHERE active = 1 AND last_seen < NOW() - INTERVAL ? DAY"
    L4_2 = {}
    L5_2 = L1_2
    L4_2[1] = L5_2
    function L5_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3
      L1_3 = debugprint
      L2_3 = "Disabled"
      L3_3 = A0_3
      L4_3 = "inactive Spark accounts."
      L1_3(L2_3, L3_3, L4_3)
    end
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = Wait
    L3_2 = L0_2
    L2_2(L3_2)
  end
end
L0_1(L1_1)
