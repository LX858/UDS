Peddata = {}
fruitObjects = {}
basketObject = nil
basketItemData = nil
activeBasketSlot = nil  -- Slot thực tế của sọt đang cầm (server-authoritative)
usedTreesData = nil
-- treeCooldowns removed - cooldown now managed by server with timestamps
clientTreeCooldowns = {} -- Client-side 6s cooldown per tree để chống spam
isPickingTree = false    -- Ngăn mở nhiều progressBar cùng lúc
basketDropped = false
treeTargets = {}
treeZoneIds = {} -- Track all tree zone IDs for cleanup
orangeTreeProps = {} -- Track all spawned orange tree props

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(1000)
--         local playerCoords = GetEntityCoords(GetPlayerPed(-1))
--         local distanceToSeller = #(playerCoords - Config.Blip.selling.coords)
        
--         if distanceToSeller < 100.0 then
--             if Peddata[1] ~= nil then
--                 if not DoesEntityExist(Peddata[1]) then
--                     RequestModel(GetHashKey(Config.PedModel))
--                     while not HasModelLoaded(GetHashKey(Config.PedModel)) do
--                         RequestModel(GetHashKey(Config.PedModel))
--                         Wait(100)
--                     end
                    
--                     Peddata[1] = CreatePed(4, GetHashKey(Config.PedModel), Config.Blip.selling.coords, Config.Blip.selling.heading, false, false)
--                     createdPed = Peddata[1]
                    
--                     ClearPedTasks(createdPed)
--                     ClearPedSecondaryTask(createdPed)
--                     TaskSetBlockingOfNonTemporaryEvents(createdPed, true)
--                     SetPedFleeAttributes(createdPed, 0, 0)
--                     SetPedCombatAttributes(createdPed, 17, 1)
--                     SetPedSeeingRange(createdPed, 0.0)
--                     SetPedHearingRange(createdPed, 0.0)
--                     SetPedAlertness(createdPed, 0)
--                     SetPedKeepTask(createdPed, true)
--                     Wait(1000)
--                     FreezeEntityPosition(createdPed, true)
--                     SetEntityInvincible(createdPed, true)
--                 else
--                     local pedCoords = GetEntityCoords(Peddata[1])
--                     local distanceFromSpawn = #(pedCoords - Config.Blip.selling.coords)
                    
--                     if distanceFromSpawn > 5 then
--                         DeleteEntity(Peddata[1])
--                         RequestModel(GetHashKey(Config.PedModel))
--                         while not HasModelLoaded(GetHashKey(Config.PedModel)) do
--                             RequestModel(GetHashKey(Config.PedModel))
--                             Wait(100)
--                         end
                        
--                         Peddata[1] = CreatePed(4, GetHashKey(Config.PedModel), Config.Blip.selling.coords, Config.Blip.selling.heading, false, false)
--                         createdPed = Peddata[1]
                        
--                         ClearPedTasks(createdPed)
--                         ClearPedSecondaryTask(createdPed)
--                         TaskSetBlockingOfNonTemporaryEvents(createdPed, true)
--                         SetPedFleeAttributes(createdPed, 0, 0)
--                         SetPedCombatAttributes(createdPed, 17, 1)
--                         SetPedSeeingRange(createdPed, 0.0)
--                         SetPedHearingRange(createdPed, 0.0)
--                         SetPedAlertness(createdPed, 0)
--                         SetPedKeepTask(createdPed, true)
--                         Wait(1000)
--                         FreezeEntityPosition(createdPed, true)
--                         SetEntityInvincible(createdPed, true)
--                     end
--                 end
--             else
--                 RequestModel(GetHashKey(Config.PedModel))
--                 while not HasModelLoaded(GetHashKey(Config.PedModel)) do
--                     RequestModel(GetHashKey(Config.PedModel))
--                     Wait(100)
--                 end
                
--                 Peddata[1] = CreatePed(4, GetHashKey(Config.PedModel), Config.Blip.selling.coords, Config.Blip.selling.heading, false, false)
--                 createdPed = Peddata[1]
                
--                 ClearPedTasks(createdPed)
--                 ClearPedSecondaryTask(createdPed)
--                 TaskSetBlockingOfNonTemporaryEvents(createdPed, true)
--                 SetPedFleeAttributes(createdPed, 0, 0)
--                 SetPedCombatAttributes(createdPed, 17, 1)
--                 SetPedSeeingRange(createdPed, 0.0)
--                 SetPedHearingRange(createdPed, 0.0)
--                 SetPedAlertness(createdPed, 0)
--                 SetPedKeepTask(createdPed, true)
--                 Wait(1000)
--                 FreezeEntityPosition(createdPed, true)
--                 SetEntityInvincible(createdPed, true)
--             end
--         end
--     end
-- end)

RegisterNetEvent("xn-fruitpicker:buystuff")
AddEventHandler("xn-fruitpicker:buystuff", function()
    if not CheckJob() then
        lib.notify({description = Language.no_job, type = 'error'})
        return
    end
    
    local shopData = {
        label = Language.shop,
        items = Config.ShopItems,
        slots = #Config.ShopItems
    }
    
    TriggerServerEvent("inventory:server:OpenInventory", "shop", "FruitMarket_" .. math.random(1, 99), shopData)
end)

