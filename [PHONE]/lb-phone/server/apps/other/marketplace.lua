local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = 15
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A0_2 then
    A0_2 = 0
  end
  L2_2 = {}
  L3_2 = {}
  if A1_2 then
    L4_2 = A1_2.search
    if L4_2 then
      L4_2 = #L3_2
      L4_2 = L4_2 + 1
      L3_2[L4_2] = "(title LIKE ? OR description LIKE ?)"
      L4_2 = #L2_2
      L4_2 = L4_2 + 1
      L5_2 = "%"
      L6_2 = A1_2.search
      L7_2 = "%"
      L5_2 = L5_2 .. L6_2 .. L7_2
      L2_2[L4_2] = L5_2
      L4_2 = #L2_2
      L4_2 = L4_2 + 1
      L5_2 = "%"
      L6_2 = A1_2.search
      L7_2 = "%"
      L5_2 = L5_2 .. L6_2 .. L7_2
      L2_2[L4_2] = L5_2
      L4_2 = A1_2.from
      if not L4_2 then
        L4_2 = #L3_2
        L4_2 = L4_2 + 1
        L3_2[L4_2] = "OR phone_number LIKE ?"
        L4_2 = #L2_2
        L4_2 = L4_2 + 1
        L5_2 = "%"
        L6_2 = A1_2.search
        L7_2 = "%"
        L5_2 = L5_2 .. L6_2 .. L7_2
        L2_2[L4_2] = L5_2
      end
    end
  end
  if A1_2 then
    L4_2 = A1_2.from
    if L4_2 then
      L4_2 = #L3_2
      L4_2 = L4_2 + 1
      L5_2 = #L3_2
      if L5_2 > 0 then
        L5_2 = "AND "
        if L5_2 then
          goto lbl_63
        end
      end
      L5_2 = ""
      ::lbl_63::
      L6_2 = "phone_number = ?"
      L5_2 = L5_2 .. L6_2
      L3_2[L4_2] = L5_2
      L4_2 = #L2_2
      L4_2 = L4_2 + 1
      L5_2 = A1_2.from
      L2_2[L4_2] = L5_2
    end
  end
  L4_2 = [[
        SELECT
            id,
            phone_number AS `number`,
            title,
            description,
            attachments,
            price,
            `timestamp`
        FROM
            phone_marketplace_posts
        {WHERE}
        ORDER BY
            `timestamp` DESC
        LIMIT ?, ?
    ]]
  L6_2 = L4_2
  L5_2 = L4_2.gsub
  L7_2 = "{WHERE}"
  L8_2 = #L3_2
  if L8_2 > 0 then
    L8_2 = "WHERE "
    L9_2 = table
    L9_2 = L9_2.concat
    L10_2 = L3_2
    L11_2 = " "
    L9_2 = L9_2(L10_2, L11_2)
    L8_2 = L8_2 .. L9_2
    if L8_2 then
      goto lbl_87
    end
  end
  L8_2 = ""
  ::lbl_87::
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2 = L5_2
  L5_2 = #L2_2
  L5_2 = L5_2 + 1
  L6_2 = A0_2 or L6_2
  if not A0_2 then
    L6_2 = 0
  end
  L7_2 = L0_1
  L6_2 = L6_2 * L7_2
  L2_2[L5_2] = L6_2
  L5_2 = #L2_2
  L5_2 = L5_2 + 1
  L6_2 = L0_1
  L2_2[L5_2] = L6_2
  L5_2 = MySQL
  L5_2 = L5_2.query
  L5_2 = L5_2.await
  L6_2 = L4_2
  L7_2 = L2_2
  return L5_2(L6_2, L7_2)
end
L2_1 = BaseCallback
L3_1 = "marketplace:getPosts"
function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = L1_1
  L4_2 = A2_2.page
  L5_2 = {}
  L6_2 = A2_2.from
  L5_2.from = L6_2
  L6_2 = A2_2.query
  L5_2.search = L6_2
  return L3_2(L4_2, L5_2)
