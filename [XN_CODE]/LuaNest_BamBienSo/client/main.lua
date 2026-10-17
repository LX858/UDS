local QBCore = exports['qb-core']:GetCoreObject()

local tvEntity = nil
local duiObj = nil
local SFHandle = nil
local dist = 1000
local isSpinning = false

function LoadScaleform()
    local scaleform = RequestScaleformMovie_2('generic_texture_renderer')
    while not HasScaleformMovieLoaded(scaleform) do
        scaleform = RequestScaleformMovie('generic_texture_renderer')
        Wait(100)
    end
    return scaleform
end

function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
end



CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(50)
    end
      LoadModel(Config.TVModel)

    tvEntity = CreateObjectNoOffset(Config.TVModel, Config.TVPosition, false, false, false)
    SetEntityHeading(tvEntity, Config.TVHeading)
    FreezeEntityPosition(tvEntity, true)
    exports.ox_target:addLocalEntity(tvEntity, {
        {
            label = 'Quay số',
            icon = 'fa-solid fa-dice',
            serverEvent = 'LuaNest_BamBienSo:server:GetNumber',
            canInteract = function(entity, distance, coords, name, bone)
                return not isSpinning
            end,
        }
    })
    QBCore.Functions.TriggerCallback('LuaNest_BamBienSo:server:GetSpinningState', function(spinningState)
        isSpinning = spinningState
    end)
    while true do
        local ped = PlayerPedId()
        dist = #(GetEntityCoords(ped) - Config.RenderScreen.Position)

        Wait(1000)
    end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(50)
    end

    SFHandle = LoadScaleform()

    while true do
        Wait(1000)
        if dist <= Config.RenderDistance then
            if SFHandle == nil then SFHandle = LoadScaleform() end

            local txd = CreateRuntimeTxd(Config.Texture.TXD)
            duiObj = CreateDui(Config.RenderURL, Config.ScreenResolution.width, Config.ScreenResolution.height)
            local dui = GetDuiHandle(duiObj)
            local tx = CreateRuntimeTextureFromDuiHandle(txd, Config.Texture.TXN, dui)
            Wait(500)

            PushScaleformMovieFunction(SFHandle, 'SET_TEXTURE')
            PushScaleformMovieMethodParameterString(Config.Texture.TXD)
            PushScaleformMovieMethodParameterString(Config.Texture.TXN)
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(Config.ScreenResolution.width)
            PushScaleformMovieFunctionParameterInt(Config.ScreenResolution.height)
            Wait(500)
            PopScaleformMovieFunctionVoid()

            SetDuiUrl(duiObj, Config.RenderURL)

            while dist <= Config.RenderDistance do
                Wait(0)
                DrawScaleformMovie_3dNonAdditive(
                    SFHandle,
                    Config.RenderScreen.Position.x, Config.RenderScreen.Position.y, Config.RenderScreen.Position.z,
                    Config.RenderScreen.Rotation.x, Config.RenderScreen.Rotation.y, Config.RenderScreen.Rotation.z,
                    2.0, 2.0, 2.0,
                    Config.Scale * 0.99,
                    Config.Scale * (9.0 / 18.5),
                    9.0,
                    2
                )
            end

            DestroyDui(duiObj)
            duiObj = nil
        end
    end
end)

RegisterNetEvent('LuaNest_BamBienSo:client:ReceiveNumber', function(data)
    if not data or not data.old or not data.new then return end

    -- Gửi dữ liệu cho giao diện Dui
    SendDuiMessage(duiObj, json.encode({
        type = "showPlate",
        oldPlate = data.old,
        newPlate = data.new,
        Model = data.Model
    }))
end)

RegisterNetEvent('LuaNest_BamBienSo:client:setSpinState', function(state)
    isSpinning = state
end)


