-- Variable để lưu thông tin
local currentShopData = nil
local pendingSale = nil
local isMenuOpen = false

-- Debug function
local function debugPrint(...)
    if Config.debug then
        print(...)
    end
end

-- Lấy thông tin job của player
local function GetPlayerJob()
    local playerData = exports.qbx_core:GetPlayerData()
    if playerData and playerData.job then
        return playerData.job.name, playerData.job.onduty
    end
    return nil, false
end

-- Lấy PID của player
local function GetPlayerPid()
    local pid = LocalPlayer.state.pid
    if not pid then
        local playerData = exports.qbx_core:GetPlayerData()
        if playerData then
            pid = playerData.pid
        end
    end
    return pid
end

-- Tìm shop config dựa trên job
local function GetShopByJob(jobName)
    for shopKey, shopConfig in pairs(Config.Shops) do
        if shopConfig.job == jobName then
            return shopKey, shopConfig
        end
    end
    return nil, nil
end

-- Kiểm tra player có phải nhân viên của shop không
local function IsEmployeeOfShop(shopKey)
    local jobName, onDuty = GetPlayerJob()
    if not jobName or not onDuty then return false end
    
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return false end
    
    return shopConfig.job == jobName
end

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb({})
end)

RegisterNUICallback('placeOrder', function(data, cb)
    debugPrint("DEBUG CLIENT: Đặt hàng - shopKey:", data.shopKey, "items:", json.encode(data.items))
    
    local pid = GetPlayerPid()
    local playerData = exports.qbx_core:GetPlayerData()
    local playerName = playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
    
    TriggerServerEvent('xn_banhnuoc:server:placeOrder', data.shopKey, data.items, pid, playerName)
    
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb({})
end)

RegisterNUICallback('confirmOrder', function(data, cb)
    debugPrint("DEBUG CLIENT: Xác nhận đơn - orderId:", data.orderId)
    TriggerServerEvent('xn_banhnuoc:server:confirmOrder', data.shopKey, data.orderId)
    cb({})
end)

RegisterNUICallback('cancelOrder', function(data, cb)
    debugPrint("DEBUG CLIENT: Hủy đơn - orderId:", data.orderId)
    TriggerServerEvent('xn_banhnuoc:server:cancelOrder', data.shopKey, data.orderId)
    cb({})
end)

RegisterNUICallback('completeOrder', function(data, cb)
    debugPrint("DEBUG CLIENT: Hoàn thành đơn - orderId:", data.orderId)
    TriggerServerEvent('xn_banhnuoc:server:completeOrder', data.shopKey, data.orderId)
    cb({})
end)

-- =============================================
-- NPC OFFLINE SYSTEM - NUI callbacks
-- =============================================

RegisterNUICallback('hireNpc', function(data, cb)
    TriggerServerEvent('xn_banhnuoc:server:hireNpc', data.shopKey, data.hours)
    cb({})
end)

RegisterNUICallback('cancelNpc', function(data, cb)
    TriggerServerEvent('xn_banhnuoc:server:cancelNpc', data.shopKey)
    cb({})
end)

RegisterNUICallback('withdrawRevenue', function(data, cb)
    TriggerServerEvent('xn_banhnuoc:server:withdrawRevenue', data.shopKey)
    cb({})
end)

RegisterNUICallback('buyFromNpc', function(data, cb)
    debugPrint("DEBUG CLIENT: Mua từ NPC - shopKey:", data.shopKey, "items:", json.encode(data.items))
    TriggerServerEvent('xn_banhnuoc:server:buyFromNpc', data.shopKey, data.items)
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb({})
end)

-- Nhận cập nhật trạng thái NPC từ server
RegisterNetEvent('xn_banhnuoc:client:npcStatusUpdate', function(shopKey, npcStatus)
    SendNUIMessage({
        action = 'npcStatusUpdate',
        data   = { shopKey = shopKey, npcStatus = npcStatus }
    })
end)

-- =============================================
-- CRAFTING SYSTEM
-- =============================================

local isCraftingMenuOpen = false
local currentCraftingKey = nil
local craftingProp = nil

-- Đóng menu crafting
RegisterNUICallback('closeCrafting', function(data, cb)
    SetNuiFocus(false, false)
    isCraftingMenuOpen = false
    currentCraftingKey = nil
    cb({})
end)

