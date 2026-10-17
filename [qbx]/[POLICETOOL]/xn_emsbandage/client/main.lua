-- ============================================================
-- XN EMS BANDAGE - CLIENT
-- Tính năng: Bác sĩ (ambulance) onduty target player bán băng gạc
-- ============================================================

-- Lưu giao dịch đang chờ của bác sĩ (để hủy nếu khách từ chối)
local pendingSaleOffer = nil

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Lấy thông tin job của player hiện tại
local function GetPlayerJob()
    local playerData = exports.qbx_core:GetPlayerData()
    if playerData and playerData.job then
        return playerData.job.name, (playerData.job.onduty == true), playerData.job.grade
    end
    return nil, false, nil
end

-- Kiểm tra bác sĩ đang onduty
local function IsEmsOnDuty()
    local jobName, onDuty = GetPlayerJob()
    return jobName == Config.EmsJob and onDuty == true
end


-- ============================================================
-- OX_TARGET - GLOBAL PLAYER TARGET
-- Bác sĩ onduty → target vào player bất kỳ → xuất hiện option bán băng gạc
-- ============================================================

exports.ox_target:addGlobalPlayer({
    {
        name = 'xn_emsbandage_sell',
        icon = 'fas fa-briefcase-medical',
        label = '🩹 Bán băng gạc',
        -- canInteract: chỉ hiển thị khi bác sĩ đang onduty
        canInteract = function(entity, distance, coords, name, bone)
            return IsEmsOnDuty()
        end,
        onSelect = function(data)
            if not IsEmsOnDuty() then
                lib.notify({ title = 'EMS Bandage', description = 'Bạn phải đang trực ca mới có thể bán băng gạc!', type = 'error' })
                return
            end

            -- Lấy server ID của người được target
            local playerIndex = NetworkGetPlayerIndexFromPed(data.entity)
            local targetServerId = GetPlayerServerId(playerIndex)

            if targetServerId == 0 or targetServerId == GetPlayerServerId(PlayerId()) then
                lib.notify({ title = 'EMS Bandage', description = 'Không thể xác định người chơi!', type = 'error' })
                return
            end

            Config.DebugPrint('Target player serverID:', targetServerId)

            -- Lấy số lượng băng gạc trong kho boss_ems
            lib.callback('xn_emsbandage:server:getStashBandageCount', false, function(stockCount)
                if stockCount == nil then
                    lib.notify({ title = 'EMS Bandage', description = 'Lỗi kết nối kho y tế!', type = 'error' })
                    return
                end

                if stockCount <= 0 then
                    lib.notify({ title = 'EMS Bandage', description = 'Kho y tế bệnh viện không còn băng gạc!', type = 'error' })
                    return
                end

                Config.DebugPrint('Stock count:', stockCount)

                -- Giới hạn max bằng số lượng thực có trong kho (tối đa 99)
                local maxSell = math.min(stockCount, Config.MaxQuantity)

                -- Hiển thị dialog nhập số lượng
                local input = lib.inputDialog('🩹 Bán Băng Gạc', {
                    {
                        type    = 'number',
                        label   = string.format('Kho y tế bệnh viện còn [x%d] băng gạc\nHãy nhập số lượng muốn bán:', stockCount),
                        required = true,
                        min     = Config.MinQuantity,
                        max     = maxSell,
                        default = 1,
                    }
                })

                -- Bác sĩ bấm Hủy → không làm gì
                if not input then
                    Config.DebugPrint('Doctor cancelled quantity dialog')
                    return
                end

                local quantity = tonumber(input[1])
                if not quantity or quantity < Config.MinQuantity or quantity > maxSell then
                    lib.notify({ title = 'EMS Bandage', description = 'Số lượng không hợp lệ!', type = 'error' })
                    return
                end

                local totalPrice = quantity * Config.BandagePrice

                Config.DebugPrint('Sending sale request - target:', targetServerId, 'qty:', quantity, 'total:', totalPrice)

                -- Gửi yêu cầu bán lên server (server sẽ forward sang client của target)
                TriggerServerEvent('xn_emsbandage:server:requestSale', targetServerId, quantity, totalPrice)
                lib.notify({ title = 'EMS Bandage', description = 'Đã gửi yêu cầu bán, chờ người mua xác nhận...', type = 'inform', duration = 6000 })
            end)
        end
    }
})

