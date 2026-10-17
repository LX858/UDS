-- ============================================================
-- XN EMS BANDAGE - SERVER
-- Logic giao dịch băng gạc giữa bác sĩ và người chơi
-- ============================================================

-- Lưu giao dịch đang chờ: key = targetPlayerId (người mua)
local pendingTransactions = {}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Lấy số lượng item bất kỳ trong kho boss_ems
local function GetBossStashItemCount(itemName)
    local items = exports.ox_inventory:GetInventoryItems(Config.BossStashId, false)
    if not items then
        Config.DebugPrint('GetInventoryItems returned nil for stash:', Config.BossStashId)
        return 0
    end

    local count = 0
    for _, item in pairs(items) do
        if item and item.name == itemName then
            count = count + item.count
        end
    end

    Config.DebugPrint('Boss stash item count [' .. tostring(itemName) .. ']:', count)
    return count
end

-- Lấy số lượng băng gạc trong kho boss_ems
local function GetBossStashBandageCount()
    return GetBossStashItemCount(Config.BandageItem)
end

-- Xác minh bác sĩ đang onduty
local function IsPlayerEmsOnDuty(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return false end
    local job = player.PlayerData.job
    return job and job.name == Config.EmsJob and job.onduty == true
end

-- Lấy cấp bậc (level) của player
local function GetPlayerJobGradeLevel(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return 0 end
    local grade = player.PlayerData.job and player.PlayerData.job.grade
    if type(grade) == 'table' then
        return grade.level or 0
    elseif type(grade) == 'number' then
        return grade
    end
    return 0
end

-- Lấy tên + cấp bậc của bác sĩ
local function GetDoctorInfo(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return 'Bác sĩ', 'Không rõ' end

    local charinfo = player.PlayerData.charinfo
    local fullName = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')

    local grade = player.PlayerData.job.grade
    local gradeLabel = (grade and grade.name) or 'Nhân viên'

    return fullName, gradeLabel
end

-- ============================================================
-- DISCORD LOGGING
-- ============================================================
local function SendDiscordLog(doctor, buyer, qty, total, stashRevenue, doctorRevenue)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' then return end

    local doctorName, doctorGrade = GetDoctorInfo(doctor.PlayerData.source)
    local doctorCitizenId = doctor.PlayerData.citizenid or 'N/A'
    local doctorId = doctor.PlayerData.source

    local buyerCharInfo = buyer.PlayerData.charinfo
    local buyerName = (buyerCharInfo.firstname or '') .. ' ' .. (buyerCharInfo.lastname or '')
    local buyerCitizenId = buyer.PlayerData.citizenid or 'N/A'
    local buyerId = buyer.PlayerData.source

    local embed = {
        {
            ["title"] = "🩹 BÁN BĂNG GẠC THÀNH CÔNG",
            ["color"] = 3066993, -- Green color
            ["fields"] = {
                {
                    ["name"] = "👨‍⚕️ Bác Sĩ (Người Bán)",
                    ["value"] = string.format("**Tên:** %s\n**Cấp bậc:** %s\n**CitizenID:** %s\n**ID:** %d", doctorName, doctorGrade, doctorCitizenId, doctorId),
                    ["inline"] = true
                },
                {
                    ["name"] = "👤 Người Mua",
                    ["value"] = string.format("**Tên:** %s\n**CitizenID:** %s\n**ID:** %d", buyerName, buyerCitizenId, buyerId),
                    ["inline"] = true
                },
                {
                    ["name"] = "📦 Chi Tiết Giao Dịch",
                    ["value"] = string.format("**Vật phẩm:** Băng Gạc (Bandage)\n**Số lượng:** x%d\n**Đơn giá:** %s$\n**Tổng cộng:** %s$", qty, lib.math.groupdigits(Config.BandagePrice), lib.math.groupdigits(total)),
                    ["inline"] = false
                },
                {
                    ["name"] = "💰 Phân Chia Doanh Thu",
                    ["value"] = string.format("**Kho y tế bệnh viện (%d%%):** +%s$\n**Bác sĩ (%d%%):** +%s$", math.floor(Config.StashRevenuePct * 100), lib.math.groupdigits(stashRevenue), math.floor(Config.DoctorRevenuePct * 100), lib.math.groupdigits(doctorRevenue)),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "XN EMS Bandage Log • " .. os.date('%d/%m/%Y %H:%M:%S')
            }
        }
    }

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = "EMS Bandage Logger",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

local function SendDiscordCraftLog(doctorSource, bandageQty, bonggonQty)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' then return end

    local doctor = exports.qbx_core:GetPlayer(doctorSource)
    if not doctor then return end

    local doctorName, doctorGrade = GetDoctorInfo(doctorSource)
    local doctorCitizenId = doctor.PlayerData.citizenid or 'N/A'

    local embed = {
        {
            ["title"] = "🏥 CHẾ TẠO BĂNG GẠC THÀNH CÔNG",
            ["color"] = 3447003, -- Blue/cyan
            ["fields"] = {
                {
                    ["name"] = "👨‍⚕️ Bác Sĩ Thực Hiện",
                    ["value"] = string.format("**Tên:** %s\n**Cấp bậc:** %s\n**CitizenID:** %s\n**ID:** %d", doctorName, doctorGrade, doctorCitizenId, doctorSource),
                    ["inline"] = true
                },
                {
                    ["name"] = "📦 Chi Tiết Chế Tạo",
                    ["value"] = string.format("**Vật phẩm tạo ra:** x%d Băng gạc (Bandage)\n**Nguyên liệu tiêu hao:** x%d Bông gòn (Bonggon)\n**Kho lưu trữ:** %s", bandageQty, bonggonQty, Config.BossStashId),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "XN EMS Craft Log • " .. os.date('%d/%m/%Y %H:%M:%S')
            }
        }
    }

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = "EMS Bandage Logger",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- ============================================================
-- CALLBACK: Lấy số lượng băng gạc trong kho boss_ems
-- ============================================================
lib.callback.register('xn_emsbandage:server:getStashBandageCount', function(source)
    -- Chỉ cho phép bác sĩ onduty gọi callback này
    if not IsPlayerEmsOnDuty(source) then
        Config.DebugPrint('Non-EMS or off-duty tried to check stash:', source)
        return nil
    end

    local count = GetBossStashBandageCount()
    return count
end)

-- CALLBACK: Lấy số lượng Bông gòn & Băng gạc trong kho boss_ems
lib.callback.register('xn_emsbandage:server:getStashItemCounts', function(source)
    if not IsPlayerEmsOnDuty(source) or GetPlayerJobGradeLevel(source) < (Config.MinCraftGrade or 6) then
        Config.DebugPrint('Unauthorized or insufficient grade tried to check stash items:', source)
        return nil
    end

    return {
        bonggon = GetBossStashItemCount(Config.BonggonItem),
        bandage = GetBossStashItemCount(Config.BandageItem)
    }
end)


-- ============================================================
-- EVENT: Bác sĩ gửi yêu cầu bán cho target player
-- ============================================================
RegisterNetEvent('xn_emsbandage:server:requestSale', function(targetServerId, quantity, totalPrice)
    local source = source -- bác sĩ

    -- Kiểm tra bác sĩ onduty
    if not IsPlayerEmsOnDuty(source) then
        TriggerClientEvent('xn_emsbandage:client:saleResult', source, false, 'Bạn phải đang trực ca để bán băng gạc!')
        return
    end

    -- Kiểm tra player đích tồn tại
    local targetPlayer = exports.qbx_core:GetPlayer(targetServerId)
    if not targetPlayer then
        TriggerClientEvent('xn_emsbandage:client:saleResult', source, false, 'Người chơi không tồn tại hoặc đã offline!')
        return
    end

    -- Không cho phép bán cho chính mình
    if source == targetServerId then
        TriggerClientEvent('xn_emsbandage:client:saleResult', source, false, 'Không thể bán cho chính mình!')
        return
    end

    -- Kiểm tra số lượng hợp lệ
    if quantity < Config.MinQuantity or quantity > Config.MaxQuantity then
        TriggerClientEvent('xn_emsbandage:client:saleResult', source, false, 'Số lượng không hợp lệ!')
        return
    end

    -- Kiểm tra kho boss_ems có đủ không
    local stockCount = GetBossStashBandageCount()
    if stockCount < quantity then
        TriggerClientEvent('xn_emsbandage:client:saleResult', source, false,
            string.format('Kho y tế không đủ băng gạc! Hiện còn: x%d', stockCount))
        return
    end

    -- Kiểm tra giá hợp lệ (chống spoof từ client)
    local expectedTotal = quantity * Config.BandagePrice
    if totalPrice ~= expectedTotal then
        Config.DebugPrint('Price mismatch! Expected:', expectedTotal, 'Got:', totalPrice)
        totalPrice = expectedTotal -- dùng giá server tính
    end

    -- Lấy thông tin bác sĩ
    local doctorName, doctorGrade = GetDoctorInfo(source)

    Config.DebugPrint('Sale request - Doctor:', doctorName, 'Target:', targetServerId, 'Qty:', quantity, 'Total:', totalPrice)

    -- Lưu giao dịch đang chờ
    pendingTransactions[targetServerId] = {
        doctorId    = source,
        quantity    = quantity,
        totalPrice  = totalPrice,
        timestamp   = os.time(),
    }

    -- Gửi offer đến người mua (client)
    TriggerClientEvent('xn_emsbandage:client:receiveSaleOffer', targetServerId,
        doctorName, doctorGrade, quantity, totalPrice, source)
end)

-- ============================================================
-- EVENT: Người mua xác nhận mua hàng
-- ============================================================
RegisterNetEvent('xn_emsbandage:server:confirmPurchase', function(doctorServerId, quantity, totalPrice)
    local source = source -- người mua

    -- Lấy pending transaction
    local pending = pendingTransactions[source]
    if not pending then
        TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, false, 'Không tìm thấy giao dịch!')
        return
    end

    -- Xác minh doctorId khớp
    if pending.doctorId ~= doctorServerId then
        TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, false, 'Giao dịch không hợp lệ!')
        return
    end

    -- Dùng giá + số lượng lưu trong server (tránh cheat từ client)
    local saleQty    = pending.quantity
    local saleTotal  = pending.totalPrice

    -- Xóa pending transaction ngay để tránh double-submit
    pendingTransactions[source] = nil

    -- Lấy player objects
    local buyer  = exports.qbx_core:GetPlayer(source)
    local doctor = exports.qbx_core:GetPlayer(doctorServerId)

    if not buyer then
        if doctor then
            TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, false, 'Người mua đã offline!')
        end
        return
    end

    -- Kiểm tra bác sĩ vẫn onduty
    if not IsPlayerEmsOnDuty(doctorServerId) then
        TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, false, 'Bác sĩ đã off-duty, giao dịch bị hủy!')
        if doctor then
            TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, false, 'Bạn đã off-duty, giao dịch bị hủy!')
        end
        return
    end

    -- Kiểm tra kho boss_ems còn đủ không (có thể ai khác đã lấy trong lúc chờ)
    local stockCount = GetBossStashBandageCount()
    if stockCount < saleQty then
        TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, false,
            string.format('Kho y tế không còn đủ băng gạc! Còn: x%d', stockCount))
        if doctor then
            TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, false,
                string.format('Kho y tế không đủ hàng! Còn: x%d', stockCount))
        end
        return
    end

    -- Kiểm tra tiền mặt của người mua
    local buyerCash = buyer.PlayerData.money.cash or 0
    if buyerCash < saleTotal then
        TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, false,
            string.format('Bạn không đủ tiền! Cần: %s$ | Có: %s$',
                lib.math.groupdigits(saleTotal), lib.math.groupdigits(buyerCash)))
        if doctor then
            TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, false, 'Người mua không đủ tiền!')
        end
        return
    end

    -- ============================================================
    -- THỰC HIỆN GIAO DỊCH
    -- ============================================================

    -- 1. Trừ tiền mặt của người mua
    buyer.Functions.RemoveMoney('cash', saleTotal, 'xn_emsbandage-buy-bandage')

    -- 2. Xóa băng gạc từ kho boss_ems
    local removed = exports.ox_inventory:RemoveItem(Config.BossStashId, Config.BandageItem, saleQty)
    if not removed then
        -- Hoàn tiền nếu không lấy được item
        buyer.Functions.AddMoney('cash', saleTotal, 'xn_emsbandage-refund')
        TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, false, 'Lỗi khi lấy băng gạc từ kho! Đã hoàn tiền.')
        if doctor then
            TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, false, 'Lỗi khi lấy băng gạc từ kho!')
        end
        return
    end

    -- 3. Thêm băng gạc vào inventory người mua
    local added = exports.ox_inventory:AddItem(source, Config.BandageItem, saleQty)
    if not added then
        -- Hoàn tiền và trả lại item vào kho
        buyer.Functions.AddMoney('cash', saleTotal, 'xn_emsbandage-refund')
        exports.ox_inventory:AddItem(Config.BossStashId, Config.BandageItem, saleQty)
        TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, false, 'Inventory đầy! Không thể nhận băng gạc. Đã hoàn tiền.')
        if doctor then
            TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, false, 'Người mua không thể nhận băng gạc (inventory đầy)!')
        end
        return
    end

    -- 4. Tính phân chia doanh thu
    local stashRevenue  = math.floor(saleTotal * Config.StashRevenuePct)   -- 80% vào kho boss_ems
    local doctorRevenue = math.floor(saleTotal * Config.DoctorRevenuePct)  -- 20% vào túi bác sĩ

    -- 5. Thêm 80% tiền vào kho boss_ems dưới dạng item 'money'
    exports.ox_inventory:AddItem(Config.BossStashId, Config.MoneyItem, stashRevenue)

    -- 6. Thêm 20% tiền vào túi bác sĩ (cash)
    if doctor then
        doctor.Functions.AddMoney('cash', doctorRevenue, 'xn_emsbandage-doctor-commission')
    end

    Config.DebugPrint(string.format(
        'Transaction success: buyer=%s, qty=%d, total=%d, stash=%d, doctor=%d',
        source, saleQty, saleTotal, stashRevenue, doctorRevenue
    ))

    -- ============================================================
    -- LOG DISCORD
    -- ============================================================
    if doctor then
        SendDiscordLog(doctor, buyer, saleQty, saleTotal, stashRevenue, doctorRevenue)
    end

    -- ============================================================
    -- THÔNG BÁO KẾT QUẢ
    -- ============================================================

    -- Thông báo cho người mua
    TriggerClientEvent('xn_emsbandage:client:purchaseResult', source, true,
        string.format('✅ Đã mua x%d băng gạc với giá %s$!', saleQty, lib.math.groupdigits(saleTotal)))

    -- Thông báo cho bác sĩ
    if doctor then
        TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, true,
            string.format('✅ Đã bán x%d băng gạc!\n💰 Hoa hồng: +%s$ | 🏥 Kho: +%s$',
                saleQty,
                lib.math.groupdigits(doctorRevenue),
                lib.math.groupdigits(stashRevenue)))
    end