-- Bắt đầu chế biến
RegisterNUICallback('startCraft', function(data, cb)
    SetNuiFocus(false, false)
    isCraftingMenuOpen = false
    
    local craftingKey = data.craftingKey
    local recipe = data.recipe
    local quantity = data.quantity or 1
    
    debugPrint("DEBUG CLIENT: Bắt đầu chế biến - craftingKey:", craftingKey, "recipe:", recipe.name, "quantity:", quantity)
    
    -- Gọi function thực hiện crafting
    StartCrafting(craftingKey, recipe, quantity)
    
    cb({})
end)

-- Function mở menu crafting
local function OpenCraftingMenu(craftingKey)
    if isCraftingMenuOpen then return end
    
    local craftConfig = Config.Crafting[craftingKey]
    if not craftConfig then return end
    
    debugPrint("DEBUG CLIENT: Mở crafting menu:", craftingKey)
    
    -- Lấy crafting data với labels từ server
    lib.callback('xn_banhnuoc:server:getCraftingData', false, function(data)
        if not data then 
            exports.qbx_core:Notify(_('wrong_job'), 'error', 3000)
            return 
        end
        
        SetNuiFocus(true, true)
        isCraftingMenuOpen = true
        currentCraftingKey = craftingKey
        
        local itemImageUrl = Config.GlobalSettings.itemImageUrl
        
        SendNUIMessage({
            action = 'openCrafting',
            data = {
                craftingKey = craftingKey,
                craftingLabel = craftConfig.label,
                recipes = data.recipes,
                playerItems = data.playerItems,
                itemImageUrl = itemImageUrl,
                maxQuantityPerCraft = Config.CraftingSettings.maxQuantityPerCraft or 10,
            }
        })
    end, craftingKey)
end

-- Function tạo prop
local function CreateCraftingProp(propConfig)
    if not propConfig or not propConfig.model then return nil end
    
    local ped = PlayerPedId()
    local propModel = propConfig.model
    
    -- Kiểm tra model hợp lệ
    if not IsModelValid(propModel) then
        debugPrint("DEBUG: Model không hợp lệ:", propModel)
        return nil
    end
    
    local success = lib.requestModel(propModel, 5000)
    if not success then
        debugPrint("DEBUG: Không thể load model:", propModel)
        return nil
    end
    
    local prop = CreateObject(propModel, 0.0, 0.0, 0.0, true, true, false)
    if not DoesEntityExist(prop) then return nil end
    
    local boneIndex = GetPedBoneIndex(ped, propConfig.bone or 28422)
    
    AttachEntityToEntity(
        prop, ped, boneIndex,
        propConfig.offset.x or 0.0, propConfig.offset.y or 0.0, propConfig.offset.z or 0.0,
        propConfig.rotation.x or 0.0, propConfig.rotation.y or 0.0, propConfig.rotation.z or 0.0,
        true, true, false, true, 1, true
    )
    
    return prop
end

-- Function xóa prop
local function DeleteCraftingProp()
    if craftingProp and DoesEntityExist(craftingProp) then
        DeleteEntity(craftingProp)
        craftingProp = nil
    end
end

-- Function thực hiện crafting
function StartCrafting(craftingKey, recipe, quantity)
    local craftConfig = Config.Crafting[craftingKey]
    if not craftConfig then return end
    
    local ped = PlayerPedId()
    local animConfig = craftConfig.animation
    local propConfig = animConfig and animConfig.prop
    local duration = (recipe.duration or 5000) * quantity
    
    -- Kiểm tra nguyên liệu trước khi bắt đầu
    lib.callback('xn_banhnuoc:server:checkCraftIngredients', false, function(canCraft, errorMsg)
        if not canCraft then
            exports.qbx_core:Notify(errorMsg or _('not_enough_ingredients'), 'error', 3000)
            return
        end
        
        -- Load animation
        if animConfig and animConfig.dict then
            lib.requestAnimDict(animConfig.dict, 5000)
        end
        
        -- Tạo prop nếu có
        if propConfig then
            craftingProp = CreateCraftingProp(propConfig)
        end
        
        -- Chơi animation
        if animConfig and animConfig.dict and animConfig.anim then
            TaskPlayAnim(ped, animConfig.dict, animConfig.anim, 8.0, -8.0, -1, animConfig.flag or 49, 0, false, false, false)
        end
        
        -- Progress bar
        local success = lib.progressBar({
            duration = duration,
            label = _('crafting_progress', recipe.label or recipe.name),
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false,
            },
        })
        
        -- Dọn dẹp
        ClearPedTasks(ped)
        DeleteCraftingProp()
        
        if success then
            -- Gửi lên server để xử lý
            TriggerServerEvent('xn_banhnuoc:server:completeCraft', craftingKey, recipe, quantity)
        else
            exports.qbx_core:Notify(_('crafting_cancelled'), 'error', 3000)
        end
    end, craftingKey, recipe, quantity)
