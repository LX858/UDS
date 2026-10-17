local lastUsed = 0
local cooldownTime = 15000 -- 15 seconds in milliseconds
local activeDisplays = {} -- Lưu trữ tất cả displays đang active
local isRendering = false

RegisterNetEvent("3dme:me")
AddEventHandler("3dme:me", function(text, source)
    -- Thêm vào danh sách active displays TRƯỚC khi bắt đầu thread
    activeDisplays[source] = {
        text = text,
        active = true
    }
    
    -- Bắt đầu render ngay lập tức
    if not isRendering then
        isRendering = true
        
        Citizen.CreateThread(function()
            while next(activeDisplays) ~= nil do
                Citizen.Wait(0)
                local combinedHTML = ""
                
                for src, displayData in pairs(activeDisplays) do
                    if displayData.active then
                        local playerId = GetPlayerFromServerId(src)
                        if playerId ~= -1 then
                            local sourceCoords = GetEntityCoords(GetPlayerPed(playerId))
                            local nearCoords = GetEntityCoords(PlayerPedId())
                            local distance = Vdist2(sourceCoords, nearCoords)
                            
                            if distance < 5.0 then
                                local onScreen, xxx, yyy = GetHudScreenPositionFromWorldPosition(
                                    sourceCoords.x + Config.CoordsX,
                                    sourceCoords.y + Config.CoordsY,
                                    sourceCoords.z + Config.CoordsZ
                                )
                                combinedHTML = combinedHTML ..
                                    '<span style="position: absolute; left: ' ..
                                    xxx * 100 ..
                                    "%;top: " .. yyy * 100 ..
                                    '%;"><div class="me-container"><div class="text-container">' ..
                                    displayData.text ..
                                    "</div></div></span>"
                            end
                        end
                    end
                end
                
                SendNUIMessage({
                    toggle = true,
                    html = combinedHTML
                })
            end
            
            -- Không còn display nào, tắt NUI
            SendNUIMessage({toggle = false})
            isRendering = false
        end)
    end
    
    -- Tự động xóa sau Config.Duration
    Citizen.CreateThread(function()
        Citizen.Wait(Config.Duration)
        if activeDisplays[source] then
            activeDisplays[source] = nil
        end
    end)
end)

RegisterCommand("me", function(source, args, rawCommand)
    local currentTime = GetGameTimer()
    if currentTime - lastUsed < cooldownTime then
        local remaining = math.ceil((cooldownTime - (currentTime - lastUsed)) / 1000)
        TriggerEvent('QBCore:Notify', "Vui lòng chờ " .. remaining .. " giây nữa!", "error")
        return
    end
    
    local text = table.concat(args, ' ')
    lastUsed = currentTime
    TriggerServerEvent('3dme:sendMe', text)
end, false)