Citizen.CreateThread(function()
    if Config.UseDrawText then
        if CheckJob() then
            while true do
                Wait(3)
                local playerCoords = GetEntityCoords(PlayerPedId())
                
                if #treeTargets > 0 then
                    for targetIndex, targetData in pairs(treeTargets) do
                        local distanceToTree = #(playerCoords - targetData.coords)
                        
                        if distanceToTree < 1.0 then
                            if CheckJob() then
                                DrawText3Ds(targetData.coords.x, targetData.coords.y, targetData.coords.z, "~g~[E] ~w~" .. Language.pluck_orange)
                                
                                if IsControlJustReleased(0, 38) then
                                    TriggerEvent("xn-fruitpicker:stealorange", targetData)
                                    Wait(1000)
                                end
                            end
                        end
                    end
                end
                
                if basketDropped then
                if basketItemData ~= nil then
                    local basketQty = (basketItemData.info and basketItemData.info.qty) or (basketItemData.metadata and basketItemData.metadata.qty) or 0
                    if basketQty > 0 then
                        local basketProp = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.0, GetHashKey("prop_fruit_basket"), 0, 0, 0)                            if basketProp then
                                if basketObject == basketProp then
                                    local basketCoords = GetEntityCoords(basketProp)
                                    local distanceToBasket = #(playerCoords - basketCoords)
                                    
                                    if distanceToBasket < 1.0 then
                                        DrawText3Ds(basketCoords.x, basketCoords.y, basketCoords.z, "~g~[E] ~w~" .. Language.pickup_fruit)
                                        
                                        if IsControlJustReleased(0, 38) then
                                            TriggerEvent("xn-fruitpicker:pickupfruit")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    for blipName, blipData in pairs(Config.Blip) do
        if blipData.enable then
            blipData.blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
            SetBlipSprite(blipData.blip, blipData.Sprite)
            SetBlipDisplay(blipData.blip, 4)
            SetBlipScale(blipData.blip, blipData.Scale)
            SetBlipColour(blipData.blip, blipData.Color)
            SetBlipAsShortRange(blipData.blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(blipData.Label)
            EndTextCommandSetBlipName(blipData.blip)
        end
    end
    
    if Config.UseDrawText then
        while true do
            Wait(3)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToSeller = #(playerCoords - Config.Blip.selling.coords)
            
            if distanceToSeller < 1.0 then
                if CheckJob() then
                    DrawText3Ds(Config.Blip.selling.coords.x, Config.Blip.selling.coords.y, Config.Blip.selling.coords.z, "~g~[E] ~w~" .. Language.buy_stuff)
                    DrawText3Ds(Config.Blip.selling.coords.x, Config.Blip.selling.coords.y, Config.Blip.selling.coords.z - 0.2, "~g~[G] ~w~" .. Language.sell_fruit)
                    
                    if IsControlJustReleased(0, 38) then
                        TriggerEvent("xn-fruitpicker:buystuff")
                    elseif IsControlJustReleased(0, 47) then
                        TriggerEvent("xn-fruitpicker:sellorange")
                    end
                end
            else
                Wait(1000)
            end
        end
    end
end)

function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local textLength = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + textLength, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function CheckJob()
    local hasJob = false
    
    if Config.RequireJob then
        if PlayerJob ~= nil then
            if PlayerJob.name == Config.JobName then
                hasJob = true
            end
        end
    else
        hasJob = true
    end
    
    return hasJob
end

function AddTargets(targetType, data)
    if targetType == "orange" then
        -- Add target for prop_fruit_basket model
        exports.ox_target:addModel('prop_fruit_basket', {
            {
                name = 'pickup_fruit',
                icon = 'fa-solid fa-hand',
                label = Language.pickup_fruit or 'Nhặt cam',
                canInteract = function(entity, distance, coords, name)
                    return basketObject ~= nil and basketObject == entity and basketDropped
                end,
                onSelect = function(data)
                    TriggerEvent("xn-fruitpicker:pickupfruit")
                end
            }
        })
    elseif targetType == "store" then
        -- Add target for selling location
        if data and data.coords then
            exports.ox_target:addSphereZone({
                coords = data.coords,
                radius = 1.0,
                options = {
                    {
                        name = 'buy_stuff',
                        icon = 'fa-solid fa-shopping-cart',
                        label = Language.buy_stuff or 'Mua đồ',
                        canInteract = function()
                            return CheckJob()
                        end,
                        onSelect = function()
                            TriggerEvent("xn-fruitpicker:buystuff")
                        end
                    },
                    {
                        name = 'sell_fruit',
                        icon = 'fa-solid fa-dollar-sign',
                        label = Language.sell_fruit or 'Bán cam',
                        canInteract = function()
                            return CheckJob()
                        end,
                        onSelect = function()
                            TriggerEvent("xn-fruitpicker:sellorange")
                        end
                    }
                }
            })
        end
    elseif targetType == "fruittree" then
        -- Add target for fruit trees
        if data and data.coords then
            local zoneId = exports.ox_target:addSphereZone({
                coords = data.coords,
                radius = 1.0,
                options = {
                    {
                        name = 'pick_orange_' .. data.name,
                        icon = 'fa-solid fa-apple-alt',
                        label = Language.pluck_orange or 'Hái cam',
                        canInteract = function()
                            return basketItemData ~= nil and basketObject ~= nil and not basketDropped
                        end,
                        onSelect = function()
                            TriggerEvent("xn-fruitpicker:stealorange", data)
                        end
                    }
                }
            })
            return zoneId -- Return zone ID for tracking
        end
    end
