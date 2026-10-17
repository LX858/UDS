-- local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1463061980201091246/ZI5bfeVXDtDUrE4dIc4XjHlHrNelDOltvjXN2PNKSaHi3RP5RP1qOzbXgII8G-iaQmsX"
-- local MULTIACC_WEBHOOK = "https://ptb.discord.com/api/webhooks/1464896729873911931/qFD9CvdceNiTvIEJB28XMzM57u6oPZApC30DADoRgXvFUzUKRZcQq_DSGI5ZSTbEw_Kd" -- Webhook riêng cho multi-account detection
-- local FIRSTTIME_WEBHOOK = "https://discord.com/api/webhooks/1465497383147405373/LM7YEB1Vv3uLM3KwkHy1Z3M77LEAXLg6i7ewhCVabeGVNmscPO_VdE5ojkMvBBLhQ3RG" -- Webhook cho First Time Login

-- -- ============ CACHING & RATE LIMITING CONFIG ============
-- local CACHE_DURATION = 300 -- Cache kết quả trong 5 phút (300 giây)
-- local COMMAND_COOLDOWN = 60 -- Cooldown 60 giây giữa mỗi lần chạy command
-- local MAX_QUERY_RESULTS = 1000 -- Giới hạn số kết quả query

-- local multiAccCache = {
--     data = nil,
--     timestamp = 0
-- }
-- local lastCommandRun = 0

-- local function GetPlayerIdentifiers(source)
--     local identifiers = {
--         license2 = nil,
--         discord = nil,
--         ip = nil,
--         steam = nil
--     }
    
--     for i = 0, GetNumPlayerIdentifiers(source) - 1 do
--         local id = GetPlayerIdentifier(source, i)
        
--         if string.find(id, "license2:") then
--             identifiers.license2 = id
--         elseif string.find(id, "discord:") then
--             identifiers.discord = id
--         elseif string.find(id, "ip:") then
--             identifiers.ip = id
--         elseif string.find(id, "steam:") then
--             identifiers.steam = id
--         end
--     end
    
--     return identifiers
-- end

-- local function GetPlayerHardwareIds(source)
--     local hwids = {}
    
--     for i = 0, GetNumPlayerTokens(source) - 1 do
--         local token = GetPlayerToken(source, i)
--         table.insert(hwids, token)
--     end
    
--     return hwids
-- end

-- local function SendToDiscord(title, description, color, fields, webhook)
--     local embed = {
--         {
--             ["title"] = title,
--             ["description"] = description,
--             ["type"] = "rich",
--             ["color"] = color,
--             ["fields"] = fields,
--             ["footer"] = {
--                 ["text"] = os.date("%d/%m/%Y %H:%M:%S"),
--             },
--         }
--     }

--     local webhookUrl = webhook or DISCORD_WEBHOOK
--     PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({
--         username = "Login Logger",
--         embeds = embed
--     }), { ['Content-Type'] = 'application/json' })
-- end

-- -- Function check xem player đã từng login chưa
-- local function CheckFirstTimeLogin(license2, callback)
--     if not license2 or license2 == "N/A" then
--         callback(false)
--         return
--     end
    
--     MySQL.Async.fetchScalar('SELECT COUNT(*) FROM player_hardware WHERE license2 = @license2', {
--         ['@license2'] = license2
--     }, function(count)
--         callback(count == 0)
--     end)
-- end

-- -- Lưu Hardware ID vào Database
-- local function SaveHardwareToDatabase(citizenid, pid, license2, hwid, playerName, characterName, discordId, ipAddress, playerId)
--     if not hwid or hwid == "" then return end
    
--     MySQL.Async.execute([[
--         INSERT INTO player_hardware (citizenid, pid, license2, hardware_id, player_name, character_name, discord_id, ip_address, player_id, first_seen, last_seen)
--         VALUES (@citizenid, @pid, @license2, @hwid, @name, @charname, @discord, @ip, @playerid, NOW(), NOW())
--         ON DUPLICATE KEY UPDATE 
--             citizenid = @citizenid,
--             pid = @pid,
--             player_name = @name,
--             character_name = @charname,
--             discord_id = @discord,
--             ip_address = @ip,
--             player_id = @playerid,
--             last_seen = NOW()
--     ]], {
--         ['@citizenid'] = citizenid,
--         ['@pid'] = pid,
--         ['@license2'] = license2,
--         ['@hwid'] = hwid,
--         ['@name'] = playerName,
--         ['@charname'] = characterName,
--         ['@discord'] = discordId,
--         ['@ip'] = ipAddress,
--         ['@playerid'] = playerId
--     })
-- end