-- ============================================================
-- EVENT: NHẬN OFFER TỪ BÁC SĨ (phía người được target)
-- ============================================================
RegisterNetEvent('xn_emsbandage:client:receiveSaleOffer', function(doctorName, doctorGrade, quantity, totalPrice, doctorServerId)
    Config.DebugPrint('Received offer from doctor:', doctorName, 'qty:', quantity, 'price:', totalPrice)

    -- Hiển thị dialog xác nhận cho người mua
    local alert = lib.alertDialog({
        header  = '🩹 Bác Sĩ Muốn Bán Băng Gạc',
        content = string.format(
            '**Bác sĩ:** %s | %s\n\n**Số lượng:** x%d băng gạc\n**Đơn giá:** %s$\n**Tổng tiền:** **%s$**',
            doctorGrade,
            doctorName,
            quantity,
            lib.math.groupdigits(Config.BandagePrice),
            lib.math.groupdigits(totalPrice)
        ),
        centered = true,
        cancel   = true,
        labels   = {
            confirm = '✅ Xác Nhận',
            cancel  = '❌ Hủy',
        }
    })

    if alert == 'confirm' then
        Config.DebugPrint('Buyer confirmed purchase')
        TriggerServerEvent('xn_emsbandage:server:confirmPurchase', doctorServerId, quantity, totalPrice)
    else
        Config.DebugPrint('Buyer declined purchase')
        TriggerServerEvent('xn_emsbandage:server:declinePurchase', doctorServerId)
    end
end)

-- ============================================================
-- EVENT: NHẬN KẾT QUẢ GIAO DỊCH (phía bác sĩ)
-- ============================================================
RegisterNetEvent('xn_emsbandage:client:saleResult', function(success, message)
    if success then
        lib.notify({ title = '🩹 EMS Bandage', description = message, type = 'success', duration = 6000 })
    else
        lib.notify({ title = '🩹 EMS Bandage', description = message, type = 'error', duration = 5000 })
    end
end)

-- ============================================================
-- EVENT: NHẬN KẾT QUẢ MUA HÀNG (phía người mua)
-- ============================================================
RegisterNetEvent('xn_emsbandage:client:purchaseResult', function(success, message)
    if success then
        lib.notify({ title = '🩹 EMS Bandage', description = message, type = 'success', duration = 6000 })
    else
        lib.notify({ title = '🩹 EMS Bandage', description = message, type = 'error', duration = 5000 })
    end
end)

-- ============================================================
-- TÍNH NĂNG CHẾ TẠO BĂNG GẠC (CRAFTING)
-- ============================================================

local isCrafting = false

-- Dialog nhập số lượng chế tạo và kích hoạt progress bar từng cái một
local function StartCraftBandageDialog(countBonggon, maxCraft)
    if isCrafting then
        lib.notify({ title = 'EMS Bandage', description = 'Bạn đang trong quá trình chế tạo!', type = 'error' })
        return
    end

    if maxCraft <= 0 then
        lib.notify({
            title = 'EMS Bandage',
            description = string.format('Kho y tế không đủ Bông gòn! Cần tối thiểu %d bông gòn để chế 1 băng gạc.', Config.BonggonPerBandage),
            type = 'error'
        })
        return
    end

    local input = lib.inputDialog('🩹 Chế Tạo Băng Gạc', {
        {
            type = 'number',
            label = 'Số lượng Băng Gạc cần chế',
            description = string.format('Kho có %d Bông gòn (Tối đa có thể chế: %d cái)', countBonggon, maxCraft),
            required = true,
            min = 1,
            max = maxCraft,
            default = 1,
        }
    })

    if not input then return end

    local quantity = tonumber(input[1])
    if not quantity or quantity < 1 or quantity > maxCraft then
        lib.notify({ title = 'EMS Bandage', description = 'Số lượng không hợp lệ hoặc vượt quá nguyên liệu trong kho!', type = 'error' })
        return
    end

    isCrafting = true
    local craftedCount = 0

    for i = 1, quantity do
        -- Chạy progress bar cho từng cái một (vd: 2 giây/cái)
        local success = lib.progressBar({
            duration = Config.CraftTimePerItem,
            label = string.format('Đang chế tạo Băng gạc [%d/%d]...', i, quantity),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
            anim = {
                dict = 'mini@repair',
                clip = 'fixing_a_ped',
            },
        })

        -- Nếu người chơi hủy (bấm Cancel)
        if not success then
            lib.notify({
                title = 'EMS Bandage',
                description = string.format('Đã dừng chế tạo! Đã hoàn thành: x%d/%d Băng gạc.', craftedCount, quantity),
                type = 'inform'
            })
            break
        end

        -- Gọi server trừ nguyên liệu và cộng 1 băng gạc vào kho
        local ok, errMsg = lib.callback.await('xn_emsbandage:server:craftSingleBandage', false)
        if not ok then
            lib.notify({
                title = 'EMS Bandage',
                description = errMsg or 'Lỗi trong quá trình chế tạo!',
                type = 'error'
            })
            break
        end

        craftedCount = craftedCount + 1
    end

    isCrafting = false

    if craftedCount > 0 then
        TriggerServerEvent('xn_emsbandage:server:finishCraftSession', craftedCount)
        if craftedCount == quantity then
            lib.notify({
                title = 'EMS Bandage',
                description = string.format('✅ Đã hoàn thành chế tạo x%d Băng gạc vào kho y tế!', craftedCount),
                type = 'success',
                duration = 5000
            })
        end
    end
