function Response(isSuccess, message, data)

  if not isSuccess then

    return {

      status = "error",

      message = message

    }

  end

  return {

    status = "success",

    data = data,

    message = message

  }

end



function GetGiftCode(code)

  local result = MySQL.single.await('SELECT * FROM giftcodes WHERE code = ? LIMIT 1', { code })

  return result

end



local function decodeGiftCodeRedeems(value)

  if not value or value == '' then return {} end

  local ok, decoded = pcall(json.decode, value)

  if not ok or type(decoded) ~= 'table' then return {} end

  return decoded

end



local function isGiftCodeRowExpired(code)

  local expired = MySQL.scalar.await(

    'SELECT IF(expires_at IS NOT NULL AND expires_at <= NOW(), 1, 0) FROM giftcodes WHERE code = ? LIMIT 1',

    { code }

  )

  return tonumber(expired) == 1

end



--- Atomic reserve: chống race condition khi nhiều người đổi cùng lúc.

---@return boolean ok

---@return table|string rowOrReason

function ReserveGiftCode(code, citizenid)

  local row = MySQL.single.await('SELECT * FROM giftcodes WHERE code = ? LIMIT 1', { code })

  if not row then return false, 'not_found' end



  if isGiftCodeRowExpired(code) then

    return false, 'expired'

  end



  local redeems = decodeGiftCodeRedeems(row.redeems)

  for _, v in ipairs(redeems) do

    if v == citizenid then return false, 'already_redeemed' end

  end



  if row.remaining ~= -1 and tonumber(row.remaining) < 1 then

    return false, 'out_of_uses'

  end



  table.insert(redeems, citizenid)

  local encodedRedeems = json.encode(redeems)

  local affectedRows



  if tonumber(row.remaining) == -1 then

    affectedRows = MySQL.update.await(

      'UPDATE giftcodes SET redeems = ? WHERE code = ? AND remaining = -1 AND (expires_at IS NULL OR expires_at > NOW()) AND NOT JSON_CONTAINS(COALESCE(redeems, "[]"), JSON_QUOTE(?))',

      { encodedRedeems, code, citizenid }

    )

  else

    local newRemaining = tonumber(row.remaining) - 1

    affectedRows = MySQL.update.await(

      'UPDATE giftcodes SET remaining = ?, redeems = ? WHERE code = ? AND remaining = ? AND (expires_at IS NULL OR expires_at > NOW()) AND NOT JSON_CONTAINS(COALESCE(redeems, "[]"), JSON_QUOTE(?))',

      { newRemaining, encodedRedeems, code, row.remaining, citizenid }

    )

    row.remaining = newRemaining

  end



  if not affectedRows or affectedRows == 0 then

    if isGiftCodeRowExpired(code) then

      return false, 'expired'

    end

    return false, 'race_condition'

  end



  row.redeems = redeems

  return true, row

end



---@deprecated Dùng ReserveGiftCode trước khi trao thưởng.

function UpdateGiftCode(citizenid, data)

  ReserveGiftCode(data.code, citizenid)

end



---@param randomCode string

---@param type string

---@param name string

---@param count number

---@param remaining number

---@param rewards any[]? -- optional reward bundle (will be json encoded)

---@param minLevel number? -- minimum player level to redeem (0 = no requirement)

---@param expiresAt string? -- MySQL DATETIME string, nil = không hết hạn

function CreateGiftCode(randomCode, type, name, count, remaining, rewards, minLevel, expiresAt)

  local redeems = json.encode({})

  minLevel = tonumber(minLevel) or 0

  if minLevel < 0 then minLevel = 0 end

  local hwidStrict = (tonumber(remaining) == 1) and 1 or 0



  local insertAttempts = {}



  if rewards ~= nil then

    table.insert(insertAttempts, function()

      return MySQL.insert.await(

        'INSERT INTO giftcodes (code, type, name, count, remaining, redeems, rewards, min_level, hwid_strict, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {

          randomCode, type, name, count, remaining, redeems, json.encode(rewards), minLevel, hwidStrict, expiresAt

        })

    end)

    table.insert(insertAttempts, function()

      return MySQL.insert.await(

        'INSERT INTO giftcodes (code, type, name, count, remaining, redeems, rewards, min_level, hwid_strict) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {

          randomCode, type, name, count, remaining, redeems, json.encode(rewards), minLevel, hwidStrict

        })

    end)

    table.insert(insertAttempts, function()

      return MySQL.insert.await(

        'INSERT INTO giftcodes (code, type, name, count, remaining, redeems, rewards, min_level) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {

          randomCode, type, name, count, remaining, redeems, json.encode(rewards), minLevel

        })

    end)

    table.insert(insertAttempts, function()

      return MySQL.insert.await(

        'INSERT INTO giftcodes (code, type, name, count, remaining, redeems, rewards) VALUES (?, ?, ?, ?, ?, ?, ?)', {

          randomCode, type, name, count, remaining, redeems, json.encode(rewards)

        })

    end)

  end



  table.insert(insertAttempts, function()

    return MySQL.insert.await(

      'INSERT INTO giftcodes (code, type, name, count, remaining, redeems, min_level, hwid_strict, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {

        randomCode, type, name, count, remaining, redeems, minLevel, hwidStrict, expiresAt

      })

  end)

  table.insert(insertAttempts, function()

    return MySQL.insert.await(

      'INSERT INTO giftcodes (code, type, name, count, remaining, redeems, min_level, hwid_strict) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {

        randomCode, type, name, count, remaining, redeems, minLevel, hwidStrict

      })

  end)

  table.insert(insertAttempts, function()

    return MySQL.insert.await(

      'INSERT INTO giftcodes (code, type, name, count, remaining, redeems, min_level) VALUES (?, ?, ?, ?, ?, ?, ?)', {

        randomCode, type, name, count, remaining, redeems, minLevel

      })

  end)

  table.insert(insertAttempts, function()

    return MySQL.insert.await(

      'INSERT INTO giftcodes (code, type, name, count, remaining, redeems) VALUES (?, ?, ?, ?, ?, ?)', {

        randomCode, type, name, count, remaining, redeems

      })

  end)



  for _, attempt in ipairs(insertAttempts) do

    local ok, id = pcall(attempt)

    if ok and id then return id end

  end



  return nil

end

