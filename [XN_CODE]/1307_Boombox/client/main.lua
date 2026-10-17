local currentData = nil
local check_use_boombox = false
local sudung_boombox_1 = false
local sudung_boombox_2 = false
local sudung_boombox_3 = false
local sudung_boombox_4 = false
local sudung_boombox_5 = false
local sudung_boombox_6 = false
local streamMode = false -- Trạng thái stream mode để tắt âm thanh boombox

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local result = lib.callback.await('1307_Boombox:server:CheckMission', 2000, "boombox_active")
    if not result then
        return 
    end
    Check_Task_BoomBox = result
end)

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

CreateThread(function()
    local models = {}
    for _, v in pairs(Config.Boombox) do
        if v.Model then
            models[#models + 1] = v.Model
            models[#models + 1] = joaat(v.Model)
            models[#models + 1] = GetHashKey(v.Model)
        end
    end

    exports.ox_target:addModel(models, {
        {
            name = "boombox_interact",
            distance = 2.0,
            icon = "fas fa-music",
            label = "Tương tác loa",
            onSelect = function(data)
                TriggerEvent('1307_Boombox:client:playMusic', data)
            end
        },
        {
            name = "boombox_admin",
            distance = 2.5,
            icon = "fas fa-shield-halved",
            label = "🛡️ Kiểm tra thông tin (Admin)",
            onSelect = function(data)
                TriggerEvent('1307_Boombox:client:adminInspect', data.entity)
            end
        }
    })
end)

local function showProgress(label, duration)
    return lib.progressCircle({
        duration = duration, 
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
        label = label,
    })
end

for k,v in pairs(Config.Boombox) do
    local object = nil
    RegisterNetEvent(''..v.itemname..':SPAWN')
    AddEventHandler(''..v.itemname..':SPAWN', function(CurrentZone)
        --============================== PROGRESS BAR ==============================
        local owned = lib.callback.await('1307_Boombox:server:Permission_BoomBox', 2000)
        print(owned) -- Bây giờ sẽ in ra `true` hoặc `false`
        if not owned then
            return exports.qbx_core:Notify('Bạn chưa có quyền hạn sử dụng Boombox', 'warning', 10000)
        end
        
        if QBX.PlayerData.metadata["boombox_active"] == nil then
            TriggerServerEvent("1307_Boombox:server:Boombox_Active")
        else
            if check_use_boombox == false then
                if showProgress("Sử dụng boombox", math.random(1000,2000)) then
                    loadAnimDict("anim@heists@money_grab@briefcase")
                    TaskPlayAnim(PlayerPedId(), "anim@heists@money_grab@briefcase", "put_down_case", 8.0, -8.0, -1, 1, 0, false, false, false)
                    Wait(1000)
                    ClearPedTasks(PlayerPedId())
                    local coords = GetEntityCoords(PlayerPedId())
                    local heading = GetEntityHeading(PlayerPedId())
                    local forward = GetEntityForwardVector(PlayerPedId())
                    local x, y, z = table.unpack(coords + forward * 1.0)

                    local object = CreateObject(GetHashKey(CurrentZone.Model), x, y, z-1, true, true, true)
                    SetEntityHeading(object, (heading + 180.0) % 360.0)
                    FreezeEntityPosition(object, true)
                    currentData = NetworkGetNetworkIdFromEntity(object)
                    exports.qbx_core:Notify('Âm lượng đã được đặt mặc định là 0.05<br>Lưu ý: Đi quá xa thì Boombox sẽ tự động xóa', 'warning', 10000)
                    sudung_boombox_1 = true
                    TriggerServerEvent("1307_Boombox:server:RemoveItem", CurrentZone.itemname, 1)
                    check_use_boombox = true
                    TriggerServerEvent("1307_Boombox:server:registerBoombox", currentData, CurrentZone.itemname, CurrentZone.Model, coords)
                else 
                    exports.qbx_core:Notify('Bạn đã ngưng quá trình sử dụng', 'warning', 10000)
                    check_use_boombox = false
                end
            else
                exports.qbx_core:Notify('Bạn đã đặt Boombox ở đâu đó rồi không thể đặt thêm', 'error', 5000)
            end
        end
        --=============================================================================
    end)
end
RegisterNetEvent('1307_Boombox:client:playMusic', function(data)
    if data and data.entity then
        currentData = NetworkGetNetworkIdFromEntity(data.entity)
    end
    if QBX.PlayerData.metadata["boombox_active"] == 1 then
        local allowedItems = {
            {
                title = '🎶 | PHÁT NHẠC',
                description = 'Nhập URL Youtube',
                onSelect = function(option)
                    TriggerEvent('1307_Boombox:client:musicMenu')
                end
            },
            {
                title = '⏹️ | DỪNG PHÁT NHẠC',
                description = 'Dừng bài hát đang phát',
                onSelect = function(option)
                    TriggerServerEvent('1307_Boombox:server:stopMusic', currentData)
                    exports.qbx_core:Notify('Đã dừng phát nhạc!', 'info', 5000)
                end
            },
            {
                title = '⏸️ | TẠM DỪNG PHÁT NHẠC',
                description = 'Tạm dừng nhạc hiện đang phát',
                onSelect = function(option)
                    TriggerServerEvent('1307_Boombox:server:pauseMusic', currentData)
                    exports.qbx_core:Notify('Đã tạm dừng nhạc!', 'info', 5000)
                end
            },
            {
                title = '▶️ | TIẾP TỤC PHÁT NHẠC',
                description = 'Tiếp tục phát nhạc đã tạm dừng',
                onSelect = function(option)
                    TriggerServerEvent('1307_Boombox:server:resumeMusic', currentData)
                    exports.qbx_core:Notify('Đã tiếp tục phát nhạc!', 'info', 5000)
                end
            },
            {
                title = '🔈 | THAY ĐỔI ÂM LƯỢNG',
                description = 'Thay đổi âm lượng của loa',
                onSelect = function(option)
                    TriggerEvent('1307_Boombox:client:changeVolume')
                end
            },
            {
                title = '❌ | NHẶT LÊN',
                description = 'Dừng phát nhạc và nhặt lên',
                onSelect = function(option)
                    TriggerEvent('1307_Boombox:client:pickupBoombox')
                end
            },
        }
        lib.registerContext({
            id = '1307_Boombox',
            title = "💿 | MÁY NGHE NHẠC",
            options = {
                { readOnly = true, title = "Hãy chọn Option bạn muốn !", description = "" },
                table.unpack(allowedItems)
            }
        })
        lib.showContext('1307_Boombox')
    else
        exports.qbx_core:Notify('Bạn không có quyền sử dụng Boombox này!', 'error', 5000)
    end
end)

RegisterNetEvent('1307_Boombox:client:musicMenu', function()
    local input = lib.inputDialog("Nhập Link bài hát", {
        {
            type = "input",
            label = 'Bạn hãy lấy đường link nhạc trên Youtube',
            description = "Đường dẫn URL",
            icon = "music",
        }
    })
    local CheckInput = input and input[1]
    if not CheckInput then 
        return 
    end
    TriggerServerEvent('1307_Boombox:server:playMusic', CheckInput, currentData, GetEntityCoords(NetworkGetEntityFromNetworkId(currentData)))

end)

RegisterNetEvent('1307_Boombox:client:changeVolume', function()
    local input = lib.inputDialog("Âm lượng nhạc", {
        {
            type = "slider",
            label = 'Chỉnh âm lượng',
            description = "Kéo để điều chỉnh âm lượng từ 0 đến 20",
            icon = "volume-up",
            min = 0,
            max = 20,
            default = 5,
            step = 1
        }
    })
    local CheckInput = input and input[1]
    if not CheckInput then 
        return 
    end
    -- Chuyển đổi giá trị từ 0-20 về 0.0-1.0 cho âm lượng thực tế
    local volumeLevel = CheckInput / 20
    TriggerServerEvent('1307_Boombox:server:changeVolume', volumeLevel, currentData, GetEntityCoords(NetworkGetEntityFromNetworkId(currentData)))

end)

RegisterNetEvent('1307_Boombox:client:pickupBoombox', function()
    local obj = NetworkGetEntityFromNetworkId(currentData)
    local objCoords = GetEntityCoords()
    NetworkRequestControlOfEntity(obj)
    loadAnimDict("anim@heists@narcotics@trash")
    TaskPlayAnim(PlayerPedId(), "anim@heists@narcotics@trash", "pickup", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(700)
    SetEntityAsMissionEntity(obj,false,true)
    DeleteEntity(obj)
    DeleteObject(obj)
    if not DoesEntityExist(obj) then
        TriggerServerEvent("1307_Boombox:server:pickedup", currentData)
        local sudung_boombox_1 = false
        local sudung_boombox_2 = false
        local sudung_boombox_3 = false
        local sudung_boombox_4 = false
        local sudung_boombox_5 = false
        local sudung_boombox_6 = false
        TriggerServerEvent("1307_Boombox:server:AddItem", "boombox_1", 1)
        check_use_boombox = false
        sudung_boombox_1 = false
        currentData = nil
    end
    Wait(500)
    ClearPedTasks(PlayerPedId())
end)

-- Lệnh tắt/bật âm thanh boombox chỉ cho riêng người dùng (Client-side / Streamer Mode)
RegisterCommand('muteboombox', function()
    -- Bật/tắt chế độ Streamer (chỉ tắt âm thanh trên máy của người dùng, người khác vẫn nghe bình thường)
    ExecuteCommand('streamermode')
    Wait(150)
    local isMuted = exports.xsound:isPlayerInStreamerMode()
    if isMuted then
        exports.qbx_core:Notify('🔇 Bạn đã TẮT âm thanh từ Boombox (Người khác vẫn nghe)', 'success', 5000)
    else
        exports.qbx_core:Notify('🔊 Bạn đã BẬT lại âm thanh từ Boombox', 'info', 5000)
    end
end, false)

-- Lệnh dừng phát bài hát hiện tại trên Boombox của mình (cho tất cả mọi người xung quanh)
-- RegisterCommand('dungnhac', function()
--     if currentData then
--         TriggerServerEvent('1307_Boombox:server:stopMusic', currentData)
--         exports.qbx_core:Notify('Đã dừng phát nhạc Boombox!', 'info', 5000)
--     else
--         exports.qbx_core:Notify('Bạn không có Boombox nào đang phát!', 'error', 5000)
--     end
-- end, false)


CreateThread(function()
	while true do
        if check_use_boombox then
            local Ped = PlayerPedId()
            local pCoord = GetEntityCoords(Ped)
            local obj = NetworkGetEntityFromNetworkId(currentData)
            local objCoords = GetEntityCoords(obj)
            if #(pCoord - objCoords) > 25.0 then
                exports.qbx_core:Notify('Bạn đang đi quá xa Boombox nếu tiếp tục đi Boombox sẽ bị xóa', 'warning', 5000)
            end
            if #(pCoord - objCoords) > 30.0 then
                NetworkRequestControlOfEntity(obj)
                Wait(700)
                SetEntityAsMissionEntity(obj,false,true)
                DeleteEntity(obj)
                TriggerServerEvent("1307_Boombox:server:pickedup", currentData)
                if sudung_boombox_1 == true then
                    check_use_boombox = false
                    sudung_boombox_1 = false
                elseif sudung_boombox_2 == true then
                    check_use_boombox = false
                    sudung_boombox_2 = false
                elseif sudung_boombox_3 == true then
                    check_use_boombox = false
                    sudung_boombox_3 = false
                elseif sudung_boombox_4 == true then
                    check_use_boombox = false
                    sudung_boombox_4 = false
                elseif sudung_boombox_5 == true then
                    check_use_boombox = false
                    sudung_boombox_5 = false
                elseif sudung_boombox_6 == true then
                    check_use_boombox = false
                    sudung_boombox_6 = false
                end
                currentData = nil
                Wait(500)
                ClearPedTasks(PlayerPedId())
                exports.qbx_core:Notify('Boombox bị xóa do bạn đã đi quá xa!', 'error', 5000)
            end
        end
        Wait(1000)
	end
end)

-- ===================================================================================
-- ADMIN FEATURES: KIỂM TRA THÔNG TIN & XÓA PROP BOOMBOX
-- ===================================================================================

RegisterNetEvent('1307_Boombox:client:adminInspect', function(entity)
    if not entity or not DoesEntityExist(entity) then
        return exports.qbx_core:Notify('Không tìm thấy đối tượng Boombox!', 'error', 5000)
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if not netId or netId == 0 then
        if not NetworkGetEntityIsNetworked(entity) then
            NetworkRegisterEntityAsNetworked(entity)
            netId = NetworkGetNetworkIdFromEntity(entity)
        end
    end

    local coords = GetEntityCoords(entity)
    local info = lib.callback.await('1307_Boombox:server:getBoomboxInfo', false, netId)
    
    if info and info.isNotAdmin then
        return exports.qbx_core:Notify('Bạn không có quyền Admin để xem thông tin Boombox!', 'error', 5000)
    end

    local options = {}

    if not info or not info.hasData then
        options = {
            {
                title = "🆔 ID Người đặt: Không rõ",
                description = "Dữ liệu người đặt không tồn tại",
                icon = "id-card",
                readOnly = true,
            },
            {
                title = "🗑️ XÓA BOOMBOX",
                description = "Xóa prop boombox và tắt âm thanh",
                icon = "trash-can",
                iconColor = "#FF4C4C",
                onSelect = function()
                    TriggerEvent('1307_Boombox:client:confirmDeleteBoombox', netId, coords)
                end
            }
        }
    else
        options = {
            {
                title = "🆔 ID Người đặt: " .. tostring(info.source or "Không rõ"),
                description = "Player ID đặt chiếc Boombox này",
                icon = "id-card",
                readOnly = true,
            },
            {
                title = "🗑️ XÓA BOOMBOX",
                description = "Xóa prop boombox và tắt âm thanh",
                icon = "trash-can",
                iconColor = "#FF4C4C",
                onSelect = function()
                    TriggerEvent('1307_Boombox:client:confirmDeleteBoombox', netId, coords)
                end
            }
        }
    end

    lib.registerContext({
        id = '1307_Boombox_AdminMenu',
        title = "🛡️ QUẢN LÝ BOOMBOX",
        options = options
    })
    lib.showContext('1307_Boombox_AdminMenu')
end)

RegisterNetEvent('1307_Boombox:client:confirmDeleteBoombox', function(netId, coords)
    local alert = lib.alertDialog({
        header = 'XÁC NHẬN XÓA BOOMBOX',
        content = 'Bạn có chắc chắn muốn xóa Boombox này không?\nHành động này sẽ xóa đối tượng và dừng âm thanh phát trên loa.',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Xác nhận xóa',
            cancel = 'Hủy bỏ'
        }
    })

    if alert == 'confirm' then
        TriggerServerEvent('1307_Boombox:server:adminDeleteBoombox', netId, coords)
    end
end)

RegisterNetEvent('1307_Boombox:client:forceDeleteEntity', function(netId, coords)
    if netId and netId ~= 0 and NetworkDoesNetworkIdExist(netId) then
        local ent = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(ent) then
            SetEntityAsMissionEntity(ent, false, true)
            DeleteEntity(ent)
            DeleteObject(ent)
        end
    end

    if coords then
        for _, v in pairs(Config.Boombox) do
            local hash = GetHashKey(v.Model)
            local closestObj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.5, hash, false, false, false)
            if DoesEntityExist(closestObj) then
                SetEntityAsMissionEntity(closestObj, false, true)
                DeleteEntity(closestObj)
                DeleteObject(closestObj)
            end
        end
    end

    if currentData == netId then
        currentData = nil
        check_use_boombox = false
    end
end)