end)

-- ============================================================
-- EVENT: Người mua từ chối giao dịch
-- ============================================================
RegisterNetEvent('xn_emsbandage:server:declinePurchase', function(doctorServerId)
    local source = source -- người mua

    -- Xóa pending transaction
    pendingTransactions[source] = nil

    Config.DebugPrint('Buyer', source, 'declined purchase from doctor', doctorServerId)

    -- Thông báo cho bác sĩ
    local doctor = exports.qbx_core:GetPlayer(doctorServerId)
    if doctor then
        TriggerClientEvent('xn_emsbandage:client:saleResult', doctorServerId, false,
            'Người chơi đã từ chối mua băng gạc!')
    end
end)

-- ============================================================
-- DỌN DẸP pending transaction khi player disconnect
-- ============================================================
AddEventHandler('playerDropped', function()
    local source = source
    -- Xóa pending nếu người mua disconnect
    if pendingTransactions[source] then
        local doctorId = pendingTransactions[source].doctorId
        pendingTransactions[source] = nil

        local doctor = exports.qbx_core:GetPlayer(doctorId)
        if doctor then
            TriggerClientEvent('xn_emsbandage:client:saleResult', doctorId, false,
                'Người mua đã ngắt kết nối, giao dịch bị hủy!')
        end
    end
end)