end

-- Mở menu shop
local function OpenShopMenu(shopKey)
    if isMenuOpen then return end
    
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    local isEmployee = IsEmployeeOfShop(shopKey)
    
    -- Lấy itemImageUrl từ shop config hoặc global settings
    local itemImageUrl = shopConfig.itemImageUrl or Config.GlobalSettings.itemImageUrl
    -- Lấy shopIcon từ shop config hoặc global settings
    local shopIcon = shopConfig.shopIcon or Config.GlobalSettings.shopIcon
    
    debugPrint("DEBUG CLIENT: Mở menu shop:", shopKey, "isEmployee:", isEmployee)
    
    -- Lấy items và orders từ server
    lib.callback('xn_banhnuoc:server:getShopData', false, function(data)
        if not data then return end
        
        SetNuiFocus(true, true)
        isMenuOpen = true
        
        SendNUIMessage({
            action = 'openMenu',
            data = {
                isEmployee = isEmployee,
                shopKey    = shopKey,
                shopLabel  = _(shopConfig.label),
                shopIcon   = shopIcon,
                itemImageUrl = itemImageUrl,
                items      = data.items or {},
                orders     = data.orders or {},
                npcStatus  = data.npcStatus,
                npcSelling = data.npcSelling or false,
                isBoss     = data.isBoss or false,
            }
        })
    end, shopKey, isEmployee)
end

-- Event nhận đơn hàng mới (cho nhân viên)
RegisterNetEvent('xn_banhnuoc:client:newOrder', function(order)
    debugPrint("DEBUG CLIENT: Nhận đơn hàng mới:", json.encode(order))
    
    -- Hiển thị bell notification
    SendNUIMessage({
        action = 'newOrder',
        data = {
            order = order
        }
    })
    
    -- Thông báo
    exports.qbx_core:Notify(_('new_order_received'), 'info', 5000)
end)

-- Event cập nhật đơn hàng
RegisterNetEvent('xn_banhnuoc:client:orderUpdated', function(order)
    debugPrint("DEBUG CLIENT: Đơn hàng được cập nhật:", json.encode(order))
    
    SendNUIMessage({
        action = 'orderUpdated',
        data = {
            order = order
        }
    })
end)

-- Event đơn hàng bị xóa
RegisterNetEvent('xn_banhnuoc:client:orderRemoved', function(orderId)
    debugPrint("DEBUG CLIENT: Đơn hàng bị xóa:", orderId)
    
    SendNUIMessage({
        action = 'orderRemoved',
        data = {
            orderId = orderId
        }
    })
end)

-- Event hiển thị/ẩn bell cho nhân viên
RegisterNetEvent('xn_banhnuoc:client:updateBell', function(orders)
    debugPrint("DEBUG CLIENT: Cập nhật bell:", json.encode(orders))
    
    if orders and #orders > 0 then
        SendNUIMessage({
            action = 'showBell',
            data = {
                orders = orders
            }
        })
    else
        SendNUIMessage({
            action = 'hideBell',
            data = {}
        })
    end
end)

-- Event thông báo kết quả đặt hàng (cho khách)
RegisterNetEvent('xn_banhnuoc:client:orderPlaced', function(success, message)
    if success then
        exports.qbx_core:Notify(message, 'success', 5000)
    else
        exports.qbx_core:Notify(message, 'error', 5000)
    end
end)

-- Event thông báo đơn hàng hoàn thành (cho khách)
RegisterNetEvent('xn_banhnuoc:client:orderCompleted', function(message)
    exports.qbx_core:Notify(message, 'success', 5000)
end)

-- Event thông báo đơn hàng bị hủy (cho khách)
RegisterNetEvent('xn_banhnuoc:client:orderCancelled', function(message)
    exports.qbx_core:Notify(message, 'error', 5000)
end)

