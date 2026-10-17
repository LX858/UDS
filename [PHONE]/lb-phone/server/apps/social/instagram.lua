local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1
L0_1 = {}
L1_1 = {}
function L2_1(A0_2)
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
  L4_2 = "Instagram"
  return L2_2(L3_2, L4_2)
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = {}
  L2_2 = MySQL
  L2_2 = L2_2.query
  L2_2 = L2_2.await
  L3_2 = "SELECT phone_number FROM phone_logged_in_accounts WHERE app = 'Instagram' AND `active` = 1 AND username = ?"
  L4_2 = {}
  L5_2 = A0_2
  L4_2[1] = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = 1
  L4_2 = #L2_2
  L5_2 = 1
  for L6_2 = L3_2, L4_2, L5_2 do
    L7_2 = L2_2[L6_2]
    L7_2 = L7_2.phone_number
    L1_2[L6_2] = L7_2
  end
  return L1_2
end
function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = BaseCallback
  L4_2 = "instagram:"
  L5_2 = A0_2
  L4_2 = L4_2 .. L5_2
  function L5_2(A0_3, A1_3, ...)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L2_3 = GetLoggedInAccount
    L3_3 = A1_3
    L4_3 = "Instagram"
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
function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = L3_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  A1_2.app = "Instagram"
  L4_2 = 1
  L5_2 = #L3_2
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = L3_2[L7_2]
    if L8_2 ~= A2_2 then
      L9_2 = SendNotification
      L10_2 = L8_2
      L11_2 = A1_2
      L9_2(L10_2, L11_2)
    end
  end
