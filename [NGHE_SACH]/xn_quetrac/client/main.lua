local QBX = exports.qbx_core
local activeTrashPoints = {}
local isCollecting = false
local isRecycling = false

-- Mission variables
local onMission = false
local currentMissionStep = 0
local missionBlip = nil

-- Tạo ox_target điểm dọn rác (mua chổi / nhận nhiệm vụ)
exports.ox_target:addBoxZone({
    coords = vec3(Config.BroomShop.coords.x, Config.BroomShop.coords.y, Config.BroomShop.coords.z),
    size = vec3(2.0, 2.0, 2.0),
    rotation = Config.BroomShop.coords.w or 0,
    debug = false,
    options = {
        {
            name = 'buy_broom',
            icon = 'fas fa-shopping-cart',
            label = 'Mua Chổi Dọn Rác ($' .. Config.BroomShop.price .. ')',
            onSelect = function()
                BuyBroom()
            end
        },
        {
            name = 'start_mission',
            icon = 'fas fa-clipboard-list',
            label = 'Nhận Nhiệm Vụ Dọn Rác',
            onSelect = function()
                StartMission()
            end,
            canInteract = function()
                return not onMission and Config.MissionEnabled and exports.ox_inventory:Search('count', Config.Items.broom) > 0
            end
        },
        {
            name = 'stop_mission',
            icon = 'fas fa-clipboard-check',
            label = 'Kết Thúc Nhiệm Vụ',
            onSelect = function()
                StopMission()
            end,
            canInteract = function()
                return onMission
            end
        }
    }
})

-- Tạo blips
CreateThread(function()
    if not Config.ShowBlips then return end
    
    -- Blip cửa hàng chổi
    local shopBlip = AddBlipForCoord(Config.BroomShop.coords.x, Config.BroomShop.coords.y, Config.BroomShop.coords.z)
    SetBlipSprite(shopBlip, Config.Blips.shop.sprite)
    SetBlipColour(shopBlip, Config.Blips.shop.color)
    SetBlipScale(shopBlip, Config.Blips.shop.scale)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.shop.label)
    EndTextCommandSetBlipName(shopBlip)
    
    -- Blip khu xử lý rác
    local recycleBlip = AddBlipForCoord(Config.RecycleLocation.coords.x, Config.RecycleLocation.coords.y, Config.RecycleLocation.coords.z)
    SetBlipSprite(recycleBlip, Config.Blips.recycle.sprite)
    SetBlipColour(recycleBlip, Config.Blips.recycle.color)
    SetBlipScale(recycleBlip, Config.Blips.recycle.scale)
    SetBlipAsShortRange(recycleBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.recycle.label)
    EndTextCommandSetBlipName(recycleBlip)
end)

-- Tạo ox_target cho khu xử lý rác
exports.ox_target:addBoxZone({
    coords = Config.RecycleLocation.coords,
    size = vec3(3, 3, 2),
    rotation = 0,
    debug = false,
    options = {
        {
            name = 'recycle_trash',
            icon = 'fas fa-recycle',
            label = 'Xử Lý Rác',
            canInteract = function()
                return exports.ox_inventory:Search('count', Config.Items.trash) > 0
            end,
            onSelect = function()
                RecycleTrash()
            end
        }
    }
})

-- Function mua chổi
function BuyBroom()
    if isCollecting or isRecycling then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn đang bận!',
            type = 'error'
        })
        return
    end

    local hasItem = exports.ox_inventory:Search('count', Config.Items.broom) > 0
    if hasItem then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn đã có chổi rồi!',
            type = 'error'
        })
        return
    end

    lib.callback('xn_quetrac:server:buyBroom', false, function(success)
        if success then
            lib.notify({
                title = 'Thành Công',
                description = 'Bạn đã mua chổi với giá $' .. Config.BroomShop.price,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Thất Bại',
                description = 'Bạn không đủ tiền!',
                type = 'error'
            })
        end
    end)
end

-- Khởi tạo dữ liệu trash points (không spawn prop)
for i, coords in ipairs(Config.TrashLocations) do
    local trashId = 'trash_' .. i
    activeTrashPoints[trashId] = {
        coords = coords,
        collected = false,
        prop = nil
    }
end

-- Function spawn prop rác
function SpawnTrashProp(trashId)
    local trashPoint = activeTrashPoints[trashId]
    if not trashPoint then return end
    
    -- Xóa prop cũ nếu tồn tại
    if trashPoint.prop and DoesEntityExist(trashPoint.prop) then
        DeleteEntity(trashPoint.prop)
    end
    
    lib.requestModel(Config.TrashProp.model)
    
    local coords = trashPoint.coords
    local prop = CreateObject(GetHashKey(Config.TrashProp.model), coords.x, coords.y, coords.z + Config.TrashProp.zOffset, false, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, true)
    
    trashPoint.prop = prop
    trashPoint.collected = false -- Reset trạng thái
end