end

-- Context menu chế tạo băng gạc
local function OpenCraftMenu()
    local jobName, onDuty, jobGrade = GetPlayerJob()
    local gradeLevel = (type(jobGrade) == 'table' and jobGrade.level) or (type(jobGrade) == 'number' and jobGrade) or 0

    if jobName ~= Config.EmsJob then
        lib.notify({
            title = 'EMS Bandage',
            description = 'Chỉ có Bác sĩ (EMS) mới có thể sử dụng bàn chế tạo này!',
            type = 'error'
        })
        return
    end

    if not onDuty then
        lib.notify({
            title = 'EMS Bandage',
            description = 'Bạn phải đang trực ca (On-Duty) mới có thể chế tạo băng gạc!',
            type = 'error'
        })
        return
    end

    if gradeLevel < (Config.MinCraftGrade or 6) then
        lib.notify({
            title = 'EMS Bandage',
            description = string.format('Bạn cần đạt cấp %d trở lên mới có thể chế tạo băng gạc!', Config.MinCraftGrade or 6),
            type = 'error'
        })
        return
    end

    lib.callback('xn_emsbandage:server:getStashItemCounts', false, function(counts)
        if not counts then
            lib.notify({ title = 'EMS Bandage', description = 'Lỗi kết nối kho y tế!', type = 'error' })
            return
        end

        local countBonggon = counts.bonggon or 0
        local countBandage = counts.bandage or 0
        local maxCraft = math.floor(countBonggon / Config.BonggonPerBandage)

        lib.registerContext({
            id = 'xn_ems_craft_menu',
            title = '🏥 Bàn Chế Băng Gạc',
            options = {
                {
                    title = '🩹 Chế Băng Gạc (Bandage)',
                    description = string.format('Tỷ lệ: %d Bông gòn = 1 Băng gạc\nKho y tế có: %d Bông gòn | Tối đa chế: %d cái', Config.BonggonPerBandage, countBonggon, maxCraft),
                    icon = 'fas fa-mortar-pestle',
                    disabled = (maxCraft <= 0),
                    metadata = {
                        { label = 'Bông gòn trong kho', value = tostring(countBonggon) },
                        { label = 'Băng gạc trong kho', value = tostring(countBandage) },
                        { label = 'Tối đa có thể chế', value = tostring(maxCraft) .. ' cái' },
                        { label = 'Thời gian', value = string.format('%d giây / cái', math.floor(Config.CraftTimePerItem / 1000)) },
                        { label = 'Kho lưu trữ', value = 'Kho y tế (' .. Config.BossStashId .. ')' }
                    },
                    onSelect = function()
                        StartCraftBandageDialog(countBonggon, maxCraft)
                    end,
                }
            }
        })
        lib.showContext('xn_ems_craft_menu')
    end)
end

-- ============================================================
-- OX_TARGET - BÀN CHẾ TẠO BĂNG GẠC
-- ============================================================
exports.ox_target:addBoxZone({
    name = 'xn_ems_craft_bandage_zone',
    coords = Config.CraftLocation,
    size = Config.CraftSize or vec3(2.0, 2.0, 2.0),
    rotation = 0,
    debug = Config.Debug,
    drawSprite = true,
    options = {
        {
            name = 'xn_ems_craft_bandage_zone',
            icon = 'fas fa-mortar-pestle',
            label = '🩹 Chế Băng Gạc',
            distance = Config.CraftDistance or 2.5,
            onSelect = function()
                OpenCraftMenu()
            end,
        }
    }
})


