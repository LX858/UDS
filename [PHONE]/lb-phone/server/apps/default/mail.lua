local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = exports
L1_1 = "GetEmailAddress"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = GetLoggedInAccount
  L2_2 = A0_2
  L3_2 = "Mail"
  return L1_2(L2_2, L3_2)
end
L0_1(L1_1, L2_1)
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = BaseCallback
  L4_2 = "mail:"
  L5_2 = A0_2
  L4_2 = L4_2 .. L5_2
  function L5_2(A0_3, A1_3, ...)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L2_3 = GetLoggedInAccount
    L3_3 = A1_3
    L4_3 = "Mail"
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
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = MySQL
  L3_2 = L3_2.query
  L3_2 = L3_2.await
  L4_2 = "SELECT phone_number FROM phone_logged_in_accounts WHERE username = ? AND app = 'Mail' AND `active` = 1"
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  A1_2.app = "Mail"
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
L2_1 = L0_1
L3_1 = "isLoggedIn"
function L4_1(A0_2, A1_2, A2_2)
  return A2_2
end
L5_1 = false
L2_1(L3_1, L4_1, L5_1)
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if A0_2 and A1_2 then
    L3_2 = #A0_2
    if not (L3_2 < 3) then
      L3_2 = #A1_2
      if not (L3_2 < 3) then
        goto lbl_22
      end
    end
  end
  if A2_2 then
    L3_2 = A2_2
    L4_2 = {}
    L4_2.success = false
    L4_2.reason = "Invalid email / password"
    L3_2(L4_2)
  end
  L3_2 = false
  L4_2 = "Invalid email / password"
  do return L3_2, L4_2 end
  ::lbl_22::
  L3_2 = GetPasswordHash
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  A1_2 = L3_2
  L3_2 = MySQL
  L3_2 = L3_2.scalar
  L3_2 = L3_2.await
  L4_2 = "SELECT 1 FROM phone_mail_accounts WHERE address=?"
  L5_2 = {}
  L6_2 = A0_2
  L5_2[1] = L6_2
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    if A2_2 then
      L4_2 = A2_2
      L5_2 = {}
      L5_2.success = false
      L5_2.error = "Address already exists"
      L4_2(L5_2)
    end
    L4_2 = false
    L5_2 = "Address already exists"
    return L4_2, L5_2
  end
  L4_2 = MySQL
  L4_2 = L4_2.update
  L4_2 = L4_2.await
  L5_2 = "INSERT INTO phone_mail_accounts (address, `password`) VALUES (?, ?)"
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2 = L4_2(L5_2, L6_2)
  L4_2 = 1 == L4_2
  if not L4_2 then
    if A2_2 then
      L5_2 = A2_2
      L6_2 = {}
      L6_2.success = false
      L6_2.error = "Server error"
      L5_2(L6_2)
    end
    L5_2 = false
    L6_2 = "Server error"
    return L5_2, L6_2
  end
  if A2_2 then
    L5_2 = A2_2
    L6_2 = {}
    L6_2.success = true
    L5_2(L6_2)
  end
  L5_2 = true
  return L5_2
end
L3_1 = exports
L4_1 = "CreateMailAccount"
L5_1 = L2_1
L3_1(L4_1, L5_1)
L3_1 = BaseCallback
L4_1 = "mail:createAccount"
function L5_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = #A2_2
  if not (L4_2 < 3) then
    L4_2 = #A3_2
    if not (L4_2 < 3) then
      goto lbl_12
    end
  end
  L4_2 = {}
  L4_2.success = false
  L4_2.error = "Invalid email / password"
  do return L4_2 end
  ::lbl_12::
  L4_2 = A2_2
  L5_2 = "@"
  L6_2 = Config
  L6_2 = L6_2.EmailDomain
  L4_2 = L4_2 .. L5_2 .. L6_2
  A2_2 = L4_2
  L4_2 = L2_1
  L5_2 = A2_2
  L6_2 = A3_2
  L4_2, L5_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L6_2 = AddLoggedInAccount
    L7_2 = A1_2
    L8_2 = "Mail"
    L9_2 = A2_2
    L6_2(L7_2, L8_2, L9_2)
  end
  L6_2 = {}
  L6_2.success = L4_2
  L6_2.error = L5_2
  return L6_2