end
L6_1 = RegisterLegacyCallback
L7_1 = "instagram:getLives"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = L2_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    return L3_2(L4_2)
  end
  L3_2 = {}
  L4_2 = pairs
  L5_2 = L0_1
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = L9_2.private
    if L10_2 then
      L10_2 = MySQL
      L10_2 = L10_2.Sync
      L10_2 = L10_2.fetchScalar
      L11_2 = "SELECT TRUE FROM phone_instagram_follows WHERE follower=@follower AND followed=@followed"
      L12_2 = {}
      L12_2["@follower"] = L2_2
      L12_2["@followed"] = L8_2
      L10_2 = L10_2(L11_2, L12_2)
      if not L10_2 then
    end
    else
      L3_2[L8_2] = L9_2
    end
  end
  L4_2 = A1_2
  L5_2 = L3_2
  L4_2(L5_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "instagram:getLiveViewers"
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = L0_1
  L3_2 = L3_2[A2_2]
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    return L4_2(L5_2)
  end
  L4_2 = L3_2.viewers
  L5_2 = {}
  L6_2 = 1
  L7_2 = #L4_2
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = GetEquippedPhoneNumber
    L11_2 = L4_2[L9_2]
    L10_2 = L10_2(L11_2)
    if not L10_2 then
    else
      L11_2 = MySQL
      L11_2 = L11_2.Sync
      L11_2 = L11_2.fetchAll
      L12_2 = [[
            SELECT
                a.profile_image AS avatar, a.verified, a.display_name AS `name`, a.username
            FROM phone_logged_in_accounts l
            INNER JOIN phone_instagram_accounts a ON l.username = a.username
            WHERE l.phone_number = ? AND l.active = 1 AND l.app = 'Instagram'
        ]]
      L13_2 = {}
      L14_2 = L10_2
      L13_2[1] = L14_2
      L11_2 = L11_2(L12_2, L13_2)
      if L11_2 then
        L12_2 = L11_2[1]
        if L12_2 then
          L12_2 = #L5_2
          L12_2 = L12_2 + 1
          L13_2 = L11_2[1]
          L5_2[L12_2] = L13_2
        end
      end
    end
  end
  L6_2 = A1_2
  L7_2 = L5_2
  L6_2(L7_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "instagram:canGoLive"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = L2_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = false
    return L3_2(L4_2)
  end
  L3_2 = CanGoLive
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2, L4_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L5_2 = GetEquippedPhoneNumber
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L6_2 = SendNotification
      L7_2 = L5_2
      L8_2 = {}
      L8_2.app = "Instagram"
      L9_2 = L4_2 or L9_2
      if not L4_2 then
        L9_2 = L
        L10_2 = "BACKEND.INSTAGRAM.NOT_ALLOWED_LIVE"
        L9_2 = L9_2(L10_2)
      end
      L8_2.title = L9_2
      L6_2(L7_2, L8_2)
    end
  end
  L5_2 = A1_2
  L6_2 = L3_2
  L5_2(L6_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterLegacyCallback
L7_1 = "instagram:canCreateStory"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = L2_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = false
    return L3_2(L4_2)
  end
  L3_2 = CanCreateStory
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2, L4_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L5_2 = GetEquippedPhoneNumber
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L6_2 = SendNotification
      L7_2 = L5_2
      L8_2 = {}
      L8_2.app = "Instagram"
      L9_2 = L4_2 or L9_2
      if not L4_2 then
        L9_2 = L
        L10_2 = "BACKEND.INSTAGRAM.NOT_ALLOWED_STORY"
        L9_2 = L9_2(L10_2)
      end
      L8_2.title = L9_2
      L6_2(L7_2, L8_2)
    end
  end
  L5_2 = A1_2
  L6_2 = L3_2
  L5_2(L6_2)
end
L6_1(L7_1, L8_1)
L6_1 = RegisterNetEvent
L7_1 = "phone:instagram:startLive"
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = source
  L2_2 = L2_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = L0_1
    L3_2 = L3_2[L2_2]
    if not L3_2 then
      L3_2 = CanGoLive
      L4_2 = L1_2
      L5_2 = L2_2
      L3_2 = L3_2(L4_2, L5_2)
      if L3_2 then
        goto lbl_18
      end
    end
  end
  do return end
  ::lbl_18::
  L3_2 = MySQL
  L3_2 = L3_2.single
  L3_2 = L3_2.await
  L4_2 = "SELECT profile_image, verified, display_name, private FROM phone_instagram_accounts WHERE username = ?"
  L5_2 = {}
  L6_2 = L2_2
  L5_2[1] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    return
  end
  L4_2 = L0_1
  L5_2 = {}
  L5_2.id = A0_2
  L6_2 = L3_2.profile_image
  L5_2.avatar = L6_2
  L6_2 = L3_2.verified
  L5_2.verified = L6_2
  L6_2 = L3_2.display_name
  L5_2.name = L6_2
  L6_2 = L3_2.private
  L5_2.private = L6_2
  L5_2.host = L1_2
  L6_2 = {}
  L5_2.viewers = L6_2
  L6_2 = {}
  L5_2.nearby = L6_2
  L6_2 = {}
  L5_2.invites = L6_2
  L6_2 = {}
  L5_2.participants = L6_2
  L4_2[L2_2] = L5_2
  L4_2 = Player
  L5_2 = L1_2
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2.state
  L4_2.instapicIsLive = L2_2
  L4_2 = TriggerClientEvent
  L5_2 = "phone:instagram:updateLives"
  L6_2 = -1
  L7_2 = L0_1
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = Log
  L5_2 = "InstaPic"
  L6_2 = L1_2
  L7_2 = "success"
  L8_2 = L
  L9_2 = "BACKEND.LOGS.LIVE_TITLE"
  L8_2 = L8_2(L9_2)
  L9_2 = L
  L10_2 = "BACKEND.LOGS.STARTED_LIVE"
  L11_2 = {}
  L11_2.username = L2_2
  L9_2, L10_2, L11_2, L12_2, L13_2 = L9_2(L10_2, L11_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L4_2 = TrackSimpleEvent
  L5_2 = "go_live"
  L4_2(L5_2)
  L4_2 = {}
  L5_2 = L
  L6_2 = "APPS.INSTAGRAM.TITLE"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L5_2 = L
  L6_2 = "BACKEND.INSTAGRAM.STARTED_LIVE"
  L7_2 = {}
  L7_2.username = L2_2
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.content = L5_2
  L5_2 = Config
  L5_2 = L5_2.InstaPicLiveNotifications
  if L5_2 then
    L5_2 = Config
    L5_2 = L5_2.InstaPicLiveNotifications
    if "all" == L5_2 then
      L5_2 = "all"
      if L5_2 then
        goto lbl_108
      end
    end
    L5_2 = "online"
    ::lbl_108::
    L6_2 = NotifyEveryone
    L7_2 = L5_2
    L8_2 = {}
    L8_2.app = "Instagram"
    L9_2 = L4_2.title
    L8_2.title = L9_2
    L9_2 = L4_2.content
    L8_2.content = L9_2
    L6_2(L7_2, L8_2)
  else
    L5_2 = MySQL
    L5_2 = L5_2.query
    L5_2 = L5_2.await
    L6_2 = "SELECT follower FROM phone_instagram_follows WHERE followed = ?"
    L7_2 = {}
    L8_2 = L2_2
    L7_2[1] = L8_2
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = 1
    L7_2 = #L5_2
    L8_2 = 1
    for L9_2 = L6_2, L7_2, L8_2 do
      L10_2 = L5_2[L9_2]
      L10_2 = L10_2.follower
      L11_2 = L5_1
      L12_2 = L10_2
      L13_2 = L4_2
      L11_2(L12_2, L13_2)
    end
  end
end
L6_1(L7_1, L8_1)
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.participants
  if not L1_2 then
    return
  end
  L1_2 = table
  L1_2 = L1_2.clone
  L2_2 = A0_2.viewers
  L1_2 = L1_2(L2_2)
  L2_2 = #L1_2
  L2_2 = L2_2 + 1
  L3_2 = A0_2.host
  L1_2[L2_2] = L3_2
  L2_2 = 1
  L3_2 = A0_2.participants
  L3_2 = #L3_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = A0_2.participants
    L6_2 = L6_2[L5_2]
    if L6_2 then
      L6_2 = L6_2.username
    end
    if not L6_2 then
    else
      L7_2 = L0_1
      L7_2 = L7_2[L6_2]
      if not L7_2 then
      else
        L8_2 = TriggerClientEvent
        L9_2 = "phone:phone:removeVoiceTarget"
        L10_2 = L7_2.host
        L11_2 = L1_2
        L8_2(L9_2, L10_2, L11_2)
        L8_2 = Player
        L9_2 = L7_2.host
        L8_2 = L8_2(L9_2)
        L8_2 = L8_2.state
        L8_2.instapicIsLive = nil
        L8_2 = L0_1
        L8_2[L6_2] = nil
        L8_2 = TriggerClientEvent
        L9_2 = "phone:instagram:endLive"
        L10_2 = -1
        L11_2 = L6_2
        L8_2(L9_2, L10_2, L11_2)
      end
    end
  end
  L2_2 = 1
  L3_2 = A0_2.nearby
  L3_2 = #L3_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = A0_2.nearby
    L6_2 = L6_2[L5_2]
    if L6_2 then
      L7_2 = TriggerClientEvent
      L8_2 = "phone:phone:removeVoiceTarget"
      L9_2 = L6_2
      L10_2 = L1_2
      L7_2(L8_2, L9_2, L10_2)
      L7_2 = TriggerClientEvent
      L8_2 = "phone:instagram:leftProximity"
      L9_2 = -1
      L10_2 = L6_2
      L11_2 = A0_2.host
      L7_2(L8_2, L9_2, L10_2, L11_2)
    end
  end
  L2_2 = TriggerClientEvent
  L3_2 = "phone:phone:removeVoiceTarget"
  L4_2 = A0_2.host
  L5_2 = A0_2.viewers
  L2_2(L3_2, L4_2, L5_2)
end
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = L0_1
  L2_2 = L2_2[A0_2]
  L3_2 = nil
  L4_2 = L2_2.participants
  if not L4_2 then
    return
  end
  L4_2 = false
  L5_2 = 1
  L6_2 = L2_2.participants
  L6_2 = #L6_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L2_2.participants
    L9_2 = L9_2[L8_2]
    L9_2 = L9_2.username
    if L9_2 == A1_2 then
      L9_2 = L2_2.participants
      L9_2 = L9_2[L8_2]
      L3_2 = L9_2.source
      L9_2 = table
      L9_2 = L9_2.remove
      L10_2 = L2_2.participants
      L11_2 = L8_2
      L9_2(L10_2, L11_2)
      L4_2 = true
      break
    end
  end
  if not L4_2 then
    return
  end
  L5_2 = table
  L5_2 = L5_2.clone
  L6_2 = L2_2.viewers
  L5_2 = L5_2(L6_2)
  L6_2 = #L5_2
  L6_2 = L6_2 + 1
  L7_2 = L2_2.host
  L5_2[L6_2] = L7_2
  L6_2 = 1
  L7_2 = #L5_2
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = TriggerClientEvent
    L11_2 = "phone:instagram:leftLive"
    L12_2 = L5_2[L9_2]
    L13_2 = A0_2
    L14_2 = A1_2
    L15_2 = L3_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  end
  L6_2 = table
  L6_2 = L6_2.clone
  L7_2 = L2_2.viewers
  L6_2 = L6_2(L7_2)
  L7_2 = 1
  L8_2 = L2_2.participants
  L8_2 = #L8_2
  L9_2 = 1
  for L10_2 = L7_2, L8_2, L9_2 do
    L11_2 = 1
    L12_2 = #L6_2
    L13_2 = 1
    for L14_2 = L11_2, L12_2, L13_2 do
      L15_2 = L6_2[L14_2]
      L16_2 = L2_2.participants
      L16_2 = L16_2[L10_2]
      L16_2 = L16_2.source
      if L15_2 == L16_2 then
        L15_2 = table
        L15_2 = L15_2.remove
        L16_2 = L6_2
        L17_2 = L14_2
        L15_2(L16_2, L17_2)
        break
      end
    end
  end
  L7_2 = TriggerClientEvent
  L8_2 = "phone:phone:removeVoiceTarget"
  L9_2 = L3_2
  L10_2 = L6_2
  L7_2(L8_2, L9_2, L10_2)
end
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:endLive"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = L2_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = true
    return L3_2(L4_2)
  end
  L3_2 = L0_1
  L3_2 = L3_2[L2_2]
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = true
    return L4_2(L5_2)
  end
  L4_2 = L3_2.participant
  if L4_2 then
    L5_2 = L7_1
    L6_2 = L4_2
    L7_2 = L2_2
    L5_2(L6_2, L7_2)
  else
    L5_2 = L6_1
    L6_2 = L3_2
    L5_2(L6_2)
  end
  L5_2 = L0_1
  L5_2[L2_2] = nil
  L5_2 = Player
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L5_2 = L5_2.state
  L5_2.instapicIsLive = nil
  L5_2 = TriggerClientEvent
  L6_2 = "phone:instagram:updateLives"
  L7_2 = -1
  L8_2 = L0_1
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = TriggerClientEvent
  L6_2 = "phone:instagram:endLive"
  L7_2 = -1
  L8_2 = L2_2
  L9_2 = L4_2
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = Log
  L6_2 = "InstaPic"
  L7_2 = A0_2
  L8_2 = "error"
  L9_2 = L
  L10_2 = "BACKEND.LOGS.LIVE_TITLE"
  L9_2 = L9_2(L10_2)
  L10_2 = L
  L11_2 = "BACKEND.LOGS.ENDED_LIVE"
  L12_2 = {}
  L12_2.username = L2_2
  L10_2, L11_2, L12_2 = L10_2(L11_2, L12_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L5_2 = A1_2
  L6_2 = true
  L5_2(L6_2)
end
L8_1(L9_1, L10_1)
L8_1 = AddEventHandler
L9_1 = "playerDropped"
function L10_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L0_2 = source
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = pairs
    L8_2 = L6_2.viewers
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
      if L12_2 == L0_2 then
        L13_2 = L1_1
        L13_2 = L13_2[L0_2]
        if L13_2 then
          L13_2 = TriggerClientEvent
          L14_2 = "phone:endCall"
          L15_2 = L6_2.host
          L16_2 = L1_1
          L16_2 = L16_2[L0_2]
          L13_2(L14_2, L15_2, L16_2)
          L13_2 = L1_1
          L13_2[L0_2] = nil
        end
        L13_2 = table
        L13_2 = L13_2.remove
        L14_2 = L6_2.viewers
        L15_2 = L11_2
        L13_2(L14_2, L15_2)
        L13_2 = TriggerClientEvent
        L14_2 = "phone:instagram:updateViewers"
        L15_2 = -1
        L16_2 = L5_2
        L17_2 = L6_2.viewers
        L17_2 = #L17_2
        L13_2(L14_2, L15_2, L16_2, L17_2)
      end
    end
    L7_2 = L6_2.host
    if L7_2 ~= L0_2 then
    else
      L7_2 = L6_2.participant
      if L7_2 then
        L8_2 = L7_1
        L9_2 = L7_2
        L10_2 = L5_2
        L8_2(L9_2, L10_2)
      else
        L8_2 = L6_1
        L9_2 = L6_2
        L8_2(L9_2)
      end
      L8_2 = L0_1
      L8_2[L5_2] = nil
      L8_2 = TriggerClientEvent
      L9_2 = "phone:instagram:updateLives"
      L10_2 = -1
      L11_2 = L0_1
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = TriggerClientEvent
      L9_2 = "phone:instagram:endLive"
      L10_2 = -1
      L11_2 = L5_2
      L12_2 = L7_2
      L8_2(L9_2, L10_2, L11_2, L12_2)
      L8_2 = L6_2.host
      if L8_2 == L0_2 then
        return
      end
    end
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "phone:instagram:addCall"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = source
  L2_2 = false
  L3_2 = pairs
  L4_2 = L0_1
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = pairs
    L10_2 = L8_2.viewers
    L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
    for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
      if L14_2 == L1_2 then
        L2_2 = true
        break
      end
    end
  end
  L3_2 = L1_1
  L3_2 = L3_2[L1_2]
  if not L3_2 and L2_2 then
    L3_2 = L1_1
    L3_2[L1_2] = A0_2
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:viewLive"
function L10_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = A0_2
  L4_2 = L0_1
  L4_2 = L4_2[A2_2]
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = false
  L6_2 = 1
  L7_2 = L4_2.viewers
  L7_2 = #L7_2
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = L4_2.viewers
    L10_2 = L10_2[L9_2]
    if L10_2 == L3_2 then
      L5_2 = true
      break
    end
  end
  if not L5_2 then
    L6_2 = L4_2.viewers
    L7_2 = L4_2.viewers
    L7_2 = #L7_2
    L7_2 = L7_2 + 1
    L6_2[L7_2] = L3_2
    L6_2 = TriggerClientEvent
    L7_2 = "phone:phone:addVoiceTarget"
    L8_2 = L4_2.host
    L9_2 = A0_2
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = TriggerClientEvent
    L7_2 = "phone:instagram:updateViewers"
    L8_2 = -1
    L9_2 = A2_2
    L10_2 = L4_2.viewers
    L10_2 = #L10_2
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L6_2 = L4_2.participants
    L7_2 = 1
    L8_2 = #L6_2
    L9_2 = 1
    for L10_2 = L7_2, L8_2, L9_2 do
      L11_2 = TriggerClientEvent
      L12_2 = "phone:phone:addVoiceTarget"
      L13_2 = L6_2[L10_2]
      L13_2 = L13_2.source
      L14_2 = A0_2
      L11_2(L12_2, L13_2, L14_2)
    end
    L7_2 = SetTimeout
    L8_2 = 500
    function L9_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
      L0_3 = L4_2
      if L0_3 then
        L0_3 = L0_3.nearby
      end
      if not L0_3 then
        L0_3 = {}
      end
      L1_3 = 1
      L2_3 = #L0_3
      L3_3 = 1
      for L4_3 = L1_3, L2_3, L3_3 do
        L5_3 = TriggerClientEvent
        L6_3 = "phone:phone:addVoiceTarget"
        L7_3 = L0_3[L4_3]
        L8_3 = A0_2
        L5_3(L6_3, L7_3, L8_3)
        L5_3 = TriggerClientEvent
        L6_3 = "phone:instagram:enteredProximity"
        L7_3 = A0_2
        L8_3 = L0_3[L4_3]
        L9_3 = L4_2.host
        L5_3(L6_3, L7_3, L8_3, L9_3)
      end
    end
    L7_2(L8_2, L9_2)
  end
  L6_2 = A1_2
  L7_2 = L4_2
  L6_2(L7_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:stopViewing"
function L10_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = A0_2
  L4_2 = L0_1
  L4_2 = L4_2[A2_2]
  if not L4_2 then
    L5_2 = A1_2
    return L5_2()
  end
  L5_2 = false
  L6_2 = pairs
  L7_2 = L4_2.viewers
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
  for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
    if L11_2 == L3_2 then
      L5_2 = true
      L12_2 = L1_1
      L12_2 = L12_2[L3_2]
      if L12_2 then
        L12_2 = TriggerClientEvent
        L13_2 = "phone:instagram:endCall"
        L14_2 = L4_2.host
        L15_2 = L1_1
        L15_2 = L15_2[L3_2]
        L12_2(L13_2, L14_2, L15_2)
        L12_2 = L1_1
        L12_2[L3_2] = nil
      end
      L12_2 = table
      L12_2 = L12_2.remove
      L13_2 = L4_2.viewers
      L14_2 = L10_2
      L12_2(L13_2, L14_2)
      break
    end
  end
  L6_2 = 1
  L7_2 = L4_2.nearby
  L7_2 = #L7_2
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = L4_2.nearby
    L10_2 = L10_2[L9_2]
    if L10_2 then
      L11_2 = TriggerClientEvent
      L12_2 = "phone:phone:removeVoiceTarget"
      L13_2 = L10_2
      L14_2 = L3_2
      L11_2(L12_2, L13_2, L14_2)
      L11_2 = TriggerClientEvent
      L12_2 = "phone:instagram:leftProximity"
      L13_2 = L3_2
      L14_2 = L10_2
      L15_2 = L4_2.host
      L11_2(L12_2, L13_2, L14_2, L15_2)
    end
  end
  if L5_2 then
    L6_2 = TriggerClientEvent
    L7_2 = "phone:phone:removeVoiceTarget"
    L8_2 = L4_2.host
    L9_2 = L3_2
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = TriggerClientEvent
    L7_2 = "phone:instagram:updateViewers"
    L8_2 = -1
    L9_2 = A2_2
    L10_2 = L4_2.viewers
    L10_2 = #L10_2
    L6_2(L7_2, L8_2, L9_2, L10_2)
    L6_2 = L4_2.participants
    L7_2 = 1
    L8_2 = #L6_2
    L9_2 = 1
    for L10_2 = L7_2, L8_2, L9_2 do
      L11_2 = TriggerClientEvent
      L12_2 = "phone:phone:removeVoiceTarget"
      L13_2 = L6_2[L10_2]
      L13_2 = L13_2.source
      L14_2 = L3_2
      L11_2(L12_2, L13_2, L14_2)
    end
  end
  L6_2 = A1_2
  L6_2()
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "phone:instagram:inviteLive"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = L2_1
  L2_2 = source
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = L0_1
  L2_2 = L2_2[L1_2]
  if L2_2 then
    L3_2 = L2_2.participants
    if L3_2 then
      goto lbl_15
    end
  end
  do return end
  ::lbl_15::
  L3_2 = L0_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    return
  end
  L4_2 = L2_2.participants
  L4_2 = #L4_2
  if L4_2 >= 3 then
    return
  end
  L4_2 = 1
  L5_2 = L2_2.participants
  L5_2 = #L5_2
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = L2_2.participants
    L8_2 = L8_2[L7_2]
    if L8_2 then
      L8_2 = L8_2.username
    end
    if L8_2 == A0_2 then
      return
    end
  end
  L4_2 = L2_2.invites
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    L4_2 = L2_2.invites
    L4_2[A0_2] = true
  end
  L4_2 = GetActiveAccounts
  L5_2 = "Instagram"
  L4_2 = L4_2(L5_2)
  L5_2 = pairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    if A0_2 == L10_2 then
      L11_2 = GetSourceFromNumber
      L12_2 = L9_2
      L11_2 = L11_2(L12_2)
      if L11_2 then
        L12_2 = TriggerClientEvent
        L13_2 = "phone:instagram:invitedLive"
        L14_2 = L11_2
        L15_2 = L1_2
        L12_2(L13_2, L14_2, L15_2)
      end
    end
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "phone:instagram:removeLive"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = L2_1
  L2_2 = source
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = L0_1
  L2_2 = L2_2[L1_2]
  if not L2_2 then
    return
  end
  L3_2 = false
  L4_2 = nil
  L5_2 = 1
  L6_2 = L2_2.participants
  L6_2 = #L6_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L2_2.participants
    L9_2 = L9_2[L8_2]
    L9_2 = L9_2.username
    if L9_2 == A0_2 then
      L3_2 = true
      L9_2 = L2_2.participants
      L9_2 = L9_2[L8_2]
      L4_2 = L9_2.source
      break
    end
  end
  if L3_2 and L4_2 then
    L5_2 = L7_1
    L6_2 = L1_2
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
    L5_2 = L0_1
    L5_2[A0_2] = nil
    L5_2 = Player
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    L5_2 = L5_2.state
    L5_2.instapicIsLive = nil
    L5_2 = TriggerClientEvent
    L6_2 = "phone:instagram:updateLives"
    L7_2 = -1
    L8_2 = L0_1
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = TriggerClientEvent
    L6_2 = "phone:instagram:endLive"
    L7_2 = -1
    L8_2 = A0_2
    L9_2 = L1_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
    L5_2 = TriggerClientEvent
    L6_2 = "phone:instagram:removedLive"
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
  L5_2 = TriggerClientEvent
  L6_2 = "phone:instagram:updateLives"
  L7_2 = -1
  L8_2 = L0_1
  L5_2(L6_2, L7_2, L8_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:joinLive"
function L10_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L4_2 = A0_2
  L5_2 = L2_1
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = false
    return L6_2(L7_2)
  end
  L6_2 = L0_1
  L6_2 = L6_2[A2_2]
  if L6_2 then
    L7_2 = L6_2.participants
    if L7_2 then
      goto lbl_22
    end
  end
  L7_2 = A1_2
  L8_2 = false
  do return L7_2(L8_2) end
  ::lbl_22::
  L7_2 = L0_1
  L7_2 = L7_2[L5_2]
  if L7_2 then
    L8_2 = A1_2
    L9_2 = false
    return L8_2(L9_2)
  end
  L8_2 = L6_2.invites
  L8_2 = L8_2[L5_2]
  if L8_2 then
    L8_2 = L6_2.invites
    L8_2[L5_2] = nil
  end
  L8_2 = L6_2.participants
  L8_2 = #L8_2
  if L8_2 >= 3 then
    L8_2 = A1_2
    L9_2 = false
    return L8_2(L9_2)
  end
  L8_2 = 1
  L9_2 = L6_2.participants
  L9_2 = #L9_2
  L10_2 = 1
  for L11_2 = L8_2, L9_2, L10_2 do
    L12_2 = L6_2.participants
    L12_2 = L12_2[L11_2]
    if L12_2 then
      L12_2 = L12_2.username
    end
    if L12_2 == L5_2 then
      L12_2 = A1_2
      L13_2 = false
      return L12_2(L13_2)
    end
  end
  L8_2 = MySQL
  L8_2 = L8_2.Sync
  L8_2 = L8_2.fetchAll
  L9_2 = "SELECT profile_image, verified, display_name FROM phone_instagram_accounts WHERE username=@username"
  L10_2 = {}
  L10_2["@username"] = L5_2
  L8_2 = L8_2(L9_2, L10_2)
  L9_2 = L8_2[1]
  if not L9_2 then
    L9_2 = A1_2
    L10_2 = false
    return L9_2(L10_2)
  end
  L9_2 = L6_2.participants
  L10_2 = L6_2.participants
  L10_2 = #L10_2
  L10_2 = L10_2 + 1
  L11_2 = {}
  L11_2.username = L5_2
  L12_2 = L8_2[1]
  L12_2 = L12_2.display_name
  L11_2.name = L12_2
  L12_2 = L8_2[1]
  L12_2 = L12_2.profile_image
  L11_2.avatar = L12_2
  L12_2 = L8_2[1]
  L12_2 = L12_2.verified
  L11_2.verified = L12_2
  L11_2.id = A3_2
  L11_2.source = L4_2
  L9_2[L10_2] = L11_2
  L9_2 = L0_1
  L10_2 = {}
  L10_2.id = A3_2
  L11_2 = L8_2[1]
  L11_2 = L11_2.profile_image
  L10_2.avatar = L11_2
  L11_2 = L8_2[1]
  L11_2 = L11_2.verified
  L10_2.verified = L11_2
  L11_2 = L8_2[1]
  L11_2 = L11_2.display_name
  L10_2.name = L11_2
  L10_2.host = L4_2
  L11_2 = {}
  L10_2.nearby = L11_2
  L11_2 = {}
  L10_2.viewers = L11_2
  L10_2.participant = A2_2
  L9_2[L5_2] = L10_2
  L9_2 = Player
  L10_2 = L4_2
  L9_2 = L9_2(L10_2)
  L9_2 = L9_2.state
  L9_2.instapicIsLive = L5_2
  L9_2 = TriggerClientEvent
  L10_2 = "phone:instagram:updateLives"
  L11_2 = -1
  L12_2 = L0_1
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = MySQL
  L9_2 = L9_2.Sync
  L9_2 = L9_2.fetchAll
  L10_2 = "SELECT follower FROM phone_instagram_follows WHERE followed = @username"
  L11_2 = {}
  L11_2["@username"] = L5_2
  L9_2 = L9_2(L10_2, L11_2)
  L10_2 = 1
  L11_2 = #L9_2
  L12_2 = 1
  for L13_2 = L10_2, L11_2, L12_2 do
    L14_2 = L9_2[L13_2]
    L15_2 = L3_1
    L16_2 = L14_2.follower
    L15_2 = L15_2(L16_2)
    L16_2 = 1
    L17_2 = #L15_2
    L18_2 = 1
    for L19_2 = L16_2, L17_2, L18_2 do
      L20_2 = L15_2[L19_2]
      L21_2 = SendNotification
      L22_2 = L20_2
      L23_2 = {}
      L23_2.app = "Instagram"
      L24_2 = L
      L25_2 = "APPS.INSTAGRAM.TITLE"
      L24_2 = L24_2(L25_2)
      L23_2.title = L24_2
      L24_2 = L
      L25_2 = "BACKEND.INSTAGRAM.JOINED_LIVE"
      L26_2 = {}
      L26_2.invitee = L5_2
      L26_2.inviter = A2_2
      L24_2 = L24_2(L25_2, L26_2)
      L23_2.content = L24_2
      L21_2(L22_2, L23_2)
    end
  end
  L10_2 = table
  L10_2 = L10_2.clone
  L11_2 = L0_1
  L11_2 = L11_2[A2_2]
  L11_2 = L11_2.viewers
  L10_2 = L10_2(L11_2)
  L11_2 = #L10_2
  L11_2 = L11_2 + 1
  L12_2 = L0_1
  L12_2 = L12_2[A2_2]
  L12_2 = L12_2.host
  L10_2[L11_2] = L12_2
  L11_2 = TriggerClientEvent
  L12_2 = "phone:phone:addVoiceTarget"
  L13_2 = L4_2
  L14_2 = L10_2
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = 1
  L12_2 = #L10_2
  L13_2 = 1
  for L14_2 = L11_2, L12_2, L13_2 do
    L15_2 = TriggerClientEvent
    L16_2 = "phone:instagram:joinedLive"
    L17_2 = L10_2[L14_2]
    L18_2 = {}
    L18_2.username = L5_2
    L19_2 = L8_2[1]
    L19_2 = L19_2.name
    L18_2.name = L19_2
    L19_2 = L8_2[1]
    L19_2 = L19_2.profile_image
    L18_2.avatar = L19_2
    L19_2 = L8_2[1]
    L19_2 = L19_2.verified
    L18_2.verified = L19_2
    L18_2.id = A3_2
    L18_2.host = A2_2
    L18_2.source = L4_2
    L15_2(L16_2, L17_2, L18_2)
  end
  L11_2 = A1_2
  L12_2 = true
  L11_2(L12_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "phone:instagram:sendLiveMessage"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = A0_2
  if L1_2 then
    L1_2 = L1_2.live
  end
  L2_2 = L0_1
  L1_2 = L2_2[L1_2]
  if L1_2 then
    L1_2 = TriggerClientEvent
    L2_2 = "phone:instagram:addLiveMessage"
    L3_2 = -1
    L4_2 = A0_2
    L1_2(L2_2, L3_2, L4_2)
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "phone:instagram:enteredLiveProximity"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = source
  L2_2 = L0_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = L2_2.participant
  end
  L3_2 = {}
  if L2_2 then
    L4_2 = L0_1
    L3_2 = L4_2[A0_2]
    A0_2 = L2_2
  end
  L4_2 = L0_1
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    return
  end
  L5_2 = table
  L5_2 = L5_2.contains
  L6_2 = L4_2.nearby
  L7_2 = L1_2
  L5_2 = L5_2(L6_2, L7_2)
  if L5_2 then
    return
  end
  L5_2 = 1
  L6_2 = L4_2.participants
  L6_2 = #L6_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L4_2.participants
    L9_2 = L9_2[L8_2]
    L9_2 = L9_2.source
    if L9_2 == L1_2 then
      return
    end
  end
  L5_2 = L4_2.nearby
  L6_2 = L4_2.nearby
  L6_2 = #L6_2
  L6_2 = L6_2 + 1
  L5_2[L6_2] = L1_2
  L5_2 = table
  L5_2 = L5_2.clone
  L6_2 = L4_2.viewers
  L5_2 = L5_2(L6_2)
  if L2_2 then
    L6_2 = #L5_2
    L6_2 = L6_2 + 1
    L7_2 = L4_2.host
    L5_2[L6_2] = L7_2
  end
  L6_2 = debugprint
  L7_2 = "shouldHear (joined)"
  L8_2 = json
  L8_2 = L8_2.encode
  L9_2 = L5_2
  L10_2 = {}
  L10_2.indent = true
  L8_2, L9_2, L10_2 = L8_2(L9_2, L10_2)
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = TriggerClientEvent
  L7_2 = "phone:phone:addVoiceTarget"
  L8_2 = L1_2
  L9_2 = L5_2
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = TriggerClientEvent
  L7_2 = "phone:instagram:enteredProximity"
  L8_2 = -1
  L9_2 = L1_2
  L10_2 = L3_2
  if L10_2 then
    L10_2 = L10_2.host
  end
  if not L10_2 then
    L10_2 = L4_2.host
  end
  L6_2(L7_2, L8_2, L9_2, L10_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "phone:instagram:leftLiveProximity"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = source
  L3_2 = L0_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L3_2 = L3_2.participant
  end
  L4_2 = {}
  if L3_2 then
    L5_2 = L0_1
    L4_2 = L5_2[A0_2]
    A0_2 = L3_2
  end
  L5_2 = L0_1
  L5_2 = L5_2[A0_2]
  if not L5_2 then
    return
  end
  L6_2 = 1
  L7_2 = L5_2.nearby
  L7_2 = #L7_2
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = L5_2.nearby
    L10_2 = L10_2[L9_2]
    if L10_2 == L2_2 then
      L10_2 = L0_1
      L10_2 = L10_2[A0_2]
      L10_2 = L10_2.nearby
      L10_2[L9_2] = nil
      break
    end
  end
  L6_2 = table
  L6_2 = L6_2.clone
  L7_2 = L5_2.viewers
  L6_2 = L6_2(L7_2)
  if L3_2 or A1_2 then
    L7_2 = #L6_2
    L7_2 = L7_2 + 1
    L8_2 = L5_2.host
    L6_2[L7_2] = L8_2
  end
  L7_2 = debugprint
  L8_2 = "shouldHear (left)"
  L9_2 = json
  L9_2 = L9_2.encode
  L10_2 = L6_2
  L11_2 = {}
  L11_2.indent = true
  L9_2, L10_2, L11_2 = L9_2(L10_2, L11_2)
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = TriggerClientEvent
  L8_2 = "phone:phone:removeVoiceTarget"
  L9_2 = L2_2
  L10_2 = L6_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = TriggerClientEvent
  L8_2 = "phone:instagram:leftProximity"
  L9_2 = -1
  L10_2 = L2_2
  L11_2 = L4_2
  if L11_2 then
    L11_2 = L11_2.host
  end
  if not L11_2 then
    L11_2 = L5_2.host
  end
  L7_2(L8_2, L9_2, L10_2, L11_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:addToStory"
function L10_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = GenerateId
  L6_2 = "phone_instagram_stories"
  L7_2 = "id"
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = MySQL
  L6_2 = L6_2.Async
  L6_2 = L6_2.execute
  L7_2 = "INSERT INTO phone_instagram_stories (id, username, image, metadata) VALUES (@id, @username, @image, @metadata)"
  L8_2 = {}
  L8_2["@id"] = L5_2
  L8_2["@username"] = L4_2
  L8_2["@image"] = A2_2
  if A3_2 then
    L9_2 = json
    L9_2 = L9_2.encode
    L10_2 = A3_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      goto lbl_32
    end
  end
  L9_2 = nil
  ::lbl_32::
  L8_2["@metadata"] = L9_2
  function L9_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = A0_3 > 0
    L1_3(L2_3)
  end
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = MySQL
  L6_2 = L6_2.Async
  L6_2 = L6_2.fetchAll
  L7_2 = "SELECT profile_image, verified FROM phone_instagram_accounts WHERE username=@username"
  L8_2 = {}
  L8_2["@username"] = L4_2
  function L9_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = TriggerClientEvent
    L2_3 = "phone:instagram:addStory"
    L3_3 = -1
    L4_3 = {}
    L5_3 = L4_2
    L4_3.username = L5_3
    L5_3 = A0_3[1]
    L5_3 = L5_3.profile_image
    L4_3.avatar = L5_3
    L5_3 = A0_3[1]
    L5_3 = L5_3.verified
    L4_3.verified = L5_3
    L4_3.seen = false
    L1_3(L2_3, L3_3, L4_3)
    L1_3 = Log
    L2_3 = "InstaPic"
    L3_3 = A0_2
    L4_3 = "info"
    L5_3 = L
    L6_3 = "BACKEND.LOGS.ADDED_STORY"
    L7_3 = {}
    L8_3 = L4_2
    L7_3.username = L8_3
    L5_3 = L5_3(L6_3, L7_3)
    L6_3 = A2_2
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
  end
  L6_2(L7_2, L8_2, L9_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:removeFromStory"
function L10_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.execute
  L5_2 = "DELETE FROM phone_instagram_stories WHERE id=@id AND username=@username"
  L6_2 = {}
  L6_2["@id"] = A2_2
  L6_2["@username"] = L3_2
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = A0_3 > 0
    L1_3(L2_3)
  end
  L4_2(L5_2, L6_2, L7_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:getStories"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L2_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    return L3_2(L4_2)
  end
  L3_2 = MySQL
  L3_2 = L3_2.Async
  L3_2 = L3_2.fetchAll
  L4_2 = [[
        SELECT
            s.username, a.verified, a.profile_image AS avatar,

            (SELECT
                (SELECT COUNT(*) FROM phone_instagram_stories s2
                    WHERE s2.username = s.username AND NOT EXISTS (
                    SELECT TRUE FROM phone_instagram_stories_views v
                    WHERE v.viewer = @loggedInAs AND v.story_id = s2.id
                )
            ) = 0) AS seen

        FROM phone_instagram_stories s

        INNER JOIN phone_instagram_accounts a
        ON a.username = s.username

        WHERE a.private=FALSE OR EXISTS (
            SELECT TRUE FROM phone_instagram_follows f
            WHERE f.followed = s.username AND f.follower = @loggedInAs
        )

        GROUP BY s.username

        ORDER BY s.`timestamp` DESC
    ]]
  L5_2 = {}
  L5_2["@loggedInAs"] = L2_2
  L6_2 = A1_2
  L3_2(L4_2, L5_2, L6_2)
end
L8_1(L9_1, L10_1)
L8_1 = L4_1
L9_1 = "getStory"
function L10_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L4_2 = MySQL
  L4_2 = L4_2.query
  L4_2 = L4_2.await
  L5_2 = [[
        SELECT
            s.id,
            s.image,
            s.metadata,
            s.`timestamp`,
            (IF((
                SELECT TRUE FROM phone_instagram_stories_views v
                WHERE v.viewer = ? AND v.story_id = s.id
            ), TRUE, FALSE)) AS seen

        FROM phone_instagram_stories s

        WHERE s.username = ?

        ORDER BY s.timestamp ASC
    ]]
  L6_2 = {}
  L7_2 = A2_2
  L8_2 = A3_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L5_2 = #L4_2
    if 0 ~= L5_2 then
      goto lbl_17
    end
  end
  do return L4_2 end
  ::lbl_17::
  L5_2 = 1
  L6_2 = #L4_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L4_2[L8_2]
    L10_2 = L9_2.metadata
    if L10_2 then
      L10_2 = json
      L10_2 = L10_2.decode
      L11_2 = L9_2.metadata
      L10_2 = L10_2(L11_2)
      L9_2.metadata = L10_2
    end
    if A2_2 == A3_2 then
      L10_2 = MySQL
      L10_2 = L10_2.scalar
      L10_2 = L10_2.await
      L11_2 = "SELECT COUNT(1) FROM phone_instagram_stories_views WHERE story_id = ? AND viewer != ?"
      L12_2 = {}
      L13_2 = L9_2.id
      L14_2 = A2_2
      L12_2[1] = L13_2
      L12_2[2] = L14_2
      L10_2 = L10_2(L11_2, L12_2)
      L9_2.views = L10_2
      L10_2 = MySQL
      L10_2 = L10_2.query
      L10_2 = L10_2.await
      L11_2 = [[
                SELECT
                    a.profile_image AS avatar,
                    a.verified

                FROM
                    phone_instagram_stories_views v

                INNER JOIN phone_instagram_accounts a
                ON a.username = v.viewer

                WHERE
                    v.story_id = ? AND v.viewer != ?

                ORDER BY v.`timestamp` DESC

                LIMIT 3
            ]]
      L12_2 = {}
      L13_2 = L9_2.id
      L14_2 = A2_2
      L12_2[1] = L13_2
      L12_2[2] = L14_2
      L10_2 = L10_2(L11_2, L12_2)
      L9_2.viewers = L10_2
    end
  end
  return L4_2
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:getViewers"
function L10_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Sync
  L5_2 = L5_2.fetchScalar
  L6_2 = "SELECT TRUE FROM phone_instagram_stories WHERE id = @id AND username = @loggedInAs"
  L7_2 = {}
  L7_2["@id"] = A2_2
  L7_2["@loggedInAs"] = L4_2
  L5_2 = L5_2(L6_2, L7_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = {}
    return L6_2(L7_2)
  end
  L6_2 = MySQL
  L6_2 = L6_2.Async
  L6_2 = L6_2.fetchAll
  L7_2 = [[
        SELECT a.profile_image AS avatar, a.verified, a.display_name AS `name`, a.username
        FROM phone_instagram_stories_views v

        INNER JOIN phone_instagram_accounts a
        ON a.username = v.viewer

        WHERE v.story_id = @id AND v.viewer != @loggedInAs

        ORDER BY v.`timestamp` DESC

        LIMIT @page, @perPage
    ]]
  L8_2 = {}
  L8_2["@id"] = A2_2
  L8_2["@loggedInAs"] = L4_2
  L9_2 = A3_2 or L9_2
  if not A3_2 then
    L9_2 = 0
  end
  L9_2 = L9_2 * 15
  L8_2["@page"] = L9_2
  L8_2["@perPage"] = 15
  L9_2 = A1_2
  L6_2(L7_2, L8_2, L9_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterLegacyCallback
L9_1 = "instagram:viewedStory"
function L10_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.execute
  L5_2 = "INSERT IGNORE INTO phone_instagram_stories_views (story_id, viewer) VALUES (@id, @loggedInAs)"
  L6_2 = {}
  L6_2["@id"] = A2_2
  L6_2["@loggedInAs"] = L3_2
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = A0_3 > 0
    L1_3(L2_3)
  end
  L4_2(L5_2, L6_2, L7_2)
end
L8_1(L9_1, L10_1)
L8_1 = CreateThread
function L9_1()
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
    L1_2 = "DELETE FROM phone_instagram_stories WHERE `timestamp` < DATE_SUB(NOW(), INTERVAL 24 HOUR)"
    L2_2 = {}
    L0_2(L1_2, L2_2)
    L0_2 = Wait
    L1_2 = 3600000
    L0_2(L1_2)
  end
end
L8_1(L9_1)
L8_1 = {}
L8_1.like_photo = "BACKEND.INSTAGRAM.LIKED_PHOTO"
L8_1.like_comment = "BACKEND.INSTAGRAM.LIKED_COMMENT"
L8_1.comment = "BACKEND.INSTAGRAM.COMMENTED"
L8_1.follow = "BACKEND.INSTAGRAM.NEW_FOLLOWER"
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if A0_2 == A1_2 then
    return
  end
  L4_2 = L8_1
  L4_2 = L4_2[A2_2]
  if not L4_2 then
    return
  end
  L5_2 = L
  L6_2 = L4_2
  L7_2 = {}
  L7_2.username = A1_2
  L5_2 = L5_2(L6_2, L7_2)
  L4_2 = L5_2
  if "follow" == A2_2 or "like_photo" == A2_2 or "like_comment" == A2_2 then
    L5_2 = MySQL
    L5_2 = L5_2.Sync
    L5_2 = L5_2.fetchScalar
    L6_2 = "SELECT TRUE FROM phone_instagram_notifications WHERE username=@username AND `from`=@from AND `type`=@type"
    if "follow" ~= A2_2 then
      L7_2 = " AND post_id=@post_id"
      if L7_2 then
        goto lbl_32
      end
    end
    L7_2 = ""
    ::lbl_32::
    L6_2 = L6_2 .. L7_2
    L7_2 = {}
    L7_2["@username"] = A0_2
    L7_2["@from"] = A1_2
    L7_2["@type"] = A2_2
    L7_2["@post_id"] = A3_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 then
      return
    end
  end
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.execute
  L6_2 = "INSERT INTO phone_instagram_notifications (id, username, `from`, `type`, post_id) VALUES (@id, @username, @from, @type, @postId)"
  L7_2 = {}
  L8_2 = GenerateId
  L9_2 = "phone_instagram_notifications"
  L10_2 = "id"
  L8_2 = L8_2(L9_2, L10_2)
  L7_2["@id"] = L8_2
  L7_2["@username"] = A0_2
  L7_2["@from"] = A1_2
  L7_2["@type"] = A2_2
  L7_2["@postId"] = A3_2
  L5_2(L6_2, L7_2)
  L5_2 = nil
  if "like_photo" == A2_2 or "comment" == A2_2 then
    L6_2 = MySQL
    L6_2 = L6_2.Async
    L6_2 = L6_2.fetchScalar
    L7_2 = "SELECT TRIM(BOTH '\"' FROM JSON_EXTRACT(media, '$[0]')) FROM phone_instagram_posts WHERE id=@id"
    L8_2 = {}
    L8_2["@id"] = A3_2
    L6_2 = L6_2(L7_2, L8_2)
    L5_2 = L6_2
  end
  L6_2 = L3_1
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L7_2 = 1
  L8_2 = #L6_2
  L9_2 = 1
  for L10_2 = L7_2, L8_2, L9_2 do
    L11_2 = L6_2[L10_2]
    L12_2 = SendNotification
    L13_2 = L11_2
    L14_2 = {}
    L14_2.app = "Instagram"
    L15_2 = L
    L16_2 = "APPS.INSTAGRAM.TITLE"
    L15_2 = L15_2(L16_2)
    L14_2.title = L15_2
    L14_2.content = L4_2
    L14_2.thumbnail = L5_2
    L12_2(L13_2, L14_2)
  end
end
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getNotifications"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L6_2 = {}
    L5_2.notifications = L6_2
    L6_2 = {}
    L7_2 = {}
    L6_2.recent = L7_2
    L6_2.total = 0
    L5_2.requests = L6_2
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Sync
  L4_2 = L4_2.fetchAll
  L5_2 = [[
        SELECT
            (
                SELECT CASE WHEN f.followed IS NULL THEN FALSE ELSE TRUE END
                    FROM phone_instagram_follows f
                    WHERE f.follower=@username AND f.followed=n.`from`
            ) AS isFollowing,
            -- notification data
            n.`from` AS username,
            n.`type`,
            n.`timestamp`,
            -- post photo
            TRIM(BOTH '"' FROM JSON_EXTRACT(p.media, '$[0]')) AS photo,
            p.id AS postId,
            -- comment text
            c.`comment`,
            c.id AS commentId,
            -- account data
            a.profile_image AS avatar,
            a.verified

        FROM phone_instagram_notifications n

        LEFT JOIN phone_instagram_comments c
            ON n.post_id = c.id

        LEFT JOIN phone_instagram_posts p
            ON p.id = (CASE
                WHEN n.`type`="like_photo"
                THEN n.post_id

                WHEN n.`type`="comment"
                THEN c.post_id

                WHEN n.`type`="like_comment"
                THEN c.post_id

                ELSE NULL
                END
            )

        LEFT JOIN phone_instagram_accounts a
            ON a.username=n.`from`

        WHERE n.username=@username

        ORDER BY n.`timestamp` DESC

        LIMIT @page, @perPage
    ]]
  L6_2 = {}
  L6_2["@username"] = L3_2
  L7_2 = A2_2 * 15
  L6_2["@page"] = L7_2
  L6_2["@perPage"] = 15
  L4_2 = L4_2(L5_2, L6_2)
  if A2_2 > 0 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.notifications = L4_2
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Sync
  L5_2 = L5_2.fetchAll
  L6_2 = [[
        SELECT a.username, a.profile_image AS avatar

        FROM phone_instagram_follow_requests r

        INNER JOIN phone_instagram_accounts a
            ON a.username = r.requester

        WHERE r.requestee=@username

        ORDER BY r.`timestamp` DESC

        LIMIT 2
    ]]
  L7_2 = {}
  L7_2["@username"] = L3_2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.fetchScalar
  L7_2 = "SELECT COUNT(1) FROM phone_instagram_follow_requests WHERE requestee=@username"
  L8_2 = {}
  L8_2["@username"] = L3_2
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = A1_2
  L8_2 = {}
  L8_2.notifications = L4_2
  L9_2 = {}
  L9_2.recent = L5_2
  L9_2.total = L6_2
  L8_2.requests = L9_2
  L7_2(L8_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getFollowRequests"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.fetchAll
  L5_2 = [[
        SELECT a.username, a.display_name AS `name`, a.profile_image AS avatar, a.verified
        FROM phone_instagram_follow_requests r

        INNER JOIN phone_instagram_accounts a
            ON a.username = r.requester

        WHERE r.requestee=@loggedInAs

        ORDER BY r.`timestamp` DESC

        LIMIT @page, @perPage
    ]]
  L6_2 = {}
  L6_2["@loggedInAs"] = L3_2
  L7_2 = A2_2 or L7_2
  if not A2_2 then
    L7_2 = 0
  end
  L7_2 = L7_2 * 15
  L6_2["@page"] = L7_2
  L6_2["@perPage"] = 15
  L7_2 = A1_2
  L4_2(L5_2, L6_2, L7_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:handleFollowRequest"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = {}
  L5_2["@loggedInAs"] = L4_2
  L5_2["@username"] = A2_2
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.execute
  L7_2 = "DELETE FROM phone_instagram_follow_requests WHERE requestee=@loggedInAs AND requester=@username"
  L8_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2)
  if 0 == L6_2 then
    L7_2 = A1_2
    L8_2 = false
    return L7_2(L8_2)
  end
  if not A3_2 then
    L7_2 = A1_2
    L8_2 = true
    return L7_2(L8_2)
  end
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.execute
  L8_2 = "INSERT IGNORE INTO phone_instagram_follows (follower, followed) VALUES (@username, @loggedInAs)"
  L9_2 = L5_2
  L7_2(L8_2, L9_2)
  L7_2 = TriggerClientEvent
  L8_2 = "phone:instagram:updateProfileData"
  L9_2 = -1
  L10_2 = L4_2
  L11_2 = "followers"
  L12_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = TriggerClientEvent
  L8_2 = "phone:instagram:updateProfileData"
  L9_2 = -1
  L10_2 = A2_2
  L11_2 = "following"
  L12_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.fetchScalar
  L8_2 = "SELECT display_name FROM phone_instagram_accounts WHERE username=@loggedInAs"
  L9_2 = L5_2
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = L3_1
  L9_2 = A2_2
  L8_2 = L8_2(L9_2)
  L9_2 = 1
  L10_2 = #L8_2
  L11_2 = 1
  for L12_2 = L9_2, L10_2, L11_2 do
    L13_2 = L8_2[L12_2]
    L14_2 = SendNotification
    L15_2 = L13_2
    L16_2 = {}
    L16_2.app = "Instagram"
    L17_2 = L
    L18_2 = "BACKEND.INSTAGRAM.FOLLOW_REQUEST_ACCEPTED_TITLE"
    L17_2 = L17_2(L18_2)
    L16_2.title = L17_2
    L17_2 = L
    L18_2 = "BACKEND.INSTAGRAM.FOLLOW_REQUEST_ACCEPTED_DESCRIPTION"
    L19_2 = {}
    L19_2.displayName = L7_2
    L19_2.username = L4_2
    L17_2 = L17_2(L18_2, L19_2)
    L16_2.content = L17_2
    L14_2(L15_2, L16_2)
  end
  L9_2 = A1_2
  L10_2 = true
  L9_2(L10_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:search"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = MySQL
  L3_2 = L3_2.Async
  L3_2 = L3_2.fetchAll
  L4_2 = [[
        SELECT username, display_name AS name, profile_image AS avatar, verified, private
        FROM phone_instagram_accounts
        WHERE
            username LIKE CONCAT(@search, "%")
            OR
            display_name LIKE CONCAT("%", @search, "%")
    ]]
  L5_2 = {}
  L5_2["@search"] = A2_2
  L6_2 = A1_2
  L3_2(L4_2, L5_2, L6_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:createAccount"
function L12_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L6_2 = A3_2
  L5_2 = A3_2.lower
  L5_2 = L5_2(L6_2)
  A3_2 = L5_2
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
  L6_2 = IsUsernameValid
  L7_2 = A3_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L6_2 = A1_2
    L7_2 = {}
    L7_2.success = false
    L7_2.error = "USERNAME_NOT_ALLOWED"
    return L6_2(L7_2)
  end
  L6_2 = debugprint
  L7_2 = "INSTAGRAM"
  L8_2 = "%s wants to create an account"
  L9_2 = L8_2
  L8_2 = L8_2.format
  L10_2 = L5_2
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L8_2(L9_2, L10_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.fetchScalar
  L7_2 = "SELECT username FROM phone_instagram_accounts WHERE username=@username"
  L8_2 = {}
  L8_2["@username"] = A3_2
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 then
    L7_2 = debugprint
    L8_2 = "INSTAGRAM"
    L9_2 = "%s tried to create an account with an existing username"
    L10_2 = L9_2
    L9_2 = L9_2.format
    L11_2 = L5_2
    L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L9_2(L10_2, L11_2)
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L7_2 = A1_2
    L8_2 = {}
    L8_2.success = false
    L8_2.error = "USERNAME_TAKEN"
    return L7_2(L8_2)
  end
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.execute
  L8_2 = "INSERT INTO phone_instagram_accounts (display_name, username, password, phone_number) VALUES (@displayName, @username, @password, @phonenumber)"
  L9_2 = {}
  L9_2["@displayName"] = A2_2
  L9_2["@username"] = A3_2
  L10_2 = GetPasswordHash
  L11_2 = A4_2
  L10_2 = L10_2(L11_2)
  L9_2["@password"] = L10_2
  L9_2["@phonenumber"] = L5_2
  L7_2(L8_2, L9_2)
  L7_2 = debugprint
  L8_2 = "INSTAGRAM"
  L9_2 = "%s created an account"
  L10_2 = L9_2
  L9_2 = L9_2.format
  L11_2 = L5_2
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L9_2(L10_2, L11_2)
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L7_2 = AddLoggedInAccount
  L8_2 = L5_2
  L9_2 = "Instagram"
  L10_2 = A3_2
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
    L7_2 = L7_2.InstaPic
    L7_2 = L7_2.Enabled
    if L7_2 then
      L7_2 = Config
      L7_2 = L7_2.AutoFollow
      L7_2 = L7_2.InstaPic
      L7_2 = L7_2.Accounts
      L8_2 = 1
      L9_2 = #L7_2
      L10_2 = 1
      for L11_2 = L8_2, L9_2, L10_2 do
        L12_2 = MySQL
        L12_2 = L12_2.update
        L12_2 = L12_2.await
        L13_2 = "INSERT INTO phone_instagram_follows (followed, follower) VALUES (?, ?)"
        L14_2 = {}
        L15_2 = L7_2[L11_2]
        L16_2 = A3_2
        L14_2[1] = L15_2
        L14_2[2] = L16_2
        L12_2(L13_2, L14_2)
      end
    end
  end
end
L13_1 = {}
L13_1.preventSpam = true
L13_1.rateLimit = 4
L10_1(L11_1, L12_1, L13_1)
L10_1 = L4_1
L11_1 = "changePassword"
function L12_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = Config
  L5_2 = L5_2.ChangePassword
  L5_2 = L5_2.InstaPic
  if not L5_2 then
    L5_2 = infoprint
    L6_2 = "warning"
    L7_2 = "%s tried to change password on InstaPic, but it's not enabled in the config."
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
  L5_2 = L0_1
  L5_2 = L5_2[A2_2]
  if L5_2 then
    L5_2 = debugprint
    L6_2 = "Can't change password when live"
    L5_2(L6_2)
    L5_2 = false
    return L5_2
  end
  L5_2 = MySQL
  L5_2 = L5_2.scalar
  L5_2 = L5_2.await
  L6_2 = "SELECT password FROM phone_instagram_accounts WHERE username = ?"
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
      goto lbl_53
    end
  end
  L6_2 = false
  do return L6_2 end
  ::lbl_53::
  L6_2 = MySQL
  L6_2 = L6_2.update
  L6_2 = L6_2.await
  L7_2 = "UPDATE phone_instagram_accounts SET password = ? WHERE username = ?"
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
  L7_2 = L5_1
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
  L8_2 = "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Instagram' AND phone_number != ?"
  L9_2 = {}
  L10_2 = A2_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L7_2(L8_2, L9_2)
  L7_2 = ClearActiveAccountsCache
  L8_2 = "Instagram"
  L9_2 = A2_2
  L10_2 = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = Log
  L8_2 = "InstaPic"
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
  L14_2.app = "InstaPic"
  L12_2, L13_2, L14_2 = L12_2(L13_2, L14_2)
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = TriggerClientEvent
  L8_2 = "phone:logoutFromApp"
  L9_2 = -1
  L10_2 = {}
  L10_2.username = A2_2
  L10_2.app = "instagram"
  L10_2.reason = "password"
  L10_2.number = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = true
  return L7_2
end
L13_1 = false
L10_1(L11_1, L12_1, L13_1)
L10_1 = L4_1
L11_1 = "deleteAccount"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = Config
  L4_2 = L4_2.DeleteAccount
  L4_2 = L4_2.InstaPic
  if not L4_2 then
    L4_2 = infoprint
    L5_2 = "warning"
    L6_2 = "%s tried to delete their account on InstaPic, but it's not enabled in the config."
    L7_2 = L6_2
    L6_2 = L6_2.format
    L8_2 = A0_2
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2(L7_2, L8_2)
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L4_2 = false
    return L4_2
  end
  L4_2 = L0_1
  L4_2 = L4_2[A2_2]
  if L4_2 then
    L4_2 = debugprint
    L5_2 = "Can't delete account when live"
    L4_2(L5_2)
    L4_2 = false
    return L4_2
  end
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = "SELECT password FROM phone_instagram_accounts WHERE username = ?"
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
      goto lbl_43
    end
  end
  L5_2 = false
  do return L5_2 end
  ::lbl_43::
  L5_2 = MySQL
  L5_2 = L5_2.update
  L5_2 = L5_2.await
  L6_2 = "DELETE FROM phone_instagram_accounts WHERE username = ?"
  L7_2 = {}
  L8_2 = A2_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  L5_2 = L5_2 > 0
  if not L5_2 then
    L6_2 = false
    return L6_2
  end
  L6_2 = L5_1
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
  L7_2 = "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Instagram'"
  L8_2 = {}
  L9_2 = A2_2
  L8_2[1] = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = ClearActiveAccountsCache
  L7_2 = "Instagram"
  L8_2 = A2_2
  L6_2(L7_2, L8_2)
  L6_2 = Log
  L7_2 = "InstaPic"
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
  L13_2.app = "InstaPic"
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L6_2 = TriggerClientEvent
  L7_2 = "phone:logoutFromApp"
  L8_2 = -1
  L9_2 = {}
  L9_2.username = A2_2
  L9_2.app = "instagram"
  L9_2.reason = "deleted"
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = true
  return L6_2
end
L13_1 = false
L10_1(L11_1, L12_1, L13_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:logIn"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = GetEquippedPhoneNumber
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    L6_2.success = false
    L6_2.error = "UNKNOWN"
    return L5_2(L6_2)
  end
  L5_2 = debugprint
  L6_2 = "INSTAGRAM"
  L7_2 = "%s wants to log in on account %s"
  L8_2 = L7_2
  L7_2 = L7_2.format
  L9_2 = L4_2
  L10_2 = A2_2
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2, L9_2, L10_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = debugprint
  L6_2 = "INSTAGRAM"
  L7_2 = "%s is not logged in, checking if account exists"
  L8_2 = L7_2
  L7_2 = L7_2.format
  L9_2 = L4_2
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2, L9_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L6_2 = A2_2
  L5_2 = A2_2.lower
  L5_2 = L5_2(L6_2)
  A2_2 = L5_2
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.fetchScalar
  L6_2 = "SELECT password FROM phone_instagram_accounts WHERE username=@username"
  L7_2 = {}
  L7_2["@username"] = A2_2
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    if not A0_3 then
      L1_3 = debugprint
      L2_3 = "INSTAGRAM"
      L3_3 = "%s tried to log in on non-existing account %s"
      L4_3 = L3_3
      L3_3 = L3_3.format
      L5_3 = L4_2
      L6_3 = A2_2
      L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3, L5_3, L6_3)
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "UNKNOWN_ACCOUNT"
      return L1_3(L2_3)
    else
      L1_3 = VerifyPasswordHash
      L2_3 = A3_2
      L3_3 = A0_3
      L1_3 = L1_3(L2_3, L3_3)
      if not L1_3 then
        L1_3 = debugprint
        L2_3 = "INSTAGRAM"
        L3_3 = "%s tried to log in on account %s with wrong password"
        L4_3 = L3_3
        L3_3 = L3_3.format
        L5_3 = L4_2
        L6_3 = A2_2
        L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3, L5_3, L6_3)
        L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
        L1_3 = A1_2
        L2_3 = {}
        L2_3.success = false
        L2_3.error = "INCORRECT_PASSWORD"
        return L1_3(L2_3)
      end
    end
    L1_3 = debugprint
    L2_3 = "INSTAGRAM"
    L3_3 = "%s logged in on account %s"
    L4_3 = L3_3
    L3_3 = L3_3.format
    L5_3 = L4_2
    L6_3 = A2_2
    L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3, L5_3, L6_3)
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L1_3 = AddLoggedInAccount
    L2_3 = L4_2
    L3_3 = "Instagram"
    L4_3 = A2_2
    L1_3(L2_3, L3_3, L4_3)
    L1_3 = MySQL
    L1_3 = L1_3.Async
    L1_3 = L1_3.fetchAll
    L2_3 = [[
            SELECT
                display_name AS name, username, profile_image AS avatar, verified
            FROM phone_instagram_accounts

            WHERE username = @username
        ]]
    L3_3 = {}
    L4_3 = A2_2
    L3_3["@username"] = L4_3
    function L4_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4
      L1_4 = debugprint
      L2_4 = "INSTAGRAM"
      L3_4 = "%s got account data"
      L4_4 = L3_4
      L3_4 = L3_4.format
      L5_4 = L4_2
      L3_4, L4_4, L5_4 = L3_4(L4_4, L5_4)
      L1_4(L2_4, L3_4, L4_4, L5_4)
      L1_4 = A1_2
      L2_4 = {}
      L2_4.success = true
      L3_4 = A0_4
      if L3_4 then
        L3_4 = L3_4[1]
      end
      L2_4.account = L3_4
      L1_4(L2_4)
    end
    L1_3(L2_3, L3_3, L4_3)
  end
  L5_2(L6_2, L7_2, L8_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:isLoggedIn"
function L12_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = GetEquippedPhoneNumber
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = false
    return L3_2(L4_2)
  end
  L3_2 = GetLoggedInAccount
  L4_2 = L2_2
  L5_2 = "Instagram"
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.single
  L4_2 = L4_2.await
  L5_2 = [[
        SELECT display_name AS `name`, username, profile_image AS avatar, verified
        FROM phone_instagram_accounts
        WHERE username = ?
    ]]
  L6_2 = {}
  L7_2 = L3_2
  L6_2[1] = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = A1_2
  L6_2 = L4_2 or L6_2
  if not L4_2 then
    L6_2 = false
  end
  L5_2(L6_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:signOut"
function L12_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = GetEquippedPhoneNumber
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = false
    return L3_2(L4_2)
  end
  L3_2 = GetLoggedInAccount
  L4_2 = L2_2
  L5_2 = "Instagram"
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = RemoveLoggedInAccount
  L5_2 = L2_2
  L6_2 = "Instagram"
  L7_2 = L3_2
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = A1_2
  L5_2 = true
  L4_2(L5_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getProfile"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.fetchAll
  L5_2 = [[
        SELECT display_name AS name, username, profile_image AS avatar, bio, verified, private, follower_count as followers, following_count as following, post_count as posts,
            (
                IF((SELECT TRUE FROM phone_instagram_follows f WHERE f.followed=@username AND f.follower=@loggedInAs), TRUE, FALSE)
            ) AS isFollowing,
            (
                IF((SELECT TRUE FROM phone_instagram_follow_requests fr WHERE fr.requester=@loggedInAs AND fr.requestee=@username), TRUE, FALSE)
            ) AS requested,

            (SELECT a.story_count > 0) AS hasStory,
            (SELECT a.story_count = (
                SELECT COUNT(*) FROM phone_instagram_stories_views
                WHERE viewer=@loggedInAs
                    AND story_id IN (SELECT id FROM phone_instagram_stories WHERE username=@username)
            )) AS seenStory

        FROM phone_instagram_accounts a

        WHERE a.username=@username
    ]]
  L6_2 = {}
  L6_2["@username"] = A2_2
  L6_2["@loggedInAs"] = L3_2
  function L7_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A0_3[1]
    if L1_3 then
      L1_3 = A0_3[1]
      L3_3 = A2_2
      L2_3 = L0_1
      L2_3 = L2_3[L3_3]
      if L2_3 then
        L2_3 = true
        if L2_3 then
          goto lbl_14
        end
      end
      L2_3 = false
      ::lbl_14::
      L1_3.isLive = L2_3
    end
    L1_3 = A1_2
    L2_3 = A0_3
    if L2_3 then
      L2_3 = L2_3[1]
    end
    if not L2_3 then
      L2_3 = false
    end
    L1_3(L2_3)
  end
  L4_2(L5_2, L6_2, L7_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:createPost"
function L12_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L5_2 = L2_1
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = false
    return L6_2(L7_2)
  end
  L6_2 = ContainsBlacklistedWord
  L7_2 = A0_2
  L8_2 = "InstaPic"
  L9_2 = A3_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if L6_2 then
    L6_2 = A1_2
    L7_2 = false
    return L6_2(L7_2)
  end
  L6_2 = GenerateId
  L7_2 = "phone_instagram_posts"
  L8_2 = "id"
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.execute
  L8_2 = "INSERT INTO phone_instagram_posts (id, username, media, caption, location) VALUES (@id, @username, @media, @caption, @location)"
  L9_2 = {}
  L9_2["@id"] = L6_2
  L9_2["@username"] = L5_2
  L9_2["@media"] = A2_2
  L9_2["@caption"] = A3_2
  L9_2["@location"] = A4_2
  L7_2(L8_2, L9_2)
  L7_2 = A1_2
  L8_2 = true
  L7_2(L8_2)
  L7_2 = {}
  L7_2.username = L5_2
  L7_2.media = A2_2
  L7_2.caption = A3_2
  L7_2.location = A4_2
  L7_2.id = L6_2
  L8_2 = TriggerClientEvent
  L9_2 = "phone:instagram:newPost"
  L10_2 = -1
  L11_2 = L7_2
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = TriggerEvent
  L9_2 = "lb-phone:instapic:newPost"
  L10_2 = L7_2
  L8_2(L9_2, L10_2)
  L8_2 = json
  L8_2 = L8_2.decode
  L9_2 = A2_2
  L8_2 = L8_2(L9_2)
  A2_2 = L8_2
  L8_2 = "**Caption**: "
  L9_2 = A3_2 or L9_2
  if not A3_2 then
    L9_2 = ""
  end
  L10_2 = [[

**Photos**:
]]
  L8_2 = L8_2 .. L9_2 .. L10_2
  L9_2 = 1
  L10_2 = #A2_2
  L11_2 = 1
  for L12_2 = L9_2, L10_2, L11_2 do
    L13_2 = L8_2
    L14_2 = "[Photo %s](%s)\n"
    L15_2 = L14_2
    L14_2 = L14_2.format
    L16_2 = L12_2
    L17_2 = A2_2[L12_2]
    L14_2 = L14_2(L15_2, L16_2, L17_2)
    L13_2 = L13_2 .. L14_2
    L8_2 = L13_2
  end
  L9_2 = L8_2
  L10_2 = "**ID:** "
  L11_2 = L6_2
  L9_2 = L9_2 .. L10_2 .. L11_2
  L8_2 = L9_2
  L9_2 = Log
  L10_2 = "InstaPic"
  L11_2 = A0_2
  L12_2 = "info"
  L13_2 = "New post"
  L14_2 = L8_2
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
  L9_2 = TrackSocialMediaPost
  L10_2 = "instapic"
  L11_2 = A2_2
  L9_2(L10_2, L11_2)
  L9_2 = Config
  L9_2 = L9_2.Post
  L9_2 = L9_2.InstaPic
  if L9_2 then
    L9_2 = INSTAPIC_WEBHOOK
    if L9_2 then
      L9_2 = INSTAPIC_WEBHOOK
      L10_2 = L9_2
      L9_2 = L9_2.sub
      L11_2 = -14
      L9_2 = L9_2(L10_2, L11_2)
      if "/api/webhooks/" ~= L9_2 then
        goto lbl_111
      end
    end
  end
  do return end
  ::lbl_111::
  L9_2 = MySQL
  L9_2 = L9_2.Sync
  L9_2 = L9_2.fetchScalar
  L10_2 = "SELECT profile_image FROM phone_instagram_accounts WHERE username=@username"
  L11_2 = {}
  L11_2["@username"] = L5_2
  L9_2 = L9_2(L10_2, L11_2)
  L10_2 = PerformHttpRequest
  L11_2 = INSTAPIC_WEBHOOK
  function L12_2()
    local L0_3, L1_3
  end
  L13_2 = "POST"
  L14_2 = json
  L14_2 = L14_2.encode
  L15_2 = {}
  L16_2 = Config
  L16_2 = L16_2.Post
  L16_2 = L16_2.Accounts
  if L16_2 then
    L16_2 = L16_2.InstaPic
  end
  if L16_2 then
    L16_2 = L16_2.Username
  end
  if not L16_2 then
    L16_2 = "InstaPic"
  end
  L15_2.username = L16_2
  L16_2 = Config
  L16_2 = L16_2.Post
  L16_2 = L16_2.Accounts
  if L16_2 then
    L16_2 = L16_2.InstaPic
  end
  if L16_2 then
    L16_2 = L16_2.Avatar
  end
  if not L16_2 then
    L16_2 = "https://loaf-scripts.com/fivem/lb-phone/icons/InstaPic.png"
  end
  L15_2.avatar_url = L16_2
  L16_2 = {}
  L17_2 = {}
  L18_2 = L
  L19_2 = "APPS.INSTAGRAM.NEW_POST"
  L18_2 = L18_2(L19_2)
  L17_2.title = L18_2
  if A3_2 then
    L18_2 = #A3_2
    if L18_2 > 0 and A3_2 then
      goto lbl_169
      L18_2 = A3_2 or L18_2
    end
  end
  L18_2 = nil
  ::lbl_169::
  L17_2.description = L18_2
  L17_2.color = 9059001
  L18_2 = GetTimestampISO
  L18_2 = L18_2()
  L17_2.timestamp = L18_2
  L18_2 = {}
  L19_2 = "@"
  L20_2 = L5_2
  L19_2 = L19_2 .. L20_2
  L18_2.name = L19_2
  L19_2 = L9_2 or L19_2
  if not L9_2 then
    L19_2 = "https://cdn.discordapp.com/embed/avatars/5.png"
  end
  L18_2.icon_url = L19_2
  L17_2.author = L18_2
  L18_2 = {}
  L19_2 = A2_2[1]
  L18_2.url = L19_2
  L17_2.image = L18_2
  L18_2 = {}
  L18_2.text = "LB Phone"
  L18_2.icon_url = "https://docs.lbscripts.com/images/icons/icon.png"
  L17_2.footer = L18_2
  L16_2[1] = L17_2
  L15_2.embeds = L16_2
  L14_2 = L14_2(L15_2)
  L15_2 = {}
  L15_2["Content-Type"] = "application/json"
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
end
L13_1 = {}
L13_1.preventSpam = true
L13_1.rateLimit = 6
L10_1(L11_1, L12_1, L13_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:deletePost"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = IsAdmin
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = MySQL
    L4_2 = L4_2.Sync
    L4_2 = L4_2.fetchScalar
    L5_2 = "SELECT TRUE FROM phone_instagram_posts WHERE id=@id AND username=@username"
    L6_2 = {}
    L6_2["@id"] = A2_2
    L6_2["@username"] = L3_2
    L4_2 = L4_2(L5_2, L6_2)
  end
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = {}
  L5_2["@id"] = A2_2
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.execute
  L7_2 = "DELETE FROM phone_instagram_likes WHERE id=@id"
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.execute
  L7_2 = "DELETE FROM phone_instagram_notifications WHERE post_id=@id"
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.execute
  L7_2 = "DELETE FROM phone_instagram_comments WHERE post_id=@id"
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = MySQL
  L6_2 = L6_2.Sync
  L6_2 = L6_2.execute
  L7_2 = "DELETE FROM phone_instagram_posts WHERE id=@id"
  L8_2 = L5_2
  L6_2 = L6_2(L7_2, L8_2)
  L6_2 = L6_2 > 0
  if L6_2 then
    L7_2 = Log
    L8_2 = "InstaPic"
    L9_2 = A0_2
    L10_2 = "error"
    L11_2 = "Deleted post"
    L12_2 = "**ID**: "
    L13_2 = A2_2
    L12_2 = L12_2 .. L13_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  end
  L7_2 = A1_2
  L8_2 = L6_2
  L7_2(L8_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getPost"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.fetchAll
  L5_2 = [[
        SELECT
            p.id, p.media, p.caption, p.username, p.timestamp, p.like_count, p.comment_count, p.location,

            a.verified, a.profile_image AS avatar,

            (IF((
                SELECT TRUE FROM phone_instagram_likes l
                WHERE l.id=p.id AND l.username=@loggedInAs AND l.is_comment=FALSE
            ), TRUE, FALSE)) AS liked

        FROM phone_instagram_posts p

        INNER JOIN phone_instagram_accounts a
            ON p.username = a.username

        WHERE p.id=@id
    ]]
  L6_2 = {}
  L6_2["@id"] = A2_2
  L6_2["@loggedInAs"] = L3_2
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = A0_3
    if L2_3 then
      L2_3 = L2_3[1]
    end
    if not L2_3 then
      L2_3 = false
    end
    L1_3(L2_3)
  end
  L4_2(L5_2, L6_2, L7_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getPosts"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    return L5_2(L6_2)
  end
  if not A2_2 then
    L5_2 = {}
    A2_2 = L5_2
  end
  L5_2 = ""
  L6_2 = "p.timestamp DESC"
  L7_2 = A2_2.following
  if L7_2 then
    L5_2 = [[
            JOIN phone_instagram_follows f

            WHERE f.follower=@loggedInAs
                AND f.followed=p.username
        ]]
  else
    L7_2 = A2_2.profile
    if L7_2 then
      L5_2 = "WHERE p.username=@username"
    else
      L5_2 = [[
            WHERE a.private=FALSE
        ]]
    end
  end
  L7_2 = [[
        SELECT
            p.id, p.media, p.caption, p.username, p.timestamp, p.like_count, p.comment_count, p.location,

            a.verified, a.profile_image AS avatar,

            (IF((
                SELECT TRUE FROM phone_instagram_likes l
                WHERE l.id=p.id AND l.username=@loggedInAs AND l.is_comment=FALSE
            ), TRUE, FALSE)) AS liked

        FROM phone_instagram_posts p

        INNER JOIN phone_instagram_accounts a
            ON p.username = a.username

        %s

        ORDER BY %s

        LIMIT @page, @perPage
    ]]
  L8_2 = L7_2
  L7_2 = L7_2.format
  L9_2 = L5_2
  L10_2 = L6_2
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = MySQL
  L8_2 = L8_2.Async
  L8_2 = L8_2.fetchAll
  L9_2 = L7_2
  L10_2 = {}
  L11_2 = A3_2 * 15
  L10_2["@page"] = L11_2
  L10_2["@perPage"] = 15
  L10_2["@loggedInAs"] = L4_2
  L11_2 = A2_2.username
  L10_2["@username"] = L11_2
  L11_2 = A1_2
  L8_2(L9_2, L10_2, L11_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getComments"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = L2_1
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
            c.id, c.comment, c.`timestamp`, c.like_count,
            a.username, a.profile_image, a.verified,

            (IF((
                SELECT TRUE FROM phone_instagram_likes l
                WHERE l.id=c.id AND l.username=@loggedInAs AND l.is_comment=TRUE
            ), TRUE, FALSE)) AS liked,

            (IF((
                SELECT TRUE FROM phone_instagram_follows f
                WHERE f.follower=@loggedInAs AND f.followed=a.username
            ), TRUE, FALSE)) AS following

        FROM phone_instagram_comments c

        INNER JOIN phone_instagram_accounts a
            ON c.username = a.username

        WHERE c.post_id=@postId

        ORDER BY following DESC, c.like_count DESC, c.`timestamp` DESC

        LIMIT @page, @perPage
    ]]
  L7_2 = {}
  L8_2 = A3_2 * 20
  L7_2["@page"] = L8_2
  L7_2["@perPage"] = 20
  L7_2["@postId"] = A2_2
  L7_2["@loggedInAs"] = L4_2
  L8_2 = A1_2
  L5_2(L6_2, L7_2, L8_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:postComment"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = ContainsBlacklistedWord
  L6_2 = A0_2
  L7_2 = "InstaPic"
  L8_2 = A3_2
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  if L5_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = GenerateId
  L6_2 = "phone_instagram_comments"
  L7_2 = "id"
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = MySQL
  L6_2 = L6_2.Async
  L6_2 = L6_2.execute
  L7_2 = "INSERT INTO phone_instagram_comments (id, post_id, username, comment) VALUES (@id, @postId, @username, @comment)"
  L8_2 = {}
  L8_2["@id"] = L5_2
  L8_2["@postId"] = A2_2
  L8_2["@username"] = L4_2
  L8_2["@comment"] = A3_2
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = MySQL
    L0_3 = L0_3.Async
    L0_3 = L0_3.fetchScalar
    L1_3 = "SELECT username FROM phone_instagram_posts WHERE id=@id"
    L2_3 = {}
    L3_3 = A2_2
    L2_3["@id"] = L3_3
    function L3_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4
      L1_4 = L9_1
      L2_4 = A0_4
      L3_4 = L4_2
      L4_4 = "comment"
      L5_4 = L5_2
      L1_4(L2_4, L3_4, L4_4, L5_4)
    end
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = TriggerClientEvent
    L1_3 = "phone:instagram:updatePostData"
    L2_3 = -1
    L3_3 = A2_2
    L4_3 = "comment_count"
    L5_3 = true
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
    L0_3 = A1_2
    L1_3 = L5_2
    L0_3(L1_3)
  end
  L6_2(L7_2, L8_2, L9_2)
end
L13_1 = {}
L13_1.preventSpam = true
L13_1.rateLimit = 10
L10_1(L11_1, L12_1, L13_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:updateProfile"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = false
    return L4_2(L5_2)
  end
  L4_2 = ""
  L5_2 = A2_2.name
  L6_2 = A2_2.bio
  L7_2 = A2_2.avatar
  L8_2 = A2_2.private
  if L5_2 then
    L9_2 = L4_2
    L10_2 = "display_name=@displayName,"
    L9_2 = L9_2 .. L10_2
    L4_2 = L9_2
  end
  if L6_2 then
    L9_2 = L4_2
    L10_2 = "bio=@bio,"
    L9_2 = L9_2 .. L10_2
    L4_2 = L9_2
  end
  if L7_2 then
    L9_2 = L4_2
    L10_2 = "profile_image=@avatar,"
    L9_2 = L9_2 .. L10_2
    L4_2 = L9_2
  end
  L9_2 = type
  L10_2 = L8_2
  L9_2 = L9_2(L10_2)
  if "boolean" == L9_2 then
    L9_2 = L4_2
    L10_2 = "private=@private,"
    L9_2 = L9_2 .. L10_2
    L4_2 = L9_2
  end
  L10_2 = L4_2
  L9_2 = L4_2.sub
  L11_2 = 1
  L12_2 = -2
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  L4_2 = L9_2
  L9_2 = MySQL
  L9_2 = L9_2.Async
  L9_2 = L9_2.execute
  L10_2 = "UPDATE phone_instagram_accounts SET "
  L11_2 = L4_2
  L12_2 = " WHERE username=@username"
  L10_2 = L10_2 .. L11_2 .. L12_2
  L11_2 = {}
  L11_2["@displayName"] = L5_2
  L11_2["@bio"] = L6_2
  L11_2["@avatar"] = L7_2
  L11_2["@username"] = L3_2
  L11_2["@private"] = L8_2
  function L12_2()
    local L0_3, L1_3
    L0_3 = A1_2
    L1_3 = true
    L0_3(L1_3)
  end
  L9_2(L10_2, L11_2, L12_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:toggleFollow"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 or A2_2 == L4_2 then
    L5_2 = A1_2
    L6_2 = not A3_2
    return L5_2(L6_2)
  end
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    if 0 == A0_3 then
      L1_3 = A1_2
      L2_3 = A3_2
      return L1_3(L2_3)
    end
    L1_3 = TriggerClientEvent
    L2_3 = "phone:instagram:updateProfileData"
    L3_3 = -1
    L4_3 = A2_2
    L5_3 = "followers"
    L6_3 = A3_2
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L1_3 = TriggerClientEvent
    L2_3 = "phone:instagram:updateProfileData"
    L3_3 = -1
    L4_3 = L4_2
    L5_3 = "following"
    L6_3 = A3_2
    L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    L1_3 = A1_2
    L2_3 = A3_2
    L1_3(L2_3)
    L1_3 = A3_2
    if L1_3 then
      L1_3 = L9_1
      L2_3 = A2_2
      L3_3 = L4_2
      L4_3 = "follow"
      L1_3(L2_3, L3_3, L4_3)
    end
  end
  L6_2 = {}
  L6_2["@username"] = A2_2
  L6_2["@loggedInAs"] = L4_2
  L7_2 = MySQL
  L7_2 = L7_2.Sync
  L7_2 = L7_2.fetchScalar
  L8_2 = "SELECT private FROM phone_instagram_accounts WHERE username=@username"
  L9_2 = L6_2
  L7_2 = L7_2(L8_2, L9_2)
  if L7_2 then
    if A3_2 then
      L8_2 = MySQL
      L8_2 = L8_2.Async
      L8_2 = L8_2.execute
      L9_2 = "INSERT IGNORE INTO phone_instagram_follow_requests (requester, requestee) VALUES (@loggedInAs, @username)"
      L10_2 = L6_2
      function L11_2()
        local L0_3, L1_3
        L0_3 = A1_2
        L1_3 = A3_2
        L0_3(L1_3)
      end
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = MySQL
      L8_2 = L8_2.Sync
      L8_2 = L8_2.fetchScalar
      L9_2 = "SELECT display_name FROM phone_instagram_accounts WHERE username=@loggedInAs"
      L10_2 = L6_2
      L8_2 = L8_2(L9_2, L10_2)
      L9_2 = L3_1
      L10_2 = A2_2
      L9_2 = L9_2(L10_2)
      L10_2 = 1
      L11_2 = #L9_2
      L12_2 = 1
      for L13_2 = L10_2, L11_2, L12_2 do
        L14_2 = L9_2[L13_2]
        L15_2 = SendNotification
        L16_2 = L14_2
        L17_2 = {}
        L17_2.app = "Instagram"
        L18_2 = L
        L19_2 = "BACKEND.INSTAGRAM.NEW_FOLLOW_REQUEST_TITLE"
        L18_2 = L18_2(L19_2)
        L17_2.title = L18_2
        L18_2 = L
        L19_2 = "BACKEND.INSTAGRAM.NEW_FOLLOW_REQUEST_DESCRIPTION"
        L20_2 = {}
        L20_2.displayName = L8_2
        L20_2.username = L4_2
        L18_2 = L18_2(L19_2, L20_2)
        L17_2.content = L18_2
        L15_2(L16_2, L17_2)
      end
      return
    end
    L8_2 = MySQL
    L8_2 = L8_2.Async
    L8_2 = L8_2.execute
    L9_2 = "DELETE FROM phone_instagram_follow_requests WHERE requester=@loggedInAs AND requestee=@username"
    L10_2 = L6_2
    L8_2(L9_2, L10_2)
  end
  L8_2 = "INSERT IGNORE INTO phone_instagram_follows (followed, follower) VALUES (@username, @loggedInAs)"
  if not A3_2 then
    L8_2 = "DELETE FROM phone_instagram_follows WHERE followed=@username AND follower=@loggedInAs"
  end
  L9_2 = MySQL
  L9_2 = L9_2.Async
  L9_2 = L9_2.execute
  L10_2 = L8_2
  L11_2 = L6_2
  L12_2 = L5_2
  L9_2(L10_2, L11_2, L12_2)
end
L13_1 = {}
L13_1.preventSpam = true
L10_1(L11_1, L12_1, L13_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:toggleLike"
function L12_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A2_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = L2_1
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L6_2 = A1_2
    L7_2 = false
    return L6_2(L7_2)
  end
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    if 0 == A0_3 then
      L1_3 = A1_2
      L2_3 = A3_2
      return L1_3(L2_3)
    end
    L1_3 = A1_2
    L2_3 = A3_2
    L1_3(L2_3)
    L1_3 = A4_2
    if L1_3 then
      L1_3 = TriggerClientEvent
      L2_3 = "phone:instagram:updateCommentLikes"
      L3_3 = -1
      L4_3 = A2_2
      L5_3 = A3_2
      L1_3(L2_3, L3_3, L4_3, L5_3)
    else
      L1_3 = TriggerClientEvent
      L2_3 = "phone:instagram:updatePostData"
      L3_3 = -1
      L4_3 = A2_2
      L5_3 = "like_count"
      L6_3 = A3_2
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
    end
    L1_3 = A3_2
    if L1_3 then
      L1_3 = MySQL
      L1_3 = L1_3.Async
      L1_3 = L1_3.fetchScalar
      L2_3 = "SELECT username FROM "
      L3_3 = A4_2
      if L3_3 then
        L3_3 = "phone_instagram_comments"
        if L3_3 then
          goto lbl_41
        end
      end
      L3_3 = "phone_instagram_posts"
      ::lbl_41::
      L4_3 = " WHERE id=@postId"
      L2_3 = L2_3 .. L3_3 .. L4_3
      L3_3 = {}
      L4_3 = A2_2
      L3_3["@postId"] = L4_3
      function L4_3(A0_4)
        local L1_4, L2_4, L3_4, L4_4, L5_4
        if A0_4 then
          L1_4 = L9_1
          L2_4 = A0_4
          L3_4 = L5_2
          L4_4 = "like_"
          L5_4 = A4_2
          if L5_4 then
            L5_4 = "comment"
            if L5_4 then
              goto lbl_14
            end
          end
          L5_4 = "photo"
          ::lbl_14::
          L4_4 = L4_4 .. L5_4
          L5_4 = A2_2
          L1_4(L2_4, L3_4, L4_4, L5_4)
        end
      end
      L1_3(L2_3, L3_3, L4_3)
    end
  end
  L7_2 = "INSERT IGNORE INTO phone_instagram_likes (id, username, is_comment) VALUES (@postId, @loggedInAs, @isComment)"
  if not A3_2 then
    L7_2 = "DELETE FROM phone_instagram_likes WHERE id=@postId AND username=@loggedInAs AND is_comment=@isComment"
  end
  L8_2 = MySQL
  L8_2 = L8_2.Async
  L8_2 = L8_2.execute
  L9_2 = L7_2
  L10_2 = {}
  L10_2["@postId"] = A2_2
  L10_2["@loggedInAs"] = L5_2
  L10_2["@isComment"] = A4_2
  L11_2 = L6_2
  L8_2(L9_2, L10_2, L11_2)
end
L13_1 = {}
L13_1.preventSpam = true
L10_1(L11_1, L12_1, L13_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getData"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = {}
    return L5_2(L6_2)
  end
  L5_2 = ""
  L6_2 = ""
  L7_2 = ""
  L8_2 = ""
  if "likes" == A2_2 then
    L5_2 = "phone_instagram_likes"
    L6_2 = "username"
    L7_2 = "id=@postId AND is_comment=@isComment"
    L8_2 = "a.username"
  elseif "followers" == A2_2 then
    L5_2 = "phone_instagram_follows"
    L6_2 = "follower"
    L7_2 = "q.followed=@username"
    L8_2 = "q.follower"
  elseif "following" == A2_2 then
    L5_2 = "phone_instagram_follows"
    L6_2 = "followed"
    L7_2 = "q.follower=@username"
    L8_2 = "q.followed"
  end
  L9_2 = MySQL
  L9_2 = L9_2.Async
  L9_2 = L9_2.fetchAll
  L10_2 = [[
        SELECT
            a.username, a.display_name AS name, a.profile_image AS avatar, a.verified,

            (IF((
                SELECT TRUE FROM phone_instagram_follows f
                WHERE f.followed=a.username AND f.follower=@loggedInAs
            ), TRUE, FALSE)) AS isFollowing

        FROM phone_instagram_accounts a

        INNER JOIN %s q ON q.%s=a.username

        WHERE %s

        ORDER BY %s DESC

        LIMIT @page, @perPage
    ]]
  L11_2 = L10_2
  L10_2 = L10_2.format
  L12_2 = L5_2
  L13_2 = L6_2
  L14_2 = L7_2
  L15_2 = L8_2
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  L11_2 = {}
  L12_2 = A3_2.username
  L11_2["@username"] = L12_2
  L12_2 = A3_2.postId
  L11_2["@postId"] = L12_2
  L12_2 = A3_2.isComment
  L12_2 = true == L12_2
  L11_2["@isComment"] = L12_2
  L11_2["@loggedInAs"] = L4_2
  L12_2 = A3_2.page
  if not L12_2 then
    L12_2 = 0
  end
  L12_2 = L12_2 * 20
  L11_2["@page"] = L12_2
  L11_2["@perPage"] = 20
  L12_2 = A1_2
  L9_2(L10_2, L11_2, L12_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getRecentMessages"
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    return L4_2(L5_2)
  end
  L4_2 = MySQL
  L4_2 = L4_2.Async
  L4_2 = L4_2.fetchAll
  L5_2 = [[
        SELECT
            m.content, m.attachments, m.sender, f_m.username, m.`timestamp`,

            a.display_name AS `name`, a.profile_image AS avatar, a.verified

        FROM phone_instagram_messages m

        JOIN ((
            SELECT (
                CASE WHEN recipient!=@loggedInAs THEN recipient ELSE sender END
            ) AS username, MAX(`timestamp`) AS `timestamp`

            FROM phone_instagram_messages

            WHERE sender=@loggedInAs OR recipient=@loggedInAs

            GROUP BY username
        ) f_m)
        ON m.`timestamp`=f_m.`timestamp`

        INNER JOIN phone_instagram_accounts a
            ON a.username=f_m.username

        WHERE m.sender=@loggedInAs OR m.recipient=@loggedInAs

        GROUP BY f_m.username

        ORDER BY m.`timestamp` DESC

        LIMIT @page, @perPage
    ]]
  L6_2 = {}
  L6_2["@loggedInAs"] = L3_2
  L7_2 = A2_2 or L7_2
  if not A2_2 then
    L7_2 = 0
  end
  L7_2 = L7_2 * 15
  L6_2["@page"] = L7_2
  L6_2["@perPage"] = 15
  L7_2 = A1_2
  L4_2(L5_2, L6_2, L7_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:getMessages"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = L2_1
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
            sender, recipient, content, attachments, `timestamp`

        FROM phone_instagram_messages

        WHERE (sender=@loggedInAs AND recipient=@username) OR (sender=@username AND recipient=@loggedInAs)

        ORDER BY `timestamp` DESC

        LIMIT @page, @perPage
    ]]
  L7_2 = {}
  L7_2["@loggedInAs"] = L4_2
  L7_2["@username"] = A2_2
  L8_2 = A3_2 or L8_2
  if not A3_2 then
    L8_2 = 0
  end
  L8_2 = L8_2 * 25
  L7_2["@page"] = L8_2
  L7_2["@perPage"] = 25
  L8_2 = A1_2
  L5_2(L6_2, L7_2, L8_2)
end
L10_1(L11_1, L12_1)
L10_1 = RegisterLegacyCallback
L11_1 = "instagram:sendMessage"
function L12_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = L2_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = ContainsBlacklistedWord
  L6_2 = A0_2
  L7_2 = "InstaPic"
  L8_2 = A3_2
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  if L5_2 then
    L5_2 = A1_2
    L6_2 = false
    return L5_2(L6_2)
  end
  L5_2 = MySQL
  L5_2 = L5_2.Async
  L5_2 = L5_2.execute
  L6_2 = "INSERT INTO phone_instagram_messages (id, sender, recipient, content, attachments) VALUES (@id, @sender, @recipient, @content, @attachments)"
  L7_2 = {}
  L8_2 = GenerateId
  L9_2 = "phone_instagram_messages"
  L10_2 = "id"
  L8_2 = L8_2(L9_2, L10_2)
  L7_2["@id"] = L8_2
  L7_2["@sender"] = L4_2
  L7_2["@recipient"] = A2_2
  L8_2 = A3_2.content
  L7_2["@content"] = L8_2
  L8_2 = A3_2.attachments
  if L8_2 then
    L8_2 = json
    L8_2 = L8_2.encode
    L9_2 = A3_2.attachments
    L8_2 = L8_2(L9_2)
    if L8_2 then
      goto lbl_46
    end
  end
  L8_2 = nil
  ::lbl_46::
  L7_2["@attachments"] = L8_2
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    if 0 == A0_3 then
      L1_3 = A1_2
      L2_3 = false
      return L1_3(L2_3)
    end
    L1_3 = A1_2
    L2_3 = true
    L1_3(L2_3)
    L1_3 = MySQL
    L1_3 = L1_3.query
    L1_3 = L1_3.await
    L2_3 = "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'Instagram' AND `active` = 1"
    L3_3 = {}
    L4_3 = A2_2
    L3_3[1] = L4_3
    L1_3 = L1_3(L2_3, L3_3)
    if L1_3 then
      L2_3 = #L1_3
      if 0 ~= L2_3 then
        goto lbl_25
      end
    end
    do return end
    ::lbl_25::
    L2_3 = MySQL
    L2_3 = L2_3.single
    L3_3 = "SELECT display_name, username, profile_image FROM phone_instagram_accounts WHERE username = ?"
    L4_3 = {}
    L5_3 = L4_2
    L4_3[1] = L5_3
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4, L9_4, L10_4, L11_4, L12_4
      if not A0_4 then
        return
      end
      L1_4 = 1
      L2_4 = L1_3
      L2_4 = #L2_4
      L3_4 = 1
      for L4_4 = L1_4, L2_4, L3_4 do
        L5_4 = L1_3
        L5_4 = L5_4[L4_4]
        L5_4 = L5_4.phone_number
        L6_4 = GetSourceFromNumber
        L7_4 = L5_4
        L6_4 = L6_4(L7_4)
        if L6_4 then
          L7_4 = TriggerClientEvent
          L8_4 = "phone:instagram:newMessage"
          L9_4 = L6_4
          L10_4 = {}
          L11_4 = L4_2
          L10_4.sender = L11_4
          L11_4 = A2_2
          L10_4.recipient = L11_4
          L11_4 = A3_2.content
          L10_4.content = L11_4
          L11_4 = A3_2.attachments
          L10_4.attachments = L11_4
          L11_4 = os
          L11_4 = L11_4.time
          L11_4 = L11_4()
          L11_4 = L11_4 * 1000
          L10_4.timestamp = L11_4
          L7_4(L8_4, L9_4, L10_4)
        end
        L7_4 = A3_2.content
        L8_4 = string
        L8_4 = L8_4.find
        L9_4 = L7_4
        L10_4 = "<!REPLIED_STORY-DATA="
        L11_4 = nil
        L12_4 = true
        L8_4 = L8_4(L9_4, L10_4, L11_4, L12_4)
        if L8_4 then
          L8_4 = L
          L9_4 = "APPS.INSTAGRAM.REPLIED_TO_YOUR_STORY"
          L8_4 = L8_4(L9_4)
          L7_4 = L8_4
        end
        L8_4 = SendNotification
        L9_4 = L5_4
        L10_4 = {}
        L10_4.app = "Instagram"
        L11_4 = A0_4.display_name
        L10_4.title = L11_4
        L10_4.content = L7_4
        L11_4 = A3_2.attachments
        if L11_4 then
          L11_4 = L11_4[1]
        end
        L10_4.thumbnail = L11_4
        L11_4 = A0_4.profile_image
        L10_4.avatar = L11_4
        L10_4.showAvatar = true
        L8_4(L9_4, L10_4)
      end
    end
    L2_3(L3_3, L4_3, L5_3)
  end
  L5_2(L6_2, L7_2, L8_2)
end
L13_1 = {}
L13_1.preventSpam = true
L13_1.rateLimit = 15
L10_1(L11_1, L12_1, L13_1)
