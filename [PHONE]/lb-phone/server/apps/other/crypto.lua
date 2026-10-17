


local cfg = Config and Config.Crypto
if not (cfg and cfg.Enabled) then
    debugprint("crypto disabled")
    return
end

-- === Paramètres & état ===
local LIMITS = (cfg.Limits and {
    Buy  = tonumber(cfg.Limits.Buy)  or 1000000,
    Sell = tonumber(cfg.Limits.Sell) or 1000000,
}) or { Buy = 1000000, Sell = 1000000 }

local COIN_IDS = (cfg.Coins and #cfg.Coins > 0) and table.concat(cfg.Coins, ",") or nil
local STATE = {
    hasFetched   = false,
    coins        = {},      -- [id] = { id,name,symbol,image,current_price,prices,change_24h, owned?, invested? }
    customCoins  = {},      -- [id] = coinTable (fusionné dans coins)
}

local reqInWindow = 0
local MAX_REQ = 5
local function allowHttp()
    if reqInWindow >= MAX_REQ then return false end
    reqInWindow = reqInWindow + 1
    SetTimeout(60000, function() reqInWindow = reqInWindow - 1 end)
    return true
end

-- === HTTP GET CoinGecko (Promise/Await) ===
local function fetchCG(path)
    if not allowHttp() then return false end
    local p = promise.new()
    PerformHttpRequest(("https://api.coingecko.com/api/v3/%s"):format(path), function(_, body)
        local ok = body and json.decode(body) or false
        p:resolve(ok)
    end, "GET", "", { ["Content-Type"] = "application/json" })
    return Citizen.Await(p)
end

-- === Lecture cache KVP si TTL valide ===
local function tryLoadCache()
    local last = GetResourceKvpInt("lb-phone:crypto:lastFetched") or 0
    local ttl  = (cfg.Refresh or 60000) / 1000
    if last > (os.time() - ttl) then
        local s = GetResourceKvpString("lb-phone:crypto:coins")
        if s then
            STATE.coins = json.decode(s) or {}
            -- merge custom
            for id, coin in pairs(STATE.customCoins) do
                STATE.coins[id] = coin
            end
            debugprint("crypto: using kvp cache")
            return true
        end
    end
    return false
end

-- === Sauvegarde cache KVP ===
local function saveCache()
    SetResourceKvpInt("lb-phone:crypto:lastFetched", os.time())
    SetResourceKvp("lb-phone:crypto:coins", json.encode(STATE.coins))
end

-- === Rafraîchit les coins depuis CoinGecko (ou vide si pas de liste) ===
local function refreshCoins()
    if tryLoadCache() then return end

    local data = nil
    if COIN_IDS then
        data = fetchCG(("coins/markets?vs_currency=%s&sparkline=true&order=market_cap_desc&precision=full&per_page=100&page=1&ids=%s")
            :format(cfg.Currency, COIN_IDS))
    else
        data = {}
    end

    if not data then
        debugprint("crypto: failed to fetch coins")
        return
    end

    for _, v in ipairs(data) do
        STATE.coins[v.id] = {
            id            = v.id,
            name          = v.name,
            symbol        = v.symbol,
            image         = v.image,
            current_price = v.current_price,
            prices        = (v.sparkline_in_7d and v.sparkline_in_7d.price) or nil,
            change_24h    = v.price_change_percentage_24h,
        }
    end

    -- merge custom
    for id, coin in pairs(STATE.customCoins) do
        STATE.coins[id] = coin
    end

    saveCache()
    debugprint("crypto: fetched coins")
end

-- === Thread de refresh & broadcast aux clients ===
CreateThread(function()
    while true do
        refreshCoins()
        STATE.hasFetched = true
        TriggerClientEvent("phone:crypto:updateCoins", -1, STATE.coins)
        Wait(cfg.Refresh or 60000)
    end
end)

-- === BDD helpers (oxmysql) ===
local function upsertHolding(identifier, coin, amount, invested)
    -- INSERT ... ON DUPLICATE KEY (clé doit couvrir id+coin)
    MySQL.update.await(
        "INSERT INTO phone_crypto (id, coin, amount, invested) VALUES (?, ?, ?, ?) " ..
        "ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount), invested = invested + VALUES(invested)",
        { identifier, coin, amount, invested or 0 }
    )
end

-- === Callbacks (CUSTOM: RegisterCallback doit exister) ===

-- Récupère le portefeuille + cours courants
RegisterCallback("crypto:get", function(src)
    local identifier = GetIdentifier(src) -- CUSTOM
    -- attendre le premier fetch et la fin d'un éventuel check DB (CUSTOM)
    while not STATE.hasFetched or not DatabaseCheckerFinished do
        Wait(500)
    end

    local rows = MySQL.query.await("SELECT coin, amount, invested FROM phone_crypto WHERE id = ?", { identifier })
    -- deep clone des coins (si ta lib a table.deep_clone)
    local coins = table.deep_clone and table.deep_clone(STATE.coins) or json.decode(json.encode(STATE.coins))

    for _, r in ipairs(rows or {}) do
        local c = coins[r.coin]
        if c then
            c.owned    = r.amount
            c.invested = r.invested
        end
    end
    return coins
end)

-- Acheter
RegisterCallback("crypto:buy", function(src, coinId, priceToSpend)
    local identifier = GetIdentifier(src)              -- CUSTOM
    local balance    = GetBalance(src)                  -- CUSTOM

    if type(priceToSpend) ~= "number" or priceToSpend <= 0 then
        return { success = false, msg = "INVALID_AMOUNT" }
    end
    if priceToSpend > LIMITS.Buy then
        debugprint(priceToSpend, "is above crypto buy limit")
        return { success = false, msg = "INVALID_AMOUNT" }
    end
    if priceToSpend > balance then
        return { success = false, msg = "NO_MONEY" }
    end

    local coin = STATE.coins[coinId]
    if not coin then
        return { success = false, msg = "INVALID_COIN" }
    end
    if not identifier then
        return { success = false, msg = "NO_IDENTIFIER" }
    end

    local qty = priceToSpend / coin.current_price
    upsertHolding(identifier, coinId, qty, priceToSpend)
    RemoveMoney(src, priceToSpend)                      -- CUSTOM

    -- Logs (CUSTOM)
    Log("Crypto", src, "success",
        L("BACKEND.LOGS.BOUGHT_CRYPTO"),
        L("BACKEND.LOGS.CRYPTO_DETAILS", { coin = coinId, amount = qty, price = priceToSpend })
    )

    return { success = true }
end, { preventSpam = true })

-- Vendre
RegisterCallback("crypto:sell", function(src, coinId, qtyToSell)
    local identifier = GetIdentifier(src)              -- CUSTOM

    if type(qtyToSell) ~= "number" or qtyToSell <= 0 then
        return { success = false, msg = "INVALID_AMOUNT" }
    end

    local row = MySQL.single.await(
        "SELECT amount, invested FROM phone_crypto WHERE id = ? AND coin = ?",
        { identifier, coinId }
    )
    if not row then
        return { success = false, msg = "NO_COINS" }
    end
    if qtyToSell > row.amount then
        return { success = false, msg = "NOT_ENOUGH_COINS" }
    end

    local coin = STATE.coins[coinId]
    if not coin then
        return { success = false, msg = "INVALID_COIN" }
    end

    local value = qtyToSell * coin.current_price
    if value > LIMITS.Sell then
        debugprint(value, "is above crypto sell limit")
        return { success = false, msg = "INVALID_AMOUNT" }
    end

    MySQL.update.await(
        "UPDATE phone_crypto SET amount = amount - ?, invested = invested - ? WHERE id = ? AND coin = ?",
        { qtyToSell, value, identifier, coinId }
    )
    AddMoney(src, value)                                -- CUSTOM

    -- Logs (CUSTOM)
    Log("Crypto", src, "error",
        L("BACKEND.LOGS.SOLD_CRYPTO"),
        L("BACKEND.LOGS.CRYPTO_DETAILS", { coin = coinId, amount = qtyToSell, price = value })
    )

    return { success = true }
end, { preventSpam = true })

-- Transférer à un autre numéro
BaseCallback("crypto:transfer", function(src, fromNumber, coinId, qty, toNumber) -- CUSTOM: BaseCallback
    local coin = STATE.coins[coinId]
    if not coin then
        return { success = false, msg = "INVALID_COIN" }
    end

    -- Trouver l’identifier du destinataire (en ligne ou via DB)
    local targetSrc = GetSourceFromNumber(toNumber)     -- CUSTOM
    local targetIdentifier
    if targetSrc then
        targetIdentifier = GetIdentifier(targetSrc)     -- CUSTOM
    else
        if not (Config.Item and Config.Item.Unique) then
            targetIdentifier = MySQL.scalar.await("SELECT id FROM phone_phones WHERE phone_number = ?", { toNumber })
        else
            targetIdentifier = MySQL.scalar.await("SELECT owned_id FROM phone_phones WHERE phone_number = ?", { toNumber })
        end
    end
    if not targetIdentifier then
        return { success = false, msg = "INVALID_NUMBER" }
    end

    local fromIdentifier = GetIdentifier(src)           -- CUSTOM
    if type(qty) ~= "number" or qty <= 0 then
        return { success = false, msg = "INVALID_AMOUNT" }
    end

    local owned = MySQL.scalar.await(
        "SELECT amount FROM phone_crypto WHERE id = ? AND coin = ?",
        { fromIdentifier, coinId }
    ) or 0
    if qty > owned then
        return { success = false, msg = "INVALID_AMOUNT" }
    end

    -- débiter l’expéditeur
    MySQL.update.await(
        "UPDATE phone_crypto SET amount = amount - ? WHERE id = ? AND coin = ?",
        { qty, fromIdentifier, coinId }
    )
    -- créditer le destinataire
    upsertHolding(targetIdentifier, coinId, qty, 0)

    -- notif (CUSTOM)
    SendNotification(toNumber, {
        app = "Crypto",
        title   = L("BACKEND.CRYPTO.RECEIVED_TRANSFER_TITLE", { coin = coin.name }),
        content = L("BACKEND.CRYPTO.RECEIVED_TRANSFER_DESCRIPTION", {
            amount = qty,
            coin   = coin.name,
            value  = math.floor(qty * coin.current_price + 0.5),
        }),
    })

    -- logs (CUSTOM)
    Log("Crypto", src, "error",
        L("BACKEND.LOGS.TRANSFERRED_CRYPTO"),
        L("BACKEND.LOGS.TRANSFERRED_CRYPTO_DETAILS", { coin = coinId, amount = qty, to = toNumber, from = fromNumber })
    )

    if targetSrc then
        TriggerClientEvent("phone:crypto:changeOwnedAmount", targetSrc, coinId, qty)
    end
    return { success = true }
end, { preventSpam = true })

-- === Exports (style ESX récent via exports) ===
-- Ajouter des coins à un joueur (server id)
exports("AddCrypto", function(src, coinId, qty)
    local identifier = GetIdentifier(src)              -- CUSTOM
    local coin = STATE.coins[coinId]
    if not coin then
        print("invalid coin", coinId)
        return false
    end
    if not identifier then
        print("no identifier")
        return false
    end
    upsertHolding(identifier, coinId, qty, 0)
    TriggerClientEvent("phone:crypto:changeOwnedAmount", src, coinId, qty)
    return true
end)

-- Retirer des coins à un joueur
exports("RemoveCrypto", function(src, coinId, qty)
    local identifier = GetIdentifier(src)              -- CUSTOM
    local coin = STATE.coins[coinId]
    if not coin then
        print("invalid coin", coinId)
        return false
    end
    if not identifier then
        print("no identifier")
        return false
    end
    MySQL.update.await(
        "UPDATE phone_crypto SET amount = amount - ? WHERE id = ? AND coin = ?",
        { qty, identifier, coinId }
    )
    TriggerClientEvent("phone:crypto:changeOwnedAmount", src, coinId, -qty)
    return true
end)

-- Ajouter/maj un coin custom (persiste dans KVP + push clients)
exports("AddCustomCoin", function(id, name, symbol, image, currentPrice, prices, change24h)
    assert(type(id)            == "string", "id must be a string")
    assert(type(name)          == "string", "name must be a string")
    assert(type(symbol)        == "string", "symbol must be a string")
    assert(type(image)         == "string", "image must be a string")
    assert(type(currentPrice)  == "number", "currentPrice must be a number")
    assert(type(prices)        == "table",  "prices must be a table")
    assert(type(change24h)     == "number", "change24h must be a number")

    local coin = {
        id = id, name = name, symbol = symbol, image = image,
        current_price = currentPrice, prices = prices, change_24h = change24h
    }
    STATE.customCoins[id] = coin
    STATE.coins[id] = coin

    SetResourceKvp("lb-phone:crypto:coins", json.encode(STATE.coins))
    TriggerClientEvent("phone:crypto:updateCoins", -1, STATE.coins)
end)

-- Récupérer un coin
exports("GetCoin", function(id)
    return STATE.coins[id]
end)
