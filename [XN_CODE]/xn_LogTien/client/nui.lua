local isMoneyInfoOpen = false
local autoRefreshThread = nil
local AUTO_REFRESH_INTERVAL = 30 -- seconds (cập nhật mỗi 30 giây)

-- ============================================================
-- AUTO-REFRESH: Push dữ liệu mới vào NUI khi đang mở
-- ============================================================

local function doAutoRefresh()
    lib.callback('xn_LogTien:server:getMoneyInfo', false, function(res)
        if res and isMoneyInfoOpen then
            SendNUIMessage({
                action = "updateData",
                data = res
            })
        end
    end)
end

local function startAutoRefresh()
    if autoRefreshThread then return end
    autoRefreshThread = CreateThread(function()
        while isMoneyInfoOpen do
            Wait(AUTO_REFRESH_INTERVAL * 1000)
            if isMoneyInfoOpen then
                doAutoRefresh()
            end
        end
        autoRefreshThread = nil
    end)
end

local function stopAutoRefresh()
    -- Đánh dấu dừng; thread tự thoát do isMoneyInfoOpen = false
    autoRefreshThread = nil
end

-- ============================================================
-- NUI EVENTS
-- ============================================================

-- Nhận event từ server để mở NUI
RegisterNetEvent('xn_LogTien:client:openMoneyInfo', function(data)
    if isMoneyInfoOpen then return end

    if data then
        SendNUIMessage({
            action = "openMoneyInfo",
            data = data
        })
        SetNuiFocus(true, true)
        isMoneyInfoOpen = true
        startAutoRefresh()
    end
end)

-- Đóng NUI
local function handleCloseUI(data, cb)
    SetNuiFocus(false, false)
    isMoneyInfoOpen = false
    stopAutoRefresh()
    if cb then cb('ok') end
end

RegisterNUICallback('closeMoneyInfo', handleCloseUI)
RegisterNUICallback('close', handleCloseUI)

-- Refresh thủ công từ nút Refresh trong UI
RegisterNUICallback('refreshData', function(data, cb)
    lib.callback('xn_LogTien:server:getMoneyInfo', false, function(res)
        cb(res or {})
    end)
end)

-- Xóa một cảnh báo
RegisterNUICallback('dismissLog', function(data, cb)
    if data and data.logKey then
        TriggerServerEvent('xn_LogTien:server:dismissLog', data.logKey)
    end
    cb('ok')
end)

-- Xóa tất cả cảnh báo
RegisterNUICallback('clearAllLogs', function(data, cb)
    TriggerServerEvent('xn_LogTien:server:clearAllLogs', data and data.keys or {})
    cb('ok')
end)

-- Admin rút tiền doanh nghiệp nhà nước
RegisterNUICallback('withdrawGovMoney', function(data, cb)
    lib.callback('xn_LogTien:server:withdrawGovMoney', false, function(res)
        cb(res or { success = false, message = 'Lỗi không xác định.' })
    end, data)
end)

-- ============================================================
-- PHÍM TẮT ESC
-- ============================================================

RegisterCommand('+closeMoneyInfo', function()
    if isMoneyInfoOpen then
        SendNUIMessage({ action = "closeMoneyInfo" })
        SetNuiFocus(false, false)
        isMoneyInfoOpen = false
        stopAutoRefresh()
    end
end, false)

RegisterCommand('-closeMoneyInfo', function() end, false)
RegisterKeyMapping('+closeMoneyInfo', 'Đóng Money Info', 'keyboard', 'ESCAPE')
