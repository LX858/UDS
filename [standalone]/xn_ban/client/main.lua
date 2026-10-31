local isMenuOpen = false

-- Mở menu NUI
RegisterNetEvent('xn_ban:client:openMenu', function()
    if isMenuOpen then return end
    isMenuOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'setVisible',
        data = true
    })

    -- Yêu cầu dữ liệu ban đầu từ server
    TriggerServerEvent('xn_ban:server:getBans')
    TriggerServerEvent('xn_ban:server:getOnlinePlayers')
end)

-- Nhận danh sách Bans từ server và chuyển sang NUI
RegisterNetEvent('xn_ban:client:receiveBans', function(bans)
    SendNUIMessage({
        action = 'setBans',
        data = bans
    })
end)

-- Nhận danh sách Online Players từ server và chuyển sang NUI
RegisterNetEvent('xn_ban:client:receiveOnlinePlayers', function(players)
    SendNUIMessage({
        action = 'setOnlinePlayers',
        data = players
    })
end)

-- Nhận kết quả tìm kiếm người chơi Offline từ server và chuyển sang NUI
RegisterNetEvent('xn_ban:client:receiveOfflineSearchResults', function(results)
    SendNUIMessage({
        action = 'setOfflineSearchResults',
        data = results
    })
end)

-- NUI Callbacks
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb('ok')
end)

RegisterNUICallback('getBans', function(_, cb)
    TriggerServerEvent('xn_ban:server:getBans')
    cb('ok')
end)

RegisterNUICallback('getOnlinePlayers', function(_, cb)
    TriggerServerEvent('xn_ban:server:getOnlinePlayers')
    cb('ok')
end)

RegisterNUICallback('searchOfflinePlayers', function(data, cb)
    TriggerServerEvent('xn_ban:server:searchOfflinePlayers', data and data.query or '')
    cb('ok')
end)

RegisterNUICallback('createBan', function(data, cb)
    TriggerServerEvent('xn_ban:server:createBan', data)
    cb('ok')
end)

RegisterNUICallback('revokeBan', function(data, cb)
    TriggerServerEvent('xn_ban:server:revokeBan', data.banId, data.reason)
    cb('ok')
end)

-- Phím ESC dự phòng đóng menu nếu cần
RegisterCommand('closebanui', function()
    if isMenuOpen then
        SetNuiFocus(false, false)
        isMenuOpen = false
        SendNUIMessage({
            action = 'setVisible',
            data = false
        })
    end
end, false)