end
L3_1(L4_1, L5_1)
L3_1 = L0_1
L4_1 = "changePassword"
function L5_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L5_2 = Config
  L5_2 = L5_2.ChangePassword
  L5_2 = L5_2.Mail
  if not L5_2 then
    L5_2 = infoprint
    L6_2 = "warning"
    L7_2 = "%s tried to change password on Mail, but it's not enabled in the config."
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
  L6_2 = "SELECT password FROM phone_mail_accounts WHERE address = ?"
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
  L7_2 = "UPDATE phone_mail_accounts SET password = ? WHERE address = ?"
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
  L7_2 = L1_1
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
  L8_2 = "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Mail' AND phone_number != ?"
  L9_2 = {}
  L10_2 = A2_2
  L11_2 = A1_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L7_2(L8_2, L9_2)
  L7_2 = ClearActiveAccountsCache
  L8_2 = "Mail"
  L9_2 = A2_2
  L10_2 = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = Log
  L8_2 = "Mail"
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
  L14_2.app = "Mail"
  L12_2, L13_2, L14_2 = L12_2(L13_2, L14_2)
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = TriggerClientEvent
  L8_2 = "phone:logoutFromApp"
  L9_2 = -1
  L10_2 = {}
  L10_2.username = A2_2
  L10_2.app = "mail"
  L10_2.reason = "password"
  L10_2.number = A1_2
  L7_2(L8_2, L9_2, L10_2)
  L7_2 = true
  return L7_2