end
L2_1(L3_1, L4_1)
L2_1 = BaseCallback
L3_1 = "marketplace:createPost"
function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L3_2 = A2_2.title
  L4_2 = A2_2.description
  L5_2 = A2_2.attachments
  L6_2 = A2_2.price
  if not (L3_2 and L4_2 and L5_2 and L6_2) or L6_2 < 0 then
    L7_2 = false
    return L7_2
  end
  L7_2 = ContainsBlacklistedWord
  L8_2 = A0_2
  L9_2 = "MarketPlace"
  L10_2 = L3_2
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  if not L7_2 then
    L7_2 = ContainsBlacklistedWord
    L8_2 = A0_2
    L9_2 = "MarketPlace"
    L10_2 = L4_2
    L7_2 = L7_2(L8_2, L9_2, L10_2)
    if not L7_2 then
      goto lbl_33
    end
  end
  L7_2 = false
  do return L7_2 end
  ::lbl_33::
  L7_2 = MySQL
  L7_2 = L7_2.insert
  L7_2 = L7_2.await
  L8_2 = "INSERT INTO phone_marketplace_posts (phone_number, title, description, attachments, price) VALUES (?, ?, ?, ?, ?)"
  L9_2 = {}
  L10_2 = A1_2
  L11_2 = L3_2
  L12_2 = L4_2
  L13_2 = json
  L13_2 = L13_2.encode
  L14_2 = L5_2
  L13_2 = L13_2(L14_2)
  L14_2 = L6_2
  L9_2[1] = L10_2
  L9_2[2] = L11_2
  L9_2[3] = L12_2
  L9_2[4] = L13_2
  L9_2[5] = L14_2
  L7_2 = L7_2(L8_2, L9_2)
  if not L7_2 then
    L8_2 = false
    return L8_2
  end
  A2_2.number = A1_2
  A2_2.id = L7_2
  L8_2 = TriggerClientEvent
  L9_2 = "phone:marketplace:newPost"
  L10_2 = -1
  L11_2 = A2_2
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = TriggerEvent
  L9_2 = "lb-phone:marketplace:newPost"
  L10_2 = A2_2
  L8_2(L9_2, L10_2)
  L8_2 = Log
  L9_2 = "Marketplace"
  L10_2 = A0_2
  L11_2 = "info"
  L12_2 = L
  L13_2 = "BACKEND.LOGS.MARKETPLACE_NEW_TITLE"
  L12_2 = L12_2(L13_2)
  L13_2 = L
  L14_2 = "BACKEND.LOGS.MARKETPLACE_NEW_DESCRIPTION"
  L15_2 = {}
  L16_2 = FormatNumber
  L17_2 = A1_2
  L16_2 = L16_2(L17_2)
  L15_2.seller = L16_2
  L15_2.title = L3_2
  L15_2.price = L6_2
  L15_2.description = L4_2
  L16_2 = json
  L16_2 = L16_2.encode
  L17_2 = L5_2
  L16_2 = L16_2(L17_2)
  L15_2.attachments = L16_2
  L15_2.id = L7_2
  L13_2, L14_2, L15_2, L16_2, L17_2 = L13_2(L14_2, L15_2)
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  return L7_2
end
L2_1(L3_1, L4_1)
L2_1 = BaseCallback
L3_1 = "marketplace:deletePost"
function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = IsAdmin
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L5_2 = A2_2
  L4_2[1] = L5_2
  L5_2 = "DELETE FROM phone_marketplace_posts WHERE id = ?"
  if not L3_2 then
    L6_2 = L5_2
    L7_2 = " AND phone_number = ?"
    L6_2 = L6_2 .. L7_2
    L5_2 = L6_2
    L6_2 = #L4_2
    L6_2 = L6_2 + 1
    L4_2[L6_2] = A1_2
  end
  L6_2 = MySQL
  L6_2 = L6_2.update
  L6_2 = L6_2.await
  L7_2 = L5_2
  L8_2 = L4_2
  L6_2 = L6_2(L7_2, L8_2)
  if L6_2 > 0 then
    L7_2 = Log
    L8_2 = "Marketplace"
    L9_2 = A0_2
    L10_2 = "error"
    L11_2 = L
    L12_2 = "BACKEND.LOGS.MARKETPLACE_DELETED"
    L11_2 = L11_2(L12_2)
    L12_2 = "**ID**: %s"
    L13_2 = L12_2
    L12_2 = L12_2.format
    L14_2 = A2_2
    L12_2, L13_2, L14_2 = L12_2(L13_2, L14_2)
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L7_2 = true
    return L7_2
  end
  L7_2 = false
  return L7_2
end
L2_1(L3_1, L4_1)