-- ============================================================
-- CALLBACK: Bác sĩ chế tạo 1 cái băng gạc (chạy theo từng nhịp progress bar)
-- ============================================================
lib.callback.register('xn_emsbandage:server:craftSingleBandage', function(source)
    -- Kiểm tra bác sĩ onduty
    if not IsPlayerEmsOnDuty(source) then
        return false, 'Bạn phải đang trực ca mới có thể chế tạo!'
    end

    -- Kiểm tra cấp bậc bác sĩ
    local minGrade = Config.MinCraftGrade or 6
    if GetPlayerJobGradeLevel(source) < minGrade then
        return false, string.format('Bạn cần đạt cấp %d trở lên mới có thể chế tạo băng gạc!', minGrade)
    end

    -- Kiểm tra khoảng cách tới bàn chế tạo
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local dist = #(playerCoords - Config.CraftLocation)
    if dist > 10.0 then
        return false, 'Bạn ở quá xa vị trí chế tạo!'
    end

    local requiredBonggon = Config.BonggonPerBandage
    local currentBonggon = GetBossStashItemCount(Config.BonggonItem)

    -- Kiểm tra kho có đủ bông gòn không
    if currentBonggon < requiredBonggon then
        return false, string.format('Kho y tế không đủ Bông gòn! Cần x%d, hiện chỉ còn x%d.', requiredBonggon, currentBonggon)
    end

    -- 1. Trừ bông gòn từ kho boss_ems
    local removed = exports.ox_inventory:RemoveItem(Config.BossStashId, Config.BonggonItem, requiredBonggon)
    if not removed then
        return false, 'Lỗi khi lấy Bông gòn từ kho y tế!'
    end

    -- 2. Thêm 1 băng gạc vào kho boss_ems
    local added = exports.ox_inventory:AddItem(Config.BossStashId, Config.BandageItem, 1)
    if not added then
        -- Hoàn lại bông gòn nếu kho đầy
        exports.ox_inventory:AddItem(Config.BossStashId, Config.BonggonItem, requiredBonggon)
        return false, 'Kho y tế đã đầy không thể chứa thêm Băng gạc! Đã hoàn lại Bông gòn.'
    end

    Config.DebugPrint(string.format('Doctor %d crafted 1 bandage using x%d bonggon', source, requiredBonggon))
    return true
end)

-- ============================================================
-- EVENT: Kết thúc phiên chế tạo (ghi log Discord tổng hợp)
-- ============================================================
RegisterNetEvent('xn_emsbandage:server:finishCraftSession', function(totalCrafted)
    local source = source
    totalCrafted = tonumber(totalCrafted)
    if not totalCrafted or totalCrafted <= 0 then return end

    if not IsPlayerEmsOnDuty(source) then return end

    local totalBonggon = totalCrafted * Config.BonggonPerBandage
    SendDiscordCraftLog(source, totalCrafted, totalBonggon)
end)