CreateThread(function()
    RequestModel(`s_m_y_cop_01`)
    while not HasModelLoaded(`s_m_y_cop_01`) do
        Wait(100)
    end

    local ped = CreatePed(0, `s_m_y_cop_01`, Config.SettingsNPC.Location.x, Config.SettingsNPC.Location.y, Config.SettingsNPC.Location.z - 1, Config.SettingsNPC.Location.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- ox_target
    exports.ox_target:addLocalEntity(ped, {
        {
            label = '📄 Nộp hồ sơ xe',
            icon = 'fa-solid fa-file',
            serverEvent = 'LuaNest_BamBienSo:server:nopHoSo',
            groups = 'police',
            item = 'giaytoxe',
            canInteract = function(entity, distance, coords, name, bone)
                return true
            end,
        }
    })
    exports.ox_target:addBoxZone({
		name = "vung_ho_so",
		coords = vec3(68.39, -434.1, 39.14),
		size = vec3(2.0, 2.0, 4.0),
		rotation = 0.0,
        options = {
            label = '📄 Hồ Sơ Phương Tiện',
            icon = 'fa-solid fa-file',
            event = 'LuaNest_BamBienSo:client:traHoSo',
            job = 'police',
        }
	})

end)


RegisterNetEvent('LuaNest_BamBienSo:client:traHoSo', function()
    local Player = QBCore.Functions.GetPlayerData()
    local playerCitizenId = Player.citizenid
    local options = {}

    QBCore.Functions.TriggerCallback("LuaNest_BamBienSo:server:GetCache", function(data)
        if data and next(data) then
            -- Chỉ hiển thị hồ sơ của người chơi hiện tại
            for plate, v in pairs(data) do
                if v.CCCD == playerCitizenId then
                    table.insert(options, {
                        title = '🚗 Biển số: ' .. v.plate,
                        description = string.format("Chủ xe: %s | Model: %s", v.tenchu, v.model),
                        onSelect = function()
                            TriggerServerEvent('LuaNest_BamBienSo:server:TraHoSo', plate)
                        end
                    })
                end
            end

            if #options > 0 then
                lib.registerContext({
                    id = 'tra_ho_so_menu',
                    title = '📋 Danh sách hồ sơ xe của bạn',
                    options = options
                })

                lib.showContext('tra_ho_so_menu')
            else
                lib.notify({
                    title = 'Thông báo',
                    description = '📭 Bạn không có hồ sơ xe nào đang giữ.',
                    type = 'error'
                })
            end
        else
            lib.notify({
                title = 'Thông báo',
                description = '📭 Không có hồ sơ nào đang giữ.',
                type = 'error'
            })
        end
    end)
end)


RegisterNetEvent('LuaNest_BamBienSo:client:ganbien', function(item)
    if item.name ~= 'biensoxe' then return end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local veh = GetClosestVehicle(coords, 4.0, 0, 71)

    if not veh or veh == 0 then
        lib.notify({ title = 'Thông báo', description = '🚗 Không tìm thấy xe gần bạn!', type = 'error' })
        return
    end

    local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    
    -- Kiểm tra biển số xe phải có format CDK + 5 số (ví dụ: CDK12345)
    local cdkPattern = "^CDK%d%d%d%d%d$"
    if not string.match(plate, cdkPattern) then
        lib.notify({ title = 'Thông báo', description = '❌ Xe phải có biển số tạm (CDK + 5 số) mới được gắn biển mới!', type = 'error' })
        return
    end

    QBCore.Functions.TriggerCallback('LuaNest_BamBienSo:server:KiemTraXeChinhChu', function(isOwner)
        if not isOwner then
            lib.notify({ title = 'Thông báo', description = '❌ Xe này không phải của bạn!', type = 'error' })
            return
        end

        local vehCoords = GetEntityCoords(veh)
        local forward = GetEntityForwardVector(veh)
        local rearPlatePos = vehCoords - (forward * 2.0) 
        local dist = #(coords - rearPlatePos)

        if dist > 2.0 then
            lib.notify({ title = 'Thông báo', description = '📏 Bạn cần đứng phía sau gần biển số xe!', type = 'error' })
            return
        end

        lib.requestAnimDict("amb@world_human_vehicle_mechanic@male@base")
        TaskPlayAnim(playerPed, "amb@world_human_vehicle_mechanic@male@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
        FreezeEntityPosition(playerPed, true)

        lib.progressCircle({
            duration = 5000,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            label = '🔧 Đang gắn biển số xe...',
        })

        FreezeEntityPosition(playerPed, false)
        ClearPedTasks(playerPed)

        SetVehicleNumberPlateText(veh, item.metadata.plate)
        TriggerServerEvent('LuaNest_BamBienSo:server:CapNhatBienSo', plate, item.metadata.plate)

        lib.notify({ title = 'Thành công', description = '✅ Biển số mới: ' .. item.metadata.plate, type = 'success' })

        TriggerServerEvent('ox_inventory:removeItem', 'biensoxe', 1)

    end, plate)
end)

-- Event mở dialog để nhập PID
RegisterNetEvent('LuaNest_BamBienSo:client:capGiayToXe', function()
    local input = lib.inputDialog('Cấp giấy tờ xe', {
        {
            type = 'number',
            label = 'PID người chơi',
            description = 'Nhập PID của người chơi cần cấp giấy tờ xe',
            required = true,
            min = 1,
            max = 9999
        }
    })

    if not input then return end
    
    local targetPid = tonumber(input[1])
    
    if not targetPid then
        lib.notify({
            title = 'Lỗi',
            description = '❌ PID không hợp lệ!',
            type = 'error'
        })
        return
    end

    -- Trigger command server với PID đã nhập
    TriggerServerEvent('LuaNest_BamBienSo:server:capGiayToXeFromClient', targetPid)
end)

RegisterNetEvent('LuaNest_BamBienSo:client:checkVehicle', function(adminSrc, inputPlate, targetPid)
    print(('[LuaNest Client] Nhận được yêu cầu kiểm tra xe - Admin: %s, Input Plate: %s, PID: %s'):format(adminSrc, inputPlate, targetPid))
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        print('[LuaNest Client] Người chơi không đang ngồi trên xe')
        
        -- Thông báo cho admin qua server event
        TriggerServerEvent('LuaNest_BamBienSo:server:playerNotInVehicle', adminSrc, targetPid)
        
        -- Thông báo cho người chơi (nhiều cách)
        QBCore.Functions.Notify('❌ Bạn cần ngồi trên xe để nhận giấy tờ xe!', 'error', 5000)
        
        -- Thông báo chat
        -- TriggerEvent('chat:addMessage', {
        --     color = {255, 0, 0},
        --     multiline = true,
        --     args = {"[GIAYTOXE]", "❌ Bạn cần ngồi trên xe để có thể nhận giấy tờ xe!"}
        -- })
        
        -- Thông báo màn hình (nếu có ox_lib)
        if lib then
            lib.notify({
                title = 'Yêu cầu giấy tờ xe',
                description = '❌ Bạn cần ngồi trên xe để nhận giấy tờ xe!',
                type = 'error',
                duration = 5000
            })
        end
        
        return
    end
    
    -- Lấy biển số thực tế từ xe mà người chơi đang ngồi
    local actualPlate = GetVehicleNumberPlateText(vehicle)
    actualPlate = string.gsub(actualPlate, "%s+", "") -- Loại bỏ khoảng trắng
    
    local vehicleModel = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(vehicleModel)
    print(('[LuaNest Client] Tìm thấy xe: %s, Biển số thực tế: %s'):format(modelName, actualPlate))
    
    -- Sử dụng biển số thực tế thay vì input plate
    TriggerServerEvent('LuaNest_BamBienSo:server:createGiayToXe', adminSrc, actualPlate, targetPid, modelName)
end)
