local Impl = NewImpl("Main")

function Impl:OnReady()
    main:LogInfo("%s ready", self:GetName())
    self.playerCache = {}
    self.primeTicket = {}
    self:CallbackHandler()
    self:EventHandler()
    -- self:InitPrimeTicket()
end

function Impl:InitPrimeTicket()
    local sql = "SELECT * FROM prime_ticket"
    local result = MySQL.query.await(sql)
    if result and result[1] then
        for k, v in pairs(result) do
            self.primeTicket[v.identifier] = v.time
        end
    end
    self:PrimeTicketThread()
end

function Impl:EventHandler()
    AddEventHandler('playerDropped', function()
        local src = source
        for identifier, _ in pairs(self.playerCache) do
            -- self.playerCache keys are identifiers, so if we can clear, or periodic cleanup
        end
    end)
end

function Impl:PrimeTicketThread()
    CreateThread(function()
        while true do
            Wait(60000)
            if next(self.primeTicket) then
                for k, v in pairs(self.primeTicket) do
                    self.primeTicket[k] = self.primeTicket[k] - 60
                    self:UpdatePlayerPrimeTicket(k, v)
                end
            end
        end
    end)
end

function Impl:CallbackHandler()
    -- Unified callback: returns all player menu data in 1 single network roundtrip!
    lib.callback.register("Tipi_menu:sv:getMenuPlayerData", function(source)
        local xPlayer = GetPlayerFromId(source)
        if not xPlayer then return {} end

        local dateRegistered = os.time() * 1000
        pcall(function()
            if self.playerCache and self.playerCache[xPlayer.identifier] then
                dateRegistered = self.playerCache[xPlayer.identifier]
            else
                dateRegistered = GetPlayerRegisteredAt(xPlayer.identifier)
                if self.playerCache then self.playerCache[xPlayer.identifier] = dateRegistered end
            end
        end)

        local phoneNumber = ''
        pcall(function()
            phoneNumber = GetPlayerPhoneNumber(xPlayer) or ''
        end)

        local ageData = { label = Config.Playtime and Config.Playtime.newbieLabel or 'Newbie', level = 0, playtime = 0, display = 'Newbie' }
        pcall(function()
            local playtimeImpl = main:GetImpl('Playtime')
            if playtimeImpl then
                local label, level, playtime = playtimeImpl:GetAgeBySource(source)
                ageData = {
                    label = label,
                    level = level,
                    playtime = playtime,
                    display = Config.FormatPlaytimeAgeDisplay(level, label),
                }
            end
        end)

        local coin = 0
        pcall(function()
            local acc = xPlayer.getAccount('coin')
            coin = acc and tonumber(acc.money) or 0
        end)

        return {
            dateRegistered = dateRegistered,
            phoneNumber = phoneNumber,
            ageData = ageData,
            coin = coin,
        }
    end)

    lib.callback.register("Tipi_menu:sv:getDateRegistered", function(source)
        local xPlayer = GetPlayerFromId(source)
        if not xPlayer then return end
        if not self.playerCache[xPlayer.identifier] then
            local createdAt = GetPlayerRegisteredAt(xPlayer.identifier)
            self.playerCache[xPlayer.identifier] = createdAt
            return createdAt
        end
        return self.playerCache[xPlayer.identifier]
    end)
    lib.callback.register("Tipi_menu:sv:getPhoneNumber", function(source)
        local xPlayer = GetPlayerFromId(source)
        if not xPlayer then return end
        return GetPlayerPhoneNumber(xPlayer)
    end)

    lib.callback.register("Tipi_menu:sv:getPlayerAge", function(source)
        local playtimeImpl = main:GetImpl('Playtime')
        if not playtimeImpl then
            return { label = Config.Playtime and Config.Playtime.newbieLabel or 'Newbie', level = 0, playtime = 0 }
        end
        local label, level, playtime = playtimeImpl:GetAgeBySource(source)
        return {
            label = label,
            level = level,
            playtime = playtime,
            display = Config.FormatPlaytimeAgeDisplay(level, label),
        }
    end)

    lib.callback.register("Tipi_menu:sv:getPlayerCoin", function(source)
        local xPlayer = GetPlayerFromId(source)
        if not xPlayer then return 0 end
        return xPlayer.getAccount('coin').money
    end)


    lib.callback.register("Tipi_menu:sv:buyCoin", function(source, amount)
        if not amount or amount < 1 then return end
        local source = source
        local xPlayer = GetPlayerFromId(source)

        if not xPlayer then return end

        local price = Config.IngameRate[amount]
        if not price then return end
        local coin = xPlayer.getAccount('coin').money
        if coin < price then
            return xPlayer.showNotification("Bạn không đủ coin!")
        end

        xPlayer.removeAccountMoney('coin', price, "Mua IG")
        xPlayer.addMoney(amount)

        TriggerEvent('hm_system:logPlayerDiscord', xPlayer.source, 'coin',
            "Đã mua tiền ingame " .. amount .. "$  với giá " ..
            price .. " Coins (Số dư mới: " ..
            xPlayer.getAccount('coin').money .. " Coins)")
    end)

    lib.callback.register("Tipi_menu:sv:buyNewbie", function(source)
        local xPlayer = GetPlayerFromId(source)

        if not xPlayer then return end

        local price = Config.NewBie["price"]
        if not price then return end
        local coin = xPlayer.getAccount('coin').money
        if coin < price then
            return xPlayer.showNotification("Bạn không đủ coin!")
        end

        xPlayer.removeAccountMoney('coin', price, "Mua Gói Newbie")
        for k, v in pairs(Config.NewBie["item"]) do
            xPlayer.addInventoryItem(v.name, v.amount, "Gói Newbie")
            TriggerEvent('esx:logDiscord', {
                webhookUrl =
                "https://discord.com/api/webhooks/1372643613208739900/WJ6tkpmyqqpXK0qQo1L_REITT5qnSVBT7pOFCrpmF0cunsSDMbQBhZB6tbSjApjpoqN0", -- link webhook cua room
                message = "\nID : " .. xPlayer.idCard .. " | Tên: " ..
                    xPlayer.name .. " \n Đã nhận được: " ..
                    GetItemLabel(v.name) .. "\nSố Lượng: " ..
                    v.amount -- tin nhan gui len discord
            })
        end

        TriggerEvent('hm_system:logPlayerDiscord', xPlayer.source, 'coin',
            "Đã mua gói newbie với giá " .. price ..
            " Coins (Số dư mới: " ..
            xPlayer.getAccount('coin').money .. " Coins)")
    end)

    lib.callback.register("Tipi_menu:sv:getPrimeTicket", function(source)
        local xPlayer = GetPlayerFromId(source)
        if not xPlayer then return end

        if self.primeTicket[xPlayer.identifier] then
            return self.primeTicket[xPlayer.identifier]
        else
            return 0
        end
    end)

    lib.callback.register("Tipi_menu:sv:onBuyPrime", function(source)
        local xPlayer = GetPlayerFromId(source)
        if not xPlayer then return end
        local coin = xPlayer.getAccount('coin').money
        if coin < Config.PrimePrice then
            xPlayer.showNotification("Bạn không đủ coin!")
            return
        end
        if self.primeTicket[xPlayer.identifier] then
            xPlayer.showNotification("Bạn đã có Prime Ticket rồi!")
            return
        end
        local newTime = Config.PrimeDay * 86400
        MySQL.query.await(
            "INSERT INTO prime_ticket SET identifier = ?, time = ?",
            { xPlayer.identifier, newTime })
        self.primeTicket[xPlayer.identifier] = newTime
        xPlayer.removeAccountMoney('coin', Config.PrimePrice, "Mua PrimeTicket")

        TriggerEvent('esx:logDiscord', {
            webhookUrl =
            "https://discord.com/api/webhooks/1375096726033272842/rBGJxXYHgHpDhn_ZO6gPFcEXKA4AnlpbHJ9q2ENhyW41My3zH9TladTASPr3emvRTO92",
            message = string.format(
                "\nID: %s | Tên: %s\nĐã mua Prime Ticket\nGiá: %s Coins\nSố dư còn lại: %s Coins",
                xPlayer.idCard, xPlayer.name, Config.PrimePrice,
                xPlayer.getAccount('coin').money)
        })

        TriggerEvent('hm_system:logPlayerDiscord', xPlayer.source, 'coin',
            "Đã mua Prime Ticket với giá " .. Config.PrimePrice ..
            " Coins (Số dư mới: " ..
            xPlayer.getAccount('coin').money .. " Coins)")
        return newTime
    end)

    lib.callback.register("Tipi_menu:sv:onBuyEvents", function(source, type)
        local xPlayer = GetPlayerFromId(source)
        if not xPlayer then return end
        if Config.Events[Config.CurrentEvent] then
            local cfgData = Config.Events[Config.CurrentEvent]
            if type == "items" then
                if cfgData[type] then
                    local playerCoin = xPlayer.getAccount("coin").money
                    if playerCoin < cfgData[type].price then
                        return xPlayer.showNotification(
                            "Bạn không đủ số dư")
                    end
                    for k, v in pairs(cfgData[type].reward) do
                        xPlayer.addInventoryItem(k, v,
                            "Mua gói vật phẩm " ..
                            Config.CurrentEvent)
                        TriggerEvent('esx:logDiscord', {
                            webhookUrl =
                            "https://discord.com/api/webhooks/1365071062697640107/pbZPwI5tJyGgxRmc3iraiyEYdfNBe-mtFmaGcBmrWehLIZSc0vjv5cmqWgNcaRKt9Y1o", -- link webhook cua room
                            message = "\nID : " .. xPlayer.idCard .. " | Tên: " ..
                                xPlayer.name .. " \n Đã nhận được: " ..
                                GetItemLabel(k) .. "\nSố Lượng: " ..
                                v -- tin nhan gui len discord
                        })
                    end
                    xPlayer.removeAccountMoney("coin", cfgData[type].price)
                    xPlayer.addAccountMoney("pumpkin", cfgData[type].bonus)
                    xPlayer.showNotification("Mua Thành Công", "HM Menu", 3000)
                    return true
                end
            elseif type == 'points' then
                if cfgData[type] then
                    local playerCoin = xPlayer.getAccount("coin").money
                    if playerCoin < cfgData[type].price then
                        return xPlayer.showNotification(
                            "Bạn không đủ số dư")
                    end
                    xPlayer.addAccountMoney("point", cfgData[type].reward,
                        "Mua gói UL Points " ..
                        Config.CurrentEvent)
                    xPlayer.removeAccountMoney("coin", cfgData[type].price)
                    xPlayer.showNotification("Mua Thành Công", "HM Menu", 3000)
                    return true
                end
            else
                local playerCoin = xPlayer.getAccount("coin").money
                if playerCoin < cfgData[type].price then
                    return xPlayer.showNotification(
                        "Bạn không đủ số dư")
                end
                TriggerEvent("hm_vehicleshop:addVehicle", source,
                    cfgData[type].reward, true)
                xPlayer.removeAccountMoney("coin", cfgData[type].price)
                xPlayer.addAccountMoney("pumpkin", cfgData[type].bonus)
                xPlayer.showNotification("Mua Thành Công", "HM Menu", 3000)
                return true
            end
        else
            return false
        end
    end)
end

function Impl:GetPrimeTicket(identifier)
    if self.primeTicket[identifier] then
        return self.primeTicket[identifier]
    else
        return 0
    end
end

function Impl:UpdatePlayerPrimeTicket(identifier, time)
    if time <= 0 then
        self.primeTicket[identifier] = nil
        local sql = "DELETE FROM prime_ticket WHERE identifier = ?"
        MySQL.query.await(sql, { identifier })
    else
        local sql = "UPDATE prime_ticket SET time = ? WHERE identifier = ?"
        MySQL.query.await(sql, { time, identifier })
    end
end