end
L6_1 = false
L3_1(L4_1, L5_1, L6_1)
L3_1 = L0_1
L4_1 = "deleteAccount"
function L5_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = Config
  L4_2 = L4_2.DeleteAccount
  L4_2 = L4_2.Mail
  if not L4_2 then
    L4_2 = infoprint
    L5_2 = "warning"
    L6_2 = "%s tried to delete their account on Mail, but it's not enabled in the config."
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
  L5_2 = "SELECT password FROM phone_mail_accounts WHERE address = ?"
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
  L6_2 = "DELETE FROM phone_mail_accounts WHERE address = ?"
  L7_2 = {}
  L8_2 = A2_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  L5_2 = L5_2 > 0
  if not L5_2 then
    L6_2 = false
    return L6_2
  end
  L6_2 = L1_1
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
  L7_2 = "DELETE FROM phone_logged_in_accounts WHERE username = ? AND app = 'Mail'"
  L8_2 = {}
  L9_2 = A2_2
  L8_2[1] = L9_2
  L6_2(L7_2, L8_2)
  L6_2 = ClearActiveAccountsCache
  L7_2 = "Mail"
  L8_2 = A2_2
  L6_2(L7_2, L8_2)
  L6_2 = Log
  L7_2 = "Mail"
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
  L13_2.app = "Mail"
  L11_2, L12_2, L13_2 = L11_2(L12_2, L13_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L6_2 = TriggerClientEvent
  L7_2 = "phone:logoutFromApp"
  L8_2 = -1
  L9_2 = {}
  L9_2.username = A2_2
  L9_2.app = "mail"
  L9_2.reason = "deleted"
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = true
  return L6_2
end
L6_1 = false
L3_1(L4_1, L5_1, L6_1)
L3_1 = BaseCallback
L4_1 = "mail:login"
function L5_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = MySQL
  L4_2 = L4_2.scalar
  L4_2 = L4_2.await
  L5_2 = "SELECT `password` FROM phone_mail_accounts WHERE address=?"
  L6_2 = {}
  L7_2 = A2_2
  L6_2[1] = L7_2
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "Invalid address"
    return L5_2
  end
  L5_2 = VerifyPasswordHash
  L6_2 = A3_2
  L7_2 = L4_2
  L5_2 = L5_2(L6_2, L7_2)
  if not L5_2 then
    L5_2 = {}
    L5_2.success = false
    L5_2.error = "Invalid password"
    return L5_2
  end
  L5_2 = AddLoggedInAccount
  L6_2 = A1_2
  L7_2 = "Mail"
  L8_2 = A2_2
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = {}
  L5_2.success = true
  return L5_2
end
L6_1 = {}
L6_1.success = false
L6_1.error = "No phone equipped"
L3_1(L4_1, L5_1, L6_1)
L3_1 = L0_1
L4_1 = "logout"
function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = RemoveLoggedInAccount
  L4_2 = A1_2
  L5_2 = "Mail"
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = {}
  L3_2.success = true
  return L3_2
end
L6_1 = {}
L6_1.success = false
L6_1.error = "Not logged in"
L3_1(L4_1, L5_1, L6_1)
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = A0_2.to
  if "all" == L1_2 then
    L1_2 = TriggerClientEvent
    L2_2 = "phone:mail:newMail"
    L3_2 = -1
    L4_2 = A0_2
    L1_2(L2_2, L3_2, L4_2)
    return
  end
  L1_2 = MySQL
  L1_2 = L1_2.query
  L1_2 = L1_2.await
  L2_2 = "SELECT phone_number FROM phone_logged_in_accounts WHERE app = 'Mail' AND username = ? AND active = 1"
  L3_2 = {}
  L4_2 = A0_2.to
  L3_2[1] = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = GetSourceFromNumber
    L9_2 = L7_2.phone_number
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "phone:mail:newMail"
      L11_2 = L8_2
      L12_2 = A0_2
      L9_2(L10_2, L11_2, L12_2)
    end
    L9_2 = SendNotification
    L10_2 = L7_2.phone_number
    L11_2 = {}
    L11_2.app = "Mail"
    L12_2 = A0_2.sender
    L11_2.title = L12_2
    L12_2 = A0_2.subject
    L11_2.content = L12_2
    L12_2 = A0_2.attachments
    L12_2 = L12_2[1]
    L11_2.thumbnail = L12_2
    L9_2(L10_2, L11_2)
  end
end
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = A0_2.to
  if L1_2 then
    L1_2 = A0_2.to
    if "all" == L1_2 then
      goto lbl_21
    end
    L1_2 = MySQL
    L1_2 = L1_2.scalar
    L1_2 = L1_2.await
    L2_2 = "SELECT 1 FROM phone_mail_accounts WHERE address = ?"
    L3_2 = {}
    L4_2 = A0_2.to
    L3_2[1] = L4_2
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      goto lbl_21
    end
  end
  L1_2 = false
  L2_2 = "Invalid address"
  do return L1_2, L2_2 end
  ::lbl_21::
  L1_2 = Config
  L1_2 = L1_2.ConvertMailToMarkdown
  if L1_2 then
    L1_2 = ConvertHTMLToMarkdown
    if L1_2 then
      L1_2 = ConvertHTMLToMarkdown
      L2_2 = A0_2.message
      L1_2 = L1_2(L2_2)
      A0_2.message = L1_2
    end
  end
  L1_2 = A0_2.attachments
  if not L1_2 then
    L1_2 = {}
  end
  A0_2.attachments = L1_2
  L1_2 = A0_2.actions
  if not L1_2 then
    L1_2 = {}
  end
  A0_2.actions = L1_2
  L1_2 = MySQL
  L1_2 = L1_2.insert
  L1_2 = L1_2.await
  L2_2 = "INSERT INTO phone_mail_messages (recipient, sender, subject, content, attachments, actions) VALUES (@recipient, @sender, @subject, @content, @attachments, @actions)"
  L3_2 = {}
  L4_2 = A0_2.to
  L3_2["@recipient"] = L4_2
  L4_2 = A0_2.sender
  if not L4_2 then
    L4_2 = "system"
  end
  L3_2["@sender"] = L4_2
  L4_2 = A0_2.subject
  if not L4_2 then
    L4_2 = "System mail"
  end
  L3_2["@subject"] = L4_2
  L4_2 = A0_2.message
  if not L4_2 then
    L4_2 = ""
  end
  L3_2["@content"] = L4_2
  L4_2 = A0_2.attachments
  L4_2 = #L4_2
  if L4_2 > 0 then
    L4_2 = json
    L4_2 = L4_2.encode
    L5_2 = A0_2.attachments
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_78
    end
  end
  L4_2 = nil
  ::lbl_78::
  L3_2["@attachments"] = L4_2
  L4_2 = A0_2.actions
  L4_2 = #L4_2
  if L4_2 > 0 then
    L4_2 = json
    L4_2 = L4_2.encode
    L5_2 = A0_2.actions
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_90
    end
  end
  L4_2 = nil
  ::lbl_90::
  L3_2["@actions"] = L4_2
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = {}
  L2_2.id = L1_2
  L3_2 = A0_2.to
  L2_2.to = L3_2
  L3_2 = A0_2.sender
  if not L3_2 then
    L3_2 = "System"
  end
  L2_2.sender = L3_2
  L3_2 = A0_2.subject
  if not L3_2 then
    L3_2 = "System mail"
  end
  L2_2.subject = L3_2
  L3_2 = A0_2.message
  if not L3_2 then
    L3_2 = ""
  end
  L2_2.message = L3_2
  L3_2 = A0_2.attachments
  L2_2.attachments = L3_2
  L3_2 = A0_2.actions
  L2_2.actions = L3_2
  L2_2.read = false
  L3_2 = os
  L3_2 = L3_2.time
  L3_2 = L3_2()
  L3_2 = L3_2 * 1000
  L2_2.timestamp = L3_2
  L3_2 = TriggerEvent
  L4_2 = "lb-phone:mail:mailSent"
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
  L3_2 = L3_1
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = true
  L4_2 = L1_2
  return L3_2, L4_2
end
L5_1 = exports
L6_1 = "SendMail"
L7_1 = L4_1
L5_1(L6_1, L7_1)
function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = Config
  L2_2 = L2_2.AutoCreateEmail
  if not L2_2 or not A1_2 then
    return
  end
  L2_2 = GetCharacterName
  L3_2 = A0_2
  L2_2, L3_2 = L2_2(L3_2)
  L5_2 = L2_2
  L4_2 = L2_2.gsub
  L6_2 = "[^%w]"
  L7_2 = ""
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L2_2 = L4_2
  L5_2 = L3_2
  L4_2 = L3_2.gsub
  L6_2 = "[^%w]"
  L7_2 = ""
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L3_2 = L4_2
  L4_2 = #L2_2
  if 0 == L4_2 then
    L4_2 = GenerateString
    L5_2 = 5
    L4_2 = L4_2(L5_2)
    L2_2 = L4_2
  end
  L4_2 = #L3_2
  if 0 == L4_2 then
    L4_2 = GenerateString
    L5_2 = 5
    L4_2 = L4_2(L5_2)
    L3_2 = L4_2
  end
  L4_2 = L2_2
  L5_2 = "."
  L6_2 = L3_2
  L4_2 = L4_2 .. L5_2 .. L6_2
  L5_2 = MySQL
  L5_2 = L5_2.scalar
  L5_2 = L5_2.await
  L6_2 = "SELECT COUNT(1) FROM phone_mail_accounts WHERE address LIKE ?"
  L7_2 = {}
  L8_2 = L4_2
  L9_2 = "%"
  L8_2 = L8_2 .. L9_2
  L7_2[1] = L8_2
  L5_2 = L5_2(L6_2, L7_2)
  if not L5_2 then
    L5_2 = 0
  end
  if L5_2 > 0 then
    L6_2 = L4_2
    L7_2 = L5_2 + 1
    L6_2 = L6_2 .. L7_2
    L4_2 = L6_2
  end
  L6_2 = L4_2
  L7_2 = "@"
  L8_2 = Config
  L8_2 = L8_2.EmailDomain
  L6_2 = L6_2 .. L7_2 .. L8_2
  L7_2 = MySQL
  L7_2 = L7_2.scalar
  L7_2 = L7_2.await
  L8_2 = "SELECT 1 FROM phone_mail_accounts WHERE address=?"
  L9_2 = {}
  L10_2 = L6_2
  L9_2[1] = L10_2
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = 0
  while L7_2 and L8_2 < 50 do
    L9_2 = L2_2
    L10_2 = "."
    L11_2 = L3_2
    L12_2 = math
    L12_2 = L12_2.random
    L13_2 = 1000
    L14_2 = 9999
    L12_2 = L12_2(L13_2, L14_2)
    L13_2 = "@"
    L14_2 = Config
    L14_2 = L14_2.EmailDomain
    L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2
    L6_2 = L9_2
    L9_2 = MySQL
    L9_2 = L9_2.scalar
    L9_2 = L9_2.await
    L10_2 = "SELECT 1 FROM phone_mail_accounts WHERE address=?"
    L11_2 = {}
    L12_2 = L6_2
    L11_2[1] = L12_2
    L9_2 = L9_2(L10_2, L11_2)
    L7_2 = L9_2
    L8_2 = L8_2 + 1
    L9_2 = Wait
    L10_2 = 0
    L9_2(L10_2)
  end
  if L7_2 then
    L9_2 = debugprint
    L10_2 = "Failed to generate address for"
    L11_2 = A0_2
    L9_2(L10_2, L11_2)
    return
  end
  L10_2 = L6_2
  L9_2 = L6_2.lower
  L9_2 = L9_2(L10_2)
  L6_2 = L9_2
  L9_2 = GenerateString
  L10_2 = 5
  L9_2 = L9_2(L10_2)
  L10_2 = L2_1
  L11_2 = L6_2
  L12_2 = L9_2
  L10_2 = L10_2(L11_2, L12_2)
  if not L10_2 then
    return
  end
  L11_2 = AddLoggedInAccount
  L12_2 = A1_2
  L13_2 = "Mail"
  L14_2 = L6_2
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = L4_1
  L12_2 = {}
  L12_2.to = L6_2
  L13_2 = L
  L14_2 = "BACKEND.MAIL.AUTOMATIC_PASSWORD.SENDER"
  L13_2 = L13_2(L14_2)
  L12_2.sender = L13_2
  L13_2 = L
  L14_2 = "BACKEND.MAIL.AUTOMATIC_PASSWORD.SUBJECT"
  L13_2 = L13_2(L14_2)
  L12_2.subject = L13_2
  L13_2 = L
  L14_2 = "BACKEND.MAIL.AUTOMATIC_PASSWORD.MESSAGE"
  L15_2 = {}
  L15_2.address = L6_2
  L15_2.password = L9_2
  L13_2 = L13_2(L14_2, L15_2)
  L12_2.message = L13_2
  L11_2(L12_2)
end
GenerateEmailAccount = L5_1
L5_1 = exports
L6_1 = "DeleteMail"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = MySQL
  L1_2 = L1_2.Sync
  L1_2 = L1_2.execute
  L2_2 = "DELETE FROM phone_mail_messages WHERE id=@id"
  L3_2 = {}
  L3_2["@id"] = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  L1_2 = L1_2 > 0
  if L1_2 then
    L2_2 = TriggerClientEvent
    L3_2 = "phone:mail:mailDeleted"
    L4_2 = -1
    L5_2 = A0_2
    L2_2(L3_2, L4_2, L5_2)
  end
  return L1_2
end
L5_1(L6_1, L7_1)
L5_1 = L0_1
L6_1 = "sendMail"
function L7_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L4_2 = A3_2.to
  if "all" == L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = A3_2.to
  L5_2 = A3_2.subject
  L6_2 = A3_2.message
  L7_2 = A3_2.attachments
  if L4_2 and L5_2 and L6_2 then
    L8_2 = type
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if "table" == L8_2 then
      goto lbl_23
    end
  end
  L8_2 = false
  do return L8_2 end
  ::lbl_23::
  L8_2 = ContainsBlacklistedWord
  L9_2 = A0_2
  L10_2 = "Mail"
  L11_2 = L5_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if not L8_2 then
    L8_2 = ContainsBlacklistedWord
    L9_2 = A0_2
    L10_2 = "Mail"
    L11_2 = L6_2
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    if not L8_2 then
      goto lbl_39
    end
  end
  L8_2 = false
  do return L8_2 end
  ::lbl_39::
  L8_2 = L4_1
  L9_2 = {}
  L9_2.to = L4_2
  L9_2.sender = A2_2
  L9_2.subject = L5_2
  L9_2.message = L6_2
  L9_2.attachments = L7_2
  L8_2, L9_2 = L8_2(L9_2)
  if not L8_2 then
    L10_2 = false
    return L10_2
  end
  L10_2 = Log
  L11_2 = "Mail"
  L12_2 = A0_2
  L13_2 = "info"
  L14_2 = L
  L15_2 = "BACKEND.LOGS.MAIL_TITLE"
  L14_2 = L14_2(L15_2)
  L15_2 = L
  L16_2 = "BACKEND.LOGS.NEW_MAIL"
  L17_2 = {}
  L17_2.sender = A2_2
  L17_2.recipient = L4_2
  L15_2, L16_2, L17_2 = L15_2(L16_2, L17_2)
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  return L9_2
end
L5_1(L6_1, L7_1)
L5_1 = L0_1
L6_1 = "getMails"
function L7_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = A3_2 or nil
  if A3_2 then
    L4_2 = A3_2.lastId
  end
  L5_2 = A3_2 or L5_2
  if A3_2 then
    L5_2 = A3_2.search
    if L5_2 then
      L5_2 = A3_2.search
      L5_2 = #L5_2
      L5_2 = "%"
      L6_2 = A3_2.search
      L7_2 = "%"
      L5_2 = L5_2 > 0 and L5_2
    end
  end
  L6_2 = {}
  L7_2 = A2_2
  L8_2 = A2_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L7_2 = [[
        SELECT
            m.id,
            m.recipient AS `to`,
            m.sender,
            m.`subject`,
            LEFT(m.content, 70) AS message,
            m.`read`,
            m.`timestamp`

        FROM
            phone_mail_messages m

        WHERE (
            recipient=?
            OR recipient="all"
            OR sender=?
        ) {EXCLUDE_DELETED} {SEARCH} {PAGINATION}

        ORDER BY `id` DESC

        LIMIT 10
    ]]
  L8_2 = Config
  L8_2 = L8_2.DeleteMail
  if L8_2 then
    L9_2 = L7_2
    L8_2 = L7_2.gsub
    L10_2 = "{EXCLUDE_DELETED}"
    L11_2 = [[
            AND NOT EXISTS (
                SELECT 1
                FROM phone_mail_deleted d
                WHERE d.message_id = m.id
                AND d.address = ?
            )
        ]]
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L8_2
    L8_2 = #L6_2
    L8_2 = L8_2 + 1
    L6_2[L8_2] = A2_2
  else
    L9_2 = L7_2
    L8_2 = L7_2.gsub
    L10_2 = "{EXCLUDE_DELETED}"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L8_2
  end
  if L5_2 then
    L9_2 = L7_2
    L8_2 = L7_2.gsub
    L10_2 = "{SEARCH}"
    L11_2 = [[
            AND (
                m.recipient LIKE ?
                OR m.sender LIKE ?
                OR m.subject LIKE ?
                OR m.content LIKE ?
            )
        ]]
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L8_2
    L8_2 = #L6_2
    L8_2 = L8_2 + 1
    L6_2[L8_2] = L5_2
    L8_2 = #L6_2
    L8_2 = L8_2 + 1
    L6_2[L8_2] = L5_2
    L8_2 = #L6_2
    L8_2 = L8_2 + 1
    L6_2[L8_2] = L5_2
    L8_2 = #L6_2
    L8_2 = L8_2 + 1
    L6_2[L8_2] = L5_2
  else
    L9_2 = L7_2
    L8_2 = L7_2.gsub
    L10_2 = "{SEARCH}"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L8_2
  end
  if L4_2 then
    L9_2 = L7_2
    L8_2 = L7_2.gsub
    L10_2 = "{PAGINATION}"
    L11_2 = "AND m.id < ?"
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L8_2
    L8_2 = #L6_2
    L8_2 = L8_2 + 1
    L6_2[L8_2] = L4_2
  else
    L9_2 = L7_2
    L8_2 = L7_2.gsub
    L10_2 = "{PAGINATION}"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L8_2
  end
  L8_2 = MySQL
  L8_2 = L8_2.query
  L8_2 = L8_2.await
  L9_2 = L7_2
  L10_2 = L6_2
  return L8_2(L9_2, L10_2)
end
L8_1 = {}
L5_1(L6_1, L7_1, L8_1)
L5_1 = L0_1
L6_1 = "getMail"
function L7_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = MySQL
  L4_2 = L4_2.single
  L4_2 = L4_2.await
  L5_2 = [[
        SELECT
            id, recipient AS `to`, sender, subject, content as message, attachments, `read`, `timestamp`, actions

        FROM phone_mail_messages

        WHERE (
            recipient=@address
            OR recipient="all"
            OR sender=@address
        ) AND id=@id
    ]]
  L6_2 = {}
  L6_2["@address"] = A2_2
  L6_2["@id"] = A3_2
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L5_2 = false
    return L5_2
  end
  L5_2 = L4_2.read
  if not L5_2 then
    L5_2 = MySQL
    L5_2 = L5_2.update
    L6_2 = "UPDATE phone_mail_messages SET `read`=1 WHERE id=? AND sender != ?"
    L7_2 = {}
    L8_2 = A3_2
    L9_2 = A2_2
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L5_2(L6_2, L7_2)
  end
  return L4_2
end
L5_1(L6_1, L7_1)
L5_1 = L0_1
L6_1 = "deleteMail"
function L7_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2
  L4_2 = Config
  L4_2 = L4_2.DeleteMail
  if not L4_2 then
    return
  end
  L4_2 = MySQL
  L4_2 = L4_2.update
  L4_2 = L4_2.await
  L5_2 = "INSERT IGNORE INTO phone_mail_deleted (message_id, address) VALUES (?, ?)"
  L6_2 = {}
  L7_2 = A3_2
  L8_2 = A2_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2(L5_2, L6_2)
  L4_2 = true
  return L4_2
end
L5_1(L6_1, L7_1)