-- =============================================
-- BÁN HÀNG TRỰC TIẾP CHO PLAYER (giữ nguyên tính năng cũ)
-- =============================================

-- Hiển thị menu chọn item để bán
local function ShowSellItemMenu(targetPlayerId, shopKey, shopConfig)
    debugPrint("DEBUG CLIENT: ShowSellItemMenu - targetPlayerId:", targetPlayerId, "shopKey:", shopKey)
    
    lib.callback('xn_banhnuoc:server:getShopItems', false, function(items)
        if not items or #items == 0 then
            exports.qbx_core:Notify(_('no_items_in_shop'), 'error', 3000)
            return
        end
        
        local menuOptions = {}
        for _, item in ipairs(items) do
            menuOptions[#menuOptions + 1] = {
                title = item.label,
                description = string.format('Giá: %s$ | Còn: %d', lib.math.groupdigits(item.price), item.count),
                icon = 'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/' .. item.name .. '.webp',
                onSelect = function()
                    ShowQuantityDialog(targetPlayerId, shopKey, shopConfig, item)
                end,
                metadata = {
                    {label = 'Giá', value = lib.math.groupdigits(item.price) .. '$'},
                    {label = 'Số lượng trong kho', value = item.count}
                }
            }
        end
        
        lib.registerContext({
            id = 'rep_shop_sell_menu',
            title = _('select_item_to_sell'),
            options = menuOptions
        })
        lib.showContext('rep_shop_sell_menu')
    end, shopKey)
end

-- Menu Quản lý giá bán cho nhân viên (chỉ grade >= customPriceMinGrade)
local function OpenManagePricesMenu(shopKey)
    local jobName, onDuty = GetPlayerJob()
    if not jobName or not onDuty then return end

    lib.callback('xn_banhnuoc:server:getManagePrices', false, function(items)
        if items == nil then
            exports.qbx_core:Notify('Bạn không đủ cấp bậc để quản lý giá bán!', 'error', 3000)
            return
        end

        if #items == 0 then
            exports.qbx_core:Notify('Cửa hàng này chưa có vật phẩm nào được bật custom giá!', 'info', 3000)
            return
        end

        local menuOptions = {}
        for _, item in ipairs(items) do
            menuOptions[#menuOptions + 1] = {
                title = item.label,
                description = string.format('Giá hiện tại: %s$', lib.math.groupdigits(item.price)),
                icon = 'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/' .. item.name .. '.webp',
                onSelect = function()
                    local input = lib.inputDialog('Chỉnh giá: ' .. item.label, {
                        {
                            type = 'number',
                            label = 'Giá bán mới ($)',
                            description = 'Nhập giá mới cho ' .. item.label,
                            required = true,
                            min = 0,
                            default = item.price
                        }
                    })

                    if input and input[1] ~= nil then
                        local newPrice = tonumber(input[1])
                        if newPrice and newPrice >= 0 then
                            TriggerServerEvent('xn_banhnuoc:server:setCustomPrice', shopKey, item.name, newPrice)
                            Wait(400)
                            OpenManagePricesMenu(shopKey) -- Mở lại menu để xem giá đã đổi
                        else
                            exports.qbx_core:Notify('Giá không hợp lệ!', 'error', 3000)
                        end
                    end
                end,
                metadata = {
                    { label = 'Giá bán', value = lib.math.groupdigits(item.price) .. '$' }
                }
            }
        end

        local shopConfig = Config.Shops[shopKey]
        lib.registerContext({
            id = 'xn_shop_manage_prices',
            title = '🏷️ Quản Lý Giá Bán - ' .. _(shopConfig and shopConfig.label or shopKey),
            options = menuOptions
        })
        lib.showContext('xn_shop_manage_prices')
    end, shopKey)
end

