local QBCore = exports['qb-core']:GetCoreObject()
local SpawnedPeds = {}
local stallZones = {}

-- EXPORT PedList ra global để client.lua sử dụng
_G.PedList = Config.Stalls

CreateThread(function()
    print("^2[fivem-stall] Loading Peds...^7")
    print("^3[StallSystem] Total stalls: " .. #PedList .. "^7")

    for k, v in ipairs(PedList) do
        local npcModel = v.npcModel or v.model
        local model = joaat(npcModel)

        RequestModel(model)

        while not HasModelLoaded(model) do
            Wait(10)
        end

        local coords = v.npcPosition or v.coords
        local ped = CreatePed(
            4,
            model,
            coords.x,
            coords.y,
            coords.z - 1.0,
            coords.w,
            false,
            true
        )

        local labelName = v.name or v.label
        print("^3[StallSystem] Spawn Ped for " .. labelName .. ": " .. ped .. "^7")

        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        -- Lưu PED với key là stall ID
        SpawnedPeds[v.id] = ped

        -- Tạo label và onSelect
        local label = '🏪 Xem gian hàng - ' .. labelName
        local onSelect = function()
            print("^3[StallSystem] Opening stall " .. v.id .. " - " .. labelName .. "^7")
            OpenStallUI(v.id)
        end

        -- Tạo target cho PED
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'stall_target_' .. v.id,
                icon = 'fa-solid fa-store',
                label = label,
                distance = 3.0,
                onSelect = onSelect
            }
        })

        stallZones['stall_zone_' .. v.id] = true
        print("^2[StallSystem] ✅ Target added for " .. labelName .. " (ID: " .. v.id .. ")^7")

        SetModelAsNoLongerNeeded(model)
    end

    local totalZones = 0
    for _ in pairs(stallZones) do totalZones = totalZones + 1 end
    print("^2[fivem-stall] Done! Total targets created: " .. totalZones .. "^7")
end)

-- Event cập nhật target
RegisterNetEvent('stall:refreshTargets', function()
    print("^3[StallSystem] Refreshing stall targets...^7")
    
    -- Xóa target cũ
    for stallId, ped in pairs(SpawnedPeds) do
        if DoesEntityExist(ped) then
            exports.ox_target:removeLocalEntity(ped)
        end
    end
    
    Citizen.Wait(500)
    
    -- Tạo lại target cho từng PED
    for stallId, ped in pairs(SpawnedPeds) do
        if DoesEntityExist(ped) then
            local stall = nil
            for _, v in ipairs(PedList) do
                if v.id == stallId then
                    stall = v
                    break
                end
            end
            
            if stall then
                local labelName = stall.name or stall.label
                local label = '🏪 Xem gian hàng - ' .. labelName
                local onSelect = function()
                    print("^3[StallSystem] Opening stall " .. stallId .. "^7")
                    OpenStallUI(stallId)
                end
                
                exports.ox_target:addLocalEntity(ped, {
                    {
                        name = 'stall_target_' .. stallId,
                        icon = 'fa-solid fa-store',
                        label = label,
                        distance = 3.0,
                        onSelect = onSelect
                    }
                })
                
                print("^2[StallSystem] ✅ Target refreshed for " .. labelName .. " (ID: " .. stallId .. ")^7")
            end
        end
    end
end)

-- Đóng UI
RegisterNetEvent('stall:closeUI', function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeUI'})
end)

-- Cleanup khi resource dừng
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    for _, ped in pairs(SpawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    SetNuiFocus(false, false)
end)

-- Command test
RegisterCommand('stallinfo', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    print("===== STALL INFO =====")
    for stallId, ped in pairs(SpawnedPeds) do
        if ped and DoesEntityExist(ped) then
            local npcCoords = GetEntityCoords(ped)
            local dist = #(coords - npcCoords)
            
            print(string.format("Stall #%d - Distance: %.1fm", stallId, dist))
            print("  Status: Click to open")
        else
            print("Stall #" .. stallId .. " - Ped does not exist!")
        end
    end
    print("======================")
end, false)

-- Kiểm tra và refresh target định kỳ
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)
        
        local needRefresh = false
        for stallId, _ in pairs(SpawnedPeds) do
            if not stallZones['stall_zone_' .. stallId] then
                needRefresh = true
                break
            end
        end
        
        if needRefresh then
            print("^3[StallSystem] Some targets are missing, refreshing...^7")
            TriggerEvent('stall:refreshTargets')
        end
    end
end)