end

local function InitializeTargets()
    if Config.Debug then
        print("^2[DEBUG] InitializeTargets called^7")
    end
    usedTreesData = lib.callback.await('xn-fruitpicker:server:getdata', false)
    
    if not Config.UseDrawText then
        if Config.Debug then
            print("^2[DEBUG] UseDrawText is false, adding targets^7")
        end
        
        -- Remove existing targets first to prevent duplicates
        pcall(function()
            exports.ox_target:removeModel('prop_fruit_basket', 'pickup_fruit')
        end)
        
        AddTargets("orange")
        AddTargets("store", Config.Blip.selling)
    else
        if Config.Debug then
            print("^3[DEBUG] UseDrawText is true, skipping targets^7")
        end
    end
end

-- Function to remove all existing tree target zones
local function RemoveAllTreeTargets()
    if Config.Debug then
        print("^2[DEBUG] Removing all tree targets, count:^7", #treeZoneIds)
    end
    
    -- Remove all registered tree zones
    for _, zoneId in ipairs(treeZoneIds) do
        pcall(function()
            exports.ox_target:removeZone(zoneId)
        end)
    end
    
    -- Clear the tracking tables
    treeZoneIds = {}
    treeTargets = {}
    
    if Config.Debug then
        print("^2[DEBUG] All tree targets removed^7")
    end
end

local function SetupTreeTargets()
    if Config.Debug then
        print("^2[DEBUG] SetupTreeTargets called, UseXp:^7", Config.UseXp)
    end
    
    -- Remove all existing tree targets first to prevent duplicates
    RemoveAllTreeTargets()
    
    if Config.UseXp then
        local playerData = exports.qbx_core:GetPlayerData()
        local jobRep = playerData.metadata.jobrep or {}
        local treeCount = 0
        
        if jobRep.fruitpeeker ~= nil then
            for xpLevel, xpData in pairs(Config.Xp) do
                if jobRep.fruitpeeker <= xpData.xp then
                    for treeIndex, treeCoords in pairs(Config.Orange) do
                        if treeCount < xpData.enabletree then
                            local treeData = {
                                coords = treeCoords,
                                name = "orange" .. treeIndex
                            }
                            
                            if Config.UseDrawText then
                                treeTargets[treeIndex] = treeData
                            else
                                local zoneId = AddTargets("fruittree", treeData)
                                if zoneId then
                                    table.insert(treeZoneIds, zoneId)
                                end
                            end
                            
                            treeCount = treeCount + 1
                        end
                    end
                end
                break
            end
        else
            for treeIndex, treeCoords in pairs(Config.Orange) do
                if treeCount < 10 then
                    local treeData = {
                        coords = treeCoords,
                        name = "orange" .. treeIndex
                    }
                    
                    if Config.UseDrawText then
                        treeTargets[treeIndex] = treeData
                    else
                        local zoneId = AddTargets("fruittree", treeData)
                        if zoneId then
                            table.insert(treeZoneIds, zoneId)
                        end
                    end
                    
                    treeCount = treeCount + 1
                end
            end
        end
    else
        for treeIndex, treeCoords in pairs(Config.Orange) do
            local treeData = {
                coords = treeCoords,
                name = "orange" .. treeIndex
            }
            
            if Config.UseDrawText then
                treeTargets[treeIndex] = treeData
            else
                local zoneId = AddTargets("fruittree", treeData)
                if zoneId then
                    table.insert(treeZoneIds, zoneId)
                end
            end
        end
    end
end

-- Function to remove all spawned orange tree props
function RemoveOrangeTrees()
    if Config.Debug then
        print("^2[DEBUG] RemoveOrangeTrees called, count:", #orangeTreeProps)
    end
    
    for treeIndex, treeProp in pairs(orangeTreeProps) do
        if DoesEntityExist(treeProp) then
            DeleteEntity(treeProp)
        end
    end
    
    orangeTreeProps = {}
    
    if Config.Debug then
        print("^2[DEBUG] All orange tree props removed^7")
    end
end

-- Function to spawn orange tree props at all Config.Orange locations
local function SpawnOrangeTrees()
    if Config.Debug then
        print("^2[DEBUG] SpawnOrangeTrees called^7")
    end
    
    -- Remove existing props first to prevent duplicates
    RemoveOrangeTrees()
    
    local treeModel = GetHashKey('prop_veg_crop_orange')
    RequestModel(treeModel)
    
    -- Wait for model to load
    local timeout = 0
    while not HasModelLoaded(treeModel) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(treeModel) then
        if Config.Debug then
            print("^1[ERROR] Failed to load prop_veg_crop_orange model^7")
        end
        return
    end
    
    if Config.Debug then
        print("^2[DEBUG] Model loaded, spawning", #Config.Orange, "trees^7")
    end
    
    -- Spawn tree at each location
    for treeIndex, treeCoords in pairs(Config.Orange) do
        -- Create prop slightly below the coords to ensure it sits on ground
        local treeProp = CreateObject(treeModel, treeCoords.x, treeCoords.y, treeCoords.z - 1.0, false, false, false)
        
        if treeProp and DoesEntityExist(treeProp) then
            -- Place on ground and freeze
            PlaceObjectOnGroundProperly(treeProp)
            FreezeEntityPosition(treeProp, true)
            
            -- Store reference
            orangeTreeProps[treeIndex] = treeProp
            
            if Config.Debug and treeIndex <= 3 then
                print("^2[DEBUG] Spawned tree", treeIndex, "at", treeCoords)
            end
        else
            if Config.Debug then
                print("^1[ERROR] Failed to create tree prop at index", treeIndex, "^7")
            end
        end
    end
    
    -- Release model
    SetModelAsNoLongerNeeded(treeModel)
    
    if Config.Debug then
        print("^2[DEBUG] Spawned", #orangeTreeProps, "orange trees^7")
    end
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    if Config.Debug then
        print("^2[DEBUG] QBCore:Client:OnPlayerLoaded fired^7")
    end
    InitializeTargets()
    SetupTreeTargets()
    SpawnOrangeTrees()
end)

-- Auto-initialize on resource start
CreateThread(function()
    Wait(2000)
    if Config.Debug then
        print("^2[DEBUG] Auto-initializing on resource start^7")
    end
    InitializeTargets()
    SetupTreeTargets()
    SpawnOrangeTrees()
end)

RegisterNetEvent("xn-fruitpicker:stealorange")
AddEventHandler("xn-fruitpicker:stealorange", function(treeData)
    if not CheckJob() then
        lib.notify({description = Language.no_job, type = 'error'})
        return
    end

    -- ===== CHỐNG SPAM: Kiểm tra đang hái dở =====
    if isPickingTree then
        lib.notify({description = 'Bạn đang hái cam rồi, chờ xong hãy hái tiếp!', type = 'error'})
        return
    end

    -- ===== CHỐNG SPAM: Client-side cooldown 6 giây mỗi cây =====
    local treeKey = treeData.coords.x + treeData.coords.y
    local now = GetGameTimer()
    if clientTreeCooldowns[treeKey] then
        local elapsed = (now - clientTreeCooldowns[treeKey]) / 1000
        local remaining = math.ceil(6 - elapsed)
        if remaining > 0 then
            lib.notify({
                description = string.format('Cây này vừa được hái! Chờ cooldown %d giây nữa.', remaining),
                type = 'error'
            })
            return
        end
    end

    -- Kiểm tra khoảng cách đến cây (phải đứng trong vòng 1 mét)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distanceToTree = #(playerCoords - treeData.coords)
    if distanceToTree > 2.0 then
        lib.notify({description = 'Bạn cách quá xa', type = 'error'})
        return
    end

    -- Kiểm tra xem người chơi có đang ở trên phương tiện không
    if IsPedInAnyVehicle(playerPed, false) then
        lib.notify({description = 'Bạn không thể hái cam khi đang ở trên phương tiện!', type = 'error'})
        return
    end
    
    if basketItemData ~= nil then
        if basketObject ~= nil and not basketDropped then
            -- treeKey đã khai báo ở trên
            
            -- Kiểm tra cooldown và cân nặng từ server
            local canPick, reason, timeRemaining = lib.callback.await('xn-fruitpicker:canPickTree', false, treeKey)
            
            if not canPick then
                if reason == 'weight' then
                    lib.notify({
                        description = 'Bạn không đủ sức chứa để hái thêm cam!',
                        type = 'error'
                    })
                else
                    lib.notify({
                        description = string.format('Cây này chưa đủ 18 tuổi không hái được được đợi %d giây sẽ trưởng thành!', timeRemaining or 0),
                        type = 'error'
                    })
                end
                return
            end
            
            if not usedTreesData[treeKey] then
                local playerPed = PlayerPedId()
                local treeCoords = treeData.coords

                -- Đánh dấu đang hái để chống spam
                isPickingTree = true
                -- Đặt cooldown client ngay khi bắt đầu
                clientTreeCooldowns[treeKey] = GetGameTimer()
                
                TaskTurnPedToFaceCoord(playerPed, treeCoords.x, treeCoords.y, treeCoords.z, 1000)
                Wait(1000)
                
                loadAnimDict("pickup_object")
                TaskPlayAnim(GetPlayerPed(-1), "pickup_object", "pickup_low", 4.0, 4.0, -1, 16, 0, false, false, false)
                Wait(1000)
                
                DetachEntity(basketObject)
                ClearPedTasks(GetPlayerPed(-1))
                
                if lib.progressBar({
                    duration = 5500,
                    label = Language.pick_prog,
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        move = true,
                        car = true,
                        combat = true
                    },
                    anim = {
                        dict = "amb@prop_human_movie_bulb@idle_a",
                        clip = "idle_a"
                    }
                }) then
                    ClearPedTasks(GetPlayerPed(-1))
                    loadAnimDict("pickup_object")
                    TaskPlayAnim(GetPlayerPed(-1), "pickup_object", "pickup_low", 4.0, 4.0, -1, 16, 0, false, false, false)
                    Wait(1000)
                    ClearPedTasks(GetPlayerPed(-1))
                    AttachBasket(playerPed)
                    
                    -- Gọi server callback để add cam vào sọt (server là nguồn sự thật về slot và qty)
                    -- activeBasketSlot là slot client biết, server sẽ tự verify
                    local ok, reason, newQty, confirmedSlot = lib.callback.await(
                        'xn-fruitpicker:server:addOrangeToBasket', false,
                        activeBasketSlot, treeKey
                    )
                    
                    if ok then
                        -- Cập nhật activeBasketSlot từ slot server xác nhận
                        activeBasketSlot = confirmedSlot
                        -- Cập nhật basketItemData.slot để sync
                        if basketItemData then
                            basketItemData.slot = confirmedSlot
                            if basketItemData.info then basketItemData.info.qty = newQty end
                            if basketItemData.metadata then basketItemData.metadata.qty = newQty end
                        end
                        lib.notify({description = Language.pickup_success, type = 'success'})
                        -- Thêm prop cam lên sọt (chỉ visual)
                        Addbasketfruit(newQty)
                    elseif reason == 'basket_full' then
                        lib.notify({description = Language.basket_full or 'Sọt đã đầy cam (tối đa 20 quả)!', type = 'error'})
                    elseif reason == 'basket_not_found' then
                        lib.notify({description = 'Không tìm thấy sọt trong inventory!', type = 'error'})
                    elseif reason == 'cannot_carry_weight' then
                        lib.notify({description = 'Bạn không đủ sức chứa để mang thêm cam!', type = 'error'})
                    else
                        lib.notify({description = 'Lỗi khi thêm cam vào sọt: ' .. tostring(reason), type = 'error'})
                    end
                else
                    ClearPedTasks(GetPlayerPed(-1))
                    loadAnimDict("pickup_object")
                    TaskPlayAnim(GetPlayerPed(-1), "pickup_object", "pickup_low", 4.0, 4.0, -1, 16, 0, false, false, false)
                    Wait(1000)
                    ClearPedTasks(GetPlayerPed(-1))
                    AttachBasket(playerPed)
                    -- Hủy → xóa cooldown để cho phép thử lại ngay
                    clientTreeCooldowns[treeKey] = nil
                    lib.notify({description = "Canceled..", type = 'error'})
                end
                -- Kết thúc hái (dù thành công hay hủy)
                isPickingTree = false
            else
                lib.notify({description = Language.no_more, type = 'error'})
            end
        elseif basketDropped then
            lib.notify({description = "Bạn đang không cầm theo sọt! Nhấn SHIFT + E để nhặt sọt lên", type = 'error'})
        else
            lib.notify({description = Language.no_basket, type = 'error'})
        end
    else
        lib.notify({description = Language.no_basket, type = 'error'})
    end
end)

function AttachBasket(ped)
    AttachEntityToEntity(basketObject, ped, GetPedBoneIndex(ped, 28422), 0.27, -0.08, 0.16, 160.0, 90.0, 125.0, true, true, false, true, 1, true)
end

RegisterNetEvent("xn-fruitpicker:togglebasket")
AddEventHandler("xn-fruitpicker:togglebasket", function()
    if basketItemData ~= nil then
        if basketObject ~= nil then
            if basketDropped then
                AttachBasket(PlayerPedId())
                basketDropped = false
                lib.notify({description = Language.pickup_basket or "Picked up basket", type = 'success'})
            else
                DetachEntity(basketObject, true, false)
                basketDropped = true
                lib.notify({description = Language.drop_basket or "Dropped basket", type = 'success'})
            end
        else
            lib.notify({description = Language.no_basket or "You don't have a basket", type = 'error'})
        end
    else
        lib.notify({description = Language.no_basket or "You don't have a basket", type = 'error'})
    end
end)

-- SHIFT + E keybind monitoring for basket toggle
CreateThread(function()
    while true do
        Wait(0)
        
        if basketItemData ~= nil and basketObject ~= nil then
            -- Check if SHIFT is held (21 = LEFT SHIFT) and E is pressed (38 = E)
            if IsControlPressed(0, 21) and IsControlJustPressed(0, 38) then
                TriggerEvent("xn-fruitpicker:togglebasket")
            end
        else
            Wait(500) -- No basket, check less frequently
        end
    end
end)

RegisterNetEvent("dropbasket")
AddEventHandler("dropbasket", function()
    TriggerEvent("xn-fruitpicker:togglebasket")
end)

RegisterNetEvent("xn-fruitpicker:sellorange")
AddEventHandler("xn-fruitpicker:sellorange", function()
    if not CheckJob() then
        lib.notify({description = Language.no_job, type = 'error'})
        return
    end
    
    if basketItemData ~= nil then
        if basketObject ~= nil then
            TriggerEvent("db-fruit:selloption")
        else
            lib.notify({description = Language.no_basket, type = 'error'})
        end
    else
        lib.notify({description = Language.no_basket, type = 'error'})
    end
end)

RegisterNetEvent("db-fruit:selloption")
AddEventHandler("db-fruit:selloption", function(data)
    local sellAmount = InsertValue(Language.sell_header, Language.amount, 5)
    sellAmount = tonumber(sellAmount)
    
    if sellAmount ~= nil and sellAmount > 0 then
        if basketItemData ~= nil then
            if basketObject ~= nil then
                -- Verify basket item từ inventory
                local currentBasketItem = GetCurrentBasketItem()
                if not currentBasketItem then
                    lib.notify({description = 'Không tìm thấy sọt trong inventory!', type = 'error'})
                    return
                end
                
                -- Lấy qty từ item thực tế trong inventory
                local currentQty = (currentBasketItem.info and currentBasketItem.info.qty) or (currentBasketItem.metadata and currentBasketItem.metadata.qty) or 0
                
                if currentQty == 0 then
                    lib.notify({description = 'Sọt này không có cam!', type = 'error'})
                    return
                end
                
                if sellAmount <= currentQty then
                    -- Update lại basketItemData từ inventory
                    basketItemData = currentBasketItem
                    -- Giữ đúng slot được server xác nhận (đề phòng QBX cache slot cũ)
                    if activeBasketSlot then
                        basketItemData.slot = activeBasketSlot
                    end
                    
                    if basketItemData.info then
                        basketItemData.info.qty = currentQty - sellAmount
                    end
                    if basketItemData.metadata then
                        basketItemData.metadata.qty = currentQty - sellAmount
                    end
                    TriggerServerEvent("xn-fruitpicker:savebasket", basketItemData, nil)
                    
                    for i = 1, sellAmount do
                        DetachEntity(fruitObjects[#fruitObjects])
                        DeleteEntity(fruitObjects[#fruitObjects])
                        table.remove(fruitObjects, #fruitObjects)
                    end
                    
                    TriggerServerEvent("xn-fruitpicker:selloranges", sellAmount)
                else
                    lib.notify({description = Language.no_fruit, type = 'error'})
                end
            end
        end
    end
end)

RegisterNetEvent("xn-fruitpicker:pickupfruit")
AddEventHandler("xn-fruitpicker:pickupfruit", function()
    local playerPed = PlayerPedId()
    
    if basketItemData ~= nil then
        if basketObject ~= nil then
            TaskTurnPedToFaceEntity(playerPed, basketObject, 1000)
            Wait(1000)
            
            local pickupAmount = InsertValue(Language.pickup_fruit, Language.amount, 5)
            pickupAmount = tonumber(pickupAmount)
            
            if pickupAmount ~= nil and pickupAmount > 0 then
                loadAnimDict("pickup_object")
                TaskPlayAnim(GetPlayerPed(-1), "pickup_object", "pickup_low", 4.0, 4.0, -1, 16, 0, false, false, false)
                Removebasketfruit(tonumber(pickupAmount))
            end
        else
            lib.notify({description = Language.not_own, type = 'error'})
        end
    else
        lib.notify({description = Language.not_own, type = 'error'})
    end
end)

RegisterNetEvent("xn-fruitpicker:eatfruit")
AddEventHandler("xn-fruitpicker:eatfruit", function()
    local playerPed = PlayerPedId()
    local attachModel = GetHashKey("orange")
    boneNumber = 28422
    local boneIndex = GetPedBoneIndex(PlayerPedId(), 28422)
    
    RequestModel(attachModel)
    while not HasModelLoaded(attachModel) do
        Citizen.Wait(100)
    end
    
    attachedProp = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(attachedProp, PlayerPedId(), boneIndex, 0.05, 0.0, -0.03, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
    SetModelAsNoLongerNeeded(attachModel)
    
    loadAnimDict("mp_missheist_countrybank@nervous")
    TaskPlayAnim(playerPed, "mp_missheist_countrybank@nervous", "nervous_idle", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
    Citizen.Wait(100)
    AttachEntityToEntity(attachedProp, playerPed, GetPedBoneIndex(playerPed, 18905), 0.12, 0.05, 0.04, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
    Citizen.Wait(1000)
    
    loadAnimDict("mp_player_inteat@burger")
    TaskPlayAnim(playerPed, "mp_player_inteat@burger", "mp_player_int_eat_burger", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
    Citizen.Wait(5000)
    
    local currentHunger = exports.qbx_core:GetPlayerData().metadata.hunger or 0
    exports.qbx_core:SetMetaData("hunger", currentHunger + math.random(5, 10))
    ClearPedTasks(playerPed)
    DetachEntity(attachedProp, true, true)
    DeleteObject(attachedProp)
end)

exports("Checkbasket", function()
    if basketObject ~= nil then
        if basketDropped then
            return "pickup"
        else
            return "drop"
        end
    else
        return false
    end
end)

-- Client exports for ox_inventory items
exports('usebasket', function(data, slot)
    -- Tạo bảng info riêng, tránh circular reference (itemData.info = itemData)
    local meta = slot.metadata or {}
    local itemData = {
        slot = slot.slot,
        name = slot.name,
        metadata = meta,
        info = {
            qty = meta.qty or 0,
            weight = meta.weight,
            durability = meta.durability,
        },
    }
    TriggerEvent("xn-fruitpicker:usebasket", itemData)
end)

exports('useorange', function(data, slot)
    TriggerEvent("xn-fruitpicker:eatfruit")
end)

RegisterNetEvent("xn-fruitpicker:usebasket")
AddEventHandler("xn-fruitpicker:usebasket", function(itemData)
    if not itemData then
        if Config.Debug then
            print("^1[ERROR] xn-fruitpicker:usebasket - itemData is nil^7")
        end
        return
    end
    
    if basketObject == nil then
        if not itemData.info then
            itemData.info = {}
        end
        if not itemData.metadata then
            itemData.metadata = {}
        end
        
        local fruitQty = itemData.info.qty or itemData.metadata.qty or 0
        itemData.info.qty = fruitQty
        itemData.metadata.qty = fruitQty
        
        basketItemData = itemData
        -- Lưu slot thực tế của sọt (server-authoritative slot tracking)
        activeBasketSlot = itemData.slot
        
        if Config.Debug then
            print(string.format("^2[DEBUG] usebasket: slot=%s, qty=%d^7", tostring(activeBasketSlot), fruitQty))
        end
        
        Setupbasketfruits(fruitQty, itemData)
        
        -- Show orbit-ui notification
        exports["orbit-ui"]:Show("Hái Cam", "Bấm [SHIFT] + [E] để thả và nhặt sọt xuống đất và nhặt cam")
    else
        for fruitIndex, fruitObj in pairs(fruitObjects) do
            DetachEntity(fruitObj)
            DeleteEntity(fruitObj)
        end
        
        DetachEntity(basketObject)
        DeleteEntity(basketObject)
        basketObject = nil
        fruitObjects = {}
        basketItemData = nil
        activeBasketSlot = nil
        
        -- Close orbit-ui notification
        exports["orbit-ui"]:Close()
    end
end)

RegisterNetEvent("xn-fruitpicker:removebasket")
AddEventHandler("xn-fruitpicker:removebasket", function()
    if basketObject ~= nil then
        for fruitIndex, fruitObj in pairs(fruitObjects) do
            DetachEntity(fruitObj)
            DeleteEntity(fruitObj)
        end
        
        DetachEntity(basketObject)
        DeleteEntity(basketObject)
        basketObject = nil
        fruitObjects = {}
        basketItemData = nil
        activeBasketSlot = nil  -- Reset slot tracking
        basketDropped = false -- Reset dropped state
        
        -- Hide orbit-ui notification
        exports["orbit-ui"]:Close()
    end
end)

RegisterNetEvent("xn-fruitpicker:updatedata")
AddEventHandler("xn-fruitpicker:updatedata", function(data)
    usedTreesData = data
end)

-- Client-side cooldown countdown đã bị XÓA
-- Cooldown giờ được quản lý hoàn toàn bởi server bằng timestamp
-- Không còn cần treeCooldowns table nữa

function loadAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Citizen.Wait(0)
    end
end

-- Helper function để lấy basket item hiện tại từ inventory
-- Ưu tiên dùng activeBasketSlot (server-authoritative) để tránh nhầm lẫn khi đảo slot
function GetCurrentBasketItem()
    if not basketObject then
        return nil
    end
    
    local PlayerData = exports.qbx_core:GetPlayerData()
    if not PlayerData or not PlayerData.items then
        return nil
    end
    
    -- Ưu tiên tìm theo activeBasketSlot (slot được server xác nhận)
    if activeBasketSlot then
        for slot, item in pairs(PlayerData.items) do
            if item and item.name == 'fruit_basket' and item.slot == activeBasketSlot then
                return item
            end
        end
    end
    
    -- Fallback: tìm theo basketItemData.slot nếu activeBasketSlot nil
    if basketItemData and basketItemData.slot then
        for slot, item in pairs(PlayerData.items) do
            if item and item.name == 'fruit_basket' and item.slot == basketItemData.slot then
                return item
            end
        end
    end
    
    -- Last resort: lấy basket đầu tiên tìm được
    for slot, item in pairs(PlayerData.items) do
        if item and item.name == 'fruit_basket' then
            return item
        end
    end
    
    return nil
end

function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(1)
    end
end

function Setupbasketfruits(fruitQty, itemData)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    if basketObject == nil then
        basketObject = CreateObject(GetHashKey("prop_fruit_basket"), playerCoords.x, playerCoords.y, playerCoords.z, true, true, true)
        AttachBasket(playerPed)
    end
    
    if fruitQty ~= 0 then
        local fruitModel = GetHashKey("orange")
        LoadModel(fruitModel)
        
        for i = 1, fruitQty do
            if not fruitObjects[i] then
                local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(basketObject, -1.0, 0.0, 0.0))
                local fruitObj = CreateObject(fruitModel, x, y, z, true, false, true)
                AttachEntityToEntity(fruitObj, basketObject, -1, Config.FruitLoc[i].x, Config.FruitLoc[i].y, Config.FruitLoc[i].z, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                fruitObjects[i] = fruitObj
            end
        end
    end
end

-- Addbasketfruit: Chỉ xử lý visual (spawn prop cam trên sọt)
-- Metadata đã được server cập nhật trước khi gọi hàm này
-- newQty: số quả hiện tại trong sọt (do server trả về)
function Addbasketfruit(newQty)
    if not basketObject then
        if Config.Debug then
            print("^3[DEBUG] Addbasketfruit: basketObject is nil, skipping visual^7")
        end
        return
    end
    
    local maxOranges = Config.BasketMaxOranges or 20
    
    -- Đảm bảo không vượt quá số vị trí FruitLoc và giới hạn cấu hình
    if newQty > maxOranges or newQty > #Config.FruitLoc then
        if Config.Debug then
            print(string.format("^3[DEBUG] Addbasketfruit: newQty=%d exceeds max=%d, capping^7", newQty, maxOranges))
        end
        newQty = math.min(newQty, maxOranges, #Config.FruitLoc)
    end
    
    if newQty <= 0 then return end
    
    local fruitModel = GetHashKey("orange")
    LoadModel(fruitModel)
    
    -- Thêm prop cho quả cam mới (chỉ tạo slot chưa có prop)
    for i = 1, newQty do
        if not fruitObjects[i] then
            local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(basketObject, -1.0, 0.0, 0.0))
            local fruitObj = CreateObject(fruitModel, x, y, z, true, false, true)
            AttachEntityToEntity(fruitObj, basketObject, -1,
                Config.FruitLoc[i].x, Config.FruitLoc[i].y, Config.FruitLoc[i].z,
                0.0, 0.0, 0.0, true, true, false, true, 1, true)
            fruitObjects[i] = fruitObj
            
            if Config.Debug then
                print(string.format("^2[DEBUG] Addbasketfruit: spawned fruit prop at slot %d^7", i))
            end
        end
    end
end

function Removebasketfruit(removeQty)
    if basketItemData ~= nil then
        if basketObject ~= nil then
            -- Verify basket item từ inventory
            local currentBasketItem = GetCurrentBasketItem()
            if not currentBasketItem then
                lib.notify({description = 'Không tìm thấy sọt trong inventory!', type = 'error'})
                return
            end
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Lấy qty từ item thực tế trong inventory
            local currentQty = (currentBasketItem.info and currentBasketItem.info.qty) or (currentBasketItem.metadata and currentBasketItem.metadata.qty) or 0
            
            if currentQty == 0 then
                lib.notify({description = 'Sọt này không có cam!', type = 'error'})
                return
            end
            
            if removeQty <= currentQty then
                -- Kiểm tra sức chứa TRƯỚC khi xóa prop và data
                lib.callback('xn-fruitpicker:canCarryOranges', false, function(canCarry)
                    if not canCarry then
                        lib.notify({description = 'Không đủ sức chứa để lấy ' .. removeQty .. ' quả cam!', type = 'error'})
                        return
                    end
                    
                    -- Update lại basketItemData từ inventory
                    basketItemData = currentBasketItem
                    -- Giữ đúng slot được server xác nhận (đề phòng QBX cache slot cũ)
                    if activeBasketSlot then
                        basketItemData.slot = activeBasketSlot
                    end
                    
                    -- Nếu đủ sức chứa mới xóa prop và data
                    if basketItemData.info then
                        basketItemData.info.qty = currentQty - removeQty
                    end
                    if basketItemData.metadata then
                        basketItemData.metadata.qty = currentQty - removeQty
                    end
                    TriggerServerEvent("xn-fruitpicker:savebasket", basketItemData, nil)
                    
                    for i = 1, removeQty do
                        DetachEntity(fruitObjects[#fruitObjects], true, true)
                        DeleteEntity(fruitObjects[#fruitObjects])
                        table.remove(fruitObjects, #fruitObjects)
                    end
                    
                    exports['monitors']:TriggerProtectedServerEvent("xn-fruitpicker:getoranges", removeQty)
                end, removeQty)
            else
                lib.notify({description = Language.no_fruit, type = 'error'})
            end
        else
            lib.notify({description = Language.no_basket, type = 'error'})
        end
    else
        lib.notify({description = Language.no_basket, type = 'error'})
    end
end

-- Cleanup when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if Config.Debug then
            print("^2[DEBUG] Resource stopping, cleaning up props^7")
        end
        RemoveOrangeTrees()
    end
end)
