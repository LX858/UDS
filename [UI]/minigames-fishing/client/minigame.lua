-- Thêm debug và export functions để có thể gọi từ script lunar_fishing
local minigameCallback = nil

-- Function được export để có thể gọi từ các script khác
function StartMinigame(callback)
    minigameCallback = callback
    SendNUIMessage({ type = "show" })
    SetNuiFocus(true, true)
end

function StopMinigame()
    SendNUIMessage({ type = "hide" })
    SetNuiFocus(false, false)
    -- Đảm bảo callback được gọi với kết quả thất bại nếu minigame bị dừng
    if minigameCallback then
        minigameCallback(false)
        minigameCallback = nil
    end
end

-- Register export để các script khác có thể sử dụng
exports('StartMinigame', StartMinigame)
exports('StopMinigame', StopMinigame)

-- Lệnh test
RegisterCommand("fishingtest", function()
    StartMinigame(function(success)
        -- Không cần debug ở đây
    end)
end, false)

RegisterCommand("fishingoff", function()
    StopMinigame()
end, false)

-- Đảm bảo callback hoạt động cho cả hai script
RegisterNUICallback("minigameEnd", function(data, cb)
    SetNuiFocus(false, false)
    
    if minigameCallback then
        minigameCallback(data.success)
        minigameCallback = nil
    end
    
    cb({})
end)

-- Debug
AddEventHandler('onClientResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
end)