-- Hiển thị dialog nhập số lượng (nếu item là custom thì cho phép chỉnh giá tại chỗ)
function ShowQuantityDialog(targetPlayerId, shopKey, shopConfig, item)
    debugPrint("DEBUG CLIENT: ShowQuantityDialog - item:", item.name, "maxCount:", item.count, "defaultPrice:", item.price, "isCustom:", item.isCustom)
    
    local fields = {
        {type = 'number', label = _('quantity'), description = 'Tối đa trong kho: ' .. item.count, required = true, min = 1, max = item.count, default = 1}
    }

    if item.isCustom then
        fields[#fields + 1] = {
            type = 'number',
            label = 'Đơn giá ($) [Tùy chỉnh]',
            description = 'Đơn giá mỗi món (Item custom - có thể chỉnh tùy ý)',
            required = true,
            min = 0,
            default = item.price
        }
    end

    local input = lib.inputDialog('Bán vật phẩm: ' .. item.label, fields)
    
    if not input then return end
    
    local quantity = tonumber(input[1])
    if not quantity or quantity < 1 then
        exports.qbx_core:Notify(_('invalid_quantity'), 'error', 3000)
        return
    end

    local price = item.price
    if item.isCustom then
        price = tonumber(input[2])
        if not price or price < 0 then
            exports.qbx_core:Notify('Đơn giá không hợp lệ!', 'error', 3000)
            return
        end
    end
    
    local totalPrice = price * quantity
    
    debugPrint("DEBUG CLIENT: Gửi yêu cầu bán - quantity:", quantity, "price:", price, "totalPrice:", totalPrice)
    
    TriggerServerEvent('rep_shop:server:requestSale', targetPlayerId, shopKey, item.name, quantity, price)
    exports.qbx_core:Notify(_('waiting_response'), 'info', 5000)
end

-- Event nhận yêu cầu mua từ nhân viên
RegisterNetEvent('rep_shop:client:receiveSaleOffer', function(employeeName, jobLabel, itemName, itemLabel, quantity, totalPrice, employeeId, shopKey)
    debugPrint("DEBUG CLIENT: Nhận offer bán hàng từ:", employeeName, "item:", itemName, "qty:", quantity)
    
    local alert = lib.alertDialog({
        header = _('sell_offer_title'),
        content = _('sell_offer_description', employeeName, jobLabel, quantity, itemLabel, lib.math.groupdigits(totalPrice)),
        centered = true,
        cancel = true,
        labels = {
            confirm = _('accept'),
            cancel = _('decline')
        }
    })
    
    if alert == 'confirm' then
        debugPrint("DEBUG CLIENT: Player đồng ý mua")
        TriggerServerEvent('rep_shop:server:confirmPurchase', employeeId, shopKey, itemName, quantity, totalPrice)
    else
        debugPrint("DEBUG CLIENT: Player từ chối mua")
        TriggerServerEvent('rep_shop:server:declinePurchase', employeeId)
    end
end)

-- Event nhận kết quả giao dịch (cho nhân viên)
RegisterNetEvent('rep_shop:client:saleResult', function(success, message)
    if success then
        exports.qbx_core:Notify(message, 'success', 5000)
    else
        exports.qbx_core:Notify(message, 'error', 5000)
    end
end)

-- Event nhận kết quả mua hàng (cho người mua)
RegisterNetEvent('rep_shop:client:purchaseResult', function(success, message)
    if success then
        exports.qbx_core:Notify(message, 'success', 5000)
    else
        exports.qbx_core:Notify(message, 'error', 5000)
    end
end)

-- =============================================
-- OX_TARGET ZONES
-- =============================================

-- Target cho player (nhân viên bán hàng trực tiếp)
exports.ox_target:addGlobalPlayer({
    {
        name = 'rep_shop_sell_to_player',
        icon = 'fas fa-hand-holding-usd',
        label = _('sell_to_player'),
        canInteract = function(entity, distance, coords, name, bone)
            local jobName, onDuty = GetPlayerJob()
            if not jobName or not onDuty then return false end
            
            local shopKey, shopConfig = GetShopByJob(jobName)
            return shopKey ~= nil
        end,
        onSelect = function(data)
            local jobName, _ = GetPlayerJob()
            local shopKey, shopConfig = GetShopByJob(jobName)
            
            if not shopKey then return end
            
            local playerIndex = NetworkGetPlayerIndexFromPed(data.entity)
            local targetPlayerId = GetPlayerServerId(playerIndex)
            debugPrint("DEBUG CLIENT: Ped:", data.entity, "PlayerIndex:", playerIndex, "ServerId:", targetPlayerId)
            
            if targetPlayerId == 0 then
                exports.qbx_core:Notify('Không thể xác định người chơi!', 'error', 3000)
                return
            end
            
            ShowSellItemMenu(targetPlayerId, shopKey, shopConfig)
        end
    }
})