-- Function xóa prop rác
function DeleteTrashProp(trashId)
    local trashPoint = activeTrashPoints[trashId]
    if not trashPoint or not trashPoint.prop then return end
    
    if DoesEntityExist(trashPoint.prop) then
        DeleteEntity(trashPoint.prop)
    end
    trashPoint.prop = nil
end

-- Hệ thống bấm E để gom rác (tối ưu chỉ check khi có nhiệm vụ)
CreateThread(function()
    local isShowingUI = false
    
    while true do
        local sleep = 1000
        
        -- Chỉ check khi đang có nhiệm vụ
        if onMission and currentMissionStep > 0 and not isCollecting and not isRecycling then
            local playerPed = cache.ped
            local playerCoords = GetEntityCoords(playerPed)
            local trashId = 'trash_' .. currentMissionStep
            local trashPoint = activeTrashPoints[trashId]
            
            -- Kiểm tra player không ngồi trên xe
            local isInVehicle = IsPedInAnyVehicle(playerPed, false)
            
            if trashPoint and not trashPoint.collected and trashPoint.prop and DoesEntityExist(trashPoint.prop) and not isInVehicle then
                local distance = #(playerCoords - trashPoint.coords)
                
                if distance < Config.DrawDistance then
                    sleep = 0
                    
                    if not isShowingUI then
                        lib.showTextUI('[E] Quét Rác', {
                            position = "left-center",
                            icon = 'trash'
                        })
                        isShowingUI = true
                    end
                    
                    if distance < Config.InteractDistance and IsControlJustReleased(0, 38) then -- E key
                        lib.hideTextUI()
                        isShowingUI = false
                        exports.XN_DevMode:RemoveDurability('dohotrac')
                        CollectTrash(trashId)
                    end
                elseif isShowingUI then
                    lib.hideTextUI()
                    isShowingUI = false
                end
            elseif isShowingUI then
                lib.hideTextUI()
                isShowingUI = false
            end
        elseif isShowingUI then
            lib.hideTextUI()
            isShowingUI = false
        end
        
        Wait(sleep)
    end
end)

-- Mission Functions
function StartMission()
    if onMission then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn đang trong nhiệm vụ!',
            type = 'error'
        })
        return
    end

    local hasBroom = exports.ox_inventory:Search('count', Config.Items.broom) > 0
    if not hasBroom then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn cần có chổi để nhận nhiệm vụ!',
            type = 'error'
        })
        return
    end

    onMission = true
    
    -- Chọn 1 vị trí cố định cho người chơi này
    currentMissionStep = math.random(1, #Config.TrashLocations)

    lib.notify({
        title = 'Nhiệm Vụ Bắt Đầu',
        description = 'Hãy đến vị trí được đánh dấu để dọn rác! Dọn liên tục tại đó. Quay lại gặp NPC để kết thúc.',
        type = 'success',
        duration = 7000
    })

    -- Spawn prop tại vị trí cố định
    SpawnTrashProp('trash_' .. currentMissionStep)
    UpdateMissionBlip()
end

function UpdateMissionBlip()
    -- Xóa blip cũ
    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end

    -- Tạo blip mới cho vị trí hiện tại
    if currentMissionStep <= #Config.TrashLocations then
        local coords = Config.TrashLocations[currentMissionStep]
        missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(missionBlip, Config.Blips.mission.sprite)
        SetBlipColour(missionBlip, Config.Blips.mission.color)
        SetBlipScale(missionBlip, Config.Blips.mission.scale)
        SetBlipRoute(missionBlip, true)
        SetBlipRouteColour(missionBlip, Config.Blips.mission.color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blips.mission.label)
        EndTextCommandSetBlipName(missionBlip)
    end
end

function StopMission()
    if not onMission then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn không có nhiệm vụ nào!',
            type = 'error'
        })
        return
    end

    -- Kiểm tra số lượng rác
    local trashCount = exports.ox_inventory:Search('count', Config.Items.trash)
    
    -- Xóa blip
    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    
    -- Xóa tất cả props còn lại
    for trashId, trashPoint in pairs(activeTrashPoints) do
        if trashPoint.prop then
            DeleteTrashProp(trashId)
        end
    end

    -- Thông báo tùy theo có rác hay không
    if trashCount > 0 then
        lib.notify({
            title = 'Kết Thúc Nhiệm Vụ',
            description = 'Bạn đã dọn được ' .. trashCount .. ' bãi rác! Hãy đem đi xử lý để nhận thưởng.',
            type = 'success',
            duration = 5000
        })
    else
        lib.notify({
            title = 'Kết Thúc Nhiệm Vụ',
            description = 'Đã kết thúc nhiệm vụ dọn rác.',
            type = 'info'
        })
    end
    
    onMission = false
    currentMissionStep = 0
end

