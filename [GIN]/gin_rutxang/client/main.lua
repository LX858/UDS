local function getVehicleFuel(vehicle)
    if not DoesEntityExist(vehicle) then return 0.0 end

    local nativeFuel = GetVehicleFuelLevel(vehicle)
    if GetResourceState('ox_fuel') == 'started' and exports.ox_fuel then
        local oxFuel = exports.ox_fuel:GetFuel(vehicle)
        if oxFuel ~= nil then
            nativeFuel = tonumber(oxFuel) or nativeFuel
        end
    end

    local stateFuel = Entity(vehicle).state and Entity(vehicle).state.fuel
    if stateFuel ~= nil then
        local numState = tonumber(stateFuel) or 0.0
        -- Nếu xăng thực tế lớn hơn StateBag (do đã đổ/bơm xăng mới) -> Cập nhật StateBag theo số xăng mới
        if nativeFuel > numState + 1.0 then
            Entity(vehicle).state:set('fuel', nativeFuel, true)
            return nativeFuel
        end
        return numState
    end

    return nativeFuel
end

local function setVehicleFuel(vehicle, fuel)
    if not DoesEntityExist(vehicle) then return end
    fuel = (tonumber(fuel) or 0.0) + 0.0

    -- Native GTA V
    SetVehicleFuelLevel(vehicle, fuel)
    Entity(vehicle).state:set('fuel', fuel, true)

    -- Hỗ trợ tất cả các script xăng FiveM phổ biến
    if GetResourceState('ox_fuel') == 'started' and exports.ox_fuel then
        pcall(function() exports.ox_fuel:SetFuel(vehicle, fuel) end)
    end
    if GetResourceState('LegacyFuel') == 'started' then
        pcall(function() exports['LegacyFuel']:SetFuel(vehicle, fuel) end)
    end
    if GetResourceState('ps-fuel') == 'started' then
        pcall(function() exports['ps-fuel']:SetFuel(vehicle, fuel) end)
    end
    if GetResourceState('cdn-fuel') == 'started' then
        pcall(function() exports['cdn-fuel']:SetFuel(vehicle, fuel) end)
    end
    if GetResourceState('qb-fuel') == 'started' then
        pcall(function() exports['qb-fuel']:SetFuel(vehicle, fuel) end)
    end
end