-- Helper function chuyển đổi 1 coord (vec3) hoặc danh sách coords ({ vec3(...), ... }) thành table
local function toCoordsList(coordData)
    if not coordData then return {} end
    if type(coordData) == 'vector3' or (type(coordData) == 'table' and coordData.x) then
        return { coordData }
    elseif type(coordData) == 'table' then
        return coordData
    end
    return {}
end

-- Tạo ox_target zones và blips cho tất cả shops
for k, v in pairs(Config.Shops) do
    -- Lấy radius từ config hoặc dùng mặc định
    local orderRadius = (v.target_config and v.target_config.order_radius) or Config.GlobalSettings.defaultTargetRadius
    local stashRadius = (v.target_config and v.target_config.stash_radius) or Config.GlobalSettings.defaultTargetRadius
    
    -- Tạo blip nếu có config
    -- if v.blip then
    --     local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
    --     SetBlipSprite(blip, v.blip.sprite or 93)
    --     SetBlipDisplay(blip, v.blip.display or 4)
    --     SetBlipScale(blip, v.blip.scale or 0.7)
    --     SetBlipColour(blip, v.blip.color or 2)
    --     SetBlipAsShortRange(blip, true)
    --     BeginTextCommandSetBlipName("STRING")
    --     AddTextComponentString(_(v.label))
    --     EndTextCommandSetBlipName(blip)
    -- end
    
    -- Target cho coords - MỞ MENU ĐẶT HÀNG + TOGGLE DUTY (Hỗ trợ 1 hoặc nhiều tọa độ)
    local orderCoords = toCoordsList(v.coords)
    for idx, coord in ipairs(orderCoords) do
        local suffix = #orderCoords > 1 and ('_' .. idx) or ''
        exports.ox_target:addSphereZone({
            coords = coord,
            radius = orderRadius,
            options = {
                {
                    name = 'xn_shop_menu_' .. k .. suffix,
                    icon = 'fas fa-store',
                    label = _('open_shop_menu'),
                    onSelect = function()
                        OpenShopMenu(k)
                    end
                },
                {
                    name = 'xn_toggle_duty_' .. k .. suffix,
                    icon = 'fas fa-clipboard-check',
                    label = _('toggle_duty'),
                    groups = v.job,
                    onSelect = function()
                        TriggerServerEvent('QBCore:ToggleDuty')
                    end
                },
                {
                    name = 'xn_manage_prices_' .. k .. suffix,
                    icon = 'fas fa-tags',
                    label = 'Quản lý giá bán',
                    groups = v.job,
                    canInteract = function()
                        local playerData = exports.qbx_core:GetPlayerData()
                        if not playerData or not playerData.job then return false end
                        if playerData.job.name ~= v.job then return false end
                        if not playerData.job.onduty then return false end
                        local grade = playerData.job.grade and playerData.job.grade.level or 0
                        local minGrade = v.customPriceMinGrade or (Config.GlobalSettings and Config.GlobalSettings.defaultCustomPriceMinGrade) or 4
                        return grade >= minGrade
                    end,
                    onSelect = function()
                        OpenManagePricesMenu(k)
                    end
                }
            }
        })
    end

    -- Tạo target cho stash - kho lưu trữ chính (chỉ có job và đủ cấp bậc mới mở được)
    local stashMinGrade = v.stash_config and v.stash_config.minGrade or 0
    local stashCoords = toCoordsList(v.stash)
    for idx, coord in ipairs(stashCoords) do
        local suffix = #stashCoords > 1 and ('_' .. idx) or ''
        exports.ox_target:addSphereZone({
            coords = coord,
            radius = stashRadius,
            options = {
                {
                    name = 'rep_shop_stash_' .. k .. suffix,
                    icon = 'fas fa-box',
                    label = _('access_stash'),
                    groups = v.job,
                    canInteract = function()
                        local playerData = exports.qbx_core:GetPlayerData()
                        if not playerData or not playerData.job then return false end
                        if playerData.job.name ~= v.job then return false end
                        if not playerData.job.onduty then return false end
                        local grade = playerData.job.grade and playerData.job.grade.level or 0
                        return grade >= stashMinGrade
                    end,
                    onSelect = function()
                        exports.ox_inventory:openInventory('stash', k)
                    end
                }
            }
        })
    end

    -- Tạo target cho stash_sell - kho bán hàng ra ngoài
    if v.stash_sell then
        local sellStashMinGrade = v.stash_sell_config and v.stash_sell_config.minGrade or 0
        local sellStashCoords = toCoordsList(v.stash_sell)
        for idx, coord in ipairs(sellStashCoords) do
            local suffix = #sellStashCoords > 1 and ('_' .. idx) or ''
            exports.ox_target:addSphereZone({
                coords = coord,
                radius = stashRadius,
                options = {
                    {
                        name = 'rep_shop_stash_sell_' .. k .. suffix,
                        icon = 'fas fa-shopping-basket',
                        label = _('access_stash') .. ' (Bán)',
                        groups = v.job,
                        canInteract = function()
                            local playerData = exports.qbx_core:GetPlayerData()
                            if not playerData or not playerData.job then return false end
                            if playerData.job.name ~= v.job then return false end
                            if not playerData.job.onduty then return false end
                            local grade = playerData.job.grade and playerData.job.grade.level or 0
                            return grade >= sellStashMinGrade
                        end,
                        onSelect = function()
                            exports.ox_inventory:openInventory('stash', k .. '_sell')
                        end
                    },
                    {
                        name = 'rep_shop_manage_prices_sell_' .. k .. suffix,
                        icon = 'fas fa-tags',
                        label = 'Quản lý giá bán',
                        groups = v.job,
                        canInteract = function()
                            local playerData = exports.qbx_core:GetPlayerData()
                            if not playerData or not playerData.job then return false end
                            if playerData.job.name ~= v.job then return false end
                            if not playerData.job.onduty then return false end
                            local grade = playerData.job.grade and playerData.job.grade.level or 0
                            local minGrade = v.customPriceMinGrade or (Config.GlobalSettings and Config.GlobalSettings.defaultCustomPriceMinGrade) or 4
                            return grade >= minGrade
                        end,
                        onSelect = function()
                            OpenManagePricesMenu(k)
                        end
                    }
                }
            })
        end
    end