-- Function quét rác
function CollectTrash(trashId)
    if isCollecting or isRecycling then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn đang bận!',
            type = 'error'
        })
        return
    end

    -- Kiểm tra nếu player đang ngồi trên xe
    local playerPed = cache.ped
    if IsPedInAnyVehicle(playerPed, false) then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn không thể quét rác khi đang ngồi trên xe!',
            type = 'error'
        })
        return
    end

    local trashPoint = activeTrashPoints[trashId]
    if trashPoint.collected then
        lib.notify({
            title = 'Thông Báo',
            description = 'Đã quét rác ở đây rồi!',
            type = 'error'
        })
        return
    end

    isCollecting = true
    local HasItem =  exports.ox_inventory:Search('count', Config.Items.broom)
    if HasItem > 0 then
        -- Progress bar với animation và prop tích hợp
        if lib.progressBar({
            duration = Config.TrashCollectTime,
            label = 'Đang quét rác...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = 'amb@world_human_janitor@male@idle_a',
                clip = 'idle_a'
            },
            prop = {
                model = 'prop_tool_broom',
                bone = 28422,
                pos = vec3(0.0, 0.0, 0.0),
                rot = vec3(0.0, 0.0, 0.0)
            }
        }) then
            
            -- Gọi server để nhận rác
            lib.callback('xn_quetrac:server:collectTrash', false, function(success)
                if success then
                    trashPoint.collected = true
                    
                    -- Nếu đang làm nhiệm vụ
                    if onMission then
                        lib.notify({
                            title = 'Thành Công',
                            description = 'Đã dọn rác! Điểm tiếp theo đã được đánh dấu.',
                            type = 'success'
                        })
                        
                        -- Xóa prop tại vị trí cũ
                        DeleteTrashProp(trashId)
                        
                        -- Chọn vị trí mới ngẫu nhiên khác vị trí hiện tại
                        local nextStep = currentMissionStep
                        if #Config.TrashLocations > 1 then
                            repeat
                                nextStep = math.random(1, #Config.TrashLocations)
                            until nextStep ~= currentMissionStep
                        else
                            nextStep = 1
                        end
                        currentMissionStep = nextStep
                        
                        -- Cập nhật Blip dẫn đường mới
                        UpdateMissionBlip()
                        
                        -- Spawn prop tại vị trí mới sau 3 giây
                        SetTimeout(3000, function()
                            if onMission and currentMissionStep > 0 then
                                SpawnTrashProp('trash_' .. currentMissionStep)
                            end
                        end)
                    else
                        lib.notify({
                            title = 'Thành Công',
                            description = 'Bạn đã nhặt được rác!',
                            type = 'success'
                        })
                        
                        -- Reset sau 10 phút (không có nhiệm vụ thì không có prop)
                        SetTimeout(600000, function()
                            trashPoint.collected = false
                        end)
                    end
                else
                    lib.notify({
                        title = 'Thất Bại',
                        description = 'Không thể nhặt rác!',
                        type = 'error'
                    })
                end
            end)
        else
            lib.notify({
                title = 'Thông Báo',
                description = 'Đã hủy!',
                type = 'error'
            })
        end
    else
         lib.notify({
            title = 'Thông Báo',
            description = 'Không có chổi để quét !',
            type = 'error'
        })
    end
    
    isCollecting = false
end

-- Function xử lý rác
function RecycleTrash()

     -- Check if player is in a vehicle
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.Notify('Không thể lục rác khi đang ngồi trên xe!', 'error')
        return
    end

    if isCollecting or isRecycling then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn đang bận!',
            type = 'error'
        })
        return
    end

    local trashCount = exports.ox_inventory:Search('count', Config.Items.trash)
    if trashCount <= 0 then
        lib.notify({
            title = 'Thông Báo',
            description = 'Bạn không có rác!',
            type = 'error'
        })
        return
    end

    isRecycling = true
    
    -- Progress bar với animation tích hợp
    if lib.progressBar({
        duration = Config.RecycleTime,
        label = 'Đang xử lý rác...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    }) then
        
        -- Gọi server để xử lý 1 rác
        lib.callback('xn_quetrac:server:recycleTrash', false, function(success, reward)
            if success then
                local rewardText
                if reward.rare and reward.rareItem then
                    rewardText = 'Đã phân loại 1 rác! Nhận: 1x ' .. reward.rareItem.label
                else
                    rewardText = 'Đã phân loại 1 rác! Nhận: 1x Nhựa Tái Chế'
                end
                
                lib.notify({
                    title = 'Phân Loại Rác',
                    description = rewardText,
                    type = 'success',
                    duration = 7000
                })
            else
                lib.notify({
                    title = 'Thất Bại',
                    description = 'Không có rác để phân loại!',
                    type = 'error'
                })
            end
        end)
    else
        lib.notify({
            title = 'Thông Báo',
            description = 'Đã hủy!',
            type = 'error'
        })
    end
    
    isRecycling = false
end

-- Cleanup khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Xóa props rác
    for _, trashPoint in pairs(activeTrashPoints) do
        if trashPoint.prop and DoesEntityExist(trashPoint.prop) then
            DeleteEntity(trashPoint.prop)
        end
    end
    
    -- Xóa blip nhiệm vụ
    if missionBlip then
        RemoveBlip(missionBlip)
    end
    
    -- Ẩn text UI
    lib.hideTextUI()
end)