-- -- Forward declaration cho ProcessMultiAccData (dùng trước khi định nghĩa)
-- local ProcessMultiAccData

-- -- Check Multi-Account và gửi Discord (Tối ưu - chỉ 1 query)
-- local function CheckMultiAccounting(forceRefresh)
--     -- Kiểm tra cache (Solution 5: Cache kết quả)
--     local currentTime = os.time()
--     if not forceRefresh and multiAccCache.data and (currentTime - multiAccCache.timestamp) < CACHE_DURATION then
--         print("^2[Hardware Tracker]^0 Sử dụng cache (còn " .. (CACHE_DURATION - (currentTime - multiAccCache.timestamp)) .. "s)")
--         ProcessMultiAccData(multiAccCache.data)
--         return
--     end
    
--     print("^3[Hardware Tracker]^0 Bắt đầu quét multi-accounting...")
    
--     -- Solution 2: Thêm LIMIT cho SQL query
--     -- Fix collation mismatch: players dùng utf8mb4_uca1400_ai_ci, player_hardware dùng utf8mb4_unicode_ci
--     MySQL.Async.fetchAll([[
--         SELECT 
--             ph.hardware_id,
--             ph.citizenid,
--             ph.pid,
--             ph.license2,
--             ph.player_name,
--             ph.character_name,
--             ph.discord_id,
--             ph.ip_address,
--             ph.player_id,
--             DATE_FORMAT(ph.last_seen, '%d/%m/%Y %H:%i') as last_seen_fmt,
--             ph.last_seen,
--             p.money
--         FROM player_hardware ph
--         INNER JOIN (
--             SELECT hardware_id, license2, MAX(last_seen) as max_seen
--             FROM player_hardware
--             WHERE last_seen >= DATE_SUB(NOW(), INTERVAL 10 DAY)
--             GROUP BY hardware_id, license2
--             LIMIT @limit
--         ) latest ON ph.hardware_id = latest.hardware_id 
--                 AND ph.license2 = latest.license2
--                 AND ph.last_seen = latest.max_seen
--         LEFT JOIN players p ON ph.citizenid COLLATE utf8mb4_uca1400_ai_ci = p.citizenid
--         ORDER BY ph.hardware_id, ph.last_seen DESC
--         LIMIT @limit
--     ]], {
--         ['@limit'] = MAX_QUERY_RESULTS
--     }, function(allData)
--         if not allData or #allData == 0 then
--             print("^2[Hardware Tracker]^0 Không có dữ liệu để quét")
--             return
--         end
        
--         -- Lưu cache
--         multiAccCache.data = allData
--         multiAccCache.timestamp = os.time()
--         print("^2[Hardware Tracker]^0 Đã cache " .. #allData .. " records")
        
--         -- Xử lý dữ liệu
--         ProcessMultiAccData(allData)
--     end)
-- end

-- -- Tách riêng function xử lý data để có thể dùng với cache
-- ProcessMultiAccData = function(allData)
--     -- Group theo hardware_id và chỉ lấy UNIQUE LICENSE
--         local cases = {}
--         for _, row in ipairs(allData) do
--             if not cases[row.hardware_id] then
--                 cases[row.hardware_id] = {}
--             end
            
--             -- Kiểm tra xem license2 này đã tồn tại chưa (tránh duplicate)
--             local alreadyExists = false
--             for _, existingAcc in ipairs(cases[row.hardware_id]) do
--                 if existingAcc.license2 == row.license2 then
--                     alreadyExists = true
--                     break
--                 end
--             end
            
--             if not alreadyExists then
--                 table.insert(cases[row.hardware_id], row)
--             end
--         end
        
--         -- Lọc chỉ lấy cases có >= 2 UNIQUE LICENSE (multi-account thật)
--         local multiAccCases = {}
--         for hwid, accounts in pairs(cases) do
--             local uniqueLicenses = {}
            
--             -- Đếm unique licenses
--             for _, acc in ipairs(accounts) do
--                 if acc.license2 then
--                     uniqueLicenses[acc.license2] = true
--                 end
--             end
            
--             local licenseCount = 0
--             for _ in pairs(uniqueLicenses) do
--                 licenseCount = licenseCount + 1
--             end
            
--             -- Chỉ báo cáo nếu có >= 2 LICENSES khác nhau (multi-account thật)
--             if licenseCount >= 2 then
--                 table.insert(multiAccCases, {
--                     hardware_id = hwid,
--                     accounts = accounts,
--                     acc_count = licenseCount, -- Đếm số licenses (= số người)
--                     license_count = licenseCount
--                 })
--             end
--         end
        
--         -- Sort theo số lượng licenses KHÁC NHAU (ưu tiên cao), sau đó theo acc_count
--         table.sort(multiAccCases, function(a, b) 
--             if a.license_count == b.license_count then
--                 return a.acc_count > b.acc_count -- Nếu bằng licenses thì so sánh acc_count
--             end
--             return a.license_count > b.license_count
--         end)
        
--         if #multiAccCases == 0 then
--             print("^2[Hardware Tracker]^0 Không phát hiện multi-accounting")
--             return
--         end
        
--         print("^1[Hardware Tracker]^0 Phát hiện " .. #multiAccCases .. " hardware IDs có nhiều accounts!")
        
--         -- Format số tiền (định nghĩa 1 lần, dùng nhiều lần)
--         local function formatMoney(amount)
--             amount = math.floor(tonumber(amount) or 0) -- Làm tròn và bỏ decimal
--             local formatted = tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse()
--             return formatted:gsub("^,", "")
--         end
        
--         -- Gửi Discord theo batch (5 embeds/message để tránh rate limit)
--         local embeds = {}
--         local batchNumber = 0
--         local totalEmbedsCreated = 0 -- Track tổng số embeds đã tạo
        
--         for caseNum, case in ipairs(multiAccCases) do
--             -- Split case thành nhiều parts nếu > 10 accounts
--             local maxAccountsPerEmbed = 10
--             local totalAccounts = #case.accounts
--             local totalParts = math.ceil(totalAccounts / maxAccountsPerEmbed)
            
--             print(string.format("^3[Hardware Tracker]^0 Xử lý Case #%d: %d accounts, chia %d parts", 
--                 caseNum, totalAccounts, totalParts))
            
--             for partNum = 1, totalParts do
--                 local startIdx = (partNum - 1) * maxAccountsPerEmbed + 1
--                 local endIdx = math.min(partNum * maxAccountsPerEmbed, totalAccounts)
                
--                 -- Tạo embed cho part này
--                 local hwid_display = case.hardware_id
--                 if #hwid_display > 32 then
--                     hwid_display = hwid_display:sub(1, 32) .. "..."
--                 end
                
--                 local caseTitle = totalParts > 1 and 
--                     string.format("🚨 Multi-Account Case #%d (Part %d/%d)", caseNum, partNum, totalParts) or
--                     string.format("🚨 Multi-Account Case #%d", caseNum)
                
--                 local description = "**Hardware ID:** ```" .. hwid_display .. "```\n"
--                 description = description .. "**⚠️ Số Accounts:** " .. case.acc_count .. " (" .. case.license_count .. " licenses)\n\n"
                
--                 local fields = {}
--                 for i = startIdx, endIdx do
--                     local acc = case.accounts[i]
                    
--                     -- Parse Discord ID an toàn (chỉ mention nếu là số)
--                     local discordMention = "N/A"
--                     if acc.discord_id and acc.discord_id ~= "" and acc.discord_id ~= "N/A" and tonumber(acc.discord_id) then
--                         discordMention = "<@" .. acc.discord_id .. ">"
--                     elseif acc.discord_id and acc.discord_id ~= "" and acc.discord_id ~= "N/A" then
--                         discordMention = acc.discord_id -- Hiển thị text nếu không phải số
--                     end
                    
--                     -- Parse money từ JSON
--                     local bank = 0
--                     local cash = 0
--                     if acc.money and acc.money ~= "" then
--                         local success, moneyData = pcall(json.decode, acc.money)
--                         if success and moneyData then
--                             bank = moneyData.bank or 0
--                             cash = moneyData.cash or 0
--                         end
--                     end
                    
--                     -- Format license2 an toàn (rút gọn nếu quá dài)
--                     local license_display = acc.license2 or "N/A"
--                     if license_display:find("^license2:") then
--                         license_display = license_display:gsub("^license2:", "")
--                     end
--                     if #license_display > 30 then
--                         license_display = license_display:sub(1, 27) .. "..."
--                     end
                    
--                     -- Format citizenid và pid
--                     local pid_display = acc.pid and tostring(acc.pid) or "N/A"
--                     local citizen_display = acc.citizenid or "N/A"
                    
--                     -- Format player_id an toàn
--                     local player_id_display = acc.player_id or "N/A"
                    
--                     -- Format name (giới hạn 40 ký tự) - Dùng username
--                     local name_display = acc.player_name or "Unknown"
--                     if #name_display > 40 then
--                         name_display = name_display:sub(1, 37) .. "..."
--                     end
                    
--                     table.insert(fields, {
--                         ["name"] = i .. "️⃣ " .. name_display,
--                         ["value"] = string.format(
--                             "**🆔 PID:** %s | **📜** %s\n**💬** %s\n**🌐** %s | **💰** $%s | **💵** $%s\n**🕐** %s",
--                             pid_display,
--                             license_display,
--                             discordMention,
--                             acc.ip_address or "N/A",
--                             formatMoney(bank),
--                             formatMoney(cash),
--                             acc.last_seen_fmt or "N/A"
--                         ),
--                         ["inline"] = false
--                     })
--                 end
                
--                 local color = case.acc_count >= 4 and 15158332 or 16776960 -- Đỏ nếu >= 4 acc, Vàng nếu 2-3
                
--                 table.insert(embeds, {
--                     ["title"] = caseTitle,
--                     ["description"] = description,
--                     ["color"] = color,
--                     ["fields"] = fields,
--                     ["footer"] = {
--                         ["text"] = os.date("%d/%m/%Y %H:%M:%S"),
--                     },
--                 })
                
--                 totalEmbedsCreated = totalEmbedsCreated + 1
--                 print(string.format("^2[Hardware Tracker]^0 Tạo embed #%d (Case #%d Part %d/%d)", 
--                     totalEmbedsCreated, caseNum, partNum, totalParts))
                
--                 -- Gửi khi đủ 5 embeds (giảm từ 10 để tránh rate limit)
--                 if #embeds == 5 then
--                     batchNumber = batchNumber + 1
--                     local dateLabel = os.date("%d/%m/%Y") .. " Batch #" .. batchNumber
                    
--                     -- Log để tracking
--                     print(string.format("^3[Hardware Tracker]^0 ⏳ GỬI BATCH #%d (%d embeds) - Cases từ #%d trở đi...", 
--                         batchNumber, #embeds, caseNum - 4))
                    
--                     PerformHttpRequest(MULTIACC_WEBHOOK, function(err, text, headers) 
--                         if err == 200 or err == 204 then
--                             print(string.format("^2[Hardware Tracker]^0 ✅ Batch #%d gửi thành công!", batchNumber))
--                         else
--                             print(string.format("^1[Hardware Tracker ERROR]^0 ❌ Batch #%d FAILED! Status: %s", batchNumber, tostring(err)))
--                         end
--                     end, 'POST', json.encode({
--                         username = "Hardware Tracker",
--                         content = batchNumber == 1 and "📊 **MULTI-ACCOUNT SCAN REPORT**\n🔍 Tìm thấy **" .. #multiAccCases .. "** hardware IDs có nhiều accounts (Active 10 ngày)\n📅 " .. dateLabel or ("📅 " .. dateLabel),
--                         embeds = embeds
--                     }), { ['Content-Type'] = 'application/json' })
                    
--                     embeds = {} -- Reset embeds cho batch tiếp theo
--                     Wait(6000) -- Chờ 6 giây giữa các batch (tăng từ 5s để an toàn hơn)
--                 end
--             end
--         end
        
--         -- Gửi batch cuối nếu còn embeds chưa gửi
--         if #embeds > 0 then
--             batchNumber = batchNumber + 1
--             local dateLabel = os.date("%d/%m/%Y") .. " Batch #" .. batchNumber
            
--             print(string.format("^3[Hardware Tracker]^0 ⏳ GỬI BATCH CUỐI #%d (%d embeds)", batchNumber, #embeds))
            
--             PerformHttpRequest(MULTIACC_WEBHOOK, function(err, text, headers) 
--                 if err == 200 or err == 204 then
--                     print(string.format("^2[Hardware Tracker]^0 ✅ Batch cuối #%d gửi thành công!", batchNumber))
--                     print(string.format("^2[Hardware Tracker]^0 🎉 HOÀN TẤT: Đã gửi %d embeds trong %d batches", totalEmbedsCreated, batchNumber))
--                 else
--                     print(string.format("^1[Hardware Tracker ERROR]^0 ❌ Batch cuối #%d FAILED! Status: %s", batchNumber, tostring(err)))
--                 end
--             end, 'POST', json.encode({
--                 username = "Hardware Tracker",
--                 content = batchNumber == 1 and "📊 **MULTI-ACCOUNT SCAN REPORT**\n🔍 Tìm thấy **" .. #multiAccCases .. "** hardware IDs có nhiều accounts (Active 10 ngày)\n📅 " .. dateLabel or ("📅 " .. dateLabel .. " (FINAL)"),
--                 embeds = embeds
--             }), { ['Content-Type'] = 'application/json' })
--         else
--             print(string.format("^2[Hardware Tracker]^0 🎉 HOÀN TẤT: Đã gửi %d embeds trong %d batches", totalEmbedsCreated, batchNumber))
--         end
        
--         -- Gửi danh sách tổng hợp (summary list)
--         Wait(3000) -- Chờ 3 giây sau khi gửi xong tất cả embeds
        
--         print("^3[Hardware Tracker]^0 📋 Đang tạo danh sách tổng hợp...")
        
--         local summaryMessages = {}
--         local currentMessage = "📋 **DANH SÁCH TỔNG HỢP MULTI-ACCOUNT**\n"
--         currentMessage = currentMessage .. "🔍 Tổng: **" .. #multiAccCases .. "** cases\n"
--         currentMessage = currentMessage .. "📅 " .. os.date("%d/%m/%Y %H:%M:%S") .. "\n"
--         currentMessage = currentMessage .. "━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        
--         for caseNum, case in ipairs(multiAccCases) do
--             local caseHeader = string.format("**🚨 Multi-Account #%d** (%d accounts)\n", caseNum, case.acc_count)
            
--             -- Check xem thêm case này có vượt limit không (2000 chars)
--             local testMessage = currentMessage .. caseHeader
            
--             -- Thêm accounts cho case này
--             local accountsList = ""
--             for i, acc in ipairs(case.accounts) do
--                 local name = (acc.character_name or "N/A"):sub(1, 30)
--                 local pid = tostring(acc.pid or "N/A")
--                 accountsList = accountsList .. string.format("   %d. %s | PID: %s\n", i, name, pid)
--             end
            
--             testMessage = testMessage .. accountsList .. "\n"
            
--             -- Nếu vượt quá 1900 chars (để buffer), gửi message hiện tại và bắt đầu message mới
--             if #testMessage > 1900 then
--                 table.insert(summaryMessages, currentMessage)
--                 currentMessage = "📋 **DANH SÁCH TỔNG HỢP (tiếp)**\n━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
--                 currentMessage = currentMessage .. caseHeader .. accountsList .. "\n"
--             else
--                 currentMessage = testMessage
--             end
--         end
        
--         -- Thêm message cuối cùng
--         if #currentMessage > 100 then
--             table.insert(summaryMessages, currentMessage)
--         end
        
--         -- Gửi tất cả summary messages
--         print(string.format("^3[Hardware Tracker]^0 📤 Gửi %d summary messages...", #summaryMessages))
        
--         for i, msg in ipairs(summaryMessages) do
--             PerformHttpRequest(MULTIACC_WEBHOOK, function(err, text, headers) 
--                 if err == 200 or err == 204 then
--                     print(string.format("^2[Hardware Tracker]^0 ✅ Summary #%d/%d gửi thành công!", i, #summaryMessages))
--                 else
--                     print(string.format("^1[Hardware Tracker ERROR]^0 ❌ Summary #%d FAILED! Status: %s", i, tostring(err)))
--                 end
--             end, 'POST', json.encode({
--                 username = "Hardware Tracker",
--                 content = msg
--             }), { ['Content-Type'] = 'application/json' })
            
--             -- Chờ 2 giây giữa các summary messages
--             if i < #summaryMessages then
--                 Wait(2000)
--             end
--         end
        
--         print("^2[Hardware Tracker]^0 ✅ Hoàn tất gửi danh sách tổng hợp!")
-- end

-- -- Command check multi-account manual
-- if GetResourceState('qb-core') == 'started' then
--     local QBCore = exports['qb-core']:GetCoreObject()
    
--     QBCore.Commands.Add('checkmultiacc', 'Quét multi-accounting ngay (Admin)', {}, false, function(source, args)
--         local Player = QBCore.Functions.GetPlayer(source)
--         if not Player then return end
        
--         if not QBCore.Functions.HasPermission(source, 'god') and not QBCore.Functions.HasPermission(source, 'admin') then
--             TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền!', 'error')
--             return
--         end
        
--         -- Solution 6: Rate limit command
--         local currentTime = os.time()
--         local timeSinceLastRun = currentTime - lastCommandRun
        
--         if timeSinceLastRun < COMMAND_COOLDOWN then
--             local remainingTime = COMMAND_COOLDOWN - timeSinceLastRun
--             TriggerClientEvent('QBCore:Notify', source, 'Vui lòng chờ ' .. remainingTime .. ' giây!', 'error')
--             print("^1[Hardware Tracker]^0 " .. GetPlayerName(source) .. " bị rate limit (còn " .. remainingTime .. "s)")
--             return
--         end
        
--         lastCommandRun = currentTime
        
--         -- Check nếu có arg "force" thì bỏ qua cache
--         local forceRefresh = args[1] == "force"
        
--         if forceRefresh then
--             TriggerClientEvent('QBCore:Notify', source, 'Force refresh - Đang quét mới...', 'success')
--         else
--             TriggerClientEvent('QBCore:Notify', source, 'Đang quét... Kết quả gửi Discord!', 'success')
--         end
        
--         print("^3[Hardware Tracker]^0 " .. GetPlayerName(source) .. " chạy check manual" .. (forceRefresh and " (FORCE)" or ""))
--         CheckMultiAccounting(forceRefresh)
--     end, 'admin')
-- end

-- -- Biến kiểm tra để tránh đăng ký event nhiều lần
-- local eventsRegistered = false

-- -- Quét khi resource khởi động
-- AddEventHandler('onResourceStart', function(resourceName)
--     if GetCurrentResourceName() == resourceName then
--         -- Chờ 5 giây để database sẵn sàng
--         SetTimeout(5000, function()
--             print("^3[Hardware Tracker]^0 Resource started - Bắt đầu quét multi-accounting...")
--             CheckMultiAccounting()
--         end)
--     end
-- end)

-- -- Lấy citizenid sau khi player loaded
-- if GetResourceState('qb-core') == 'started' and not eventsRegistered then
--     eventsRegistered = true
--     local QBCore = exports['qb-core']:GetCoreObject()
    
--     RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
--         local source = source
--         local Player = QBCore.Functions.GetPlayer(source)
        
--         if Player then
--             local identifiers = GetPlayerIdentifiers(source)
--             local hwids = GetPlayerHardwareIds(source)
--             local playerName = GetPlayerName(source)
            
--             local discordId = identifiers.discord and identifiers.discord:gsub("discord:", "") or "N/A"
--             local license2 = identifiers.license2 or "N/A"
--             local ipv4 = identifiers.ip and identifiers.ip:gsub("ip:", "") or "N/A"
            
--             -- Check xem có phải First Time Login không
--             CheckFirstTimeLogin(license2, function(isFirstTime)
--                 if isFirstTime then
--                     -- GỬI DISCORD FIRST TIME LOGIN
--                     local characterName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
--                     local firstTimeFields = {
--                         {
--                             ["name"] = "👤 Họ và Tên",
--                             ["value"] = characterName,
--                             ["inline"] = true
--                         },
--                         {
--                             ["name"] = "🆔 PID",
--                             ["value"] = tostring(Player.PlayerData.pid),
--                             ["inline"] = true
--                         }
--                     }
                    
--                     SendToDiscord(
--                         "🆕 NEW PLAYER - LOGIN",
--                         "Mod helper hỗ trợ newbie",
--                         3447003, -- Màu xanh dương
--                         firstTimeFields,
--                         FIRSTTIME_WEBHOOK
--                     )
                    
--                     print("^2[Login Logger]^0 First Time Login: " .. playerName .. " (PID: " .. Player.PlayerData.pid .. ")")
--                 end
--             end)
            
--             -- Lưu hardware IDs vào database (chỉ lưu 1 ID chính - tránh duplicate)
--             if #hwids > 0 then
--                 local characterName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
--                 SaveHardwareToDatabase(
--                     Player.PlayerData.citizenid, -- Citizenid QBCore
--                     Player.PlayerData.pid, -- PID
--                     license2,
--                     hwids[1], -- Chỉ lưu cái đầu tiên
--                     playerName,
--                     characterName, -- Họ và tên IC
--                     discordId,
--                     ipv4,
--                     source -- Player ID
--                 )
--             end
            
--             local hwidsText = ""
--             if #hwids > 0 then
--                 for i, hwid in ipairs(hwids) do
--                     hwidsText = hwidsText .. hwid
--                     if i < #hwids then
--                         hwidsText = hwidsText .. "\n"
--                     end
--                 end
--             else
--                 hwidsText = "N/A"
--             end
            
--             local fields = {
--                 {
--                     ["name"] = "👤 Username",
--                     ["value"] = playerName,
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "📜 License2",
--                     ["value"] = "```" .. license2 .. "```",
--                     ["inline"] = false
--                 },
--                 {
--                     ["name"] = "🆔 PID",
--                     ["value"] = tostring(Player.PlayerData.pid),
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "💬 Discord ID",
--                     ["value"] = discordId,
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "🌐 IPv4",
--                     ["value"] = ipv4,
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "🔐 Hardware IDs",
--                     ["value"] = "```" .. hwidsText .. "```",
--                     ["inline"] = false
--                 }
--             }
            
--             SendToDiscord(
--                 "✅ Player Loaded",
--                 "**" .. playerName .. "** đã load xong vào máy chủ",
--                 5763719, -- Màu xanh lá
--                 fields
--             )
--         end
--     end)
    
--     -- Log khi player logout
--     AddEventHandler('playerDropped', function(reason)
--         local source = source
--         local Player = QBCore.Functions.GetPlayer(source)
        
--         if Player then
--             local identifiers = GetPlayerIdentifiers(source)
--             local hwids = GetPlayerHardwareIds(source)
--             local playerName = GetPlayerName(source)
            
--             local discordId = identifiers.discord and identifiers.discord:gsub("discord:", "") or "N/A"
--             local license2 = identifiers.license2 or "N/A"
--             local ipv4 = identifiers.ip and identifiers.ip:gsub("ip:", "") or "N/A"
            
--             local hwidsText = ""
--             if #hwids > 0 then
--                 for i, hwid in ipairs(hwids) do
--                     hwidsText = hwidsText .. hwid
--                     if i < #hwids then
--                         hwidsText = hwidsText .. "\n"
--                     end
--                 end
--             else
--                 hwidsText = "N/A"
--             end
            
--             -- Xác định lý do logout
--             local logoutReason = reason or "Unknown"
            
--             local fields = {
--                 {
--                     ["name"] = "👤 Username",
--                     ["value"] = playerName,
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "📜 License2",
--                     ["value"] = "```" .. license2 .. "```",
--                     ["inline"] = false
--                 },
--                 {
--                     ["name"] = "🆔 PID",
--                     ["value"] = tostring(Player.PlayerData.pid),
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "💬 Discord ID",
--                     ["value"] = discordId,
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "🌐 IPv4",
--                     ["value"] = ipv4,
--                     ["inline"] = true
--                 },
--                 {
--                     ["name"] = "❌ Lý Do Logout",
--                     ["value"] = logoutReason,
--                     ["inline"] = false
--                 },
--                 {
--                     ["name"] = "🔐 Hardware IDs",
--                     ["value"] = "```" .. hwidsText .. "```",
--                     ["inline"] = false
--                 }
--             }
            
--             SendToDiscord(
--                 "🔴 Player Logout",
--                 "**" .. playerName .. "** đã rời khỏi máy chủ",
--                 15158332, -- Màu đỏ
--                 fields
--             )
--         end
--     end)
-- end