local function startSiphoningFuel(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local currentFuel = getVehicleFuel(vehicle)
    if not currentFuel or currentFuel <= 0.5 then
        lib.notify({
            title = 'Rút Xăng',
            description = 'Phương tiện này hiện không còn xăng để rút!',
            type = 'error'
        })
        return
    end

    -- Tính toán thời gian rút xăng theo tỷ lệ (Tối đa Config.MaxDuration = 30000ms)
    local maxFuel = 100.0
    local fuelRatio = math.min(currentFuel / maxFuel, 1.0)
    local duration = math.floor(fuelRatio * Config.MaxDuration)

    if duration < Config.MinDuration then
        duration = Config.MinDuration
    end

    -- Chạy Progressbar của ox_lib
    if lib.progressBar({
        duration = duration,
        label = string.format('Đang rút xăng (%d%%)...', math.floor(currentFuel)),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = Config.Anim.scenario and {
            scenario = Config.Anim.scenario
        } or {
            dict = Config.Anim.dict,
            clip = Config.Anim.clip,
            flag = Config.Anim.flag or 1
        }
    }) then
        -- Đặt xăng về 0 ngay phía client
        setVehicleFuel(vehicle, 0.0)

        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('gin_rutxang:server:siphonFuel', netId, currentFuel)
    else
        lib.notify({
            title = 'Rút Xăng',
            description = 'Bạn đã hủy thao tác rút xăng!',
            type = 'error'
        })
    end
end

-- Event đồng bộ trực tiếp từ server cho tất cả người chơi
RegisterNetEvent('gin_rutxang:client:syncFuel', function(netId, newFuel)
    if not netId then return end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        setVehicleFuel(vehicle, newFuel)
    end
end)

-- Tự động đồng bộ xăng từ StateBag khi StateBag của xe thay đổi
AddStateBagChangeHandler('fuel', nil, function(bagName, key, value, _unused, replicated)
    if value == nil then return end
    local entity = GetEntityFromStateBagName(bagName)
    if entity and entity ~= 0 and DoesEntityExist(entity) and IsEntityAVehicle(entity) then
        SetVehicleFuelLevel(entity, (tonumber(value) or 0.0) + 0.0)
    end
end)

-- Tự động kiểm tra và áp dụng lại số xăng khi người chơi bước lên xe
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        local playerPed = PlayerPedId()
        local entityNetId, vehicle = args[1], args[2]
        if entityNetId == playerPed or entityNetId == PedToNet(playerPed) then
            if DoesEntityExist(vehicle) then
                SetTimeout(250, function()
                    if DoesEntityExist(vehicle) then
                        local currentFuel = GetVehicleFuelLevel(vehicle)
                        if GetResourceState('ox_fuel') == 'started' and exports.ox_fuel then
                            local oxFuel = exports.ox_fuel:GetFuel(vehicle)
                            if oxFuel ~= nil then currentFuel = tonumber(oxFuel) or currentFuel end
                        end

                        local stateFuel = Entity(vehicle).state and Entity(vehicle).state.fuel
                        if stateFuel ~= nil then
                            local numState = tonumber(stateFuel) or 0.0
                            -- Nếu xăng thực tế trên xe lớn hơn StateBag (xe vừa được đổ/bơm xăng mới)
                            if currentFuel > numState + 1.0 then
                                Entity(vehicle).state:set('fuel', currentFuel, true)
                            else
                                setVehicleFuel(vehicle, numState)
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- Thêm Option Target vào tất cả các phương tiện (Vehicle)
CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'gin_rutxang_option',
            icon = 'fas fa-gas-pump',
            label = 'Rút xăng',
            items = Config.EmptyItem, -- Bắt buộc phải có bình xăng rỗng trong túi/cầm trên tay
            distance = Config.TargetDistance,
            onSelect = function(data)
                startSiphoningFuel(data.entity)
            end
        }
    })

    -- Thêm BoxZone Target cho Kho lưu trữ cây xăng tại tọa độ 289.30, -1264.72, 29.50
    exports.ox_target:addBoxZone({
        coords = Config.ExchangeLocation,
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0.0,
        debug = false,
        options = {
            {
                name = 'gin_rutxang_storage_exchange',
                icon = 'fas fa-boxes-stacked',
                label = 'Kho cây xăng - Đổi bình xăng rỗng',
                groups = Config.RequiredJob, -- Chỉ người chơi có job 'cayxang' mới thấy và đổi được
                distance = 2.5,
                onSelect = function()
                    local input = lib.inputDialog('Kho Lưu Trữ Cây Xăng', {
                        {
                            type = 'number',
                            label = 'Số lượng bình xăng rỗng muốn đổi',
                            description = string.format('Tỷ lệ đổi: %d vỏ chai (%s) = 1 bình xăng rỗng', Config.ExchangeRatio, Config.BottleItem),
                            min = 1,
                            max = 1000,
                            default = 1,
                            required = true
                        }
                    })

                    if not input or not input[1] then return end
                    local amount = math.floor(tonumber(input[1]) or 0)
                    if amount <= 0 then return end

                    -- Kiểm tra số lượng vỏ chai trong túi đồ trước khi chạy progressbar
                    local neededBottles = amount * (Config.ExchangeRatio or 10)
                    local currentBottles = exports.ox_inventory:Search('count', Config.BottleItem) or 0

                    if currentBottles < neededBottles then
                        lib.notify({
                            title = 'Kho Lưu Trữ Cây Xăng',
                            description = string.format('Bạn không đủ vỏ chai! Cần %d %s (bạn hiện có %d).', neededBottles, Config.BottleItem, currentBottles),
                            type = 'error'
                        })
                        return
                    end

                    -- Chạy Progressbar 10 giây và animation đổi bình xăng
                    if lib.progressBar({
                        duration = Config.ExchangeDuration or 10000,
                        label = string.format('Đang đổi %d bình xăng rỗng...', amount),
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                            move = true,
                            combat = true,
                        },
                        anim = {
                            dict = Config.ExchangeAnim.dict,
                            clip = Config.ExchangeAnim.clip,
                            flag = Config.ExchangeAnim.flag or 49
                        }
                    }) then
                        TriggerServerEvent('gin_rutxang:server:exchangeEmptyCans', amount)
                    else
                        lib.notify({
                            title = 'Kho Lưu Trữ Cây Xăng',
                            description = 'Bạn đã hủy quá trình đổi bình xăng rỗng!',
                            type = 'error'
                        })
                    end
                end
            }
        }
    })
end)
