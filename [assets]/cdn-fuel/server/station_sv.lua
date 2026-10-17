if Config.PlayerOwnedGasStationsEnabled then -- This is so Player Owned Gas Stations are a Config Option, instead of forced. Set this option in shared/config.lua!
    
    -- Variables
    local QBCore = exports[Config.Core]:GetCoreObject()
    local FuelPickupSent = {} -- This is in case of an issue with vehicles not spawning when picking up vehicles.
    local CENTRAL_STATION = Config.CentralStation or 5 -- Cây xăng số 5 Strawberry Ave Xero là cây xăng tổng kho thành phố

    -- ========================
    -- STATION ACCESS CACHE
    -- ========================
    local stationAccessCache = {}
    local CACHE_TTL = 30000 -- 30 giây tính bằng ms (GetGameTimer)

    local function invalidateStationCache(citizenid, location)
        if citizenid and location then
            stationAccessCache[tostring(citizenid) .. ":" .. tostring(location)] = nil
        elseif location then
            local suffix = ":" .. tostring(location)
            for key in pairs(stationAccessCache) do
                if string.sub(key, -#suffix) == suffix then stationAccessCache[key] = nil end
            end
        elseif citizenid then
            local prefix = tostring(citizenid) .. ":"
            for key in pairs(stationAccessCache) do
                if string.sub(key, 1, #prefix) == prefix then stationAccessCache[key] = nil end
            end
        end
    end

    -- ========================
    -- STATION STATIC DATA CACHE (RAM)
    -- Giúp giảm tải 100% các query SELECT cây xăng định kỳ từ client
    -- ========================
    local stationDataCache = {} -- [location] = { owned = 0/1, owner = citizenid, label = name }

    local function LoadStationDataCache()
        MySQL.Async.fetchAll('SELECT location, owned, owner, label FROM fuel_stations', {}, function(result)
            if result then
                for _, v in pairs(result) do
                    local loc = tonumber(v.location)
                    if loc then
                        stationDataCache[loc] = {
                            owned = 1,
                            owner = "cayxang",
                            label = tostring(v.label or "")
                        }
                    end
                end
                if Config.FuelDebug then print("[CDN-Fuel] Loaded " .. tostring(#result) .. " fuel stations into memory cache!") end
            end
        end)
    end

    local function IsStationOwned(loc)
        return true -- Mặc định tất cả cây xăng đều thuộc Doanh Nghiệp Cây Xăng
    end

    if MySQL and MySQL.ready then
        MySQL.ready(function()
            LoadStationDataCache()
        end)
    end
    CreateThread(function()
        Wait(2000)
        -- Mặc định cập nhật tất cả cây xăng thuộc về Doanh Nghiệp Cây Xăng (job cayxang)
        MySQL.Async.execute('UPDATE fuel_stations SET owned = 1, owner = "cayxang"')
        LoadStationDataCache()

        -- Đảm bảo Cây xăng #5 (Tổng kho thành phố) có dữ liệu và trữ lượng ban đầu
        local maxFuel = Config.MaxFuelReserves or 100000
        MySQL.Async.fetchAll('SELECT fuel FROM fuel_stations WHERE location = ?', { CENTRAL_STATION }, function(res)
            if not res or #res == 0 then
                MySQL.Async.execute('INSERT INTO fuel_stations (location, owned, owner, fuel, fuelprice, balance, label) VALUES (?, 1, "cayxang", ?, 3, 0, ?)',
                    { CENTRAL_STATION, maxFuel, (Config.GasStations[CENTRAL_STATION] and Config.GasStations[CENTRAL_STATION].label) or "Strawberry Ave Xero (Tổng Kho)" })
            elseif tonumber(res[1].fuel or 0) <= 0 then
                MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE location = ?', { maxFuel, CENTRAL_STATION })
            end
        end)
    end)

    -- ========================
    -- DISCORD WEBHOOK CONFIG
    -- ========================
    -- Đặt các convar này trong server.cfg (hoặc dùng mặc định đã config bên dưới):
    local DEFAULT_WEBHOOK_NHAP_XANG    = 'https://discord.com/api/webhooks/1538175665386295417/qnalPOSdznG24ZajL96WtT2RlzXKIUwuhFNo73RpwRKWnuG2I1kB0wzw3qC7Yy60qE6Y'
    local DEFAULT_WEBHOOK_BAN_XANG     = 'https://discord.com/api/webhooks/1536371328020385807/R47EAdN-EN0SBpUZljJ0vZW1V_Fp8EiA0eJZYblZmj1GwN34zXPXIeo4a19EQoIBy9UI'
    local DEFAULT_WEBHOOK_BAN_CAN_XANG = 'https://discord.com/api/webhooks/1536371633982414958/PCic57MxAlcM1HntDSef3Wp8hitpO82IYNEBe9bBA9iOK-O329GbkjC2-SQHAGJEvcCG'

    local convarNhapXang   = GetConvar('cdn_fuel_webhook_nhapxang', '')
    local convarBanXang    = GetConvar('cdn_fuel_webhook_banxang', '')
    local convarBanCanXang = GetConvar('cdn_fuel_webhook_bancanxang', '')
    if convarBanCanXang == '' then
        convarBanCanXang = GetConvar('cdn_fuel_webhook_layxang', '')
    end

    local WEBHOOK_NHAP_XANG    = (convarNhapXang ~= '' and convarNhapXang) or DEFAULT_WEBHOOK_NHAP_XANG
    local WEBHOOK_BAN_XANG     = (convarBanXang ~= '' and convarBanXang) or DEFAULT_WEBHOOK_BAN_XANG
    local WEBHOOK_BAN_CAN_XANG = (convarBanCanXang ~= '' and convarBanCanXang) or DEFAULT_WEBHOOK_BAN_CAN_XANG


    local function SendWebhook(webhookUrl, title, color, fields)
        if not webhookUrl or webhookUrl == '' then return end
        local embedFields = {}
        for _, f in ipairs(fields) do
            embedFields[#embedFields + 1] = {
                name   = f[1],
                value  = tostring(f[2]),
                inline = f[3] or false
            }
        end
        local payload = json.encode({
            username = "CDN-Fuel Logger",
            avatar_url = "https://i.imgur.com/4M34hi2.png",
            embeds = {{
                title       = title,
                color       = color,
                fields      = embedFields,
                footer      = { text = os.date("%d/%m/%Y %H:%M:%S") },
            }}
        })
        PerformHttpRequest(webhookUrl, function(err, text, headers)
            if err ~= 200 and err ~= 204 then
                print(string.format("^1[cdn-fuel] Discord Webhook Error (%s): %s^7", tostring(err), tostring(text)))
            end
        end, 'POST', payload, { ['Content-Type'] = 'application/json' })
    end

    local function GetPlayerInfo(src)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return "N/A", "N/A", "N/A" end
        local pd = Player.PlayerData
        local name = (pd.charinfo and (pd.charinfo.firstname .. " " .. pd.charinfo.lastname)) or "Unknown"
        return pd.citizenid or "N/A", name, tostring(src)
    end

    -- Chỉ gửi webhook khi người thực hiện là nhân viên cây xăng đang bật ca (on duty)
    local function IsOnDutyFuelEmployee(src)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not Player.PlayerData.job then return false end
        if Player.PlayerData.job.name ~= 'cayxang' then return false end
        local onDuty = Player.PlayerData.job.onduty
        return onDuty == true or onDuty == 1 or onDuty == 'true'
    end

    -- Functions
    local function GlobalTax(value)
        local tax = (value / 100 * Config.GlobalTax)
        return tax
    end

    function math.percent(percent, maxvalue)
        if tonumber(percent) and tonumber(maxvalue) then
            return (maxvalue*percent)/100
        end
        return false
    end

    local function UpdateStationLabel(location, newLabel, src)
        local loc = tonumber(location)
        if not newLabel or newLabel == nil then
            if loc and stationDataCache[loc] and stationDataCache[loc].label and stationDataCache[loc].label ~= "" then
                local label = stationDataCache[loc].label
                if src then
                    TriggerClientEvent('cdn-fuel:client:updatestationlabels', src, location, label)
                else
                    TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, location, label)
                end
                return
            end
            if Config.FuelDebug then print('Attempting to fetch label for Location #'..location) end
            MySQL.Async.fetchAll('SELECT label FROM fuel_stations WHERE location = ?', {location}, function(result)
                if result and result[1] then
                    local label = result[1].label
                    if loc then
                        stationDataCache[loc] = stationDataCache[loc] or { owned = 0, owner = "0" }
                        stationDataCache[loc].label = label
                    end
                    if src then
                        TriggerClientEvent('cdn-fuel:client:updatestationlabels', src, location, label)
                    else
                        TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, location, label)
                    end
                end
            end)
        else
            if loc then
                stationDataCache[loc] = stationDataCache[loc] or { owned = 0, owner = "0" }
                stationDataCache[loc].label = newLabel
            end
            if Config.FuelDebug then print(newLabel, location) end
            MySQL.Async.execute('UPDATE fuel_stations SET label = ? WHERE `location` = ?', {newLabel, location})
            if src then
                TriggerClientEvent('cdn-fuel:client:updatestationlabels', src, location, newLabel)
            else
                TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, location, newLabel)
            end
        end
    end
    
    -- Events
    RegisterNetEvent('cdn-fuel:server:updatelocationlabels', function()
        local src = source
        local allLabels = {}
        if next(stationDataCache) ~= nil then
            for loc, data in pairs(stationDataCache) do
                if data.label and data.label ~= "" then
                    allLabels[loc] = data.label
                end
            end
            TriggerClientEvent('cdn-fuel:client:syncAllStationLabels', src, allLabels)
        else
            MySQL.Async.fetchAll('SELECT location, label FROM fuel_stations', {}, function(result)
                if result then
                    for _, v in pairs(result) do
                        local loc = tonumber(v.location)
                        if loc and v.label and v.label ~= "" then
                            allLabels[loc] = v.label
                        end
                    end
                end
                TriggerClientEvent('cdn-fuel:client:syncAllStationLabels', src, allLabels)
            end)
        end
    end)

    RegisterNetEvent('cdn-fuel:server:buyStation', function(location, CitizenID)
        local src = source
        TriggerClientEvent('QBCore:Notify', src, "Tất cả cây xăng hiện tại đã thuộc quyền quản lý của Doanh Nghiệp Cây Xăng!", "primary", 7500)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:sellstation', function(location)
        local src = source
        TriggerClientEvent('QBCore:Notify', src, "Cây xăng là tài sản của Doanh Nghiệp Cây Xăng, không thể bán lẻ!", "error", 7500)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:transferStation', function(location, targetServerId, targetCitizenId)
        local src = source
        TriggerClientEvent('QBCore:Notify', src, "Cây xăng thuộc quyền sở hữu chung của Doanh Nghiệp Cây Xăng!", "error", 7500)
    end)

    local function IsManagerOrOwner(citizenid, location, src)
        local Player = (src and QBCore.Functions.GetPlayer(src)) or (citizenid and QBCore.Functions.GetPlayerByCitizenId(citizenid))
        if Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name == 'cayxang' then
            local jGrade = tonumber(Player.PlayerData.job.grade and (Player.PlayerData.job.grade.level or Player.PlayerData.job.grade)) or 0
            if jGrade >= 1 then
                return true
            end
        end
        return false
    end

    -- Chủ trạm HOẶC bất kỳ nhân viên nào có job cayxang đều được nhập xăng
    local function IsOwnerOrEmployee(citizenid, location, src)
        local Player = (src and QBCore.Functions.GetPlayer(src)) or (citizenid and QBCore.Functions.GetPlayerByCitizenId(citizenid))
        if Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name == 'cayxang' then
            return true
        end
        return false
    end

    local function PerformWithdraw(src, Player, loc, amt)
        MySQL.Async.execute('UPDATE fuel_stations SET balance = balance - ? WHERE location = ? AND balance >= ?', { amt, CENTRAL_STATION, amt }, function(affectedRows)
            if affectedRows and affectedRows > 0 then
                Player.Functions.AddMoney("cash", amt, "Rút tiền từ quỹ Doanh Nghiệp Cây Xăng")
                TriggerClientEvent('QBCore:Notify', src, "Đã rút thành công $" .. amt .. " tiền mặt từ quỹ Doanh Nghiệp Cây Xăng!", "success", 7500)
            else
                TriggerClientEvent('QBCore:Notify', src, "Số dư quỹ Doanh Nghiệp không đủ để rút $" .. amt .. "!", "error", 7500)
            end
        end)
    end

    RegisterNetEvent('cdn-fuel:stations:server:withdrawmoney', function(location, amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local amt = tonumber(amount)
        if not amt or amt <= 0 then
            TriggerClientEvent('QBCore:Notify', src, "Số tiền rút không hợp lệ!", "error", 7500)
            return
        end

        local citizenid = Player.PlayerData.citizenid

        if not IsManagerOrOwner(citizenid, location, src) then
            TriggerClientEvent('QBCore:Notify', src, "Chỉ có Giám Đốc hoặc Quản lý Doanh Nghiệp Cây Xăng mới có quyền rút tiền!", "error", 7500)
            return
        end

        PerformWithdraw(src, Player, location, amt)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:depositmoney', function(location, amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local amt = tonumber(amount)
        if not amt or amt <= 0 then
            TriggerClientEvent('QBCore:Notify', src, "Số tiền gửi không hợp lệ!", "error", 7500)
            return
        end

        local bankMoney = Player.PlayerData.money and Player.PlayerData.money.bank or 0
        local cashMoney = Player.PlayerData.money and Player.PlayerData.money.cash or 0

        local moneyType = "bank"
        if bankMoney < amt then
            if cashMoney >= amt then
                moneyType = "cash"
            else
                TriggerClientEvent('QBCore:Notify', src, "Tài khoản cá nhân của bạn không đủ $" .. amt .. "!", "error", 7500)
                return
            end
        end

        if Player.Functions.RemoveMoney(moneyType, amt, "Gửi tiền vào quỹ Doanh Nghiệp Cây Xăng") then
            MySQL.Async.execute('UPDATE fuel_stations SET balance = balance + ? WHERE location = ?', { amt, CENTRAL_STATION }, function()
                TriggerClientEvent('QBCore:Notify', src, "Đã gửi thành công $" .. amt .. " vào quỹ Doanh Nghiệp Cây Xăng!", "success", 7500)
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, "Không thể trừ tiền từ tài khoản!", "error", 7500)
        end
    end)

    RegisterNetEvent('cdn-fuel:station:server:Withdraw', function(amount, location, StationBalance)
        TriggerEvent('cdn-fuel:stations:server:withdrawmoney', location, amount)
    end)

    RegisterNetEvent('cdn-fuel:station:server:Deposit', function(amount, location, StationBalance)
        TriggerEvent('cdn-fuel:stations:server:depositmoney', location, amount)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:Shutoff', function(location)
        local src = source
        if Config.FuelDebug then print("Toggling Emergency Shutoff Valves for Location #"..location) end
        Config.GasStations[location].shutoff = not Config.GasStations[location].shutoff
        Wait(5)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("station_shutoff_success"), 'success')
        if Config.FuelDebug then print('Successfully altered the shutoff valve state for location #'..location..'!') end
        if Config.FuelDebug then print(Config.GasStations[location].shutoff) end
    end)

    RegisterNetEvent('cdn-fuel:stations:server:alterfuelprice', function(location, price)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local loc = tonumber(location)
        local newPrice = tonumber(price)

        if not loc or loc <= 0 or not newPrice or newPrice <= 0 then
            TriggerClientEvent('QBCore:Notify', src, "Giá xăng không hợp lệ!", "error", 7500)
            return
        end

        if not IsManagerOrOwner(Player.PlayerData.citizenid, loc, src) then
            TriggerClientEvent('QBCore:Notify', src, "Chỉ có Giám Đốc hoặc Quản lý Doanh Nghiệp Cây Xăng mới có quyền chỉnh giá xăng!", "error", 7500)
            return
        end

        local minPrice = tonumber(Config.MinimumFuelPrice) or 1
        local maxPrice = tonumber(Config.MaxFuelPrice) or 20

        if newPrice < minPrice then
            TriggerClientEvent('QBCore:Notify', src, "Giá xăng không được thấp hơn $" .. minPrice .. " / Lít!", "error", 7500)
            return
        end

        if newPrice > maxPrice then
            TriggerClientEvent('QBCore:Notify', src, "Giá xăng không được vượt quá $" .. maxPrice .. " / Lít!", "error", 7500)
            return
        end

        MySQL.Async.execute('UPDATE fuel_stations SET fuelprice = ?', { newPrice }, function()
            TriggerClientEvent('QBCore:Notify', src, "Đã cập nhật giá bán xăng toàn thành phố: $" .. newPrice .. " / Lít!", "success", 7500)
            TriggerClientEvent('cdn-fuel:stations:client:updateStationFuelPrice', -1, loc, newPrice)
        end)
    end)

    RegisterNetEvent('cdn-fuel:station:server:updatefuelprice', function(fuelprice, location)
        TriggerEvent('cdn-fuel:stations:server:alterfuelprice', location, fuelprice)
    end)

    RegisterNetEvent('cdn-fuel:station:server:updatereserves', function(reason, amount, currentlevel, location)
        local src = source
        local loc = tonumber(location)
        local amt = tonumber(amount)
        if not amt or amt <= 0 then return end

        if reason == "remove" then
            -- Toàn thành phố cùng trừ trữ lượng từ Kho Xăng Tổng (CENTRAL_STATION #5)
            MySQL.Async.execute('UPDATE fuel_stations SET fuel = GREATEST(0, fuel - ?) WHERE location = ?', {amt, CENTRAL_STATION})
        elseif reason == "add" then
            local maxCap = Config.MaxFuelReserves or 100000
            MySQL.Async.execute('UPDATE fuel_stations SET fuel = LEAST(?, fuel + ?) WHERE location = ?', {maxCap, amt, CENTRAL_STATION})
        end

        -- WEBHOOK: Log bán xăng / bơm xăng tại trạm
        if reason == "remove" and src and src > 0 then
            local cid_bx, name_bx, _ = GetPlayerInfo(src)
            local isEmp = IsOnDutyFuelEmployee(src)
            local stationLabel = (Config.GasStations and Config.GasStations[loc] and Config.GasStations[loc].label) or ("Trạm Cây Xăng #" .. tostring(loc or "N/A"))
            SendWebhook(WEBHOOK_BAN_XANG, "⛽ Bán Xăng / Bơm Xăng Tại Trạm", 0x2ECC71, {
                { "👤 Người Bơm",       name_bx .. " (ID: " .. tostring(src) .. ")", true },
                { "🪪 Citizen ID",       cid_bx,                                      true },
                { "🏪 Cây Xăng",         stationLabel,                                true },
                { "⛽ Lượng Xăng",       amt .. "L (Trừ Kho Tổng #" .. tostring(CENTRAL_STATION) .. ")", true },
                { "👨‍💼 Vai Trò",          isEmp and "Nhân Viên (On Duty)" or "Khách Hàng (Tự Đổ)", true },
            })
        end
    end)

    RegisterNetEvent('cdn-fuel:station:server:updateelectricreserves', function(reason, amount, location)
        local loc = tonumber(location)
        local amt = tonumber(amount)
        if not loc or loc <= 0 or not amt or amt <= 0 then return end

        if reason == "remove" then
            MySQL.Async.execute('UPDATE fuel_stations SET electric = GREATEST(0, electric - ?) WHERE location = ?', { amt, loc })
        elseif reason == "add" then
            local maxElec = Config.MaxElectricReserves or 10000
            MySQL.Async.execute('UPDATE fuel_stations SET electric = LEAST(?, electric + ?) WHERE location = ?', { maxElec, amt, loc })
        end
    end)

    RegisterNetEvent('cdn-fuel:station:server:updatebalance', function(reason, amount, StationBalance, location, FuelPrice)
        local loc = tonumber(location)
        local amt = tonumber(amount)
        if not amt or amt <= 0 then return end

        local pricePerUnit = tonumber(FuelPrice) or 10
        local Price = pricePerUnit * amt
        local StationGetAmount = math.floor(Config.StationFuelSalePercentage * Price)
        if StationGetAmount <= 0 then return end

        if reason == "add" then
            MySQL.Async.execute('UPDATE fuel_stations SET balance = balance + ? WHERE location = ?', { StationGetAmount, CENTRAL_STATION })
        elseif reason == "remove" then
            MySQL.Async.execute('UPDATE fuel_stations SET balance = GREATEST(0, balance - ?) WHERE location = ?', { StationGetAmount, CENTRAL_STATION })
        end
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:getDauThoCount', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return cb(0) end
        local count = 0
        if GetResourceState('ox_inventory') == 'started' then
            count = exports.ox_inventory:Search(src, 'count', 'dau_tho') or 0
        else
            local itemData = Player.Functions.GetItemByName('dau_tho')
            count = itemData and itemData.amount or 0
        end
        cb(count)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:buyreserves', function(location, price, amount)
        local location = tonumber(location) or CENTRAL_STATION
        local amount = tonumber(amount) or 1000
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        if not IsOwnerOrEmployee(Player.PlayerData.citizenid, location, src) then
            TriggerClientEvent('QBCore:Notify', src, "Bạn cần có công việc Doanh Nghiệp Cây Xăng mới có quyền nhập xăng!", "error", 7500)
            return
        end

        local ReserveBuyPossible = false
        local OldAmount = 0
        local NewAmount = 0

        -- Kiểm tra trữ lượng từ Kho Xăng Tổng Thành Phố (CENTRAL_STATION)
        local maxCap = Config.MaxFuelReserves or 100000
        local result = MySQL.Sync.fetchAll('SELECT fuel FROM fuel_stations WHERE `location` = ?', { CENTRAL_STATION })
        if result and #result > 0 then
            OldAmount = tonumber(result[1].fuel) or 0
            if OldAmount + amount > maxCap then
                ReserveBuyPossible = false
                TriggerClientEvent('QBCore:Notify', src, "Kho xăng tổng thành phố đã đầy (Tối đa " .. maxCap .. "L)!", 'error')
            else
                ReserveBuyPossible = true
                NewAmount = OldAmount + amount
            end
        else
            ReserveBuyPossible = true
            OldAmount = 0
            NewAmount = amount
        end

        local requiredItem = 'dau_tho'
        local amt = tonumber(amount) or 1000
        local fuelPerItem = Config.FuelPerDauTho or 100
        local requiredCount = math.ceil(amt / fuelPerItem)

        local itemCount = 0
        if GetResourceState('ox_inventory') == 'started' then
            itemCount = exports.ox_inventory:Search(src, 'count', requiredItem) or 0
        else
            local itemData = Player.Functions.GetItemByName(requiredItem)
            itemCount = itemData and itemData.amount or 0
        end

        if ReserveBuyPossible then
            if itemCount >= requiredCount then
                local removed = false
                if GetResourceState('ox_inventory') == 'started' then
                    removed = exports.ox_inventory:RemoveItem(src, requiredItem, requiredCount)
                else
                    removed = Player.Functions.RemoveItem(requiredItem, requiredCount)
                end

                if removed then
                    local cid_nxang, name_nxang, _ = GetPlayerInfo(src)
                    if not Config.OwnersPickupFuel then
                        MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE `location` = ?', {NewAmount, CENTRAL_STATION})
                        TriggerClientEvent('QBCore:Notify', src, "Đã nhập thành công " .. amt .. "L vào Kho Tổng Thành Phố (tốn " .. requiredCount .. "x Dầu Thô)!", 'success')
                        if Config.FuelDebug then print("SQL Execute Update: central fuel level to: "..NewAmount.. " Math: ("..amt.." + "..OldAmount.." = "..NewAmount) end

                        -- WEBHOOK: Log nhập xăng trực tiếp
                        SendWebhook(WEBHOOK_NHAP_XANG, "🛢️ Nhập Xăng Vào Kho Tổng (Trực Tiếp)", 0x3498DB, {
                            { "👤 Người Nhập",   name_nxang,          true  },
                            { "🪪 Citizen ID",   cid_nxang,           true  },
                            { "🏪 Kho Tổng #",   tostring(CENTRAL_STATION) .. " (Strawberry Ave Xero)",  true  },
                            { "⛽ Số Lượng",     amt .. "L",          true  },
                            { "📦 Dầu Thô Dùng", requiredCount .. "x",true  },
                            { "📊 Dự Trữ Mới",   NewAmount .. "L",    true  },
                        })
                    else
                        if FuelPickupSent[src] then
                            TriggerClientEvent('QBCore:Notify', src, "Bạn đang có một đơn nhập xăng chưa hoàn tất!", 'error')
                            if GetResourceState('ox_inventory') == 'started' then
                                exports.ox_inventory:AddItem(src, requiredItem, requiredCount)
                            else
                                Player.Functions.AddItem(requiredItem, requiredCount)
                            end
                            return
                        end

                        FuelPickupSent[src] = {
                            ['src'] = src,
                            ['location'] = location,
                            ['amountBought'] = amt,
                            ['requiredItem'] = requiredItem,
                            ['requiredCount'] = requiredCount,
                            ['pickedUp'] = false,
                        }
                        TriggerClientEvent('cdn-fuel:station:client:initiatefuelpickup', src, amt, NewAmount, location)
                        if Config.FuelDebug then print("Initiating a Fuel Pickup for Location: "..location.." with amount of "..amt.." | Triggered By: Source: "..src) end

                        -- WEBHOOK: Log bắt đầu nhiệm vụ nhập xăng
                        SendWebhook(WEBHOOK_NHAP_XANG, "🛢️ Bắt Đầu Nhiệm Vụ Nhập Xăng Kho Tổng", 0x3498DB, {
                            { "👤 Người Nhập",   name_nxang,          true  },
                            { "🪪 Citizen ID",   cid_nxang,           true  },
                            { "🏪 Vị Trí Giao",   tostring(location),  true  },
                            { "⛽ Số Lượng",     amt .. "L",          true  },
                            { "📦 Dầu Thô Dùng", requiredCount .. "x",true  },
                            { "📊 Dự Trữ Mục Tiêu Kho Tổng", tostring(NewAmount) .. "L", true },
                        })
                    end
                else
                    TriggerClientEvent('QBCore:Notify', src, "Lỗi khi trừ vật phẩm Dầu Thô!", 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', src, "Bạn cần có ít nhất " .. requiredCount .. "x Dầu Thô để nhập " .. amt .. "L nhiên liệu!", 'error')
            end
        end
    end)

    RegisterNetEvent('cdn-fuel:station:server:vehiclePickedUp', function(location)
        local src = source
        if FuelPickupSent[src] then
            FuelPickupSent[src]['pickedUp'] = true
            if Config.FuelDebug then print("Vehicle picked up for Source: "..src.." Location: "..tostring(location)) end
        end
    end)

    RegisterNetEvent('cdn-fuel:station:server:fuelpickup:failed', function(location)
        local src = source
        if FuelPickupSent[src] then
            FuelPickupSent[src] = nil
            TriggerClientEvent('QBCore:Notify', src, "Nhiệm vụ nhập xăng đã bị hủy / thất bại!", 'error', 7500)
        end
    end)

    RegisterNetEvent('cdn-fuel:station:server:fuelpickup:finished', function(location)
        local src = source
        local pickupData = FuelPickupSent[src]
        if pickupData then
            local amt = pickupData.amountBought or 0
            local result = MySQL.Sync.fetchAll('SELECT fuel FROM fuel_stations WHERE `location` = ?', {CENTRAL_STATION})
            local currentFuel = (result and result[1] and tonumber(result[1].fuel)) or 0
            local maxFuel = Config.MaxFuelReserves or 100000
            local newFuel = math.min(maxFuel, currentFuel + amt)

            MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE `location` = ?', {newFuel, CENTRAL_STATION})
            TriggerClientEvent('QBCore:Notify', src, "Giao xe thành công! Kho xăng tổng thành phố hiện có: " .. tostring(newFuel) .. "L", 'success')

            if Config.FuelDebug then
                print("User successfully dropped off fuel truck. SQL Execute Update: Central fuel level to: "..newFuel.." | Source: "..src)
            end

            -- WEBHOOK: Log nhập xăng (giao xe thành công)
            local cid_lx, name_lx, _ = GetPlayerInfo(src)
            SendWebhook(WEBHOOK_NHAP_XANG, "🚛 Giao Xe Xăng Kho Tổng Thành Công", 0x3498DB, {
                { "👤 Người Giao",    name_lx,                        true },
                { "🪪 Citizen ID",   cid_lx,                         true },
                { "🏪 Kho Tổng #",   tostring(CENTRAL_STATION) .. " (Strawberry Ave Xero)", true },
                { "⛽ Lít Nhập",     tostring(amt) .. "L",           true },
                { "📊 Dự Trữ Mới",   tostring(newFuel) .. "L",       true },
            })

            FuelPickupSent[src] = nil
        else
            if Config.FuelDebug then
                print("FuelPickupSent[src] is not valid! Source: "..src.." Location: "..tostring(location))
            end
        end
    end)

    AddEventHandler('playerDropped', function()
        local src = source
        if FuelPickupSent[src] then
            FuelPickupSent[src] = nil
        end
    end)

    -- Server backup: xóa xe giao xăng nếu client không xóa được
    RegisterNetEvent('cdn-fuel:station:server:deleteDeliveryVehicles', function(truckNetId, trailerNetId)
        local function SafeDeleteEntity(netId)
            if not netId or netId == 0 then return end
            local ent = NetworkGetEntityFromNetworkId(netId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then
                SetEntityAsMissionEntity(ent, false, true)
                DeleteEntity(ent)
                if Config.FuelDebug then print("[cdn-fuel] Server deleted entity netId: "..netId) end
            end
        end
        Wait(1000) -- đợi client xóa trước, nếu vẫn còn thì server xóa
        SafeDeleteEntity(truckNetId)
        SafeDeleteEntity(trailerNetId)
    end)

    RegisterNetEvent('cdn-fuel:station:server:updatelocationname', function(newName, location)
        local src = source
        if not Config.GasStationNameChanges then
            TriggerClientEvent('QBCore:Notify', src, "Tính năng đổi tên cây xăng đã bị vô hiệu hóa!", 'error', 7500)
            return
        end
        local loc = tonumber(location)
        if loc and stationDataCache[loc] then
            stationDataCache[loc].label = tostring(newName)
        end
        if Config.FuelDebug then print('Attempting to set name for Location #'..location..' to: '..newName) end
        MySQL.Async.execute('UPDATE fuel_stations SET label = ? WHERE `location` = ?', {newName, location})
        if Config.FuelDebug then print('Successfully executed the previous SQL Update!') end
        TriggerClientEvent('QBCore:Notify', src, Lang:t("station_name_change_success")..newName.."!", 'success')
        TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, location, newName)
    end)

    -- Callbacks 
    QBCore.Functions.CreateCallback('cdn-fuel:server:getownedstations', function(source, cb)
        local ownedStations = {}
        for loc, data in pairs(stationDataCache) do
            if data.owned == 1 then
                ownedStations[loc] = true
            end
        end
        cb(ownedStations)
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:locationpurchased', function(source, cb, location)
        local loc = tonumber(location)
        if loc and stationDataCache[loc] then
            cb(stationDataCache[loc].owned == 1)
        else
            cb(false)
        end
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:doesPlayerOwnStation', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then cb(false) return end
        if Player.PlayerData.job and Player.PlayerData.job.name == 'cayxang' then
            cb(true)
            return
        end
        cb(false)
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:isowner', function(source, cb, location)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then cb(false) return end
        if Player.PlayerData.job and Player.PlayerData.job.name == 'cayxang' then
            local grade = tonumber(Player.PlayerData.job.grade and (Player.PlayerData.job.grade.level or Player.PlayerData.job.grade)) or 0
            cb(grade >= 2)
            return
        end
        cb(false)
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:fetchinfo', function(source, cb, location)
        local src = source
        local loc = tonumber(location) or 1
        if Config.FuelDebug then print("Fetching Information for Location: "..tostring(location)) end
        MySQL.Async.fetchAll('SELECT * FROM fuel_stations WHERE location IN (?, ?)', {loc, CENTRAL_STATION}, function(result)
            if result and #result > 0 then
                local currentStationData = nil
                local centralStationData = nil
                for _, row in ipairs(result) do
                    if tonumber(row.location) == loc then
                        currentStationData = row
                    end
                    if tonumber(row.location) == CENTRAL_STATION then
                        centralStationData = row
                    end
                end
                if not currentStationData then currentStationData = result[1] end
                if not centralStationData then centralStationData = currentStationData end

                -- Map central warehouse reserves, balance, and price to current station response
                currentStationData.fuel = tonumber(centralStationData.fuel) or (Config.MaxFuelReserves or 100000)
                currentStationData.balance = tonumber(centralStationData.balance) or 0
                currentStationData.fuelprice = tonumber(centralStationData.fuelprice) or (Config.CostMultiplier or 2)
                currentStationData.owned = 1
                currentStationData.owner = "cayxang"

                cb({ currentStationData })
                if Config.FuelDebug then print(json.encode({ currentStationData })) end
            else
                cb(false)
            end
	    end)
	end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:checkshutoff', function(source, cb, location)
        if Config.FuelDebug then print("Fetching Shutoff State for Location: "..location) end
        cb(Config.GasStations[location].shutoff)
	end)
    
    QBCore.Functions.CreateCallback('cdn-fuel:server:fetchlabel', function(source, cb, location)
        if Config.FuelDebug then print("Fetching Shutoff State for Location: "..location) end
        MySQL.Async.fetchAll('SELECT label FROM fuel_stations WHERE location = ?', {location}, function(result)
            if result then
                cb(result)
                if Config.FuelDebug then print(result) end
            else
                cb(false)
            end
	    end)
	end)

    CreateThread(function()
        Wait(1000)
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `fuel_station_employees` (
                `id` INT(11) NOT NULL AUTO_INCREMENT,
                `location` INT(11) NOT NULL,
                `citizenid` VARCHAR(50) NOT NULL,
                `name` VARCHAR(100) DEFAULT '',
                `grade` INT(11) NOT NULL DEFAULT 0,
                PRIMARY KEY (`id`),
                UNIQUE KEY `location_citizenid` (`location`, `citizenid`)
            );
        ]])
        pcall(function()
            MySQL.Async.execute('ALTER TABLE fuel_stations ADD COLUMN IF NOT EXISTS electric INT(11) NOT NULL DEFAULT 10000;')
        end)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:purchaseelectricreserves', function(location, amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local loc = tonumber(location)
        local amt = tonumber(amount)

        if not loc or loc <= 0 or not amt or amt < 1 then
            TriggerClientEvent('QBCore:Notify', src, "Số lượng điện nạp không hợp lệ!", "error", 7500)
            return
        end

        if not IsOwnerOrEmployee(Player.PlayerData.citizenid, loc, src) then
            TriggerClientEvent('QBCore:Notify', src, "Chỉ có Chủ sở hữu hoặc Nhân viên cây xăng mới có quyền nạp điện!", "error", 7500)
            return
        end

        local electricPerItem = Config.ElectricPerPinNangLuong or 100
        local requiredPin = math.ceil(amt / electricPerItem)

        local hasPinCount = 0
        if GetResourceState('ox_inventory') == 'started' then
            hasPinCount = exports.ox_inventory:Search(src, 'count', 'pin_nang_luong') or 0
        else
            local pinItem = Player.Functions.GetItemByName('pin_nang_luong')
            if pinItem then
                hasPinCount = tonumber(pinItem.amount) or 0
            end
        end

        if hasPinCount < requiredPin then
            TriggerClientEvent('QBCore:Notify', src, "Bạn không có đủ " .. requiredPin .. "x Pin Năng Lượng!", "error", 7500)
            return
        end

        MySQL.Async.fetchAll('SELECT electric FROM fuel_stations WHERE location = ?', { loc }, function(result)
            if not result or not result[1] then return end

            local currentElectric = tonumber(result[1].electric) or 10000
            local maxElectric = Config.MaxElectricReserves or 10000

            if currentElectric >= maxElectric then
                TriggerClientEvent('QBCore:Notify', src, "Dự trữ điện của trạm sạc đã đầy (Tối đa " .. maxElectric .. " KW)!", "error", 7500)
                return
            end

            local newElectric = currentElectric + amt
            if newElectric > maxElectric then
                newElectric = maxElectric
            end

            local itemRemoved = false
            if GetResourceState('ox_inventory') == 'started' then
                itemRemoved = exports.ox_inventory:RemoveItem(src, 'pin_nang_luong', requiredPin)
            else
                itemRemoved = Player.Functions.RemoveItem('pin_nang_luong', requiredPin)
            end

            if itemRemoved then
                local itemConfig = QBCore.Shared.Items["pin_nang_luong"]
                if itemConfig then
                    TriggerClientEvent('inventory:client:ItemBox', src, itemConfig, "remove")
                end
                TriggerClientEvent('cdn-fuel:client:startElectricDelivery', src, { location = loc, amount = amt })
            else
                TriggerClientEvent('QBCore:Notify', src, "Không thể trừ vật phẩm Pin Năng Lượng!", "error", 7500)
            end
        end)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:finishElectricDelivery', function(location, amount)
        local src = source
        local loc = tonumber(location)
        local amt = tonumber(amount)
        if not loc or not amt or amt <= 0 then return end

        MySQL.Async.fetchAll('SELECT electric FROM fuel_stations WHERE location = ?', { loc }, function(result)
            if not result or not result[1] then return end
            local currentElectric = tonumber(result[1].electric) or 0
            local maxElectric = Config.MaxElectricReserves or 10000
            local newElectric = currentElectric + amt
            if newElectric > maxElectric then
                newElectric = maxElectric
            end

            MySQL.Async.execute('UPDATE fuel_stations SET electric = ? WHERE location = ?', { newElectric, loc }, function()
                TriggerClientEvent('QBCore:Notify', src, "Đã giao xe và nạp thành công " .. amt .. " KW điện vào kho dự trữ trạm sạc!", "success", 7500)
            end)
        end)
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:getnearbyplayersinfo', function(source, cb, targetServerIds)
        local playersData = {}
        if type(targetServerIds) == "table" then
            for _, targetId in ipairs(targetServerIds) do
                local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
                if TargetPlayer then
                    local charinfo = TargetPlayer.PlayerData.charinfo
                    local name = (charinfo and charinfo.firstname and charinfo.lastname and (charinfo.firstname .. ' ' .. charinfo.lastname)) or GetPlayerName(targetId)
                    table.insert(playersData, {
                        serverId = targetId,
                        source = targetId,
                        name = name .. " (ID: " .. targetId .. ")",
                        citizenid = TargetPlayer.PlayerData.citizenid
                    })
                end
            end
        end
        cb(playersData)
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:checkStationAccess', function(source, cb, location)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not location or location <= 0 then
            cb({ isOwner = false, isManager = false, isEmployee = false, grade = -1 })
            return
        end

        local citizenid = tostring(Player.PlayerData.citizenid)
        local jobName = Player.PlayerData.job and Player.PlayerData.job.name
        local jobGrade = Player.PlayerData.job and Player.PlayerData.job.grade and tonumber(Player.PlayerData.job.grade.level or Player.PlayerData.job.grade) or 0

        if jobName == 'cayxang' then
            local isOwner = (jobGrade >= 2)
            local isManager = (jobGrade >= 1)
            local isEmployee = true
            cb({ isOwner = isOwner, isManager = isManager, isEmployee = isEmployee, grade = jobGrade })
        else
            cb({ isOwner = false, isManager = false, isEmployee = false, grade = -1 })
        end
    end)

    QBCore.Functions.CreateCallback('cdn-fuel:server:getEmployeeList', function(source, cb, location)
        MySQL.Async.fetchAll('SELECT citizenid, name, grade FROM fuel_station_employees', {}, function(result)
            local employees = {}
            if result then
                for _, v in ipairs(result) do
                    local isOnline = false
                    local empGrade = tonumber(v.grade) or 0
                    local empName = v.name
                    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(v.citizenid)
                    if targetPlayer then
                        isOnline = true
                        if targetPlayer.PlayerData and targetPlayer.PlayerData.charinfo then
                            empName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
                        end
                        if targetPlayer.PlayerData and targetPlayer.PlayerData.job and targetPlayer.PlayerData.job.name == 'cayxang' then
                            empGrade = tonumber(targetPlayer.PlayerData.job.grade and (targetPlayer.PlayerData.job.grade.level or targetPlayer.PlayerData.job.grade)) or empGrade
                        end
                    end
                    table.insert(employees, {
                        citizenid = v.citizenid,
                        name = empName,
                        grade = empGrade,
                        gradeLevel = empGrade,
                        isOnline = isOnline
                    })
                end
            end
            cb(employees)
        end)
    end)

    RegisterNetEvent('cdn-fuel:server:hireEmployee', function(targetServerId, gradeLevel, location)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local TargetPlayer = QBCore.Functions.GetPlayer(targetServerId)

        if not Player or not TargetPlayer then return end

        local jobName  = Player.PlayerData.job and Player.PlayerData.job.name
        local jobGrade = Player.PlayerData.job and Player.PlayerData.job.grade and tonumber(Player.PlayerData.job.grade.level or Player.PlayerData.job.grade) or 0

        -- Chỉ từ chức vụ Phó Giám Đốc (job cayxang >= 2) trở lên mới có quyền tuyển dụng nhân sự
        if jobName ~= 'cayxang' or jobGrade < 2 then
            TriggerClientEvent('QBCore:Notify', src, "Chỉ Phó Giám Đốc trở lên (Cấp >= 2) mới có quyền tuyển dụng nhân sự!", "error")
            return
        end

        local targetCitizenId = TargetPlayer.PlayerData.citizenid
        local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
        local targetGrade = tonumber(gradeLevel) or 0

        -- Không cho tuyển chức vụ cao hơn hoặc bằng người tuyển
        if targetGrade >= jobGrade then
            targetGrade = math.max(0, jobGrade - 1)
        end

        MySQL.Async.execute('INSERT INTO fuel_station_employees (location, citizenid, name, grade) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade), location = VALUES(location)',
        { CENTRAL_STATION, targetCitizenId, targetName, targetGrade }, function()
            invalidateStationCache(targetCitizenId, CENTRAL_STATION)
            if GetResourceState('qbx_core') == 'started' and exports.qbx_core and exports.qbx_core.SetJob then
                exports.qbx_core:SetJob(targetCitizenId, 'cayxang', targetGrade)
            elseif TargetPlayer.Functions and TargetPlayer.Functions.SetJob then
                TargetPlayer.Functions.SetJob('cayxang', targetGrade)
            end
            local gradeLabel = (targetGrade >= 2 and "Phó Giám Đốc") or (targetGrade == 1 and "Quản Lý") or "Nhân Viên"
            TriggerClientEvent('QBCore:Notify', src, "Đã tuyển " .. targetName .. " làm " .. gradeLabel .. " (Cấp " .. targetGrade .. ") cho Doanh Nghiệp Cây Xăng!", "success")
            TriggerClientEvent('QBCore:Notify', targetServerId, "Bạn đã được nhận làm " .. gradeLabel .. " (Cấp " .. targetGrade .. ") của Doanh Nghiệp Cây Xăng!", "success")
        end)
    end)

    local function FireEmployeeInternal(src, targetCitizenId, location)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not targetCitizenId then return end

        local jobName  = Player.PlayerData.job and Player.PlayerData.job.name
        local jobGrade = Player.PlayerData.job and Player.PlayerData.job.grade and tonumber(Player.PlayerData.job.grade.level or Player.PlayerData.job.grade) or 0

        -- Chỉ từ chức vụ Phó Giám Đốc (job cayxang >= 2) trở lên mới có quyền sa thải nhân sự
        if jobName ~= 'cayxang' or jobGrade < 2 then
            TriggerClientEvent('QBCore:Notify', src, "Chỉ Phó Giám Đốc trở lên (Cấp >= 2) mới có quyền sa thải nhân sự!", "error")
            return
        end

        MySQL.Async.execute('DELETE FROM fuel_station_employees WHERE citizenid = ?', { targetCitizenId }, function(rowsChanged)
            invalidateStationCache(targetCitizenId, CENTRAL_STATION)
            if GetResourceState('qbx_core') == 'started' and exports.qbx_core then
                pcall(function() exports.qbx_core:RemovePlayerFromJob(targetCitizenId, 'cayxang') end)
                pcall(function() exports.qbx_core:SetJob(targetCitizenId, 'unemployed', 0) end)
            end

            local TargetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCitizenId)
            if TargetPlayer then
                if not (GetResourceState('qbx_core') == 'started') and TargetPlayer.Functions and TargetPlayer.Functions.SetJob then
                    TargetPlayer.Functions.SetJob('unemployed', 0)
                end
                TriggerClientEvent('QBCore:Notify', TargetPlayer.PlayerData.source, "Bạn đã bị sa thải khỏi Doanh Nghiệp Cây Xăng!", "error")
            else
                if not (GetResourceState('qbx_core') == 'started') then
                    local defaultJob = json.encode({
                        name = "unemployed", label = "Unemployed", payment = 10, type = "none",
                        grade = { name = "Freelancer", level = 0 }, onduty = true
                    })
                    MySQL.Async.execute("UPDATE players SET job = ? WHERE citizenid = ?", { defaultJob, targetCitizenId })
                end
            end
            TriggerClientEvent('QBCore:Notify', src, "Đã sa thải nhân viên khỏi Doanh Nghiệp Cây Xăng!", "success")
        end)
    end

    local function SetEmployeeGradeInternal(src, targetCitizenId, newGrade, location)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not targetCitizenId then return end

        local jobName  = Player.PlayerData.job and Player.PlayerData.job.name
        local jobGrade = Player.PlayerData.job and Player.PlayerData.job.grade and tonumber(Player.PlayerData.job.grade.level or Player.PlayerData.job.grade) or 0

        -- Chỉ từ chức vụ Phó Giám Đốc (job cayxang >= 2) trở lên mới có quyền thay đổi chức vụ
        if jobName ~= 'cayxang' or jobGrade < 2 then
            TriggerClientEvent('QBCore:Notify', src, "Chỉ Phó Giám Đốc trở lên (Cấp >= 2) mới có quyền thay đổi chức vụ nhân sự!", "error")
            return
        end

        local targetGrade = tonumber(newGrade) or 0
        if targetGrade >= jobGrade then
            targetGrade = math.max(0, jobGrade - 1)
        end

        MySQL.Async.execute('UPDATE fuel_station_employees SET grade = ? WHERE citizenid = ?', { targetGrade, targetCitizenId }, function(rowsChanged)
            invalidateStationCache(targetCitizenId, CENTRAL_STATION)
            local gradeLabel = (targetGrade >= 2 and "Phó Giám Đốc") or (targetGrade == 1 and "Quản Lý") or "Nhân Viên"

            if GetResourceState('qbx_core') == 'started' and exports.qbx_core then
                pcall(function() exports.qbx_core:SetJob(targetCitizenId, 'cayxang', targetGrade) end)
            end

            local TargetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCitizenId)
            if TargetPlayer then
                if not (GetResourceState('qbx_core') == 'started') and TargetPlayer.Functions and TargetPlayer.Functions.SetJob then
                    TargetPlayer.Functions.SetJob('cayxang', targetGrade)
                end
                TriggerClientEvent('QBCore:Notify', TargetPlayer.PlayerData.source, "Chức vụ của bạn tại Doanh Nghiệp Cây Xăng đã thay đổi thành " .. gradeLabel .. " (Cấp " .. targetGrade .. ")!", "success")
            else
                if not (GetResourceState('qbx_core') == 'started') then
                    MySQL.Async.fetchAll("SELECT job FROM players WHERE citizenid = ?", { targetCitizenId }, function(res)
                        if res and res[1] then
                            local jobData = json.decode(res[1].job) or {}
                            jobData.name  = "cayxang"
                            jobData.label = "Cây Xăng"
                            jobData.grade = { name = gradeLabel, level = targetGrade }
                            MySQL.Async.execute("UPDATE players SET job = ? WHERE citizenid = ?", { json.encode(jobData), targetCitizenId })
                        end
                    end)
                end
            end
            TriggerClientEvent('QBCore:Notify', src, "Đã cập nhật chức vụ nhân viên thành " .. gradeLabel .. " (Cấp " .. targetGrade .. ")!", "success")
        end)
    end

    RegisterNetEvent('cdn-fuel:server:fireEmployee', function(targetCitizenId, location)
        FireEmployeeInternal(source, targetCitizenId, location)
    end)

    RegisterNetEvent('cdn-fuel:server:fireEmployeeByCitizenId', function(targetCitizenId, location)
        FireEmployeeInternal(source, targetCitizenId, location)
    end)

    RegisterNetEvent('cdn-fuel:server:setEmployeeGrade', function(targetCitizenId, newGrade, location)
        SetEmployeeGradeInternal(source, targetCitizenId, newGrade, location)
    end)

    RegisterNetEvent('cdn-fuel:server:setEmployeeGradeByCitizenId', function(targetCitizenId, newGrade, location)
        SetEmployeeGradeInternal(source, targetCitizenId, newGrade, location)
    end)

    RegisterNetEvent('cdn-fuel:server:toggleDuty', function()
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local currentDuty = Player.PlayerData.job and Player.PlayerData.job.onduty
        local newDuty = not currentDuty

        if GetResourceState('qbx_core') == 'started' and exports.qbx_core and exports.qbx_core.SetJobDuty then
            exports.qbx_core:SetJobDuty(src, newDuty)
        elseif Player.Functions and Player.Functions.SetJobDuty then
            Player.Functions.SetJobDuty(newDuty)
        else
            Player.PlayerData.job.onduty = newDuty
            Player.Functions.SetPlayerData('job', Player.PlayerData.job)
        end

        local statusMsg = newDuty and "Bạn đã BẬT Ca Làm (On Duty)!" or "Bạn đã TẮT Ca Làm (Off Duty)!"
        local statusType = newDuty and "success" or "error"
        TriggerClientEvent('QBCore:Notify', src, statusMsg, statusType)
    end)

    RegisterNetEvent('cdn-fuel:stations:server:buyjerrycanfromreserves', function(location, amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        local loc = tonumber(location) or CENTRAL_STATION
        local amt = tonumber(amount)
        if not amt or amt < 25 or amt > 100 then
            TriggerClientEvent('QBCore:Notify', src, "Lượng xăng mỗi can phải từ 25L đến 100L!", "error", 7500)
            return
        end

        if not Player.PlayerData.job or Player.PlayerData.job.name ~= 'cayxang' then
            TriggerClientEvent('QBCore:Notify', src, "Bạn không có quyền thực hiện thao tác này!", "error", 7500)
            return
        end

        MySQL.Async.fetchAll('SELECT * FROM fuel_stations WHERE location = ?', {CENTRAL_STATION}, function(result)
            if not result or not result[1] then return end
            local stationData = result[1]
            local currentReserves = tonumber(stationData.fuel) or 0

            if currentReserves < amt then
                TriggerClientEvent('QBCore:Notify', src, "Dự trữ nhiên liệu tại Tổng Kho không đủ! (Hiện có: " .. currentReserves .. "L)", "error", 7500)
                return
            end

            local newReserves = currentReserves - amt
            MySQL.Async.execute('UPDATE fuel_stations SET fuel = ? WHERE location = ?', {newReserves, CENTRAL_STATION})
            if stationDataCache[CENTRAL_STATION] then
                stationDataCache[CENTRAL_STATION].fuel = newReserves
            end

            local itemInfo = { cdn_fuel = tostring(amt), gasamount = amt, fuel = amt }
            local itemAdded = false
            if GetResourceState('ox_inventory') == 'started' then
                itemAdded = exports.ox_inventory:AddItem(src, 'can_xang', 1, itemInfo)
                if not itemAdded then
                    itemAdded = exports.ox_inventory:AddItem(src, 'jerrycan', 1, itemInfo)
                end
            else
                itemAdded = Player.Functions.AddItem('can_xang', 1, false, itemInfo)
                if not itemAdded then
                    itemAdded = Player.Functions.AddItem('jerrycan', 1, false, itemInfo)
                end
            end

            local itemConfig = QBCore.Shared.Items["can_xang"] or QBCore.Shared.Items["jerrycan"]
            if itemConfig then
                TriggerClientEvent('inventory:client:ItemBox', src, itemConfig, "add")
            end
            TriggerClientEvent('QBCore:Notify', src, "Đã chiết thành công Can Xăng " .. amt .. "L từ Tổng Kho thành phố!", "success", 7500)
        end)
    end)

    RegisterNetEvent('cdn-fuel:server:sellJerryCanToPlayer', function(targetServerId, fuelAmount, location)
        local src = source
        local Seller = QBCore.Functions.GetPlayer(src)
        local Buyer = QBCore.Functions.GetPlayer(tonumber(targetServerId))

        if not Seller or not Buyer then return end

        if not Seller.PlayerData.job or Seller.PlayerData.job.name ~= 'cayxang' then
            TriggerClientEvent('QBCore:Notify', src, "Bạn không có chức vụ nhân viên cây xăng!", "error", 7500)
            return
        end

        local amount = tonumber(fuelAmount)
        local loc = tonumber(location) or CENTRAL_STATION

        if not amount or amount < 1 or amount > (Config.JerryCanCap or 100) then
            TriggerClientEvent('QBCore:Notify', src, "Lượng xăng phải từ 1L đến " .. (Config.JerryCanCap or 100) .. "L!", "error", 7500)
            return
        end

        local pricePerLiter = Config.JerryCanPricePerLiter or 25
        local cost = math.floor(amount * pricePerLiter)

        local buyerCash = Buyer.PlayerData.money['cash'] or 0
        local buyerBank = Buyer.PlayerData.money['bank'] or 0

        if buyerCash < cost and buyerBank < cost then
            TriggerClientEvent('QBCore:Notify', src, "Người mua không có đủ tiền ($" .. cost .. ")!", "error", 7500)
            TriggerClientEvent('QBCore:Notify', Buyer.PlayerData.source, "Bạn không đủ tiền để mua Can Xăng ($" .. cost .. ")!", "error", 7500)
            return
        end

        if Config.PlayerOwnedGasStationsEnabled then
            local p = promise.new()
            MySQL.Async.fetchAll('SELECT fuel FROM fuel_stations WHERE location = ?', { CENTRAL_STATION }, function(r) p:resolve(r) end)
            local stationRes = Citizen.Await(p)
            if stationRes and #stationRes > 0 then
                local currentFuel = tonumber(stationRes[1].fuel) or 0
                if currentFuel < amount then
                    TriggerClientEvent('QBCore:Notify', src, "Dự trữ nhiên liệu tại Tổng Kho không đủ! (Hiện có: " .. currentFuel .. "L)", "error", 7500)
                    return
                end
            end
        end

        local sellerName = Seller.PlayerData.charinfo.firstname .. ' ' .. Seller.PlayerData.charinfo.lastname
        local buyerName = Buyer.PlayerData.charinfo.firstname .. ' ' .. Buyer.PlayerData.charinfo.lastname

        TriggerClientEvent('QBCore:Notify', src, "Đã gửi đề nghị bán Can Xăng (" .. amount .. "L - $" .. cost .. ") đến " .. buyerName .. ", đang chờ xác nhận...", "primary", 7500)
        TriggerClientEvent('cdn-fuel:client:confirmJerryCanPurchase', Buyer.PlayerData.source, src, sellerName, amount, cost, loc)
    end)

    RegisterNetEvent('cdn-fuel:server:confirmSellJerryCan', function(sellerSrc, amount, cost, location)
        local buyerSrc = source
        local Buyer = QBCore.Functions.GetPlayer(buyerSrc)
        local Seller = QBCore.Functions.GetPlayer(tonumber(sellerSrc))

        if not Buyer or not Seller then return end

        local amt = tonumber(amount)
        local price = tonumber(cost)
        local loc = tonumber(location) or CENTRAL_STATION

        if not amt or amt < 1 or not price or price < 1 then return end

        local buyerCash = Buyer.PlayerData.money['cash'] or 0
        local buyerBank = Buyer.PlayerData.money['bank'] or 0
        local payType = nil

        if buyerCash >= price then
            payType = 'cash'
        elseif buyerBank >= price then
            payType = 'bank'
        else
            TriggerClientEvent('QBCore:Notify', buyerSrc, "Bạn không đủ tiền để mua Can Xăng ($" .. price .. ")!", "error", 7500)
            TriggerClientEvent('QBCore:Notify', sellerSrc, "Giao dịch thất bại: Người mua không có đủ tiền!", "error", 7500)
            return
        end

        if Config.PlayerOwnedGasStationsEnabled then
            local p = promise.new()
            MySQL.Async.fetchAll('SELECT fuel, balance FROM fuel_stations WHERE location = ?', { CENTRAL_STATION }, function(r) p:resolve(r) end)
            local stationRes = Citizen.Await(p)
            if stationRes and #stationRes > 0 then
                local currentFuel    = tonumber(stationRes[1].fuel) or 0
                local currentBalance = tonumber(stationRes[1].balance) or 0

                if currentFuel < amt then
                    TriggerClientEvent('QBCore:Notify', sellerSrc, "Dự trữ nhiên liệu tại Tổng Kho không đủ!", "error", 7500)
                    TriggerClientEvent('QBCore:Notify', buyerSrc, "Giao dịch thất bại: Cây xăng không đủ dự trữ nhiên liệu!", "error", 7500)
                    return
                end

                local newFuel    = currentFuel - amt
                local newBalance = currentBalance + price
                MySQL.Async.execute('UPDATE fuel_stations SET fuel = ?, balance = ? WHERE location = ?', { newFuel, newBalance, CENTRAL_STATION })
                if stationDataCache[CENTRAL_STATION] then
                    stationDataCache[CENTRAL_STATION].fuel = newFuel
                    stationDataCache[CENTRAL_STATION].balance = newBalance
                end
            end
        end

        -- Deduct money from buyer
        Buyer.Functions.RemoveMoney(payType, price, "Mua Can Xăng từ nhân viên cây xăng")

        -- Give Jerry Can item to buyer
        local itemInfo = { cdn_fuel = tostring(amt), gasamount = amt, fuel = amt }
        local itemAdded = false
        if GetResourceState('ox_inventory') == 'started' then
            itemAdded = exports.ox_inventory:AddItem(buyerSrc, 'can_xang', 1, itemInfo)
            if not itemAdded then
                itemAdded = exports.ox_inventory:AddItem(buyerSrc, 'jerrycan', 1, itemInfo)
            end
        else
            itemAdded = Buyer.Functions.AddItem('can_xang', 1, false, itemInfo)
            if not itemAdded then
                itemAdded = Buyer.Functions.AddItem('jerrycan', 1, false, itemInfo)
            end
        end

        local itemConfig = QBCore.Shared.Items["can_xang"] or QBCore.Shared.Items["jerrycan"]
        if itemConfig then
            TriggerClientEvent('inventory:client:ItemBox', buyerSrc, itemConfig, "add")
        end

        local sellerName = Seller.PlayerData.charinfo.firstname .. ' ' .. Seller.PlayerData.charinfo.lastname
        local buyerName = Buyer.PlayerData.charinfo.firstname .. ' ' .. Buyer.PlayerData.charinfo.lastname

        if itemAdded then
            TriggerClientEvent('QBCore:Notify', sellerSrc, "Người chơi " .. buyerName .. " đã xác nhận mua Can Xăng (" .. amt .. "L - $" .. price .. ")! Tiền đã nạp vào quỹ cây xăng.", "success", 7500)
            TriggerClientEvent('QBCore:Notify', buyerSrc, "Bạn đã mua thành công Can Xăng (" .. amt .. "L) từ nhân viên " .. sellerName .. " với giá $" .. price .. "!", "success", 7500)

            -- WEBHOOK: Log nhân viên cây xăng bán can xăng cho player
            local cid_seller, name_seller, _ = GetPlayerInfo(tonumber(sellerSrc))
            local cid_buyer, name_buyer, _   = GetPlayerInfo(buyerSrc)
            SendWebhook(WEBHOOK_BAN_CAN_XANG, "🛢️ Bán Can Xăng Cho Khách", 0xF1C40F, {
                { "👨‍💼 Nhân Viên Bán",  name_seller .. " (ID: " .. tostring(sellerSrc) .. ")", true },
                { "🪪 CitizenID NV",    cid_seller,                                           true },
                { "🏪 Trạm Cây Xăng #", tostring(loc or "N/A"),                               true },
                { "👤 Khách Hàng Mua",  name_buyer .. " (ID: " .. tostring(buyerSrc) .. ")",   true },
                { "🪪 CitizenID Khách", cid_buyer,                                            true },
                { "💳 Thanh Toán",      (payType == 'cash' and "Tiền Mặt" or "Ngân Hàng"),    true },
                { "⛽ Dung Tích Can",   amt .. "L",                                           true },
                { "💵 Tổng Tiền",       "$" .. tostring(price),                               true },
            })
        else
            TriggerClientEvent('QBCore:Notify', sellerSrc, "Giao dịch thất bại: Túi đồ người mua đã đầy!", "error", 7500)
            TriggerClientEvent('QBCore:Notify', buyerSrc, "Túi đồ của bạn đã đầy, không thể nhận Can Xăng!", "error", 7500)
            Buyer.Functions.AddMoney(payType, price, "Hoàn tiền mua Can Xăng")
        end
    end)

    RegisterNetEvent('cdn-fuel:server:rejectSellJerryCan', function(sellerSrc)
        local buyerSrc = source
        local Buyer = QBCore.Functions.GetPlayer(buyerSrc)
        local buyerName = Buyer and (Buyer.PlayerData.charinfo.firstname .. ' ' .. Buyer.PlayerData.charinfo.lastname) or "Người chơi"

        if sellerSrc then
            TriggerClientEvent('QBCore:Notify', tonumber(sellerSrc), buyerName .. " đã từ chối mua Can Xăng!", "error", 7500)
        end
        TriggerClientEvent('QBCore:Notify', buyerSrc, "Bạn đã từ chối mua Can Xăng.", "primary", 7500)
    end)

    -- Fuel Invoice System --
    QBCore.Functions.CreateCallback('cdn-fuel:server:getNearbyPlayerNames', function(source, cb, nearbyIds)
        local names = {}
        if type(nearbyIds) == 'table' then
            for _, sId in ipairs(nearbyIds) do
                local Target = QBCore.Functions.GetPlayer(tonumber(sId))
                if Target and Target.PlayerData and Target.PlayerData.charinfo then
                    local char = Target.PlayerData.charinfo
                    names[sId] = (char.firstname or "") .. " " .. (char.lastname or "")
                else
                    names[sId] = "Khách Hàng (" .. sId .. ")"
                end
            end
        end
        cb(names)
    end)

    RegisterNetEvent('cdn-fuel:server:createFuelInvoice', function(location, fuelAmount, totalCost, plate)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        if not Player.PlayerData.job or Player.PlayerData.job.name ~= 'cayxang' then return end
        local onDuty = Player.PlayerData.job.onduty
        if not (onDuty == true or onDuty == 1 or onDuty == 'true') then return end

        local loc = tonumber(location) or 1
        local stationName = (Config.GasStations[loc] and Config.GasStations[loc].label) or ("Cây Xăng #" .. loc)
        local vehiclePlate = (plate and plate ~= '' and tostring(plate)) or "N/A"
        local charInfo = Player.PlayerData.charinfo
        local senderName = (charInfo and charInfo.firstname and charInfo.lastname) and (charInfo.firstname .. " " .. charInfo.lastname) or Player.PlayerData.name

        local invoiceData = {
            station_id = loc,
            station_name = stationName,
            plate = vehiclePlate,
            fuel_amount = math.floor(tonumber(fuelAmount) or 0),
            total_cost = math.floor(tonumber(totalCost) or 0),
            sender_name = senderName,
            description = string.format("Trạm: %s | Biển số: %s | Xăng: %dL | Giá: $%d", stationName, vehiclePlate, math.floor(fuelAmount or 0), math.floor(totalCost or 0))
        }

        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:AddItem(src, 'hoadonxangdau', 1, invoiceData)
        else
            Player.Functions.AddItem('hoadonxangdau', 1, false, invoiceData)
        end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['hoadonxangdau'] or {name = 'hoadonxangdau', label = 'Hóa đơn Xăng dầu'}, "add")
        TriggerClientEvent('QBCore:Notify', src, "Đã tạo Hóa Đơn Xăng Dầu thành công!", "success", 7500)
    end)

    QBCore.Functions.CreateUseableItem('hoadonxangdau', function(source, item)
        TriggerClientEvent('cdn-fuel:client:useFuelInvoice', source, item)
    end)

    RegisterNetEvent('cdn-fuel:server:sendInvoiceToPlayer', function(targetServerId, invoiceData)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local Target = QBCore.Functions.GetPlayer(targetServerId)
        if not Player or not Target then
            TriggerClientEvent('QBCore:Notify', src, "Người chơi không tồn tại hoặc đã rời server!", "error", 7500)
            return
        end

        local charInfo = Player.PlayerData.charinfo
        local senderName = (charInfo and charInfo.firstname and charInfo.lastname) and (charInfo.firstname .. " " .. charInfo.lastname) or Player.PlayerData.name

        TriggerClientEvent('QBCore:Notify', src, "Đã gửi hóa đơn cho [" .. targetServerId .. "] " .. Target.PlayerData.charinfo.firstname .. " " .. Target.PlayerData.charinfo.lastname .. "!", "primary", 7500)
        TriggerClientEvent('cdn-fuel:client:receiveFuelInvoice', targetServerId, src, senderName, invoiceData)
    end)

    RegisterNetEvent('cdn-fuel:server:rejectInvoice', function(senderSrc)
        TriggerClientEvent('QBCore:Notify', senderSrc, "Người chơi đã từ chối thanh toán hóa đơn!", "error", 7500)
    end)

    RegisterNetEvent('cdn-fuel:server:payInvoice', function(senderSrc, invoiceData)
        local targetSrc = source
        local TargetPlayer = QBCore.Functions.GetPlayer(targetSrc)
        local SenderPlayer = QBCore.Functions.GetPlayer(senderSrc)

        if not TargetPlayer then return end
        if not SenderPlayer then
            TriggerClientEvent('QBCore:Notify', targetSrc, "Nhân viên phát hóa đơn không còn online!", "error", 7500)
            return
        end

        local cost = tonumber(invoiceData.total_cost) or 0
        if cost <= 0 then return end

        local targetCash = TargetPlayer.PlayerData.money['cash'] or 0
        local targetBank = TargetPlayer.PlayerData.money['bank'] or 0

        local paidMoneyType = nil
        if targetCash >= cost then
            paidMoneyType = 'cash'
        elseif targetBank >= cost then
            paidMoneyType = 'bank'
        end

        if not paidMoneyType then
            TriggerClientEvent('QBCore:Notify', targetSrc, "Bạn không đủ tiền để thanh toán hóa đơn này! ($" .. cost .. ")", "error", 7500)
            TriggerClientEvent('QBCore:Notify', senderSrc, "Người chơi không đủ tiền để thanh toán hóa đơn!", "error", 7500)
            return
        end

        TargetPlayer.Functions.RemoveMoney(paidMoneyType, cost, "pay-fuel-invoice")
        SenderPlayer.Functions.AddMoney('cash', cost, "received-fuel-invoice")

        if GetResourceState('ox_inventory') == 'started' then
            if invoiceData.slot then
                exports.ox_inventory:RemoveItem(senderSrc, 'hoadonxangdau', 1, nil, invoiceData.slot)
            else
                exports.ox_inventory:RemoveItem(senderSrc, 'hoadonxangdau', 1)
            end
        else
            SenderPlayer.Functions.RemoveItem('hoadonxangdau', 1, invoiceData.slot)
        end

        TriggerClientEvent('QBCore:Notify', targetSrc, "Bạn đã thanh toán thành công $" .. cost .. " cho hóa đơn xăng dầu!", "success", 7500)
        TriggerClientEvent('QBCore:Notify', senderSrc, "Khách hàng đã thanh toán thành công $" .. cost .. "! Bạn đã nhận được tiền mặt.", "success", 7500)

        -- WEBHOOK: Log thanh toán hóa đơn bán xăng
        local cid_sender, name_sender, _ = GetPlayerInfo(senderSrc)
        local cid_target, name_target, _ = GetPlayerInfo(targetSrc)
        SendWebhook(WEBHOOK_BAN_XANG, "🧾 Bán Xăng (Thanh Toán Hóa Đơn)", 0x2ECC71, {
            { "👨‍💼 Nhân Viên Bán",   name_sender .. " (ID: " .. tostring(senderSrc) .. ")", true },
            { "🪪 CitizenID NV",     cid_sender,                                            true },
            { "👤 Khách Hàng",       name_target .. " (ID: " .. tostring(targetSrc) .. ")", true },
            { "🪪 CitizenID Khách",  cid_target,                                            true },
            { "🏪 Cây Xăng",         tostring(invoiceData.station_name or invoiceData.station_id or "N/A"), true },
            { "🚘 Biển Số Xe",       tostring(invoiceData.plate or "N/A"),                  true },
            { "⛽ Lượng Xăng",       tostring(invoiceData.fuel_amount or 0) .. "L",         true },
            { "💵 Số Tiền",          "$" .. tostring(cost),                                 true },
            { "💳 Hình Thức",        (paidMoneyType == 'cash' and "Tiền Mặt" or "Ngân Hàng"), true },
        })
    end)

    -- Startup Process
    local function Startup()
        if Config.FuelDebug then print("Startup process...") end
        -- Tối ưu: 1 query batch thay vì N queries riêng biệt cho từng trạm
        MySQL.Async.fetchAll('SELECT location, label FROM fuel_stations', {}, function(result)
            if result then
                for _, v in pairs(result) do
                    if v.label then
                        TriggerClientEvent('cdn-fuel:client:updatestationlabels', -1, v.location, v.label)
                    end
                end
            end
        end)
    end

    AddEventHandler('onResourceStart', function(resource)
        if resource == GetCurrentResourceName() then
            Startup()
        end
    end)

end -- For Config.PlayerOwnedGasStationsEnabled check, don't remove!\