end

-- Tạo ox_target zones cho các bàn chế tạo (crafting)
if Config.Crafting then
    for craftId, craftConfig in pairs(Config.Crafting) do
        local craftRadius = craftConfig.target_radius or Config.GlobalSettings.defaultTargetRadius
        local craftMinGrade = craftConfig.minGrade or 0
        local craftCoords = toCoordsList(craftConfig.coords)

        for idx, coord in ipairs(craftCoords) do
            local suffix = #craftCoords > 1 and ('_' .. idx) or ''
            local targetOptions = {
                {
                    name = 'xn_crafting_' .. craftId .. suffix,
                    icon = 'fas fa-mortar-pestle',
                    label = craftConfig.label or 'Chế tạo',
                    canInteract = function()
                        if not craftConfig.job then return true end  -- Nếu không có job restriction
                        local playerData = exports.qbx_core:GetPlayerData()
                        if not playerData or not playerData.job then return false end
                        if playerData.job.name ~= craftConfig.job then return false end
                        if not playerData.job.onduty then return false end
                        local grade = playerData.job.grade and playerData.job.grade.level or 0
                        return grade >= craftMinGrade
                    end,
                    onSelect = function()
                        OpenCraftingMenu(craftId)
                    end
                }
            }
            
            -- Thêm job restriction nếu có
            if craftConfig.job then
                targetOptions[1].groups = craftConfig.job
            end
            
            exports.ox_target:addSphereZone({
                coords = coord,
                radius = craftRadius,
                options = targetOptions
            })
            
            debugPrint("Tạo crafting zone:", craftId, "tại", coord)
        end
    end
end

-- Khi player load xong, kiểm tra nếu là nhân viên thì hiển thị bell
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    
    local jobName, onDuty = GetPlayerJob()
    if not jobName or not onDuty then return end
    
    local shopKey, _ = GetShopByJob(jobName)
    if shopKey then
        TriggerServerEvent('xn_banhnuoc:server:getEmployeeOrders', shopKey)
    end
end)

-- Khi player đổi job/duty
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Wait(500)
    
    if not job.onduty then
        SendNUIMessage({
            action = 'hideBell',
            data = {}
        })
        return
    end
    
    local shopKey, _ = GetShopByJob(job.name)
    if shopKey then
        TriggerServerEvent('xn_banhnuoc:server:getEmployeeOrders', shopKey)
    end
end)